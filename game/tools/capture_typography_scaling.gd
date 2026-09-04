extends "res://tools/capture_visual_review.gd"
## Disposable production UI fixtures at actual window sizes; no worker or saves.
## --skip-fullscreen leaves fullscreen untested. --validate-only checks helpers.

const OUTPUT := "res://tests/output/typography-scaling"
const LOGICAL_SIZE := Vector2i(1280, 720)
const UI_RECT := Rect2(784, 0, 496, 720)
const VARIANTS: Array[Dictionary] = [
	{"id": "native-1280x720", "size": Vector2i(1280, 720)},
	{"id": "fractional-1600x900", "size": Vector2i(1600, 900)},
	{"id": "integer-2560x1440", "size": Vector2i(2560, 1440)},
	{"id": "letterbox-1440x1000", "size": Vector2i(1440, 1000)},
	{"id": "fullscreen-display", "fullscreen": true},
]
var _checks := 0
var _failures: Array[String] = []
var _variants: Array[Dictionary] = []
var _reference_geometry: Dictionary = {}

func _run() -> void:
	if "--validate-only" in OS.get_cmdline_user_args():
		_validate_math()
		print("Typography scaling helper: %d checks, %d failures" % [_checks, _failures.size()])
		quit(_failures.size())
		return
	if DisplayServer.get_name() == "headless":
		push_error("Raster/window evidence needs a normal renderer; use --validate-only for helper checks.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var original_size := root.size
	var original_position := root.position
	var original_mode := root.mode
	root.content_scale_size = LOGICAL_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	for variant: Dictionary in VARIANTS:
		if bool(variant.get("fullscreen", false)) and "--skip-fullscreen" in OS.get_cmdline_user_args():
			_variants.append({"id": variant.id, "skipped": true, "reason": "Explicit --skip-fullscreen; no fullscreen claim."})
			continue
		await _capture_variant(variant)
		_write_manifest()
	root.mode = Window.MODE_WINDOWED
	await create_timer(0.25).timeout
	root.size = original_size
	root.position = original_position
	root.mode = original_mode
	await _settle(3)
	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		_main.free()
	_write_manifest()
	print("Typography scaling: %d checks, %d failures; %d variants" % [_checks, _failures.size(), _variants.size()])
	quit(_failures.size())

func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(description)
		push_error(description)

func _capture_variant(variant: Dictionary) -> void:
	await _fresh_main(2)
	_main.game_audio.shutdown()
	_main.day_clock.set_time(12, DayClock.WORK_START)
	_main.clock_panel.show_money_earned(123456.78)
	_show_sample_chat(false)
	await create_timer(0.3).timeout
	_freeze_processing(_main)
	await _configure_window(variant)
	var id: String = variant.id
	var transform := root.get_final_transform()
	var result := {
		"id": id,
		"requested_window": _v2(variant.get("size", DisplayServer.screen_get_size(root.current_screen))),
		"actual_window": _v2(root.size),
		"mode": root.mode,
		"display_scale": DisplayServer.screen_get_max_scale(),
		"display_size": _v2(DisplayServer.screen_get_size(root.current_screen)),
		"logical_visible_rect": _rect(root.get_visible_rect()),
		"content_rect_window_pixels": _rect(transform * Rect2(Vector2.ZERO, Vector2(LOGICAL_SIZE))),
		"viewport_to_window": {"x": _v2(transform.x), "y": _v2(transform.y), "origin": _v2(transform.origin)},
		"integer_scale": is_equal_approx(transform.x.length(), roundf(transform.x.length())),
		"captures": [],
	}
	_check(is_equal_approx(transform.x.length(), transform.y.length()), id + ": aspect-preserving equal-axis scale")
	if bool(variant.get("fullscreen", false)):
		_check(root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN], id + ": entered actual fullscreen")
	else:
		_check(root.size == Vector2i(variant.size), id + ": requested physical window size accepted")
	var panel := _main.job_panel
	var player_start := _main.player.position
	await _window_click(panel._tab_buttons[1].get_global_rect().get_center())
	await create_timer(0.2).timeout
	_check(panel._tabs.current_tab == 1, id + ": physical-coordinate click selects Assign")
	await _window_click(panel._tab_buttons[0].get_global_rect().get_center())
	await create_timer(0.2).timeout
	_check(panel._tabs.current_tab == 0, id + ": physical-coordinate click returns to Chat")
	await _window_click(panel._chat_input.get_global_rect().get_center())
	_check(panel._chat_input.has_focus(), id + ": physical-coordinate click focuses composer")
	await _type_ascii("layout probe")
	_check(panel._chat_input.text == "layout probe", id + ": keyboard text reaches focused composer")
	panel._chat_input.clear()
	panel._chat_input.release_focus()
	_check(_main.player.position.is_equal_approx(player_start) and _main.player.route.is_empty(), id + ": UI clicks create no world route")
	await _move_pointer(Vector2(20, 120))
	await create_timer(0.25).timeout
	result["drawer_geometry"] = _geometry(false)
	_compare_geometry(id, result.drawer_geometry)
	result.captures.append(await _save_capture(id + "-drawer"))
	result["detail_crops"] = [
		_save_detail(id + "-hud-detail", _main.clock_panel.get_global_rect()),
		_save_detail(id + "-drawer-detail", UI_RECT),
	]
	result["stationary"] = await _stationary_probe(id)
	result["motion"] = await _motion_probe(id)
	var document := "# A useful first version\n\nA readable **launch brief** keeps *one promise* and `site/index.html` clear.\n\n## Customer evidence\n\n- Interview five creators.\n- Test a clear call to action.\n\n```html\n<main>会社の計画 · 产品验证 → résumé</main>\n```\n\n"
	var viewer := _main.artifact_viewer
	viewer.show_artifact("company/会社の計画—产品验证—résumé-launch-brief.md", document.repeat(5), "Shared Studio")
	await create_timer(0.25).timeout
	var scroll_before := viewer._content.get_v_scroll_bar().value
	for index: int in range(4): await _window_click(viewer._content.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	_check(viewer._content.get_v_scroll_bar().value > scroll_before, id + ": physical-coordinate wheel scrolls reader")
	await _window_click(viewer._close_button.get_global_rect().get_center())
	await create_timer(0.25).timeout
	_check(not viewer.visible, id + ": physical-coordinate close dismisses reader")
	viewer.show_artifact("company/会社の計画—产品验证—résumé-launch-brief.md", document.repeat(5), "Shared Studio")
	await create_timer(0.25).timeout
	_check(viewer._content.get_parsed_text().contains("会社の計画"), id + ": reopened reader retains actual Unicode content")
	_check(viewer.modal_fits_viewport(), id + ": reader remains inside logical viewport")
	await _move_pointer(Vector2(20, 120))
	result["reader_geometry"] = _geometry(true)
	result.captures.append(await _save_capture(id + "-reader"))
	result.detail_crops.append(_save_detail(id + "-reader-detail", Rect2(316, 60, 648, 320)))
	result["texture_size"] = _v2(root.get_texture().get_image().get_size())
	result["capture_includes_full_client"] = root.get_texture().get_image().get_size() == root.size
	_variants.append(result)
	print("Typography scaling captured: " + id)

func _configure_window(variant: Dictionary) -> void:
	root.mode = Window.MODE_WINDOWED
	await create_timer(0.25).timeout
	if bool(variant.get("fullscreen", false)):
		root.mode = Window.MODE_FULLSCREEN
		await create_timer(1.2).timeout # Native macOS fullscreen Space transition.
	else:
		root.size = Vector2i(variant.size)
		var usable := DisplayServer.screen_get_usable_rect(root.current_screen)
		root.position = usable.position + (usable.size - root.size) / 2
		await create_timer(0.35).timeout
	await _settle(4)

func _freeze_processing(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child: Node in node.get_children(): _freeze_processing(child)

func _window_click(logical_point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await _move_pointer(logical_point)
	var window_point := root.get_final_transform() * logical_point
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = window_point
		event.global_position = window_point
		event.button_index = button
		event.pressed = pressed
		root.push_input(event, false)
		await _settle(1)

func _move_pointer(logical_point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * logical_point
	motion.global_position = motion.position
	root.push_input(motion, false)
	await _settle(2)

func _type_ascii(value: String) -> void:
	for character: String in value:
		for pressed: bool in [true, false]:
			var event := InputEventKey.new()
			event.unicode = character.unicode_at(0)
			event.pressed = pressed
			root.push_input(event, false)
			await _settle(1)

func _save_capture(name_value: String) -> String:
	await _settle(2)
	RenderingServer.force_draw(false)
	var path := OUTPUT.path_join(name_value + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "Capture saved: " + name_value)
	return path

func _texture_transform() -> Transform2D:
	# Root texture is the rendered content only: Godot omits letterbox gutters.
	# Input uses the full window transform; texture crops must omit its offset.
	var value := root.get_final_transform()
	value.origin = Vector2.ZERO
	return value

func _save_detail(name_value: String, logical_rect: Rect2) -> String:
	var image := root.get_texture().get_image()
	var rectangle := Rect2i(_texture_transform() * logical_rect).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var path := OUTPUT.path_join(name_value + ".png")
	_check(image.get_region(rectangle).save_png(path) == OK, "Native-size detail crop saved: " + name_value)
	return path

func _stationary_probe(id: String) -> Dictionary:
	RenderingServer.force_draw(false)
	var first := root.get_texture().get_image()
	var baseline := first.get_data()
	var changed_frames := 0
	var hashes: Array[String] = [_image_hash(first)]
	for frame: int in range(12):
		await _settle(2)
		RenderingServer.force_draw(false)
		var current := root.get_texture().get_image()
		if current.get_data() != baseline: changed_frames += 1
		hashes.append(_image_hash(current))
	_check(changed_frames == 0, id + ": frozen stationary frames contain no temporal shimmer")
	return {"frames": 13, "interval_process_frames": 2, "changed_frames": changed_frames, "sha256": hashes, "world_processing_frozen": true, "note": "Checks shimmer at rest, not pixel-width regularity during fractional motion."}

func _motion_probe(id: String) -> Dictionary:
	var start := _main.player.position
	var hashes: Array[String] = []
	var steps: Array[int] = []
	var paths: Array[String] = []
	var ui_reference := PackedByteArray()
	var ui_changed := 0
	var previous_x := 0
	for frame: int in range(13):
		# Isolate sampling through integer logical translation with a frozen pose.
		# This does not claim to test autonomous navigation or locomotion.
		_main.player.position = start + Vector2(frame, 0)
		await _settle(2)
		RenderingServer.force_draw(false)
		var image := root.get_texture().get_image()
		hashes.append(_image_hash(image))
		var mapped_x := roundi((root.get_final_transform() * _main.player.position).x)
		if frame > 0: steps.append(mapped_x - previous_x)
		previous_x = mapped_x
		var ui_region := Rect2i(_texture_transform() * UI_RECT).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		var ui_bytes := image.get_region(ui_region).get_data()
		if frame == 0: ui_reference = ui_bytes
		elif ui_bytes != ui_reference: ui_changed += 1
		if frame in [0, 6, 12]:
			var path := OUTPUT.path_join("%s-motion-%02d.png" % [id, frame])
			_check(image.save_png(path) == OK, "Motion keyframe saved: " + path)
			paths.append(path)
	_main.player.position = start
	await _settle(2)
	_check(hashes[0] != hashes[12], id + ": translated founder produces distinct frames")
	_check(ui_changed == 0, id + ": UI remains stationary during founder translation")
	return {"frames": 13, "logical_step_pixels": 1, "rounded_physical_x_steps": steps, "sha256": hashes, "ui_changed_frames": ui_changed, "keyframes": paths, "note": "Frozen sprite translated in logical pixels, not a gameplay walk. Alternating physical widths are expected at fractional scale, not native-grid equivalence."}

func _geometry(reader: bool) -> Dictionary:
	var controls: Dictionary = {
		"day_value": _main.clock_panel._day_label,
		"time_value": _main.clock_panel._time_label,
		"earned_value": _main.clock_panel._earned_label,
		"day_caption": _main.clock_panel._day_caption,
		"chat_tab": _main.job_panel._tab_buttons[0],
		"assign_tab": _main.job_panel._tab_buttons[1],
		"chat_input": _main.job_panel._chat_input,
		"ask_button": _main.job_panel._chat_send_button,
	}
	if reader:
		controls["reader_title"] = _main.artifact_viewer._title_label
		controls["reader_content"] = _main.artifact_viewer._content
		controls["reader_close"] = _main.artifact_viewer._close_button
	var result := {}
	for key_value: String in controls:
		var control: Control = controls[key_value]
		result[key_value] = {"logical_rect": _rect(control.get_global_rect()), "window_rect": _rect(root.get_final_transform() * control.get_global_rect()), "texture_rect": _rect(_texture_transform() * control.get_global_rect()), "scale": _v2(control.scale)}
		if control is Label or control is Button or control is LineEdit:
			result[key_value]["font"] = control.get_theme_font("font").resource_path
			result[key_value]["font_size"] = control.get_theme_font_size("font_size")
	return result

func _compare_geometry(id: String, geometry: Dictionary) -> void:
	if _reference_geometry.is_empty():
		_reference_geometry = geometry.duplicate(true)
		return
	for key_value: String in geometry:
		_check(geometry[key_value].logical_rect == _reference_geometry[key_value].logical_rect, "%s: %s retains logical layout" % [id, key_value])
		if geometry[key_value].has("font_size"):
			_check(geometry[key_value].font_size == _reference_geometry[key_value].font_size, "%s: %s retains semantic font size" % [id, key_value])

func _image_hash(image: Image) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(image.get_data())
	return digest.finish().hex_encode()

func _v2(value: Vector2) -> Array:
	return [value.x, value.y]

func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

func _validate_math() -> void:
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(2560, 1440), Vector2i(1440, 1000)]:
		var scale := minf(float(size.x) / LOGICAL_SIZE.x, float(size.y) / LOGICAL_SIZE.y)
		var offset := (Vector2(size) - Vector2(LOGICAL_SIZE) * scale) * 0.5
		var mapping := Transform2D(Vector2(scale, 0), Vector2(0, scale), offset)
		var point := Vector2(1040, 640)
		_check((mapping.affine_inverse() * (mapping * point)).is_equal_approx(point), "Input round trip: %s" % size)
		_check(Rect2(Vector2.ZERO, Vector2(size)).encloses(mapping * Rect2(Vector2.ZERO, Vector2(LOGICAL_SIZE))), "Aspect-kept content fits: %s" % size)

func _write_manifest() -> void:
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"worker_disabled": true, "production_typography": true,
		"production_window_policy_changed": false, "save_access": false,
		"logical_size": _v2(LOGICAL_SIZE), "checks": _checks, "failures": _failures, "variants": _variants,
		"limitations": [
			"Viewport PNGs show game-client rendering, not OS chrome or hardware screenshots.",
			"Godot viewport textures omit outer aspect-ratio gutters; their dimensions and positions are recorded from the actual window transform, but gutter appearance is not visible in these PNGs.",
			"Physical-coordinate events traverse viewport/GUI transforms, but are injected, not OS hardware clicks.",
			"Fractional scaling cannot preserve an exact native pixel grid; uneven physical pixel widths and motion steps are expected.",
			"Stationary samples freeze world processing; motion is an integer-logical-pixel sprite translation, not a complete locomotion test.",
			"Fullscreen uses the currently available display only; other displays and platform scaling remain untested."
		]
	}, "\t"))
	file.close()
