extends SceneTree
## DEV ONLY. Exercises the dormant collaboration-cluster-v2 profile inside an
## actual GameMain/TownRoom instance. The candidate profile is installed only
## on a disposable in-memory OfficeLayout; production JSON and saves are never
## written or read by this fixture.

const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const OUTPUT := "res://tests/output/collaboration-cluster-v2-actual-room"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const CANDIDATE_ART_ROOT := "res://assets/runtime/office/collaboration-cluster-v2"
const PREFERRED_PIVOT := Vector2i(10, 14)
const ACTOR_IDS: Array[String] = ["mira", "theo"]
const MAX_ROUTE_FRAMES := 900

var main: GameMain
var model: OfficeLayout
var pivot_cell := PREFERRED_PIVOT
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Dictionary = {}
var full_frames: Dictionary[String, Image] = {}
var occupied_details: Dictionary[String, Image] = {}
var empty_details: Dictionary[String, Image] = {}
var catalog_hash_before := ""
var layout_hash_before := ""

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

func point_values(point: Vector2) -> Array[float]:
	return [point.x, point.y]

func cell_values(cell: Vector2i) -> Array[int]:
	return [cell.x, cell.y]

func rect_values(rectangle: Rect2) -> Array[float]:
	return [rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y]

func make_candidate_model() -> OfficeLayout:
	var room_data: Dictionary = main.room.layout_model.data.duplicate(true)
	var catalog: Dictionary = main.room.layout_model.catalog.duplicate(true)
	var cluster: Dictionary = (catalog.get("collaboration_cluster", {}) as Dictionary).duplicate(true)
	var profiles: Dictionary = {}
	for side: String in GEOMETRY.SIDES:
		profiles[side] = GEOMETRY.production_profile(side, CANDIDATE_ART_ROOT)
	cluster["facings"] = GEOMETRY.SIDES.duplicate()
	cluster["facing_profiles"] = profiles
	catalog["collaboration_cluster"] = cluster
	var candidate := OfficeLayout.new()
	candidate.configure(room_data, catalog)
	return candidate

func choose_common_pivot(candidate: OfficeLayout) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y: int in range(3, candidate.height - 3):
		for x: int in range(3, candidate.width - 3):
			var point := Vector2i(x, y)
			var valid := true
			for stage: int in range(1, 5):
				for side: String in GEOMETRY.SIDES:
					if not bool(candidate.validate_candidate("collaboration-cluster", point, side, stage).valid):
						valid = false
						break
				if not valid:
					break
			if valid:
				candidates.append(point)
	candidates.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		var left_distance := absi(left.x - PREFERRED_PIVOT.x) + absi(left.y - PREFERRED_PIVOT.y)
		var right_distance := absi(right.x - PREFERRED_PIVOT.x) + absi(right.y - PREFERRED_PIVOT.y)
		if left_distance != right_distance:
			return left_distance < right_distance
		return left.y < right.y if left.y != right.y else left.x < right.x
	)
	check(not candidates.is_empty(), "A common production-room pivot validates for all four candidate facings at every unlock stage")
	return candidates[0] if not candidates.is_empty() else PREFERRED_PIVOT

func install_candidate_model() -> void:
	model = make_candidate_model()
	check(model.available_facings("collaboration_cluster") == GEOMETRY.SIDES, "Disposable model admits exactly four reviewed collaboration profiles")
	for side: String in GEOMETRY.SIDES:
		var resolution := model.resolve_profile("collaboration_cluster", side)
		check((resolution.errors as Array).is_empty(), side + " candidate profile resolves without definition errors: " + str(resolution.errors))
		check(str((resolution.profile as Dictionary).get("asset_revision", "")) == "collaboration-cluster-v2", side + " resolves the dormant v2 asset revision")
	pivot_cell = choose_common_pivot(model)
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.tile_size = model.tile_size
	main.room.grid_width = model.width
	main.room.grid_height = model.height
	main.room.player_spawn = OfficeLayout.vector(model.data.get("player_spawn", [17, 19]))
	main.room.architecture.configure(model)
	main.room.navigation.configure(model.navigation_data(), main.room.global_position)

func collision_shapes(prop: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if prop is CollisionShape2D:
		result.append(prop as CollisionShape2D)
	for child: Node in prop.get_children():
		result.append_array(collision_shapes(child))
	return result

func collision_signature(prop: Node2D) -> Array[String]:
	var result: Array[String] = []
	for collision: CollisionShape2D in collision_shapes(prop):
		var rectangle := collision.shape as RectangleShape2D
		var size := rectangle.size if rectangle != null else Vector2.ZERO
		var world_position := prop.global_position + collision.position
		result.append("%.1f,%.1f:%.1f,%.1f" % [world_position.x, world_position.y, size.x, size.y])
	result.sort()
	return result

func reset_actor_positions() -> Dictionary[String, Vector2]:
	var navigation := main.room.navigation
	navigation.actors.clear()
	navigation.reservations.clear()
	main.player.set_physics_process(false)
	main.player.cancel_route()
	main.player.hide()
	main.player.position = navigation.safe_position(main.room.grid_to_world_position(main.room.player_spawn), "founder")
	navigation.actors["founder"] = main.player.position
	var starts: Dictionary[String, Vector2] = {}
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		actor.show()
		actor.set_physics_process(true)
		actor.world_paused = false
		actor.labels_suppressed = true
		actor._label_layer.hide()
		actor._effect_sprite.hide()
		actor.has_live_job = false
		actor.schedule_phase = "work"
		actor.work_state = EmployeeAvatar.WorkState.IDLE
		actor._has_target = false
		actor._waiting_for_desk = false
		actor._route_requires_desk = false
		actor._route.clear()
		actor._speech_visible = false
		actor._activity = &""
		actor.position = navigation.safe_position(main.room.employee_spawn_position(actor_id), actor_id)
		navigation.actors[actor_id] = actor.position
		navigation.reservations[actor_id] = navigation.cell_at(actor.position)
		actor._update_character_frame()
		starts[actor_id] = actor.position
	return starts

func check_profile_and_collision(side: String, placement: Dictionary, prop: Node2D) -> Array[String]:
	check(str(placement.get("profile_kind", "")) == "collaboration", side + " actual prop resolves as a collaboration profile")
	check(str(placement.profile.get("asset_revision", "")) == "collaboration-cluster-v2", side + " actual prop uses v2 rather than production v1 art")
	check(str(placement.profile.get("reference_gaze", "")) == side, side + " reference gaze identifies its authored screen-axis view")
	check((placement.get("collaboration_slots", []) as Array).size() == 4, side + " retains four distinct service/seat sockets")
	var layer_names: Array[String] = []
	for layer: Dictionary in placement.render_layers:
		var name := str(layer.name)
		layer_names.append(name)
		check(str(layer.art).begins_with(CANDIDATE_ART_ROOT + "/" + side + "-"), side + " owns native direction-specific art for " + name)
		check(not layer.has("rotation") and not layer.has("scale") and not layer.has("flip_h") and not layer.has("flip_v"), side + " " + name + " does not transform a finished bitmap")
		var sprite := prop.get_node_or_null(NodePath(name)) as Sprite2D
		check(sprite != null and sprite.texture != null and sprite.texture.get_size() == Vector2(GEOMETRY.CANVAS), side + " " + name + " loads the full native candidate canvas")
		if sprite != null:
			check(sprite.position == Vector2(0, -40) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + name + " has an integer 1x unmirrored transform")
			check(sprite.z_index == prop.z_index + int(layer.z_offset), side + " " + name + " uses its authored screen depth")
	check(layer_names.size() == GEOMETRY.cluster_specs(side, CANDIDATE_ART_ROOT).size(), side + " actual prop reconstructs every candidate component layer")
	var signature := collision_signature(prop)
	check(signature.size() == 10, side + " actual prop has one 32px collision cell for each of ten occupied cells")
	var collision_cells: Array[Vector2i] = []
	for collision: CollisionShape2D in collision_shapes(prop):
		var rectangle := collision.shape as RectangleShape2D
		check(rectangle != null and rectangle.size == Vector2(32, 32), side + " collision remains the native cell size")
		var cell := main.room.navigation.cell_at(prop.global_position + collision.position)
		if not collision_cells.has(cell):
			collision_cells.append(cell)
	for cell: Vector2i in placement.occupied:
		check(collision_cells.has(cell) and not main.room.navigation.walkable(cell), side + " collision/navigation agree at occupied " + str(cell))
	return signature

func preflight_routes(side: String, starts: Dictionary[String, Vector2], targets: Dictionary[String, Vector2]) -> Dictionary:
	var result: Dictionary = {}
	var navigation := main.room.navigation
	for actor_id: String in ACTOR_IDS:
		var route := navigation.path(starts[actor_id], targets[actor_id], actor_id)
		var target_cell := navigation.cell_at(targets[actor_id])
		check(not route.is_empty(), side + " " + actor_id + " has a real navigation route to its seat")
		check(not route.is_empty() and route[-1] == targets[actor_id], side + " " + actor_id + " route terminates at the exact authored socket")
		check(navigation.reservations.get(actor_id, Vector2i(-1, -1)) == target_cell, side + " " + actor_id + " route reserves its authored socket")
		var route_safe := true
		for point: Vector2 in route:
			if not navigation._footprint_clear(point):
				route_safe = false
				break
		check(route_safe, side + " " + actor_id + " route keeps the 20px actor footprint outside furniture and walls")
		result[actor_id] = {"waypoints": route.size(), "target_cell": cell_values(target_cell)}
		navigation.release(actor_id)
	return result

func route_pair(side: String, targets: Dictionary[String, Vector2]) -> Dictionary:
	var navigation := main.room.navigation
	for actor_id: String in ACTOR_IDS:
		navigation.release(actor_id)
	for actor_id: String in ACTOR_IDS:
		main.get_employee(actor_id).set_schedule_phase("lunch")
	var initial_reservations: Dictionary = {}
	for actor_id: String in ACTOR_IDS:
		initial_reservations[actor_id] = cell_values(navigation.reservations.get(actor_id, Vector2i(-1, -1)))
		check(navigation.reservations.get(actor_id, Vector2i(-1, -1)) == navigation.cell_at(targets[actor_id]), side + " " + actor_id + " holds its distinct destination reservation during travel")
	check(navigation.reservations.get("mira") != navigation.reservations.get("theo"), side + " Mina and Theo never share a destination reservation")
	var min_distance := INF
	var unsafe_samples := 0
	var reservation_conflicts := 0
	var frames_used := 0
	while frames_used < MAX_ROUTE_FRAMES:
		await physics_frame
		frames_used += 1
		var mina := main.get_employee("mira")
		var theo := main.get_employee("theo")
		min_distance = minf(min_distance, mina.position.distance_to(theo.position))
		for actor_id: String in ACTOR_IDS:
			var actor := main.get_employee(actor_id)
			if not navigation.position_is_safe(actor.position, actor_id):
				unsafe_samples += 1
			if navigation.actors.get(actor_id, Vector2(INF, INF)).distance_to(actor.position) > 0.01:
				unsafe_samples += 1
		if navigation.reservations.get("mira") == navigation.reservations.get("theo"):
			reservation_conflicts += 1
		var arrived := true
		for actor_id: String in ACTOR_IDS:
			var actor := main.get_employee(actor_id)
			if actor._has_target or actor.position.distance_to(targets[actor_id]) > 0.5:
				arrived = false
		if arrived:
			break
	check(frames_used < MAX_ROUTE_FRAMES, side + " both actors reach their collaboration sockets within the bounded route window")
	check(unsafe_samples == 0, side + " concurrent movement has no wall/furniture/actor footprint violations")
	check(reservation_conflicts == 0, side + " concurrent movement has no reservation collisions")
	check(min_distance >= 20.0, side + " navigation separation keeps Mina and Theo at least 20px apart (minimum %.2f)" % min_distance)
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		check(not actor._has_target and actor.position == targets[actor_id], side + " " + actor_id + " arrives exactly on its logical seat center")
		check(navigation.reservations.get(actor_id, Vector2i(-1, -1)) == navigation.cell_at(targets[actor_id]), side + " " + actor_id + " retains its seat reservation after arrival")
	return {"physics_frames": frames_used, "minimum_actor_distance": min_distance, "unsafe_samples": unsafe_samples, "reservation_conflicts": reservation_conflicts, "initial_destination_reservations": initial_reservations}

func chair_for_slot(side: String, local_cell: Vector2i) -> Dictionary:
	for chair: Dictionary in GEOMETRY.profile(side).chairs:
		if OfficeLayout.vector(chair.cell) == local_cell:
			return chair
	return {}

func check_actor_presentation(side: String, actor_id: String, placement: Dictionary, prop: Node2D, slot: Dictionary) -> Dictionary:
	var actor := main.get_employee(actor_id)
	var visual: Dictionary = main.room.collaboration_visual(actor_id)
	var local_cell := (slot.cell as Vector2i) - (placement.grid as Vector2i)
	var chair := chair_for_slot(side, local_cell)
	check(not visual.is_empty() and actor._collaboration_visual == visual, side + " " + actor_id + " receives exact TownRoom collaboration metadata")
	check(actor.schedule_phase == "lunch" and actor.work_state == EmployeeAvatar.WorkState.LUNCH and actor._uses_collaboration_visual(), side + " " + actor_id + " uses the stationary collaboration presentation only at lunch")
	check(str(visual.work_facing) == str(slot.work_facing), side + " " + actor_id + " gaze matches its authored inward-facing seat")
	var capability := CharacterArt.reviewed_collaboration_capability(str(visual.pose_set), str(visual.work_facing), str(visual.collaboration_capability_revision))
	check(not capability.is_empty() and (capability.employees as Array).has(actor_id), side + " " + actor_id + " uses the exact code-owned v2 directional capability")
	var authored := CharacterArt.work_pose_frame(actor_id, str(visual.pose_set), str(visual.work_facing), "seated", 0)
	check(not authored.is_empty() and (authored.get("layers", []) as Array).size() == 2, side + " " + actor_id + " uses a native split seated source, not locomotion fallback")
	check(actor._active_work_pose_layers.size() == 2 and not actor._character_sprite.visible, side + " " + actor_id + " renders the authored lower/upper body layers")
	check(actor.render_position() == (actor.position + Vector2(visual.seat_anchor)).round(), side + " " + actor_id + " visual anchor is integer and separate from its reserved feet")
	var anchor_y := roundi(Vector2(visual.prop_anchor).y)
	var lower_z := anchor_y + int(visual.seat_layer_z_offsets.lower)
	var upper_z := anchor_y + int(visual.seat_layer_z_offsets.upper)
	var shadow_z := anchor_y + int(visual.ground_shadow_z_offset)
	check(actor.z_index == anchor_y + int(visual.seat_z_offset), side + " " + actor_id + " root depth is tied to the collaboration prop anchor")
	check(actor._shadow_sprite.z_index == shadow_z and shadow_z < lower_z and lower_z < upper_z, side + " " + actor_id + " shadow/lower/upper ordering is strict")
	for part_name: String in ["lower", "upper"]:
		var layer := actor._work_pose_layer_sprites.get(part_name) as Sprite2D
		var expected_z := lower_z if part_name == "lower" else upper_z
		check(layer != null and layer.visible and layer.z_index == expected_z, side + " " + actor_id + " " + part_name + " body layer occupies its authored depth")
	check(not chair.is_empty(), side + " " + actor_id + " socket maps to a physical chair component")
	if not chair.is_empty():
		var chair_sources: Array = GEOMETRY.CHAIR_PATHS.get(str(chair.facing), [])
		var chair_front_depth := int(chair.z_offset) + maxi(0, chair_sources.size() - 1) * 2
		check(chair_front_depth < int(visual.seat_layer_z_offsets.lower), side + " " + actor_id + " chair stays behind the seated lower body")
		if int(visual.seat_z_offset) < 0 and GEOMETRY.profile(side).axis == "horizontal":
			check(int(visual.seat_layer_z_offsets.upper) < 0, side + " " + actor_id + " far horizontal body remains behind the table surface")
		elif int(visual.seat_z_offset) < 0:
			check(int(visual.seat_layer_z_offsets.lower) < 0 and int(visual.seat_layer_z_offsets.upper) > 0 and int(visual.seat_layer_z_offsets.upper) < 3, side + " " + actor_id + " far side-facing body splits across the top and stays behind its front edge")
		else:
			check(int(visual.seat_layer_z_offsets.lower) > 3, side + " " + actor_id + " near-seat body remains in front of the table apron")
	var body_rect := Rect2(actor.render_position() + Vector2(-24, -72), Vector2(48, 80))
	return {"slot_cell": cell_values(slot.cell), "logical_position": point_values(actor.position), "render_position": point_values(actor.render_position()), "work_facing": str(visual.work_facing), "capability_revision": str(visual.collaboration_capability_revision), "seat_anchor": point_values(visual.seat_anchor), "depths": {"shadow": shadow_z - prop.z_index, "lower": lower_z - prop.z_index, "upper": upper_z - prop.z_index}, "body_rect": rect_values(body_rect)}

func image_difference(left: Image, right: Image) -> int:
	var result := 0
	for y: int in range(left.get_height()):
		for x: int in range(left.get_width()):
			if left.get_pixel(x, y) != right.get_pixel(x, y):
				result += 1
	return result

func changed_mask(image: Image, background: Image) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(image.get_width() * image.get_height())
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			result[y * image.get_width() + x] = 1 if image.get_pixel(x, y) != background.get_pixel(x, y) else 0
	return result

func mask_overlap(left: PackedByteArray, right: PackedByteArray) -> int:
	var result := 0
	for index: int in range(left.size()):
		if left[index] != 0 and right[index] != 0:
			result += 1
	return result

func mask_table_contact(mask: PackedByteArray, table: Image) -> int:
	var result := 0
	for y: int in range(table.get_height()):
		for x: int in range(table.get_width()):
			if mask[y * table.get_width() + x] != 0 and table.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func viewport_image() -> Image:
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain viewport stays native 1280x720")
	return image

func save_image(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)

func capture_side(side: String, placement: Dictionary) -> Dictionary:
	await frames(3)
	var crop := Rect2i(Vector2i(main.room.global_position + Vector2(placement.anchor)) - GEOMETRY.PIVOT, GEOMETRY.CANVAS)
	var full := await viewport_image()
	var room_path := OUTPUT.path_join("room-" + side + ".png")
	save_image(full, room_path)
	full_frames[side] = full
	var both := full.get_region(crop)
	check(both.get_size() == GEOMETRY.CANVAS, side + " exact candidate canvas fits the native viewport")
	var both_path := OUTPUT.path_join("detail-" + side + "-native.png")
	save_image(both, both_path)
	occupied_details[side] = both
	main.get_employee("theo").hide()
	await frames(2)
	var mina_only := (await viewport_image()).get_region(crop)
	main.get_employee("mira").hide()
	main.get_employee("theo").show()
	await frames(2)
	var theo_only := (await viewport_image()).get_region(crop)
	main.get_employee("theo").hide()
	await frames(2)
	var empty := (await viewport_image()).get_region(crop)
	empty_details[side] = empty
	main.get_employee("mira").show()
	main.get_employee("theo").show()
	await frames(2)
	save_image(mina_only, OUTPUT.path_join("detail-" + side + "-mina-native.png"))
	save_image(theo_only, OUTPUT.path_join("detail-" + side + "-theo-native.png"))
	save_image(empty, OUTPUT.path_join("detail-" + side + "-empty-native.png"))
	var mina_mask := changed_mask(mina_only, empty)
	var theo_mask := changed_mask(theo_only, empty)
	var actor_overlap := mask_overlap(mina_mask, theo_mask)
	var table := GEOMETRY.cluster_whole(side)
	var mina_contact := mask_table_contact(mina_mask, table)
	var theo_contact := mask_table_contact(theo_mask, table)
	var pair_delta := image_difference(both, empty)
	check(image_difference(mina_only, empty) > 0 and image_difference(theo_only, empty) > 0, side + " both seated actors contribute visible actual-room pixels")
	check(actor_overlap == 0, side + " Mina and Theo have no overlapping rendered actor pixels")
	check(mina_contact > 0 and theo_contact > 0, side + " both actors visibly contact/occlude their authored chair/table assembly")
	check(pair_delta > 0, side + " occupied and empty actual-room evidence differ")
	return {"actor_pixel_overlap": actor_overlap, "mina_furniture_contact_pixels": mina_contact, "theo_furniture_contact_pixels": theo_contact, "pair_pixel_delta": pair_delta, "crop": [crop.position.x, crop.position.y, crop.size.x, crop.size.y]}

func run_side(side: String) -> void:
	check(main.room.set_placement_overrides({"collaboration-cluster": {"grid": cell_values(pivot_cell), "facing": side}}), side + " v2 candidate commits to the disposable actual-room model")
	await frames(3)
	var placement := main.room.placement_by_id("collaboration-cluster")
	var prop := main.room.prop_node("collaboration-cluster")
	check(not placement.is_empty() and prop != null and placement.facing == side, side + " actual GameMain rebuilds the intended candidate facing")
	if placement.is_empty() or prop == null:
		return
	var collision_before := check_profile_and_collision(side, placement, prop)
	var starts := reset_actor_positions()
	var targets: Dictionary[String, Vector2] = {}
	var slots: Dictionary[String, Dictionary] = {}
	for index: int in range(ACTOR_IDS.size()):
		var actor_id := ACTOR_IDS[index]
		var slot: Dictionary = placement.collaboration_slots[index]
		slots[actor_id] = slot
		targets[actor_id] = main.room.lunch_position(actor_id)
		check(targets[actor_id] == main.room.grid_to_world_position(slot.cell), side + " " + actor_id + " lunch lookup resolves its deterministic socket")
		check(main.room.navigation.walkable(slot.cell) and not (placement.occupied as Array).has(slot.cell), side + " " + actor_id + " seat is clear, walkable, and outside collision")
	check((slots.mira as Dictionary).cell != (slots.theo as Dictionary).cell, side + " Mina and Theo use distinct collaboration sockets")
	var preflight := preflight_routes(side, starts, targets)
	var route := await route_pair(side, targets)
	var actors: Dictionary = {}
	for actor_id: String in ACTOR_IDS:
		actors[actor_id] = check_actor_presentation(side, actor_id, placement, prop, slots[actor_id])
	var mina_rect := Rect2((actors.mira as Dictionary).body_rect[0], (actors.mira as Dictionary).body_rect[1], (actors.mira as Dictionary).body_rect[2], (actors.mira as Dictionary).body_rect[3])
	var theo_rect := Rect2((actors.theo as Dictionary).body_rect[0], (actors.theo as Dictionary).body_rect[1], (actors.theo as Dictionary).body_rect[2], (actors.theo as Dictionary).body_rect[3])
	check(not mina_rect.intersects(theo_rect), side + " native 48x80 seated envelopes do not overlap")
	check(collision_signature(prop) == collision_before, side + " actor routing and seating leave prop collision byte-for-byte stable")
	var pixel_evidence: Dictionary = {}
	if DisplayServer.get_name() != "headless":
		pixel_evidence = await capture_side(side, placement)
	observations[side] = {"pivot_cell": cell_values(placement.grid), "anchor": point_values(placement.anchor), "occupied_cells": (placement.occupied as Array).size(), "collision_signature": collision_before, "preflight_routes": preflight, "concurrent_route": route, "actors": actors, "pixel_evidence": pixel_evidence}

func build_contact_sheets() -> void:
	if occupied_details.size() != GEOMETRY.SIDES.size():
		return
	var detail_sheet := Image.create(GEOMETRY.CANVAS.x * 2, GEOMETRY.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	var empty_sheet := Image.create(GEOMETRY.CANVAS.x * 2, GEOMETRY.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	var full_sheet := Image.create(1280 * 2, 720 * 2, false, Image.FORMAT_RGBA8)
	detail_sheet.fill(Color("151515"))
	empty_sheet.fill(Color("151515"))
	full_sheet.fill(Color("151515"))
	for index: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[index]
		var detail_origin := Vector2i(index % 2, index / 2) * GEOMETRY.CANVAS
		var full_origin := Vector2i(index % 2 * 1280, index / 2 * 720)
		detail_sheet.blit_rect(occupied_details[side], Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), detail_origin)
		empty_sheet.blit_rect(empty_details[side], Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), detail_origin)
		full_sheet.blit_rect(full_frames[side], Rect2i(Vector2i.ZERO, Vector2i(1280, 720)), full_origin)
	save_image(detail_sheet, OUTPUT.path_join("actual-room-contact-sheet-native.png"))
	save_image(empty_sheet, OUTPUT.path_join("actual-room-empty-contact-sheet-native.png"))
	var enlarged := detail_sheet.duplicate()
	enlarged.resize(detail_sheet.get_width() * 2, detail_sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	save_image(enlarged, OUTPUT.path_join("actual-room-contact-sheet-2x.png"))
	# Each quadrant remains an untouched native 1280x720 GameMain capture.
	save_image(full_sheet, OUTPUT.path_join("full-room-contact-sheet-native-panels.png"))

func save_report(renderer: String) -> void:
	var report_path := OUTPUT.path_join("headless-results.json" if renderer == "headless" else "actual-room-results.json")
	var report := {
		"status": "native_review_candidate_not_runtime_registered" if failures.is_empty() else "candidate_rejected",
		"scene": "actual GameMain and production TownRoom with collaboration-cluster-v2 injected only into a disposable in-memory OfficeLayout",
		"renderer": renderer,
		"worker_disabled": true,
		"save_access": false,
		"production_catalog_mutated": false,
		"default_layout_mutated": false,
		"production_collaboration_revision": "collaboration-table-v1",
		"candidate_revision": "collaboration-cluster-v2",
		"runtime_registered": false,
		"common_pivot": cell_values(pivot_cell),
		"native_viewport": [1280, 720],
		"candidate_canvas": [GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y],
		"candidate_pivot": [GEOMETRY.PIVOT.x, GEOMETRY.PIVOT.y],
		"facings": GEOMETRY.SIDES,
		"observations": observations,
		"captures": captures,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	check(file != null, "Opened deterministic collaboration-cluster-v2 result manifest")
	report.checks = checks
	report.failures = failures
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	catalog_hash_before = FileAccess.get_sha256(PRODUCTION_CATALOG)
	layout_hash_before = FileAccess.get_sha256(DEFAULT_LAYOUT)
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames(5)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.job_panel.close_drawer(false)
	main.founder_hud.dismiss_movement_hint()
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts with the worker disabled")
	for side: String in GEOMETRY.SIDES:
		var production := main.room.layout_model.resolve_profile("collaboration_cluster", side)
		check(str((production.profile as Dictionary).get("asset_revision", "")) == "collaboration-table-v1", side + " production truth remains collaboration-table-v1 before fixture injection")
	install_candidate_model()
	for side: String in GEOMETRY.SIDES:
		await run_side(side)
	if DisplayServer.get_name() != "headless":
		build_contact_sheets()
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_hash_before, "Fixture leaves production furniture_catalog.json byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_hash_before, "Fixture leaves default office_layout.json byte-exact")
	await save_report(DisplayServer.get_name())
	main.game_audio.shutdown()
	main.free()
	print("Collaboration cluster v2 actual GameMain: %d checks, %d failures (%s)" % [checks, failures.size(), DisplayServer.get_name()])
	quit(0 if failures.is_empty() else 1)
