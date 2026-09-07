extends SceneTree
## DEV ONLY. Actual GameMain/TownRoom evidence for the shadow-corrected owner-scoped passive
## visitor chair. Mina is an existing standing/seated contact and depth probe;
## her accepted directional pose remains separately owned character art.

const CHAIR := preload("res://tools/visitor_chair_review_v2.gd")
const OUTPUT := "res://tests/output/visitor-chair-v2"
const CANDIDATE_ID := "visitor-chair-candidate"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var main: GameMain
var model: OfficeLayout
var production_catalogue: Dictionary
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

func body_sprites(actor: EmployeeAvatar) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = [actor._character_sprite]
	for sprite: Sprite2D in actor._work_pose_layer_sprites.values(): result.append(sprite)
	return result

func capture_frame(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain source frame stays native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

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

func wall_distance(point: Vector2i) -> int:
	for radius: int in range(1, 8):
		for y: int in range(-radius, radius + 1):
			for x: int in range(-radius, radius + 1):
				if absi(x) + absi(y) != radius: continue
				if not model.is_floor(point + Vector2i(x, y)): return radius
	return 99

func choose_common_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(2, model.height - 2):
		for x: int in range(2, model.width - 2):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in CHAIR.SIDES:
				if not model.validate_candidate(CANDIDATE_ID, point, side, 0).valid:
					valid = false
					break
			if valid: choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(Vector2i(12, 13)) < b.distance_squared_to(Vector2i(12, 13))
	)
	check(not choices.is_empty(), "Actual production architecture has one common safe pivot for N/E/S/W")
	return choices[0] if not choices.is_empty() else Vector2i(12, 13)

func nearest_valid_wall_probe(side: String) -> Dictionary:
	var best := {}
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point): continue
			var result := model.validate_candidate(CANDIDATE_ID, point, side, 0)
			if not result.valid: continue
			var distance := wall_distance(point)
			if best.is_empty() or distance < int(best.distance): best = {"grid": point, "distance": distance}
	return best

func corner_rejection(side: String) -> Dictionary:
	var fallback := {}
	for y: int in range(model.height):
		for x: int in range(model.width):
			var point := Vector2i(x, y)
			if not model.is_floor(point): continue
			var result := model.validate_candidate(CANDIDATE_ID, point, side, 0)
			if result.valid: continue
			var codes := issue_codes(result)
			var architecture := false
			for code: String in codes:
				if code in ["wall_intersection", "visual_wall_intersection", "wall_clearance", "decorative_headroom"]: architecture = true
			if not architecture: continue
			var probe := {"grid": point, "neighbors": wall_neighbors(point), "codes": codes}
			if fallback.is_empty(): fallback = probe
			if int(probe.neighbors) >= 2: return probe
	return fallback

func visible_point_for(layer_name: String, sprites: Dictionary) -> Vector2:
	var sprite := sprites[layer_name] as Sprite2D
	var image := (sprite.texture as Texture2D).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0: continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5) - Vector2(CHAIR.CANVAS) / 2.0)
			var candidates: Array[Sprite2D] = []
			for name_value: String in CHAIR.LAYERS: candidates.append(sprites[name_value] as Sprite2D)
			if VisibleSurface.top(candidates, point) == sprite: return point
	return Vector2(INF, INF)

func inspect_prop(side: String) -> Dictionary:
	var room := main.room
	var placement := room.placement_by_id(CANDIDATE_ID)
	var prop := room.prop_node(CANDIDATE_ID)
	check(prop != null and prop.get_script() == null, side + " uses TownRoom's neutral native-layer carrier")
	if prop == null: return {}
	check(placement.facing == side and placement.profile_kind == "decorative", side + " remains an owner-scoped passive candidate")
	check(not placement.has("interaction") and not room.interaction_world_position(CANDIDATE_ID).is_finite(), side + " exposes no production action or seat destination")
	check(placement.occupied == [placement.grid] and placement.clearance.size() == 1, side + " resolves one collision cell and one clear contact cell")
	var shapes := collision_shapes(prop)
	check(shapes.size() == 1, side + " builds exactly one real collision shape")
	if shapes.size() == 1:
		var shape := shapes[0]
		check(shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(32, 32), side + " collision is an exact 32px square")
		check(Vector2i(shape.global_position.round()) == Vector2i((room.global_position + model.world(placement.grid)).round()), side + " collision center matches the occupied grid cell")
	check(not room.navigation.walkable(placement.grid), side + " occupied chair cell blocks actual AStar navigation")
	var sprites := {}
	for layer: Dictionary in placement.render_layers:
		var key := str(layer.name).trim_prefix("VisitorChair").to_snake_case()
		var sprite := prop.get_node(str(layer.name)) as Sprite2D
		sprites[key] = sprite
		check(sprite != null and sprite.texture.get_size() == Vector2(CHAIR.CANVAS), side + " " + key + " loads the full native canvas")
		check(sprite.position == Vector2(CHAIR.SPRITE_OFFSET) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + key + " keeps native integer registration")
		check(sprite.z_index == prop.z_index + int(layer.z_offset), side + " " + key + " keeps authored absolute depth")
	for layer_name: String in CHAIR.LAYERS:
		var point := visible_point_for(layer_name, sprites)
		check(point.is_finite(), side + " " + layer_name + " owns a visible painted surface")
		if point.is_finite():
			var hit := room.surface_at(point)
			check(hit.get("sprite") == sprites[layer_name], side + " alpha-aware room picking selects visible " + layer_name)
			check((hit.get("interaction", {}) as Dictionary).is_empty() and main._interaction_at(point).is_empty(), side + " painted chair surface invents no action")
	var transparent := prop.global_position + Vector2(CHAIR.SPRITE_OFFSET) - Vector2(CHAIR.CANVAS) / 2.0 + Vector2(0.5, 0.5)
	var transparent_hit := room.surface_at(transparent)
	check(transparent_hit.get("sprite") == null or (transparent_hit.get("sprite") as Node).get_parent() != prop, side + " transparent canvas padding is not pickable")
	return {"placement": placement, "prop": prop, "sprites": sprites, "shapes": shapes.size()}

func hide_probe(actor: EmployeeAvatar) -> void:
	actor.hide()
	actor._workstation_visual.clear()
	actor._has_target = false
	actor._route.clear()
	actor.work_state = EmployeeAvatar.WorkState.IDLE
	actor._update_character_frame()
	main.room.navigation.release(actor.employee_id)
	main.room.navigation.actors.erase(actor.employee_id)

func place_standing(actor: EmployeeAvatar, side: String, placement: Dictionary) -> Dictionary:
	var socket := CHAIR.contact_socket(side)
	var cell: Vector2i = placement.grid + OfficeLayout.vector(socket.physical_cell)
	var position := main.room.grid_to_world_position(cell)
	actor._workstation_visual.clear()
	actor.position = position
	actor.desk_position = position
	actor._has_target = false
	actor._route.clear()
	actor.has_live_job = false
	actor.work_state = EmployeeAvatar.WorkState.IDLE
	actor._facing = {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}[side]
	actor._animation_elapsed = 0.0
	actor.labels_suppressed = true
	actor._speech_visible = false
	actor._effect_sprite.hide()
	actor.show()
	actor._update_character_frame()
	main.room.navigation.actors[actor.employee_id] = position
	main.room.navigation.reservations[actor.employee_id] = cell
	check(main.room.navigation.walkable(cell) and main.room.navigation.position_is_safe(position, actor.employee_id), side + " optional contact cell safely supports the standing actor probe")
	check(actor.seated_render_offset() == Vector2.ZERO and not actor._uses_seated_visual(), side + " standing mode adds no hidden seat correction")
	return {"cell": cell, "position": position}

func place_seated(actor: EmployeeAvatar, side: String, placement: Dictionary) -> Dictionary:
	var socket := CHAIR.contact_socket(side)
	var cell: Vector2i = placement.grid + OfficeLayout.vector(socket.physical_cell)
	var physical := main.room.grid_to_world_position(cell)
	var accepted: Dictionary = production_catalogue.desk.facing_profiles[side]
	var metadata := {
		"work_facing": side,
		"pose_set": str(accepted.pose_set),
		"workstation_capability_revision": str(accepted.workstation_capability_revision),
		"seat_anchor": Vector2(OfficeLayout.vector(socket.seated_render_offset)),
		"seat_z_offset": 1,
		"seat_layer_z_offsets": accepted.seat_layer_z_offsets.duplicate(true),
		"prop_anchor": main.room.global_position + Vector2(placement.anchor),
	}
	actor.position = physical
	actor.desk_position = physical
	actor._has_target = false
	actor._route.clear()
	actor.has_live_job = false
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	check(actor.configure_workstation_visual(metadata), side + " existing Mina accepts her already-reviewed directional seated source for contact probing")
	actor._animation_elapsed = 0.0
	actor.show()
	actor._update_character_frame()
	main.room.navigation.actors[actor.employee_id] = physical
	main.room.navigation.reservations[actor.employee_id] = cell
	var expected_render := main.room.global_position + Vector2(placement.anchor) + Vector2(OfficeLayout.vector(socket.mounted_render_foot))
	check(actor._uses_seated_visual() and actor.seated_render_offset() == Vector2(OfficeLayout.vector(socket.seated_render_offset)), side + " probe uses accepted seated art at the declared candidate offset")
	check(actor.render_position() == expected_render, side + " physical socket plus visual mount lands on the declared chair contact")
	check(main.room.navigation.position_is_safe(actor.position, actor.employee_id) and model.cell_at(actor.position - main.room.global_position) == cell, side + " seated visual keeps physical feet/reservation on the clear socket")
	check(actor.z_index == roundi((main.room.global_position + Vector2(placement.anchor)).y) + 1, side + " seated probe depth is locked between chair rear and front")
	return {"cell": cell, "physical": physical, "render": actor.render_position(), "seat_offset": actor.seated_render_offset(), "depth": actor.z_index, "pose_set": accepted.pose_set}

func depth_overlap(actor: EmployeeAvatar, sprites: Dictionary, placement: Dictionary) -> Dictionary:
	var rear_overlap := 0
	var rear_wrong := 0
	var front_overlap := 0
	var front_wrong := 0
	var bounds: Rect2 = placement.world_visual_bounds
	bounds.position += main.room.global_position
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body := actor.body_surface_at(point)
			if body == null: continue
			var rear := sprites.seat_back as Sprite2D
			if VisibleSurface.painted(rear, point):
				rear_overlap += 1
				if not VisibleSurface.in_front(body, rear): rear_wrong += 1
			var front := sprites.seat_front as Sprite2D
			if VisibleSurface.painted(front, point):
				front_overlap += 1
				if not VisibleSurface.in_front(front, body): front_wrong += 1
	check(rear_overlap > 0 and rear_wrong == 0, str(placement.facing) + " seated body overlaps only in front of chair-back pixels")
	check(front_overlap > 0 and front_wrong == 0, str(placement.facing) + " chair-front pixels overlap only in front of the seated body")
	return {"rear_overlap": rear_overlap, "rear_wrong_depth": rear_wrong, "front_overlap": front_overlap, "front_wrong_depth": front_wrong}

func opaque_source_mismatches(frame: Image, placement: Dictionary) -> Dictionary:
	var source := CHAIR.whole(str(placement.facing))
	var origin := Vector2i(main.room.global_position + Vector2(placement.anchor)) - CHAIR.PIVOT
	var opaque := 0
	var mismatch := 0
	for y: int in range(CHAIR.CANVAS.y):
		for x: int in range(CHAIR.CANVAS.x):
			var expected := source.get_pixel(x, y)
			if expected.a == 0.0: continue
			opaque += 1
			if frame.get_pixelv(origin + Vector2i(x, y)) != expected: mismatch += 1
	return {"opaque": opaque, "mismatch": mismatch}

func image_difference(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x, y) != b.get_pixel(x, y): result += 1
	return result

func run_side(side: String, actor: EmployeeAvatar, base_details: Dictionary, standing_details: Dictionary, seated_details: Dictionary, room_frames: Dictionary) -> void:
	check(main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [common_pivot.x, common_pivot.y], "facing": side}}), side + " commits at the common pivot through actual TownRoom validation")
	await frames(3)
	var inspected := inspect_prop(side)
	if inspected.is_empty(): return
	var placement: Dictionary = inspected.placement
	var crop_rect := Rect2i(Vector2i(main.room.global_position + Vector2(placement.anchor)) - CHAIR.PIVOT, CHAIR.CANVAS)
	hide_probe(actor)
	await frames(2)
	await RenderingServer.frame_post_draw
	var base_frame := root.get_texture().get_image()
	var base := base_frame.get_region(crop_rect)
	var source_match := opaque_source_mismatches(base_frame, placement)
	check(int(source_match.opaque) > 0 and int(source_match.mismatch) == 0, side + " actual room preserves every opaque candidate source pixel before actor contact")
	var base_path := OUTPUT.path_join("detail-%s-base-native.png" % side)
	check(base.save_png(base_path) == OK, "Saved " + base_path)
	captures.append(base_path)
	base_details[side] = base
	var standing := place_standing(actor, side, placement)
	await frames(2)
	await RenderingServer.frame_post_draw
	var standing_frame := root.get_texture().get_image()
	var standing_detail := standing_frame.get_region(crop_rect)
	var standing_path := OUTPUT.path_join("detail-%s-standing-native.png" % side)
	check(standing_detail.save_png(standing_path) == OK, "Saved " + standing_path)
	captures.append(standing_path)
	standing_details[side] = standing_detail
	check(image_difference(base, standing_detail) > 0, side + " standing contact probe is visible in the exact native crop")
	var seated := place_seated(actor, side, placement)
	await frames(2)
	var full := await capture_frame(OUTPUT.path_join("room-%s-seated.png" % side))
	room_frames[side] = full
	var seated_detail := full.get_region(crop_rect)
	var seated_path := OUTPUT.path_join("detail-%s-seated-native.png" % side)
	check(seated_detail.save_png(seated_path) == OK, "Saved " + seated_path)
	captures.append(seated_path)
	seated_details[side] = seated_detail
	check(image_difference(base, seated_detail) > 0 and image_difference(standing_detail, seated_detail) > 0, side + " optional seated contact is visible and distinct from standing mode")
	var overlap := depth_overlap(actor, inspected.sprites, placement)
	check((collision_shapes(inspected.prop) as Array).size() == int(inspected.shapes), side + " standing/seated probes do not mutate collision geometry")
	observations[side] = {
		"grid": [common_pivot.x, common_pivot.y],
		"occupied": [[placement.grid.x, placement.grid.y]],
		"clearance": placement.clearance.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"standing_probe": {"cell": [standing.cell.x, standing.cell.y], "position": [standing.position.x, standing.position.y]},
		"seated_probe": {"cell": [seated.cell.x, seated.cell.y], "physical": [seated.physical.x, seated.physical.y], "render": [seated.render.x, seated.render.y], "seat_offset": [seated.seat_offset.x, seated.seat_offset.y], "depth": seated.depth, "pose_set": seated.pose_set},
		"depth_overlap": overlap,
		"source_match": source_match,
		"render_layers": placement.render_layers,
		"collision_shapes": inspected.shapes,
	}
	hide_probe(actor)

func make_sheet(images: Dictionary, path: String, background := Color("151515")) -> void:
	var sheet := Image.create(CHAIR.CANVAS.x * 4, CHAIR.CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(background)
	for index: int in range(CHAIR.SIDES.size()):
		var side: String = CHAIR.SIDES[index]
		if images.has(side): sheet.blit_rect(images[side], Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(index * CHAIR.CANVAS.x, 0))
	check(sheet.save_png(path) == OK, "Saved " + path)
	captures.append(path)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visitor-chair actual-room evidence requires the native renderer; run test_visitor_chair.gd headlessly.")
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
	main.player.hide()
	main.player.set_physics_process(false)
	var actor := main.get_employee("mira")
	var theo := main.get_employee("theo")
	check(actor != null and theo != null and main._employees.size() == 2, "Actual GameMain supplies only its two existing employees")
	if actor == null:
		quit(1)
		return
	if theo != null:
		theo.hide()
		theo.set_physics_process(false)
	actor.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker transport")
	production_catalogue = main.room.layout_model.catalog.duplicate(true)
	var room_data := main.room.layout_model.data.duplicate(true)
	room_data.props = [{"id": CANDIDATE_ID, "kind": "visitor_chair", "grid": [12, 13], "facing": "north", "required_hires": 0}]
	var catalogue := production_catalogue.duplicate(true)
	catalogue["visitor_chair"] = CHAIR.catalog_entry()
	model = OfficeLayout.new()
	model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), "Capture owns one isolated dev-only layout model")
	for side: String in CHAIR.SIDES:
		check(model.authorize_calibration_decorative_profile("visitor_chair", side, self), side + " exact definition receives passive owner-scoped admission")
	main.room.layout_model = model
	main.room.player_spawn = OfficeLayout.vector(room_data.player_spawn)
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.navigation.configure(model.navigation_data(), main.room.global_position)
	main.room.set_hire_count(0)
	await frames(3)
	common_pivot = choose_common_pivot()
	var wall_results := {}
	for side: String in CHAIR.SIDES:
		var wall := nearest_valid_wall_probe(side)
		check(not wall.is_empty() and int(wall.distance) <= 3, side + " has a genuinely valid placement within three cells of architecture")
		if not wall.is_empty():
			check(main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [wall.grid.x, wall.grid.y], "facing": side}}), side + " commits the valid near-wall placement in actual TownRoom")
		var corner := corner_rejection(side)
		check(not corner.is_empty() and int(corner.neighbors) >= 2, side + " finds an actual two-axis corner rejection")
		if not corner.is_empty():
			var before := main.room.placement_by_id(CANDIDATE_ID).duplicate(true)
			check(not main.room.set_placement_overrides({CANDIDATE_ID: {"grid": [corner.grid.x, corner.grid.y], "facing": side}}), side + " unsafe wall/corner placement is rejected atomically")
			var after := main.room.placement_by_id(CANDIDATE_ID)
			check(after.grid == before.grid and after.facing == before.facing, side + " rejected corner leaves the committed near-wall chair unchanged")
		wall_results[side] = {
			"nearest_valid": [wall.grid.x, wall.grid.y] if not wall.is_empty() else [],
			"wall_distance_cells": wall.distance if not wall.is_empty() else null,
			"rejected_corner": [corner.grid.x, corner.grid.y] if not corner.is_empty() else [],
			"corner_wall_neighbors": corner.neighbors if not corner.is_empty() else 0,
			"rejection_codes": corner.codes if not corner.is_empty() else [],
		}
	var base_details: Dictionary = {}
	var standing_details: Dictionary = {}
	var seated_details: Dictionary = {}
	var room_frames: Dictionary = {}
	for side: String in CHAIR.SIDES: await run_side(side, actor, base_details, standing_details, seated_details, room_frames)
	make_sheet(base_details, OUTPUT.path_join("actual-room-base-contact-sheet-native.png"))
	make_sheet(standing_details, OUTPUT.path_join("actual-room-standing-contact-sheet-native.png"))
	make_sheet(seated_details, OUTPUT.path_join("actual-room-seated-contact-sheet-native.png"))
	var seated_sheet := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join("actual-room-seated-contact-sheet-native.png")))
	var enlarged := seated_sheet.duplicate()
	enlarged.resize(enlarged.get_width() * 4, enlarged.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-seated-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved nearest-neighbor seated inspection sheet")
	captures.append(enlarged_path)
	var full_sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8)
	full_sheet.fill(Color("151515"))
	for index: int in range(CHAIR.SIDES.size()):
		var side: String = CHAIR.SIDES[index]
		if room_frames.has(side): full_sheet.blit_rect(room_frames[side], Rect2i(0, 0, 1280, 720), Vector2i((index % 2) * 1280, (index / 2) * 720))
	var full_sheet_path := OUTPUT.path_join("actual-gamemain-contact-sheet-native.png")
	check(full_sheet.save_png(full_sheet_path) == OK, "Saved four unscaled native 1280x720 GameMain panels")
	captures.append(full_sheet_path)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "Capture leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Capture leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == catalogue_before, "Capture leaves shared art catalogue byte-exact")
	var manifest := {
		"status": "shadow_cleanup_candidate_not_runtime_registered",
		"scene": "actual GameMain and production TownRoom architecture/navigation with one owner-scoped passive visitor_chair",
		"renderer": DisplayServer.get_name(),
		"viewport_per_panel": [1280, 720],
		"actor_probe": "Existing Mina only: ordinary standing source and her accepted directional seated source at one candidate-declared physical contact socket; no actor art, hire, role, behavior, workstation, or seating capability is added.",
		"worker_disabled": true,
		"save_access": false,
		"runtime_registered": false,
		"dev_catalogue_registered": true,
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"shared_art_catalogue_mutated": false,
		"common_safe_pivot": [common_pivot.x, common_pivot.y],
		"wall_and_corner": wall_results,
		"observations": observations,
		"captures": captures,
		"limitations": [
			"Contact metadata proves only placement, scale, directional gaze, physical reservation, and visual depth; production seating behavior is absent.",
			"Mina's accepted workstation pose is reused only in this disposable capture and remains character-owned, not chair-owned.",
			"Production approval, runtime registration, and seated lifecycle review remain separate work.",
		],
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
	print("Visitor chair actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
