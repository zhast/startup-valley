extends SceneTree
const FIXTURE := preload("res://tools/grounded_engineer_mat_fixture.gd")
const BASELINE := preload("res://tools/engineer_mat_fixture.gd")
const OUTPUT := "res://tests/output/grounded-work-shadow"
var checks := 0
var failures: Array[String] = []
var physics_ticks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func make_fixture() -> Node:
	return FIXTURE.new()

func result_directory() -> String:
	return OUTPUT

func mechanics(actor: EmployeeAvatar) -> Array:
	var layers: Array = []
	for part: Sprite2D in actor._work_pose_layer_sprites.values(): layers.append([part.position, part.region_rect, part.z_index, part.visible])
	return [actor.position, actor.desk_position, actor._route.duplicate(), actor._requested_target,
		actor._has_target, actor._activity, actor._effect_elapsed, actor._animation_elapsed,
		actor._effect_sprite.position, actor._effect_sprite.region_rect, actor._effect_sprite.visible,
		actor._character_sprite.position, actor._character_sprite.region_rect, actor.work_state,
		actor._seat_transition_elapsed, actor._seat_visual_offset, actor.z_index, layers,
		actor.navigation.actors.duplicate(), actor.navigation.reservations.duplicate()]

func check_floor(actor: EmployeeAvatar, station_depth: bool) -> void:
	check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(0, -2), "Shadow stays on physical floor through all pose states")
	check(not actor._shadow_sprite.z_as_relative, "Opt-in shadow has independent absolute floor depth")
	var expected := int(actor.position.y)
	if station_depth: expected = roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.ground_shadow_z_offset)
	check(actor._shadow_sprite.z_index == expected, "Shadow uses derived workstation depth only while mounted/transitioning")
	check(actor._shadow_sprite.visible and actor._shadow_sprite.modulate == Color.WHITE and actor._shadow_sprite.scale == Vector2.ONE, "Shadow is never hidden, recolored or rescaled")

func step(actor: EmployeeAvatar, at_desk: bool) -> void:
	var arrived := false
	var visited_transition := false
	for tick: int in range(600):
		actor._physics_process(1.0 / 30.0)
		physics_ticks += 1
		check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Actual route remains physically safe")
		check_floor(actor, actor._uses_seated_visual() or actor._seat_transition_active)
		visited_transition = visited_transition or actor._seat_transition_active
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active:
			arrived = true
			break
	check(arrived, "Actual path and seat interpolation settle")
	check(visited_transition, "Real mount/dismount interpolation was exercised")
	check(actor.position == (actor.desk_position if at_desk else actor.home_position), "Shadow correction never changes the destination")

func gates(owner: Node, facing: String) -> void:
	var model: OfficeLayout = owner.model
	var original: Dictionary = model.catalog.desk.facing_profiles[facing].duplicate(true)
	for value: Variant in [1, "true", null, []]:
		model.catalog.desk.facing_profiles[facing] = original.duplicate(true)
		model.catalog.desk.facing_profiles[facing].grounded_work_shadow = value
		check(not model.resolve_profile("desk", facing).errors.is_empty(), "Nonboolean shadow opt-in fails closed")
	model.catalog.desk.facing_profiles[facing] = original.duplicate(true)
	model.catalog.desk.facing_profiles[facing]["ground_shadow_z_offset"] = -999
	check(not model.resolve_profile("desk", facing).errors.is_empty(), "Authored shadow depth cannot bypass canonical layer-derived depth")
	model.catalog.desk.facing_profiles[facing] = original.duplicate(true)
	model.catalog.desk.facing_profiles[facing].status = "runtime_ready"
	model.catalog.desk.facing_profiles[facing].review = {"art": true, "geometry": true, "poses": true}
	check(not model.resolve_profile("desk", facing).errors.is_empty(), "Review flags do not enable this dev-only correction in production")
	model.catalog.desk.facing_profiles[facing] = original
	var service: Dictionary = model.catalog.artifact_archive.facing_profiles.south.duplicate(true)
	for field: String in ["grounded_work_shadow", "ground_shadow_z_offset"]:
		model.catalog.artifact_archive.facing_profiles.south = service.duplicate(true)
		model.catalog.artifact_archive.facing_profiles.south[field] = false if field == "grounded_work_shadow" else -3
		check(not model.resolve_profile("artifact_archive", "south").errors.is_empty(), "Standing archive rejects seated shadow field even when false: " + field)
		var resolved := model.resolve({"id": "test-service", "kind": "artifact_archive", "grid": [4, 13], "facing": "south"})
		check(not resolved.has(field), "Service placement never leaks seated shadow metadata")
	model.catalog.artifact_archive.facing_profiles.south = service
	var outsider := OfficeLayout.new()
	outsider.configure(model.data, model.catalog)
	check(not outsider.resolve_profile("desk", facing).errors.is_empty(), "A copied profile without its live owner cannot enable grounded shadows")
	var production := OfficeLayout.new()
	check(production.load_files(), "Production model reads the reviewed catalog")
	var legacy_catalog: Dictionary = production.catalog.duplicate(true)
	legacy_catalog.desk.erase("facing_profiles")
	legacy_catalog.desk.facings = ["south"]
	var legacy := OfficeLayout.new()
	legacy.configure(production.data, legacy_catalog)
	for stage: int in range(5):
		for placement: Dictionary in legacy.resolve_placements(stage):
			check(not placement.has("grounded_work_shadow") and not placement.has("ground_shadow_z_offset"), "Reconstructed legacy placements receive no implicit reviewed capability fields")
	legacy.catalog.desk["grounded_work_shadow"] = true
	legacy.catalog.desk["calibration_preview"] = true
	check(not legacy.resolve_profile("desk", "south").errors.is_empty(), "Legacy raw/forged calibration marker cannot enable correction")

func run_direction(facing: String) -> void:
	var owner := make_fixture()
	owner.employee_ids.assign(["mira", "theo"])
	owner.initial_facing = facing
	root.add_child(owner)
	await process_frame
	check(owner.ready_ok, "Actual calibrated fixture is admitted")
	if owner.ready_ok:
		owner.main.set_process(false)
		gates(owner, facing)
		for id: String in ["mira", "theo"]:
			var actor: EmployeeAvatar = owner.main.get_employee(id)
			actor.set_physics_process(false)
			check(bool(actor._workstation_visual.get("grounded_work_shadow", false)), "Explicit correction propagates from model to actual actor")
			var expected_depth := 4096
			for entry: Dictionary in owner.model.resolve_profile("desk", facing).profile.render_layers: expected_depth = mini(expected_depth, int(entry.z_offset))
			check(actor._workstation_visual.ground_shadow_z_offset == expected_depth - 1, "TownRoom derives one pixel below every own layer, including chair")
			var accepted: Dictionary = actor._workstation_visual.duplicate(true)
			for invalid: Variant in ["-3", null, 0.25, INF, -4097, 4096]:
				var metadata := accepted.duplicate(true)
				metadata.ground_shadow_z_offset = invalid
				check(not actor.configure_workstation_visual(metadata) and actor._workstation_visual == accepted, "Malformed actor depth cannot mutate the previous admitted state")
			owner.send_to_desk(id)
			step(actor, true)
			for state: EmployeeAvatar.WorkState in [EmployeeAvatar.WorkState.SITTING, EmployeeAvatar.WorkState.TYPING]:
				actor.work_state = state
				actor._update_character_frame()
				check_floor(actor, true)
				var snapshot := mechanics(actor)
				var baseline := accepted.duplicate(true)
				baseline.erase("grounded_work_shadow")
				baseline.erase("ground_shadow_z_offset")
				baseline.erase("grounded_work_shadow_follow_seat_x")
				check(actor.configure_workstation_visual(baseline), "Legacy-equivalent metadata still accepted")
				check(actor._shadow_sprite.position == Vector2(0, -2) + actor.seated_render_offset() + actor.position.round() - actor.position and actor._shadow_sprite.z_as_relative and actor._shadow_sprite.z_index == 0, "Absent option exactly restores former position/inherited depth")
				check(actor.configure_workstation_visual(accepted) and mechanics(actor) == snapshot, "Only shadow presentation changes; feet, poses, cue, timing, navigation remain identical")
				actor.world_paused = true
				var floor_before := actor._shadow_sprite.global_position
				var seat_before := actor._seat_visual_offset
				actor._physics_process(0.25)
				check(actor._shadow_sprite.global_position == floor_before and actor._seat_visual_offset == seat_before, "Pause cannot lift or move the shadow/socket")
				actor.world_paused = false
			owner.leave_desk(id)
			step(actor, false)
			check_floor(actor, false)
			for terminal: StringName in [&"job.failed", &"job.completed"]:
				owner.send_to_desk(id)
				step(actor, true)
				actor.has_live_job = true
				var event := WorkerEventRecord.new()
				event.type = terminal
				actor.apply_worker_event(event, actor.home_position)
				for tick: int in range(8):
					actor._physics_process(1.0 / 30.0)
					check_floor(actor, actor._uses_seated_visual() or actor._seat_transition_active)
				check(not actor._seat_transition_active, "Terminal departure removes station-relative shadow depth")
				check_floor(actor, false)
				owner.leave_desk(id)
				# It is already standing here, so a second seat transition is
				# neither expected nor artificially manufactured.
				for tick: int in range(600):
					actor._physics_process(1.0 / 30.0)
					if not actor._has_target: break
		# Capability loss must clear custom depth without stale seat elevation.
		for id: String in ["mira", "theo"]:
			owner.send_to_desk(id)
			step(owner.main.get_employee(id), true)
		var definition: Dictionary = owner.pose_registry()
		check(CharacterArt.unregister_calibration_pose_set(owner.pose_set_id, owner), "Temporary capability can be explicitly revoked")
		for id: String in ["mira", "theo"]:
			var actor: EmployeeAvatar = owner.main.get_employee(id)
			actor._update_character_frame()
			check_floor(actor, false)
		check(CharacterArt.register_calibration_pose_set(owner.pose_set_id, definition, owner), "Existing pose source registration restored for separate missing-pose test")
		check(CharacterArt.unregister_calibration_pose_set(owner.pose_set_id, owner), "Replace only dev registry definition")
		definition.facings[facing].erase("typing")
		check(CharacterArt.register_calibration_pose_set(owner.pose_set_id, definition, owner), "Other real poses remain registered with typing deliberately absent")
		for id: String in ["mira", "theo"]:
			var actor: EmployeeAvatar = owner.main.get_employee(id)
			actor.work_state = EmployeeAvatar.WorkState.TYPING
			actor._update_character_frame()
			check_floor(actor, false)
	owner.free()
	await process_frame

func run() -> void:
	for facing: String in ["north", "east", "south", "west"]: await run_direction(facing)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(result_directory()))
	var file := FileAccess.open(result_directory().path_join("results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "physics_ticks": physics_ticks, "worker_disabled": true, "production_catalog_written": false}, "\t"))
	print("Grounded work shadow: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
