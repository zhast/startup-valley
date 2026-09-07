extends SceneTree

const RUNTIME := "res://assets/runtime/office/research-bench-v1/"
const SOURCE := "res://tests/fixtures/furniture-calibration/research-bench-v1/"
const PARTS: Array[String] = ["floor_shadow", "rear_structure", "front_structure", "tool_overlay"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func run() -> void:
	var model := OfficeLayout.new(); check(model.load_files(), "Production model loads")
	check(model.available_facings("research_table") == OfficeLayout.FACINGS, "Research bench exposes four reviewed views")
	for side: String in OfficeLayout.FACINGS:
		var resolved := model.resolve_profile("research_table", side); check(resolved.errors.is_empty(), side + " resolves: " + str(resolved.errors))
		var profile: Dictionary = resolved.profile
		check(profile.status == "runtime_ready" and profile.review.art and profile.review.geometry and profile.review.poses, side + " review gates")
		check(profile.work_facing == side and profile.pose_set == CharacterArt.REVIEWED_WORKSTATION_POSE_SET, side + " directional pose contract")
		var expected_interaction: Dictionary = {"north": [0, 1], "east": [-1, 0], "south": [0, -1], "west": [1, 0]}
		var expected_cell := OfficeLayout.vector(expected_interaction[side])
		check(OfficeLayout.vector(profile.interaction) == expected_cell and OfficeLayout.vector(profile.work_cell) == expected_cell, side + " employee stands opposite their gaze")
		for employee: String in ["mira", "theo"]:
			check(CharacterArt.supports_work_pose(employee, profile.pose_set, side, "research"), employee + " research pose " + side)
		for part: String in PARTS:
			var name := side + "-" + part + ".png"
			check(FileAccess.file_exists(RUNTIME + name), "Runtime exists " + name)
			check(FileAccess.get_sha256(RUNTIME + name) == FileAccess.get_sha256(SOURCE + name), "Byte-exact reviewed fixture " + name)
		var original: Dictionary = model.catalog.research_table.facing_profiles[side].duplicate(true)
		model.catalog.research_table.facing_profiles[side].status = "candidate"
		check(not model.resolve_profile("research_table", side).errors.is_empty(), side + " candidate fails closed")
		model.catalog.research_table.facing_profiles[side] = original
	var main := load("res://world/main.tscn").instantiate() as GameMain; root.add_child(main); await process_frame
	main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0); main.room.set_hire_count(2)
	var default_placement := main.room.placement_by_id("research-bench")
	check(default_placement.grid == Vector2i(29, 8), "Default bench moved inward from wall")
	check(main.room.navigation.walkable(default_placement.interaction), "Default research interaction is walkable")
	for employee: String in ["mira", "theo"]:
		check(main.get_employee(employee).configure_research_visual(main.room.research_visual()), employee + " accepts production visual")
	var mina := main.get_employee("mira"); mina.world_paused = false; mina.has_live_job = true
	var research_event := WorkerEventRecord.new(); research_event.type = &"tool.started"; research_event.tool = "web_search"
	mina.apply_worker_event(research_event, main.player.position)
	var movement_ticks := 0
	while movement_ticks < 1500 and mina.position.distance_to(main.room.research_position()) > 0.5:
		movement_ticks += 1; await process_frame
	check(mina.position.distance_to(main.room.research_position()) <= 0.5, "Mina reaches contact; pos=%s target=%s state=%s" % [mina.position, main.room.research_position(), mina.work_state])
	check(mina.work_state == EmployeeAvatar.WorkState.WORKING, "Mina enters research state; state=%s target=%s" % [mina.work_state, mina._has_target])
	check(movement_ticks > 0 and movement_ticks < 1500, "Research route bounded; ticks=%d has_target=%s" % [movement_ticks, mina._has_target])
	main.game_audio.shutdown(); main.free(); await process_frame
	print("Research bench production: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
