extends "res://tools/calibrated_service_fixture.gd"
const BENCH := preload("res://tools/prototype_bench_geometry.gd")
const BENCH_ID := "prototype-bench"
class BenchEditor extends "res://tools/calibrated_service_fixture.gd".ServiceEditor:
	func _build_interface() -> void:
		super._build_interface(); _status.text = "PROTOTYPE BENCH · dev review · no worker or saves"
func _ready() -> void:
	if not OS.has_feature("editor"): errors.append("Prototype fixture requires editor Godot"); return
	previous_no_worker = OS.get_environment("STARTUP_VALLEY_NO_WORKER"); OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	main = load("res://world/main.tscn").instantiate() as GameMain; main.get_node("WorkerClient").set_script(TRANSPORT.NullWorker); add_child(main)
	main.game_audio.set_volumes(0, 0); main.day_clock.set_speed(0); main._state_loaded = false; main._worker_ready = false; main.job_panel.set_worker_ready(); main.founder_hud.dismiss_movement_hint(); main._spawn_employees([]); main.job_panel.close_drawer(false); main.company_panel.hide()
	var data := main.room.layout_model.data.duplicate(true); var catalog := main.room.layout_model.catalog.duplicate(true)
	data.player_spawn = [17, 18]; data.props = [{"id": BENCH_ID, "kind": "prototype_bench", "grid": [10, 13], "facing": initial_facing, "required_hires": 0}]; data.employees = []; catalog.prototype_bench = BENCH.catalog_entry()
	model = OfficeLayout.new(); model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Prototype live owner rejected"); return
	for facing: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_service_profile("prototype_bench", facing, self): errors.append("Candidate rejected: " + facing)
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage)); if not validation.valid: errors.append("Stage%d: %s" % [stage, str(validation.errors)])
	if not errors.is_empty(): return
	main.room.layout_model = model; main.room.player_spawn = Vector2i(17, 18); main.room.placement_overrides.clear(); main.room.architecture.configure(model); main.room.set_hire_count(0); main.player.cancel_route(); main.player.position = model.world(Vector2i(17, 18)); main.room.navigation.actors["founder"] = main.player.position
	editor = BenchEditor.new(); editor.game = main; add_child(editor); editor.select_placement(BENCH_ID); ready_ok = true
func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
