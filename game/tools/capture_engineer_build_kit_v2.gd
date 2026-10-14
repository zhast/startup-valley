extends SceneTree
## DEV ONLY. Actual GameMain/TownRoom proof for the unregistered engineer kit v2
## on Theo's accepted production desk. Theo is an existing directional seated
## contact/scale/occlusion probe only; no engineer employee, service, backend, or pose exists.

const KIT := preload("res://tools/engineer_build_kit_v2_geometry.gd")
const OUTPUT := "res://tests/output/engineer-build-kit-v2"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const LEGACY_HASHES := {
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v1.png": "58d4b551c5e725c3e87bb27b40cd87f152a0b15cefc1560e3eac18ed36813604",
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v2.png": "e96e938435902bcb1323409177443b3ad56bb7688ba48f32084609ecfc50c7f4",
	"res://assets/source/overnight-20260904/roles/engineer-mat-east-v1.png": "4d5688c0bf757351abb2470d7c52cf0aec3b74cd73a1979762d7c4a1e365f856",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v1.png": "a2f5a669cf15d3d465299a562bd6ef503cbf0e7b2563d0decff85c7495ddeed7",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v2.png": "8b735f19797d9fe3c46a6a00ebd08372089a6b2239650748862f3785b2d07c93",
	"res://assets/source/overnight-20260904/roles/engineer-mat-west-v1.png": "372f5b5e9fa3bfd4d4031709d36cd230a8dc6f568feb411189d6dbc3a6e89a59",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v1.png": "9a3dcd2447d29cbd301976abb7a6c4923522af620ee3468fae9303cadecfae5d",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v2.png": "78f2877d83d0af0f81f9fff8b670ce8e4621f392b474248eff6a9b15540b7fc0",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/east-v1.png": "a6e2323708bbb64b23c462ee9b3d1317bda9ab8718c38730bbc1eb7ea2874450",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v1.png": "67ded27384c11a703e62b20d987de37f3970cbfea7d5d3775885a12b949899fe",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v2.png": "46494712079df1335e20fc10c9d5913fb2d7129203329d92d46416d436d15e38",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/west-v1.png": "2742221f198e1f2f853135e9ec1fdf8c9b92724b0693b844b1d41a9ceff2ff8c",
}

var main: GameMain
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Dictionary = {}
var total_actor_occlusion := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func _authored_office_roster(game: GameMain) -> bool:
	if not game._employees.has("mira") or not game._employees.has("theo"):
		return false
	if game._employees.size() == 2:
		return true
	return game._employees.size() == 3 and game._employees.has("creative")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for _index: int in range(count):
		await process_frame

func collision_shape_count(node: Node) -> int:
	var result := 1 if node is CollisionShape2D else 0
	for child: Node in node.get_children():
		result += collision_shape_count(child)
	return result

func attach_candidate(side: String) -> Array[Sprite2D]:
	var prop := main.room.prop_node("theo-workstation")
	var result: Array[Sprite2D] = []
	for layer_name: String in KIT.LAYERS:
		var descriptor := KIT.descriptor(side, layer_name)
		var source := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
		var sprite := Sprite2D.new()
		sprite.name = str(descriptor.name)
		sprite.texture = ImageTexture.create_from_image(source)
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

func masked_change(before: Image, after: Image, mask: Image) -> Dictionary:
	var changed := 0
	var covered := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if mask.get_pixel(x, y).a == 0.0:
				continue
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				changed += 1
			else:
				covered += 1
	return {"changed": changed, "covered_by_existing_assembly_or_actor": covered, "source_opaque": changed + covered}

func masked_difference(a: Image, b: Image, mask: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if mask.get_pixel(x, y).a > 0.0 and a.get_pixel(x, y) != b.get_pixel(x, y):
				result += 1
	return result

func image_difference(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				result += 1
	return result

func setup_theo_probe(actor: EmployeeAvatar) -> void:
	actor.show()
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
	actor._speech_visible = false
	actor._label_hold = 0
	actor._label_layer.hide()
	actor._effect_sprite.hide()

func run_side(side: String, occupied_details: Dictionary[String, Image], unoccupied_details: Dictionary[String, Image]) -> void:
	check(main.room.set_placement_overrides({
		"mira-workstation": {"grid": [10, 8], "facing": side},
		"theo-workstation": {"grid": [20, 8], "facing": side},
	}), "Production room accepts engineer-v2 probe desk facing " + side)
	main._on_room_placements_changed()
	var actor := main.get_employee("theo")
	var mina := main.get_employee("mira")
	if mina != null:
		mina.hide()
	setup_theo_probe(actor)
	await frames(3)
	var placement := main.room.placement_by_id("theo-workstation")
	var visual := main.room.employee_workstation_visual("theo")
	var prop := main.room.prop_node("theo-workstation")
	check(placement.facing == side and str(placement.workstation_capability_revision) == "workstations-v2:" + side, side + " uses the accepted production workstation capability")
	check(str(visual.work_facing) == side and str(visual.pose_set) == CharacterArt.REVIEWED_WORKSTATION_POSE_SET, side + " host publishes the exact accepted gaze and pose contract")
	check(str(actor._workstation_visual.work_facing) == side and str(actor._workstation_visual.workstation_capability_revision) == "workstations-v2:" + side, side + " Theo probe consumes the exact host gaze capability")
	check(actor.position == actor.desk_position and actor.desk_position == visual.work_position, side + " Theo probe contacts the authored physical work point")
	check(actor._uses_seated_visual(), side + " Theo probe uses his accepted seated typing presentation")
	var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - KIT.PIVOT, KIT.CANVAS)
	await RenderingServer.frame_post_draw
	var before := root.get_texture().get_image().get_region(crop_rect)
	var collisions_before := collision_shape_count(prop)
	var sprites := attach_candidate(side)
	check(sprites.size() == 2 and collision_shape_count(prop) == collisions_before, side + " rear/front attachment adds zero collision")
	for index: int in range(sprites.size()):
		var sprite := sprites[index]
		var descriptor := KIT.descriptor(side, KIT.LAYERS[index])
		check(sprite.texture != null and sprite.texture.get_size() == Vector2(KIT.CANVAS), side + " " + sprite.name + " loads the full fixture canvas")
		check(sprite.position == Vector2(0, -48) and sprite.position == Vector2(KIT.SPRITE_OFFSET), side + " " + sprite.name + " resolves the exact 96,160 floor pivot")
		check(sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " " + sprite.name + " has no runtime transform")
		check(sprite.z_index == prop.z_index + int(descriptor.z_offset), side + " " + sprite.name + " keeps authored host-relative depth")
	await frames(3)
	var full := await capture_frame(OUTPUT.path_join("room-" + side + ".png"))
	var occupied := full.get_region(crop_rect)
	check(occupied.get_size() == KIT.CANVAS, side + " exact 192x224 production-room crop")
	var occupied_path := OUTPUT.path_join("detail-" + side + "-native.png")
	check(occupied.save_png(occupied_path) == OK, "Saved " + occupied_path)
	captures.append(occupied_path)
	occupied_details[side] = occupied
	actor.hide()
	await frames(3)
	await RenderingServer.frame_post_draw
	var unoccupied := root.get_texture().get_image().get_region(crop_rect)
	var unoccupied_path := OUTPUT.path_join("detail-" + side + "-unoccupied-native.png")
	check(unoccupied.save_png(unoccupied_path) == OK, "Saved " + unoccupied_path)
	captures.append(unoccupied_path)
	unoccupied_details[side] = unoccupied
	actor.show()
	var parts := KIT.layers(side)
	var layer_visibility := {}
	var actor_occlusion := {}
	for layer_name: String in KIT.LAYERS:
		layer_visibility[layer_name] = masked_change(before, occupied, parts[layer_name])
		var occluded := masked_difference(occupied, unoccupied, parts[layer_name])
		actor_occlusion[layer_name] = occluded
		total_actor_occlusion += occluded
	check(int(layer_visibility.surface_decor_rear.changed) > 0 and int(layer_visibility.surface_decor_front.changed) > 0, side + " both reusable overlays contribute visible actual-room pixels")
	var actor_pixel_delta := image_difference(occupied, unoccupied)
	check(actor_pixel_delta > 0, side + " occupied/unoccupied pair contains the accepted seated Theo probe")
	observations[side] = {
		"desk_asset_revision": placement.profile.asset_revision,
		"workstation_capability_revision": placement.workstation_capability_revision,
		"work_facing": str(visual.work_facing),
		"actor_probe_role": "existing_theo_directional_seated_typing_not_engineer",
		"actor_work_point": [actor.desk_position.x, actor.desk_position.y],
		"actor_pixel_delta": actor_pixel_delta,
		"actor_overlay_occlusion_measured_not_quality_proxy": actor_occlusion,
		"actor_upper_z": prop.z_index + int(placement.seat_layer_z_offsets.upper),
		"layer_z": {"rear": sprites[0].z_index, "front": sprites[1].z_index},
		"layer_visibility": layer_visibility,
		"collision_shapes_before": collisions_before,
		"collision_shapes_after": collision_shape_count(prop),
	}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Actual-room evidence requires the native renderer; run test_engineer_build_kit_v2.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var catalog_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
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
	for employee: EmployeeAvatar in main._employees.values():
		if employee.employee_id != "theo":
			employee.hide()
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker")
	check(main.room.layout_model.available_facings("desk") == KIT.SIDES, "Actual production room exposes four accepted desk facings")
	check(_authored_office_roster(main), "Actual GameMain roster is Mina, Theo, and optionally Creative")
	check(not main._employees.has("engineer"), "Capture creates no engineer employee or hire")
	var occupied_details: Dictionary[String, Image] = {}
	var unoccupied_details: Dictionary[String, Image] = {}
	for side: String in KIT.SIDES:
		await run_side(side, occupied_details, unoccupied_details)
	var occupied_contact := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	var unoccupied_contact := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	occupied_contact.fill(Color("151515"))
	unoccupied_contact.fill(Color("151515"))
	for index: int in range(KIT.SIDES.size()):
		occupied_contact.blit_rect(occupied_details[KIT.SIDES[index]], Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(index * KIT.CANVAS.x, 0))
		unoccupied_contact.blit_rect(unoccupied_details[KIT.SIDES[index]], Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(index * KIT.CANVAS.x, 0))
	var contact_path := OUTPUT.path_join("actual-room-contact-sheet-native.png")
	check(occupied_contact.save_png(contact_path) == OK, "Saved native actual-room contact sheet")
	captures.append(contact_path)
	var unoccupied_path := OUTPUT.path_join("actual-room-unoccupied-contact-sheet-native.png")
	check(unoccupied_contact.save_png(unoccupied_path) == OK, "Saved native unoccupied contact sheet")
	captures.append(unoccupied_path)
	var enlarged := occupied_contact.duplicate()
	enlarged.resize(occupied_contact.get_width() * 4, occupied_contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join("actual-room-contact-sheet-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved nearest-neighbor inspection sheet")
	captures.append(enlarged_path)
	var unoccupied_enlarged := unoccupied_contact.duplicate()
	unoccupied_enlarged.resize(unoccupied_contact.get_width() * 4, unoccupied_contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var unoccupied_enlarged_path := OUTPUT.path_join("actual-room-unoccupied-contact-sheet-4x.png")
	check(unoccupied_enlarged.save_png(unoccupied_enlarged_path) == OK, "Saved unoccupied nearest-neighbor inspection sheet")
	captures.append(unoccupied_enlarged_path)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_before, "Capture leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Capture leaves default office layout byte-exact")
	for path: String in LEGACY_HASHES:
		check(FileAccess.get_sha256(path) == str(LEGACY_HASHES[path]), "Capture preserves legacy/source engineer evidence byte-exact: " + path)
	var manifest := {
		"status": "native_review_candidate_not_catalogued_or_runtime_registered",
		"candidate_revision": "engineer-build-kit-v2",
		"scene": "actual GameMain and production TownRoom; fixture-only rear/front Sprite2D overlays on theo-workstation using accepted workstations-v2 desk",
		"actor_presentation": "Theo's accepted directional seated typing presentation at the authored desk work point; host contact, gaze, scale and occlusion probe only because no engineer employee or accepted engineer role pose exists",
		"actor_role_claimed": false,
		"engineer_employee_service_backend_or_hire_created": false,
		"renderer": DisplayServer.get_name(),
		"worker_disabled": true,
		"save_access": false,
		"production_catalog_mutated": false,
		"default_layout_mutated": false,
		"dev_catalogue_family": "engineer_build_kit",
		"candidate_revision_registered": false,
		"production_catalogue_registered": false,
		"runtime_registered": false,
		"canvas": [KIT.CANVAS.x, KIT.CANVAS.y],
		"pivot": [KIT.PIVOT.x, KIT.PIVOT.y],
		"sprite_offset": [KIT.SPRITE_OFFSET.x, KIT.SPRITE_OFFSET.y],
		"facings": KIT.SIDES,
		"layers": KIT.LAYERS,
		"objects": KIT.OBJECTS,
		"total_actor_overlay_overlap_pixels_measured_not_acceptance_threshold": total_actor_occlusion,
		"observations": observations,
		"captures": captures,
		"legacy_files_hash_guarded": LEGACY_HASHES.size(),
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room result")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	main.game_audio.shutdown()
	main.free()
	print("Engineer build kit v2 actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
