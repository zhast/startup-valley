extends SceneTree
## DEV ONLY. Actual GameMain/TownRoom evidence for task_floor_lamp,
## coat_bag_stand, and the desk-hosted desk_lamp_kit. Every candidate is
## admitted or attached only inside this disposable capture.

const ART := preload("res://tools/passive_lighting_entry_geometry.gd")
const OUTPUTS := {
	"task_floor_lamp": "res://tests/output/task-floor-lamp-v2",
	"desk_lamp_kit": "res://tests/output/desk-lamp-kit-v2",
	"coat_bag_stand": "res://tests/output/coat-bag-stand-v3",
}
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var main: GameMain
var model: OfficeLayout
var family := ""
var candidate_id := ""
var common_pivot := Vector2i(12, 13)
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

func frames(count := 2) -> void:
	for _index: int in range(count): await process_frame

func collision_shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if node is CollisionShape2D: result.append(node as CollisionShape2D)
	for child: Node in node.get_children(): result.append_array(collision_shapes(child))
	return result

func capture_frame(path: String, captures: Array[String]) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), family + " actual GameMain capture stays native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

func image_difference(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x, y) != b.get_pixel(x, y): result += 1
	return result

func changed_points(before: Image, after: Image, points: Array[Vector2i]) -> int:
	var result := 0
	for point: Vector2i in points:
		if before.get_pixelv(point) != after.get_pixelv(point):
			result += 1
	return result

func exact_source_region(frame: Image, source: Image, rect: Rect2i) -> Dictionary:
	var opaque := 0
	var mismatches := 0
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var expected := source.get_pixel(x, y)
			if expected.a == 0.0:
				continue
			opaque += 1
			if frame.get_pixel(x, y) != expected:
				mismatches += 1
	return {"opaque": opaque, "mismatches": mismatches}

func issue_codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for issue: Dictionary in result.get("issues", []):
		var code := str(issue.get("code", ""))
		if not codes.has(code): codes.append(code)
	return codes

func wall_neighbors(point: Vector2i) -> int:
	var result := 0
	for offset: Vector2i in OfficeLayout.NEIGHBORS:
		if not model.is_floor(point + offset): result += 1
	return result

func choose_common_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(3, model.height - 3):
		for x: int in range(3, model.width - 3):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in ART.SIDES:
				if not model.validate_candidate(candidate_id, point, side, 0).valid:
					valid = false
					break
			if valid: choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(Vector2i(12, 13)) < b.distance_squared_to(Vector2i(12, 13))
	)
	check(not choices.is_empty(), family + " has one production-room pivot safe for all facings")
	return choices[0] if not choices.is_empty() else Vector2i(12, 13)

func find_corner_probe(side: String) -> Dictionary:
	var fallback := {}
	var wall_codes: Array[String] = ["wall_intersection", "visual_wall_intersection", "wall_clearance", "decorative_headroom"]
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point): continue
			var result := model.validate_candidate(candidate_id, point, side, 0)
			if result.valid: continue
			var codes := issue_codes(result)
			var architectural := false
			for code: String in codes:
				if code in wall_codes: architectural = true
			if not architectural: continue
			var probe := {"grid": point, "codes": codes, "wall_neighbors": wall_neighbors(point)}
			if fallback.is_empty(): fallback = probe
			if int(probe.wall_neighbors) >= 2: return probe
	return fallback

func visible_point_for(layer_name: String, sprites: Dictionary, size: Vector2i) -> Vector2:
	var sprite := sprites[layer_name] as Sprite2D
	var image := (sprite.texture as Texture2D).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0: continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5) - Vector2(size) / 2.0)
			var all: Array[Sprite2D] = []
			for name_value: String in ART.layer_names(family): all.append(sprites[name_value] as Sprite2D)
			if VisibleSurface.top(all, point) == sprite: return point
	return Vector2(INF, INF)

func inspect_base_prop(side: String) -> Dictionary:
	var room: TownRoom = main.room
	var placement := room.placement_by_id(candidate_id)
	var prop := room.prop_node(candidate_id)
	check(prop != null and prop.get_script() == null, family + "/" + side + " uses TownRoom's neutral native-layer carrier")
	if prop == null: return {}
	check(placement.facing == side and placement.profile_kind == "decorative", family + "/" + side + " remains a passive owner-scoped candidate")
	check(not placement.has("interaction") and not room.interaction_world_position(candidate_id).is_finite(), family + "/" + side + " creates no service/action target")
	check(placement.occupied == [placement.grid] and placement.clearance.size() == 1, family + "/" + side + " resolves one collision and one clear probe cell")
	var shapes := collision_shapes(prop)
	check(shapes.size() == 1, family + "/" + side + " builds one real collision shape")
	if shapes.size() == 1:
		check(shapes[0].shape is RectangleShape2D and (shapes[0].shape as RectangleShape2D).size == Vector2(32, 32), family + "/" + side + " collision is exact 32px square")
		check(Vector2i(shapes[0].global_position.round()) == Vector2i((room.global_position + model.world(placement.grid)).round()), family + "/" + side + " collision center matches its occupied cell")
	check(not room.navigation.walkable(placement.grid), family + "/" + side + " occupied cell blocks actual AStar")
	var sprites := {}
	for layer_name: String in ART.layer_names(family):
		var descriptor := ART.descriptor(family, side, layer_name)
		var sprite := prop.get_node(str(descriptor.name)) as Sprite2D
		sprites[layer_name] = sprite
		check(sprite != null and sprite.texture.get_size() == Vector2(ART.canvas(family)), family + "/" + side + "/" + layer_name + " loads full native canvas")
		check(sprite.position == Vector2(ART.sprite_offset(family)) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, family + "/" + side + "/" + layer_name + " keeps native registration")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), family + "/" + side + "/" + layer_name + " keeps authored depth")
	for layer_name: String in ART.layer_names(family):
		var point := visible_point_for(layer_name, sprites, ART.canvas(family))
		check(point.is_finite(), family + "/" + side + "/" + layer_name + " owns a visible surface pixel")
		if point.is_finite():
			var hit := room.surface_at(point)
			check(hit.get("sprite") == sprites[layer_name], family + "/" + side + " alpha-aware picking selects " + layer_name)
			check((hit.get("interaction", {}) as Dictionary).is_empty() and main._interaction_at(point).is_empty(), family + "/" + side + " passive surface invents no action")
	return {"placement": placement, "prop": prop, "sprites": sprites, "shape_count": shapes.size()}

func source_match(frame: Image, placement: Dictionary) -> Dictionary:
	var source := ART.whole(family, str(placement.facing))
	var origin := Vector2i(main.room.global_position + Vector2(placement.anchor)) - ART.pivot(family)
	var opaque := 0
	var mismatches := 0
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			var expected := source.get_pixel(x, y)
			if expected.a == 0.0: continue
			opaque += 1
			if frame.get_pixelv(origin + Vector2i(x, y)) != expected: mismatches += 1
	return {"opaque": opaque, "mismatches": mismatches}

func approach_founder(side: String, placement: Dictionary, sprites: Dictionary) -> Dictionary:
	var p := ART.profile(family, side)
	var relative := OfficeLayout.vector(p.interaction)
	var destination_cell: Vector2i = placement.grid + relative
	var destination := model.world(destination_cell)
	check(placement.standing_viewpoints.size() == 1 and placement.standing_viewpoints[0].cell == destination_cell, family + "/" + side + " exposes only declared passive viewpoint")
	check(main.room.navigation.walkable(destination_cell) and destination_cell not in placement.occupied, family + "/" + side + " probe cell is walkable and outside collision")
	main.player.show()
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 18))
	main.room.navigation.actors["founder"] = main.player.position
	check(main.player.move_to(destination), family + "/" + side + " founder receives an actual approach route")
	var route_points := main.player.route.size()
	var crossings := 0
	var safe := true
	var traveled := 0.0
	for _tick: int in range(900):
		var before := main.player.position
		main.player._physics_process(1.0 / 30.0)
		traveled += before.distance_to(main.player.position)
		if not main.room.navigation.position_is_safe(main.player.position, "founder"): safe = false
		if model.cell_at(main.player.position) in placement.occupied: crossings += 1
		if main.player.route.is_empty(): break
	check(safe and crossings == 0 and main.player.route.is_empty() and main.player.position.distance_to(destination) < 0.1, family + "/" + side + " reaches exact contact without crossing collision")
	main.player.z_index = roundi(main.player.position.y)
	main.player.face_direction(Vector2(OfficeLayout.vector(p.employee_look_vector)))
	var rear := sprites.rear_structure as Sprite2D
	var front := sprites.front_structure as Sprite2D
	var depth_class := ""
	if relative.y < 0:
		check(main.player.z_index < rear.z_index, family + "/" + side + " approach actor is behind whole structure")
		depth_class = "actor_behind_structure"
	elif relative.y > 0:
		check(main.player.z_index > front.z_index, family + "/" + side + " approach actor is in front of whole structure")
		depth_class = "actor_in_front_of_structure"
	else:
		check(rear.z_index < main.player.z_index and main.player.z_index < front.z_index, family + "/" + side + " side approach actor is bracketed by rear/front")
		depth_class = "actor_between_rear_and_front_layers"
	return {"destination_cell": [destination_cell.x, destination_cell.y], "destination_px": [destination.x, destination.y], "employee_look_vector": p.employee_look_vector, "initial_route_points": route_points, "traveled_px": traveled, "occupied_crossings": crossings, "actor_z": main.player.z_index, "rear_z": rear.z_index, "front_z": front.z_index, "depth_class": depth_class}

func actor_layer_overlap(side: String, placement: Dictionary, sprites: Dictionary) -> Dictionary:
	var result := {"floor_shadow": 0, "rear_structure": 0, "front_structure": 0, "wrong_depth_pixels": 0}
	var relative := OfficeLayout.vector(ART.profile(family, side).interaction)
	var bounds: Rect2 = placement.world_visual_bounds
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body := main.player.body_surface_at(point)
			if body == null: continue
			for layer_name: String in ART.BASE_LAYERS:
				var sprite := sprites[layer_name] as Sprite2D
				if not VisibleSurface.painted(sprite, point): continue
				result[layer_name] = int(result[layer_name]) + 1
				var correct := true
				if relative.y < 0: correct = VisibleSurface.in_front(sprite, body)
				elif relative.y > 0: correct = VisibleSurface.in_front(body, sprite)
				elif layer_name == "front_structure": correct = VisibleSurface.in_front(sprite, body)
				else: correct = VisibleSurface.in_front(body, sprite)
				if not correct: result.wrong_depth_pixels = int(result.wrong_depth_pixels) + 1
	result["total"] = int(result.floor_shadow) + int(result.rear_structure) + int(result.front_structure)
	check(int(result.wrong_depth_pixels) == 0, family + "/" + side + " has no wrong-depth actor intersection pixels")
	return result

func run_base_side(side: String, base_details: Dictionary[String, Image], actor_details: Dictionary[String, Image], room_frames: Dictionary[String, Image], observations: Dictionary, captures: Array[String]) -> void:
	check(main.room.set_placement_overrides({candidate_id: {"grid": [common_pivot.x, common_pivot.y], "facing": side}}), family + "/" + side + " commits at common safe pivot")
	await frames(3)
	var inspected := inspect_base_prop(side)
	if inspected.is_empty(): return
	var placement: Dictionary = inspected.placement
	main.player.hide()
	await frames(2)
	await RenderingServer.frame_post_draw
	var base_frame := root.get_texture().get_image()
	var crop := Rect2i(Vector2i(main.room.global_position + placement.anchor) - ART.pivot(family), ART.canvas(family))
	var base_detail := base_frame.get_region(crop)
	var exact := source_match(base_frame, placement)
	check(int(exact.opaque) > 0 and int(exact.mismatches) == 0, family + "/" + side + " preserves all opaque candidate pixels before actor contact")
	var output := str(OUTPUTS[family])
	var base_path := output.path_join("detail-%s-base-native.png" % side)
	check(base_detail.save_png(base_path) == OK, "Saved " + base_path)
	captures.append(base_path)
	base_details[side] = base_detail
	var approach := approach_founder(side, placement, inspected.sprites)
	await frames(2)
	var room_frame := await capture_frame(output.path_join("room-%s.png" % side), captures)
	room_frames[side] = room_frame
	var actor_detail := room_frame.get_region(crop)
	var actor_path := output.path_join("detail-%s-actor-native.png" % side)
	check(actor_detail.save_png(actor_path) == OK, "Saved " + actor_path)
	captures.append(actor_path)
	actor_details[side] = actor_detail
	var delta := image_difference(base_detail, actor_detail)
	check(delta > 0, family + "/" + side + " exact crop visibly contains founder probe")
	var overlap := actor_layer_overlap(side, placement, inspected.sprites)
	check(collision_shapes(inspected.prop).size() == int(inspected.shape_count) and not main.room.navigation.walkable(placement.grid), family + "/" + side + " actor approach leaves collision stable")
	observations[side] = {"grid": [common_pivot.x, common_pivot.y], "occupied": placement.occupied.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]), "clearance": placement.clearance.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]), "collision_shapes": inspected.shape_count, "founder_approach": approach, "actor_pixel_delta": delta, "actor_layer_overlap_measured_not_required": overlap, "source_match": exact, "render_layers": placement.render_layers}

func save_sheets(base_details: Dictionary[String, Image], actor_details: Dictionary[String, Image], room_frames: Dictionary[String, Image], captures: Array[String]) -> void:
	var size := ART.canvas(family)
	var base_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	var actor_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	base_sheet.fill(Color("151515")); actor_sheet.fill(Color("151515"))
	for index: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[index]
		base_sheet.blit_rect(base_details[side], Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
		actor_sheet.blit_rect(actor_details[side], Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
	var output := str(OUTPUTS[family])
	var base_path := output.path_join("actual-room-base-contact-sheet-native.png")
	check(base_sheet.save_png(base_path) == OK, "Saved " + base_path); captures.append(base_path)
	var actor_path := output.path_join("actual-room-actor-contact-sheet-native.png")
	check(actor_sheet.save_png(actor_path) == OK, "Saved " + actor_path); captures.append(actor_path)
	var enlarged := actor_sheet.duplicate(); enlarged.resize(enlarged.get_width() * 4, enlarged.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := output.path_join("actual-room-actor-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved " + enlarged_path); captures.append(enlarged_path)
	var full := Image.create(2560, 1440, false, Image.FORMAT_RGBA8); full.fill(Color("151515"))
	for index: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[index]
		full.blit_rect(room_frames[side], Rect2i(0, 0, 1280, 720), Vector2i((index % 2) * 1280, (index / 2) * 720))
	var full_path := output.path_join("actual-gamemain-contact-sheet-native.png")
	check(full.save_png(full_path) == OK, "Saved " + full_path); captures.append(full_path)

func configure_base(next_family: String) -> void:
	family = next_family; candidate_id = family + "-candidate"
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main); await frames(5)
	main.set_process(false); main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0)
	main.founder_hud.dismiss_movement_hint(); main.job_panel.close_drawer(false); main.company_panel.hide(); main._spawn_employees([])
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, family + " GameMain starts no worker")
	var room_data := main.room.layout_model.data.duplicate(true)
	var catalogue := main.room.layout_model.catalog.duplicate(true)
	room_data.props = [{"id": candidate_id, "kind": family, "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []; room_data.player_spawn = [17, 18]
	catalogue[family] = ART.catalog_entry(family)
	model = OfficeLayout.new(); model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), family + " owns isolated calibration model")
	for side: String in ART.SIDES: check(model.authorize_calibration_decorative_profile(family, side, self), family + "/" + side + " receives owner-scoped passive admission")
	main.room.layout_model = model; main.room.player_spawn = Vector2i(17, 18); main.room.placement_overrides.clear(); main.room.architecture.configure(model); main.room.set_hire_count(0)
	main.player.set_physics_process(false); main.player.position = model.world(Vector2i(17, 18)); main.room.navigation.actors["founder"] = main.player.position
	await frames(3)

func close_current() -> void:
	if model != null: model.disable_calibration_preview(self)
	if main != null:
		main.game_audio.shutdown(); main.queue_free(); await frames(3)
	main = null; model = null

func run_base_family(next_family: String, cleanup_after := true) -> void:
	var start_checks := checks; var start_failures := failures.size()
	await configure_base(next_family)
	common_pivot = choose_common_pivot()
	var walls := {}
	for side: String in ART.SIDES:
		var probe := find_corner_probe(side)
		check(not probe.is_empty() and int(probe.wall_neighbors) >= 2, family + "/" + side + " finds production-room two-axis corner rejection")
		if not probe.is_empty():
			var before := main.room.placement_by_id(candidate_id).duplicate(true)
			check(not main.room.set_placement_overrides({candidate_id: {"grid": [probe.grid.x, probe.grid.y], "facing": side}}), family + "/" + side + " unsafe corner is rejected")
			var after := main.room.placement_by_id(candidate_id)
			check(after.grid == before.grid and after.facing == before.facing, family + "/" + side + " rejection is atomic")
			walls[side] = {"grid": [probe.grid.x, probe.grid.y], "wall_neighbors": probe.wall_neighbors, "issue_codes": probe.codes}
	var base_details: Dictionary[String, Image] = {}; var actor_details: Dictionary[String, Image] = {}; var room_frames: Dictionary[String, Image] = {}; var observations := {}; var captures: Array[String] = []
	for side: String in ART.SIDES: await run_base_side(side, base_details, actor_details, room_frames, observations, captures)
	save_sheets(base_details, actor_details, room_frames, captures)
	var local_failures: Array[String] = []
	for index: int in range(start_failures, failures.size()): local_failures.append(failures[index])
	var result := {"status": "native_review_candidate_not_runtime_registered", "family": family, "scene": "actual GameMain and production TownRoom with one owner-scoped passive candidate", "renderer": DisplayServer.get_name(), "viewport": [1280, 720], "worker_disabled": true, "save_access": false, "runtime_registered": false, "service_created": false, "common_safe_pivot": [common_pivot.x, common_pivot.y], "wall_corner_rejections": walls, "observations": observations, "captures": captures, "actor_probe_limit": "Founder is only a route, scale, gaze and depth probe; no service or light interaction is created.", "checks": checks - start_checks, "failures": local_failures}
	var file := FileAccess.open(str(OUTPUTS[family]).path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " actual-room result")
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	if cleanup_after:
		await close_current()

func attach_desk_lamp(prop: Node2D, side: String) -> Dictionary:
	var sprites := {}
	for layer_name: String in ART.DESK_LAYERS:
		var descriptor := ART.descriptor("desk_lamp_kit", side, layer_name)
		var source := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
		var sprite := Sprite2D.new(); sprite.name = str(descriptor.name); sprite.texture = ImageTexture.create_from_image(source)
		sprite.position = Vector2(ART.sprite_offset("desk_lamp_kit")); sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; sprite.z_as_relative = false; sprite.z_index = prop.z_index + int(descriptor.z_offset)
		prop.add_child(sprite); sprites[layer_name] = sprite
		check(sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + "/" + layer_name + " desk overlay has no runtime transform")
	return sprites

func setup_mira(actor: EmployeeAvatar) -> void:
	actor.show(); actor.set_physics_process(false); actor.position = actor.desk_position; actor.navigation.actors[actor.employee_id] = actor.position
	actor._has_target = false; actor.has_live_job = true; actor.work_state = EmployeeAvatar.WorkState.TYPING; actor._activity = &"typing"; actor._animation_elapsed = 0.26
	actor._update_character_frame(); actor._physics_process(0.14); actor.labels_suppressed = true; actor._speech_visible = false; actor._label_layer.hide(); actor._effect_sprite.hide()

func masked_change(before: Image, after: Image, mask: Image) -> Dictionary:
	var changed := 0; var covered := 0
	for y: int in range(mask.get_height()):
		for x: int in range(mask.get_width()):
			if mask.get_pixel(x, y).a == 0.0: continue
			if before.get_pixel(x, y) != after.get_pixel(x, y): changed += 1
			else: covered += 1
	return {"changed": changed, "covered_by_host": covered, "source_opaque": changed + covered}

func desk_actor_overlap(actor: EmployeeAvatar, sprites: Dictionary, placement: Dictionary) -> Dictionary:
	var result := {"surface_decor_rear": 0, "surface_decor_front": 0}
	var bounds: Rect2 = placement.world_visual_bounds; bounds.position += main.room.global_position
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			if actor.body_surface_at(point) == null: continue
			for layer_name: String in ART.DESK_LAYERS:
				if VisibleSurface.painted(sprites[layer_name], point): result[layer_name] = int(result[layer_name]) + 1
	result["total"] = int(result.surface_decor_rear) + int(result.surface_decor_front)
	return result

func run_desk_lamp(cleanup_after := true) -> void:
	var start_checks := checks; var start_failures := failures.size(); family = "desk_lamp_kit"
	main = load("res://world/main.tscn").instantiate() as GameMain; root.add_child(main); await frames(5)
	main.set_process(false); main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0); main.founder_hud.dismiss_movement_hint(); main.job_panel.close_drawer(false); main.company_panel.hide(); main.player.hide(); main.player.set_physics_process(false)
	var mira := main.get_employee("mira"); var theo := main.get_employee("theo")
	check(mira != null and theo != null, "Desk lamp uses only existing production employees")
	if theo != null: theo.hide(); theo.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Desk lamp GameMain starts no worker")
	var baseline_details: Dictionary[String, Image] = {}; var lamp_details: Dictionary[String, Image] = {}; var actor_details: Dictionary[String, Image] = {}; var room_frames: Dictionary[String, Image] = {}; var observations := {}; var captures: Array[String] = []
	for side: String in ART.SIDES:
		check(main.room.set_placement_overrides({"mira-workstation": {"grid": [10, 8], "facing": side}}), side + " accepted production desk commits at lamp review pivot")
		main._on_room_placements_changed(); await frames(3)
		var placement := main.room.placement_by_id("mira-workstation"); var prop := main.room.prop_node("mira-workstation")
		check(placement.facing == side and str(placement.workstation_capability_revision) == "workstations-v2:" + side and placement.occupied.size() > 0, side + " lamp host is the ordinary accepted production workstation")
		var shapes_before := collision_shapes(prop).size()
		mira.hide(); await frames(2); await RenderingServer.frame_post_draw
		var crop := Rect2i(Vector2i(main.room.global_position + placement.anchor) - ART.pivot(family), ART.canvas(family))
		var baseline := root.get_texture().get_image().get_region(crop); baseline_details[side] = baseline
		var sprites := attach_desk_lamp(prop, side); await frames(2); await RenderingServer.frame_post_draw
		var lamp_only := root.get_texture().get_image().get_region(crop); lamp_details[side] = lamp_only
		var support_path := ART.desk_support_path(side)
		var support_pixels_visible := changed_points(baseline, lamp_only, support_path)
		check(support_pixels_visible == support_path.size(), side + " base-to-shade support centerline remains continuously visible after accepted host composition")
		var shade_source_match := exact_source_region(lamp_only, ART.whole(family, side), ART.profile(family, side).shade)
		check(int(shade_source_match.opaque) > 0 and int(shade_source_match.mismatches) == 0, side + " complete shade pixels match the whole source after accepted host composition")
		var layer_visibility := {}
		var parts := ART.layers(family, side)
		for layer_name: String in ART.DESK_LAYERS:
			layer_visibility[layer_name] = masked_change(baseline, lamp_only, parts[layer_name])
			check(int(layer_visibility[layer_name].changed) > 0, side + " " + layer_name + " contributes visible pixels on accepted desk")
		setup_mira(mira); await frames(2)
		var full := await capture_frame(str(OUTPUTS[family]).path_join("room-%s.png" % side), captures); room_frames[side] = full
		var actor_detail := full.get_region(crop); actor_details[side] = actor_detail
		check(image_difference(lamp_only, actor_detail) > 0, side + " occupied lamp/desk crop visibly contains existing Mina")
		check(mira.position == mira.desk_position and mira._uses_seated_visual(), side + " Mina keeps accepted authored workstation contact")
		check(collision_shapes(prop).size() == shapes_before, side + " zero-collision lamp overlays do not mutate desk collision")
		for layer_name: String in ART.DESK_LAYERS:
			var sprite := sprites[layer_name] as Sprite2D
			check(sprite.position == Vector2(ART.sprite_offset(family)) and sprite.z_index == prop.z_index + ART.layer_depth(family, layer_name), side + " " + layer_name + " stays on exact host anchor/depth")
		observations[side] = {"desk_asset_revision": placement.profile.asset_revision, "workstation_capability_revision": placement.workstation_capability_revision, "work_position_px": [mira.desk_position.x, mira.desk_position.y], "collision_shapes_before_after": [shapes_before, collision_shapes(prop).size()], "support_centerline_visible_pixels": support_pixels_visible, "support_centerline_total_pixels": support_path.size(), "shade_whole_source_match": shade_source_match, "layer_visibility": layer_visibility, "actor_overlay_intersection_measured_not_required": desk_actor_overlap(mira, sprites, placement), "render_descriptors": ART.DESK_LAYERS.map(func(name_value: String) -> Dictionary: return ART.descriptor(family, side, name_value))}
		mira.hide()
	var size := ART.canvas(family); var baseline_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8); var lamp_sheet := baseline_sheet.duplicate(); var actor_sheet := baseline_sheet.duplicate(); baseline_sheet.fill(Color("151515")); lamp_sheet.fill(Color("151515")); actor_sheet.fill(Color("151515"))
	for index: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[index]; var at := Vector2i(index * size.x, 0)
		baseline_sheet.blit_rect(baseline_details[side], Rect2i(Vector2i.ZERO, size), at); lamp_sheet.blit_rect(lamp_details[side], Rect2i(Vector2i.ZERO, size), at); actor_sheet.blit_rect(actor_details[side], Rect2i(Vector2i.ZERO, size), at)
	for item: Array in [[baseline_sheet, "actual-room-host-baseline-native.png"], [lamp_sheet, "actual-room-lamp-contact-sheet-native.png"], [actor_sheet, "actual-room-actor-contact-sheet-native.png"]]:
		var path := str(OUTPUTS[family]).path_join(str(item[1])); check((item[0] as Image).save_png(path) == OK, "Saved " + path); captures.append(path)
	var enlarged := actor_sheet.duplicate(); enlarged.resize(enlarged.get_width() * 4, enlarged.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := str(OUTPUTS[family]).path_join("actual-room-actor-contact-sheet-4x.png"); check(enlarged.save_png(enlarged_path) == OK, "Saved " + enlarged_path); captures.append(enlarged_path)
	var full_sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8); full_sheet.fill(Color("151515"))
	for index: int in range(ART.SIDES.size()): full_sheet.blit_rect(room_frames[ART.SIDES[index]], Rect2i(0, 0, 1280, 720), Vector2i((index % 2) * 1280, (index / 2) * 720))
	var full_path := str(OUTPUTS[family]).path_join("actual-gamemain-contact-sheet-native.png"); check(full_sheet.save_png(full_path) == OK, "Saved " + full_path); captures.append(full_path)
	var local_failures: Array[String] = []
	for index: int in range(start_failures, failures.size()):
		local_failures.append(failures[index])
	var result := {"status": "native_review_candidate_not_runtime_registered", "family": family, "scene": "actual GameMain / production TownRoom with accepted workstation and manually attached exact candidate overlays", "renderer": DisplayServer.get_name(), "viewport": [1280, 720], "worker_disabled": true, "save_access": false, "runtime_registered": false, "floor_collision_added": false, "service_created": false, "observations": observations, "captures": captures, "actor_probe_limit": "Existing Mina proves accepted workstation contact, gaze, host depth and visible overlay contribution only; no lamp service, switch or work behavior is created.", "checks": checks - start_checks, "failures": local_failures}
	var file := FileAccess.open(str(OUTPUTS[family]).path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened desk lamp actual-room result")
	if file != null:
		file.store_string(JSON.stringify(result, "\t") + "\n")
	if cleanup_after:
		main.game_audio.shutdown()
		main.queue_free()
		await frames(3)
		main = null

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Passive lighting/entry actual-room evidence requires native renderer; run test_passive_lighting_entry.gd headlessly."); quit(1); return
	root.size = Vector2i(1280, 720); root.content_scale_size = Vector2i(1280, 720); root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for output: String in OUTPUTS.values(): DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var before := {"production": FileAccess.get_sha256(PRODUCTION_CATALOG), "layout": FileAccess.get_sha256(DEFAULT_LAYOUT), "catalogue": FileAccess.get_sha256(DEV_CATALOGUE)}
	var requested_family := OS.get_environment("STARTUP_VALLEY_PASSIVE_CAPTURE_FAMILY")
	check(requested_family in OUTPUTS, "One known passive family must be requested in STARTUP_VALLEY_PASSIVE_CAPTURE_FAMILY")
	if requested_family not in OUTPUTS:
		print("Passive lighting/entry actual room: %d checks, %d failures" % [checks, failures.size()])
		quit(1)
		return
	if requested_family == "task_floor_lamp":
		await run_base_family(requested_family, false)
	elif requested_family == "coat_bag_stand":
		await run_base_family(requested_family, false)
	elif requested_family == "desk_lamp_kit":
		await run_desk_lamp(false)
	if model != null:
		model.disable_calibration_preview(self)
	if main != null:
		main.game_audio.shutdown()
		main.free()
	main = null
	model = null
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == before.production, "Capture leaves production catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == before.layout, "Capture leaves default layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == before.catalogue, "Capture leaves shared art catalogue byte-exact")
	print("Passive lighting/entry actual room%s: %d checks, %d failures" % [("/" + requested_family) if not requested_family.is_empty() else "", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
