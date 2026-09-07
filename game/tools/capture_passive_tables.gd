extends SceneTree
## DEV ONLY. Native actual-GameMain review of three bare passive table families.

const TABLES := preload("res://tools/passive_table_geometry.gd")
const FIXTURE := preload("res://tools/passive_table_fixture.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/passive-tables-v2"
const ACTORS := {"low_coffee_table": "founder", "cafe_table": "mira", "round_meeting_table": "theo"}
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations := {}

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

func collision_shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if node is CollisionShape2D: result.append(node as CollisionShape2D)
	for child: Node in node.get_children(): result.append_array(collision_shapes(child))
	return result

func capture(label: String) -> Image:
	await frames(2)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), label + " native 1280x720")
	var path := OUTPUT.path_join(label + ".png")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path.trim_prefix("res://../"))
	return image

func save_detail(frame: Image, family: String, side: String, suffix: String, placement: Dictionary) -> void:
	var size := TABLES.canvas(family)
	var crop_rect := Rect2i(Vector2i(placement.anchor) - TABLES.pivot(family), size)
	var crop := frame.get_region(crop_rect)
	check(crop.get_size() == size, family + " " + side + " " + suffix + " exact native crop")
	var native_path := OUTPUT.path_join("%s-%s-%s-native.png" % [family, side, suffix])
	check(crop.save_png(native_path) == OK, "Saved " + native_path)
	var enlarged := crop.duplicate()
	enlarged.resize(size.x * 4, size.y * 4, Image.INTERPOLATE_NEAREST)
	var detail_path := OUTPUT.path_join("%s-%s-%s-4x.png" % [family, side, suffix])
	check(enlarged.save_png(detail_path) == OK, "Saved " + detail_path)
	captures.append_array([native_path.trim_prefix("res://../"), detail_path.trim_prefix("res://../")])

func actor_node(id: String) -> Node2D:
	return fixture.main.player if id == "founder" else fixture.main.get_employee(id)

func hide_actors(except := "") -> void:
	fixture.main.player.visible = except == "founder"
	for id: String in fixture.main._employees:
		var actor: EmployeeAvatar = fixture.main._employees[id]
		actor.labels_suppressed = true
		actor.visible = id == except

func overlap_order(actor: Node2D, prop: Node2D, bounds: Rect2, actor_should_front: bool) -> Dictionary:
	var overlap := 0
	var wrong := 0
	for y: int in range(floori(bounds.position.y), ceili(bounds.end.y)):
		for x: int in range(floori(bounds.position.x), ceili(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body: Sprite2D = actor.body_surface_at(point)
			var surface: Dictionary = fixture.main.room.surface_at(point)
			if body == null or surface.get("sprite") == null or (surface.sprite as Node).get_parent() != prop: continue
			overlap += 1
			if VisibleSurface.in_front(body, surface.sprite) != actor_should_front: wrong += 1
	return {"overlap": overlap, "wrong": wrong}

func actor_probe(family: String, side: String, placement: Dictionary) -> Dictionary:
	var id: String = ACTORS[family]
	var actor := actor_node(id)
	var profile := TABLES.profile(family, side)
	var cells: Array[Vector2i] = []
	for raw: Variant in profile.occupied: cells.append(Vector2i(int(raw[0]), int(raw[1])))
	var x_offset := cells[0].x
	for cell: Vector2i in cells:
		if absi(cell.x) < absi(x_offset): x_offset = cell.x
	var min_y := cells.map(func(cell: Vector2i) -> int: return cell.y).min() as int
	var max_y := cells.map(func(cell: Vector2i) -> int: return cell.y).max() as int
	var base: Vector2i = fixture.model.cell_at(placement.anchor)
	var probes := {"behind": base + Vector2i(x_offset, min_y - 1), "front": base + Vector2i(x_offset, max_y + 1)}
	var result := {}
	hide_actors(id)
	for label: String in ["behind", "front"]:
		var cell: Vector2i = probes[label]
		# Low furniture needs a near-edge visual overlap to prove ordering. Four
		# pixels remains wholly inside the same clear32px actor cell (10px foot
		# radius) and does not weaken the physical collision assertion.
		var point: Vector2 = fixture.model.world(cell) + (Vector2(0, 4) if label == "behind" else Vector2.ZERO)
		check(fixture.model.is_floor(cell) and fixture.main.room.navigation.walkable(cell), family + " " + side + " " + label + " actor cell clear")
		check(fixture.main.room.navigation.position_is_safe(point, id), family + " " + side + " " + label + " physical actor footprint remains safe")
		actor.position = point
		actor.z_index = int(point.y)
		fixture.main.room.navigation.actors.clear()
		fixture.main.room.navigation.actors[id] = point
		await frames(2)
		var order := overlap_order(actor, fixture.main.room.prop_node(str(placement.id)), placement.world_visual_bounds, label == "front")
		check(int(order.overlap) > 0 and int(order.wrong) == 0, family + " " + side + " " + id + " " + label + " native opaque depth")
		var frame := await capture("%s-%s-%s-%s-room" % [family, side, id, label])
		save_detail(frame, family, side, id + "-" + label, placement)
		result[label] = {"cell": [cell.x, cell.y], "opaque_overlap": order.overlap, "wrong_depth": order.wrong}
	return result

func route_probe(family: String, placement: Dictionary) -> Dictionary:
	var id: String = ACTORS[family]
	var base: Vector2i = fixture.model.cell_at(placement.anchor)
	var start: Vector2i = base + Vector2i(-5, 3)
	var target: Vector2i = base + Vector2i(5, 3)
	# Find a nearby all-floor horizontal lane if this row meets architecture.
	for y_offset: int in [3, -3, 4, -4]:
		var a: Vector2i = base + Vector2i(-5, y_offset)
		var b: Vector2i = base + Vector2i(5, y_offset)
		if fixture.model.is_floor(a) and fixture.model.is_floor(b) and fixture.main.room.navigation.walkable(a) and fixture.main.room.navigation.walkable(b):
			start = a
			target = b
			break
	fixture.main.room.navigation.actors.clear()
	fixture.main.room.navigation.actors[id] = fixture.model.world(start)
	var route: PackedVector2Array = fixture.main.room.navigation.path(fixture.model.world(start), fixture.model.world(target), id)
	check(route.size() > 2, family + " real navigation finds a route around the blocked table")
	var blocked := false
	for point: Vector2 in route:
		if not fixture.main.room.navigation.walkable(fixture.model.cell_at(point)): blocked = true
	check(not blocked, family + " route never enters an occupied table cell")
	return {"actor": id, "start": [start.x, start.y], "target": [target.x, target.y], "waypoints": route.size()}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Passive table actual-room evidence requires a native renderer")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(5)
	check(fixture.ready_ok, "Disposable table fixture: " + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.queue_free()
		await frames()
		quit(1)
		return
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor.set_physics_process(false)
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, "No worker process")
	check(not fixture.main._state_loaded and not fixture.main._worker_ready, "No personal save/bootstrap state")
	var all_observations := {}
	for side: String in TABLES.SIDES:
		var overrides := {}
		for family: String in TABLES.FAMILIES:
			var base: Dictionary = FIXTURE.PLACEMENTS[family]
			overrides[base.id] = {"grid": base.grid, "facing": side}
		check(fixture.main.room.set_placement_overrides(overrides), side + " three-table room commits through actual TownRoom")
		await frames(3)
		hide_actors()
		var empty_frame := await capture("all-tables-" + side + "-room")
		var side_observations := {}
		for family: String in TABLES.FAMILIES:
			var id: String = FIXTURE.PLACEMENTS[family].id
			var placement: Dictionary = fixture.main.room.placement_by_id(id)
			var prop: Node2D = fixture.main.room.prop_node(id)
			check(prop != null and prop.get_script() == null, family + " " + side + " neutral native-layer carrier")
			check(collision_shapes(prop).size() == TABLES.profile(family, side).occupied.size(), family + " " + side + " exact collision-cell count")
			check(not placement.has("interaction") and not fixture.main.room.interaction_world_position(id).is_finite(), family + " " + side + " remains actionless")
			for layer: Dictionary in placement.render_layers:
				var sprite := prop.get_node(str(layer.name)) as Sprite2D
				check(sprite != null and sprite.texture.get_size() == Vector2(TABLES.canvas(family)), family + " " + side + " native texture canvas")
				check(sprite.position == Vector2(TABLES.sprite_offset(family)) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation), family + " " + side + " integer untransformed layer")
			save_detail(empty_frame, family, side, "base", placement)
			var actor_result := await actor_probe(family, side, placement)
			var corner: Dictionary = fixture.model.validate_candidate(id, Vector2i(1, 3), side, 2, overrides)
			check(not corner.valid, family + " " + side + " wall/corner placement rejected")
			side_observations[family] = {"actor_depth": actor_result, "corner_rejection": corner.errors}
		all_observations[side] = side_observations
	# One real navigation path for founder, Mina and Theo around their South view.
	var routes := {}
	for family: String in TABLES.FAMILIES:
		var id: String = FIXTURE.PLACEMENTS[family].id
		routes[family] = route_probe(family, fixture.main.room.placement_by_id(id))
	hide_actors()
	var model: OfficeLayout = fixture.model
	fixture.queue_free()
	await frames(3)
	check(not model.resolve_profile("low_coffee_table", "north").errors.is_empty(), "Owner-scoped table admission revoked with fixture")
	var result := {
		"status": "three_passive_table_native_candidates_not_runtime_registered", "date": "2026-09-06",
		"viewport": [1280, 720], "renderer": DisplayServer.get_name(), "worker_disabled": true, "save_access": false,
		"observations": all_observations, "routes": routes, "captures": captures,
		"limitations": ["Bare art only: no chairs, tools, interaction, seating, work pose, service, worker behavior, save data or production registration.", "Cafe and round-table actor probes establish scale/depth, not future multi-seat behavior.", "Visual approval requires inspecting these native and nearest-neighbor 4x images; check counts are geometry evidence only."],
		"checks": checks, "failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room table result")
	result.checks = checks
	result.failures = failures
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Passive tables actual room: %d checks, %d failures, %d captures" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
