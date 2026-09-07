extends "res://tools/play_calibrated_workstation.gd"
## DEV ONLY: same isolated fixture and controls, with an unobstructed first view.
## No credential flag changes, worker, saving, exporting or repeated UI hiding.

static func finish_startup(viewer: Node) -> void:
	# The inherited fixture's missing-key presentation opens a connection drawer
	# through call_deferred after its own synchronous close. Settle that callback
	# once, then use the ordinary close path; later user-opened panels stay live.
	for tick: int in range(2): await viewer.get_tree().process_frame
	if not is_instance_valid(viewer) or not viewer.ready_ok: return
	viewer.main.job_panel.close_drawer(false)
	viewer.get_viewport().gui_release_focus()

func run() -> void:
	await super.run()
	if is_instance_valid(fixture) and fixture.ready_ok:
		await finish_startup(fixture)
