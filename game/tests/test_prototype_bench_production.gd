extends SceneTree
const RUNTIME := "res://assets/runtime/office/prototype-bench-v1/"
const SOURCE := "res://tests/fixtures/furniture-calibration/prototype-bench-v1/"
const PARTS: Array[String] = ["floor_shadow", "rear_structure", "front_structure", "tool_overlay"]
var checks := 0; var failures: Array[String] = []
func _initialize() -> void: OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1"); call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var model := OfficeLayout.new(); check(model.load_files(), "Production model loads"); check(model.available_facings("prototype_bench") == OfficeLayout.FACINGS, "Prototype bench exposes four reviewed views")
	for side: String in OfficeLayout.FACINGS:
		var result := model.resolve_profile("prototype_bench", side); check(result.errors.is_empty(), side + " resolves")
		var profile: Dictionary = result.profile; check(profile.profile_kind == "service" and profile.service_side == side and profile.approach_gaze == OfficeLayout.OPPOSITE_GAZE[side], side + " service contract")
		for part: String in PARTS:
			var name := side + "-" + part + ".png"; check(FileAccess.file_exists(RUNTIME + name), "Runtime exists " + name); check(FileAccess.get_sha256(RUNTIME + name) == FileAccess.get_sha256(SOURCE + name), "Byte-exact reviewed source " + name)
		var original: Dictionary = model.catalog.prototype_bench.facing_profiles[side].duplicate(true); model.catalog.prototype_bench.facing_profiles[side].status = "candidate"; check(not model.resolve_profile("prototype_bench", side).errors.is_empty(), side + " candidate status fails closed"); model.catalog.prototype_bench.facing_profiles[side] = original
	var main := load("res://world/main.tscn").instantiate() as GameMain; root.add_child(main); await process_frame; main.set_process(false); main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0); main.room.set_hire_count(4); check(main.worker_client._stdio == null, "No worker")
	for side: String in OfficeLayout.FACINGS:
		check(main.room.set_placement_overrides({"prototype-bench": {"grid": [29, 18], "facing": side}}), "Normal room commits " + side); main._on_room_placements_changed(); var placement := main.room.placement_by_id("prototype-bench"); check(placement.facing == side and main.room.navigation.walkable(placement.interaction), side + " production placement and aisle")
	main.game_audio.shutdown(); main.free(); await process_frame; print("Prototype bench production: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
