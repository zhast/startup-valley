extends SceneTree
## Dev-only regression: one real double-click may dispatch only one reconnect.

const MAIN := preload("res://world/main.tscn")
var _viewport: SubViewport
var _main: GameMain
var _checks := 0
var _failures: Array[String] = []
var _retry_dispatches := 0
var _settings_dispatches := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)

func _frames(count: int = 2) -> void:
	for frame: int in range(count):
		await process_frame

func _real_click(control: Control, double_click: bool = false) -> void:
	await process_frame
	_check(control.is_visible_in_tree(), "Real-pointer target is visible: " + control.name)
	var point := control.get_global_rect().get_center()
	_check(_viewport.get_visible_rect().has_point(point), "Real-pointer target is inside the native viewport: " + control.name)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	_viewport.push_input(motion, true)
	var click_count := 2 if double_click else 1
	for click_index: int in range(click_count):
		for pressed: bool in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			event.double_click = double_click and click_index == 1
			_viewport.push_input(event, true)
			await process_frame
	await _frames()

func _disconnect_signal(signal_value: Signal) -> void:
	for connection: Dictionary in signal_value.get_connections():
		signal_value.disconnect(connection.callable)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	_main = MAIN.instantiate()
	_viewport.add_child(_main)
	await _frames(4)
	_main.day_clock.set_speed(0)
	_main.worker_client.set_process(false)
	var panel := _main.job_panel
	_disconnect_signal(panel.worker_retry_requested)
	_disconnect_signal(panel.settings_requested)
	panel.worker_retry_requested.connect(func() -> void: _retry_dispatches += 1)
	panel.settings_requested.connect(func() -> void: _settings_dispatches += 1)
	panel.set_credential_status(true)
	panel.set_worker_ready()
	panel.set_worker_connection_error("Worker disconnected during the session.")
	panel._open_connection_settings()
	await _frames()
	_check(panel._settings_button.text == "Reconnect" and not panel._settings_button.disabled, "Offline rail offers one enabled Reconnect entry point")
	_check(panel._connection_retry_button.text == "Reconnect" and not panel._connection_retry_button.disabled, "Offline page offers one enabled retry action")

	await _real_click(panel._connection_retry_button, true)
	_check(_retry_dispatches == 1, "A real double-click dispatches exactly one reconnect request")
	_check(panel._connection_retry_pending, "Reconnect request remains explicitly pending")
	_check(panel._connection_retry_button.disabled and panel._key_status.text == "Reconnecting…", "Main recovery surface disables retry and shows progress")
	_check(panel._settings_button.text == "Linking…" and panel._settings_button.disabled, "Rail truthfully shows a non-actionable connecting state")
	_check(panel._settings_button.get_meta("cozy_variant", "") == "secondary", "Pending rail action no longer uses the urgent enabled texture")
	var rail_font := panel._settings_button.get_theme_font("font")
	var rail_font_size := panel._settings_button.get_theme_font_size("font_size")
	var rail_style := panel._settings_button.get_theme_stylebox("disabled")
	var rail_required_width := rail_font.get_string_size(panel._settings_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, rail_font_size).x \
		+ rail_style.get_content_margin(SIDE_LEFT) + rail_style.get_content_margin(SIDE_RIGHT)
	_check(rail_required_width <= panel._settings_button.size.x, "Pending rail caption and disabled-style margins fit its fixed button width")
	_check(not panel._connection_back_button.disabled, "Back to game remains usable while reconnecting")

	await _real_click(panel._connection_back_button)
	_check(not panel._connection_panel.visible, "Back to game closes the pending connection surface")
	await _real_click(panel._settings_button, true)
	_check(_retry_dispatches == 1 and not panel._connection_panel.visible, "Disabled rail ignores repeat real input without reopening or redispatching")

	panel.set_worker_connection_error("Reconnect failed; try again.")
	_check(not panel._connection_retry_pending and panel._settings_button.text == "Reconnect" and not panel._settings_button.disabled, "A terminal retry error restores the rail recovery action")
	panel.set_worker_ready()
	await _frames()
	_check(panel._settings_button.text == "Settings" and not panel._settings_button.disabled, "Recovery restores useful Settings access")
	_check(panel._settings_button.get_meta("cozy_variant", "") == "secondary", "Recovered Settings returns to the calm texture")
	_check(panel._settings_button.tooltip_text == "Open settings or connect AI", "Recovery clears the stale disconnect tooltip")
	await _real_click(panel._settings_button)
	_check(_settings_dispatches == 1, "Recovered Settings still dispatches through real pointer input")

	_main.queue_free()
	await _frames()
	if _failures.is_empty():
		print("Connection retry guard: %d checks, 0 failures" % _checks)
		quit(0)
	else:
		push_error("Connection retry guard: %d checks, %d failures" % [_checks, _failures.size()])
		quit(1)
