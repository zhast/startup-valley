class_name GameMain
extends Node

const EMPLOYEE_SCENE: PackedScene = preload("res://actors/employee_avatar.tscn")

@onready var room: TownRoom = $TownRoom
@onready var player: PlayerAvatar = $PlayerAvatar
@onready var employee_container: Node2D = $Employees
@onready var worker_client: WorkerClient = $WorkerClient
@onready var job_panel: JobPanel = $Interface/JobPanel
@onready var artifact_viewer: ArtifactViewer = $Interface/ArtifactViewer

var _employees: Dictionary[String, EmployeeAvatar] = {}
var _job_employees: Dictionary[String, String] = {}
var _project_id: String = "company"
var _project_root: String = ""
var _token_budget: int = 12000

func _ready() -> void:
	room.load_layout()
	player.position = room.grid_to_world_position(room.player_spawn)
	player.movement_bounds = room.playable_bounds()
	_spawn_employees(room.placeholder_records())
	_connect_signals()
	if OS.get_environment("STARTUP_VALLEY_NO_WORKER") != "1":
		worker_client.start()
	else:
		job_panel.set_error("Deterministic test mode — worker disabled")

func _connect_signals() -> void:
	worker_client.connected.connect(job_panel.set_worker_ready)
	worker_client.bootstrap_received.connect(_on_bootstrap)
	worker_client.credential_status_received.connect(job_panel.set_credential_status)
	worker_client.credential_saved.connect(job_panel.set_credential_saved)
	worker_client.job_event_received.connect(_on_job_event)
	worker_client.artifacts_received.connect(job_panel.show_artifacts)
	worker_client.artifact_content_received.connect(_on_artifact_content)
	worker_client.worker_crashed.connect(_on_worker_crashed)
	worker_client.request_failed.connect(job_panel.set_error)
	job_panel.key_submitted.connect(worker_client.save_openrouter_key)
	job_panel.assignment_submitted.connect(_on_assignment_submitted)
	job_panel.cancel_requested.connect(worker_client.cancel_job)
	job_panel.approval_decided.connect(worker_client.approve)
	job_panel.artifact_refresh_requested.connect(worker_client.request_artifacts)
	job_panel.artifact_open_requested.connect(worker_client.read_artifact)

func _on_bootstrap(
	records: Array[EmployeeRecord],
	project_id: String,
	project_root: String,
	default_token_budget: int,
	daily_spend: float,
	daily_spend_warning: float
) -> void:
	_project_id = project_id
	_project_root = project_root
	_token_budget = default_token_budget
	room.configure_employee_desks(records)
	_spawn_employees(records)
	job_panel.configure_employees(records)
	job_panel.set_spend(daily_spend, daily_spend_warning)

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
	acceptance_criteria: PackedStringArray
) -> void:
	var job_id := "job-%x-%x" % [Time.get_ticks_usec(), randi()]
	_job_employees[job_id] = employee_id
	job_panel.begin_job(job_id)
	worker_client.start_job(
		job_id,
		employee_id,
		_project_id,
		title,
		assignment,
		acceptance_criteria,
		_token_budget
	)

func _on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var employee_id: String = _job_employees.get(job_id, "")
	var employee: EmployeeAvatar = _employees.get(employee_id) as EmployeeAvatar
	if employee != null:
		employee.apply_worker_event(event, player.position)
	job_panel.on_job_event(job_id, event)
	if event.type == &"job.completed":
		worker_client.remember_job(job_id)

func _on_artifact_content(_job_id: String, name: String, content: String) -> void:
	artifact_viewer.show_artifact(name, content)

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
