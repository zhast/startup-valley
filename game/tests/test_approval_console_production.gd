extends SceneTree

const RUNTIME := "res://assets/runtime/office/approval-console-v1/"
const SOURCE := "res://tests/fixtures/furniture-calibration/decision-console-v1/"
const PARTS: Array[String] = ["floor_shadow", "rear_structure", "front_structure", "ambient_overlay"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var model := OfficeLayout.new()
	check(model.load_files(), "Normal production model loads")
	check(model.available_facings("approval_console") == OfficeLayout.FACINGS, "Decision console exposes exactly four reviewed views")
	for side: String in OfficeLayout.FACINGS:
		var result := model.resolve_profile("approval_console", side)
		check(result.errors.is_empty(), side + " production profile resolves")
		var profile: Dictionary = result.profile
		check(profile.profile_kind == "service" and profile.service_side == side and profile.approach_gaze == OfficeLayout.OPPOSITE_GAZE[side], side + " retains service semantics")
		check(profile.interaction in profile.clearance, side + " interaction is in its clear aisle")
		for part: String in PARTS:
			var name := side + "-" + part + ".png"
			check(FileAccess.file_exists(RUNTIME + name), "Runtime layer exists: " + name)
			check(FileAccess.get_sha256(RUNTIME + name) == FileAccess.get_sha256(SOURCE + name), "Runtime layer is byte-exact reviewed source: " + name)
		var original: Dictionary = model.catalog.approval_console.facing_profiles[side].duplicate(true)
		model.catalog.approval_console.facing_profiles[side].status = "candidate"
		check(not model.resolve_profile("approval_console", side).errors.is_empty(), side + " status cannot forge runtime admission")
		model.catalog.approval_console.facing_profiles[side] = original
		model.catalog.approval_console.facing_profiles[side].render_layers[0].art = "res://missing-console.png"
		check(not model.resolve_profile("approval_console", side).errors.is_empty(), side + " missing art fails closed")
		model.catalog.approval_console.facing_profiles[side] = original
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "No worker starts")
	for side: String in OfficeLayout.FACINGS:
		check(main.room.set_placement_overrides({"approval-console": {"grid": [29, 13], "facing": side}}), "Normal room commits " + side)
		main._on_room_placements_changed()
		var placement := main.room.placement_by_id("approval-console")
		check(placement.facing == side and placement.profile_kind == "service", "Normal room resolves " + side)
		check(main.room.navigation.walkable(placement.interaction), side + " service cell remains walkable")
		check(main.room.interaction_at(main.room.global_position + placement.world_hit_bounds.get_center()).id == "approval-console", side + " painted hit area opens Activity station")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("Approval console production: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
