extends SceneTree

const MAIN := preload("res://world/main.tscn")

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	call_deferred("_run")

func _run() -> void:
	# The launcher must supply an isolated data directory through its Node wrapper.
	if not OS.get_environment("STARTUP_VALLEY_STARTUP_TEST").is_valid_int():
		push_error("Use the disposable live-startup test launcher")
		quit(1)
		return
	var game: GameMain = MAIN.instantiate()
	root.add_child(game)
	var deadline := Time.get_ticks_msec() + 15000
	while not game._state_loaded and Time.get_ticks_msec() < deadline:
		await process_frame
	var ok := game._state_loaded and game._worker_ready and game.company_panel != null
	if ok:
		ok = game.company_panel.visible and game.company_panel.screen == "title" and game._employees.is_empty()
	if ok:
		print("LIVE STARTUP PASS: production GameMain + real worker + founder-only title")
	else:
		push_error("Production startup did not reach the founder-only title")
	# Main's normal exit handler waits for a durable save and closes worker stdin.
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await create_timer(1.0).timeout
	quit(0 if ok else 1)
