extends "res://tools/capture_corrected_east_assembly.gd"
## DEV-ONLY world-space device placement. All source pixels, actor attachment,
## source cut and layer depths remain fixed; no production facing is enabled.

const PLACEMENT_OUTPUT := "res://tests/output/east-keyboard-placement"
const KEY_SHIFTS: Array[int] = [4, 6, 8]
var placement_observations: Array[Dictionary] = []
var device_hashes: Dictionary = {}
var placement_cache: Dictionary = {}

class PlacementGuide extends CorrectedGuide:
	var key_shift := 0
	func _draw() -> void:
		var actor_foot := Vector2(-20, actor_y)
		draw_rect(Rect2(-16, -80, 32, 96), Color("6196C1"), false, 1)
		draw_rect(Rect2(Vector2(NEW_KEY_BED.position) - KIT_PIVOT + Vector2(key_shift, 0), Vector2(NEW_KEY_BED.size)), Color.YELLOW, false, 1)
		draw_rect(Rect2(actor_foot - ACTOR_PIVOT + Vector2(24, 18), Vector2(20, 21)), Color("C1FA81"), false, 1)
		draw_line(Vector2(-32, 0), actor_foot, Color.WHITE, 1)

func build() -> void:
	super.build()
	(panels[0].get_child(0) as Label).text = "EAST KEYBOARD PLACEMENT · devices move +X · chair, actor and monitor stay fixed"
	(panels[1].get_child(0) as Label).text = "UNAPPROVED · all source pixels intact · fingertip reach and face clearance are separate checks"
	for index: int in range(stations.size()):
		var station: Dictionary = stations[index]
		station.key_shift = KEY_SHIFTS[index % 3]
		station.actor_y = 3 if station.id == "mira" else 4
		station.render_foot = station.chair_foot + Vector2(0, station.actor_y)
		station.actor.position = station.render_foot + Vector2(0, -32)
		station.guide.queue_free()
		var guide := PlacementGuide.new()
		guide.position = station.anchor
		guide.actor_y = station.actor_y
		guide.key_shift = station.key_shift
		guide.hip_rows = Vector2i(53, 55) if station.id == "mira" else Vector2i(52, 54)
		guide.z_as_relative = false
		guide.z_index = 1500
		stage.add_child(guide)
		station.guide = guide
		station.keyboard_image = station.keyboard.texture.get_image()
		station.mouse_image = station.mouse.texture.get_image()
		for part: String in ["monitor", "keyboard", "mouse"]:
			device_hashes[part] = station[part].texture.get_image().get_data().hex_encode().sha256_text()
		check(station.cut == 52 and station.render_foot - station.logical == Vector2(12, station.actor_y), "Study cannot change accepted comparison cut or character support endpoint")

func skin_sample(color: Color) -> bool:
	return color.a > 0.5 and color.r > 0.3 and color.g > color.r * 0.45 and color.g < color.r * 0.8 and color.b < color.g * 0.9

func opaque_at(source: Image, point: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, source.get_size()).has_point(point) and source.get_pixelv(point).a > 0.5

func measure_placement(station: Dictionary, frame: int, shift: int) -> Dictionary:
	var cache_key := "%s-%d-%d" % [station.id, frame, shift]
	if placement_cache.has(cache_key): return placement_cache[cache_key]
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin := Vector2i(station.render_foot - ACTOR_PIVOT)
	var kit_origin := Vector2i(station.anchor - KIT_PIVOT)
	var key_origin := kit_origin + Vector2i(shift, 0)
	var key_bed := Rect2i(key_origin + NEW_KEY_BED.position, NEW_KEY_BED.size)
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	var hands: Array[Vector2i] = []
	var head: Array[Vector2i] = []
	var face: Array[Vector2i] = []
	var tip_right := -1
	for y: int in range(80):
		for x: int in range(48):
			var color := source.get_pixel(x, y)
			if color.a < 0.5: continue
			var point := Vector2i(x, y)
			if y < 39: head.append(actor_origin + point)
			if Rect2i(24, 18, 20, 21).has_point(point) and skin_sample(color): face.append(actor_origin + point)
			if Rect2i(28, 39, 16, 12).has_point(point) and skin_sample(color):
				hands.append(point)
				# Independent geometry inference: the forwardmost three columns of
				# skin inside hand rows39..49. It is NOT optimized per key placement.
				if y <= 49: tip_right = maxi(tip_right, x)
	var hand_on_key := 0
	var tips := 0
	var tips_on_key := 0
	var tips_on_outline := 0
	var tip_contour: Array[Vector2i] = []
	var outside_top := 0
	var key_outline := Rect2i(key_origin + NEW_KEY_OUTLINE.position, NEW_KEY_OUTLINE.size)
	for point: Vector2i in hands:
		var world_point := actor_origin + point
		if key_bed.has_point(world_point): hand_on_key += 1
		if not top.has_point(world_point): outside_top += 1
		if point.y <= 49 and point.x >= tip_right - 2:
			tips += 1
			if key_bed.has_point(world_point): tips_on_key += 1
			if key_outline.has_point(world_point): tips_on_outline += 1
			if not tip_contour.has(point): tip_contour.append(point)
			# Include only actual immediate east-side outline pixels adjacent to
			# inferred skin tips. Never extend/repaint an arm to meet the keyboard.
			for dy: int in range(-1, 2):
				var edge := point + Vector2i(1, dy)
				if edge.y <= 49 and opaque_at(source, edge) and not tip_contour.has(edge): tip_contour.append(edge)
	var tip_edge_on_key := 0
	var tip_edge_on_outline := 0
	var nearest_key_pixel := 999
	for point: Vector2i in tip_contour:
		var world_point := actor_origin + point
		if key_bed.has_point(world_point): tip_edge_on_key += 1
		if key_outline.has_point(world_point): tip_edge_on_outline += 1
		for y: int in range(NEW_KEY_OUTLINE.position.y, NEW_KEY_OUTLINE.end.y):
			for x: int in range(NEW_KEY_OUTLINE.position.x, NEW_KEY_OUTLINE.end.x):
				if opaque_at(station.keyboard_image, Vector2i(x, y)):
					var delta := (key_origin + Vector2i(x, y) - world_point).abs()
					nearest_key_pixel = mini(nearest_key_pixel, maxi(delta.x, delta.y))
	var head_key := 0
	var face_key := 0
	var head_near_key := 0
	var face_near_key := 0
	for points: Array[Vector2i] in [head, face]:
		var is_head: bool = points == head
		for point: Vector2i in points:
			var local := point - key_origin
			if opaque_at(station.keyboard_image, local):
				if is_head: head_key += 1
				else: face_key += 1
			var near := false
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if opaque_at(station.keyboard_image, local + Vector2i(dx, dy)): near = true
			if near:
				if is_head: head_near_key += 1
				else: face_near_key += 1
	var keyboard_monitor_overlap := 0
	var mouse_monitor_overlap := 0
	var keyboard_mouse_overlap := 0
	for y: int in range(224):
		for x: int in range(192):
			var point := Vector2i(x, y)
			if opaque_at(station.keyboard_image, point):
				if opaque_at(station.monitor_image, point + Vector2i(shift, 0)): keyboard_monitor_overlap += 1
				if opaque_at(station.mouse_image, point): keyboard_mouse_overlap += 1
			if opaque_at(station.mouse_image, point) and opaque_at(station.monitor_image, point + Vector2i(shift, 0)): mouse_monitor_overlap += 1
	var result := {"key_shift_x": shift, "hand_samples": hands.size(), "hand_on_keybed": hand_on_key, "fingertip_inference_rightmost_source_x": tip_right, "fingertip_samples": tips, "fingertips_on_keybed": tips_on_key, "fingertips_on_key_outline": tips_on_outline, "hand_outside_tabletop": outside_top, "head_keyboard_projection_overlap": head_key, "face_keyboard_projection_overlap": face_key, "head_pixels_within_one_px_of_keyboard": head_near_key, "face_pixels_within_one_px_of_keyboard": face_near_key, "keyboard_monitor_opaque_overlap": keyboard_monitor_overlap, "mouse_monitor_opaque_overlap": mouse_monitor_overlap, "keyboard_mouse_opaque_overlap": keyboard_mouse_overlap, "keyboard_inside_top": top.encloses(key_outline), "mouse_inside_top": top.encloses(Rect2i(key_origin + Vector2i(81, 149), Vector2i(9, 6))), "monitor_keyboard_bbox_empty_columns": 99 - (81 + shift + 9)}
	result.merge({"fingertip_source_contour_pixels": tip_contour.size(), "fingertip_contour_on_keybed": tip_edge_on_key, "fingertip_contour_on_key_outline": tip_edge_on_outline, "nearest_fingertip_contour_to_key_pixel_chebyshev": nearest_key_pixel, "empty_pixels_between_nearest_fingertip_contour_and_key": maxi(0, nearest_key_pixel - 1)})
	placement_cache[cache_key] = result
	return result

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var result := super.metrics(station, frame)
	if not station.has("key_shift"): return result
	var placement := measure_placement(station, frame, station.key_shift)
	result.hand_pixels_over_key_bed = placement.hand_on_keybed
	result.hand_pixels_over_short_key_bed = placement.hand_on_keybed
	result.merge(placement)
	return result

func set_frame(frame: int, mode: String = "native") -> void:
	super.set_frame(frame, mode)
	for station: Dictionary in stations:
		var actual_shift: int = 0 if mode == "baseline" else station.key_shift
		# Sprite centers retain canvas/2 - pivot = (0,-48), not the host pivot.
		station.keyboard.position = station.anchor + Vector2(actual_shift, -48)
		station.mouse.position = station.anchor + Vector2(actual_shift, -48)
		var result := measure_placement(station, frame, actual_shift)
		station.label.text = "%s · keyboard X+%d\nTips %d/%d · face overlap %d" % ["Mina" if station.id == "mira" else "Theo", actual_shift, result.fingertips_on_keybed, result.fingertip_samples, result.face_keyboard_projection_overlap]

func validate_ui() -> void:
	super.validate_ui()
	for station: Dictionary in stations:
		var actual_shift := int(station.keyboard.position.x - station.anchor.x)
		check(station.keyboard.position - Vector2(96, 112) == station.anchor - KIT_PIVOT + Vector2(actual_shift, 0), "Rendered keyboard top-left equals measured full-canvas origin")
		check(station.mouse.position == station.keyboard.position, "Mouse and keyboard use identical translation and registered pivot")
		check(station.monitor.position == station.anchor + Vector2(0, -48), "Monitor sprite center stays at its original registered position")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Keyboard evidence is native1280x720")
	check(screenshot.save_png(PLACEMENT_OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.detail_bounds)
			crop.resize(512, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-key%d-4x.png" % [name_value, station.id, 0 if name_value.begins_with("baseline") else station.key_shift]
			# Baseline has three identical station variants; keep one per actor.
			if path in captures: continue
			check(crop.save_png(PLACEMENT_OUTPUT.path_join(path)) == OK, "Save contact detail " + path)
			captures.append(path)
	print("East keyboard placement: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PLACEMENT_OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			validate_source_reunion(station, frame)
			var result := split_metrics(station, frame)
			result.baseline = measure_placement(station, frame, 0)
			placement_observations.append(result)
			check(result.keyboard_inside_top and result.mouse_inside_top, "Complete device bounds stay on the unchanged tabletop")
			check(result.keyboard_monitor_opaque_overlap == 0 and result.mouse_monitor_opaque_overlap == 0 and result.keyboard_mouse_opaque_overlap == 0, "Independently translated native devices never intersect")
			check(result.monitor_keyboard_bbox_empty_columns >= 1, "At least one empty column separates key and monitor bounding boxes")
			check(result.hand_outside_tabletop == 0 and result.sampled_hand_pixels_below_cut == 0, "Device experiment cannot change hands or actor layer ownership")
			check(result.fingertip_samples > 0 and result.hand_samples >= result.fingertip_samples, "Fingertip inference is a nonempty source-only subset, separate from whole hand reach")
			check(result.fingertip_source_contour_pixels >= result.fingertip_samples and result.nearest_fingertip_contour_to_key_pixel_chebyshev < 999, "Adjacent actual source outline is measured separately, not mistaken for skin or invented pixels")
			check(result.head_hidden_by_monitor == 0 and result.hip_band_minus_observed_seat == [0, 2], "Fixed monitor/head clearance and preferred support persist")
	set_frame(0)
	await frames()
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		set_frame(2, "baseline")
		await capture("baseline-frame2", true)
		for frame: int in range(6):
			set_frame(frame)
			await capture("native-frame%d" % frame, true)
		set_frame(2, "guides")
		await capture("guides-frame2")
		for tick: int in range(180):
			set_frame((tick / 15) % 2 if tick < 60 else 2 + ((tick - 60) / 6) % 4)
			await RenderingServer.frame_post_draw
	for station: Dictionary in stations:
		check(station.pose_image.get_data().hex_encode().sha256_text() == source_hashes[station.id], "Original actor pixels remain unchanged")
		for part: String in ["monitor", "keyboard", "mouse"]:
			check(station[part].texture.get_image().get_data().hex_encode().sha256_text() == device_hashes[part], "Source device pixels are unchanged: " + part)
	var file := FileAccess.open(PLACEMENT_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "dev_placement_comparison_not_runtime_approved", "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "captures": captures, "key_shifts": KEY_SHIFTS, "logical_work_pixel": [-32, 0], "chair_render_offset": [12, 0], "actor_y": {"mira": 3, "theo": 4}, "cut_row": 52, "fingertip_inference": "Source skin samples in x28..43/y39..49, forwardmost three occupied columns per frame; not authored fingertip segmentation", "face_roi": [24, 18, 20, 21], "head_roi": "All opaque pixels with sourceY<39", "production_or_source_art_changed": false, "diagnostic_motion_frames": 180, "source_pixel_hashes": source_hashes, "device_pixel_hashes": device_hashes, "observations": placement_observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("east_keyboard_placement: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
