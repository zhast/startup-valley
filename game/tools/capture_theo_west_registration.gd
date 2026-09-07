extends "res://tools/capture_west_supported_layers.gd"
## DEV-ONLY same-socket, same-cut comparison; original atlas and studies untouched.
const REG_OUTPUT := "res://tests/output/theo-west-registration"
const REG_ART := "res://tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered.png"
const REG_Y: Array[int] = [0, 0, -1, -1, -1, 0]
var registration_observations: Array[Dictionary] = []
var registration_hashes: Dictionary = {}
var native_frames: Array[Image] = []
var source_aware_cuts := false

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	height_normalized = true
	source_aware_cuts = "--source-aware-cuts" in OS.get_cmdline_user_args()
	output_path = REG_OUTPUT.path_join("source-aware-cuts") if source_aware_cuts else REG_OUTPUT
	seat_band = Rect2i(37, 97, 18, 2)
	call_deferred("run")

func build() -> void:
	super.build()
	(panels[0].get_child(0) as Label).text = "THEO WEST REGISTRATION · original above / translated below · same cut48 and socket"
	if source_aware_cuts:
		(panels[0].get_child(0) as Label).text = "THEO WEST REGISTRATION · original above / translated below · original layer ownership"
	(panels[1].get_child(0) as Label).text = "UNAPPROVED · source translation only · columns: assembled / exposed support / actor source"
	var original := texture(FIXTURES.path_join("characters/theo-west-seated-v3.png"))
	var registered := texture(REG_ART)
	for index: int in range(stations.size()):
		var station: Dictionary = stations[index]
		station.id = "theo"
		station.registered = index >= 3
		station.variant = "registered" if station.registered else "original"
		station.column = index % 3
		station.pose = registered if station.registered else original
		station.pose_image = station.pose.get_image()
		station.cut = 48
		station.actor_y = 8
		station.actor_foot = station.render_foot + Vector2(0, 8)
		station.guide.hip_rows = Vector2i(49, 51)
		station.guide.actor_y = 8
		station.guide.cut = 48
		station.actor.texture = station.pose
		station.upper.texture = station.pose
		station.lower.texture = station.pose
		registration_hashes[station.variant] = station.pose_image.get_data().hex_encode().sha256_text()
		check(station.cut == 48 and station.actor_foot - station.logical == Vector2(-12, 8), "Both variants retain exact Theo cut48/socket−12,+8")

func set_frame(frame: int, _mode: String = "native") -> void:
	for station: Dictionary in stations:
		station.cut = 48 + (REG_Y[frame] if source_aware_cuts and station.registered else 0)
	super.set_frame(frame)
	for station: Dictionary in stations:
		station.guide.hide()
		if station.column > 0:
			for part: String in ["desk", "monitor", "keyboard", "mouse"]: station[part].hide()
		if station.column == 2:
			station.chair_rear.hide()
			station.chair_near_arm.hide()
		station.label.text = "%s · frame%d · Y%+d\n%s" % [station.variant.capitalize(), frame, REG_Y[frame] if station.registered else 0, ["Assembled · cut%d" % station.cut, "Exposed seat and legs", "Unchanged source pixels"][station.column]]

func registration_metrics(station: Dictionary, frame: int) -> Dictionary:
	var shift: int = REG_Y[frame] if station.registered else 0
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var origin := Vector2i(station.actor_foot - ACTOR_PIVOT)
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	var keys := Rect2i(Vector2i(station.anchor - KIT_PIVOT) + KEY_BED.position, KEY_BED.size)
	var hands := Rect2i(7, 39 + shift, 15, 9)
	var lap_start := 48 + shift
	var cut := 48 + (shift if source_aware_cuts else 0)
	var hand_count := 0
	var hand_keys := 0
	var hand_below := 0
	var foreground_lap := 0
	var lap_points: Array[Array] = []
	for y: int in range(80):
		for x: int in range(48):
			if source.get_pixel(x, y).a < 0.5: continue
			var point := origin + Vector2i(x, y)
			if hands.has_point(Vector2i(x, y)):
				hand_count += 1
				if keys.has_point(point): hand_keys += 1
				if y >= cut: hand_below += 1
			if y >= lap_start and y < cut and top.has_point(point):
				foreground_lap += 1
				lap_points.append([x, y])
	var used := source.get_used_rect()
	return {"variant": station.variant, "frame": frame, "translation_y": shift, "cut": cut, "actor_from_logical": [-12, 8], "hip_minus_seat": [shift, 2 + shift], "head_row": used.position.y, "sole_row": used.end.y - 1, "hand_region": [7, 39 + shift, 15, 9], "hand_roi_opaque": hand_count, "hand_roi_on_keys": hand_keys, "hand_roi_below_cut": hand_below, "translated_lap_start": lap_start, "foreground_lap_roi_pixels": foreground_lap, "foreground_lap_source_points": lap_points, "method": "Same manual ROI translated with source; source-aware cut=%s" % source_aware_cuts}

func capture_registration(frame: int) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Comparison remains native1280×720")
	var path := "frame%d.png" % frame
	check(screenshot.save_png(output_path.path_join(path)) == OK, "Save native comparison " + path)
	captures.append(path)
	native_frames.append(screenshot)
	for station: Dictionary in stations:
		var detail := screenshot.get_region(station.detail_bounds)
		detail.resize(512, 640, Image.INTERPOLATE_NEAREST)
		var detail_path := "frame%d-%s-%s-4x.png" % [frame, station.variant, ["assembly", "support", "source"][station.column]]
		check(detail.save_png(output_path.path_join(detail_path)) == OK, "Save nearest4× comparison detail")
		captures.append(detail_path)

func contacts() -> void:
	for column: int in range(3):
		var contact := Image.create(768, 320, false, Image.FORMAT_RGBA8)
		for frame: int in range(6):
			for row: int in range(2):
				var station: Dictionary = stations[row * 3 + column]
				contact.blit_rect(native_frames[frame], station.detail_bounds, Vector2i(frame * 128, row * 160))
		var path := "all-six-%s-native.png" % ["assembly", "support", "source"][column]
		check(contact.save_png(output_path.path_join(path)) == OK, "Save all-six native contact")
		captures.append(path)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path))
	build()
	for frame: int in range(6):
		set_frame(frame)
		for index: int in [0, 3]:
			var station: Dictionary = stations[index]
			validate_actor_reunion(station, frame)
			var result := registration_metrics(station, frame)
			registration_observations.append(result)
			check(result.hand_roi_below_cut == 0, "Source-aware hand region remains above unchanged cut")
			check(result.hip_minus_seat[0] >= -1 and result.hip_minus_seat[1] <= 2, "Measured support remains within original±one-pixel estimate")
			check(result.head_row == 4 if station.registered else result.head_row in [4, 5], "Actual head extent matches explicit registration")
			if source_aware_cuts:
				check(result.foreground_lap_roi_pixels == 0, "Translated original ownership keeps all lap pixels behind the top")
	set_frame(0)
	await frames()
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		for frame: int in range(6):
			set_frame(frame)
			await capture_registration(frame)
		contacts()
		for tick: int in range(210):
			var frame := (tick / 15) % 2 if tick < 60 or tick >= 180 else 2 + ((tick - 60) / 6) % 4
			set_frame(frame)
			await RenderingServer.frame_post_draw
	for station: Dictionary in stations:
		check(station.pose_image.get_data().hex_encode().sha256_text() == registration_hashes[station.variant], "Original/candidate pixels unchanged during capture")
	var file := FileAccess.open(output_path.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "worker_disabled": true, "production_changed": false, "status": "unapproved_registration_with_translated_ownership" if source_aware_cuts else "unapproved_same_socket_same_cut_registration_comparison", "registered_atlas": REG_ART, "frame_y_offsets": REG_Y, "registered_upper_cuts": [48, 48, 47, 47, 47, 48] if source_aware_cuts else [48, 48, 48, 48, 48, 48], "source_aware_cuts": source_aware_cuts, "actor_from_logical": [-12, 8], "chair_from_logical": [-12, 0], "chair_partition": "res://tools/calibration_west_chair_layers.gd", "captures": captures, "observations": registration_observations, "source_hashes": registration_hashes, "movie_sequence_frames": 210, "limitation": "Registration changes visible support by1px; exact per-frame cut ownership is explicit"}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("theo_west_registration_capture: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
