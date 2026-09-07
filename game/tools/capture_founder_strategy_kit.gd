extends SceneTree
## DEV ONLY. Actual GameMain/production TownRoom review of two disposable
## overlay sprites on founder-workstation. The founder remains a standing scale
## and occlusion probe; this does not invent a seated pose or work capability.

const KIT := preload("res://tools/founder_strategy_kit_geometry.gd")
const OUTPUT := "res://tests/output/founder-strategy-kit"
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
	if not ok: failures.append(message); push_error(message)
func frames(count := 2) -> void:
	for _index: int in range(count): await process_frame

func collision_shape_count(node: Node) -> int:
	var result := 1 if node is CollisionShape2D else 0
	for child: Node in node.get_children(): result += collision_shape_count(child)
	return result

func attach_candidate(side: String) -> Array[Sprite2D]:
	var prop := main.room.prop_node("founder-workstation"); var result: Array[Sprite2D] = []
	for layer_name: String in KIT.LAYERS:
		var descriptor := KIT.descriptor(side, layer_name); var sprite := Sprite2D.new()
		sprite.name = str(descriptor.name); sprite.texture = load(str(descriptor.art)) as Texture2D
		sprite.position = Vector2(KIT.SPRITE_OFFSET); sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE; sprite.rotation = 0.0; sprite.flip_h = false; sprite.flip_v = false
		sprite.z_as_relative = false; sprite.z_index = prop.z_index + int(descriptor.z_offset)
		prop.add_child(sprite); result.append(sprite)
	return result

func capture_frame(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain capture is native 1280x720")
	check(image.save_png(path) == OK, "Saved " + path); captures.append(path); return image

func visibility(before: Image, after: Image, layer: Image) -> Dictionary:
	var changed := 0; var covered := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if layer.get_pixel(x, y).a == 0.0: continue
			if before.get_pixel(x, y) != after.get_pixel(x, y): changed += 1
			else: covered += 1
	return {"changed": changed, "covered_by_existing_assembly_or_founder": covered, "source_opaque": changed + covered}

func facing_vector(side: String) -> Vector2:
	match side:
		"north": return Vector2.UP
		"east": return Vector2.RIGHT
		"south": return Vector2.DOWN
		"west": return Vector2.LEFT
	return Vector2.DOWN

func run_side(side: String, details: Dictionary[String, Image]) -> void:
	# Swap two already-validated workstation sites so the founder review uses the
	# same clear production-room area as the employee workstation evidence.
	check(main.room.set_placement_overrides({
		"founder-workstation": {"grid": [20, 8], "facing": side},
		"mira-workstation": {"grid": [10, 8], "facing": "south"},
		"theo-workstation": {"grid": [8, 17], "facing": "south"},
	}), "Production room accepts reviewed founder desk facing " + side)
	main._on_room_placements_changed()
	var placement := main.room.placement_by_id("founder-workstation"); var prop := main.room.prop_node("founder-workstation")
	check(placement.facing == side and str(placement.workstation_capability_revision) == "workstations-v2:" + side, side + " uses accepted production workstation capability")
	main.player.set_physics_process(false); main.player.cancel_route()
	main.player.position = main.room.grid_to_world_position(placement.work_cell); main.player.z_index = roundi(main.player.position.y)
	main.player.face_direction(facing_vector(side)); main.room.navigation.actors["founder"] = main.player.position
	await frames(3)
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - KIT.PIVOT, KIT.CANVAS)
	await RenderingServer.frame_post_draw
	var before := root.get_texture().get_image().get_region(crop_rect); var collisions_before := collision_shape_count(prop)
	var sprites := attach_candidate(side)
	check(sprites.size() == 2 and collision_shape_count(prop) == collisions_before, side + " attachment preserves desk collision exactly")
	for index: int in range(sprites.size()):
		var sprite := sprites[index]; var descriptor := KIT.descriptor(side, KIT.LAYERS[index])
		check(sprite.texture != null and sprite.texture.get_size() == Vector2(KIT.CANVAS), side + " " + sprite.name + " loads registered texture")
		check(sprite.position == Vector2(0, -48) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + sprite.name + " has native integer transform")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), side + " " + sprite.name + " uses authored layer depth")
	await frames(3)
	var full := await capture_frame(OUTPUT.path_join("room-" + side + ".png")); var detail := full.get_region(crop_rect)
	check(detail.get_size() == KIT.CANVAS, side + " exact registered actual-room crop")
	var detail_path := OUTPUT.path_join("detail-" + side + "-native.png"); check(detail.save_png(detail_path) == OK, "Saved " + detail_path); captures.append(detail_path); details[side] = detail
	var parts := KIT.layers(side); var layer_visibility := {}
	for layer_name: String in KIT.LAYERS: layer_visibility[layer_name] = visibility(before, detail, parts[layer_name])
	check(int(layer_visibility.surface_decor_rear.changed) > 0 and int(layer_visibility.surface_decor_front.changed) > 0, side + " both reusable overlays contribute visible actual-room pixels")
	observations[side] = {"desk_asset_revision": placement.profile.asset_revision, "workstation_capability_revision": placement.workstation_capability_revision, "founder_probe_cell": [placement.work_cell.x, placement.work_cell.y], "founder_probe_z": main.player.z_index, "layer_z": {"rear": sprites[0].z_index, "front": sprites[1].z_index}, "layer_visibility": layer_visibility, "collision_shapes_before": collisions_before, "collision_shapes_after": collision_shape_count(prop)}

func run() -> void:
	if DisplayServer.get_name() == "headless": push_error("Actual-room evidence requires native renderer"); quit(1); return
	root.size = Vector2i(1280, 720); root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain; root.add_child(main); await frames(4)
	main.set_process(false); main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0); main.job_panel.close_drawer(false); main.founder_hud.dismiss_movement_hint()
	for actor: EmployeeAvatar in main._employees.values(): actor.hide()
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker")
	check(main.room.layout_model.available_facings("desk") == KIT.SIDES, "Actual room exposes all accepted workstation facings")
	var details: Dictionary[String, Image] = {}
	for side: String in KIT.SIDES: await run_side(side, details)
	var contact := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8); contact.fill(Color("151515"))
	for index: int in range(KIT.SIDES.size()): contact.blit_rect(details[KIT.SIDES[index]], Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(index * KIT.CANVAS.x, 0))
	var contact_path := OUTPUT.path_join("actual-room-contact-sheet-native.png"); check(contact.save_png(contact_path) == OK, "Saved native actual-room contact sheet"); captures.append(contact_path)
	var enlarged := contact.duplicate(); enlarged.resize(contact.get_width() * 4, contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-contact-sheet-4x.png"); check(enlarged.save_png(enlarged_path) == OK, "Saved 4x inspection sheet"); captures.append(enlarged_path)
	var manifest := {"status": "native_review_candidate_not_runtime_registered", "scene": "actual GameMain/production TownRoom founder-workstation with fixture-only overlays", "founder_presentation": "actual standing PlayerAvatar at the authored work cell; occlusion/scale probe only, not a seated or working pose", "renderer": DisplayServer.get_name(), "worker_disabled": true, "save_access": false, "production_catalog_mutated": false, "runtime_registered": false, "canvas": [192, 224], "pivot": [96, 160], "facings": KIT.SIDES, "observations": observations, "captures": captures, "checks": checks, "failures": failures}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE); check(file != null, "Opened actual-room result"); manifest.checks = checks; manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	main.game_audio.shutdown(); main.free(); print("Founder strategy actual room: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
