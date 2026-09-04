extends "res://tools/capture_visual_review.gd"
## Reuses isolated static fixtures without changing production fonts or captures.
const C_OVERLAY = preload("res://tools/typography-options/audit_c_overlay.gd")
const C_OUTPUT := "res://tests/output/typography-audit-c"
var _c_evidence: Array[Dictionary] = []
var _production := "--production" in OS.get_cmdline_user_args()

func _capture(name_value: String) -> bool:
	if not _production: C_OVERLAY.apply(_main)
	await create_timer(0.25).timeout
	await process_frame
	RenderingServer.force_draw(false)
	var output := C_OUTPUT + ("-production" if _production else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var path := output.path_join(name_value + ".png")
	var rendered := root.get_texture().get_image()
	if rendered.get_size() != Vector2i(1280, 720) or rendered.save_png(path) != OK:
		push_error("Typography C capture failed: " + name_value)
		quit(1)
		return false
	var controls: Array[Dictionary] = []
	C_OVERLAY.inventory(_main, controls)
	if _production:
		for control: Dictionary in controls:
			if str(control.font).contains("tools/"):
				push_error("Production acceptance contains a developer font: " + str(control))
				quit(1)
				return false
	_c_evidence.append({"name": name_value, "path": path, "controls": controls})
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"workerDisabled": true, "previewOnly": not _production, "productionTypography": _production, "viewport": [1280, 720], "captures": _c_evidence}, "\t"))
	file.close()
	print("C typography audit: " + name_value)
	if name_value == "ui-artifact":
		_main.artifact_viewer.show_artifact("research/résumé–validation-notes-for-the-first-company-launch-and-customer-interviews.md", _sample_artifact())
		await _capture("ui-artifact-unicode-long-title")
		_main.artifact_viewer.show_artifact("site/index.html", "<!doctype html>\n<html>\n  <head>\n    <title>Startup Valley</title>\n  </head>\n  <body>\n    <main class=\"launch-card\">\n      <h1>One clear promise</h1>\n      <p>A useful first version.</p>\n    </main>\n  </body>\n</html>")
		await _capture("ui-artifact-source")
		if _production:
			_main.artifact_viewer.show_artifact("company/会社の計画—产品验证—résumé.html", "<!doctype html>\n<html>\n  <body>\n    <h1>会社の計画 · 产品验证 · résumé</h1>\n    <p>One clear promise → one useful first version.</p>\n  </body>\n</html>")
			await _capture("ui-artifact-cjk-source")
	return true
