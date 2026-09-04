extends SceneTree

const EDITOR_SCRIPT: Script = preload("res://tools/office_layout_editor.gd")
const OUTPUT := "res://tests/output/office-layout"
var _editor: DevOfficeLayoutEditor
var _failures: Array[String] = []
var _checks: int = 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 800)
	root.content_scale_size = Vector2i(1600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	# Construct through the script so the test never creates a worker or GameMain.
	_editor = EDITOR_SCRIPT.new() as DevOfficeLayoutEditor
	root.add_child(_editor)
	await _settle()
	var original_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH)
	_check(bool(_editor.validate_all_stages({}).get("valid", false)), "Default layout validates before editing")
	_check(_editor._placements.size() == 8, "Mina + Theo stage shows eight authored props")
	_check(_editor._facing_picker.item_count == 1, "Only authored south orientation is selectable")
	var original := _editor.model.placement_by_id("founder-workstation", 2)
	var original_grid: Vector2i = original.get("grid", Vector2i.ZERO)
	_editor.select_placement("founder-workstation")
	await _key(KEY_M)
	_check(_editor.placement_active, "Real M key enters placement preview")
	_check(not _editor.room.prop_node("founder-workstation").visible, "Selected original art is hidden behind translucent preview")
	await _move(Vector2(16, 48 + 144))
	_check(_editor.preview_grid == Vector2i(0, 4), "Mouse motion snaps to 32 px grid")
	_check(not bool(_editor.preview_result.get("valid", true)), "Wall overlap preview is rejected")
	_check((_editor.preview_result.get("errors", []) as Array).size() > 0, "Invalid preview has specific rejection reasons")
	_check(not _editor._candidate.is_empty(), "Invalid preview retains rendered ghost geometry")
	await _capture("editor-invalid-wall.png")
	await _click(Vector2(16, 48 + 144))
	_check(_editor.overrides.is_empty(), "Invalid real click does not change layout")
	_check(_editor.placement_active, "Invalid click keeps placement mode active for correction")
	_check(not _editor.export_layout(OUTPUT + "/uncommitted-preview.json"), "Uncommitted preview cannot be silently exported")
	await _key(KEY_ESCAPE)
	_check(not _editor.placement_active, "Escape cancels preview")
	_check(_editor.room.prop_node("founder-workstation").visible, "Escape restores original prop art")
	_check(_editor.overrides.is_empty(), "Escape preserves committed state")
	_editor.set_stage(0)
	_editor.select_placement("founder-workstation")
	_editor.begin_move()
	var future := _editor.preview_at(Vector2i(29, 18))
	_check(not bool(future.get("valid", true)), "Stage-zero edit cannot break later office growth")
	_check("Stage 4" in "\n".join(future.get("errors", [])), "Future-stage rejection identifies affected stage")
	_editor.cancel_move()
	_editor.set_stage(2)
	_editor.select_placement("founder-workstation")
	await _key(KEY_M)
	var target := original_grid + Vector2i.RIGHT
	var target_point := _editor.ROOM_ORIGIN + _editor.model.world(target)
	await _move(target_point + Vector2(7, 5))
	_check(_editor.preview_grid == target, "Sub-cell pointer movement uses stable snapped anchor")
	_check(bool(_editor.preview_result.get("valid", false)), "Clear adjacent bay produces valid preview")
	await _capture("editor-valid-preview.png")
	await _click(target_point)
	_check(not _editor.placement_active, "Valid real click commits and exits placement mode")
	_check(_editor.overrides.has("founder-workstation"), "Valid placement is stored as a local override")
	_check(_editor.room.prop_node("founder-workstation").position == _editor.model.world(target), "Runtime renderer consumes the same snapped placement")
	_check(_editor._history.size() == 1, "Only successful placement enters undo history")
	await _key(KEY_N)
	await _key(KEY_V)
	_check(_editor.show_routes and _editor.show_visual_bounds, "Real keyboard toggles route and occlusion inspection")
	_check(_editor._routes.size() == _editor._placements.size(), "Every active interaction has an inspection route")
	for route: PackedVector2Array in _editor._routes:
		_check(route.size() >= 2, "Inspection route reaches its station")
	await _capture("editor-placed-routes.png")
	_check(_editor.export_layout(OUTPUT + "/editor-test-layout.json"), "Validated layout exports to the developer output directory")
	_check(FileAccess.file_exists(OUTPUT + "/editor-test-layout.json"), "Export exists for code review")
	var reloaded := OfficeLayout.new()
	_check(reloaded.load_files(OUTPUT + "/editor-test-layout.json"), "Export can be loaded through production room model")
	for stage: int in range(5):
		_check(bool(reloaded.validate_placements(reloaded.resolve_placements(stage)).get("valid", false)), "Reloaded exported stage %d validates" % stage)
	var exported_prop := reloaded.placement_by_id("founder-workstation", 2)
	_check(exported_prop.get("grid") == target, "JSON export preserves edited coordinate")
	_check(exported_prop.get("owner_id") == "founder", "JSON export preserves ownership")
	_check(not _editor.export_layout("res://data/office_layout.json"), "Export refuses to overwrite production layout")
	_check(not _editor.export_layout(OUTPUT + "/../../../../data/office_layout.json"), "Export cannot escape developer output scope")
	_check(FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH) == original_hash, "Editing and export never mutate original layout")
	await _key(KEY_Z, true)
	_check(_editor.overrides.is_empty(), "Ctrl+Z restores original placement state")
	_check(_editor.room.prop_node("founder-workstation").position == _editor.model.world(original_grid), "Undo restores runtime prop anchor")
	_check(_editor._history.is_empty(), "Undo consumes exactly one successful edit")
	await _test_catalog_anchor()
	_check(FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH) == original_hash, "Catalog-anchor fixture never modifies production room JSON")
	if _failures.is_empty():
		print("Office layout editor passed %d checks (real input, previews, rejection, export, reload, undo)." % _checks)
	else:
		for failure: String in _failures:
			push_error(failure)
	_editor.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)

func _test_catalog_anchor() -> void:
	# Nonzero art anchors are supported catalog data. Keep the physical footprint
	# and interaction cells unchanged while proving the preview's visual origin.
	var original_profile: Dictionary = _editor.model.catalog["desk"].duplicate(true)
	var profile := original_profile.duplicate(true)
	var offset := Vector2(12, -4)
	profile["anchor_offset"] = [12, -4]
	_editor.model.catalog["desk"] = profile
	_check(_editor.room.set_placement_overrides({}), "Nonzero catalog art anchor retains valid physical placement")
	_editor._refresh_placements()
	var placement := _editor._placement("founder-workstation")
	var prop := _editor.room.prop_node("founder-workstation")
	var grid_anchor := _editor.model.world(placement.grid)
	_check(prop.position == grid_anchor + offset, "Runtime prop applies the nonzero catalog art anchor")
	_check(_editor._visual_anchor(placement) == prop.global_position, "Ghost anchor equals the actual placed prop anchor")
	var expected_bounds: Rect2 = placement.world_visual_bounds
	_check(_editor._visual_rect(placement) == expected_bounds, "Editor hit/inspection bounds consume resolved visual bounds")
	_check(expected_bounds.position == grid_anchor + offset + placement.visual_bounds.position, "Visual bounds include the catalog offset exactly once")
	_compare_preview_layers(placement, prop)
	# The rightmost strip is inside the offset bounds but outside the old bounds.
	_editor.select_placement("mira-workstation")
	var click_point := _editor.ROOM_ORIGIN + Vector2(expected_bounds.end.x - 2, expected_bounds.get_center().y)
	await _click(click_point)
	_check(_editor.selected_id == "founder-workstation", "Real hit selection uses shifted art bounds, not the unshifted cell center")
	await _key(KEY_M)
	var target: Vector2i = placement.grid + Vector2i.RIGHT
	await _move(_editor.ROOM_ORIGIN + _editor.model.world(target))
	_check(bool(_editor.preview_result.get("valid", false)), "Offset-anchor preview validates after a grid move")
	var ghost := _editor._candidate.duplicate(true)
	var ghost_layers := _editor._preview_layers(ghost)
	_check(_editor._visual_anchor(ghost) == _editor.ROOM_ORIGIN + _editor.model.world(target) + offset, "Preview preserves offset while snapping its physical anchor to the grid")
	await _capture("editor-offset-preview.png")
	await _click(_editor.ROOM_ORIGIN + _editor.model.world(target))
	_check(not _editor.placement_active, "Offset-anchor preview commits through a real click")
	prop = _editor.room.prop_node("founder-workstation")
	placement = _editor._placement("founder-workstation")
	_compare_preview_layers(placement, prop)
	_check(_editor._preview_layers(placement) == ghost_layers, "Committed native layer rectangles equal the prior preview rectangles")
	_check(_editor._visual_rect(placement) == _editor._visual_rect(ghost), "Committed art bounds equal the prior preview bounds")
	await _capture("editor-offset-placed.png")
	# Research uses row one of a different atlas; preview must not default to the
	# workstation row or treat the entire atlas as a single giant prop.
	_compare_preview_layers(_editor._placement("research-bench"), _editor.room.prop_node("research-bench"))
	var research_layers := _editor._preview_layers(_editor._placement("research-bench"))
	_check(research_layers.size() == 2 and research_layers[0].source.position.y == 96, "Research ghost uses its catalog atlas row")
	for current: Dictionary in _editor._placements:
		_compare_preview_layers(current, _editor.room.prop_node(str(current.id)))
	_editor.model.catalog["desk"] = original_profile
	_editor.cancel_move()
	_editor.overrides.clear()
	_check(_editor.room.set_placement_overrides({}), "Catalog-anchor fixture restores the original runtime layout")
	_editor._refresh_placements()

func _compare_preview_layers(placement: Dictionary, prop: Node2D) -> void:
	var layers := _editor._preview_layers(placement)
	var sprites: Array[Sprite2D] = []
	for child: Node in prop.get_children():
		if child is Sprite2D and not child is OfficeAmbientOverlay: sprites.append(child as Sprite2D)
	_check(layers.size() == sprites.size(), "Preview and runtime have the same layer count: " + str(placement.id))
	for index: int in range(mini(layers.size(), sprites.size())):
		var sprite := sprites[index]
		var source := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, sprite.texture.get_size())
		var destination := Rect2(sprite.global_position - source.size * 0.5, source.size)
		_check(layers[index].texture == sprite.texture, "Preview uses the catalog/runtime texture: " + str(placement.id))
		_check(layers[index].source == source, "Preview atlas cell matches the runtime layer: " + str(placement.id))
		_check(layers[index].destination == destination, "Preview native draw rectangle matches the runtime layer: " + str(placement.id))

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _settle(frames: int = 4) -> void:
	for frame: int in range(frames):
		await process_frame

func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)
	await _settle(2)

func _click(point: Vector2) -> void:
	await _move(point)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await _settle(2)

func _key(code: Key, ctrl: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.ctrl_pressed = ctrl
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await _settle(2)

func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var image := root.get_texture().get_image()
	_check(image.save_png(OUTPUT + "/" + filename) == OK, "Rendered evidence saved: " + filename)
