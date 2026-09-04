extends SceneTree

# Read-only visual evidence for company UI. Every image gets a fresh runtime
# scene, simulated company projection, stopped clock and disabled worker.
const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/ui-elements-audit/shell"
var _main: GameMain
var _captures: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	var cases: Array[Dictionary] = [
		{"name": "title-new", "mode": "title", "hires": 0},
		{"name": "title-continue", "mode": "title", "hires": 2},
		{"name": "journey-onboarding", "mode": "journey", "hires": 0},
		{"name": "journey-onboarding-bottom", "mode": "journey", "hires": 0, "scroll": 9999},
		{"name": "journey-available", "mode": "journey", "hires": 1},
		{"name": "journey-active", "mode": "journey", "hires": 1, "status": "active"},
		{"name": "journey-revision", "mode": "journey", "hires": 1, "status": "revision_required"},
		{"name": "journey-revision-actions", "mode": "journey", "hires": 1, "status": "revision_required", "scroll": 410},
		{"name": "journey-ready", "mode": "journey", "hires": 1, "status": "ready"},
		{"name": "pause-settings", "mode": "settings", "hires": 2},
		{"name": "pause-settings-bottom", "mode": "settings", "hires": 2, "scroll": 9999},
		{"name": "hire-confirmation", "mode": "hired", "hires": 1},
		{"name": "day-closing", "mode": "closing", "hires": 2},
		{"name": "day-summary", "mode": "summary", "hires": 2},
		{"name": "reset-confirmation", "mode": "confirm", "hires": 2},
	]
	for fixture: Dictionary in cases:
		await _fresh_main(fixture)
		if not _capture(fixture):
			await _cleanup()
			quit(1)
			return
	var manifest := {"viewport": [1280, 720], "workerDisabled": true, "isolatedFixtures": true,
		"note": "CompanyPanel's existing public presentation and explicit deterministic projections only; no button callbacks or provider requests.",
		"captures": _captures}
	var file := FileAccess.open(OUTPUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	await _cleanup()
	print("UI shell audit: %d isolated 1280x720 captures; no worker or saved-state access" % _captures.size())
	quit()

func _fresh_main(fixture: Dictionary) -> void:
	await _cleanup()
	_main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(_main)
	await _settle(5)
	_main.game_audio.set_volumes(0.0, 0.0)
	_main.day_clock.set_speed(0.0)
	var hires := int(fixture["hires"])
	_main.day_clock.set_time(2 if fixture["mode"] == "summary" else 1, DayClock.WORK_END if fixture["mode"] == "closing" else DayClock.WORK_START)
	var employees: Array[EmployeeRecord] = []
	var records := _main.room.placeholder_records()
	for index: int in range(hires): employees.append(records[index])
	_main._spawn_employees(employees)
	_main.room.set_hire_count(hires)
	_main.job_panel.set_credential_status(true)
	_main.job_panel.set_worker_ready()
	_main.job_panel.close_drawer(false)
	_main.founder_hud.dismiss_movement_hint()
	_main.founder_hud.hide_delivery()
	_main.artifact_viewer.hide()
	var state := _state(hires, str(fixture.get("status", "available")))
	_main.company_panel.day = _main.day_clock.day
	_main._on_journey(state)
	if str(fixture.get("status", "")) == "active":
		_main._job_employees["website-audit"] = "mira"
		_main.job_panel.begin_job("website-audit", "mira")
		_main.job_panel.accept_submission("website-audit")
		var started := WorkerEventRecord.new()
		started.type = &"job.started"
		_main._on_job_event("website-audit", started)
	_main.company_panel.present(str(fixture["mode"]))
	if fixture["mode"] == "summary": _main.company_panel.show_summary(state["daySummary"])
	await _settle(20)
	_main.company_panel._scroll.scroll_vertical = int(fixture.get("scroll", 0))
	await _settle(3)
	await create_timer(0.22).timeout
	await process_frame

func _state(hires: int, status: String) -> Dictionary:
	var website := {"id": "website", "title": "Build a website", "employeeId": "mira",
		"files": ["site/index.html", "site/styles.css"], "rewardCents": 60000, "reputation": 10,
		"state": "locked" if hires == 0 else "available", "availableFromDay": 1}
	if hires == 2: website["state"] = "completed"
	if status == "active":
		website.merge({"state": "active", "jobId": "website-audit", "jobStatus": "running"}, true)
	if status in ["revision_required", "ready"]:
		website.merge({"state": "revision_required" if status == "revision_required" else "active", "jobId": "website-audit", "jobStatus": "completed",
			"evaluation": {"verdict": "revise" if status == "revision_required" else "ready", "score": 2.25 if status == "revision_required" else 2.75,
				"summary": "The offer is clear, but the signup flow needs a usable next step." if status == "revision_required" else "The website meets the brief and is ready for founder review.",
				"criteria": [{"name": "Offer clarity", "score": 3, "evidence": "The headline identifies the target customer and one useful promise."},
					{"name": "Page structure", "score": 2, "evidence": "The page has an offer, benefits, evidence, and a clear next step."},
					{"name": "Calls to action", "score": 1 if status == "revision_required" else 3, "evidence": "The signup button points to a placeholder." if status == "revision_required" else "The signup call to action opens the contact form."},
					{"name": "Completeness", "score": 3, "evidence": "Both requested files are present and contain complete content."}]}}, true)
	return {"company": {"cashCents": 30000 if hires == 2 else 0, "earnedCents": 60000 if hires == 2 else 0, "reputation": 10 if hires == 2 else 0, "chapter": 1},
		"player": {"movementSeen": hires > 0},
		"candidates": [{"id": "mira", "name": "Mina", "role": "Product + research", "costCents": 0, "available": hires == 0, "hired": hires >= 1},
			{"id": "theo", "name": "Theo", "role": "Growth + operations", "costCents": 30000, "available": false, "hired": hires >= 2}],
		"milestones": [website,
			{"id": "ads", "title": "Run ads", "state": "locked", "availableFromDay": 2, "files": ["ads/campaign-plan.md", "ads/creative.md"]},
			{"id": "incorporate", "title": "Incorporate", "state": "locked", "availableFromDay": 3, "files": ["company/incorporation-readiness.md", "company/incorporation-checklist.md"]}],
		"daySummary": {"day": 1, "earnedCents": 60000, "reputation": 10, "aiSpend": 0.0437,
			"completedWork": ["Build a website"], "entries": [{"label": "Website milestone"}, {"label": "Hired Theo"}], "nextMilestone": "Run ads"}}

func _capture(fixture: Dictionary) -> bool:
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var name_value := str(fixture["name"])
	var path := "%s/%s.png" % [OUTPUT, name_value]
	if image.get_size() != Vector2i(1280, 720) or image.save_png(path) != OK:
		push_error("Could not capture native UI: " + name_value)
		return false
	_captures.append({"name": name_value, "mode": fixture["mode"], "path": ProjectSettings.globalize_path(path),
		"hires": fixture["hires"], "status": fixture.get("status", "available"), "scroll": _main.company_panel._scroll.scroll_vertical})
	print("UI shell captured: " + name_value)
	return true

func _cleanup() -> void:
	if not is_instance_valid(_main): return
	_main.game_audio.shutdown()
	await create_timer(0.05).timeout
	root.remove_child(_main)
	_main.free()
	await _settle(2)

func _settle(frames: int) -> void:
	for frame: int in range(frames): await process_frame
