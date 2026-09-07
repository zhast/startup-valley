extends SceneTree
## DEV ONLY. Actual GameMain/TownRoom collision, wall/corner, navigation,
## picking and actor-depth evidence for one unregistered broadleaf planter.

const PLANT := preload("res://tools/broadleaf_planter_geometry.gd")
const OUTPUT := "res://tests/output/broadleaf-planter"
const CANDIDATE_ID := "broadleaf-planter-candidate"
const FAMILY := "broadleaf_planter"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var main: GameMain
var model: OfficeLayout
var common_pivot := Vector2i(12, 13)
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
	for _index: int in range(count):
		await process_frame

func collision_shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if node is CollisionShape2D:
		result.append(node as CollisionShape2D)
	for child: Node in node.get_children():
		result.append_array(collision_shapes(child))
	return result

func capture_frame(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain capture stays native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

func image_difference(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				result += 1
	return result

func issue_codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for issue: Dictionary in result.get("issues", []):
		var code := str(issue.get("code", ""))
		if not codes.has(code):
			codes.append(code)
	return codes

func wall_neighbors(point: Vector2i) -> int:
	var result := 0
	for offset: Vector2i in OfficeLayout.NEIGHBORS:
		if not model.is_floor(point + offset):
			result += 1
	return result

func wall_distance(point: Vector2i) -> int:
	for radius: int in range(1, 8):
		for y: int in range(-radius, radius + 1):
			for x: int in range(-radius, radius + 1):
				if absi(x) + absi(y) != radius:
					continue
				if not model.is_floor(point + Vector2i(x, y)):
					return radius
	return 99

func choose_common_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(3, model.height - 3):
		for x: int in range(3, model.width - 3):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in PLANT.SIDES:
				if not model.validate_candidate(CANDIDATE_ID, point, side, 0).valid:
					valid = false
					break
			if valid:
				choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(Vector2i(12, 13)) < b.distance_squared_to(Vector2i(12, 13))
	)
	check(not choices.is_empty(), "Production architecture has a common safe N/E/S/W planter pivot")
	return choices[0] if not choices.is_empty() else Vector2i(12, 13)

func nearest_valid_wall_probe(side: String) -> Dictionary:
	var best := {}
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point):
				continue
			var result := model.validate_candidate(CANDIDATE_ID, point, side, 0)
			if not result.valid:
				continue
			var distance := wall_distance(point)
			if best.is_empty() or distance < int(best.distance):
				best = {"grid": point, "distance": distance}
	return best

func corner_rejection(side: String) -> Dictionary:
	var fallback := {}
	var wall_codes: Array[String] = ["wall_intersection", "visual_wall_intersection", "wall_clearance", "decorative_headroom"]
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point):
				continue
			var result := model.validate_candidate(CANDIDATE_ID, point, side, 0)
			if result.valid:
				continue
			var codes := issue_codes(result)
			var architectural := false
			for code: String in codes:
				if code in wall_codes:
					architectural = true
			if not architectural:
				continue
			var probe := {"grid": point, "codes": codes, "wall_neighbors": wall_neighbors(point)}
			if fallback.is_empty():
				fallback = probe
			if int(probe.wall_neighbors) >= 2:
				return probe
	return fallback

func visible_point_for(layer_name: String, sprites: Dictionary) -> Vector2:
	var sprite := sprites[layer_name] as Sprite2D
	var image := (sprite.texture as Texture2D).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0:
				continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5) - Vector2(PLANT.CANVAS) / 2.0)
			var all: Array[Sprite2D] = []
			for name_value: String in PLANT.LAYERS:
				all.append(sprites[name_value] as Sprite2D)
			if VisibleSurface.top(all, point) == sprite:
				return point
	return Vector2(INF, INF)

func inspect_native_prop(side: String) -> Dictionary:
	var room: TownRoom = main.room
	var placement := room.placement_by_id(CANDIDATE_ID)
	var prop := room.prop_node(CANDIDATE_ID)
	check(prop != null and prop.get_script() == null, side + " uses TownRoom's neutral native-layer carrier")
	if prop == null:
		return {}
	check(placement.facing == side and placement.profile_kind == "decorative", side + " resolves only as an owner-scoped passive candidate")
	check(not placement.has("interaction") and not room.interaction_world_position(CANDIDATE_ID).is_finite(), side + " creates no service, action or seat target")
	check(placement.occupied == [placement.grid] and placement.clearance.size() == 1, side + " carries one occupied cell and one planning clearance cell")
	var shapes := collision_shapes(prop)
	check(shapes.size() == 1, side + " builds exactly one real collision shape")
	if shapes.size() == 1:
		var shape := shapes[0]
		check(shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(32, 32), side + " collision is an exact 32px square")
		check(Vector2i(shape.global_position.round()) == Vector2i((room.global_position + model.world(placement.grid)).round()), side + " collision center matches the occupied grid cell")
	check(not room.navigation.walkable(placement.grid), side + " occupied planter cell blocks actual AStar navigation")
	var sprites := {}
	for layer_name: String in PLANT.LAYERS:
		var descriptor := PLANT.descriptor(side, layer_name)
		var sprite := prop.get_node(str(descriptor.name)) as Sprite2D
		sprites[layer_name] = sprite
		check(sprite != null and sprite.texture.get_size() == Vector2(PLANT.CANVAS), side + " " + layer_name + " loads the full native canvas")
		check(sprite.position == Vector2(PLANT.SPRITE_OFFSET) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + layer_name + " keeps exact native integer registration")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), side + " " + layer_name + " keeps authored host-relative depth")
	for layer_name: String in PLANT.LAYERS:
		var point := visible_point_for(layer_name, sprites)
		check(point.is_finite(), side + " " + layer_name + " owns a visible final surface pixel")
		if point.is_finite():
			var hit := room.surface_at(point)
			check(hit.get("sprite") == sprites[layer_name], side + " alpha-aware picking selects visible " + layer_name)
			check((hit.get("interaction", {}) as Dictionary).is_empty() and main._interaction_at(point).is_empty(), side + " passive painted surface invents no action")
	var transparent := prop.global_position + Vector2(PLANT.SPRITE_OFFSET) - Vector2(PLANT.CANVAS) / 2.0 + Vector2(0.5, 0.5)
	var transparent_hit := room.surface_at(transparent)
	check(transparent_hit.get("sprite") == null or (transparent_hit.get("sprite") as Node).get_parent() != prop, side + " transparent canvas padding is not pickable")
	return {"placement": placement, "prop": prop, "sprites": sprites, "shape_count": shapes.size()}

func source_match(frame: Image, placement: Dictionary) -> Dictionary:
	var source := PLANT.whole(str(placement.facing))
	var origin := Vector2i(main.room.global_position + Vector2(placement.anchor)) - PLANT.PIVOT
	var opaque := 0
	var mismatches := 0
	for y: int in range(PLANT.CANVAS.y):
		for x: int in range(PLANT.CANVAS.x):
			var expected := source.get_pixel(x, y)
			if expected.a == 0.0:
				continue
			opaque += 1
			if frame.get_pixelv(origin + Vector2i(x, y)) != expected:
				mismatches += 1
	return {"opaque": opaque, "mismatches": mismatches}

func approach_founder(side: String, placement: Dictionary, sprites: Dictionary) -> Dictionary:
	var p := PLANT.profile(side)
	var relative := OfficeLayout.vector(p.interaction)
	var destination_cell: Vector2i = placement.grid + relative
	var destination := model.world(destination_cell)
	check(placement.standing_viewpoints.size() == 1 and placement.standing_viewpoints[0].cell == destination_cell, side + " admission exposes only the declared actor probe cell")
	check(main.room.navigation.walkable(destination_cell) and destination_cell not in placement.occupied, side + " actor contact cell is outside collision and walkable")
	var start_cell := Vector2i(17, 18)
	main.player.show()
	main.player.cancel_route()
	main.player.position = model.world(start_cell)
	main.player.z_index = roundi(main.player.position.y)
	main.room.navigation.actors["founder"] = main.player.position
	check(main.player.move_to(destination), side + " founder receives a real path to the planter probe")
	var initial_route_points := main.player.route.size()
	var safe := true
	var occupied_crossings := 0
	var traveled := 0.0
	for _tick: int in range(900):
		var before := main.player.position
		main.player._physics_process(1.0 / 30.0)
		traveled += before.distance_to(main.player.position)
		if not main.room.navigation.position_is_safe(main.player.position, "founder"):
			safe = false
		if model.cell_at(main.player.position) in placement.occupied:
			occupied_crossings += 1
		if main.player.route.is_empty():
			break
	check(safe and occupied_crossings == 0 and main.player.route.is_empty() and main.player.position.distance_to(destination) < 0.1, side + " founder safely reaches contact without crossing planter collision")
	main.player.z_index = roundi(main.player.position.y)
	main.player.face_direction(Vector2(OfficeLayout.vector(p.employee_look_vector)))
	var rear := sprites.rear_structure as Sprite2D
	var front := sprites.front_structure as Sprite2D
	var depth_class := ""
	if side == "north":
		check(main.player.z_index > front.z_index, "North contact actor stands naturally in front of the whole planter")
		depth_class = "actor_in_front_of_structure"
	elif side == "south":
		check(main.player.z_index < rear.z_index, "South contact actor stands naturally behind the whole planter")
		depth_class = "actor_behind_structure"
	else:
		check(rear.z_index < main.player.z_index and main.player.z_index < front.z_index, side + " side contact actor is bracketed by rear/front plant layers")
		depth_class = "actor_between_rear_and_front_layers"
	return {
		"destination_cell": [destination_cell.x, destination_cell.y],
		"destination_px": [destination.x, destination.y],
		"employee_look_vector": p.employee_look_vector,
		"initial_route_points": initial_route_points,
		"traveled_px": traveled,
		"occupied_crossings": occupied_crossings,
		"actor_z": main.player.z_index,
		"rear_z": rear.z_index,
		"front_z": front.z_index,
		"depth_class": depth_class,
	}

func actor_layer_overlap(side: String, placement: Dictionary, sprites: Dictionary) -> Dictionary:
	var result := {
		"floor_shadow": 0,
		"rear_structure": 0,
		"front_structure": 0,
		"wrong_depth_pixels": 0,
	}
	var bounds: Rect2 = placement.world_visual_bounds
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body := main.player.body_surface_at(point)
			if body == null:
				continue
			for layer_name: String in PLANT.LAYERS:
				var sprite := sprites[layer_name] as Sprite2D
				if not VisibleSurface.painted(sprite, point):
					continue
				result[layer_name] = int(result[layer_name]) + 1
				var correct := true
				if side == "north":
					correct = VisibleSurface.in_front(body, sprite)
				elif side == "south":
					correct = VisibleSurface.in_front(sprite, body)
				elif layer_name == "front_structure":
					correct = VisibleSurface.in_front(sprite, body)
				else:
					correct = VisibleSurface.in_front(body, sprite)
				if not correct:
					result.wrong_depth_pixels = int(result.wrong_depth_pixels) + 1
	var total := int(result.floor_shadow) + int(result.rear_structure) + int(result.front_structure)
	result["total"] = total
	check(total > 0, side + " exact adjacent actor contact naturally intersects painted plant pixels")
	check(int(result.wrong_depth_pixels) == 0, side + " every intersecting actor/plant pixel follows declared depth")
	return result

func run_side(side: String, base_details: Dictionary[String, Image], actor_details: Dictionary[String, Image], room_frames: Dictionary[String, Image]) -> void:
	check(main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [common_pivot.x, common_pivot.y], "facing": side}}), side + " commits at the common safe pivot")
	await frames(3)
	var inspected := inspect_native_prop(side)
	if inspected.is_empty():
		return
	var placement: Dictionary = inspected.placement
	var prop: Node2D = inspected.prop
	var sprites: Dictionary = inspected.sprites
	main.player.hide()
	await frames(2)
	await RenderingServer.frame_post_draw
	var base_frame := root.get_texture().get_image()
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - PLANT.PIVOT, PLANT.CANVAS)
	var base_detail := base_frame.get_region(crop_rect)
	check(base_detail.get_size() == PLANT.CANVAS, side + " base crop uses the exact candidate canvas")
	var match_result := source_match(base_frame, placement)
	check(int(match_result.opaque) > 0 and int(match_result.mismatches) == 0, side + " actual room preserves every opaque composite pixel before actor contact")
	var base_path := OUTPUT.path_join("detail-%s-base-native.png" % side)
	check(base_detail.save_png(base_path) == OK, "Saved " + base_path)
	captures.append(base_path)
	base_details[side] = base_detail
	var approach := approach_founder(side, placement, sprites)
	await frames(2)
	var room_frame := await capture_frame(OUTPUT.path_join("room-%s.png" % side))
	room_frames[side] = room_frame
	var actor_detail := room_frame.get_region(crop_rect)
	var actor_path := OUTPUT.path_join("detail-%s-actor-native.png" % side)
	check(actor_detail.save_png(actor_path) == OK, "Saved " + actor_path)
	captures.append(actor_path)
	actor_details[side] = actor_detail
	var actor_delta := image_difference(base_detail, actor_detail)
	check(actor_delta > 0, side + " exact native crop visibly contains the real founder probe")
	var overlap := actor_layer_overlap(side, placement, sprites)
	check(collision_shapes(prop).size() == int(inspected.shape_count) and not main.room.navigation.walkable(placement.grid), side + " approach leaves collision geometry and navigation stable")
	observations[side] = {
		"grid": [common_pivot.x, common_pivot.y],
		"occupied": placement.occupied.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"clearance": placement.clearance.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"collision_shapes": inspected.shape_count,
		"founder_approach": approach,
		"actor_pixel_delta": actor_delta,
		"actor_layer_overlap": overlap,
		"source_match": match_result,
		"render_layers": placement.render_layers,
	}

func make_sheet(images: Dictionary[String, Image], path: String) -> Image:
	var sheet := Image.create(PLANT.CANVAS.x * PLANT.SIDES.size(), PLANT.CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	for index: int in range(PLANT.SIDES.size()):
		var side: String = PLANT.SIDES[index]
		if images.has(side):
			sheet.blit_rect(images[side], Rect2i(Vector2i.ZERO, PLANT.CANVAS), Vector2i(index * PLANT.CANVAS.x, 0))
	check(sheet.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return sheet

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Broadleaf-planter actual-room evidence requires the native renderer; run test_broadleaf_planter.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var catalogue_before := FileAccess.get_sha256(DEV_CATALOGUE)
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
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker transport")
	var room_data := main.room.layout_model.data.duplicate(true)
	var catalogue := main.room.layout_model.catalog.duplicate(true)
	room_data.props = [{"id": CANDIDATE_ID, "kind": FAMILY, "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	room_data.player_spawn = [17, 18]
	catalogue[FAMILY] = PLANT.catalog_entry()
	model = OfficeLayout.new()
	model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), "Capture owns one isolated dev-only layout model")
	for side: String in PLANT.SIDES:
		check(model.authorize_calibration_decorative_profile(FAMILY, side, self), side + " exact profile receives passive owner-scoped admission")
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
	for side: String in PLANT.SIDES:
		var wall := nearest_valid_wall_probe(side)
		check(not wall.is_empty() and int(wall.distance) <= 3, side + " has a valid placement within three cells of production architecture")
		if not wall.is_empty():
			check(main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [wall.grid.x, wall.grid.y], "facing": side}}), side + " commits the valid near-wall placement")
		var corner := corner_rejection(side)
		check(not corner.is_empty() and int(corner.wall_neighbors) >= 2, side + " finds a real two-axis corner rejection")
		if not corner.is_empty():
			var before := main.room.placement_by_id(CANDIDATE_ID).duplicate(true)
			check(not main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [corner.grid.x, corner.grid.y], "facing": side}}), side + " unsafe corner transaction is rejected")
			var after := main.room.placement_by_id(CANDIDATE_ID)
			check(after.grid == before.grid and after.facing == before.facing, side + " rejected corner leaves the committed planter unchanged")
		wall_results[side] = {
			"nearest_valid": [wall.grid.x, wall.grid.y] if not wall.is_empty() else [],
			"wall_distance_cells": wall.distance if not wall.is_empty() else null,
			"rejected_corner": [corner.grid.x, corner.grid.y] if not corner.is_empty() else [],
			"corner_wall_neighbors": corner.wall_neighbors if not corner.is_empty() else 0,
			"rejection_codes": corner.codes if not corner.is_empty() else [],
		}
	var base_details: Dictionary[String, Image] = {}
	var actor_details: Dictionary[String, Image] = {}
	var room_frames: Dictionary[String, Image] = {}
	for side: String in PLANT.SIDES:
		await run_side(side, base_details, actor_details, room_frames)
	make_sheet(base_details, OUTPUT.path_join("actual-room-base-contact-sheet-native.png"))
	var actor_sheet := make_sheet(actor_details, OUTPUT.path_join("actual-room-actor-contact-sheet-native.png"))
	var enlarged := actor_sheet.duplicate()
	enlarged.resize(enlarged.get_width() * 4, enlarged.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-actor-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved nearest-neighbor actor contact sheet")
	captures.append(enlarged_path)
	var full_sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8)
	full_sheet.fill(Color("151515"))
	for index: int in range(PLANT.SIDES.size()):
		var side: String = PLANT.SIDES[index]
		if room_frames.has(side):
			full_sheet.blit_rect(room_frames[side], Rect2i(0, 0, 1280, 720), Vector2i((index % 2) * 1280, (index / 2) * 720))
	var full_sheet_path := OUTPUT.path_join("actual-gamemain-contact-sheet-native.png")
	check(full_sheet.save_png(full_sheet_path) == OK, "Saved four unscaled native 1280x720 GameMain panels")
	captures.append(full_sheet_path)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "Capture leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Capture leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == catalogue_before, "Capture leaves shared art catalogue byte-exact")
	var result := {
		"status": "native_review_candidate_not_runtime_registered",
		"family": FAMILY,
		"scene": "actual GameMain and production TownRoom architecture/navigation with one owner-scoped passive broadleaf-planter candidate",
		"renderer": DisplayServer.get_name(),
		"viewport_per_panel": [1280, 720],
		"worker_disabled": true,
		"save_access": false,
		"runtime_registered": false,
		"dev_catalogue_registration": "Not asserted; this capture only verifies the shared catalogue stays byte-exact during its run.",
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"shared_art_catalogue_mutated": false,
		"service_backend_or_interaction_created": false,
		"common_safe_pivot": [common_pivot.x, common_pivot.y],
		"wall_and_corner": wall_results,
		"observations": observations,
		"captures": captures,
		"actor_probe_limit": "The existing founder is only a scale, route, adjacent contact, gaze and occlusion/depth probe; no plant interaction, service, animation, hire or backend is claimed.",
		"source_pixel_use": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room result")
	result.checks = checks
	result.failures = failures
	if file != null:
		file.store_string(JSON.stringify(result, "\t") + "\n")
	model.disable_calibration_preview(self)
	main.game_audio.shutdown()
	main.queue_free()
	await frames(3)
	print("Broadleaf planter actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
