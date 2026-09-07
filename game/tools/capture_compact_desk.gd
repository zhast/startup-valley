extends SceneTree
## DEV ONLY. Native GameMain/TownRoom placement, collision, picking, wall,
## corner, and founder-approach evidence for the passive compact base candidate.

const DESK := preload("res://tools/compact_desk_geometry.gd")
const OUTPUT := "res://tests/output/compact-desk"
const CANDIDATE_ID := "compact-desk-candidate"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var main: GameMain
var model: OfficeLayout
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations := {}
var common_pivot := Vector2i(12, 13)

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

func capture_frame(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain capture stays native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

func choose_common_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(2, model.height - 2):
		for x: int in range(2, model.width - 2):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in DESK.SIDES:
				if not model.validate_candidate(CANDIDATE_ID, point, side, 0).valid:
					valid = false
					break
			if valid: choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(Vector2i(12, 13)) < b.distance_squared_to(Vector2i(12, 13))
	)
	check(not choices.is_empty(), "Actual TownRoom has a common safe pivot for all four compact views")
	return choices[0] if not choices.is_empty() else Vector2i(12, 13)

func issue_codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for issue: Dictionary in result.issues:
		var code := str(issue.code)
		if not codes.has(code): codes.append(code)
	return codes

func wall_neighbors(point: Vector2i) -> int:
	var result := 0
	for offset: Vector2i in OfficeLayout.NEIGHBORS:
		if not model.is_floor(point + offset): result += 1
	return result

func find_wall_probe(side: String, corner_only: bool) -> Dictionary:
	var fallback := {}
	var wall_codes: Array[String] = ["wall_intersection", "visual_wall_intersection", "wall_clearance", "decorative_headroom"]
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point): continue
			var result := model.validate_candidate(CANDIDATE_ID, point, side, 0)
			if result.valid: continue
			var codes := issue_codes(result)
			var architecture_failure := false
			for code: String in codes:
				if code in wall_codes: architecture_failure = true
			if not architecture_failure: continue
			var probe := {"grid": point, "codes": codes, "wall_neighbors": wall_neighbors(point)}
			if fallback.is_empty(): fallback = probe
			if not corner_only or int(probe.wall_neighbors) >= 2: return probe
	return fallback

func visible_point_for(layer_name: String, sprites: Dictionary) -> Vector2:
	var sprite := sprites[layer_name] as Sprite2D
	var image := (sprite.texture as Texture2D).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0: continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5) - Vector2(DESK.CANVAS) / 2.0)
			var all: Array[Sprite2D] = []
			for name_value: String in DESK.LAYERS: all.append(sprites[name_value] as Sprite2D)
			if VisibleSurface.top(all, point) == sprite: return point
	return Vector2(INF, INF)

func inspect_native_prop(side: String) -> Dictionary:
	var room: TownRoom = main.room
	var placement := room.placement_by_id(CANDIDATE_ID)
	var prop := room.prop_node(CANDIDATE_ID)
	check(prop != null and prop.get_script() == null, side + " uses TownRoom's neutral native-layer carrier")
	if prop == null: return {}
	check(placement.facing == side and placement.profile_kind == "decorative", side + " resolves only as a passive calibration candidate")
	check(not placement.has("interaction") and not room.interaction_world_position(CANDIDATE_ID).is_finite(), side + " creates no production interaction target")
	check(placement.occupied.size() == 2 and placement.clearance.size() == 1, side + " carries exact two-cell footprint and one approach clearance")
	var shapes := collision_shapes(prop)
	check(shapes.size() == 2, side + " builds exactly two real per-cell collision shapes")
	var found_centers: Array[Vector2i] = []
	for shape: CollisionShape2D in shapes:
		check(shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(32, 32), side + " collision cell is an exact 32px square")
		found_centers.append(Vector2i(shape.global_position.round()))
	for cell: Vector2i in placement.occupied:
		var center := Vector2i((room.global_position + model.world(cell)).round())
		check(found_centers.has(center), side + " collision center matches occupied cell " + str(cell))
		check(not room.navigation.walkable(cell), side + " occupied cell is blocked in actual AStar navigation")
	var sprites := {}
	for layer: Dictionary in placement.render_layers:
		var sprite := prop.get_node(str(layer.name)) as Sprite2D
		sprites[str(layer.name).trim_prefix("CompactDesk").to_snake_case()] = sprite
		check(sprite != null and sprite.texture.get_size() == Vector2(DESK.CANVAS), side + " " + str(layer.name) + " loads the full native texture")
		check(sprite.position == Vector2(DESK.SPRITE_OFFSET) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + str(layer.name) + " keeps native integer registration")
		check(sprite.z_index == prop.z_index + int(layer.z_offset), side + " " + str(layer.name) + " keeps authored prop-relative depth")
	for layer_name: String in DESK.LAYERS:
		var point := visible_point_for(layer_name, sprites)
		check(point.is_finite(), side + " " + layer_name + " owns a visible painted surface pixel")
		if point.is_finite():
			var hit := room.surface_at(point)
			check(hit.get("sprite") == sprites[layer_name], side + " actual alpha-aware room picking selects " + layer_name)
			check((hit.get("interaction", {}) as Dictionary).is_empty() and main._interaction_at(point).is_empty(), side + " painted passive surface never invents an action")
	return {"placement": placement, "prop": prop, "shapes": shapes.size(), "sprites": sprites}

func walk_founder_to(side: String, placement: Dictionary) -> Dictionary:
	var player: PlayerAvatar = main.player
	var relative := OfficeLayout.vector(DESK.profile(side).interaction)
	var destination_cell: Vector2i = placement.grid + relative
	var destination := model.world(destination_cell)
	check(placement.standing_viewpoints.size() == 1 and placement.standing_viewpoints[0].cell == destination_cell, side + " passive admission preserves the proposed approach viewpoint")
	check(main.room.navigation.walkable(destination_cell), side + " proposed approach cell is physically walkable")
	var start_cell := Vector2i(17, 18)
	player.cancel_route()
	player.position = model.world(start_cell)
	player.z_index = int(player.position.y)
	main.room.navigation.actors["founder"] = player.position
	var start := player.position
	check(player.move_to(destination), side + " founder receives an actual navigation route to the approach cell")
	var route_points := player.route.size()
	var traveled := 0.0
	var samples: Array[Array] = [[player.position.x, player.position.y]]
	for tick: int in range(900):
		var before := player.position
		player._physics_process(1.0 / 30.0)
		traveled += before.distance_to(player.position)
		check(main.room.navigation.position_is_safe(player.position, "founder"), side + " founder stays physically safe on approach tick " + str(tick))
		if tick == 15: samples.append([player.position.x, player.position.y])
		if player.route.is_empty(): break
	check(player.route.is_empty() and player.position.distance_to(destination) < 0.1, side + " actual founder route reaches the exact approach center")
	check(model.cell_at(player.position) == destination_cell and destination_cell not in placement.occupied, side + " founder finishes outside both compact collision cells")
	player.face_direction(Vector2(OfficeLayout.vector(DESK.profile(side).employee_look_vector)))
	samples.append([player.position.x, player.position.y])
	return {"start": [start.x, start.y], "destination_cell": [destination_cell.x, destination_cell.y], "destination": [destination.x, destination.y], "initial_route_points": route_points, "traveled_px": traveled, "samples": samples}

func run_side(side: String, base_details: Dictionary[String, Image], approach_details: Dictionary[String, Image]) -> void:
	var overrides := {CANDIDATE_ID: {"grid": [common_pivot.x, common_pivot.y], "facing": side}}
	check(main.room.set_placement_overrides(overrides), side + " commits at the common pivot through actual TownRoom validation")
	await frames(3)
	var inspected := inspect_native_prop(side)
	if inspected.is_empty(): return
	var placement: Dictionary = inspected.placement
	main.player.hide()
	await frames(2)
	await RenderingServer.frame_post_draw
	var base_frame := root.get_texture().get_image()
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - DESK.PIVOT, DESK.CANVAS)
	var base_detail := base_frame.get_region(crop_rect)
	check(base_detail.get_size() == DESK.CANVAS, side + " base-only crop uses the exact 160x192 registered canvas")
	var base_path := OUTPUT.path_join("detail-%s-base-native.png" % side)
	check(base_detail.save_png(base_path) == OK, "Saved " + base_path)
	captures.append(base_path)
	base_details[side] = base_detail
	main.player.show()
	var approach := walk_founder_to(side, placement)
	await frames(2)
	var room_frame := await capture_frame(OUTPUT.path_join("room-%s.png" % side))
	var approach_detail := room_frame.get_region(crop_rect)
	var approach_path := OUTPUT.path_join("detail-%s-approach-native.png" % side)
	check(approach_detail.save_png(approach_path) == OK, "Saved " + approach_path)
	captures.append(approach_path)
	approach_details[side] = approach_detail
	check(base_detail.get_data() != approach_detail.get_data(), side + " final native crop visibly contains the founder approach probe")
	observations[side] = {
		"grid": [common_pivot.x, common_pivot.y],
		"occupied": placement.occupied.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"clearance": placement.clearance.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"collision_shapes": inspected.shapes,
		"founder_approach": approach,
		"render_layers": placement.render_layers,
	}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Compact desk actual-room evidence requires the native renderer; run test_compact_desk.gd for headless structure.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var catalog_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_before := FileAccess.get_sha256(DEV_CATALOGUE)
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames(5)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.founder_hud.dismiss_movement_hint()
	main.job_panel.close_drawer(false)
	main.company_panel.hide()
	main._spawn_employees([])
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker")
	var room_data := main.room.layout_model.data.duplicate(true)
	var catalogue := main.room.layout_model.catalog.duplicate(true)
	room_data.props = [{"id": CANDIDATE_ID, "kind": "compact_desk", "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	room_data.player_spawn = [17, 18]
	catalogue["compact_desk"] = DESK.catalog_entry()
	model = OfficeLayout.new()
	model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), "Capture owns one isolated dev-only layout model")
	for side: String in DESK.SIDES:
		check(model.authorize_calibration_decorative_profile("compact_desk", side, self), side + " exact definition receives passive owner-scoped admission")
	main.room.layout_model = model
	main.room.player_spawn = Vector2i(17, 18)
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(0)
	main.player.set_physics_process(false)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 18))
	main.room.navigation.actors["founder"] = main.player.position
	await frames(3)
	common_pivot = choose_common_pivot()
	var wall_results := {}
	for side: String in DESK.SIDES:
		var probe := find_wall_probe(side, true)
		check(not probe.is_empty(), side + " finds a real wall/corner rejection in the production room geometry")
		if probe.is_empty(): continue
		check(int(probe.wall_neighbors) >= 2, side + " rejected probe is adjacent to two wall axes at a room corner")
		var before := main.room.placement_by_id(CANDIDATE_ID).duplicate(true)
		var bad := {CANDIDATE_ID: {"grid": [probe.grid.x, probe.grid.y], "facing": side}}
		check(not main.room.set_placement_overrides(bad), side + " actual TownRoom transaction rejects the unsafe corner")
		check(main.room.placement_by_id(CANDIDATE_ID).grid == before.grid and main.room.placement_by_id(CANDIDATE_ID).facing == before.facing, side + " rejected corner leaves the committed prop unchanged")
		wall_results[side] = {"grid": [probe.grid.x, probe.grid.y], "wall_neighbors": probe.wall_neighbors, "issue_codes": probe.codes}
	var base_details: Dictionary[String, Image] = {}
	var approach_details: Dictionary[String, Image] = {}
	for side: String in DESK.SIDES: await run_side(side, base_details, approach_details)
	var base_sheet := Image.create(DESK.CANVAS.x * 4, DESK.CANVAS.y, false, Image.FORMAT_RGBA8)
	var approach_sheet := Image.create(DESK.CANVAS.x * 4, DESK.CANVAS.y, false, Image.FORMAT_RGBA8)
	base_sheet.fill(Color("151515"))
	approach_sheet.fill(Color("151515"))
	for index: int in range(DESK.SIDES.size()):
		var side: String = DESK.SIDES[index]
		if base_details.has(side): base_sheet.blit_rect(base_details[side], Rect2i(Vector2i.ZERO, DESK.CANVAS), Vector2i(index * DESK.CANVAS.x, 0))
		if approach_details.has(side): approach_sheet.blit_rect(approach_details[side], Rect2i(Vector2i.ZERO, DESK.CANVAS), Vector2i(index * DESK.CANVAS.x, 0))
	var base_sheet_path := OUTPUT.path_join("actual-room-base-contact-sheet-native.png")
	check(base_sheet.save_png(base_sheet_path) == OK, "Saved actual-room base-only contact sheet")
	captures.append(base_sheet_path)
	var approach_sheet_path := OUTPUT.path_join("actual-room-approach-contact-sheet-native.png")
	check(approach_sheet.save_png(approach_sheet_path) == OK, "Saved actual-room actor-approach contact sheet")
	captures.append(approach_sheet_path)
	var enlarged := approach_sheet.duplicate()
	enlarged.resize(approach_sheet.get_width() * 4, approach_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-approach-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved nearest-neighbor approach inspection sheet")
	captures.append(enlarged_path)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_before, "Capture leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Capture leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == dev_before, "Capture leaves the shared art catalogue byte-exact")
	var manifest := {
		"status": "native_review_candidate_not_runtime_registered",
		"scene": "actual GameMain and production TownRoom architecture/navigation; owner-scoped passive compact_desk definition",
		"renderer": DisplayServer.get_name(),
		"viewport": [1280, 720],
		"worker_disabled": true,
		"save_access": false,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"shared_art_catalogue_mutated": false,
		"common_safe_pivot": [common_pivot.x, common_pivot.y],
		"wall_corner_rejections": wall_results,
		"observations": observations,
		"captures": captures,
		"limitations": ["Founder standing locomotion is only a scale, route, contact, and occlusion probe; no compact seated pose or chair assembly is claimed.", "The room carrier is passive so visible-surface picking deliberately yields no action.", "Chair, device, and role overlay compatibility remains a separate review."],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room result")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	model.disable_calibration_preview(self)
	main.game_audio.shutdown()
	main.queue_free()
	await frames(3)
	main = null
	model = null
	print("Compact desk actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
