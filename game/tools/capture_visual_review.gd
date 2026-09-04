extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const REVIEW_DIRECTORY := "res://tests/output/visual-review"

var _main: GameMain

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_DIRECTORY))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create visual-review directory")
		quit(1)
		return

	# Every image starts with a new GameMain. Visual fixtures must never inherit a
	# prior job, notification, clock, employee, or connection state.
	for hire_count: int in range(5):
		await _fresh_main(hire_count)
		_main.job_panel.visible = false
		_main.clock_panel.visible = false
		_main.founder_hud.visible = false
		await _settle(30)
		if not await _capture("office-hires-%d" % hire_count):
			return

	await _fresh_main(2)
	if not await _capture("ui-team-rail"):
		return

	await _fresh_main(2, true)
	var mina := _main.get_employee("mira")
	_main.player.position = mina.position + Vector2(68.0, 0.0)
	_main.player._physics_process(0.0)
	_main._process(0.0)
	await _settle()
	if not await _capture("ui-founder-hud"):
		return

	await _fresh_main(2)
	mina = _main.get_employee("mira")
	mina.memory_line = "Yesterday's customer notes point to one clear promise."
	mina._speech_visible = true
	mina.queue_redraw()
	await _settle()
	if not await _capture("ui-world-speech"):
		return

	await _fresh_main(2)
	_show_sample_chat(false)
	await _settle()
	if not await _capture("ui-chat"):
		return

	await _fresh_main(2)
	_show_sample_chat(true)
	await _settle()
	if not await _capture("ui-chat-long"):
		return

	await _fresh_main(2)
	_show_sample_chat(false)
	_main.job_panel._make_last_chat_a_job()
	await _settle()
	if not await _capture("ui-chat-to-assignment"):
		return

	await _fresh_main(2)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 1
	await _settle()
	if not await _capture("ui-work"):
		return

	await _fresh_main(2)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 1
	_main.job_panel._job_picker.select(_main.job_panel.CANNED_JOBS.size())
	_main.job_panel._on_job_selected(_main.job_panel.CANNED_JOBS.size())
	_main.job_panel._custom_title_input.text = "One-week launch plan"
	_main.job_panel._assignment_preview.text = "Create a concise launch plan with a promise, evidence, and next experiment."
	_main.job_panel._custom_title_input.grab_focus()
	await _settle()
	if not await _capture("ui-keyboard-focus"):
		return

	await _fresh_main(2)
	_setup_active_job("review-job", "mira")
	var thinking := WorkerEventRecord.new()
	thinking.type = &"agent.thinking"
	thinking.summary = "Turning interview notes into a focused launch brief…"
	_main._on_job_event("review-job", thinking)
	var tool := WorkerEventRecord.new()
	tool.type = &"tool.started"
	tool.tool = "write_file"
	tool.label = "Writing launch-brief.md"
	_main._on_job_event("review-job", tool)
	var usage := WorkerEventRecord.new()
	usage.type = &"usage.updated"
	usage.input_tokens = 1842
	usage.output_tokens = 614
	usage.cost = 0.0198
	_main.job_panel.on_job_event("review-job", usage)
	_main.job_panel.set_spend(usage.cost, 5.0)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-active"):
		return

	await _fresh_main(2)
	_setup_active_job("active-chat", "mira")
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 0
	await _settle()
	if not await _capture("ui-chat-active-readonly"):
		return

	await _fresh_main(2)
	_setup_active_job("approval-job", "mira")
	var approval := WorkerEventRecord.new()
	approval.type = &"approval.required"
	approval.approval_id = "approval-review"
	approval.action = "Publish the launch brief to the shared Studio for Theo to review."
	_main._on_job_event("approval-job", approval)
	_advance_employee(_main.get_employee("mira"), 45)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-approval"):
		return

	await _fresh_main(2)
	_show_completion("completion-job")
	_main.job_panel.close_drawer(false)
	await create_timer(0.25).timeout
	if not await _capture("ui-completion-memo"):
		return

	await _fresh_main(2)
	_show_completion("promotion-job")
	_main.founder_hud.hide_delivery()
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-promotion"):
		return

	await _fresh_main(2)
	_main.founder_hud.show_delivery("dismissed-job", "mira", "Mina", "launch-brief.md ready")
	_main.founder_hud.hide_delivery()
	await _settle()
	if not await _capture("ui-notification-dismissed"):
		return

	await _fresh_main(2)
	var studio_file := _sample_studio_file()
	_main.job_panel.show_studio_files([studio_file])
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 3
	await _settle()
	if not await _capture("ui-studio"):
		return

	await _fresh_main(2)
	_main.job_panel.show_studio_files([])
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 3
	await _settle()
	if not await _capture("ui-studio-empty"):
		return

	await _fresh_main(2)
	_main.artifact_viewer.show_artifact("launch-brief.md", _sample_artifact())
	await _settle()
	if not await _capture("ui-artifact"):
		return

	await _fresh_main(0)
	_main.job_panel.open_drawer(false)
	await _settle()
	if not await _capture("ui-empty-team"):
		return

	await _fresh_main(2)
	_main.day_clock.set_time(1, DayClock.WORK_END)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 1
	await _settle()
	if not await _capture("ui-off-hours"):
		return

	await _fresh_main(2)
	_main.day_clock.set_time(1, DayClock.WORK_END)
	_main.job_panel._custom_title_input.text = "Tomorrow's launch brief"
	_main.job_panel.begin_job("queued-review", "theo")
	_main.job_panel.accept_submission("queued-review")
	var queued := WorkerEventRecord.new()
	queued.type = &"job.queued"
	_main.job_panel.on_job_event("queued-review", queued)
	_main.job_panel.mark_job_queued("queued-review")
	_main.job_panel.select_employee("theo")
	_main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-queued"):
		return

	await _fresh_main(2)
	_main.job_panel.set_credential_status(false)
	await _settle()
	if not await _capture("ui-connect"):
		return

	await _fresh_main(2)
	_main.job_panel.set_worker_connection_error("The local worker stopped responding. Reconnect to resume your saved work.")
	_main.job_panel._open_connection_settings()
	await _settle()
	if not await _capture("ui-error"):
		return

	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		await create_timer(0.05).timeout
		root.remove_child(_main)
		_main.free()
	print("visual review captured with isolated fixtures")
	quit()

func _fresh_main(hire_count: int, keep_movement_hint: bool = false) -> void:
	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		await create_timer(0.05).timeout
		root.remove_child(_main)
		_main.free()
		await _settle(2)
	_main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(_main)
	await _settle(5)
	_disconnect_worker_actions()
	_main.day_clock.set_speed(0.0)
	_main.day_clock.set_time(1, DayClock.WORK_START)
	var records := _main.room.placeholder_records()
	var visible_records: Array[EmployeeRecord] = []
	for index: int in range(mini(hire_count, records.size())):
		visible_records.append(records[index])
	_main._spawn_employees(visible_records)
	_main.room.set_hire_count(hire_count)
	_main.player.position = _main.room.grid_to_world_position(_main.room.player_spawn)
	_main.player._physics_process(0.0)
	_main.job_panel.visible = true
	_main.clock_panel.visible = true
	_main.job_panel.set_credential_status(true)
	_main.job_panel.set_worker_ready()
	_main.job_panel.close_drawer(false)
	_main.artifact_viewer.hide()
	_main.founder_hud.hide_delivery()
	if not keep_movement_hint:
		_main.founder_hud.dismiss_movement_hint()
	await _settle(5)

func _disconnect_worker_actions() -> void:
	_disconnect_if_connected(_main.job_panel.key_submitted, Callable(_main.worker_client, "save_openrouter_key"))
	_disconnect_if_connected(_main.job_panel.chat_history_requested, Callable(_main.worker_client, "request_chat_history"))
	_disconnect_if_connected(_main.job_panel.chat_submitted, Callable(_main.worker_client, "send_chat"))
	_disconnect_if_connected(_main.job_panel.cancel_requested, Callable(_main.worker_client, "cancel_job"))
	_disconnect_if_connected(_main.job_panel.steer_submitted, Callable(_main.worker_client, "steer_job"))
	_disconnect_if_connected(_main.job_panel.approval_decided, Callable(_main.worker_client, "approve"))
	_disconnect_if_connected(_main.job_panel.artifact_refresh_requested, Callable(_main.worker_client, "request_artifacts"))
	_disconnect_if_connected(_main.job_panel.artifact_open_requested, Callable(_main.worker_client, "read_artifact"))
	_disconnect_if_connected(_main.job_panel.studio_open_requested, Callable(_main.worker_client, "read_studio_file"))
	_disconnect_if_connected(_main.job_panel.promotion_decided, Callable(_main.worker_client, "promote_job"))

func _disconnect_if_connected(signal_value: Signal, callable: Callable) -> void:
	if signal_value.is_connected(callable):
		signal_value.disconnect(callable)

func _show_sample_chat(long_history: bool) -> void:
	_main.job_panel.select_employee("mira")
	var messages: Array[Dictionary] = [
		{"sender": "player", "content": "Can you turn customer interviews into the smallest useful launch plan?"},
		{"sender": "employee", "content": "Yes. I would group the pain points, pick one narrow promise, and write a one-week validation plan before we build."},
	]
	if long_history:
		messages = []
		for index: int in range(10):
			messages.append({"sender": "player", "content": "Founder note %d: keep the launch focused and testable." % (index + 1)})
			messages.append({"sender": "employee", "content": "Mina reply %d: I’ll turn that into one concrete decision and next step." % (index + 1)})
	_main.job_panel.show_chat_history("mira", messages)
	_main.job_panel._tabs.current_tab = 0

func _setup_active_job(job_id: String, employee_id: String) -> void:
	_main._job_employees[job_id] = employee_id
	_main.job_panel._custom_title_input.text = "Launch brief"
	_main.job_panel.begin_job(job_id, employee_id)
	_main.job_panel.accept_submission(job_id)
	var started := WorkerEventRecord.new()
	started.type = &"job.started"
	_main._on_job_event(job_id, started)

func _show_completion(job_id: String) -> void:
	_main._job_employees[job_id] = "mira"
	_main.job_panel._custom_title_input.text = "Launch brief"
	_main.job_panel.begin_job(job_id, "mira")
	_main.job_panel.accept_submission(job_id)
	var completed := WorkerEventRecord.new()
	completed.type = &"job.completed"
	completed.summary = "Launch brief complete with a focused promise, interview evidence, and a one-week validation plan."
	_main.get_employee("mira").apply_worker_event(completed, _main.player.position)
	_main.job_panel.on_job_event(job_id, completed)
	var brief := ArtifactRecord.new()
	brief.artifact_id = job_id + "-brief"
	brief.name = "Launch brief"
	brief.relative_path = "launch-brief.md"
	_main.job_panel.show_artifacts(job_id, [brief])
	_main.job_panel.offer_promotion(job_id, "mira")
	_main.founder_hud.show_delivery(job_id, "mira", "Mina", "launch-brief.md ready")

func _sample_studio_file() -> StudioFileRecord:
	var studio_file := StudioFileRecord.new()
	studio_file.name = "launch-brief.md"
	studio_file.relative_path = "launch-brief.md"
	studio_file.source_job_id = "review-job"
	return studio_file

func _sample_artifact() -> String:
	return "# Launch brief\n\n## Promise\nHelp first-time creators validate one paid offer in seven days.\n\n## Evidence\n- Five of eight interviews struggled to choose a narrow customer.\n- Buyers wanted a concrete launch checklist.\n\n## Next experiment\nPublish one landing page and book five follow-up calls.\n\n```text\nOwner: Mina\nWindow: 7 days\n```"

func _capture(name_value: String) -> bool:
	# A frame count is not elapsed time on fast/uncapped renderers. Let the
	# longest UI entrance (180ms) finish before judging static text contrast.
	await create_timer(0.22).timeout
	await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [REVIEW_DIRECTORY, name_value]
	var save_error := image.save_png(path)
	if save_error != OK:
		push_error("Could not save %s" % path)
		quit(1)
		return false
	print("visual review captured: %s" % name_value)
	return true

func _settle(frame_count: int = 15) -> void:
	for frame: int in range(frame_count):
		await process_frame

func _advance_employee(employee: EmployeeAvatar, frame_count: int) -> void:
	for frame: int in range(frame_count):
		employee._physics_process(1.0 / 60.0)
