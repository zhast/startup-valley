extends SceneTree
## Explicit developer entry only; never loaded by project/main scene.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
var fixture: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.title = "Startup Valley — workstation calibration (no worker or saves)"
	fixture = FIXTURE.new()
	if "--two-employees" in OS.get_cmdline_user_args(): fixture.employee_ids.assign(["mira", "theo"])
	root.add_child(fixture)
	if not fixture.ready_ok:
		push_error(str(fixture.errors))
		quit(1)
