extends "res://tools/capture_ui_shell_audit.gd"
const C_OVERLAY = preload("res://tools/typography-options/audit_c_overlay.gd")
const C_OUTPUT := "res://tests/output/typography-audit-c-shell"
var _production := "--production" in OS.get_cmdline_user_args()

func _run() -> void:
	var output := C_OUTPUT + ("-production" if _production else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280, 720)
	var cases: Array[Dictionary] = [
		{"name": "title-new", "mode": "title", "hires": 0},
		{"name": "journey-onboarding", "mode": "journey", "hires": 0},
		{"name": "journey-available", "mode": "journey", "hires": 1},
		{"name": "journey-revision", "mode": "journey", "hires": 1, "status": "revision_required"},
		{"name": "journey-revision-evidence", "mode": "journey", "hires": 1, "status": "revision_required", "details": true},
		{"name": "journey-revision-actions", "mode": "journey", "hires": 1, "status": "revision_required", "details": true, "scroll": 9999},
		{"name": "pause-settings", "mode": "settings", "hires": 2},
		{"name": "day-closing", "mode": "closing", "hires": 2},
		{"name": "day-summary", "mode": "summary", "hires": 2},
		{"name": "day-summary-large-values", "mode": "summary", "hires": 2, "largeValues": true},
		{"name": "journey-evaluating", "mode": "journey", "hires": 1, "status": "active", "evaluating": true},
		{"name": "journey-long-error", "mode": "journey", "hires": 1, "status": "revision_required", "error": true},
		{"name": "journey-evaluation-retry", "mode": "journey", "hires": 1, "retry": true},
		{"name": "reset-confirmation", "mode": "confirm", "hires": 2},
	]
	for fixture: Dictionary in cases:
		await _fresh_main(fixture)
		if bool(fixture.get("details", false)):
			_main.company_panel._details_open = true
			_main.company_panel._render()
		if bool(fixture.get("largeValues", false)):
			var summary: Dictionary = _main.company_panel.state["daySummary"].duplicate(true)
			summary["earnedCents"] = 12345678900
			summary["reputation"] = 123456
			summary["aiSpend"] = 1234.5678
			_main.company_panel.show_summary(summary)
		if bool(fixture.get("evaluating", false)):
			_main.company_panel.busy = true
			_main.company_panel._pending_method = "milestone.evaluate"
			_main.company_panel._pending_job_id = "website-audit"
			_main.company_panel._render()
		if bool(fixture.get("error", false)):
			_main.company_panel.show_error("Evaluation could not finish because the provider returned an incomplete response. Your files are saved. Retry when your connection is restored; no milestone reward has been claimed.")
		if bool(fixture.get("retry", false)):
			var retry_state := _state(1, "available")
			var milestone: Dictionary = retry_state["milestones"][0]
			milestone.merge({"state": "active", "jobId": "website-audit", "jobStatus": "completed", "evaluation": null, "evaluationError": "Provider temporarily unavailable."}, true)
			_main._on_journey(retry_state)
			_main.company_panel.present("journey")
		if not _production: C_OVERLAY.apply(_main)
		await create_timer(0.25).timeout
		await process_frame
		_main.company_panel._scroll.scroll_vertical = int(fixture.get("scroll", 0))
		await _settle(2)
		RenderingServer.force_draw(false)
		var path := output.path_join(str(fixture.name) + ".png")
		if root.get_texture().get_image().save_png(path) != OK:
			quit(1)
			return
		var controls: Array[Dictionary] = []
		C_OVERLAY.inventory(_main, controls)
		if _production:
			for control: Dictionary in controls:
				if str(control.font).contains("tools/"):
					push_error("Production acceptance contains a developer font: " + str(control))
					quit(1)
					return
		_captures.append({"name": fixture.name, "path": path, "controls": controls})
		print("C shell typography: " + str(fixture.name))
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"workerDisabled": true, "previewOnly": not _production, "productionTypography": _production, "viewport": [1280, 720], "captures": _captures}, "\t"))
	file.close()
	await _cleanup()
	quit()
