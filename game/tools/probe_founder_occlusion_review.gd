extends "res://tools/capture_founder_occlusion.gd"
## Independent review only: never writes the frozen founder BEFORE/AFTER files.
const REVIEW_OUTPUT := "res://tests/output/founder-occlusion-review"
var details: Array[Dictionary] = []

func run() -> void:
	if DisplayServer.get_name() != "headless":
		push_error("Independent review probe is headless-only")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var baseline_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for repeat_index: int in range(3):
		await setup()
		var mina := main.get_employee("mira")
		mina.position = Vector2(464, 432)
		mina.work_state = EmployeeAvatar.WorkState.IDLE
		mina._has_target = false
		mina._route.clear()
		mina._animation_elapsed = 0
		mina._update_character_frame()
		main.player.position = Vector2(464, 464)
		main.player.face_direction(Vector2.DOWN)
		main.player._physics_process(0)
		main._process(0)
		await frames()
		var founder := main.player._character_sprite
		var hole := Vector2.INF
		var overlap := Vector2.INF
		var shadow_only := Vector2.INF
		for y: int in range(392, 472):
			for x: int in range(440, 488):
				var point := Vector2(x + 0.5, y + 0.5)
				var painted := main.player.body_surface_at(point) != null
				if mina.body_surface_at(point) != null:
					if painted: overlap = point
					else: hole = point
				if not painted and VisibleSurface.painted(main.player._shadow_sprite, point): shadow_only = point
		check(hole.is_finite(), "Real founder atlas transparency overlaps a visible employee")
		if hole.is_finite():
			check(str(main._interaction_at(hole).get("id", "")) == "mira", "Transparent founder pixel leaves visible Mina selectable")
			await click(hole)
			check(main._pending_interaction == "mira", "Real click passes through founder atlas transparency")
		check(shadow_only.is_finite(), "Real shadow-only pixels exist outside founder body")
		if shadow_only.is_finite(): check(main.player.body_surface_at(shadow_only) == null, "Shadow does not enlarge founder body hit mask")
		check(overlap.is_finite(), "Real opaque overlap exists")
		if overlap.is_finite():
			main.player.modulate.a = 0
			check(main.player.body_surface_at(overlap) == null, "Ancestor alpha zero removes founder occlusion")
			check(str(main._interaction_at(overlap).get("id", "")) == "mira", "Underlying employee selectable under transparent parent")
			main.player.modulate.a = 1
			main.player.cancel_route()
			await click(overlap)
			check(main._pending_interaction.is_empty(), "Opaque founder suppresses hidden employee action")
			check(not main.player.route.is_empty(), "Suppressed action retains ordinary ground-click movement")
			check(main.player._route_target == overlap, "Ground click uses visible pixel coordinate, not hidden employee socket")
			# Same effective depth must follow scene order in both directions.
			mina.z_index = main.player.z_index
			check(main._interaction_at(overlap).is_empty(), "Founder later in equal-depth scene order hides employee")
			var actors := mina.get_parent()
			var old_index := actors.get_index()
			main.move_child(actors, main.get_child_count() - 1)
			check(str(main._interaction_at(overlap).get("id", "")) == "mira", "Moving employee branch later at equal depth exposes employee")
			main.move_child(actors, old_index)
		# Find a blocked floor cell independently of the monitor's visual overhang.
		mina.position = mina.desk_position
		mina.work_state = EmployeeAvatar.WorkState.SITTING
		mina._update_character_frame()
		main.player.position = Vector2(336, 304)
		main.player._physics_process(0)
		main._process(0)
		var blocked_point := Vector2.INF
		for y: int in range(232, 312):
			for x: int in range(312, 360):
				var point := Vector2(x + 0.5, y + 0.5)
				if main.player.body_surface_at(point) != null and not main.room.navigation.walkable(main.room.navigation.cell_at(point)) and main._interaction_at(point).is_empty():
					blocked_point = point
		check(blocked_point.is_finite(), "Actual opaque founder body overlaps blocked ground")
		if blocked_point.is_finite():
			await click(blocked_point)
			check(main._pending_interaction.is_empty() and main.player.route.is_empty(), "Blocked founder-covered ground neither opens hidden desk nor starts a route")
		details.append({"repeat": repeat_index, "atlas_hole": [hole.x, hole.y], "opaque_overlap": [overlap.x, overlap.y], "shadow_only": [shadow_only.x, shadow_only.y], "blocked_floor_overlap": [blocked_point.x, blocked_point.y]})
		var node_id := main.get_instance_id()
		main.game_audio.shutdown()
		main.free()
		main = null
		await frames(3)
		check(not is_instance_id_valid(node_id), "Fixture GameMain is actually destroyed")
		check(root.get_child_count() == 0, "No fixture node survives teardown")
		check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == baseline_orphans, "Repeated setup/free adds no orphan Nodes")
	# Let already queued transient UI timers finish before judging shutdown leaks.
	await create_timer(0.3).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_OUTPUT))
	var result := {"checks": checks, "failures": failures, "details": details, "baseline_orphan_nodes": baseline_orphans, "final_orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "renderer_used": false, "worker_or_save_access": false}
	var file := FileAccess.open(REVIEW_OUTPUT.path_join("headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("Independent founder review: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
