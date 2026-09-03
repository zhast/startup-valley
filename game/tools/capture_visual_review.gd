extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const REVIEW_DIRECTORY := "res://tests/output/visual-review"

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_capture_office_stages")

func _capture_office_stages() -> void:
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_DIRECTORY))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create visual-review directory")
		quit(1)
		return

	var main := MAIN_SCENE.instantiate() as GameMain
	root.add_child(main)
	await _settle()
	var employees := main.room.placeholder_records()
	for hire_count: int in range(5):
		var stage_records: Array[EmployeeRecord] = []
		for index: int in range(mini(hire_count, employees.size())):
			stage_records.append(employees[index])
		main._spawn_employees(stage_records)
		main.room.set_hire_count(hire_count)
		main.job_panel.visible = false
		main.clock_panel.visible = false
		await _settle()
		if not await _capture("office-hires-%d" % hire_count):
			return

	main._spawn_employees(employees)
	main.room.set_hire_count(2)
	main.job_panel.visible = true
	main.clock_panel.visible = true
	main.job_panel.set_credential_status(true)
	main.job_panel.close_drawer(false)
	await _settle()
	if not await _capture("ui-team-rail"):
		return
	var mina := main.get_employee("mira")
	main.player.position = mina.position + Vector2(68.0, 0.0)
	await _settle()
	if not await _capture("ui-founder-hud"):
		return
	main.player.position = main.room.grid_to_world_position(main.room.player_spawn)
	await _settle()
	mina.memory_line = "Yesterday's customer notes point to one clear promise."
	mina._speech_visible = true
	mina.queue_redraw()
	await _settle()
	if not await _capture("ui-world-speech"):
		return
	mina._speech_visible = false
	mina.queue_redraw()
	main.job_panel.select_employee("mira")
	main.job_panel.show_chat_history("mira", [
		{"sender": "player", "content": "Can you turn customer interviews into the smallest useful launch plan?"},
		{"sender": "employee", "content": "Yes. I would group the pain points, pick one narrow promise, and write a one-week validation plan before we build."},
	])
	main.job_panel._tabs.current_tab = 0
	await _settle()
	if not await _capture("ui-chat"):
		return

	main.job_panel._tabs.current_tab = 1
	await _settle()
	if not await _capture("ui-work"):
		return

	main.job_panel.begin_job("review-job", "mira")
	main._job_employees["review-job"] = "mira"
	var started := WorkerEventRecord.new()
	started.type = &"job.started"
	main._on_job_event("review-job", started)
	var walk_frames := 0
	while not main.get_employee("mira").is_at_desk() and walk_frames < 180:
		main.get_employee("mira")._physics_process(1.0 / 60.0)
		walk_frames += 1
	var thinking := WorkerEventRecord.new()
	thinking.type = &"agent.thinking"
	thinking.summary = "Turning interview notes into a focused launch brief…"
	main._on_job_event("review-job", thinking)
	var tool := WorkerEventRecord.new()
	tool.type = &"tool.started"
	tool.tool = "write_file"
	tool.label = "Writing launch-brief.md"
	main._on_job_event("review-job", tool)
	var usage := WorkerEventRecord.new()
	usage.type = &"usage.updated"
	usage.input_tokens = 1842
	usage.output_tokens = 614
	usage.cost = 0.0198
	main.job_panel.on_job_event("review-job", usage)
	main.job_panel.select_employee("mira")
	main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-active"):
		return

	var approval := WorkerEventRecord.new()
	approval.type = &"approval.required"
	approval.approval_id = "approval-review"
	approval.action = "Publish the launch brief to the shared studio for Theo to review."
	main._on_job_event("review-job", approval)
	_advance_employee(main.get_employee("mira"), 45)
	await _settle()
	if not await _capture("ui-journal-approval"):
		return

	var completed := WorkerEventRecord.new()
	completed.type = &"job.completed"
	completed.summary = "Launch brief complete with a focused promise, interview evidence, and a one-week validation plan."
	main.get_employee("mira").apply_worker_event(completed, main.player.position)
	main.job_panel.on_job_event("review-job", completed)
	main.job_panel.offer_promotion("review-job")
	main.job_panel.close_drawer(false)
	main.founder_hud.show_delivery("review-job", "mira", "Mina", "launch-brief.md ready")
	await _settle()
	if not await _capture("ui-completion-memo"):
		return
	main.job_panel.select_employee("mira")
	main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-promotion"):
		return

	var studio_file := StudioFileRecord.new()
	studio_file.name = "launch-brief.md"
	studio_file.relative_path = "launch-brief.md"
	studio_file.source_job_id = "review-job"
	main.job_panel.show_studio_files([studio_file])
	main.job_panel._tabs.current_tab = 3
	await _settle()
	if not await _capture("ui-studio"):
		return
	main.job_panel.show_studio_files([])
	await _settle()
	if not await _capture("ui-studio-empty"):
		return
	main.job_panel.show_studio_files([studio_file])
	await _settle()

	main.artifact_viewer.show_artifact(
		"launch-brief.md",
		"# Launch brief\n\n## Promise\nHelp first-time creators validate one paid offer in seven days.\n\n## Evidence\n- Five of eight interviews struggled to choose a narrow customer.\n- Buyers wanted a concrete launch checklist.\n\n## Next experiment\nPublish one landing page and book five follow-up calls."
	)
	await _settle()
	if not await _capture("ui-artifact"):
		return
	main.artifact_viewer.hide()
	main.job_panel._promotion_box.visible = false
	main.job_panel._approval_box.visible = false
	main.job_panel._event_log.clear()
	main._spawn_employees([])
	main.room.set_hire_count(0)
	main.job_panel._tabs.current_tab = 0
	await _settle()
	if not await _capture("ui-empty-team"):
		return

	main._spawn_employees(employees)
	main.room.set_hire_count(2)
	main.day_clock.set_time(1, DayClock.WORK_END)
	main.job_panel.select_employee("mira")
	main.job_panel._tabs.current_tab = 1
	await _settle()
	if not await _capture("ui-off-hours"):
		return

	main.job_panel.begin_job("queued-review", "theo")
	main.job_panel.mark_job_queued("queued-review")
	main.job_panel.select_employee("theo")
	main.job_panel._tabs.current_tab = 2
	await _settle()
	if not await _capture("ui-journal-queued"):
		return

	main._on_worker_crashed("The worker disconnected")
	await _settle()
	if not await _capture("ui-error"):
		return
	quit()

func _capture(name_value: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [REVIEW_DIRECTORY, name_value]
	var save_error := image.save_png(path)
	if save_error != OK:
		push_error("Could not save %s" % path)
		quit(1)
		return false
	print("visual review captured: %s" % name_value)
	return true

func _settle(frame_count: int = 5) -> void:
	for frame: int in range(frame_count):
		await process_frame

func _advance_employee(employee: EmployeeAvatar, frame_count: int) -> void:
	for frame: int in range(frame_count):
		employee._physics_process(1.0 / 60.0)
