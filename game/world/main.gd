class_name GameMain
extends Node

const EMPLOYEE_SCENE: PackedScene = preload("res://actors/employee_avatar.tscn")
const OFFICE_RENOVATION_SCRIPT: Script = preload("res://ui/office_renovation.gd")

@onready var room: TownRoom = $TownRoom
@onready var player: PlayerAvatar = $PlayerAvatar
@onready var employee_container: Node2D = $Employees
@onready var worker_client: WorkerClient = $WorkerClient
@onready var job_panel: JobPanel = $Interface/JobPanel
@onready var artifact_viewer: ArtifactViewer = $Interface/ArtifactViewer
@onready var day_clock: DayClock = $DayClock
@onready var clock_panel: ClockPanel = $Interface/ClockPanel
@onready var founder_hud: FounderHud = $Interface/FounderHud

var _employees: Dictionary[String, EmployeeAvatar] = {}
var _job_employees: Dictionary[String, String] = {}
var _project_id: String = "company"
var _token_budget: int = 12000
var _worker_ready: bool = false
var _state_loaded: bool = false
var _job_artifact_names: Dictionary[String, String] = {}
var company_panel: CompanyPanel
var office_renovation: OfficeRenovation
var game_audio: GameAudio
var click_feedback: ClickFeedback
var _journey: Dictionary = {}
var _pending_interaction := ""
var _pending_kind := ""
var _save_elapsed := 0.0
var _footstep_elapsed := 0.0
var _closing_shown_day := -1
var _restored_player := false
var _quitting := false
var _save_acknowledged := false
var _was_drawer_open := false
var _updating_roster := false
var _studio_paths: PackedStringArray = []
var _pending_preview_html := ""
var _pending_preview_html_content := ""
var _pending_preview_css_path := ""

func _ready() -> void:
	_apply_initial_window_presentation.call_deferred()
	room.load_layout()
	player.position = room.grid_to_world_position(room.player_spawn)
	player.movement_bounds = room.playable_bounds()
	player.navigation = room.navigation
	room.navigation.passage_requested.connect(_yield_employee_passage)
	room.placements_changed.connect(_on_room_placements_changed)
	var initial_employees: Array[EmployeeRecord] = []
	if OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1":
		initial_employees = room.placeholder_records()
	_spawn_employees(initial_employees)
	company_panel = CompanyPanel.new()
	$Interface.add_child(company_panel)
	office_renovation = OFFICE_RENOVATION_SCRIPT.new() as OfficeRenovation
	office_renovation.name = "OfficeRenovation"
	office_renovation.game = self
	add_child(office_renovation)
	founder_hud.station_input_enabled = func() -> bool: return not player.input_blocked and not _world_paused()
	company_panel.action_requested.connect(worker_client.company_request)
	company_panel.milestone_requested.connect(job_panel.prepare_milestone)
	company_panel.connection_requested.connect(job_panel._open_connection_settings)
	company_panel.renovation_requested.connect(_open_office_renovation)
	company_panel.architecture_theme = room.architecture.theme_id
	company_panel.architecture_theme_requested.connect(_on_architecture_theme)
	job_panel.settings_requested.connect(func() -> void: company_panel.present("settings"))
	job_panel.journey_requested.connect(func() -> void:
		job_panel.close_drawer()
		company_panel.present("journey")
	)
	job_panel.worker_retry_requested.connect(_retry_worker_connection)
	game_audio = GameAudio.new()
	add_child(game_audio)
	company_panel.volume_changed.connect(game_audio.set_volumes)
	click_feedback = ClickFeedback.new()
	click_feedback.z_index = 2000
	add_child(click_feedback)
	player.destination_reached.connect(_on_destination_reached)
	_connect_signals()
	_on_clock_changed(day_clock.day, day_clock.minute_of_day, day_clock.phase, day_clock.speed)
	if OS.get_environment("STARTUP_VALLEY_NO_WORKER") != "1":
		get_tree().auto_accept_quit = false
		company_panel.present("title")
		worker_client.start()
	else:
		job_panel.set_worker_connection_error("Deterministic test mode — worker disabled")

func _apply_initial_window_presentation() -> void:
	# Only the actual entry scene opts in; isolated visual/gameplay fixtures do not.
	if get_tree().current_scene != self or Engine.is_editor_hint(): return
	var policy: Script = preload("res://ui/window_presentation.gd")
	var window := get_window()
	if not policy.should_adapt(OS.get_name(), DisplayServer.get_name(), window.mode, OS.get_cmdline_args()): return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var display_scale := DisplayServer.screen_get_max_scale()
	var decorations := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var rectangle: Rect2i = policy.initial_rect(usable, display_scale, decorations)
	if not rectangle.has_area(): return
	window.size = rectangle.size
	window.position = rectangle.position
	await get_tree().process_frame
	print("Window presentation: internal=1280x720 native=%dx%d display_scale=%.2f usable=%s" % [window.size.x, window.size.y, display_scale, usable])

func _process(delta: float) -> void:
	var paused := _world_paused()
	day_clock.ui_paused = paused
	player.input_blocked = paused
	if job_panel.drawer_is_open() != _was_drawer_open:
		_was_drawer_open = job_panel.drawer_is_open()
		game_audio.play("drawer")
	if paused:
		player.cancel_route()
		_pending_interaction = ""
	for employee: EmployeeAvatar in _employees.values():
		employee.world_paused = paused
	_save_elapsed += delta
	if _save_elapsed > 5.0 and _state_loaded:
		_save_elapsed = 0.0
		_save_game()
	if player.velocity.length() > 10 and not paused:
		founder_hud.notice_movement()
		_footstep_elapsed += delta
		if _footstep_elapsed > 0.28:
			_footstep_elapsed = 0.0
			game_audio.play("step")
	if not _pending_interaction.is_empty() and _pending_kind == "employee" and _employees.has(_pending_interaction) and not player.route.is_empty():
		var target := _employees[_pending_interaction].position
		if player.route[-1].distance_to(target) > 80:
			player.move_to(target + Vector2(0, 40))
	founder_hud.update_interaction(
		player.position,
		_employees,
		not paused,
		_world_ui_obstacles()
	)
	# Proximity/E remains valid even when crowded scenery hides the visual prompt.
	var interaction_target := founder_hud.interaction_target_id()
	var hovered_control := get_viewport().gui_get_hovered_control()
	var ui_owns_hover := hovered_control != null and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE
	var hover := _interaction_at(get_viewport().get_mouse_position()) if not paused and not ui_owns_hover else {}
	var station := _station_hover_details(hover)
	var station_obstacles := _world_ui_obstacles()
	station_obstacles.append(WorldCalloutSkin.actor_rect(player.position))
	for employee: EmployeeAvatar in _employees.values(): station_obstacles.append(WorldCalloutSkin.actor_rect(employee.render_position()))
	founder_hud.update_station_hover(str(station.get("id", "")), str(station.get("caption", "")), station.get("bounds", Rect2()), not paused and not player.input_blocked, station_obstacles)
	if company_panel != null and company_panel.visible:
		founder_hud.hide_next_step()
	else:
		founder_hud.set_next_step(CompanyPanel.next_step_line(_journey, company_panel.busy if company_panel != null else false, company_panel._pending_method if company_panel != null else "", company_panel._pending_job_id if company_panel != null else ""))
	for employee_id: String in _employees:
		var employee := _employees[employee_id]
		employee.set_ui_presentation_state(job_panel._employee_ui_state(employee_id))
		var drawer_selected := job_panel.drawer_is_open() and job_panel.selected_employee_id() == employee_id
		employee.set_drawer_selected(drawer_selected)
		employee.set_speech_suppressed(employee_id == interaction_target or drawer_selected or employee.has_attention())
		employee.set_interaction_highlighted(employee_id == interaction_target)
		employee.set_ui_highlighted(str(hover.get("kind", "")) == "employee" and str(hover.get("id", "")) == employee_id)
	_update_label_visibility(interaction_target)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not hover.is_empty() else Input.CURSOR_ARROW)

func _station_hover_details(hover: Dictionary) -> Dictionary:
	if str(hover.get("kind", "")) != "prop": return {}
	var id := str(hover.get("id", ""))
	var placement := room.placement_by_id(id)
	if placement.is_empty(): return {}
	var owner_id := str(placement.get("owner_id", ""))
	var caption := CompanyPanel.station_caption(
		_journey,
		id,
		str(placement.kind),
		owner_id,
		not job_panel.active_job_id().is_empty() and (owner_id.is_empty() or job_panel._active_employee_id == owner_id),
		not job_panel._approval_id.is_empty(),
		job_panel._has_pending_delivery(owner_id)
	)
	var bounds: Rect2 = placement.world_visual_bounds
	bounds.position += room.global_position
	return {"id": id, "caption": caption, "bounds": bounds} if not caption.is_empty() else {}

func _retry_worker_connection() -> void:
	if OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1":
		job_panel.set_worker_connection_error("Worker is disabled in this deterministic preview.")
		return
	job_panel.set_info("Reconnecting to your saved company…")
	# start() is already idempotent. A retry uses the same stdio/bootstrap path.
	worker_client.start()
	worker_client.refresh_journey()

func _open_office_renovation() -> void:
	job_panel.close_drawer(false)
	artifact_viewer.hide()
	player.cancel_route()
	_pending_interaction = ""
	_pending_kind = ""
	office_renovation.open()

func _world_paused() -> bool:
	return (office_renovation != null and office_renovation.active) or job_panel.drawer_is_open() or job_panel._connection_panel.visible or artifact_viewer.visible or (company_panel != null and company_panel.visible)

func _connect_signals() -> void:
	worker_client.furnishing_received.connect(_on_furnishing_received)
	worker_client.furnishing_failed.connect(_on_furnishing_failed)
	office_renovation.save_requested.connect(_save_furnishing)
	worker_client.daily_spend_received.connect(job_panel.set_spend)
	worker_client.game_saved.connect(func() -> void:
		_save_acknowledged = true
		if company_panel.visible and company_panel.screen == "settings" and not company_panel.busy and company_panel._notice != null and company_panel._notice.text.is_empty():
			company_panel._notice.text = "Company saved. Safe to close the window."
	)
	worker_client.journey_received.connect(_on_journey)
	worker_client.company_action_completed.connect(_on_company_action)
	worker_client.company_action_failed.connect(_on_company_action_failed)
	worker_client.connected.connect(_on_worker_connected)
	worker_client.bootstrap_received.connect(_on_bootstrap)
	worker_client.credential_status_received.connect(job_panel.set_credential_status)
	worker_client.credential_detail_received.connect(job_panel.set_credential_detail)
	worker_client.credential_saved.connect(job_panel.set_credential_saved)
	worker_client.grok_login_challenge.connect(job_panel.show_grok_login_challenge)
	worker_client.grok_login_poll_received.connect(job_panel.show_grok_login_poll)
	worker_client.grok_login_failed.connect(job_panel.show_grok_login_failed)
	worker_client.chat_history_received.connect(job_panel.show_chat_history)
	worker_client.chat_reply_received.connect(job_panel.show_chat_reply)
	worker_client.chat_failed.connect(job_panel.set_chat_failed)
	worker_client.job_event_received.connect(_on_job_event)
	worker_client.artifacts_received.connect(job_panel.show_artifacts)
	worker_client.studio_files_received.connect(_on_studio_files)
	worker_client.promotion_state_received.connect(_on_promotion_state)
	worker_client.job_submission_received.connect(_on_job_submission)
	worker_client.job_submission_failed.connect(_on_job_submission_failed)
	worker_client.job_steered.connect(job_panel.set_steer_sent)
	worker_client.job_steer_failed.connect(job_panel.set_steer_failed)
	worker_client.artifact_content_received.connect(_on_artifact_content)
	worker_client.worker_crashed.connect(_on_worker_crashed)
	worker_client.request_failed.connect(_on_worker_request_failed)
	job_panel.key_submitted.connect(worker_client.save_openrouter_key)
	job_panel.grok_login_start_requested.connect(worker_client.start_grok_login)
	job_panel.grok_login_poll_requested.connect(worker_client.poll_grok_login)
	job_panel.grok_login_cancel_requested.connect(worker_client.cancel_grok_login)
	job_panel.grok_logout_requested.connect(worker_client.logout_grok)
	job_panel.grok_use_local_requested.connect(worker_client.use_local_grok)
	job_panel.chat_history_requested.connect(worker_client.request_chat_history)
	job_panel.chat_submitted.connect(worker_client.send_chat)
	job_panel.assignment_submitted.connect(_on_assignment_submitted)
	job_panel.cancel_requested.connect(worker_client.cancel_job)
	job_panel.steer_submitted.connect(worker_client.steer_job)
	job_panel.approval_decided.connect(worker_client.approve)
	job_panel.artifact_refresh_requested.connect(worker_client.request_artifacts)
	job_panel.artifact_open_requested.connect(worker_client.read_artifact)
	job_panel.studio_open_requested.connect(worker_client.read_studio_file)
	job_panel.promotion_decided.connect(_on_promotion_decided)
	founder_hud.chat_requested.connect(_on_hud_chat_requested)
	founder_hud.delivery_requested.connect(_on_hud_delivery_requested)
	day_clock.time_changed.connect(_on_clock_changed)

func _on_worker_connected() -> void:
	_worker_ready = true
	job_panel.set_worker_ready()

func _on_bootstrap(
	records: Array[EmployeeRecord],
	project_id: String,
	project_root: String,
	default_token_budget: int,
	daily_spend: float,
	daily_spend_warning: float,
	clock_state: Dictionary,
	studio_files: Array[StudioFileRecord],
	pending_promotions: Array,
	recent_jobs: Array,
	memories: Dictionary
) -> void:
	_project_id = project_id
	_token_budget = default_token_budget
	if not worker_client.furnishing_state.is_empty():
		_updating_roster = true
		_on_furnishing_received(worker_client.furnishing_state)
		_updating_roster = false
	_apply_memories(records, memories)
	_spawn_employees(records)
	job_panel.set_spend(daily_spend, daily_spend_warning)
	_remember_studio_paths(studio_files)
	job_panel.show_studio_files(studio_files)
	# Hydration restores durable rail attention, never announces an old delivery.
	job_panel.show_recent_jobs(recent_jobs)
	job_panel.show_pending_promotions(pending_promotions)
	_restore_recent_jobs(recent_jobs)
	_state_loaded = true
	day_clock.restore(
		int(clock_state.get("day", 1)),
		int(clock_state.get("minuteOfDay", DayClock.WORK_START)),
		1.0
	)
	if not _restored_player:
		_restore_player()
	var furnishing_recovery := str(worker_client.furnishing_state.get("recovery", ""))
	if not furnishing_recovery.is_empty() and company_panel.visible:
		company_panel.show_error(furnishing_recovery)

func _on_furnishing_received(state: Dictionary, operation_id: String = "") -> void:
	if not operation_id.is_empty() and int(state.get("revision", -1)) < room.furnishing_revision:
		office_renovation.save_failed(operation_id, "A newer office layout is already loaded. Your latest room was kept.")
		return
	if not room.apply_furnishing_state(state):
		office_renovation.save_failed(operation_id, "The saved office could not be displayed safely. Your previous room is kept.")
		return
	office_renovation.receive_state(state, operation_id)

func _on_furnishing_failed(operation_id: String, message: String) -> void:
	office_renovation.save_failed(operation_id, message)
	# A stale revision or uncertain write must be reconciled from the worker,
	# not retried forever against a cached layout revision.
	if _worker_ready and operation_id != "furnishing": worker_client.refresh_furnishing()

func _save_furnishing(operation_id: String, expected_revision: int, placements: Dictionary, actor_cells: Array) -> void:
	# The worker commits the exact founder position with the same layout write,
	# so furniture cannot occupy the founder's stale autosave cell after a crash.
	worker_client.update_furnishing(operation_id, expected_revision, placements, actor_cells)

func _apply_memories(records: Array[EmployeeRecord], memories: Dictionary) -> void:
	for record: EmployeeRecord in records:
		var values: Variant = memories.get(record.id, [])
		if not values is Array:
			continue
		for memory_value: Variant in values as Array:
			if memory_value is Dictionary:
				var memory := memory_value as Dictionary
				if str(memory.get("kind", "")) == "outcome":
					record.memory_line = str(memory.get("fact", ""))
					break

func _restore_recent_jobs(jobs: Array) -> void:
	for job_value: Variant in jobs:
		if not job_value is Dictionary:
			continue
		var job := job_value as Dictionary
		var job_id := str(job.get("jobId", ""))
		var employee_id := str(job.get("employeeId", ""))
		if not job_id.is_empty() and not employee_id.is_empty():
			_job_employees[job_id] = employee_id
		var status := str(job.get("status", ""))
		if status == "queued" or status == "running":
			job_panel.restore_job(job_id, status, str(job.get("title", "Work order")), employee_id)

func _spawn_employees(records: Array[EmployeeRecord]) -> void:
	# Geometry may change before new employees exist. Delay its actor callback
	# until the complete roster is present, so routes see all positions at once.
	_updating_roster = true
	var roster: Array[String] = []
	for record: EmployeeRecord in records: roster.append(record.id)
	for id: String in _employees.keys():
		if id not in roster:
			var removed := _employees[id]
			employee_container.remove_child(removed)
			removed.queue_free()
			_employees.erase(id)
	if room.navigation != null:
		room.navigation.actors.clear()
		room.navigation.actors["founder"] = player.position
	room.configure_employee_desks(records)
	player.position = room.navigation.safe_position(player.position, "founder")
	room.navigation.actors["founder"] = player.position
	for record: EmployeeRecord in records:
		var employee: EmployeeAvatar = _employees.get(record.id)
		if employee == null:
			employee = EMPLOYEE_SCENE.instantiate() as EmployeeAvatar
			employee.configure(record, room.employee_spawn_position(record.id), room.employee_desk_position(record.id), room.research_position())
			employee_container.add_child(employee)
			employee.navigation = room.navigation
		employee.position = room.navigation.safe_position(employee.position, record.id)
		employee.memory_line = record.memory_line
		room.navigation.actors[record.id] = employee.position
		_employees[record.id] = employee
	_updating_roster = false
	_on_room_placements_changed()
	job_panel.configure_employees(records)
	if records.is_empty():
		founder_hud.hide_delivery()

func _on_room_placements_changed() -> void:
	if _updating_roster: return
	player.cancel_route()
	_pending_interaction = ""
	room.navigation.actors.clear()
	room.navigation.reservations.clear()
	player.position = room.navigation.safe_position(player.position, "founder")
	room.navigation.actors["founder"] = player.position
	var replans: Array[Dictionary] = []
	for employee: EmployeeAvatar in _employees.values():
		var previous_desk := employee.desk_position
		var previous_research := employee.research_position
		var previous_lunch := employee.lunch_position
		var previous_home := employee.home_position
		var target := employee._requested_target
		var was_moving := employee._has_target or employee._waiting_for_desk
		var travel_state := employee._desk_travel_state if employee._route_requires_desk else employee.work_state
		employee.position = room.navigation.safe_position(employee.position, employee.employee_id)
		employee.home_position = room.employee_spawn_position(employee.employee_id)
		employee.desk_position = room.employee_desk_position(employee.employee_id)
		employee.research_position = room.research_position()
		employee.lunch_position = room.lunch_position(employee.employee_id)
		employee.configure_workstation_visual(room.employee_workstation_visual(employee.employee_id))
		employee.configure_research_visual(room.research_visual())
		employee.configure_collaboration_visual(room.collaboration_visual(employee.employee_id))
		room.navigation.actors[employee.employee_id] = employee.position
		room.navigation.reservations[employee.employee_id] = room.navigation.cell_at(employee.position)
		if was_moving:
			if target.distance_to(previous_desk) < 1: target = employee.desk_position
			elif target.distance_to(previous_research) < 1: target = employee.research_position
			elif target.distance_to(previous_lunch) < 1: target = employee.lunch_position
			elif target.distance_to(previous_home) < 1: target = employee.home_position
			replans.append({"employee": employee, "target": target, "state": travel_state, "arrival": employee._arrival_state})
		elif employee.work_state in [EmployeeAvatar.WorkState.SITTING, EmployeeAvatar.WorkState.TYPING] and employee.position.distance_to(employee.desk_position) > 1:
			replans.append({"employee": employee, "target": employee.desk_position, "state": EmployeeAvatar.WorkState.WALKING_TO_DESK, "arrival": employee.work_state})
	# Plan only after every actor's relocated feet are registered. Otherwise the
	# first employee can reserve a later employee's current cell as a destination.
	for replan: Dictionary in replans:
		var employee := replan.employee as EmployeeAvatar
		employee.walk_to(replan.target, replan.state, replan.arrival)

func _on_assignment_submitted(
	employee_id: String,
	title: String,
	assignment: String,
	acceptance_criteria: PackedStringArray,
	attached_studio_path: String
) -> void:
	var job_id := "job-%x-%x" % [Time.get_ticks_usec(), randi()]
	_job_employees[job_id] = employee_id
	job_panel.begin_job(job_id, employee_id)
	worker_client.start_job(
		job_id,
		employee_id,
		_project_id,
		title,
		assignment,
		acceptance_criteria,
		job_panel.requested_token_budget,
		attached_studio_path,
		job_panel.milestone_id,
		job_panel.revision_of_job_id
	)

func _on_job_submission(job_id: String, queued: bool) -> void:
	job_panel.accept_submission(job_id)
	if queued:
		job_panel.mark_job_queued(job_id)

func _on_job_submission_failed(job_id: String, message: String) -> void:
	_job_employees.erase(job_id)
	job_panel.reject_submission(job_id, message)

func _on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	if event.type == &"usage.updated" and _worker_ready: worker_client.refresh_spend()
	if _worker_ready and event.type in [&"job.started", &"job.queued", &"job.completed", &"job.blocked", &"job.failed", &"approval.required"]:
		worker_client.refresh_journey()
	var employee_id: String = _job_employees.get(job_id, "")
	var employee: EmployeeAvatar = _employees.get(employee_id) as EmployeeAvatar
	if employee != null:
		employee.apply_worker_event(event, player.position)
	if event.type == &"artifact.created" and not event.name.is_empty():
		_job_artifact_names[job_id] = event.name
		if _worker_ready: worker_client.request_artifacts(job_id)
	job_panel.on_job_event(job_id, event)
	if event.type == &"job.completed":
		game_audio.play("notice")
		var employee_name := employee.display_name if employee != null else employee_id.capitalize()
		var artifact_name: String = _job_artifact_names.get(job_id, "")
		var detail := "%s ready" % artifact_name if not artifact_name.is_empty() else "Work order ready"
		founder_hud.show_delivery(job_id, employee_id, employee_name, detail)
		worker_client.remember_job(job_id)
		worker_client.request_artifacts(job_id)
		job_panel.offer_promotion(job_id, employee_id)

func _on_artifact_content(job_id: String, name: String, content: String) -> void:
	if job_id == "studio-preview-css":
		var html_path := _pending_preview_html
		var html := _pending_preview_html_content
		_clear_pending_preview()
		if SitePreview.is_html_path(html_path):
			artifact_viewer.show_artifact(html_path, html, "Shared Studio", {"css": content, "studio": true})
		return
	if job_id.is_empty() and SitePreview.is_html_path(name):
		var css_path := SitePreview.companion_stylesheet(name, content, _studio_paths)
		if not css_path.is_empty():
			_pending_preview_html = name
			_pending_preview_html_content = content
			_pending_preview_css_path = css_path
			worker_client.read_studio_file(css_path, "studio-preview-css")
			return
	artifact_viewer.show_artifact(name, content, "Shared Studio" if job_id.is_empty() else "Job delivery")

func _clear_pending_preview() -> void:
	_pending_preview_html = ""
	_pending_preview_html_content = ""
	_pending_preview_css_path = ""

func _on_worker_request_failed(message: String) -> void:
	job_panel.set_error(message)

func _remember_studio_paths(files: Array[StudioFileRecord]) -> void:
	_studio_paths.clear()
	for file: StudioFileRecord in files:
		if not file.relative_path.is_empty():
			_studio_paths.append(file.relative_path)

func _on_studio_files(files: Array[StudioFileRecord]) -> void:
	_remember_studio_paths(files)
	job_panel.show_studio_files(files)
	job_panel.set_info("Durable studio updated. Files remain after restart.")

func _on_promotion_state(files: Array[StudioFileRecord], pending_promotions: Array) -> void:
	_remember_studio_paths(files)
	job_panel.show_studio_files(files)
	job_panel.show_pending_promotions(pending_promotions)
	founder_hud.hide_delivery()

func _show_pending_delivery(pending_promotions: Array) -> void:
	if pending_promotions.is_empty():
		founder_hud.hide_delivery()
		return
	var candidate_value: Variant = pending_promotions[0]
	if not candidate_value is Dictionary:
		return
	var candidate := candidate_value as Dictionary
	var employee_id := str(candidate.get("employeeId", ""))
	var employee_name := str(candidate.get("employeeName", "Team member"))
	if employee_id.is_empty():
		for known_id: String in _employees:
			var known_employee := _employees[known_id] as EmployeeAvatar
			if known_employee != null and known_employee.display_name == employee_name:
				employee_id = known_id
				break
	var detail := str(candidate.get("title", "Work order ready"))
	var artifacts_value: Variant = candidate.get("artifacts", [])
	if artifacts_value is Array and not (artifacts_value as Array).is_empty():
		var artifact_value: Variant = (artifacts_value as Array)[0]
		if artifact_value is Dictionary:
			detail = "%s ready" % str((artifact_value as Dictionary).get("name", "Delivery"))
	founder_hud.show_delivery(str(candidate.get("jobId", "")), employee_id, employee_name, detail)

func _on_hud_chat_requested(employee_id: String) -> void:
	job_panel.open_chat_for_employee(employee_id)

func _on_hud_delivery_requested(_job_id: String, employee_id: String) -> void:
	job_panel.open_journal_for_employee(employee_id)
	founder_hud.hide_delivery()

func _on_promotion_decided(job_id: String, approved: bool) -> void:
	founder_hud.hide_delivery()
	worker_client.promote_job(job_id, approved)

func _on_clock_changed(day: int, minute_of_day: int, phase: String, speed: float) -> void:
	if company_panel != null:
		company_panel.day = day
	clock_panel.show_clock(day, minute_of_day)
	job_panel.set_clock_phase(phase)
	for employee_value: EmployeeAvatar in _employees.values():
		employee_value.set_schedule_phase(phase)
	if _worker_ready and _state_loaded:
		worker_client.set_clock(day, minute_of_day, speed)
	if minute_of_day >= DayClock.WORK_END and _closing_shown_day != day and OS.get_environment("STARTUP_VALLEY_NO_WORKER") != "1":
		_closing_shown_day = day
		company_panel.present("closing")
		if _worker_ready: worker_client.refresh_journey()

func _on_journey(value: Dictionary) -> void:
	_journey = value
	company_panel.update_state(value)
	job_panel.set_journey_state(value)
	var company: Dictionary = value.get("company", {})
	clock_panel.show_money_earned(float(company.get("earnedCents", 0)) / 100.0)
	founder_hud.set_next_step(CompanyPanel.next_step_line(value, company_panel.busy, company_panel._pending_method, company_panel._pending_job_id))

func _restore_player() -> void:
	_restored_player = true
	var saved: Dictionary = _journey.get("player", {})
	# Fresh NPC spawn positions are temporary. Restore the founder against the
	# actual room first, then relocate NPCs; otherwise a valid saved location
	# shared with a default spawn is needlessly changed at every restart.
	room.navigation.actors.clear()
	room.navigation.reservations.clear()
	if saved.has("x") and saved.has("y"):
		var point := Vector2(float(saved.x), float(saved.y))
		# Preserve exact safe coordinates, including fractional legacy positions.
		player.position = room.navigation.safe_position(point, "founder")
	room.navigation.actors["founder"] = player.position
	var relocate_routes: Array[EmployeeAvatar] = []
	for employee: EmployeeAvatar in _employees.values():
		employee.position = room.navigation.safe_position(employee.position, employee.employee_id)
		room.navigation.actors[employee.employee_id] = employee.position
		room.navigation.reservations[employee.employee_id] = room.navigation.cell_at(employee.position)
		if employee._has_target or employee._waiting_for_desk:
			relocate_routes.append(employee)
		elif employee.work_state in [EmployeeAvatar.WorkState.SITTING, EmployeeAvatar.WorkState.TYPING] and employee.position.distance_to(employee.desk_position) > 0.5:
			employee._requested_target = employee.desk_position
			employee._arrival_state = employee.work_state
			employee._desk_travel_state = EmployeeAvatar.WorkState.WALKING_TO_DESK
			employee._route_requires_desk = true
			relocate_routes.append(employee)
	# All actor positions must be registered before any route claims a target.
	for employee: EmployeeAvatar in relocate_routes:
		var travel_state := employee._desk_travel_state if employee._route_requires_desk else employee.work_state
		employee.walk_to(employee._requested_target, travel_state, employee._arrival_state)
	if bool(saved.get("movementSeen", false)):
		founder_hud.dismiss_movement_hint()
	company_panel.effects_volume = float(saved.get("effectsVolume", 0.5))
	company_panel.ambience_volume = float(saved.get("ambienceVolume", 0.2))
	game_audio.set_volumes(company_panel.effects_volume, company_panel.ambience_volume)
	var saved_theme := str(saved.get("architectureTheme", "")).strip_edges()
	if not saved_theme.is_empty() and room.architecture.apply_theme(saved_theme):
		company_panel.set_architecture_theme(room.architecture.theme_id)
	var attention := str(saved.get("attentionEmployeeId", ""))
	if _employees.has(attention):
		job_panel._attention_employee_id = attention
		job_panel._refresh_team_card_styles()

func _on_company_action(method: String, result: Dictionary) -> void:
	company_panel.busy = false
	if result.has("dailySpend"):
		job_panel.set_spend(float(result.dailySpend), 5.0)
	match method:
		"game.new":
			office_renovation.reset_layout()
			_restored_player = true
			_closing_shown_day = -1
			_job_employees.clear()
			_job_artifact_names.clear()
			founder_hud.hide_delivery()
			artifact_viewer.hide()
			job_panel.reset_company()
			player.position = room.grid_to_world_position(room.player_spawn)
			job_panel._attention_employee_id = ""
			founder_hud._movement_seen = false
			if founder_hud._movement_hint_tween != null and founder_hud._movement_hint_tween.is_valid(): founder_hud._movement_hint_tween.kill()
			founder_hud._movement_hint.modulate.a = 1.0
			founder_hud._movement_hint.show()
			room.architecture.apply_theme(OfficeArchitecture.DEFAULT_THEME)
			company_panel.set_architecture_theme(OfficeArchitecture.DEFAULT_THEME)
			company_panel.present("journey")
			company_panel._notice.text = "Previous company backed up to: " + str(result.get("backupPath", ""))
		"hiring.complete":
			game_audio.play("reward")
			company_panel.present("hired")
		"milestone.complete", "milestone.override":
			game_audio.play("reward")
			company_panel.present("journey")
		"day.end":
			job_panel.close_drawer(false)
			artifact_viewer.hide()
			founder_hud.hide_delivery()
			var clock: Dictionary = result.get("clock", {})
			day_clock.restore(int(clock.get("day", day_clock.day + 1)), int(clock.get("minuteOfDay", 480)), 1)
			company_panel.show_summary(result.get("summary", {}))
	_save_game()

func _on_company_action_failed(method: String, message: String) -> void:
	company_panel.show_error(message)
	if method == "milestone.evaluate" and _worker_ready: worker_client.refresh_journey()

func _save_game() -> void:
	if not _worker_ready: return
	worker_client.company_request("game.save", {
		"x": player.position.x, "y": player.position.y,
		"movementSeen": founder_hud._movement_seen,
		"effectsVolume": game_audio.effects_volume, "ambienceVolume": game_audio.ambience_volume,
		"attentionEmployeeId": job_panel._attention_employee_id,
		"architectureTheme": room.architecture.theme_id if room != null and room.architecture != null else OfficeArchitecture.DEFAULT_THEME,
	})

func _on_architecture_theme(theme_id: String) -> void:
	if room == null or room.architecture == null: return
	if not room.architecture.apply_theme(theme_id):
		company_panel.set_architecture_theme(room.architecture.theme_id)
		return
	company_panel.set_architecture_theme(room.architecture.theme_id)
	_save_game()

func _unhandled_input(event: InputEvent) -> void:
	# Renovation owns its keys and its full-screen pointer surface. Do not let a
	# placement click create a founder route or let Escape open Settings beneath it.
	if office_renovation != null and office_renovation.active: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key := event as InputEventKey
		if not _world_paused():
			for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
				if event.is_action_pressed(action):
					# Even a key tap shorter than one physics tick cancels the route.
					player.cancel_route()
					_pending_interaction = ""
					_pending_kind = ""
					return
		if key.physical_keycode == KEY_J and not _world_paused():
			company_panel.present("journey")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_cancel"):
			if artifact_viewer.visible:
				artifact_viewer.close_viewer()
			elif job_panel._connection_panel.visible:
				job_panel._close_connection_settings()
			elif job_panel.drawer_is_open():
				job_panel.close_drawer()
			else:
				company_panel.present("settings")
			get_viewport().set_input_as_handled()
			return
	if not event is InputEventMouseButton or _world_paused(): return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT: return
	player.cancel_route()
	_pending_interaction = ""
	_pending_kind = ""
	var point := click.position
	var interaction := _interaction_at(point)
	if not interaction.is_empty():
		_pending_interaction = interaction.id
		_pending_kind = interaction.kind
		point = interaction.point
	if _pending_interaction.is_empty() and not room.navigation.walkable(room.navigation.cell_at(point)):
		click_feedback.show_at(point, false)
		get_viewport().set_input_as_handled()
		return
	var accepted := player.move_to(point)
	if accepted and str(interaction.get("kind", "")) == "prop" and not room.interaction_approach_direction(str(interaction.id)).is_zero_approx():
		# General ground/employee movement may select a nearby free cell. An
		# explicit service interaction must reach its authored standing socket,
		# not silently open a UI from an occupied socket's fallback location.
		if player.route[-1].distance_to(point) > 1.0:
			player.cancel_route()
			accepted = false
	click_feedback.show_at(player.route[-1] if accepted else point, accepted)
	if not accepted: _pending_interaction = ""
	get_viewport().set_input_as_handled()

func _interaction_at(point: Vector2) -> Dictionary:
	var surface := room.surface_at(point)
	var top_sprite := surface.get("sprite") as Sprite2D
	var interaction: Dictionary = surface.get("interaction", {})
	for id: String in _employees:
		var employee := _employees[id]
		var body := employee.body_surface_at(point)
		if VisibleSurface.in_front(body, top_sprite):
			top_sprite = body
			interaction = {"id": id, "kind": "employee", "point": employee.position + Vector2(0, 40)}
	if VisibleSurface.in_front(player.body_surface_at(point), top_sprite):
		return {} # Same noninteractive occlusion rule as passive furniture.
	return interaction

func _on_destination_reached() -> void:
	var target := _pending_interaction
	_pending_interaction = ""
	if target.is_empty(): return
	if _pending_kind == "prop":
		var approach := room.interaction_approach_direction(target)
		if not approach.is_zero_approx():
			var socket := room.interaction_world_position(target)
			if player.position.distance_to(socket) > 2.0 or not room.navigation.position_is_safe(socket, "founder"):
				click_feedback.show_at(socket, false)
				return
		player.face_direction(approach)
	if _pending_kind == "employee":
		var employee := get_employee(target)
		if employee != null and player.position.distance_to(employee.position) < 110:
			job_panel.open_chat_for_employee(target)
	elif target == "founder-workstation":
		company_panel.present("journey")
	elif target == "artifact-archive":
		job_panel.open_drawer()
		job_panel._tabs.current_tab = 3
	elif target == "approval-console":
		job_panel.open_journal_for_employee(job_panel.pending_decision_employee_id())
	else:
		for placement: Dictionary in room.resolved_placements:
			if placement.id == target and _employees.has(placement.owner_id):
				job_panel.select_employee(placement.owner_id)
				job_panel._tabs.current_tab = 2 if not job_panel.active_job_id().is_empty() else 1

func _yield_employee_passage(employee_id: String, destination: Vector2) -> void:
	var employee := get_employee(employee_id)
	if employee == null or employee._has_target: return
	# Retain approval/work state after a small step aside; no job lifecycle change.
	employee.walk_to(destination, EmployeeAvatar.WorkState.WANDERING, employee.work_state)

func _world_ui_obstacles() -> Array[Rect2]:
	# Rendering metadata only: never alter furniture, navigation or collision.
	var placed: Array[Rect2] = []
	for placement: Dictionary in room.resolved_placements:
		var rect: Rect2 = placement.world_visual_bounds
		rect.position += room.global_position
		placed.append(rect)
	for employee: EmployeeAvatar in _employees.values():
		var cue := employee.visible_world_vfx_rect()
		if cue.has_area(): placed.append(cue.grow(4))
	placed.append(clock_panel.get_global_rect())
	placed.append(job_panel.rail_global_rect())
	if job_panel._drawer_panel.is_visible_in_tree(): placed.append(job_panel.drawer_global_rect())
	if job_panel._connection_panel.is_visible_in_tree(): placed.append(job_panel._connection_panel.get_global_rect())
	if artifact_viewer.visible or (company_panel != null and company_panel.visible):
		placed.append(get_viewport().get_visible_rect())
	if founder_hud.delivery_visible(): placed.append(founder_hud._notification.get_global_rect())
	if founder_hud._movement_hint.visible: placed.append(founder_hud._movement_hint.get_global_rect())
	var next_step := founder_hud.next_step_rect()
	if next_step.has_area(): placed.append(next_step)
	return placed

func _update_label_visibility(priority_id: String) -> void:
	var placed := _world_ui_obstacles()
	placed.append(WorldCalloutSkin.actor_rect(player.position))
	for employee: EmployeeAvatar in _employees.values(): placed.append(WorldCalloutSkin.actor_rect(employee.render_position()))
	if founder_hud.interaction_visible(): placed.append(founder_hud.interaction_rect())
	var station_hover := founder_hud.station_hover_rect()
	if station_hover.has_area(): placed.append(station_hover)
	var ordered: Array[EmployeeAvatar] = []
	for employee: EmployeeAvatar in _employees.values(): ordered.append(employee)
	ordered.sort_custom(func(a: EmployeeAvatar, b: EmployeeAvatar) -> bool:
		var a_priority := 2 if a.employee_id == priority_id else 1 if a.has_attention() else 0
		var b_priority := 2 if b.employee_id == priority_id else 1 if b.has_attention() else 0
		return a_priority > b_priority
	)
	for employee: EmployeeAvatar in ordered:
		var was_suppressed := employee.labels_suppressed
		employee.labels_suppressed = false
		var viewport := Rect2(18, 82, 1114, get_viewport().get_visible_rect().size.y - 100)
		var body := employee.world_label_body_rect()
		var candidate := WorldCalloutSkin.place(employee.render_position(), body.size, placed, viewport, employee._speech_visible or employee.attention_cue_visible())
		if not candidate.has_area() and (employee._interaction_highlighted or employee._ui_highlighted):
			candidate = _calibration_callout_fallback(employee, body.size, placed, viewport)
		employee.labels_suppressed = not candidate.has_area()
		if candidate.has_area(): employee.set_callout_position(candidate.position)
		if was_suppressed != employee.labels_suppressed: employee.queue_redraw()
		if not employee.labels_suppressed and (employee._labels_visible() or employee._speech_visible or employee.attention_cue_visible()): placed.append(employee.world_label_rect())

func _calibration_callout_fallback(employee: EmployeeAvatar, size: Vector2, occupied: Array[Rect2], viewport: Rect2) -> Rect2:
	# A supported North chair can enclose every actor-relative candidate. Only
	# reviewed production or owner-scoped calibration work cues opt into this
	# larger assembly perimeter; legacy/unrequested labels remain unchanged.
	var cue := employee.work_vfx_rect()
	if not cue.has_area(): return Rect2()
	var actor := WorldCalloutSkin.actor_rect(employee.render_position())
	var assembly := actor.merge(cue)
	for placement: Dictionary in room.resolved_placements:
		if str(placement.get("owner_id", "")) != employee.employee_id: continue
		var prop: Rect2 = placement.world_visual_bounds
		prop.position += room.global_position
		assembly = assembly.merge(prop)
	var gap := float(WorldCalloutSkin.POINTER_LENGTH + 3)
	var positions: Array[Vector2] = [
		Vector2(actor.get_center().x - size.x * 0.5, assembly.end.y + gap),
		Vector2(assembly.position.x - size.x - gap, actor.get_center().y - size.y * 0.5),
		Vector2(assembly.end.x + gap, actor.get_center().y - size.y * 0.5),
		Vector2(actor.get_center().x - size.x * 0.5, assembly.position.y - size.y - gap),
	]
	for point: Vector2 in positions:
		var candidate := Rect2(point.round(), size.round())
		# The pointer still aims at the real actor, not an invented larger body.
		var painted := WorldCalloutSkin.bounds(candidate, actor.get_center())
		if not viewport.encloses(painted): continue
		var obstructed := false
		for obstacle: Rect2 in occupied:
			if painted.intersects(obstacle):
				obstructed = true
				break
		if not obstructed: return candidate
	return Rect2()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _quitting:
		_quitting = true
		game_audio.shutdown()
		_save_acknowledged = false
		_save_game()
		var deadline := Time.get_ticks_msec() + 2000
		while _worker_ready and not _save_acknowledged and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		# Let the audio mixer retire stopped playback before tearing down the tree.
		await get_tree().create_timer(0.05).timeout
		get_tree().quit()

func _on_worker_crashed(message: String) -> void:
	_worker_ready = false
	if office_renovation != null: office_renovation.connection_lost()
	company_panel.busy = false
	if company_panel.visible:
		company_panel.show_error("Connection interrupted. Your completed work is saved. Reconnecting…")
	var active_job := job_panel.active_job_id()
	if not active_job.is_empty():
		var event := WorkerEventRecord.new()
		event.type = &"job.failed"
		event.error = "%s. The work order was marked failed and can be assigned again." % message
		_on_job_event(active_job, event)
	job_panel.set_worker_connection_error("%s. Restarting the worker once…" % message)

func get_employee(employee_id: String) -> EmployeeAvatar:
	return _employees.get(employee_id) as EmployeeAvatar

func simulate_worker_event(employee_id: String, event_type: StringName, tool: String = "") -> void:
	var employee: EmployeeAvatar = _employees.get(employee_id) as EmployeeAvatar
	if employee == null:
		return
	var event := WorkerEventRecord.new()
	event.type = event_type
	event.tool = tool
	event.label = tool
	employee.apply_worker_event(event, player.position)
