extends "res://tests/test_grounded_work_shadow.gd"
const REFINED := preload("res://tools/horizontal_grounded_mat_fixture.gd")

func make_fixture() -> Node:
	return REFINED.new()

func result_directory() -> String:
	return "res://tests/output/grounded-shadow-x-follow"

func run() -> void:
	for facing: String in ["north", "east", "south", "west"]: await run_direction(facing)
	check(checks >= 20960 and physics_ticks == 3940, "All four inherited lifecycle cases must finish; runtime-aborted test bodies cannot appear green")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(result_directory()))
	var file := FileAccess.open(result_directory().path_join("results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "physics_ticks": physics_ticks, "worker_disabled": true, "production_catalog_written": false}, "\t"))
	print("Horizontal grounded shadow: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_floor(actor: EmployeeAvatar, station_depth: bool) -> void:
	var x := actor.seated_render_offset().x if station_depth else 0.0
	check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(x, -2), "Refined shadow follows snapped seated X only, never vertical seat lift")
	check(not actor._shadow_sprite.z_as_relative, "Refined ground depth remains absolute")
	var expected := int(actor.position.y)
	if station_depth: expected = roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.ground_shadow_z_offset)
	check(actor._shadow_sprite.z_index == expected, "Refined shadow retains derived depth and restores physical depth")
	check(actor._shadow_sprite.visible and actor._shadow_sprite.modulate == Color.WHITE and actor._shadow_sprite.scale == Vector2.ONE, "Refinement never hides/repaints/rescales shadow")

func step(actor: EmployeeAvatar, at_desk: bool) -> void:
	super.step(actor, at_desk)
	if not at_desk: return
	var accepted := actor._workstation_visual.duplicate(true)
	var snapshot := mechanics(actor)
	var first_policy := accepted.duplicate(true)
	first_policy.grounded_work_shadow_follow_seat_x = false
	check(actor.configure_workstation_visual(first_policy), "Explicit false remains the admitted first floor-only policy")
	check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(0, -2), "False does not silently inherit horizontal alignment")
	check(actor.configure_workstation_visual(accepted) and mechanics(actor) == snapshot, "Switching only horizontal policy preserves every non-shadow state")

func gates(owner: Node, facing: String) -> void:
	super.gates(owner, facing)
	var model: OfficeLayout = owner.model
	var original: Dictionary = model.catalog.desk.facing_profiles[facing].duplicate(true)
	for value: Variant in [1, "true", null, []]:
		model.catalog.desk.facing_profiles[facing] = original.duplicate(true)
		model.catalog.desk.facing_profiles[facing].grounded_work_shadow_follow_seat_x = value
		check(not model.resolve_profile("desk", facing).errors.is_empty(), "Horizontal-follow option requires explicit boolean")
	model.catalog.desk.facing_profiles[facing] = original.duplicate(true)
	model.catalog.desk.facing_profiles[facing].grounded_work_shadow = false
	check(not model.resolve_profile("desk", facing).errors.is_empty(), "Horizontal follow cannot be enabled without grounded shadow admission")
	model.catalog.desk.facing_profiles[facing] = original
	var service: Dictionary = model.catalog.artifact_archive.facing_profiles.south.duplicate(true)
	model.catalog.artifact_archive.facing_profiles.south["grounded_work_shadow_follow_seat_x"] = false
	check(not model.resolve_profile("artifact_archive", "south").errors.is_empty(), "Service profile rejects horizontal seated-shadow metadata even false")
	model.catalog.artifact_archive.facing_profiles.south = service
	for id: String in ["mira", "theo"]:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		check(bool(actor._workstation_visual.get("grounded_work_shadow_follow_seat_x", false)), "Horizontal policy reaches actual actor through model and room")
		var accepted := actor._workstation_visual.duplicate(true)
		for value: Variant in [1, "true", null]:
			var invalid := accepted.duplicate(true)
			invalid.grounded_work_shadow_follow_seat_x = value
			check(not actor.configure_workstation_visual(invalid) and actor._workstation_visual == accepted, "Invalid actor follow flag preserves previous accepted state")
		var unsupported := accepted.duplicate(true)
		unsupported.grounded_work_shadow = false
		check(not actor.configure_workstation_visual(unsupported), "Actor also rejects ungrounded horizontal-follow shortcut")
