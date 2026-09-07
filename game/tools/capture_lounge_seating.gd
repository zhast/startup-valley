extends SceneTree
## DEV ONLY. Native actual-GameMain review for two passive lounge families.

const SEATING := preload("res://tools/lounge_seating_geometry.gd")
const FIXTURE := preload("res://tools/lounge_seating_fixture.gd")
const OUTPUT := "res://tests/output/lounge-seating-v3-final"
const ACTORS := {"two_seat_sofa": "founder", "lounge_armchair": "mira"}
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for _index: int in range(count): await process_frame

func shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if node is CollisionShape2D: result.append(node as CollisionShape2D)
	for child: Node in node.get_children(): result.append_array(shapes(child))
	return result

func capture(label: String) -> Image:
	await frames(2)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), label + " native viewport")
	var path := OUTPUT.path_join(label + ".png")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path.trim_prefix("res://../"))
	return image

func save_detail(frame: Image, family: String, side: String, suffix: String, placement: Dictionary) -> void:
	var size := SEATING.canvas(family)
	var crop := frame.get_region(Rect2i(Vector2i(placement.anchor) - SEATING.pivot(family), size))
	check(crop.get_size() == size, family + " " + side + " " + suffix + " native crop")
	var native := OUTPUT.path_join("%s-%s-%s-native.png" % [family, side, suffix])
	check(crop.save_png(native) == OK, "Saved " + native)
	var enlarged := crop.duplicate()
	enlarged.resize(size.x * 4, size.y * 4, Image.INTERPOLATE_NEAREST)
	var detail := OUTPUT.path_join("%s-%s-%s-4x.png" % [family, side, suffix])
	check(enlarged.save_png(detail) == OK, "Saved " + detail)
	captures.append_array([native.trim_prefix("res://../"), detail.trim_prefix("res://../")])

func actor_node(id: String) -> Node2D:
	return fixture.main.player if id == "founder" else fixture.main.get_employee(id)

func hide_actors(except := "") -> void:
	fixture.main.player.visible = except == "founder"
	for id: String in fixture.main._employees:
		var actor: EmployeeAvatar = fixture.main._employees[id]
		actor.labels_suppressed = true
		actor.visible = id == except

func overlap_order(actor: Node2D, prop: Node2D, bounds: Rect2, actor_front: bool) -> Dictionary:
	var overlap := 0
	var wrong := 0
	for y: int in range(floori(bounds.position.y), ceili(bounds.end.y)):
		for x: int in range(floori(bounds.position.x), ceili(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body: Sprite2D = actor.body_surface_at(point)
			var surface: Dictionary = fixture.main.room.surface_at(point)
			if body == null or surface.get("sprite") == null or (surface.sprite as Node).get_parent() != prop: continue
			overlap += 1
			if VisibleSurface.in_front(body, surface.sprite) != actor_front: wrong += 1
	return {"overlap": overlap, "wrong": wrong}

func actor_probe(family: String, side: String, placement: Dictionary) -> Dictionary:
	var id: String = ACTORS[family]
	var actor := actor_node(id)
	var profile := SEATING.profile(family, side)
	var cells: Array[Vector2i] = []
	for raw: Variant in profile.occupied: cells.append(Vector2i(int(raw[0]), int(raw[1])))
	var min_y: int = cells.map(func(cell: Vector2i) -> int: return cell.y).min()
	var max_y: int = cells.map(func(cell: Vector2i) -> int: return cell.y).max()
	var nearest_x := cells[0].x
	for cell: Vector2i in cells:
		if absi(cell.x) < absi(nearest_x): nearest_x = cell.x
	var base: Vector2i = fixture.model.cell_at(placement.anchor)
	var probes := {"behind": base + Vector2i(nearest_x, min_y - 1), "front": base + Vector2i(nearest_x, max_y + 1)}
	var result := {}
	hide_actors(id)
	for label: String in ["behind", "front"]:
		var cell: Vector2i = probes[label]
		# The preserved +4 probe still had zero overlap, while +12 correctly failed
		# position safety. Keep the actor at the natural clear cell center instead of
		# moving it solely to manufacture an occlusion measurement.
		var subcell_offset := Vector2.ZERO
		var point: Vector2 = fixture.model.world(cell) + subcell_offset
		check(fixture.model.is_floor(cell) and fixture.main.room.navigation.walkable(cell), family + " " + side + " " + label + " actor cell clear")
		check(fixture.model.cell_at(point) == cell, family + " " + side + " " + label + " subcell depth probe stays in the same physical cell")
		check(fixture.main.room.navigation.position_is_safe(point, id), family + " " + side + " " + label + " actor footprint safe")
		actor.position = point
		actor.z_index = int(point.y)
		fixture.main.room.navigation.actors.clear()
		fixture.main.room.navigation.actors[id] = point
		await frames(2)
		var order := overlap_order(actor, fixture.main.room.prop_node(str(placement.id)), placement.world_visual_bounds, label == "front")
		# The v3 rear shell hides the seat correctly, so the natural North cell is
		# now just clear of both families; the floor-projected E/W bodies overlap.
		# Classify what the unchanged geometry actually proves rather than carrying
		# v2's expectation map into a different drawing.
		var natural_clearance := side == "north" and label == "behind"
		if natural_clearance:
			check(int(order.overlap) == 0 and int(order.wrong) == 0, family + " " + side + " " + id + " behind remains naturally clear without an unsafe probe")
		else:
			check(int(order.overlap) > 0 and int(order.wrong) == 0, family + " " + side + " " + id + " " + label + " opaque depth")
		var frame := await capture("%s-%s-%s-%s-room" % [family, side, id, label])
		save_detail(frame, family, side, id + "-" + label, placement)
		result[label] = {"cell": [cell.x, cell.y], "subcell_offset": [subcell_offset.x, subcell_offset.y], "evidence_kind": "safe_clearance" if natural_clearance else "opaque_depth", "opaque_overlap": order.overlap, "wrong_depth": order.wrong}
	return result

func route_probe(family: String, placement: Dictionary) -> Dictionary:
	var id: String = ACTORS[family]
	var base: Vector2i = fixture.model.cell_at(placement.anchor)
	var start := base + Vector2i(-5, 3)
	var target := base + Vector2i(5, 3)
	for y_offset: int in [3, -3, 4, -4]:
		var a := base + Vector2i(-5, y_offset)
		var b := base + Vector2i(5, y_offset)
		if fixture.model.is_floor(a) and fixture.model.is_floor(b) and fixture.main.room.navigation.walkable(a) and fixture.main.room.navigation.walkable(b):
			start = a
			target = b
			break
	fixture.main.room.navigation.actors.clear()
	fixture.main.room.navigation.actors[id] = fixture.model.world(start)
	var route: PackedVector2Array = fixture.main.room.navigation.path(fixture.model.world(start), fixture.model.world(target), id)
	check(route.size() > 2, family + " route exists around blocked footprint")
	for point: Vector2 in route: check(fixture.main.room.navigation.walkable(fixture.model.cell_at(point)), family + " route avoids every blocked cell")
	return {"actor": id, "start": [start.x, start.y], "target": [target.x, target.y], "waypoints": route.size()}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Lounge actual-room evidence requires native renderer")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(5)
	check(fixture.ready_ok, "Disposable lounge fixture: " + str(fixture.errors))
	if not fixture.ready_ok:
		quit(1)
		return
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor.set_physics_process(false)
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, "No worker process")
	check(not fixture.main._state_loaded and not fixture.main._worker_ready, "No personal save/bootstrap state")
	var all_observations := {}
	for side: String in SEATING.SIDES:
		var overrides := {}
		for family: String in SEATING.FAMILIES:
			var base: Dictionary = FIXTURE.PLACEMENTS[family]
			overrides[base.id] = {"grid": base.grid, "facing": side}
		check(fixture.main.room.set_placement_overrides(overrides), side + " lounge room commits")
		await frames(3)
		hide_actors()
		var empty_frame := await capture("lounge-pair-" + side + "-room")
		var side_result := {}
		for family: String in SEATING.FAMILIES:
			var id: String = FIXTURE.PLACEMENTS[family].id
			var placement: Dictionary = fixture.main.room.placement_by_id(id)
			var prop: Node2D = fixture.main.room.prop_node(id)
			check(prop != null and prop.get_script() == null, family + " " + side + " neutral layer carrier")
			check(shapes(prop).size() == SEATING.profile(family, side).occupied.size(), family + " " + side + " exact collision cells")
			check(not placement.has("interaction") and not fixture.main.room.interaction_world_position(id).is_finite(), family + " " + side + " actionless")
			for layer: Dictionary in placement.render_layers:
				var sprite := prop.get_node(str(layer.name)) as Sprite2D
				check(sprite != null and sprite.texture.get_size() == Vector2(SEATING.canvas(family)), family + " " + side + " native texture")
				check(sprite.position == Vector2(SEATING.sprite_offset(family)) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation), family + " " + side + " untransformed layer")
			save_detail(empty_frame, family, side, "base", placement)
			side_result[family] = {"actor_depth": await actor_probe(family, side, placement), "corner_rejection": fixture.model.validate_candidate(id, Vector2i(1, 3), side, 2, overrides).errors}
			check(not fixture.model.validate_candidate(id, Vector2i(1, 3), side, 2, overrides).valid, family + " " + side + " wall/corner rejected")
		all_observations[side] = side_result
	var routes := {}
	for family: String in SEATING.FAMILIES:
		var id: String = FIXTURE.PLACEMENTS[family].id
		routes[family] = route_probe(family, fixture.main.room.placement_by_id(id))
	hide_actors()
	var model: OfficeLayout = fixture.model
	fixture.queue_free()
	await frames(3)
	check(not model.resolve_profile("two_seat_sofa", "north").errors.is_empty(), "Owner-scoped lounge admission revoked")
	var result := {"status": "two_passive_lounge_candidates_not_runtime_registered", "date": "2026-09-06", "viewport": [1280, 720], "renderer": DisplayServer.get_name(), "worker_disabled": true, "save_access": false, "observations": all_observations, "routes": routes, "captures": captures, "limitations": ["Bare passive upholstery only: no seat socket, Sit action, reservation, actor pose, worker behavior, save data or production registration.", "Actor probes establish native scale and front/rear depth only; they do not approve seated silhouettes.", "Visual approval requires native and 4x inspection; check counts are geometry evidence only."], "checks": checks, "failures": failures}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened lounge result")
	result.checks = checks
	result.failures = failures
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Lounge actual room: %d checks, %d failures, %d captures" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
