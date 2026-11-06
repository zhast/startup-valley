class_name WorkerClient
extends Node

signal connected
signal daily_spend_received(value: float, warning: float)
signal bootstrap_received(
	employees: Array[EmployeeRecord],
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
)
signal credential_status_received(configured: bool)
signal credential_detail_received(detail: Dictionary)
signal credential_saved
signal grok_login_challenge(user_code: String, verification_uri: String, interval_seconds: int)
signal grok_login_poll_received(result: Dictionary)
signal grok_login_failed(message: String)
signal chat_history_received(employee_id: String, messages: Array)
signal chat_reply_received(employee_id: String, message: Dictionary, daily_spend: float)
signal chat_failed(employee_id: String, message: String)
signal job_event_received(job_id: String, event: WorkerEventRecord)
signal artifacts_received(job_id: String, artifacts: Array[ArtifactRecord])
signal artifact_content_received(job_id: String, name: String, content: String)
signal studio_files_received(files: Array[StudioFileRecord])
signal promotion_state_received(files: Array[StudioFileRecord], pending_promotions: Array)
signal job_submission_received(job_id: String, queued: bool)
signal job_submission_failed(job_id: String, message: String)
signal job_steered(job_id: String)
signal job_steer_failed(job_id: String, message: String)
signal worker_crashed(message: String)
signal request_failed(message: String)
signal journey_received(state: Dictionary)
signal company_action_completed(method: String, result: Dictionary)
signal company_action_failed(method: String, message: String)
signal game_saved
signal furnishing_received(state: Dictionary, operation_id: String)
signal furnishing_failed(operation_id: String, message: String)

# Worker-owned committed state. Kept separate from Renovate's local preview.
var furnishing_state: Dictionary = {}

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
	var data_dir := OS.get_environment("STARTUP_VALLEY_DATA_DIR")
	if data_dir.is_empty():
		data_dir = OS.get_user_data_dir()
	var arguments := PackedStringArray([worker_script, "--data-dir", data_dir])
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
		var error := str(message.get("error", "Worker request failed"))
		if method == "furnishing.update":
			furnishing_failed.emit(job_id, error)
			return
		if method.begins_with("milestone.") or method.begins_with("hiring.") or method.begins_with("game.") or method.begins_with("tycoon.") or method == "day.end":
			company_action_failed.emit(method, error)
			return
		if method.begins_with("credential.grok."):
			grok_login_failed.emit(error)
			return
		if method == "job.start":
			job_submission_failed.emit(job_id, error)
		elif method == "job.steer":
			job_steer_failed.emit(job_id, error)
		elif method == "chat.send":
			chat_failed.emit(job_id, error)
		elif method == "studio.read" and job_id == "studio-preview-css":
			artifact_content_received.emit(job_id, "", "")
			return
		request_failed.emit(error)
		return
	_handle_response(method, job_id, message.get("result"))

func _handle_response(method: String, job_id: String, result_value: Variant) -> void:
	var result: Dictionary = result_value as Dictionary if result_value is Dictionary else {}
	if method == "furnishing.update" or (method == "bootstrap" and job_id == "furnishing"):
		var value: Variant = result.get("furnishing")
		if value is Dictionary and int(value.get("version", 0)) == 1:
			furnishing_state = value.duplicate(true)
			furnishing_received.emit(furnishing_state.duplicate(true), job_id if method == "furnishing.update" else "")
		else:
			furnishing_failed.emit(job_id, "The worker returned an unreadable office layout. Your last saved room was kept.")
		return
	if method == "bootstrap" and job_id in ["journey", "spend"]:
		daily_spend_received.emit(float(result.get("dailySpend", 0.0)), float(result.get("dailySpendWarning", 5.0)))
		if job_id == "journey": journey_received.emit(result.get("journey", {}))
		return
	match method:
		"hiring.complete", "game.new":
			_handle_response("bootstrap", "", result)
			company_action_completed.emit(method, result)
		"tycoon.expandOffice":
			journey_received.emit(result.get("journey", {}))
			var office_furnishing: Variant = result.get("furnishing")
			if office_furnishing is Dictionary and int((office_furnishing as Dictionary).get("version", 0)) == 1:
				furnishing_state = (office_furnishing as Dictionary).duplicate(true)
				furnishing_received.emit(furnishing_state.duplicate(true), "")
			company_action_completed.emit(method, result)
		"milestone.evaluate", "milestone.complete", "milestone.override", "chapter.continue", "day.end", "tycoon.start", "tycoon.release", "tycoon.train", "tycoon.research", "tycoon.buyUpgrade", "tycoon.buyEngine", "tycoon.acceptContract", "tycoon.patch", "tycoon.sequel", "tycoon.award", "tycoon.port", "tycoon.localize", "tycoon.takeLoan", "tycoon.signPublisher", "tycoon.bookBooth", "tycoon.takeTownDay", "tycoon.showPressDemo", "tycoon.makeTrailer", "tycoon.writeDiary", "tycoon.addFeature":
			journey_received.emit(result.get("journey", {}))
			company_action_completed.emit(method, result)
		"game.save":
			game_saved.emit()
		"health":
			connected.emit()
			_send_request("bootstrap", {})
			_send_request("credential.status", {})
		"bootstrap":
			var furnishing_value: Variant = result.get("furnishing", {})
			furnishing_state = furnishing_value.duplicate(true) if furnishing_value is Dictionary else {}
			journey_received.emit(result.get("journey", {}))
			var employees: Array[EmployeeRecord] = []
			var employee_values: Variant = result.get("employees", [])
			if employee_values is Array:
				for employee_value: Variant in employee_values as Array:
					if employee_value is Dictionary:
						employees.append(EmployeeRecord.from_dictionary(employee_value as Dictionary))
			var project_value: Variant = result.get("project", {})
			var project: Dictionary = project_value as Dictionary if project_value is Dictionary else {}
			var studio_files := _studio_files_from_value(result.get("studioFiles", []))
			var pending_value: Variant = result.get("pendingPromotions", [])
			var pending_promotions: Array = pending_value as Array if pending_value is Array else []
			var clock_value: Variant = result.get("clock", {})
			var clock_state: Dictionary = clock_value as Dictionary if clock_value is Dictionary else {}
			var recent_value: Variant = result.get("recentJobs", [])
			var recent_jobs: Array = recent_value as Array if recent_value is Array else []
			var memories_value: Variant = result.get("memories", {})
			var memories: Dictionary = memories_value as Dictionary if memories_value is Dictionary else {}
			bootstrap_received.emit(
				employees,
				str(project.get("id", "company")),
				str(project.get("rootPath", "")),
				int(result.get("defaultTokenBudget", 12000)),
				float(result.get("dailySpend", 0.0)),
				float(result.get("dailySpendWarning", 5.0)),
				clock_state,
				studio_files,
				pending_promotions,
				recent_jobs,
				memories
			)
		"credential.status", "credential.set", "credential.grok.login.cancel", "credential.grok.logout", "credential.grok.use_local":
			credential_status_received.emit(bool(result.get("configured", false)))
			credential_detail_received.emit(result)
			if method == "credential.set":
				credential_saved.emit()
		"credential.grok.login.start":
			grok_login_challenge.emit(str(result.get("userCode", "")), str(result.get("verificationUri", "")), int(result.get("intervalSeconds", 5)))
		"credential.grok.login.poll":
			grok_login_poll_received.emit(result)
			if str(result.get("status", "")) == "complete":
				credential_status_received.emit(bool(result.get("configured", false)))
				credential_detail_received.emit(result)
		"chat.history":
			var messages: Array = result_value as Array if result_value is Array else []
			chat_history_received.emit(job_id, messages)
		"chat.send":
			var message_value: Variant = result.get("message", {})
			var chat_message: Dictionary = message_value as Dictionary if message_value is Dictionary else {}
			chat_reply_received.emit(job_id, chat_message, float(result.get("dailySpend", 0.0)))
		"job.artifacts":
			var artifacts: Array[ArtifactRecord] = []
			if result_value is Array:
				for artifact_value: Variant in result_value as Array:
					if artifact_value is Dictionary:
						artifacts.append(ArtifactRecord.from_dictionary(artifact_value as Dictionary))
			artifacts_received.emit(job_id, artifacts)
		"job.start":
			job_submission_received.emit(job_id, bool(result.get("queued", false)))
		"job.steer":
			job_steered.emit(job_id)
		"job.promote":
			var pending_value: Variant = result.get("pendingPromotions", [])
			var pending_promotions: Array = pending_value as Array if pending_value is Array else []
			promotion_state_received.emit(_studio_files_from_value(result.get("studioFiles", [])), pending_promotions)
		"studio.files":
			studio_files_received.emit(_studio_files_from_value(result_value))
		"artifact.read":
			artifact_content_received.emit(job_id, str(result.get("relativePath", result.get("name", "Artifact"))), str(result.get("content", "")))
		"studio.read":
			artifact_content_received.emit(job_id, str(result.get("relativePath", result.get("name", "Studio file"))), str(result.get("content", "")))

func _studio_files_from_value(value: Variant) -> Array[StudioFileRecord]:
	var files: Array[StudioFileRecord] = []
	if value is Array:
		for file_value: Variant in value as Array:
			if file_value is Dictionary:
				files.append(StudioFileRecord.from_dictionary(file_value as Dictionary))
	return files

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

func start_grok_login() -> void:
	_send_request("credential.grok.login.start", {})

func poll_grok_login() -> void:
	_send_request("credential.grok.login.poll", {})

func cancel_grok_login() -> void:
	_send_request("credential.grok.login.cancel", {})

func logout_grok() -> void:
	_send_request("credential.grok.logout", {})

func use_local_grok() -> void:
	_send_request("credential.grok.use_local", {})

func update_furnishing(operation_id: String, expected_revision: int, placements: Dictionary, actor_cells: Array) -> void:
	if _stdio == null:
		furnishing_failed.emit(operation_id, "The worker is disconnected. Reconnect before saving the office.")
		return
	_send_request("furnishing.update", {"operationId": operation_id, "expectedRevision": expected_revision, "placements": placements, "actorCells": actor_cells}, operation_id)

func refresh_furnishing() -> void:
	if _stdio != null: _send_request("bootstrap", {}, "furnishing")

func request_chat_history(employee_id: String) -> void:
	_send_request("chat.history", {"employeeId": employee_id}, employee_id)

func send_chat(employee_id: String, message: String) -> void:
	_send_request("chat.send", {"employeeId": employee_id, "message": message}, employee_id)

func start_job(
	job_id: String,
	employee_id: String,
	project_id: String,
	title: String,
	assignment: String,
	acceptance_criteria: PackedStringArray,
	token_budget: int,
	attached_studio_path: String = ""
	, milestone_id: String = "", revision_of_job_id: String = ""
) -> void:
	var spec: Dictionary = {
		"jobId": job_id,
		"employeeId": employee_id,
		"projectId": project_id,
		"title": title,
		"assignment": assignment,
		"acceptanceCriteria": Array(acceptance_criteria),
		"tokenBudget": token_budget,
	}
	if not attached_studio_path.is_empty():
		spec["attachedStudioPath"] = attached_studio_path
	if not milestone_id.is_empty():
		spec["milestoneId"] = milestone_id
	if not revision_of_job_id.is_empty():
		spec["revisionOfJobId"] = revision_of_job_id
	_send_request("job.start", {"spec": spec}, job_id)

func refresh_journey() -> void:
	_send_request("bootstrap", {}, "journey")

func refresh_spend() -> void:
	_send_request("bootstrap", {}, "spend")

func company_request(method: String, params: Dictionary) -> void:
	_send_request(method, params)

func request_artifacts(job_id: String) -> void:
	_send_request("job.artifacts", {"jobId": job_id}, job_id)

func read_artifact(job_id: String, relative_path: String) -> void:
	_send_request("artifact.read", {"jobId": job_id, "relativePath": relative_path}, job_id)

func remember_job(job_id: String) -> void:
	_send_request("job.remember", {"jobId": job_id}, job_id)

func cancel_job(job_id: String) -> void:
	_send_request("job.cancel", {"jobId": job_id}, job_id)

func steer_job(job_id: String, message: String) -> void:
	_send_request("job.steer", {"jobId": job_id, "message": message}, job_id)

func promote_job(job_id: String, approved: bool) -> void:
	_send_request("job.promote", {"jobId": job_id, "approved": approved}, job_id)

func request_studio_files() -> void:
	_send_request("studio.files", {})

func read_studio_file(relative_path: String, job_id: String = "") -> void:
	_send_request("studio.read", {"relativePath": relative_path}, job_id)

func set_clock(day: int, minute_of_day: int, speed: float) -> void:
	_send_request("clock.set", {"day": day, "minuteOfDay": minute_of_day, "speed": speed})

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
	_process_id = -1
