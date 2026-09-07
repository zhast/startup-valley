extends "res://tools/capture_native_floor_study.gd"
## DEV ONLY. Exact raster geometry plus an additive disposable-room obstacle.
## No new furniture profile, canonical editor admission, service ID or UI action.
const BOARD := preload("res://tools/mobile_whiteboard_geometry.gd")
const OUT := "res://tests/output/mobile-whiteboard"
const EXPORT := "res://tests/fixtures/furniture-calibration/mobile-whiteboard-v1"
const HOST := Vector2i(784, 432)
var board: Node2D
var planning: Image
var planning_path := ""
var records: Array[Dictionary] = []
var exports: Array[Dictionary] = []
var render_images: Dictionary[String, Image] = {}
var walked_frames := 0
var painted_actor_pixels := 0
var environment_before := ""
var physics_before := 60

func _initialize() -> void:
	environment_before = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func layer_bounds(parts: Dictionary[String, Image]) -> Rect2i:
	return BOARD.reunite(parts).get_used_rect()

func inside_room(p: Dictionary, point: Vector2i, visitor := true) -> bool:
	var model := OfficeLayout.new()
	model.load_files()
	var regions: Array[Rect2i] = [p.conservative_visual_bounds]
	if visitor: regions.append(Rect2i(p.visitor_bounds.position + p.visitor_offset, p.visitor_bounds.size))
	for rect: Rect2i in regions:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				if not model.is_floor(model.cell_at(Vector2(point + Vector2i(x, y)))): return false
	return true

func preflight() -> void:
	for side: String in BOARD.SIDES:
		var p := BOARD.profile(side)
		var parts := BOARD.raster_layers(side)
		check(parts.size() == 7 and p.canvas == Vector2i(192, 224) and p.pivot == Vector2i(96, 160), "All seven layers retain one192×224 canvas and one floor pivot")
		check(p.board_rise == 80 and p.board_lower_rise == 24 and p.board_thickness == 4, "Physical dimensions remain facing-independent")
		check(p.direction_semantics == "visual_orientation" and p.interaction == "none" and not p.has("service_side"), "No fake service/seat capability")
		check(p.floor.size == (Vector2i(96, 32) if side in ["north", "south"] else Vector2i(32, 96)), "Caster floor envelope exchanges axes without rotating elevation")
		check(layer_bounds(parts) == Rect2i(p.conservative_visual_bounds.position + BOARD.PIVOT, p.conservative_visual_bounds.size), "Measured opaque union matches exact declared native geometry")
		for name_value: String in BOARD.LAYERS:
			var image: Image = parts[name_value]
			check(image.get_size() == BOARD.CANVAS, "No independently trimmed layer")
			var partial := 0
			var hidden_rgb := 0
			for y: int in range(BOARD.CANVAS.y):
				for x: int in range(BOARD.CANVAS.x):
					var color := image.get_pixel(x, y)
					if color.a > 0 and color.a < 1: partial += 1
					if color.a == 0 and color != Color(0, 0, 0, 0): hidden_rgb += 1
			check(partial == 0 and hidden_rgb == 0, "Binary native alpha and zero hidden padding: " + name_value)
			check(image.save_png(EXPORT.path_join(side + "-" + name_value.to_snake_case() + ".png")) == OK, "Write registered dev layer")
		var whole := BOARD.reunite(parts)
		check(whole.save_png(EXPORT.path_join(side + "-whole.png")) == OK, "Write source-reconstructed whole")
		var result := Image.create(192, 224, false, Image.FORMAT_RGBA8)
		for name_value: String in BOARD.LAYERS:
			var saved := Image.load_from_file(ProjectSettings.globalize_path(EXPORT.path_join(side + "-" + name_value.to_snake_case() + ".png")))
			result.blend_rect(saved, Rect2i(Vector2i.ZERO, BOARD.CANVAS), Vector2i.ZERO)
		check(result.get_data() == whole.get_data(), "Reopening/recombining all exported PNGs preserves every byte")
		var details := whole.duplicate() as Image
		details.resize(768, 896, Image.INTERPOLATE_NEAREST)
		check(details.save_png(EXPORT.path_join(side + "-whole-4x.png")) == OK, "Write nearest native export detail")
		exports.append({"orientation": side, "canvas": [192, 224], "pivot": [96, 160], "layer_names": BOARD.LAYERS, "opaque_bounds": str(whole.get_used_rect()), "runtime_approved": false})
		check(inside_room(p, HOST), "Central prototype and conservative visitor envelope fit real room")
		var first_y := 208 if side in ["north", "south"] else 240
		check(inside_room(p, Vector2i(112, first_y)), "Proposed upper-left inward placement fits native visitor headroom")
		check(not inside_room(p, Vector2i(112, first_y - 32)), "One row too close to the wall is rejected by real native height")
		check(not inside_room(p, Vector2i(16, first_y)), "Left-wall/corner overhang is rejected, not hidden by transparent padding")
		if side in ["east", "west"]:
			check(p.board == Rect2i(-2, -124, 4, 144) and p.content_socket.size == Vector2i.ZERO, "Genuinely thin edge; no squeezed wide notes panel")
			check(p.tray.position.x == (2 if side == "east" else -10), "Actual tray protrudes on the separately authored side")
			var edge: Image = parts.BoardFrame
			check(edge.get_pixelv(BOARD.PIVOT + Vector2i(-1, -123)) == BOARD.LIGHT, "Screen upper-left light does not mirror with direction")
		if side == "north":
			check(not parts.FarTray.is_invisible() and parts.NearTray.is_invisible(), "Far tray exists behind the back, not pasted in front")
			var without := parts.duplicate()
			without.FarTray = Image.create(192, 224, false, Image.FORMAT_RGBA8)
			check(BOARD.reunite(without).get_data() == whole.get_data(), "North tray is correctly fully hidden by the physical back panel")
	if planning != null:
		check(planning.get_size() == Vector2i(80, 48) and planning.detect_alpha() == Image.ALPHA_NONE, "Planning insert is a real opaque80×48 source; no source scaling")
		var blank := BOARD.raster_layers("south")
		var marked := BOARD.raster_layers("south", planning)
		check(not marked.is_empty(), "South accepts exact native planning insert")
		if not marked.is_empty():
			check(marked.FaceInsert.get_region(Rect2i(56, 86, 80, 48)).get_data() == planning.get_data(), "Insert fits exact protected socket without changing pixels")
			for name_value: String in BOARD.LAYERS:
				if name_value != "FaceInsert": check(marked[name_value].get_data() == blank[name_value].get_data(), "Planning changes only the content layer")
			check(BOARD.reunite(marked).save_png(EXPORT.path_join("south-planning-whole.png")) == OK, "Save optional planning assembly separately from blank")
		for side: String in ["north", "east", "west"]: check(BOARD.raster_layers(side, planning).is_empty(), "No false readable notes on hidden/edge camera faces")

func make_board_room(side: String) -> void:
	await make_main(2)
	board = BOARD.new()
	board.position = HOST
	board.z_as_relative = false
	board.z_index = HOST.y
	main.room.add_child(board)
	check(board.configure(side), "Build actual blank board without catalogue registration")
	var p: Dictionary = board.resolved
	var collision := StaticBody2D.new()
	collision.collision_layer = 2
	collision.collision_mask = 0
	collision.position = HOST
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = p.floor.size
	shape.shape = rectangle
	shape.position = Vector2(p.floor.get_center())
	collision.add_child(shape)
	main.room.add_child(collision)
	# Exercise existing navigation/physics, but do not pretend a new canonical
	# family/profile was accepted. Teardown removes this one additive obstacle.
	var navigation_placements := main.room.resolved_placements.duplicate(true)
	var occupied: Array[Vector2i] = []
	for offset: Vector2i in p.occupied: occupied.append(main.room.layout_model.cell_at(HOST) + offset)
	navigation_placements.append({"occupied": occupied})
	main.room.navigation.rebuild_placements(navigation_placements)
	for cell: Vector2i in occupied: check(not main.room.navigation.walkable(cell), "Real navigation excludes the actual caster-base cells")
	check(main.room.placement_by_id("mobile-whiteboard-study").is_empty(), "No fabricated canonical placement or archive service alias")
	for index: int in range(3):
		var actor := actor_for(["founder", "mira", "theo"][index])
		actor.position = [Vector2(688, 368), Vector2(688, 496), Vector2(784, 560)][index]
		main.room.navigation.actors[["founder", "mira", "theo"][index]] = actor.position
		if actor is EmployeeAvatar:
			actor._idle_cooldown = 1000
			actor.world_paused = false
			actor.labels_suppressed = true
			actor._update_character_frame()
		else:
			actor.input_blocked = false
			actor.face_direction(Vector2.RIGHT)
			actor._character_sprite.position = Vector2(0, -32)
			actor._shadow_sprite.position = Vector2(0, -2)
		actor.z_index = int(actor.position.y)
	await frames(3)

func actor_for(id: String) -> Node2D:
	return main.player if id == "founder" else main.get_employee(id)

func rendered_depth(image: Image, checkpoint: String) -> void:
	var whole: Image = BOARD.reunite(board.layer_images)
	var other_actors: Array[Dictionary] = []
	for other_id: String in ["founder", "mira", "theo"]:
		var other := actor_for(other_id)
		var other_sprite := other.get_node("CharacterSprite") as Sprite2D
		other_actors.append({"id": other_id, "depth": other.z_index, "origin": Vector2i(other_sprite.global_position - Vector2(24, 40)), "image": other_sprite.texture.get_image().get_region(Rect2i(other_sprite.region_rect))})
	for id: String in ["founder", "mira", "theo"]:
		var actor := actor_for(id)
		var sprite := actor.get_node("CharacterSprite") as Sprite2D
		var cell := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
		var origin := Vector2i(sprite.global_position - Vector2(24, 40))
		var checked := 0
		var hidden := 0
		var hidden_by_actor := 0
		var mismatches := 0
		for y: int in range(80):
			for x: int in range(48):
				var color := cell.get_pixel(x, y)
				if color.a < 0.99: continue
				var point := origin + Vector2i(x, y)
				var visible_depth := actor.z_index
				var board_point := point - HOST + BOARD.PIVOT
				if Rect2i(Vector2i.ZERO, BOARD.CANVAS).has_point(board_point):
					var covering := whole.get_pixelv(board_point)
					if covering.a > 0.99 and actor.z_index < board.z_index:
						color = covering
						visible_depth = board.z_index
						hidden += 1
				# Distinct physical feet can legitimately overlap in screen space:
				# another actor's nearer head may cover the current actor's shoes.
				# Model that real source/depth relationship rather than skipping it.
				var actor_cover := false
				for other: Dictionary in other_actors:
					if other.id == id or other.depth <= visible_depth: continue
					var other_point: Vector2i = point - other.origin
					if not Rect2i(0, 0, 48, 80).has_point(other_point): continue
					var other_pixel: Color = (other.image as Image).get_pixelv(other_point)
					if other_pixel.a < 0.99: continue
					color = other_pixel
					visible_depth = other.depth
					actor_cover = true
				if actor_cover: hidden_by_actor += 1
				if color_delta(image.get_pixelv(point), color) > 0.015: mismatches += 1
				checked += 1
		check(checked > 0 and mismatches == 0, "Actual native actor/board depth matches floor ordering: " + id)
		painted_actor_pixels += checked
		records.append({"checkpoint": checkpoint, "orientation": board.resolved.orientation, "actor": id, "feet": str(actor.position), "source_region": str(sprite.region_rect), "opaque_pixels_checked": checked, "hidden_by_board": hidden, "hidden_by_actor": hidden_by_actor, "mismatches": mismatches})

func capture_board(name_value: String, details := false) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(2)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	check(shot.get_size() == VIEWPORT, "Actual disposable room stays native1280×720")
	rendered_depth(shot, name_value)
	check(shot.save_png(OUT.path_join(name_value + ".png")) == OK, "Save actual native room " + name_value)
	render_images[name_value] = shot
	if details:
		var crop := shot.get_region(Rect2i(HOST - Vector2i(96, 144), Vector2i(192, 224)))
		check(crop.save_png(OUT.path_join(name_value + "-native.png")) == OK, "Save exact native board vicinity")
		crop.resize(768, 896, Image.INTERPOLATE_NEAREST)
		check(crop.save_png(OUT.path_join(name_value + "-4x.png")) == OK, "Save nearest board detail")

func move_actor(id: String, target: Vector2, side: String) -> void:
	var actor := actor_for(id)
	if id == "founder":
		var hover := InputEventMouseMotion.new()
		hover.position = target
		hover.global_position = target
		root.push_input(hover, true)
		for down: bool in [true, false]:
			var event := InputEventMouseButton.new()
			event.pressed = down
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = target
			event.global_position = target
			root.push_input(event, true)
		check(not main.player.route.is_empty(), "Founder real mouse input creates route around prototype")
		check(main._pending_interaction.is_empty(), "Ground-walk click does not accidentally target another existing office station")
	else:
		(actor as EmployeeAvatar).walk_to(target, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
		check(actor._has_target, "Employee existing path starts around prototype")
	var source_frames := {}
	for tick: int in range(240):
		actor._physics_process(1.0 / 30.0)
		main.click_feedback._process(1.0 / 30.0)
		walked_frames += 1
		check(main.room.navigation.position_is_safe(actor.position, id), "Every step stays outside board footprint and other actors")
		check(actor._character_sprite.global_position == actor._character_sprite.global_position.round(), "Moving body stays pixel-snapped")
		source_frames[str(actor._character_sprite.region_rect)] = true
		if DisplayServer.get_name() != "headless": await process_frame
		if tick in [10, 22, 30, 50] or (id == "founder" and tick == 17): await capture_board("%s-%s-walk-%03d" % [side, id, tick])
		var active: bool = not actor.route.is_empty() if actor is PlayerAvatar else actor._has_target
		if not active: break
	check(actor.position == target and source_frames.size() >= 3, "Live route reaches target with distinct native gait frames: %s/%s got%s target%s frames%d" % [side, id, actor.position, target, source_frames.size()])
	await capture_board(side + "-" + id + "-arrival", true)

func run() -> void:
	physics_before = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 30
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--planning="):
			planning_path = arg.split("=", true, 1)[1]
			planning = Image.load_from_file(ProjectSettings.globalize_path(planning_path))
			if planning != null: planning.convert(Image.FORMAT_RGBA8)
	for path: String in [OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH, DEFAULT_FLOOR, BOARD.POWDERCOAT]: source_hashes[path] = FileAccess.get_sha256(path)
	if not planning_path.is_empty(): source_hashes[planning_path] = FileAccess.get_sha256(planning_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT))
	preflight()
	if failures.is_empty():
		for side: String in BOARD.SIDES:
			await make_board_room(side)
			await capture_board(side + "-blank", true)
			await move_actor("founder", Vector2(848, 368), side)
			await move_actor("mira", Vector2(848, 496), side)
			await move_actor("theo", Vector2(784, 304), side)
			if side == "south" and planning != null:
				check(board.configure(side, planning, planning_path), "Attach candidate planning face without rewriting blank base")
				await capture_board("south-planning", true)
			main.free()
			await frames(2)
		await make_main(2)
		check(main.room.placement_by_id("mobile-whiteboard-study").is_empty() and main.room.navigation.walkable(main.room.layout_model.cell_at(HOST)), "Fresh ordinary scene has no prototype/admission/navigation leak")
		main.free()
		if DisplayServer.get_name() != "headless":
			for side: String in BOARD.SIDES:
				var actual_hidden_pixels := 0
				for record: Dictionary in records:
					if record.orientation == side: actual_hidden_pixels += record.hidden_by_board
				check(actual_hidden_pixels > 0, "Actual recorded crossing exercises opaque board/actor depth even for a4px edge: " + side)
			var contact := Image.create(768, 224, false, Image.FORMAT_RGBA8)
			for index: int in range(4):
				var crop := render_images[BOARD.SIDES[index] + "-blank"].get_region(Rect2i(HOST - Vector2i(96, 144), Vector2i(192, 224)))
				contact.blit_rect(crop, Rect2i(0, 0, 192, 224), Vector2i(index * 192, 0))
			check(contact.save_png(OUT.path_join("all-four-native.png")) == OK, "Save true native N/E/S/W actual-room comparison")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Preserve source/production data " + path)
	finish()

func finish() -> void:
	var result := {"checks": checks, "failures": failures, "exports": exports, "captures": render_images.keys(), "actor_depth_samples": records, "painted_actor_pixels": painted_actor_pixels, "physics_steps": walked_frames, "source_hashes": source_hashes, "planning_source": planning_path, "runtime_approved": false, "canonical_editor_admission": false, "worker_started": false, "production_changed": false, "limitations": ["Blank code-native visual orientation prototype, no service action or writing pose.", "The disposable fixture adds physical collision and passes its occupied cells to existing navigation; no new catalogue/profile/factory schema.", "The current canonical editor accepts only known registered families and service/workstation explicit profiles. This prototype is not an accepted selectable family.", "Planning insert only appears on South; North is structural rear and E/W are honest thin edges."]}
	var file := FileAccess.open(OUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	Engine.physics_ticks_per_second = physics_before
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", environment_before)
	print("Mobile whiteboard: %d checks, %d failures, %d actual actor pixel checks, %d physical steps" % [checks, failures.size(), painted_actor_pixels, walked_frames])
	quit(0 if failures.is_empty() else 1)
