extends SceneTree
## DEV ONLY. Places the unregistered kit on Theo's accepted production desk in
## an otherwise ordinary GameMain room. It never mutates a catalogue or save.

const KIT := preload("res://tools/theo_campaign_kit_geometry.gd")
const OUTPUT := "res://tests/output/theo-campaign-kit"
var main: GameMain
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Dictionary = {}

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

func collision_shape_count(node: Node) -> int:
	var result := 1 if node is CollisionShape2D else 0
	for child: Node in node.get_children(): result += collision_shape_count(child)
	return result

func attach_candidate(side: String) -> Array[Sprite2D]:
	var prop := main.room.prop_node("theo-workstation")
	var result: Array[Sprite2D] = []
	for layer_name: String in KIT.LAYERS:
		var descriptor := KIT.descriptor(side, layer_name)
		var sprite := Sprite2D.new()
		sprite.name = str(descriptor.name)
		sprite.texture = load(str(descriptor.art)) as Texture2D
		sprite.position = Vector2(KIT.SPRITE_OFFSET)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0
		sprite.flip_h = false
		sprite.flip_v = false
		sprite.z_as_relative = false
		sprite.z_index = prop.z_index + int(descriptor.z_offset)
		prop.add_child(sprite)
		result.append(sprite)
	return result

func capture_frame(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain capture stays native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

func changed_pixels(before: Image, after: Image, layer: Image) -> Dictionary:
	var changed := 0
	var covered := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if layer.get_pixel(x, y).a == 0.0: continue
			if before.get_pixel(x, y) != after.get_pixel(x, y): changed += 1
			else: covered += 1
	return {"changed": changed, "covered_by_existing_assembly": covered, "source_opaque": changed + covered}

func setup_actor(actor: EmployeeAvatar) -> void:
	actor.set_physics_process(false)
	actor.position = actor.desk_position
	actor.navigation.actors[actor.employee_id] = actor.position
	actor._has_target = false
	actor.has_live_job = true
	actor.work_state = EmployeeAvatar.WorkState.TYPING
	actor._activity = &"typing"
	actor._animation_elapsed = 0.26
	actor._update_character_frame()
	actor._physics_process(0.14)
	actor.labels_suppressed = true
	actor._label_layer.hide()
	actor._effect_sprite.hide()

func run_side(side: String, details: Dictionary[String, Image]) -> void:
	check(main.room.set_placement_overrides({
		"mira-workstation": {"grid": [10, 8], "facing": side},
		"theo-workstation": {"grid": [20, 8], "facing": side},
	}), "Production room accepts Theo's reviewed " + side + " desk")
	main._on_room_placements_changed()
	var actor := main.get_employee("theo")
	setup_actor(actor)
	await frames(3)
	var placement := main.room.placement_by_id("theo-workstation")
	var prop := main.room.prop_node("theo-workstation")
	check(placement.facing == side and str(placement.workstation_capability_revision) == "workstations-v2:" + side, side + " uses accepted production desk/pose capability")
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - KIT.PIVOT, KIT.CANVAS)
	await RenderingServer.frame_post_draw
	var before_full := root.get_texture().get_image()
	var before := before_full.get_region(crop_rect)
	var collisions_before := collision_shape_count(prop)
	var sprites := attach_candidate(side)
	check(sprites.size() == 2 and collision_shape_count(prop) == collisions_before, side + " rear/front attachment adds zero collision")
	for index: int in range(sprites.size()):
		var sprite := sprites[index]
		var descriptor := KIT.descriptor(side, KIT.LAYERS[index])
		check(sprite.texture != null and sprite.texture.get_size() == Vector2(KIT.CANVAS), side + " " + sprite.name + " loads full registered texture")
		check(sprite.position == Vector2(0, -48) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + sprite.name + " remains native on integer anchor")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), side + " " + sprite.name + " keeps authored depth")
	await frames(3)
	var full := await capture_frame(OUTPUT.path_join("room-" + side + ".png"))
	var detail := full.get_region(crop_rect)
	check(detail.get_size() == KIT.CANVAS, side + " exact 192x224 production-room crop")
	var detail_path := OUTPUT.path_join("detail-" + side + "-native.png")
	check(detail.save_png(detail_path) == OK, "Saved " + detail_path)
	captures.append(detail_path)
	details[side] = detail
	var parts := KIT.layers(side)
	var layer_visibility := {}
	for layer_name: String in KIT.LAYERS: layer_visibility[layer_name] = changed_pixels(before, detail, parts[layer_name])
	check(int(layer_visibility.surface_decor_rear.changed) > 0 and int(layer_visibility.surface_decor_front.changed) > 0, side + " both semantic layers contribute visible pixels in actual room")
	observations[side] = {
		"desk_asset_revision": placement.profile.asset_revision,
		"workstation_capability_revision": placement.workstation_capability_revision,
		"actor_upper_z": prop.z_index + int(placement.seat_layer_z_offsets.upper),
		"layer_z": {"rear": sprites[0].z_index, "front": sprites[1].z_index},
		"layer_visibility": layer_visibility,
		"collision_shapes_before": collisions_before,
		"collision_shapes_after": collision_shape_count(prop),
	}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Actual-room evidence requires the native renderer; run test_theo_campaign_kit.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames(4)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.job_panel.close_drawer(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker")
	check(main.room.layout_model.available_facings("desk") == KIT.SIDES, "Actual production room exposes the four accepted desk facings")
	var details: Dictionary[String, Image] = {}
	for side: String in KIT.SIDES: await run_side(side, details)
	var contact := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	contact.fill(Color("151515"))
	for index: int in range(KIT.SIDES.size()):
		contact.blit_rect(details[KIT.SIDES[index]], Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(index * KIT.CANVAS.x, 0))
	var contact_path := OUTPUT.path_join("actual-room-contact-sheet-native.png")
	check(contact.save_png(contact_path) == OK, "Saved native actual-room contact sheet")
	captures.append(contact_path)
	var enlarged := contact.duplicate()
	enlarged.resize(contact.get_width() * 4, contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved nearest-neighbor inspection sheet")
	captures.append(enlarged_path)
	var manifest := {
		"status": "native_review_candidate_not_runtime_registered",
		"scene": "actual GameMain and production TownRoom; fixture-only Sprite2D attachments on Theo's accepted desk",
		"renderer": DisplayServer.get_name(),
		"worker_disabled": true,
		"save_access": false,
		"production_catalog_mutated": false,
		"runtime_registered": false,
		"canvas": [KIT.CANVAS.x, KIT.CANVAS.y],
		"pivot": [KIT.PIVOT.x, KIT.PIVOT.y],
		"facings": KIT.SIDES,
		"observations": observations,
		"captures": captures,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room result")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	main.game_audio.shutdown()
	main.free()
	print("Theo campaign actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
