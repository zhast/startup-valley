class_name GameMain
extends Node

const EMPLOYEE_SCENE: PackedScene = preload("res://actors/employee_avatar.tscn")

@onready var room: TownRoom = $TownRoom
@onready var player: PlayerAvatar = $PlayerAvatar
@onready var employee_container: Node2D = $Employees
@onready var worker_client: WorkerClient = $WorkerClient
@onready var job_panel: JobPanel = $Interface/JobPanel
@onready var artifact_viewer: ArtifactViewer = $Interface/ArtifactViewer
@onready var day_clock: DayClock = $DayClock
@onready var clock_panel: ClockPanel = $Interface/ClockPanel

var _employees: Dictionary[String, EmployeeAvatar] = {}
var _job_employees: Dictionary[String, String] = {}
var _project_id: String = "company"
var _token_budget: int = 12000
var _worker_ready: bool = false
var _state_loaded: bool = false

func _ready() -> void:
	room.load_layout()
	player.position = room.grid_to_world_position(room.player_spawn)
	player.movement_bounds = room.playable_bounds()
	_spawn_employees(room.placeholder_records())
	_connect_signals()
	_on_clock_changed(day_clock.day, day_clock.minute_of_day, day_clock.phase, day_clock.speed)
	if OS.get_environment("STARTUP_VALLEY_NO_WORKER") != "1":
		worker_client.start()
	else:
		job_panel.set_error("Deterministic test mode — worker disabled")

func _connect_signals() -> void:
	worker_client.connected.connect(_on_worker_connected)
	worker_client.bootstrap_received.connect(_on_bootstrap)
	worker_client.credential_status_received.connect(job_panel.set_credential_status)
	worker_client.credential_saved.connect(job_panel.set_credential_saved)
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
	worker_client.request_failed.connect(job_panel.set_error)
	job_panel.key_submitted.connect(worker_client.save_openrouter_key)
	job_panel.chat_history_requested.connect(worker_client.request_chat_history)
	job_panel.chat_submitted.connect(worker_client.send_chat)
	job_panel.assignment_submitted.connect(_on_assignment_submitted)
	job_panel.cancel_requested.connect(worker_client.cancel_job)
	job_panel.steer_submitted.connect(worker_client.steer_job)
	job_panel.approval_decided.connect(worker_client.approve)
	job_panel.artifact_refresh_requested.connect(worker_client.request_artifacts)
	job_panel.artifact_open_requested.connect(worker_client.read_artifact)
	job_panel.studio_open_requested.connect(worker_client.read_studio_file)
	job_panel.promotion_decided.connect(worker_client.promote_job)
	day_clock.time_changed.connect(_on_clock_changed)
	clock_panel.speed_selected.connect(day_clock.set_speed)

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
	_apply_memories(records, memories)
	room.configure_employee_desks(records)
	_spawn_employees(records)
	job_panel.configure_employees(records)
	job_panel.set_spend(daily_spend, daily_spend_warning)
	job_panel.show_studio_files(studio_files)
	job_panel.show_pending_promotions(pending_promotions)
	job_panel.show_recent_jobs(recent_jobs)
	_restore_recent_jobs(recent_jobs)
	_state_loaded = true
	day_clock.restore(
		int(clock_state.get("day", 1)),
		int(clock_state.get("minuteOfDay", DayClock.WORK_START)),
		float(clock_state.get("speed", 1.0))
	)

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
	for child: Node in employee_container.get_children():
		child.queue_free()
	_employees.clear()
	room.configure_employee_desks(records)
	for record: EmployeeRecord in records:
		var employee := EMPLOYEE_SCENE.instantiate() as EmployeeAvatar
		employee.configure(
			record,
			room.employee_spawn_position(record.id),
			room.employee_desk_position(record.id),
			room.research_position()
		)
		employee_container.add_child(employee)
		_employees[record.id] = employee
	job_panel.configure_employees(records)

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
		_token_budget,
		attached_studio_path
	)

func _on_job_submission(job_id: String, queued: bool) -> void:
	if queued:
		job_panel.mark_job_queued(job_id)

func _on_job_submission_failed(job_id: String, message: String) -> void:
	var event := WorkerEventRecord.new()
	event.type = &"job.failed"
	event.error = message
	_on_job_event(job_id, event)

func _on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var employee_id: String = _job_employees.get(job_id, "")
	var employee: EmployeeAvatar = _employees.get(employee_id) as EmployeeAvatar
	if employee != null:
		employee.apply_worker_event(event, player.position)
	job_panel.on_job_event(job_id, event)
	if event.type == &"job.completed":
		worker_client.remember_job(job_id)
		worker_client.request_artifacts(job_id)
		job_panel.offer_promotion(job_id)

func _on_artifact_content(_job_id: String, name: String, content: String) -> void:
	artifact_viewer.show_artifact(name, content)

func _on_studio_files(files: Array[StudioFileRecord]) -> void:
	job_panel.show_studio_files(files)
	job_panel.set_info("Durable studio updated. Files remain after restart.")

func _on_promotion_state(files: Array[StudioFileRecord], pending_promotions: Array) -> void:
	job_panel.show_studio_files(files)
	job_panel.show_pending_promotions(pending_promotions)

func _on_clock_changed(day: int, minute_of_day: int, phase: String, speed: float) -> void:
	clock_panel.show_clock(day, minute_of_day, phase, speed)
	job_panel.set_clock_phase(phase)
	for employee_value: EmployeeAvatar in _employees.values():
		employee_value.set_schedule_phase(phase)
	if _worker_ready and _state_loaded:
		worker_client.set_clock(day, minute_of_day, speed)

func _on_worker_crashed(message: String) -> void:
	var active_job := job_panel.active_job_id()
	if not active_job.is_empty():
		var event := WorkerEventRecord.new()
		event.type = &"job.failed"
		event.error = "%s. The work order was marked failed and can be assigned again." % message
		_on_job_event(active_job, event)
	job_panel.set_error("%s. Restarting the worker once…" % message)

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
