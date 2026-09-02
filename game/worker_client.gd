class_name WorkerClient
extends Node

signal connected
signal bootstrap_received(
	employees: Array[EmployeeRecord],
	project_id: String,
	project_root: String,
	default_token_budget: int,
	daily_spend: float,
	daily_spend_warning: float
)
signal credential_status_received(configured: bool)
signal credential_saved
signal job_event_received(job_id: String, event: WorkerEventRecord)
signal artifacts_received(job_id: String, artifacts: Array[ArtifactRecord])
signal artifact_content_received(job_id: String, name: String, content: String)
signal worker_crashed(message: String)
signal request_failed(message: String)

var _stdio: FileAccess
var _stderr: FileAccess
var _process_id: int = -1
var _read_buffer: String = ""
var _next_request_id: int = 1
var _pending_methods: Dictionary[String, String] = {}
var _pending_jobs: Dictionary[String, String] = {}
var _restart_count: int = 0

func start() -> void:
	if _stdio != null:
		return
	var worker_script := ProjectSettings.globalize_path("res://../harness/dist/main.js")
	if not FileAccess.file_exists(worker_script):
		request_failed.emit("Worker build missing. Run: cd harness && npm run build")
		return
	var node_path := OS.get_environment("STARTUP_VALLEY_NODE")
	if node_path.is_empty():
		node_path = "node"
	var arguments := PackedStringArray([worker_script, "--data-dir", OS.get_user_data_dir()])
	var process: Dictionary = OS.execute_with_pipe(node_path, arguments, false)
	if process.is_empty():
		request_failed.emit("Could not start Node worker. Install Node 22.19+ or set STARTUP_VALLEY_NODE.")
		return
	_stdio = process.get("stdio") as FileAccess
	_stderr = process.get("stderr") as FileAccess
	_process_id = int(process.get("pid", -1))
	if _stdio == null:
		request_failed.emit("Worker process did not provide a stdio pipe")
		return
	_send_request("health", {})
	set_process(true)

func _process(_delta: float) -> void:
	_read_stdout()
	_read_stderr()
	if _process_id > 0 and not OS.is_process_running(_process_id):
		var exit_code := OS.get_process_exit_code(_process_id)
		var message := "Worker exited with code %d" % exit_code
		_process_id = -1
		if _stdio != null:
			_stdio.close()
		_stdio = null
		_stderr = null
		_pending_methods.clear()
		_pending_jobs.clear()
		worker_crashed.emit(message)
		request_failed.emit("%s. The active job was failed safely." % message)
		set_process(false)
		if _restart_count < 1:
			_restart_count += 1
			call_deferred("_restart_after_crash")

func _restart_after_crash() -> void:
	await get_tree().create_timer(0.4).timeout
	start()

func _read_stdout() -> void:
	if _stdio == null:
		return
	var available := int(_stdio.get_length())
	if available <= 0:
		return
	_read_buffer += _stdio.get_buffer(available).get_string_from_utf8()
	var newline := _read_buffer.find("\n")
	while newline >= 0:
		var line := _read_buffer.substr(0, newline).strip_edges()
		_read_buffer = _read_buffer.substr(newline + 1)
		if not line.is_empty():
			_handle_line(line)
		newline = _read_buffer.find("\n")

func _read_stderr() -> void:
	if _stderr == null:
		return
	var available := int(_stderr.get_length())
	if available <= 0:
		return
	var message := _stderr.get_buffer(available).get_string_from_utf8().strip_edges()
	if not message.is_empty():
		push_warning("Worker: %s" % message)

func _handle_line(line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	if not parsed is Dictionary:
		request_failed.emit("Worker sent invalid JSON")
		return
	var message := parsed as Dictionary
	var kind := str(message.get("kind", ""))
	if kind == "event":
		var event_data: Variant = message.get("event")
		if event_data is Dictionary:
			job_event_received.emit(str(message.get("jobId", "")), WorkerEventRecord.from_dictionary(event_data as Dictionary))
		return
	if kind != "response":
		return
	var request_id := str(message.get("id", ""))
	var method: String = _pending_methods.get(request_id, "")
	var job_id: String = _pending_jobs.get(request_id, "")
	_pending_methods.erase(request_id)
	_pending_jobs.erase(request_id)
	if not bool(message.get("ok", false)):
		request_failed.emit(str(message.get("error", "Worker request failed")))
		return
	_handle_response(method, job_id, message.get("result"))

func _handle_response(method: String, job_id: String, result_value: Variant) -> void:
	var result: Dictionary = result_value as Dictionary if result_value is Dictionary else {}
	match method:
		"health":
			connected.emit()
			_send_request("bootstrap", {})
			_send_request("credential.status", {})
		"bootstrap":
			var employees: Array[EmployeeRecord] = []
			var employee_values: Variant = result.get("employees", [])
			if employee_values is Array:
				for employee_value: Variant in employee_values as Array:
					if employee_value is Dictionary:
						employees.append(EmployeeRecord.from_dictionary(employee_value as Dictionary))
			var project_value: Variant = result.get("project", {})
			var project: Dictionary = project_value as Dictionary if project_value is Dictionary else {}
			bootstrap_received.emit(
				employees,
				str(project.get("id", "company")),
				str(project.get("rootPath", "")),
				int(result.get("defaultTokenBudget", 12000)),
				float(result.get("dailySpend", 0.0)),
				float(result.get("dailySpendWarning", 5.0))
			)
		"credential.status":
			credential_status_received.emit(bool(result.get("configured", false)))
		"credential.set":
			credential_saved.emit()
		"job.artifacts":
			var artifacts: Array[ArtifactRecord] = []
			if result_value is Array:
				for artifact_value: Variant in result_value as Array:
					if artifact_value is Dictionary:
						artifacts.append(ArtifactRecord.from_dictionary(artifact_value as Dictionary))
			artifacts_received.emit(job_id, artifacts)
		"artifact.read":
			artifact_content_received.emit(job_id, str(result.get("name", "Artifact")), str(result.get("content", "")))

func _send_request(method: String, parameters: Dictionary, job_id: String = "") -> void:
	if _stdio == null:
		request_failed.emit("Worker is not connected")
		return
	var request_id := str(_next_request_id)
	_next_request_id += 1
	_pending_methods[request_id] = method
	if not job_id.is_empty():
		_pending_jobs[request_id] = job_id
	var envelope := {"kind": "request", "id": request_id, "method": method, "params": parameters}
	_stdio.store_string(JSON.stringify(envelope) + "\n")
	_stdio.flush()

func save_openrouter_key(key: String) -> void:
	_send_request("credential.set", {"key": key})

func start_job(
	job_id: String,
	employee_id: String,
	project_id: String,
	title: String,
	assignment: String,
	acceptance_criteria: PackedStringArray,
	token_budget: int
) -> void:
	_send_request("job.start", {"spec": {
		"jobId": job_id,
		"employeeId": employee_id,
		"projectId": project_id,
		"title": title,
		"assignment": assignment,
		"acceptanceCriteria": Array(acceptance_criteria),
		"tokenBudget": token_budget,
	}}, job_id)

func request_artifacts(job_id: String) -> void:
	_send_request("job.artifacts", {"jobId": job_id}, job_id)

func read_artifact(job_id: String, relative_path: String) -> void:
	_send_request("artifact.read", {"jobId": job_id, "relativePath": relative_path}, job_id)

func remember_job(job_id: String) -> void:
	_send_request("job.remember", {"jobId": job_id}, job_id)

func cancel_job(job_id: String) -> void:
	_send_request("job.cancel", {"jobId": job_id}, job_id)

func approve(job_id: String, approval_id: String, approved: bool, reason: String = "") -> void:
	_send_request("job.approve", {
		"jobId": job_id,
		"approvalId": approval_id,
		"approved": approved,
		"reason": reason,
	}, job_id)

func _exit_tree() -> void:
	if _stdio != null:
		_stdio.close()
	if _process_id > 0 and OS.is_process_running(_process_id):
		OS.kill(_process_id)
	_process_id = -1
