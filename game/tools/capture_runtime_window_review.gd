extends "res://tools/capture_typography_scaling.gd"
## Bounded current-production scaling review. Separate output; no fullscreen.
var CURRENT_OUTPUT := OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT").path_join("runtime-window-review") if not OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT").is_empty() else "res://tests/output/runtime-window-review"
const BLOCKED_FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const CASES: Array[Dictionary] = [
	{"id": "native", "size": Vector2i(1280, 720)},
	{"id": "integer2x", "size": Vector2i(2560, 1440)},
	{"id": "letterbox", "size": Vector2i(1600, 1000)},
]
var current_results: Array[Dictionary] = []
var reference_rects := {}

func _run() -> void:
	# Isolate this dev-only event stream from the user's physical pointer.
	# Native rendering and ordinary GUI hit-testing remain enabled.
	root.unfocusable = true
	root.mouse_passthrough = true
	if DisplayServer.get_name() == "headless":
		_validate_math()
		print("Runtime window math: %d checks, %d failures; rendered evidence not run" % [_checks, _failures.size()])
		quit(0 if _failures.is_empty() else 1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CURRENT_OUTPUT))
	var original_size := root.size
	var original_position := root.position
	root.content_scale_size = LOGICAL_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	for spec: Dictionary in CASES:
		await current_fixture()
		await _configure_window(spec)
		await current_case(spec)
	_main.game_audio.shutdown()
	_main.free()
	root.size = original_size
	root.position = original_position
	_check(current_results.size() == 3, "Every requested window case completed")
	var result := {"checks": _checks, "failures": _failures, "cases": current_results, "fullscreen_used": false, "worker_or_save_access": false, "production_changes": false, "input_isolation": "Unfocusable mouse-passthrough native window and injected GUI InputEvents; three bounded world-hover polling probes temporarily position and immediately restore the physical cursor, without physical clicks"}
	var file := FileAccess.open(CURRENT_OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print(JSON.stringify(result))
	quit(0 if _failures.is_empty() else 1)

func current_fixture() -> void:
	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		_main.free()
	_main = MAIN_SCENE.instantiate() as GameMain
	_main.get_node("WorkerClient").set_script(BLOCKED_FIXTURE.NullWorker)
	root.add_child(_main)
	await _settle(3)
	_main.job_panel._close_connection_settings()
	_main.job_panel.close_drawer(false)
	_main.day_clock.set_speed(0)
	_main.day_clock.set_time(12, DayClock.WORK_START)
	_main.clock_panel.show_money_earned(123456.78)
	_main.room.set_hire_count(4)
	_main.founder_hud.dismiss_movement_hint()
	_main.game_audio.set_volumes(0, 0)
	await _settle(3)
	_main._process(0)
	_freeze_processing(_main)
	_check(_main.worker_client._stdio == null and _main.worker_client._process_id == -1 and not _main._state_loaded, "Disposable native fixture has no worker or save state")

func pointer(logical: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * logical
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await _settle(2)
	_main._process(0)

func polled_world_pointer(logical: Vector2) -> Vector2:
	# Top-level Viewport.get_mouse_position polls DisplayServer, unlike GUI
	# hit-testing. Preserve that actual production check without pretending an
	# injected motion updates the physical cursor. Never warp during a drag.
	for tick: int in range(60):
		if DisplayServer.mouse_get_button_state() == 0: break
		await _settle(1)
	if DisplayServer.mouse_get_button_state() != 0:
		_check(false, "World cursor probe needs released physical mouse buttons")
		return root.get_mouse_position()
	var previous_screen := DisplayServer.mouse_get_position()
	root.warp_mouse(logical)
	await _settle(2)
	_main._process(0)
	var observed := root.get_mouse_position()
	_check(observed.distance_to(logical) < 1.0, "World cursor probe reaches the requested logical position")
	# The scene is frozen: its real computed hover remains available to inspect
	# after returning the user's cursor. No synthetic world-hover handler call.
	Input.warp_mouse(previous_screen)
	await _settle(2)
	_check(DisplayServer.mouse_get_position().distance_to(previous_screen) < 2.0, "World cursor probe restores the original screen position")
	return observed

func physical_click(logical: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await pointer(logical)
	var point := root.get_final_transform() * logical
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = button
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT and pressed else 0
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await _settle(2)

func save(name_value: String) -> String:
	await _settle(3)
	RenderingServer.force_draw(false)
	var path := CURRENT_OUTPUT.path_join(name_value + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "Save current window evidence " + name_value)
	var logical_detail := Rect2(64, 270, 220, 250)
	if name_value.ends_with("-drawer"): logical_detail = Rect2(782, 0, 498, 720)
	elif name_value.ends_with("-reader"): logical_detail = Rect2(316, 60, 648, 600)
	var texture_transform := root.get_final_transform()
	texture_transform.origin = Vector2.ZERO
	var detail_path := CURRENT_OUTPUT.path_join(name_value + "-detail.png")
	_check(root.get_texture().get_image().get_region(Rect2i(texture_transform * logical_detail)).save_png(detail_path) == OK, "Save actual-pixel detail " + name_value)
	return path

func current_geometry() -> Dictionary:
	var result := {"hud": _rect(_main.clock_panel.get_global_rect()), "rail": _rect(_main.job_panel.rail_global_rect()), "drawer": _rect(_main.job_panel.drawer_global_rect())}
	for id: String in _main._employees:
		var actor := _main.get_employee(id)
		_check(actor._character_sprite.scale == Vector2.ONE and actor._character_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Current actor remains native nearest-filtered")
		_check(actor._character_sprite.global_position == actor._character_sprite.global_position.round(), "Current actor painted transform is integer-snapped")
	for placement: Dictionary in _main.room.resolved_placements:
		var prop := _main.room.prop_node(str(placement.id))
		for layer: Dictionary in placement.render_layers:
			var sprite := prop.get_node(NodePath(str(layer.name))) as Sprite2D
			_check(sprite.scale == Vector2.ONE and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Current prop remains native nearest-filtered")
			_check(sprite.global_position == sprite.global_position.round(), "Current prop layer has integer logical translation")
	return result

func current_case(spec: Dictionary) -> void:
	var id := str(spec.id)
	_check(root.unfocusable and root.mouse_passthrough, id + ": native audit window retains isolated input after resizing")
	var transform := root.get_final_transform()
	var content := transform * Rect2(Vector2.ZERO, Vector2(LOGICAL_SIZE))
	_check(root.size == Vector2i(spec.size), id + ": actual controlled window accepted requested size")
	_check(is_equal_approx(transform.x.length(), transform.y.length()), id + ": scale remains aspect-preserving")
	_check(root.get_visible_rect().size == Vector2(LOGICAL_SIZE), id + ": logical composition remains1280×720")
	var polled_cursor := await polled_world_pointer(Vector2(128, 400))
	_check(_main.founder_hud.station_hover_target_id() == "artifact-archive", id + ": actual window cursor reaches native archive hover")
	var result := {"id": id, "window": _v2(root.size), "content_window_rect": _rect(content), "transform": {"x": _v2(transform.x), "y": _v2(transform.y), "origin": _v2(transform.origin)}, "actual_station_cursor": _v2(polled_cursor), "captures": []}
	var geometry := current_geometry()
	if reference_rects.is_empty(): reference_rects = geometry.duplicate(true)
	_check(geometry == reference_rects, id + ": current HUD/rail/drawer logical rectangles are identical across window sizes")
	result["geometry"] = geometry
	result.captures.append(await save(id + "-world-hover"))
	var image := root.get_texture().get_image()
	result["texture_size"] = _v2(image.get_size())
	result["full_client_texture"] = image.get_size() == root.size
	# Native world interior probes, not a blanket ban on legitimate charcoal art.
	var texture_transform := transform
	texture_transform.origin = Vector2.ZERO
	for point: Vector2 in [Vector2(32, 112), Vector2(1120, 112), Vector2(32, 640), Vector2(1120, 640), Vector2(576, 420)]:
		var color := image.get_pixelv(Vector2i(texture_transform * point))
		_check(color.r + color.g + color.b > 0.2, id + ": no exposed black world backdrop at " + str(point))
	var stationary_hashes: Array[String] = [_image_hash(image)]
	for tick: int in range(3):
		await _settle(2)
		RenderingServer.force_draw(false)
		stationary_hashes.append(_image_hash(root.get_texture().get_image()))
	_check(stationary_hashes.all(func(value: String) -> bool: return value == stationary_hashes[0]), id + ": frozen current world is stable at rest")
	result["stationary_hashes"] = stationary_hashes
	await physical_click(Vector2(128, 400))
	_check(_main._pending_interaction == "artifact-archive" and not _main.player.route.is_empty(), id + ": physical station click maps through window/letterbox transform")
	_main.player.cancel_route()
	var portrait := _main.job_panel._team_buttons["mira"]
	await physical_click(portrait.get_global_rect().get_center())
	await create_timer(0.22).timeout
	_main._process(0)
	_check(_main.job_panel.drawer_is_open() and _main.job_panel.selected_employee_id() == "mira", id + ": physical portrait click opens Mina")
	_check(_main.player.route.is_empty() and not _main.founder_hud.station_hover_rect().has_area(), id + ": UI click neither walks nor retains station hover")
	_check(_main.job_panel.drawer_global_rect() == Rect2(782, 0, 368, 720), id + ": settled open drawer preserves current contiguous rail frame")
	result["open_drawer_rect"] = _rect(_main.job_panel.drawer_global_rect())
	await pointer(Vector2(600, 420))
	result.captures.append(await save(id + "-drawer"))
	var document := "# Window scaling review\n\nA **clear promise** keeps *one useful next step* visible. This is local fixture text, not worker content.\n\n## Requirements\n\n- Keep the office whole.\n- Preserve native pixel artwork.\n- Keep fonts readable.\n\n```text\nsite/index.html\n会社の計画 · résumé\n```\n\n"
	_main.artifact_viewer.show_artifact("company/会社の計画—résumé.md", document.repeat(5), "Local fixture")
	await create_timer(0.22).timeout
	_main._process(0)
	_check(_main.artifact_viewer.modal_fits_viewport(), id + ": reader frame fits the same logical viewport")
	result["reader_geometry"] = _geometry(true)
	_compare_geometry(id, result.reader_geometry)
	result.captures.append(await save(id + "-reader"))
	var bar := _main.artifact_viewer._content.get_v_scroll_bar()
	var before := bar.value
	for tick: int in range(3): await physical_click(_main.artifact_viewer._content.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	_check(bar.value > before, id + ": physical wheel scroll reaches reader")
	await physical_click(_main.artifact_viewer._close_button.get_global_rect().get_center())
	await create_timer(0.22).timeout
	_check(not _main.artifact_viewer.visible, id + ": physical close hit matches modal at this scale")
	result["detail_crops"] = []
	for path: String in result.captures: result.detail_crops.append(path.trim_suffix(".png") + "-detail.png")
	current_results.append(result)
