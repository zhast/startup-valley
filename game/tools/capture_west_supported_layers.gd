extends "res://tools/capture_supported_west_assembly.gd"
## DEV-ONLY per-character support + exact source-layer study. Baselines untouched.
const WEST_CHAIR := preload("res://tools/calibration_west_chair_layers.gd")
const LAYER_OUTPUT := "res://tests/output/west-supported-layers"
const CUTS: Dictionary = {"mira": [50, 52, 54], "theo": [48, 50, 52]}
const ACTOR_FROM_CHAIR: Dictionary = {"mira": 4, "theo": 8}
const HAND_REGIONS: Dictionary = {"mira": Rect2i(10, 43, 12, 7), "theo": Rect2i(7, 39, 15, 9)}

var layer_observations: Array[Dictionary] = []
var source_hashes: Dictionary = {}
var actor_pixels_compared := 0
var chair_pixels_compared := 0
var rendered_actor_pixels_compared := 0
var rendered_chair_pixels_compared := 0
var reunion_original: Image
var chair_reunion_original: Image

class LayerGuide extends Node2D:
	var actor_y := 0
	var hip_rows := Vector2i(53, 55)
	var hand_rect := Rect2i()
	var cut := 50

	func _draw() -> void:
		var chair_foot := Vector2(20, 0)
		var actor_origin := chair_foot + Vector2(-24, actor_y - 72)
		draw_rect(Rect2(-16, -48, 32, 96), Color("FA4616"), false, 1)
		draw_rect(Rect2(16, -16, 32, 32), Color("C1FA81"), false, 1)
		draw_rect(Rect2(-16, -80, 32, 96), Color("6196C1"), false, 1)
		draw_line(Vector2(27, 0), Vector2(37, 0), Color.WHITE, 1)
		draw_line(Vector2(32, -5), Vector2(32, 5), Color.WHITE, 1)
		draw_line(Vector2(32, 0), chair_foot, Color.WHITE, 1)
		draw_rect(Rect2(chair_foot + Vector2(-11, -15), Vector2(18, 2)), Color.CYAN, false, 1)
		draw_rect(Rect2(actor_origin + Vector2(14, hip_rows.x), Vector2(14, hip_rows.y - hip_rows.x + 1)), Color("FFD27F"), false, 1)
		draw_rect(Rect2(actor_origin + Vector2(hand_rect.position), Vector2(hand_rect.size)), Color.YELLOW, false, 1)
		draw_line(actor_origin + Vector2(0, cut), actor_origin + Vector2(48, cut), Color(1, 0.4, 0.8), 1)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	height_normalized = true
	output_path = LAYER_OUTPUT
	seat_band = Rect2i(37, 97, 18, 2)
	call_deferred("run")

func build() -> void:
	super.build()
	(panels[0].get_child(0) as Label).text = "WEST LAYER STUDY · chair X−12 · supported actor Y+4 Mina / +8 Theo"
	(panels[1].get_child(0) as Label).text = "UNAPPROVED · exact source ownership · whole-body baseline preserved · Theo drift remains"
	var partition := WEST_CHAIR.partition()
	for index: int in range(stations.size()):
		var station: Dictionary = stations[index]
		station.cut = int(CUTS[station.id][index % 3])
		station.actor_y = int(ACTOR_FROM_CHAIR[station.id])
		station.shift = -12
		station.render_foot = station.logical + Vector2(-12, 0)
		station.actor_foot = station.render_foot + Vector2(0, station.actor_y)
		station.actor.position = station.actor_foot + Vector2(0, -32)
		station.chair.position = station.render_foot + Vector2(0, -32)
		station.guide.free()
		var guide := LayerGuide.new()
		guide.actor_y = station.actor_y
		guide.hip_rows = Vector2i(53, 55) if station.id == "mira" else Vector2i(49, 51)
		guide.hand_rect = HAND_REGIONS[station.id]
		guide.cut = station.cut
		guide.position = station.anchor
		guide.z_as_relative = false
		guide.z_index = 1500
		guide.hide()
		stage.add_child(guide)
		station.guide = guide
		for part: String in ["rear", "near_arm"]:
			var depth := -5 if part == "rear" else -3
			var layer := WEST_CHAIR.layer(station.chair.texture, partition[part], station.render_foot, roundi(station.anchor.y + depth))
			stage.add_child(layer)
			station["chair_" + part] = layer
		for part: String in ["upper", "lower"]:
			var layer := Sprite2D.new()
			layer.texture = station.pose
			layer.centered = false
			layer.region_enabled = true
			layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			layer.z_as_relative = false
			layer.z_index = roundi(station.anchor.y + (2 if part == "upper" else -4))
			stage.add_child(layer)
			station[part] = layer
		source_hashes[station.id] = station.pose_image.get_data().hex_encode().sha256_text()
		check(station.actor_foot - station.render_foot == Vector2(0, station.actor_y), "Per-character source support offsets remain explicit")
		check(station.render_foot - station.logical == Vector2(-12, 0), "Chair pull-in is visual, not a shifted logical cell")
		check(station.chair_rear.z_index < station.lower.z_index and station.lower.z_index < station.chair_near_arm.z_index and station.chair_near_arm.z_index < station.desk.z_index - 1 and station.upper.z_index > station.desk.z_index, "Layer contract: rear chair, lower body, near arm, top, hands")
	validate_chair_reunion(stations[0].chair_image, partition)

func validate_chair_reunion(source: Image, partition: Dictionary) -> void:
	var combined := Image.create(96, 160, false, source.get_format())
	var owners := PackedByteArray()
	owners.resize(96 * 160)
	var counts := {"rear": 0, "near_arm": 0}
	for part: String in ["rear", "near_arm"]:
		for rectangle: Rect2i in partition[part]:
			check(Rect2i(0, 0, 96, 160).encloses(rectangle), "Chair region stays in original padded canvas")
			combined.blit_rect(source, rectangle, rectangle.position)
			for y: int in range(rectangle.position.y, rectangle.end.y):
				for x: int in range(rectangle.position.x, rectangle.end.x):
					owners[y * 96 + x] += 1
					if source.get_pixel(x, y).a > 0.5: counts[part] += 1
	check(owners.count(1) == owners.size(), "Every chair pixel, including transparent padding, has exactly one owner")
	check(combined.get_data() == source.get_data(), "West chair regions reconstruct every original RGBA byte")
	check(counts.near_arm == 86, "Measured west bar46px plus stem40px supplies86 opaque near-arm pixels")
	chair_pixels_compared = owners.size()
	source_hashes.chair_counts = counts

func validate_actor_reunion(station: Dictionary, frame: int) -> void:
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var combined := Image.create(48, 80, false, source.get_format())
	var cut: int = station.cut
	combined.blit_rect(source, Rect2i(0, 0, 48, cut), Vector2i.ZERO)
	combined.blit_rect(source, Rect2i(0, cut, 48, 80 - cut), Vector2i(0, cut))
	check(combined.get_data() == source.get_data(), "Exact actor upper/lower reconstruction, %s cut%d frame%d" % [station.id, cut, frame])
	check(Rect2i(0, 0, 48, cut).end.y == Rect2i(0, cut, 48, 80 - cut).position.y, "No missing/duplicate source row at actor seam")
	actor_pixels_compared += 48 * 80

func layer_metrics(station: Dictionary, frame: int) -> Dictionary:
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var origin := Vector2i(station.actor_foot - ACTOR_PIVOT)
	var key_bed := Rect2i(Vector2i(station.anchor - KIT_PIVOT) + KEY_BED.position, KEY_BED.size)
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	var hand: Rect2i = HAND_REGIONS[station.id]
	var opaque_hand_roi := 0
	var hand_on_keys := 0
	var hand_below_cut := 0
	var lower_on_top := 0
	var upper_lap_on_top := 0
	var lap_start := 50 if station.id == "mira" else 48
	for y: int in range(80):
		for x: int in range(48):
			if source.get_pixel(x, y).a < 0.5: continue
			var point := origin + Vector2i(x, y)
			if hand.has_point(Vector2i(x, y)):
				opaque_hand_roi += 1
				if key_bed.has_point(point): hand_on_keys += 1
				if y >= int(station.cut): hand_below_cut += 1
			if top.has_point(point):
				if y >= int(station.cut): lower_on_top += 1
				elif y >= lap_start: upper_lap_on_top += 1
	var hip: Vector2i = station.guide.hip_rows
	var seat_y := int(station.render_foot.y) - 15
	var used := source.get_used_rect()
	return {"id": station.id, "frame": frame, "cut": station.cut, "chair_from_logical": [-12, 0], "actor_from_chair": [0, station.actor_y], "hip_minus_seat": [origin.y + hip.x - seat_y, origin.y + hip.y - seat_y], "hand_roi_opaque": opaque_hand_roi, "hand_roi_on_key_bed": hand_on_keys, "hand_roi_below_cut": hand_below_cut, "lower_pixels_correctly_occluded_by_top": lower_on_top, "upper_lap_roi_pixels_still_over_top": upper_lap_on_top, "native_top_row": used.position.y, "native_last_row": used.end.y - 1, "method": "Opaque manually reviewed region, no skin-color classifier; not a semantic hand collider"}

func set_frame(frame: int, mode: String = "native") -> void:
	for station: Dictionary in stations:
		var cut: int = station.cut
		var origin: Vector2 = station.actor_foot - ACTOR_PIVOT
		station.actor.texture = station.pose
		station.actor.region_rect = Rect2(frame * 48, 0, 48, 80)
		station.actor.position = station.actor_foot + Vector2(0, -32)
		station.actor.hide()
		station.upper.region_rect = Rect2(frame * 48, 0, 48, cut)
		station.lower.region_rect = Rect2(frame * 48, cut, 48, 80 - cut)
		station.upper.position = origin
		station.lower.position = origin + Vector2(0, cut)
		station.upper.z_index = roundi(station.anchor.y + 2)
		station.lower.z_index = roundi(station.anchor.y - 4)
		station.upper.show()
		station.lower.show()
		station.chair.hide()
		station.chair_rear.show()
		station.chair_near_arm.show()
		for part: String in ["desk", "monitor", "keyboard", "mouse"]: station[part].visible = mode != "support"
		station.guide.visible = mode in ["support", "guides"]
		if mode.begins_with("reunion") or mode.begins_with("chair-reunion"):
			for part: String in ["desk", "monitor", "keyboard", "mouse", "guide"]: station[part].hide()
			if mode.begins_with("reunion"):
				station.chair_rear.hide()
				station.chair_near_arm.hide()
				station.lower.z_index = station.upper.z_index
				if mode == "reunion-original":
					station.actor.show()
					station.upper.hide()
					station.lower.hide()
			else:
				station.upper.hide()
				station.lower.hide()
				if mode == "chair-reunion-original":
					station.chair.show()
					station.chair_rear.hide()
					station.chair_near_arm.hide()
		station.label.text = "%s · cut%d · body Y+%d\n%s" % ["Mina" if station.id == "mira" else "Theo", cut, station.actor_y, "Exact pixel reunion" if "reunion" in mode else "%s · frame%d" % [mode, frame]]

func validate_ui() -> void:
	super.validate_ui()
	for panel: PanelContainer in panels:
		var style := panel.get_theme_stylebox("panel")
		var label := panel.get_child(0) as Label
		check(label.get_minimum_size().x <= panel.custom_minimum_size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT), "Caption fits paper's intended inner width without stretching")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Layer capture stays1280×720")
	check(screenshot.save_png(LAYER_OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if name_value.begins_with("reunion-original"): reunion_original = screenshot
	if name_value.begins_with("reunion-split"):
		for station: Dictionary in stations:
			check(screenshot.get_region(station.detail_bounds).get_data() == reunion_original.get_region(station.detail_bounds).get_data(), "Actual rendered actor reunion is byte-identical to original")
			rendered_actor_pixels_compared += 128 * 160
	if name_value == "chair-reunion-original": chair_reunion_original = screenshot
	if name_value == "chair-reunion-split":
		for station: Dictionary in stations:
			check(screenshot.get_region(station.detail_bounds).get_data() == chair_reunion_original.get_region(station.detail_bounds).get_data(), "Actual rendered chair region reunion is byte-identical to original")
			rendered_chair_pixels_compared += 128 * 160
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.detail_bounds)
			crop.resize(512, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-cut%d-4x.png" % [name_value, station.id, station.cut]
			check(crop.save_png(LAYER_OUTPUT.path_join(path)) == OK, "Save exact4× supported contact detail")
			captures.append(path)
	print("West supported layers: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LAYER_OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			validate_actor_reunion(station, frame)
			var result := layer_metrics(station, frame)
			layer_observations.append(result)
			check(result.hip_minus_seat == [0, 2], "Measured per-character Y offsets align same hip/seat estimate")
			check(result.hand_roi_opaque > 0 and result.hand_roi_below_cut == 0, "All cuts retain the explicitly reviewed hand-region source pixels")
			check(result.lower_pixels_correctly_occluded_by_top > 0, "Every frame exercises real lower-body/top occlusion")
	set_frame(0)
	await frames()
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		for frame: int in range(6):
			set_frame(frame)
			await capture("native-frame%d" % frame, frame == 2)
		for frame: int in range(6):
			set_frame(frame, "support")
			await capture("support-frame%d" % frame, frame == 2)
		set_frame(2, "guides")
		await capture("guides-frame2")
		for frame: int in range(6):
			set_frame(frame, "reunion-original")
			await capture("reunion-original-frame%d" % frame)
			set_frame(frame, "reunion-split")
			await capture("reunion-split-frame%d" % frame)
		set_frame(2, "chair-reunion-original")
		await capture("chair-reunion-original")
		set_frame(2, "chair-reunion-split")
		await capture("chair-reunion-split")
		for tick: int in range(210):
			var frame := (tick / 15) % 2 if tick < 60 or tick >= 180 else 2 + ((tick - 60) / 6) % 4
			set_frame(frame)
			await RenderingServer.frame_post_draw
	for station: Dictionary in stations:
		check(station.pose_image.get_data().hex_encode().sha256_text() == source_hashes[station.id], "Source atlas remains unchanged after partitioning")
	var file := FileAccess.open(LAYER_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "source_preserving_supported_candidates_not_runtime_approved", "checks": checks, "failures": failures, "worker_disabled": true, "production_or_source_changed": false, "renderer": DisplayServer.get_name(), "captures": captures, "cuts": CUTS, "actor_from_chair_y": ACTOR_FROM_CHAIR, "chair_from_logical": [-12, 0], "logical_work_cell": [1, 0], "logical_work_pixel": [32, 0], "chair_partition": "res://tools/calibration_west_chair_layers.gd", "near_arm_regions": [[39, 89, 13, 4], [44, 93, 4, 10]], "depths_relative_desk": {"chair_rear": -5, "actor_lower": -4, "chair_near_arm": -3, "tabletop": -1, "keyboard": 1, "actor_upper": 2, "monitor": 3}, "source_actor_pixels_compared": actor_pixels_compared, "source_chair_pixels_compared": chair_pixels_compared, "rendered_actor_reunion_pixels_compared": rendered_actor_pixels_compared, "rendered_chair_reunion_pixels_compared": rendered_chair_pixels_compared, "source_hashes": source_hashes, "known_theo_wobble": "headrow4/5,solerow70/71", "movie_sequence_frames": 210, "observations": layer_observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("west_supported_layers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
