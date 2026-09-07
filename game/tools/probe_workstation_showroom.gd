extends "res://tools/probe_workstation_entry.gd"
## Same real input replay; corrected launch writes only its own AFTER evidence.
const SAFE_ENTRY := preload("res://tools/play_workstation_showroom.gd")

func output_directory() -> String:
	return "res://tests/output/workstation-entry-after/"

func launch_viewer() -> void:
	await super.launch_viewer()
	await SAFE_ENTRY.finish_startup(fixture)

func snapshot(label: String) -> void:
	await super.snapshot(label)
	check(not fixture.main.job_panel._connection_panel.visible and not fixture.main.job_panel.drawer_is_open(), label + ": startup drawer remains closed without an ongoing override")
	check(not fixture.main.job_panel._credential_configured and fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, label + ": credential still absent and transport still isolated")
