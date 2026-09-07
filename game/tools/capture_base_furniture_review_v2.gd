extends SceneTree
## DEV ONLY. Actual GameMain/TownRoom native review for the shadow-only base
## revision. Existing compact/workbench v1 captures remain untouched.

const REVIEW := preload("res://tools/base_furniture_review_v2.gd")
const OUTPUT := "res://tests/output/base-furniture-review-2026-09-06"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var main: GameMain
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

func save_view(path: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Native review remains 1280x720")
	check(image.save_png(path) == OK, "Saved " + path)
	captures.append(path)
	return image

func configure_family(family: String, pivot: Vector2i) -> OfficeLayout:
	var base: Variant = REVIEW.source(family)
	var room_data: Dictionary = main.room.layout_model.data.duplicate(true)
	var catalogue: Dictionary = main.room.layout_model.catalog.duplicate(true)
	room_data.props = [{"id": family + "-review", "kind": family, "grid": [pivot.x, pivot.y], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	room_data.player_spawn = [17, 18]
	catalogue[family] = REVIEW.catalog_entry(family)
	var model := OfficeLayout.new()
	model.configure(room_data, catalogue)
	check(model.enable_calibration_preview(self), family + " native capture owns its isolated calibration model")
	for side: String in base.SIDES:
		check(model.authorize_calibration_decorative_profile(family, side, self), family + " " + side + " exact v2 fixture receives scoped admission")
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
	return model

func run_family(family: String, pivot: Vector2i) -> void:
	var base: Variant = REVIEW.source(family)
	var id := family + "-review"
	var model := await configure_family(family, pivot)
	var base_crops: Dictionary[String, Image] = {}
	var actor_crops: Dictionary[String, Image] = {}
	var family_observations := {}
	for side: String in base.SIDES:
		check(main.room.set_placement_overrides({id: {"grid": [pivot.x, pivot.y], "facing": side}}), family + " " + side + " commits through actual TownRoom validation")
		await frames(3)
		var placement := main.room.placement_by_id(id)
		var prop := main.room.prop_node(id)
		check(prop != null and prop.get_script() == null, family + " " + side + " uses the neutral native-layer carrier")
		if prop == null:
			continue
		var expected_shapes := int(base.profile(side).occupied.size())
		check(collision_shapes(prop).size() == expected_shapes, family + " " + side + " preserves the v1 collision-cell count")
		check(not placement.has("interaction") and not main.room.interaction_world_position(id).is_finite(), family + " " + side + " remains passive")
		for layer: Dictionary in placement.render_layers:
			var sprite := prop.get_node(str(layer.name)) as Sprite2D
			check(sprite != null and sprite.texture.get_size() == Vector2(base.CANVAS), family + " " + side + " " + str(layer.name) + " loads the native v2 canvas")
			check(sprite.position == Vector2(base.SPRITE_OFFSET) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation), family + " " + side + " " + str(layer.name) + " keeps exact integer registration")
		main.player.hide()
		await frames(2)
		var base_frame := await save_view(OUTPUT.path_join("%s-%s-base-room.png" % [family, side]))
		var crop_rect := Rect2i(Vector2i(main.room.global_position + placement.anchor) - base.PIVOT, base.CANVAS)
		var base_crop := base_frame.get_region(crop_rect)
		check(base_crop.get_size() == base.CANVAS, family + " " + side + " base crop uses the exact registered canvas")
		var base_path := OUTPUT.path_join("%s-%s-base-native.png" % [family, side])
		check(base_crop.save_png(base_path) == OK, "Saved " + base_path)
		captures.append(base_path)
		base_crops[side] = base_crop
		var approach: Vector2i = OfficeLayout.vector(base.profile(side).interaction)
		var actor_cell := pivot + approach
		check(model.is_floor(actor_cell) and main.room.navigation.walkable(actor_cell), family + " " + side + " review actor stands on the unchanged clear proposal cell")
		main.player.position = model.world(actor_cell)
		main.player.z_index = int(main.player.position.y)
		main.player.face_direction(Vector2(OfficeLayout.vector(base.profile(side).employee_look_vector)))
		main.room.navigation.actors["founder"] = main.player.position
		main.player.show()
		await frames(2)
		var actor_frame := await save_view(OUTPUT.path_join("%s-%s-actor-room.png" % [family, side]))
		var actor_crop := actor_frame.get_region(crop_rect)
		var actor_path := OUTPUT.path_join("%s-%s-actor-native.png" % [family, side])
		check(actor_crop.save_png(actor_path) == OK, "Saved " + actor_path)
		captures.append(actor_path)
		actor_crops[side] = actor_crop
		check(actor_crop.get_data() != base_crop.get_data(), family + " " + side + " actor-scale crop is visibly distinct")
		family_observations[side] = {
			"grid": [pivot.x, pivot.y],
			"actor_cell": [actor_cell.x, actor_cell.y],
			"occupied_cells": placement.occupied.size(),
			"render_layers": placement.render_layers,
		}
	var base_sheet := Image.create(base.CANVAS.x * 4, base.CANVAS.y, false, Image.FORMAT_RGBA8)
	var actor_sheet := Image.create(base.CANVAS.x * 4, base.CANVAS.y, false, Image.FORMAT_RGBA8)
	base_sheet.fill(Color("151515"))
	actor_sheet.fill(Color("151515"))
	for index: int in range(base.SIDES.size()):
		var side: String = base.SIDES[index]
		base_sheet.blit_rect(base_crops[side], Rect2i(Vector2i.ZERO, base.CANVAS), Vector2i(index * base.CANVAS.x, 0))
		actor_sheet.blit_rect(actor_crops[side], Rect2i(Vector2i.ZERO, base.CANVAS), Vector2i(index * base.CANVAS.x, 0))
	var base_sheet_path := OUTPUT.path_join(family + "-actual-room-base-native.png")
	var actor_sheet_path := OUTPUT.path_join(family + "-actual-room-actor-native.png")
	check(base_sheet.save_png(base_sheet_path) == OK, "Saved " + base_sheet_path)
	check(actor_sheet.save_png(actor_sheet_path) == OK, "Saved " + actor_sheet_path)
	captures.append_array([base_sheet_path, actor_sheet_path])
	var enlarged := actor_sheet.duplicate()
	enlarged.resize(actor_sheet.get_width() * 4, actor_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_path := OUTPUT.path_join(family + "-actual-room-actor-4x.png")
	check(enlarged.save_png(enlarged_path) == OK, "Saved " + enlarged_path)
	captures.append(enlarged_path)
	observations[family] = family_observations
	model.disable_calibration_preview(self)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Base furniture v2 actual-room evidence requires the native renderer")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var hashes := {
		PRODUCTION_CATALOG: FileAccess.get_sha256(PRODUCTION_CATALOG),
		DEFAULT_LAYOUT: FileAccess.get_sha256(DEFAULT_LAYOUT),
		DEV_CATALOGUE: FileAccess.get_sha256(DEV_CATALOGUE),
	}
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
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Actual GameMain starts no worker")
	await run_family("compact_desk", Vector2i(12, 13))
	await run_family("shared_workbench", Vector2i(12, 14))
	for path: String in hashes:
		check(FileAccess.get_sha256(path) == hashes[path], "Native review leaves " + path + " byte-identical")
	var result := {
		"status": "base_only_native_review_candidate_not_runtime_registered",
		"date": "2026-09-06",
		"renderer": DisplayServer.get_name(),
		"viewport": [1280, 720],
		"worker_disabled": true,
		"save_access": false,
		"change_scope": "floor shadow only; all v1 structure, geometry and overlay ownership retained",
		"runtime_registered": false,
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"shared_art_catalogue_mutated": false,
		"observations": observations,
		"captures": captures,
		"limitations": ["The founder is an adjacent native scale/occlusion probe only; optional chairs, devices, tools and seated lifecycle remain separately owned.", "Existing v1 route, wall, corner, collision and picking evidence remains applicable because v2 changes no geometry or structure pixels."],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("actual-room-results.json"), FileAccess.WRITE)
	check(file != null, "Opened actual-room v2 result")
	result.checks = checks
	result.failures = failures
	if file != null:
		file.store_string(JSON.stringify(result, "\t") + "\n")
	main.game_audio.shutdown()
	main.queue_free()
	await frames(3)
	print("Base furniture v2 actual room: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
