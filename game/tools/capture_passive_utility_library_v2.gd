extends SceneTree
## DEV ONLY. Perspective-correct v2 GameMain/TownRoom collision, wall/corner, passive picking,
## actor approach, and depth proof for three unregistered library candidates.

const ART := preload("res://tools/passive_utility_library_v2_geometry.gd")
const OUTPUTS := {
	"tall_storage_cabinet": "res://tests/output/tall-storage-cabinet-v2",
	"server_cabinet": "res://tests/output/server-cabinet-v2",
	"recycling_sorter": "res://tests/output/recycling-sorter-v2",
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

func choose_common_pivot() -> Vector2i:
	var started_ms := Time.get_ticks_msec()
	print("Passive utility v2 pivot search start: " + family)
	var choices: Array[Vector2i] = []
	for y: int in range(3, model.height - 3):
		for x: int in range(3, model.width - 3):
			choices.append(Vector2i(x, y))
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance := a.distance_squared_to(Vector2i(12, 13))
		var b_distance := b.distance_squared_to(Vector2i(12, 13))
		if a_distance != b_distance: return a_distance < b_distance
		if a.y != b.y: return a.y < b.y
		return a.x < b.x
	)
	var validation_count := 0
	for point: Vector2i in choices:
		validation_count += 1
		var valid := true
		for side: String in ART.SIDES:
			if not model.validate_candidate(candidate_id, point, side, 0).valid:
				valid = false
				break
		if valid:
			check(true, family + " has one actual TownRoom pivot safe for all four profiles")
			print("Passive utility v2 pivot search complete: %s checked=%d elapsed_ms=%d" % [family, validation_count, Time.get_ticks_msec() - started_ms])
			return point
	check(false, family + " has one actual TownRoom pivot safe for all four profiles")
	print("Passive utility v2 pivot search failed: %s checked=%d elapsed_ms=%d" % [family, validation_count, Time.get_ticks_msec() - started_ms])
	return Vector2i(12, 13)

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

func visible_point_for(layer_name: String, sprites: Dictionary) -> Vector2:
	var sprite := sprites[layer_name] as Sprite2D
	var image := (sprite.texture as Texture2D).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0: continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5) - Vector2(ART.canvas(family)) / 2.0)
			var all: Array[Sprite2D] = []
			for name_value: String in ART.LAYERS: all.append(sprites[name_value] as Sprite2D)
			if VisibleSurface.top(all, point) == sprite: return point
	return Vector2(INF, INF)

func inspect_native_prop(side: String) -> Dictionary:
	var room: TownRoom = main.room
	var placement := room.placement_by_id(candidate_id)
	var prop := room.prop_node(candidate_id)
	check(prop != null and prop.get_script() == null, family + "/" + side + " uses TownRoom's neutral native-layer carrier")
	if prop == null: return {}
	check(placement.facing == side and placement.profile_kind == "decorative", family + "/" + side + " resolves only as a passive calibration candidate")
	check(not placement.has("interaction") and not room.interaction_world_position(candidate_id).is_finite(), family + "/" + side + " creates no production interaction target")
	check(placement.occupied.size() == 2 and placement.clearance.size() == 1, family + "/" + side + " carries the exact two-cell footprint and one planning clearance cell")
	var shapes := collision_shapes(prop)
	check(shapes.size() == 2, family + "/" + side + " builds exactly two real per-cell collision shapes")
	var found_centers: Array[Vector2i] = []
	for shape: CollisionShape2D in shapes:
		check(shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(32, 32), family + "/" + side + " collision cell is an exact 32px square")
		found_centers.append(Vector2i(shape.global_position.round()))
	for cell: Vector2i in placement.occupied:
		var center := Vector2i((room.global_position + model.world(cell)).round())
		check(found_centers.has(center), family + "/" + side + " collision center matches " + str(cell))
		check(not room.navigation.walkable(cell), family + "/" + side + " occupied cell is blocked in actual AStar navigation")
	var sprites := {}
	for layer_name: String in ART.LAYERS:
		var descriptor := ART.descriptor(family, side, layer_name)
		var sprite := prop.get_node(str(descriptor.name)) as Sprite2D
		sprites[layer_name] = sprite
		check(sprite != null and sprite.texture.get_size() == Vector2(ART.canvas(family)), family + "/" + side + "/" + layer_name + " loads the full native texture")
		check(sprite.position == Vector2(ART.sprite_offset(family)) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, family + "/" + side + "/" + layer_name + " keeps exact native registration")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), family + "/" + side + "/" + layer_name + " keeps authored host-relative depth")
	for layer_name: String in ART.LAYERS:
		var point := visible_point_for(layer_name, sprites)
		check(point.is_finite(), family + "/" + side + "/" + layer_name + " owns a visible final surface pixel")
		if point.is_finite():
			var hit := room.surface_at(point)
			check(hit.get("sprite") == sprites[layer_name], family + "/" + side + " alpha-aware picking selects " + layer_name)
			check((hit.get("interaction", {}) as Dictionary).is_empty() and main._interaction_at(point).is_empty(), family + "/" + side + " passive surface invents no action")
	return {"placement": placement, "prop": prop, "shape_count": shapes.size(), "sprites": sprites}

func approach_founder(side: String, placement: Dictionary, sprites: Dictionary) -> Dictionary:
	var p := ART.profile(family, side)
	var relative := OfficeLayout.vector(p.interaction)
	var destination_cell: Vector2i = placement.grid + relative
	var destination := model.world(destination_cell)
	check(placement.standing_viewpoints.size() == 1 and placement.standing_viewpoints[0].cell == destination_cell, family + "/" + side + " passive admission exposes only the planned geometry viewpoint")
	check(main.room.navigation.walkable(destination_cell) and destination_cell not in placement.occupied, family + "/" + side + " approach is outside collision and walkable")
	var start_cell := Vector2i(17, 18)
	main.player.cancel_route()
	main.player.position = model.world(start_cell)
	main.player.z_index = int(main.player.position.y)
	main.room.navigation.actors["founder"] = main.player.position
	check(main.player.move_to(destination), family + "/" + side + " founder receives an actual path to the passive approach")
	var route_points := main.player.route.size()
	var traveled := 0.0
	var safe := true
	for _tick: int in range(900):
		var before := main.player.position
		main.player._physics_process(1.0 / 30.0)
		traveled += before.distance_to(main.player.position)
		if not main.room.navigation.position_is_safe(main.player.position, "founder"): safe = false
		if main.player.route.is_empty(): break
	check(safe and main.player.route.is_empty() and main.player.position.distance_to(destination) < 0.1, family + "/" + side + " founder safely reaches the exact approach cell")
	main.player.z_index = int(main.player.position.y)
	main.player.face_direction(Vector2(OfficeLayout.vector(p.employee_look_vector)))
	var rear := sprites.rear_structure as Sprite2D
	var front := sprites.front_structure as Sprite2D
	var depth_class := ""
	if side == "north":
		check(main.player.z_index < rear.z_index, family + "/north approach actor is behind the rear structure")
		depth_class = "actor_behind_structure"
	elif side == "south":
		check(main.player.z_index > front.z_index, family + "/south approach actor is in front of the front structure")
		depth_class = "actor_in_front_of_structure"
	else:
		check(rear.z_index < main.player.z_index and main.player.z_index < front.z_index, family + "/" + side + " side approach actor is bracketed by rear/front layers")
		depth_class = "actor_between_rear_and_front_layers"
	return {
		"destination_cell": [destination_cell.x, destination_cell.y],
		"destination_px": [destination.x, destination.y],
		"employee_look_vector": p.employee_look_vector,
		"initial_route_points": route_points,
		"traveled_px": traveled,
		"actor_z": main.player.z_index,
		"rear_z": rear.z_index,
		"front_z": front.z_index,
		"depth_class": depth_class,
	}

func actor_prop_overlap(placement: Dictionary, prop: Node2D) -> Dictionary:
	var player: PlayerAvatar = main.player
	var bounds: Rect2 = placement.world_visual_bounds
	var overlap := 0
	var actor_in_front := 0
	var prop_in_front := 0
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body := player.body_surface_at(point)
			var surface := main.room.surface_at(point)
			var sprite := surface.get("sprite") as Sprite2D
			if body == null or sprite == null or sprite.get_parent() != prop: continue
			overlap += 1
			if VisibleSurface.in_front(body, sprite): actor_in_front += 1
			else: prop_in_front += 1
	return {"pixels": overlap, "actor_in_front_pixels": actor_in_front, "prop_in_front_pixels": prop_in_front}

func run_side(side: String, base_details: Dictionary[String, Image], approach_details: Dictionary[String, Image], observations: Dictionary, captures: Array[String]) -> void:
	check(main.room.set_placement_overrides({candidate_id: {"grid": [common_pivot.x, common_pivot.y], "facing": side}}), family + "/" + side + " commits at the common safe pivot")
	await frames(3)
	var inspected := inspect_native_prop(side)
	if inspected.is_empty(): return
	var placement: Dictionary = inspected.placement
	var prop: Node2D = inspected.prop
	var sprites: Dictionary = inspected.sprites
	main.player.hide()
	await frames(2)
	await RenderingServer.frame_post_draw
	var base_frame := root.get_texture().get_image()
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - ART.pivot(family), ART.canvas(family))
	var base_detail := base_frame.get_region(crop_rect)
	check(base_detail.get_size() == ART.canvas(family), family + "/" + side + " base crop uses the exact candidate canvas")
	var output := str(OUTPUTS[family])
	var base_path := output.path_join("detail-%s-base-native.png" % side)
	check(base_detail.save_png(base_path) == OK, "Saved " + base_path)
	captures.append(base_path)
	base_details[side] = base_detail
	main.player.show()
	var approach := approach_founder(side, placement, sprites)
	await frames(2)
	var room_frame := await capture_frame(output.path_join("room-%s.png" % side), captures)
	var approach_detail := room_frame.get_region(crop_rect)
	var approach_path := output.path_join("detail-%s-approach-native.png" % side)
	check(approach_detail.save_png(approach_path) == OK, "Saved " + approach_path)
	captures.append(approach_path)
	approach_details[side] = approach_detail
	var actor_delta := image_difference(base_detail, approach_detail)
	check(actor_delta > 0, family + "/" + side + " exact crop visibly contains the founder depth probe")
	observations[side] = {
		"grid": [common_pivot.x, common_pivot.y],
		"occupied": placement.occupied.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"clearance": placement.clearance.map(func(cell: Vector2i) -> Array: return [cell.x, cell.y]),
		"collision_shapes": inspected.shape_count,
		"founder_approach": approach,
		"actor_pixel_delta": actor_delta,
		"actor_prop_overlap_measured_not_acceptance_threshold": actor_prop_overlap(placement, prop),
		"render_layers": placement.render_layers,
	}

func configure_family(next_family: String) -> void:
	print("Passive utility v2 configure start: " + next_family)
	family = next_family
	candidate_id = family + "-candidate"
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
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, family + " actual GameMain starts no worker")
	var room_data := main.room.layout_model.data.duplicate(true)
	var catalogue := main.room.layout_model.catalog.duplicate(true)
	room_data.props = [{"id": candidate_id, "kind": family, "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	room_data.player_spawn = [17, 18]
	catalogue[family] = ART.catalog_entry(family)
	model = OfficeLayout.new()
	model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), family + " capture owns one isolated dev-only model")
	for side: String in ART.SIDES:
		check(model.authorize_calibration_decorative_profile(family, side, self), family + "/" + side + " receives owner-scoped passive admission")
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
	print("Passive utility v2 configure complete: " + family)

func close_family() -> void:
	print("Passive utility v2 close start: " + family)
	model.disable_calibration_preview(self)
	main.game_audio.shutdown()
	main.queue_free()
	await frames(3)
	main = null
	model = null
	print("Passive utility v2 close complete: " + family)

func run_family(next_family: String) -> void:
	print("Passive utility v2 family start: " + next_family)
	var start_checks := checks
	var start_failures := failures.size()
	await configure_family(next_family)
	var output := str(OUTPUTS[family])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	common_pivot = choose_common_pivot()
	print("Passive utility v2 pivot selected: %s %s" % [family, common_pivot])
	var wall_results := {}
	for side: String in ART.SIDES:
		var probe := find_corner_probe(side)
		check(not probe.is_empty(), family + "/" + side + " finds a real wall/corner rejection")
		if probe.is_empty(): continue
		check(int(probe.wall_neighbors) >= 2, family + "/" + side + " rejected probe is a production-room corner")
		var before := main.room.placement_by_id(candidate_id).duplicate(true)
		check(not main.room.set_placement_overrides({candidate_id: {"grid": [probe.grid.x, probe.grid.y], "facing": side}}), family + "/" + side + " TownRoom rejects the unsafe corner transaction")
		var after := main.room.placement_by_id(candidate_id)
		check(after.grid == before.grid and after.facing == before.facing, family + "/" + side + " rejected corner leaves the committed prop unchanged")
		wall_results[side] = {"grid": [probe.grid.x, probe.grid.y], "wall_neighbors": probe.wall_neighbors, "issue_codes": probe.codes}
	var base_details: Dictionary[String, Image] = {}
	var approach_details: Dictionary[String, Image] = {}
	var observations := {}
	var captures: Array[String] = []
	for side: String in ART.SIDES: await run_side(side, base_details, approach_details, observations, captures)
	print("Passive utility v2 sides complete: " + family)
	var size := ART.canvas(family)
	var base_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	var approach_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	base_sheet.fill(Color("151515"))
	approach_sheet.fill(Color("151515"))
	for index: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[index]
		base_sheet.blit_rect(base_details[side], Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
		approach_sheet.blit_rect(approach_details[side], Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
	var base_sheet_path := output.path_join("actual-room-base-contact-sheet-native.png")
	check(base_sheet.save_png(base_sheet_path) == OK, "Saved " + base_sheet_path)
	captures.append(base_sheet_path)
	var approach_sheet_path := output.path_join("actual-room-approach-contact-sheet-native.png")
	check(approach_sheet.save_png(approach_sheet_path) == OK, "Saved " + approach_sheet_path)
	captures.append(approach_sheet_path)
	var enlarged := approach_sheet.duplicate()
	enlarged.resize(approach_sheet.get_width() * 4, approach_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := output.path_join("actual-room-approach-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved " + enlarged_path)
	captures.append(enlarged_path)
	var family_failures: Array[String] = []
	for index: int in range(start_failures, failures.size()): family_failures.append(failures[index])
	var result := {
		"status": "perspective_corrected_v2_candidate_without_runtime_binding",
		"family": family,
		"scene": "actual GameMain and production TownRoom architecture/navigation with one owner-scoped passive candidate definition",
		"renderer": DisplayServer.get_name(),
		"viewport": [1280, 720],
		"worker_disabled": true,
		"save_access": false,
		"runtime_registered": false,
		"dev_catalogue_registration": "Not asserted. This capture only verifies that the shared catalogue stays byte-exact during its own run.",
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"shared_art_catalogue_mutated": false,
		"service_backend_or_interaction_created": false,
		"common_safe_pivot": [common_pivot.x, common_pivot.y],
		"wall_corner_rejections": wall_results,
		"observations": observations,
		"captures": captures,
		"actor_probe_limit": "Founder standing locomotion is only a scale, route, contact, and occlusion/depth probe; no service animation, transaction, backend, role, or interaction is claimed.",
		"checks": checks - start_checks,
		"failures": family_failures,
	}
	var file := FileAccess.open(output.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " actual-room result")
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	await close_family()
	print("Passive utility v2 family complete: " + next_family)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Passive utility v2 actual-room evidence requires the native renderer; run test_passive_utility_library.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_before := FileAccess.get_sha256(DEV_CATALOGUE)
	var requested_family := OS.get_environment("STARTUP_VALLEY_CAPTURE_FAMILY")
	var capture_families: Array[String] = []
	capture_families.assign(ART.FAMILIES)
	if not requested_family.is_empty():
		check(requested_family in ART.FAMILIES, "Optional diagnostic family selector names a v2 utility family")
		capture_families.clear()
		if requested_family in ART.FAMILIES: capture_families.append(requested_family)
	for next_family: String in capture_families: await run_family(next_family)
	var production_after := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_after := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_after := FileAccess.get_sha256(DEV_CATALOGUE)
	check(production_after == production_before, "Capture leaves production furniture catalogue byte-exact")
	check(layout_after == layout_before, "Capture leaves default office layout byte-exact")
	check(dev_after == dev_before, "Capture leaves shared art catalogue byte-exact")
	if not requested_family.is_empty():
		var invocation_path := "res://tests/output/passive-utility-library-v2/native-invocation-%s.json" % requested_family.replace("_", "-")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/output/passive-utility-library-v2"))
		var invocation_file := FileAccess.open(invocation_path, FileAccess.WRITE)
		check(invocation_file != null, "Opened isolated native invocation result for " + requested_family)
		if invocation_file != null:
			invocation_file.store_string(JSON.stringify({
				"status": "passed" if failures.is_empty() else "failed",
				"selected_family": requested_family,
				"renderer": DisplayServer.get_name(),
				"viewport": [1280, 720],
				"checks": checks,
				"failures": failures,
				"actual_room_results_path": str(OUTPUTS[requested_family]).trim_prefix("res://").path_join("actual-room-results.json"),
				"production_catalogue_sha256_before": production_before,
				"production_catalogue_sha256_after": production_after,
				"default_layout_sha256_before": layout_before,
				"default_layout_sha256_after": layout_after,
				"shared_art_catalogue_sha256_before": dev_before,
				"shared_art_catalogue_sha256_after": dev_after,
				"worker_disabled": true,
				"save_access": false,
				"runtime_registered": false,
				"service_backend_or_interaction_created": false,
			}, "\t") + "\n")
	print("Passive utility library v2 actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
