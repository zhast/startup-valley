extends "res://tools/capture_native_floor_study.gd"
## DEV ONLY. Actual-room geometry study, no canonical family/service activation.
const PEDESTAL := preload("res://tools/rolling_pedestal_geometry.gd")
const OUT := "res://tests/output/rolling-pedestal"
const EXPORT := "res://tests/fixtures/furniture-calibration/pedestal-v1"
const FRONT := EXPORT + "/drawer-front.png"
const HOST := Vector2i(784, 432)
var pedestal: Node2D
var front: Image
var evidence: Dictionary[String, Image] = {}
var depth_samples: Array[Dictionary] = []
var physical_steps := 0
var actor_pixel_checks := 0
var previous_environment := ""
var previous_physics := 60

func _initialize() -> void:
	previous_environment = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func within_architecture(p: Dictionary, pivot: Vector2i) -> bool:
	var model := OfficeLayout.new()
	model.load_files()
	var areas: Array[Rect2i] = [p.visual_bounds, Rect2i(p.approach_visual_bounds.position + p.service_cell * 32, p.approach_visual_bounds.size)]
	for rect: Rect2i in areas:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				if not model.is_floor(model.cell_at(Vector2(pivot + Vector2i(x, y)))): return false
	return true

func preflight() -> void:
	check(front != null and front.get_size() == Vector2i(24, 24) and front.detect_alpha() == Image.ALPHA_NONE, "Supplied front is exact opaque24×24, not a whole cabinet")
	if front == null: return
	front.convert(Image.FORMAT_RGBA8)
	for side: String in PEDESTAL.SIDES:
		var p := PEDESTAL.profile(side)
		var parts := PEDESTAL.raster_layers(side, front if side == "south" else null)
		check(parts.size() == 6 and p.canvas == Vector2i(96, 144) and p.pivot == Vector2i(48, 96), "Six registered layers at agreed common canvas/pivot")
		check(p.rise == 32 and p.underside_rise == 4 and p.occupied == [Vector2i.ZERO], "Side-storage height and one-cell occupancy; no under-desk promise")
		check(p.body_floor.size == (Vector2i(28, 24) if side in ["north", "south"] else Vector2i(24, 28)), "Physical body axes swap without rotating raster height")
		var broad := side in ["north", "south"]
		check(p.caster_mounts.size() == 4 and p.caster_mounts[0] == (Vector2i(-11, -13) if broad else Vector2i(-13, -11)), "All four caster mount coordinates exchange physical axes with body")
		check(p.clearance == [p.service_cell] and p.approach_visual_bounds == Rect2i(-24, -72, 48, 80), "Full unchanged standing envelope and separate clear visitor cell")
		check(p.approach_gaze == {"north": "south", "east": "west", "south": "north", "west": "east"}[side], "Approach gaze is opposite physical drawer service side")
		check(not p.has("work_facing") and not p.has("pose_set") and p.interaction == "none", "No invented seat, archive alias or drawer functionality")
		var whole := PEDESTAL.reunite(parts)
		check(whole.get_used_rect() == Rect2i(p.visual_bounds.position + PEDESTAL.PIVOT, p.visual_bounds.size), "Exact visible geometry independent of full padded canvas")
		var reloaded: Dictionary[String, Image] = {}
		for name_value: String in PEDESTAL.LAYERS:
			var image: Image = parts[name_value]
			var clean := true
			for y: int in range(144):
				for x: int in range(96):
					var color := image.get_pixel(x, y)
					if (color.a > 0 and color.a < 1) or (color.a == 0 and color != Color(0, 0, 0, 0)): clean = false
			check(clean and image.get_size() == PEDESTAL.CANVAS, "Binary alpha, zero padding and full native layer: " + name_value)
			var path := EXPORT.path_join(side + "-" + name_value.to_snake_case() + ".png")
			check(image.save_png(path) == OK, "Write source-registered dev layer")
			reloaded[name_value] = Image.load_from_file(ProjectSettings.globalize_path(path))
		check(PEDESTAL.reunite(reloaded).get_data() == whole.get_data(), "All exported layer PNGs reconstruct byte-exactly")
		check(whole.save_png(EXPORT.path_join(side + "-whole.png")) == OK, "Write exact whole-view export")
		var enlarged := whole.duplicate() as Image
		enlarged.resize(384, 576, Image.INTERPOLATE_NEAREST)
		check(enlarged.save_png(EXPORT.path_join(side + "-whole-4x.png")) == OK, "Write nearest native4× detail")
		check(within_architecture(p, HOST), "Central actual-room pedestal and visitor headroom fit")
		var first_y: int = {"north": 208, "east": 176, "south": 144, "west": 176}[side]
		check(within_architecture(p, Vector2i(112, first_y)), "Proposed first inward row protects architecture and headroom")
		check(not within_architecture(p, Vector2i(112, first_y - 32)), "One row too close to wall fails without shrinking actor bounds")
		check(not within_architecture(p, Vector2i(16, first_y)), "Corner overhang is rejected")
		check(parts.Top.get_pixelv(PEDESTAL.PIVOT + p.top.position + Vector2i.ONE) == PEDESTAL.LIGHT, "Top lighting remains fixed upper-left")
		if side == "south":
			check(parts.FaceInsert.get_region(Rect2i(36, 78, 24, 24)).get_data() == front.get_data(), "Generated front copies byte-exactly into protected socket")
			var blank := PEDESTAL.raster_layers(side)
			for name_value: String in PEDESTAL.LAYERS:
				if name_value != "FaceInsert": check(blank[name_value].get_data() == parts[name_value].get_data(), "Front only changes its own layer")
		else:
			check(PEDESTAL.raster_layers(side, front).is_empty(), "Never paste South drawer handles on hidden back/side")
		check(not parts.CasterRear.is_invisible() and not parts.CasterFront.is_invisible(), "All four physical caster shapes exist even where body hides them")

func actor_for(id: String) -> Node2D:
	return main.player if id == "founder" else main.get_employee(id)

func suppress_geometry_labels() -> void:
	# Only this geometry fixture is frozen/manual-step. Moving its old label
	# positions without GameMain's normal placement pass would create a false
	# actor-art mismatch. Retain ordinary UI in the initial room checkpoints.
	for employee: EmployeeAvatar in main._employees.values():
		employee.labels_suppressed = true
		employee.queue_redraw()

func prepare_room(side: String) -> void:
	await make_main(2)
	pedestal = PEDESTAL.new()
	pedestal.position = HOST
	pedestal.z_as_relative = false
	pedestal.z_index = HOST.y
	main.room.add_child(pedestal)
	check(pedestal.configure(side, front if side == "south" else null), "Construct actual native pedestal without a production family")
	var collider := StaticBody2D.new()
	collider.position = HOST
	collider.collision_layer = 2
	collider.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(32, 32)
	shape.shape = rectangle
	collider.add_child(shape)
	main.room.add_child(collider)
	var placements := main.room.resolved_placements.duplicate(true)
	placements.append({"occupied": [main.room.layout_model.cell_at(HOST)]})
	main.room.navigation.rebuild_placements(placements)
	check(not main.room.navigation.walkable(main.room.layout_model.cell_at(HOST)), "Real navigation excludes the single physical caster-base cell")
	check(main.room.placement_by_id("rolling_storage_pedestal").is_empty(), "No borrowed archive ID or fabricated canonical registration")
	for index: int in range(3):
		var id: String = ["founder", "mira", "theo"][index]
		var actor := actor_for(id)
		actor.position = [Vector2(688, 400), Vector2(688, 496), Vector2(784, 560)][index]
		main.room.navigation.actors[id] = actor.position
		if actor is EmployeeAvatar:
			actor._idle_cooldown = 1000
			actor.world_paused = false
			actor._update_character_frame()
		else:
			actor.input_blocked = false
			actor.face_direction(Vector2.RIGHT)
			actor._character_sprite.position = Vector2(0, -32)
		actor.z_index = roundi(actor.position.y)
	await frames(3)

func inspect_native(image: Image, checkpoint: String) -> void:
	var layers: Array[Dictionary] = [{"id": "pedestal", "depth": pedestal.z_index, "origin": HOST - PEDESTAL.PIVOT, "image": PEDESTAL.reunite(pedestal.layer_images)}]
	for id: String in ["founder", "mira", "theo"]:
		var actor := actor_for(id)
		var sprite := actor.get_node("CharacterSprite") as Sprite2D
		layers.append({"id": id, "depth": actor.z_index, "origin": Vector2i(sprite.global_position - Vector2(24, 40)), "image": sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))})
	for layer: Dictionary in layers:
		if layer.id == "pedestal": continue
		var source: Image = layer.image
		var tested := 0
		var hidden := 0
		var mismatch := 0
		for y: int in range(80):
			for x: int in range(48):
				var color := source.get_pixel(x, y)
				if color.a < 0.99: continue
				var point: Vector2i = layer.origin + Vector2i(x, y)
				var visible_depth: int = layer.depth
				for covering: Dictionary in layers:
					if covering.id == layer.id or covering.depth <= visible_depth: continue
					var local: Vector2i = point - covering.origin
					var source_cover: Image = covering.image
					if not Rect2i(Vector2i.ZERO, source_cover.get_size()).has_point(local): continue
					var cover := source_cover.get_pixelv(local)
					if cover.a < 0.99: continue
					color = cover
					visible_depth = covering.depth
					if covering.id == "pedestal": hidden += 1
				if color_delta(image.get_pixelv(point), color) > 0.015: mismatch += 1
				tested += 1
		check(tested > 0 and mismatch == 0, "Actual native actor/pedestal/other actor floor ordering: " + checkpoint + "/" + layer.id)
		actor_pixel_checks += tested
		depth_samples.append({"checkpoint": checkpoint, "actor": layer.id, "tested": tested, "hidden_by_pedestal": hidden, "mismatches": mismatch})

func shot(name_value: String, detail := false) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(2)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == VIEWPORT, "Actual room remains native1280×720")
	inspect_native(image, name_value)
	check(image.save_png(OUT.path_join(name_value + ".png")) == OK, "Save native room checkpoint")
	evidence[name_value] = image
	if detail:
		var crop := image.get_region(Rect2i(HOST - PEDESTAL.PIVOT, PEDESTAL.CANVAS))
		check(crop.save_png(OUT.path_join(name_value + "-native.png")) == OK, "Save native pedestal crop")
		crop.resize(384, 576, Image.INTERPOLATE_NEAREST)
		check(crop.save_png(OUT.path_join(name_value + "-4x.png")) == OK, "Save nearest4× actual-room detail")

func walk(id: String, target: Vector2, side: String) -> void:
	var actor := actor_for(id)
	if id == "founder":
		var hover := InputEventMouseMotion.new()
		hover.position = target
		hover.global_position = target
		root.push_input(hover, true)
		for down: bool in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = target
			event.global_position = target
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
		check(not main.player.route.is_empty() and main._pending_interaction.is_empty(), "Real mouse input starts ground route, not a nearby station action")
	else:
		(actor as EmployeeAvatar).walk_to(target, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
		check(actor._has_target, "Existing employee navigation starts a real route")
	var gait := {}
	for tick: int in range(240):
		actor._physics_process(1.0 / 30)
		main.click_feedback._process(1.0 / 30)
		physical_steps += 1
		check(main.room.navigation.position_is_safe(actor.position, id), "Every physical step stays outside occupied pedestal and other actors")
		check(actor._character_sprite.global_position == actor._character_sprite.global_position.round(), "Every body transform is pixel-snapped")
		gait[str(actor._character_sprite.region_rect)] = true
		if DisplayServer.get_name() != "headless": await process_frame
		if side == "south" and id == "mira" and tick == 17:
			# Revisit the first run's failed position with the actual production
			# placement pass. This proves frozen fixture timing, not a label bug.
			main._update_label_visibility("")
			for employee: EmployeeAvatar in main._employees.values():
				if not employee._labels_visible(): continue
				for other_id: String in ["founder", "mira", "theo"]:
					var other := actor_for(other_id)
					check(not employee.world_label_rect().intersects(WorldCalloutSkin.actor_rect(other.position)), "Normal label-placement pass keeps the failed fixture position clear of actors")
			await shot("south-live-label-relayout")
			suppress_geometry_labels()
		if tick in [10, 17, 30, 50]: await shot("%s-%s-walk-%03d" % [side, id, tick])
		if (actor.route.is_empty() if actor is PlayerAvatar else not actor._has_target): break
	check(actor.position == target and gait.size() >= 3, "Route finishes at requested floor point with distinct gait frames: " + id)
	await shot(side + "-" + id + "-arrival", true)

func run() -> void:
	previous_physics = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 30
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT))
	front = Image.load_from_file(ProjectSettings.globalize_path(FRONT))
	for path: String in [FRONT, PEDESTAL.POWDERCOAT, DEFAULT_FLOOR, OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH]: source_hashes[path] = FileAccess.get_sha256(path)
	preflight()
	if failures.is_empty():
		for side: String in PEDESTAL.SIDES:
			await prepare_room(side)
			await shot(side + "-room", true)
			suppress_geometry_labels()
			await walk("founder", Vector2(848, 400), side)
			await walk("mira", Vector2(848, 496), side)
			await walk("theo", Vector2(784, 336), side)
			main.free()
			await frames(2)
		await make_main(2)
		check(main.room.navigation.walkable(main.room.layout_model.cell_at(HOST)) and main.room.placement_by_id("rolling_storage_pedestal").is_empty(), "Fresh ordinary scene has no prototype navigation/family leak")
		main.free()
		if DisplayServer.get_name() != "headless":
			var contact := Image.create(384, 144, false, Image.FORMAT_RGBA8)
			for index: int in range(4):
				var name_value := PEDESTAL.SIDES[index] + "-room"
				contact.blit_rect(evidence[name_value], Rect2i(HOST - PEDESTAL.PIVOT, PEDESTAL.CANVAS), Vector2i(index * 96, 0))
			check(contact.save_png(OUT.path_join("all-four-native.png")) == OK, "Save actual native N/E/S/W room comparison")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Preserve native source/production hash " + path)
	var report := {"checks": checks, "failures": failures, "captures": evidence.keys(), "depth_samples": depth_samples, "actor_pixel_checks": actor_pixel_checks, "physical_steps": physical_steps, "source_hashes": source_hashes, "canvas": [96, 144], "pivot": [48, 96], "runtime_approved": false, "canonical_family": false, "worker_started": false, "production_changed": false}
	var file := FileAccess.open(OUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	Engine.physics_ticks_per_second = previous_physics
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", previous_environment)
	print("Rolling pedestal: %d checks, %d failures, %d actor pixels, %d physical steps" % [checks, failures.size(), actor_pixel_checks, physical_steps])
	quit(0 if failures.is_empty() else 1)
