extends SceneTree
## Native-window, worker-free UI playtest. No credential, save or provider path.
## godot --path game --script res://tools/play_ui_redesign.gd

var main: GameMain
const DOCUMENT := "# A clear first offer\n\nOne useful page for one audience. **Readable evidence**, *small experiments*, and `site/index.html`.\n\n## Next steps\n\n- Say who the offer helps.\n- Show the result and one clear call to action.\n\n```css\n.offer { color: #151515; }\n```\n\n"

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func run() -> void:
	root.title = "Startup Valley — UI playtest (worker disabled)"
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	current_scene = main # Explicit native-entry opt-in; capture fixtures omit this.
	await process_frame
	var panel := main.job_panel
	for signal_name: String in ["key_submitted", "chat_history_requested", "chat_submitted", "assignment_submitted", "cancel_requested", "steer_submitted", "approval_decided", "artifact_open_requested", "artifact_refresh_requested", "studio_open_requested", "promotion_decided"]:
		for connection: Dictionary in panel.get_signal_connection_list(signal_name):
			panel.disconnect(signal_name, connection.callable)
	for connection: Dictionary in main.company_panel.get_signal_connection_list("action_requested"):
		main.company_panel.disconnect("action_requested", connection.callable)
	main.company_panel.action_requested.connect(func(_method: String, _params: Dictionary) -> void:
		main.company_panel.show_error("Read-only UI preview — no company state was changed.")
	)
	panel.chat_submitted.connect(func(employee_id: String, _copy: String) -> void:
		panel.show_chat_reply(employee_id, {"sender": "employee", "content": "Let's start with one **clear offer**, one audience, and one useful next step. This is a local UI preview; no AI request was made."}, 0)
	)
	panel.chat_history_requested.connect(func(employee_id: String) -> void:
		panel.show_chat_history(employee_id, [{"sender": "player", "content": "What should we build first?"}, {"sender": "employee", "content": "Start with one **clear offer**, one audience, and one action. We can turn that into a small work order."}])
	)
	panel.assignment_submitted.connect(func(_id: String, _title: String, _assignment: String, _criteria: PackedStringArray, _attachment: String) -> void:
		panel.set_info("Local UI preview: this draft was not sent to a worker.")
	)
	panel.studio_open_requested.connect(func(path: String) -> void:
		main.artifact_viewer.show_artifact(path, DOCUMENT.repeat(16), "Shared Studio")
	)
	panel.set_credential_status(true)
	panel.set_worker_ready()
	main.game_audio.set_volumes(0, 0)
	main.founder_hud.dismiss_movement_hint()
	main._on_journey({"company": {"cashCents": 30000, "earnedCents": 60000, "reputation": 10, "chapter": 1},
		"candidates": [{"id": "mira", "name": "Mina", "role": "Product + research", "hired": true}, {"id": "theo", "name": "Theo", "role": "Growth + operations", "hired": true}],
		"milestones": [{"id": "website", "title": "Build a website", "employeeId": "mira", "state": "available", "files": ["site/index.html", "site/styles.css"], "rewardCents": 60000, "reputation": 10}],
		"player": {"movementSeen": true}})
	var file := StudioFileRecord.new()
	file.name = "A clear first offer"
	file.relative_path = "briefs/a-clear-first-offer-and-a-one-week-validation-plan.md"
	file.media_type = "text/markdown"
	file.source_job_id = "ui-preview"
	panel.show_studio_files([file])
	panel.open_chat_for_employee("mira")
