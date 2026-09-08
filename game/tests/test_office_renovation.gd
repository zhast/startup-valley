extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/office-renovation"

var checks := 0
var failures: Array[String] = []
var main: GameMain

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(main)
	await frames(5)
	preload("res://tests/renovation_transport_fixture.gd").bind_layout_only(main)
	check(main.office_renovation != null and not main.office_renovation.active, "Normal GameMain owns a closed player renovation controller")
	main.company_panel.present("settings")
	await frames(4)
	await create_timer(0.2).timeout
	var renovate := find_button(main.company_panel, "Renovate office")
	check(renovate != null, "Settings exposes Renovate office")
	await capture("settings-entry.png")
	if renovate != null: await click(renovate.get_global_rect().get_center())
	check(main.office_renovation.active and not main.company_panel.visible, "A real Settings click opens renovation over the normal office")
	main._process(0.0)
	check(main._world_paused() and main.player.input_blocked and main.day_clock.ui_paused, "Renovation pauses world input and business time")
	check(main.office_renovation._input_surface.get_global_rect().encloses(Rect2(0, 0, 1280, 720)), "Renovation owns the full pointer surface so UI clicks cannot leak into movement")
	await capture("renovation-open.png")
	var starting_overrides := main.room.placement_overrides.duplicate(true)
	var player_position := main.player.position
	main.player.cancel_route()
	var coffee_placement := main.room.placement_by_id("coffee-station")
	var coffee_prop := main.room.prop_node("coffee-station")
	var coffee_sprite := coffee_prop.get_node(str(coffee_placement.render_layers[0].name)) as Sprite2D
	await click(painted_point(coffee_sprite))
	check(main.office_renovation.selected_id == "coffee-station", "A real painted furniture pixel selects its front-most live prop")
	await click(main.room.layout_model.world(Vector2i(20, 16)))
	check(main.player.route.is_empty() and main.player.position == player_position, "Renovation world clicks never create a founder route")

	var renovation := main.office_renovation
	renovation.select_placement("artifact-archive")
	var archive_before := main.room.placement_by_id("artifact-archive")
	var archive_facing := str(archive_before.facing)
	var authored := main.room.layout_model.available_facings("artifact_archive")
	check(authored.size() == 4 and renovation._facing_picker.item_count == authored.size(), "Runtime archive selector exposes all and only four reviewed authored views")
	await key(KEY_R)
	check(renovation.placement_active and renovation.preview_facing != archive_facing, "Real R begins an authored directional preview")
	check(bool(renovation.preview_result.get("valid", false)), "In-place archive rotation passes wall, route, clearance, and stage checks")
	await capture("authored-rotation-preview.png")
	var rotated_facing := renovation.preview_facing
	await click(main.room.global_position + main.room.layout_model.world(renovation.preview_grid))
	check(not renovation.placement_active and str(main.room.placement_by_id("artifact-archive").facing) == rotated_facing, "Real world click atomically commits the authored view")
	var rotated_archive := main.room.placement_by_id("artifact-archive")
	var rotated_prop := main.room.prop_node("artifact-archive")
	for layer: Dictionary in rotated_archive.render_layers:
		var sprite := rotated_prop.get_node(str(layer.name)) as Sprite2D
		check(sprite != null and sprite.rotation == 0.0 and sprite.scale == Vector2.ONE and not sprite.flip_h and not sprite.flip_v, "Committed direction uses untouched native source pixels: " + str(layer.name))
	for cell: Vector2i in rotated_archive.occupied:
		check(not main.room.navigation.walkable(cell), "Committed directional footprint blocks live navigation: " + str(cell))
	check(main.room.navigation.walkable(rotated_archive.interaction), "Committed directional interaction remains walkable")
	check(renovation._history.size() == 1, "Successful placement creates exactly one Undo step")
	await key(KEY_U)
	check(str(main.room.placement_by_id("artifact-archive").facing) == archive_facing and renovation._history.is_empty(), "Real U restores the exact previous facing")

	renovation.select_placement("founder-workstation")
	var before_invalid := main.room.placement_overrides.duplicate(true)
	await key(KEY_M)
	await click(main.room.global_position + main.room.layout_model.world(Vector2i(0, 4)))
	check(renovation.placement_active and not bool(renovation.preview_result.get("valid", true)), "Wall/corner placement remains a visible rejected preview")
	check(main.room.placement_overrides == before_invalid, "Rejected wall/corner placement changes no live furniture")
	check(renovation._status.tooltip_text.contains("wall") or renovation._status.tooltip_text.contains("boundary"), "Wall rejection retains a specific diagnostic")
	await capture("wall-rejection.png")
	await key(KEY_ESCAPE)
	check(not renovation.placement_active and main.room.prop_node("founder-workstation").visible, "Escape restores hidden committed art after an invalid move")

	# South archive leaves this floor cell free; its next West view would occupy it.
	renovation.select_placement("artifact-archive")
	var blocker := main.room.layout_model.world(Vector2i(4, 12))
	main.player.position = blocker
	main.room.navigation.actors["founder"] = blocker
	var before_actor := main.room.placement_overrides.duplicate(true)
	await key(KEY_R)
	check(renovation.placement_active and not bool(renovation.preview_result.get("valid", true)), "A live founder footprint rejects an otherwise valid rotation")
	check(renovation._status.text.contains("Founder"), "Occupied rotation names the actor who must move")
	await click(main.room.layout_model.world(renovation.preview_grid))
	check(main.room.placement_overrides == before_actor and renovation.placement_active, "Occupied commit preserves the room and remains correctable")
	await key(KEY_ESCAPE)
	main.player.position = player_position
	main.room.navigation.actors["founder"] = player_position
	var mina := main.get_employee("mira")
	var mina_position := mina.position
	var mina_desk := main.room.placement_by_id("mira-workstation")
	mina._has_target = false
	mina._route = PackedVector2Array()
	mina.position = main.room.global_position + Vector2(mina_desk.work_position)
	main.room.navigation.actors["mira"] = mina.position
	renovation.select_placement("mira-workstation")
	await key(KEY_R)
	check(renovation.placement_active and not bool(renovation.preview_result.get("valid", true)), "An occupied workstation cannot move or rotate under its employee")
	check(renovation._status.text.contains("Mina") and renovation._status.text.contains("leave"), "Occupied desk rejection tells its owner to leave first")
	await key(KEY_ESCAPE)
	mina.position = mina_position
	main.room.navigation.actors["mira"] = mina_position

	# Unsupported families stay honest: one authored direction means no fake
	# transform. If a later reviewed facing ships, this assertion adapts to it.
	renovation.select_placement("coffee-station")
	var coffee_facings := main.room.layout_model.available_facings("coffee_station")
	check(renovation._facing_picker.item_count == coffee_facings.size(), "Facing selector follows production review gates for every family")
	if coffee_facings.size() == 1:
		await key(KEY_R)
		check(not renovation.placement_active and renovation._status.text.contains("only one reviewed view"), "Rotation never bitmap-rotates a missing direction")

	await key(KEY_ESCAPE)
	check(not renovation.active and not main.company_panel.visible, "Escape closes renovation without opening a second modal underneath")
	check(main.room.placement_overrides == starting_overrides, "Rotate plus Undo and rejected previews leave the initial layout exact")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("Office renovation passed %d checks (normal GameMain, real pointer/keys, authored rotation, collision, Undo)." % checks)
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func find_button(node: Node, text_value: String) -> Button:
	if node is Button and (node as Button).text == text_value: return node as Button
	for child: Node in node.get_children():
		var found := find_button(child, text_value)
		if found != null: return found
	return null

func frames(count: int = 2) -> void:
	for _index: int in range(count): await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await frames()
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await frames()

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await frames()

func painted_point(sprite: Sprite2D) -> Vector2:
	var image := sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var region := Rect2i(sprite.region_rect)
	var crop := image.get_region(region)
	for y: int in range(crop.get_height()):
		for x: int in range(crop.get_width()):
			if crop.get_pixel(x, y).a > 0.5:
				return sprite.to_global(Vector2(x, y) + Vector2(0.5, 0.5) - Vector2(region.size) * 0.5)
	return sprite.global_position

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var image := root.get_texture().get_image()
	check(image != null and not image.is_empty() and image.save_png(OUTPUT + "/" + filename) == OK, "Saved native renovation evidence: " + filename)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
