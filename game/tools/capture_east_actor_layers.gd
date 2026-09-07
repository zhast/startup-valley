extends "res://tools/capture_supported_east_assembly.gd"
## DEV-ONLY exact source-preserving actor-layer study. The frozen whole-body
## baseline remains unchanged. No actor source, registry, or runtime code edits.

const LAYER_OUTPUT := "res://tests/output/east-actor-layers"
const CUT_ROWS: Array[int] = [50, 52, 55]
const ASSEMBLY_SHIFT := 12
const CHAIR_LAYERS := preload("res://tools/calibration_chair_layers.gd")

var layer_observations: Array[Dictionary] = []
var source_pixels_compared := 0
var rendered_reunion_pixels := 0
var reunion_original: Image
var source_hashes: Dictionary = {}
var chair_pixels_compared := 0
var chair_rendered_reunion_pixels := 0
var chair_reunion_original: Image

func build() -> void:
	super.build()
	(panels[0].get_child(0) as Label).text = "EAST LAYER STUDY · chair/body X+12 · exact source cut at row50 / 52 / 55"
	(panels[1].get_child(0) as Label).text = "UNAPPROVED · exact source regions · no repainted pixels · short keyboard remains a separate gap"
	var chair_partition := CHAIR_LAYERS.partition("east")
	check(CHAIR_LAYERS.partition("west").is_empty(), "No unreviewed mirrored west chair partition is substituted")
	for index: int in range(stations.size()):
		var station: Dictionary = stations[index]
		var cut := CUT_ROWS[index % 3]
		station.cut = cut
		station.shift = ASSEMBLY_SHIFT
		station.render_foot = station.logical + Vector2(ASSEMBLY_SHIFT, 0)
		station.guide.shift = ASSEMBLY_SHIFT
		station.chair.position = station.render_foot + Vector2(0, -32)
		station.actor.position = station.render_foot + Vector2(0, -32)
		for part: String in ["rear", "front"]:
			var layer := CHAIR_LAYERS.layer(station.chair.texture, chair_partition[part], station.render_foot, roundi(station.anchor.y - 5) if part == "rear" else roundi(station.anchor.y - 3))
			stage.add_child(layer)
			station["chair_" + part] = layer
		for layer_name: String in ["upper", "lower"]:
			var layer := Sprite2D.new()
			layer.name = "%s_%s_%d" % [station.id, layer_name, cut]
			layer.texture = station.pose
			layer.centered = false
			layer.region_enabled = true
			layer.z_as_relative = false
			layer.z_index = roundi(station.anchor.y + 2) if layer_name == "upper" else roundi(station.anchor.y - 2)
			layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			stage.add_child(layer)
			station[layer_name] = layer
		check(cut >= 50 and cut <= 55, "Candidate cuts are bounded to observed hip region")
		check(station.render_foot - station.logical == Vector2(12, 0), "All cut candidates preserve provisional12px pull-in and real logical feet")
		check(station.upper.scale == Vector2.ONE and station.lower.scale == Vector2.ONE, "Neither cropped region is independently resized")
		var source: Image = station.pose_image
		source_hashes[station.id] = source.get_data().hex_encode().sha256_text()
	validate_chair_reunion(stations[0].chair_image, chair_partition)

func validate_chair_reunion(source: Image, partition: Dictionary) -> void:
	var combined := Image.create(96, 160, false, source.get_format())
	var owners := PackedByteArray()
	owners.resize(96 * 160)
	var counts := {"rear": 0, "front": 0}
	for part: String in ["rear", "front"]:
		for rectangle: Rect2i in partition[part]:
			check(Rect2i(0, 0, 96, 160).encloses(rectangle), "Chair crop remains inside original registered canvas")
			combined.blit_rect(source, rectangle, rectangle.position)
			for y: int in range(rectangle.position.y, rectangle.end.y):
				for x: int in range(rectangle.position.x, rectangle.end.x):
					owners[y * 96 + x] += 1
					if source.get_pixel(x, y).a > 0.5: counts[part] += 1
	check(owners.count(1) == owners.size(), "Every original chair pixel has exactly one region owner, including alpha padding")
	check(combined.get_data() == source.get_data(), "Partitioned chair reconstructs every original RGBA byte")
	check(counts.front > 0 and counts.rear > counts.front, "Near-arm layer has actual source pixels, not an empty declared layer")
	chair_pixels_compared = owners.size()
	source_hashes.chair_front_opaque = counts.front
	source_hashes.chair_rear_opaque = counts.rear

func validate_source_reunion(station: Dictionary, frame: int) -> void:
	var cut: int = station.cut
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var reunited := Image.create(48, 80, false, source.get_format())
	reunited.blit_rect(source, Rect2i(0, 0, 48, cut), Vector2i.ZERO)
	reunited.blit_rect(source, Rect2i(0, cut, 48, 80 - cut), Vector2i(0, cut))
	check(reunited.get_data() == source.get_data(), "Two nonoverlapping source rectangles reconstruct every RGBA byte: %s cut%d frame%d" % [station.id, cut, frame])
	source_pixels_compared += 48 * 80
	check(Rect2i(0, 0, 48, cut).end.y == Rect2i(0, cut, 48, 80 - cut).position.y, "Upper/lower source boundary has neither overlap nor missing row")

func split_metrics(station: Dictionary, frame: int) -> Dictionary:
	var original := metrics(station, frame)
	var cut: int = station.cut
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var origin := Vector2i(station.render_foot - ACTOR_PIVOT)
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	var lower_opaque := 0
	var lower_over_top := 0
	var upper_lap_roi_over_top := 0
	var sampled_hand_below_cut := 0
	for y: int in range(80):
		for x: int in range(48):
			var color := source.get_pixel(x, y)
			if color.a < 0.5: continue
			var on_top := top.has_point(origin + Vector2i(x, y))
			if y >= cut:
				lower_opaque += 1
				if on_top: lower_over_top += 1
			if y >= 50 and y < cut and on_top: upper_lap_roi_over_top += 1
			if y >= cut and x >= 28 and x <= 43 and y >= 39 and y <= 50 and color.r > 0.3 and color.g > color.r * 0.45 and color.g < color.r * 0.8 and color.b < color.g * 0.9:
				sampled_hand_below_cut += 1
	original.merge({"cut_row": cut, "lower_opaque_pixels": lower_opaque, "lower_source_pixels_occluded_by_top": lower_over_top, "upper_lap_roi_pixels_still_over_top": upper_lap_roi_over_top, "sampled_hand_pixels_below_cut": sampled_hand_below_cut, "registration": "original48x80 pivot24,72; region positions include original row offset"})
	return original

func set_frame(frame: int, mode: String = "native") -> void:
	super.set_frame(frame, mode)
	for station: Dictionary in stations:
		var cut: int = station.cut
		var origin: Vector2 = station.render_foot - ACTOR_PIVOT
		var upper: Sprite2D = station.upper
		var lower: Sprite2D = station.lower
		upper.region_rect = Rect2(frame * 48, 0, 48, cut)
		lower.region_rect = Rect2(frame * 48, cut, 48, 80 - cut)
		upper.position = origin
		lower.position = origin + Vector2(0, cut)
		upper.z_index = roundi(station.anchor.y + 2)
		lower.z_index = roundi(station.anchor.y - 4)
		station.actor.hide()
		upper.show()
		lower.show()
		station.chair.hide()
		station.chair_rear.show()
		station.chair_front.show()
		# Preserve baseline's chair-behind-body relationship for BOTH new actor
		# layers. Keeping chair atdesk0 after lowering the legs would introduce
		# a new whole-chair-through-hips defect unrelated to tabletop occlusion.
		if mode in ["whole-chair-behind", "chair-above-lower"]:
			station.chair_rear.hide()
			station.chair_front.hide()
			station.chair.show()
			station.chair.z_index = roundi(station.anchor.y - 5) if mode == "whole-chair-behind" else roundi(station.anchor.y)
		if mode.begins_with("reunion"):
			station.desk.hide()
			station.monitor.hide()
			station.keyboard.hide()
			station.mouse.hide()
			station.chair.hide()
			station.chair_rear.hide()
			station.chair_front.hide()
			station.guide.hide()
			lower.z_index = upper.z_index
			if mode == "reunion-original":
				station.actor.show()
				upper.hide()
				lower.hide()
		if mode.begins_with("chair-reunion"):
			station.desk.hide()
			station.monitor.hide()
			station.keyboard.hide()
			station.mouse.hide()
			station.actor.hide()
			upper.hide()
			lower.hide()
			station.guide.hide()
			if mode == "chair-reunion-original":
				station.chair.show()
				station.chair_rear.hide()
				station.chair_front.hide()
		var result := split_metrics(station, frame)
		station.label.text = "%s · cut %d · shift +12\n%s" % ["Mina" if station.id == "mira" else "Theo", cut, "Exact source-pixel reunion" if "reunion" in mode else "Hidden %dpx · lap %dpx" % [result.lower_source_pixels_occluded_by_top, result.upper_lap_roi_pixels_still_over_top]]

func validate_ui() -> void:
	super.validate_ui()
	for panel: PanelContainer in panels:
		var style := panel.get_theme_stylebox("panel")
		var label := panel.get_child(0) as Label
		var safe_width := panel.custom_minimum_size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
		check(label.get_minimum_size().x <= safe_width, "Caption fits intended paper width without forcing a wider panel or crowding corners")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Native source-layer evidence remains1280x720")
	check(screenshot.save_png(LAYER_OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if name_value == "reunion-original": reunion_original = screenshot
	if name_value == "chair-reunion-original": chair_reunion_original = screenshot
	if name_value == "chair-reunion-split":
		for station: Dictionary in stations:
			var actual := screenshot.get_region(station.detail_bounds)
			var expected := chair_reunion_original.get_region(station.detail_bounds)
			check(actual.get_data() == expected.get_data(), "Actual registered chair-region render is pixel-identical to whole original")
			chair_rendered_reunion_pixels += station.detail_bounds.size.x * station.detail_bounds.size.y
	if name_value == "reunion-split":
		for station: Dictionary in stations:
			var actual := screenshot.get_region(station.detail_bounds)
			var expected := reunion_original.get_region(station.detail_bounds)
			check(actual.get_data() == expected.get_data(), "Actual renderer reunion preserves native colors/alpha/registration: %s cut%d" % [station.id, station.cut])
			rendered_reunion_pixels += station.detail_bounds.size.x * station.detail_bounds.size.y
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.detail_bounds)
			crop.resize(512, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-cut%d-4x.png" % [name_value, station.id, station.cut]
			check(crop.save_png(LAYER_OUTPUT.path_join(path)) == OK, "Save nearest contact detail " + path)
			captures.append(path)
	print("East actor layers: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LAYER_OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			validate_source_reunion(station, frame)
			var result := split_metrics(station, frame)
			layer_observations.append(result)
			check(result.lower_source_pixels_occluded_by_top > 0, "Every frame/cut exercises actual lower-body tabletop occlusion")
			if station.cut >= 52:
				check(result.sampled_hand_pixels_below_cut == 0, "Safer cuts preserve the entire conservative hand sample region")
			elif station.id == "mira":
				check(result.sampled_hand_pixels_below_cut > 0, "Cut50 preserves the observed Mina hand/cuff boundary risk as a rejected measurement, not a hidden pass")
			check(result.head_hidden_by_monitor == 0 and result.head_pixels > 0, "All actor head pixels remain outside monitor")
	set_frame(0)
	await frames()
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		for frame: int in range(6):
			set_frame(frame)
			await capture("native-frame%d" % frame, frame == 2)
		set_frame(2, "guides")
		await capture("guides-frame2")
		set_frame(2, "support")
		await capture("support-frame2")
		set_frame(2, "whole-chair-behind")
		await capture("whole-chair-behind-frame2")
		set_frame(2, "chair-above-lower")
		await capture("chair-above-lower-frame2")
		set_frame(2, "reunion-original")
		await capture("reunion-original")
		set_frame(2, "reunion-split")
		await capture("reunion-split")
		set_frame(2, "chair-reunion-original")
		await capture("chair-reunion-original")
		set_frame(2, "chair-reunion-split")
		await capture("chair-reunion-split")
		for tick: int in range(180):
			var frame := (tick / 15) % 2 if tick < 60 else 2 + ((tick - 60) / 6) % 4
			set_frame(frame)
			await RenderingServer.frame_post_draw
	for station: Dictionary in stations:
		check(station.pose_image.get_data().hex_encode().sha256_text() == source_hashes[station.id], "Original pixel source remains unchanged after every crop/render")
	var file := FileAccess.open(LAYER_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "dev_source_preserving_layer_study_not_runtime_approved", "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "captures": captures, "cut_rows": CUT_ROWS, "source_pixels_compared": source_pixels_compared, "rendered_reunion_pixels_compared": rendered_reunion_pixels, "chair_source_pixels_compared": chair_pixels_compared, "chair_rendered_reunion_pixels_compared": chair_rendered_reunion_pixels, "source_pixel_hashes": source_hashes, "assembly_x_shift": ASSEMBLY_SHIFT, "logical_work_pixel": [-32, 0], "upper_depth": "desk+2", "lower_depth": "desk-4", "chair_depth": "rear-5 / neararm-3; tabletop-1; explicit whole-chair controls", "chair_partition": "res://tools/calibration_chair_layers.gd", "short_keyboard_approved": false, "production_or_source_art_changed": false, "diagnostic_motion_frames": 180, "observations": layer_observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("east_actor_layers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
