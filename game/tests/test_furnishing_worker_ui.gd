extends SceneTree
## Launched only by harness/test/furnishing-game.test.ts. The room is never
## hydrated from a fixture: every committed state comes from production JSONL.
const MAIN := preload("res://world/main.tscn")
const PLANT := "decor-broadleaf_planter"
const CELL := Vector2i(7, 14)
var game: GameMain
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	call_deferred("run")

func run() -> void:
	if OS.get_environment("STARTUP_VALLEY_FURNISHING_TEST") != "1" or OS.get_environment("STARTUP_VALLEY_FURNISHING_ROOT").is_empty():
		push_error("Use the disposable furnishing-game test launcher")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	# Native rendering and actual GUI hit-testing remain enabled, but this
	# disposable test neither moves the user's pointer nor accepts their input.
	# Apply after engine startup, which resets _initialize-time window flags.
	root.unfocusable = true
	root.mouse_passthrough = true
	root.always_on_top = false
	# The headless DisplayServer has no native window and does not retain these
	# flags; all native runs must still prove both flags were applied.
	if DisplayServer.get_name() != "headless":
		check(root.unfocusable and root.mouse_passthrough, "Native capture input is isolated without grabbing focus or warping the OS pointer")
	game = MAIN.instantiate() as GameMain
	root.add_child(game)
	await until(func() -> bool: return game._state_loaded and game._worker_ready, "Actual worker bootstrap reaches GameMain")
	check(game._employees.is_empty(), "A disposable fresh company has no employees or paid work")
	var expected_json := OS.get_environment("STARTUP_VALLEY_FURNISHING_EXPECTED")
	var expected_value: Variant = JSON.parse_string(expected_json) if not expected_json.is_empty() else null
	if expected_value is Dictionary:
		check(game.worker_client.furnishing_state == expected_value, "Restart bootstrap restores the exact version, revision, inventory, placements and recovery")
		check(game.room.placement_overrides == expected_value.placements, "Scene projection is the saved layout before any UI interaction")
		var founder_grid := OfficeLayout.vector(expected_value.placements["founder-workstation"].grid)
		check(game.room.placement_by_id("founder-workstation").grid == founder_grid, "Legacy founder desk defaults do not overwrite a saved arrangement")
		var player: Dictionary = game._journey.get("player", {})
		check(player.has("x") and player.has("y") and game.player.position == Vector2(float(player.get("x", -1)), float(player.get("y", -1))), "Restart keeps exact safe founder coordinates saved alongside the layout")
	else:
		var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
		var starter_count: int = (library.get("starter_decor", []) as Array).size()
		check(game.worker_client.furnishing_state.inventory.size() == 1 + starter_count, "Founder station and owned starter decorations are bootstrapped")
		check(game.room.visible_prop_count() == 4, "Fresh companies place the phone booth and adjacent café pair")
		check(game.room.prop_node("decor-phone_booth") != null, "Phone booth occupies the southwest lounge bay on a fresh company")
		check(game.room.prop_node("decor-cafe_table") != null and game.room.prop_node("decor-cafe_chair") != null, "Café table and chair render on first bootstrap")
		check(OfficeLayout.vector(game.worker_client.furnishing_state.placements["decor-cafe_table"].grid) == Vector2i(5, 8) and OfficeLayout.vector(game.worker_client.furnishing_state.placements["decor-cafe_chair"].grid) == Vector2i(7, 8), "Starter café is arranged together by the future coffee station")
		for cafe_id: String in ["decor-cafe_table", "decor-cafe_chair"]:
			var bounds: Rect2 = game.room.placement_by_id(cafe_id).world_visual_bounds
			for employee_id: String in ["mira", "theo", "creative"]:
				var arrival := Rect2(game.room.employee_spawn_position(employee_id) - Vector2(24, 72), CharacterArt.FRAME_SIZE)
				check(not bounds.intersects(arrival), "Starter café art clears employee arrival: " + employee_id)
		check(OfficeLayout.vector(game.worker_client.furnishing_state.placements["decor-phone_booth"].grid) != CELL, "First-run lounge never occupies the planter test bay")
	await button_named("Continue" if game.company_panel._company_started() else "Start company", game.company_panel)
	await key(KEY_ESCAPE)
	if not game.company_panel.visible: await key(KEY_ESCAPE)
	check(game.company_panel.visible and game.company_panel.screen == "settings", "Keyboard Escape opens actual Settings")
	await button_named("Renovate office", game.company_panel)
	check(game.office_renovation.active and game._world_paused(), "Normal Settings button opens Renovate and pauses the world")
	await frames(4)
	await capture("open")
	var phase := OS.get_environment("STARTUP_VALLEY_FURNISHING_PHASE")
	if phase == "edit": await edit_room()
	elif phase == "lost_ack": await lose_reply()
	else:
		check(game.office_renovation._committed_state == expected_value, "Renovate opens on the worker's restored state, not old session overrides")
		check(game.office_renovation._history.is_empty(), "Undo history is intentionally local to this visit")
		await select_item(PLANT)
		check(game.office_renovation._ownership.text.contains("1 placed"), "Restarted picker displays actual owned/placed count")
		if phase == "final_restart" and DisplayServer.get_name() != "headless": await scaled_views()
	await key(KEY_ESCAPE)
	check(not game.office_renovation.active, "Escape exits Renovate without a second modal underneath")
	print("FURNISHING_SNAPSHOT " + JSON.stringify(game.worker_client.furnishing_state))
	if failures.is_empty(): print("FURNISHING WORKER UI PASS: %s, %d checks" % [phase, checks])
	for failure: String in failures: push_error(failure)
	game.queue_free()
	await frames(4)
	quit(0 if failures.is_empty() else 1)

func edit_room() -> void:
	var renovate := game.office_renovation
	var initial_revision := int(renovate._committed_state.revision)
	var initial_position := game.player.position
	await select_item(PLANT)
	check(renovate._ownership.text.contains("1 in storage") and renovate._move_button.text.begins_with("Place"), "Stored item has explicit ownership and Place action")
	await capture("stored-picker")
	await click(renovate._move_button.get_global_rect().get_center())
	check(renovate.placement_active, "Real Place button starts preview")
	await motion(game.room.layout_model.world(CELL))
	check(bool(renovate.preview_result.get("valid", false)), "Decor preview has valid floor, wall, route and future-hire clearance")
	await capture("valid-preview")
	await commit_pointer(initial_revision + 1)
	check(game.player.position == initial_position and game.player.route.is_empty(), "Placement clicks never leak into founder movement")
	check(renovate._history.size() == 1, "Rapid duplicate input creates exactly one Undo step")
	check(game.room.prop_node(PLANT) != null and not game.room.navigation.walkable(CELL), "Committed decoration adds actual art and navigation collision")
	await capture("saved-" + str(game.room.placement_by_id(PLANT).facing))
	var seen: Array[String] = [str(game.room.placement_by_id(PLANT).facing)]
	for _index: int in range(3):
		await key(KEY_R)
		check(renovate.placement_active and bool(renovate.preview_result.get("valid", false)), "Real R previews another accepted facing")
		await commit_pointer(int(renovate._committed_state.revision) + 1)
		seen.append(str(game.room.placement_by_id(PLANT).facing))
		await capture("saved-" + str(game.room.placement_by_id(PLANT).facing))
		for child: Node in game.room.prop_node(PLANT).get_children():
			if child is Sprite2D: check(child.scale == Vector2.ONE and child.rotation == 0 and not child.flip_h and not child.flip_v, "Saved facing uses native untransformed art")
	seen.sort()
	check(seen == ["east", "north", "south", "west"], "All four authored directions survive real UI and worker validation")
	await capture("four-directions-saved")
	var placed: Dictionary = renovate._committed_state.placements.duplicate(true)
	var revision := int(renovate._committed_state.revision)
	await click(renovate._store_button.get_global_rect().get_center())
	await saved(revision + 1)
	check(not renovate._committed_state.placements.has(PLANT) and game.room.prop_node(PLANT) == null, "Store removes placement and world art, not ownership")
	check(renovate._committed_state.inventory.size() == 4 and renovate._ownership.text.contains("1 in storage"), "Storage retains exactly one owned decoration")
	await capture("stored-again")
	await key(KEY_U)
	await saved(revision + 2)
	check(renovate._committed_state.placements == placed, "Keyboard Undo durably restores the exact previous layout")
	await select_item("founder-workstation")
	check(renovate._store_button.disabled, "Required founder station cannot be stored")
	await key(KEY_M)
	await key(KEY_UP)
	check(renovate.preview_grid == Vector2i(8, 16) and bool(renovate.preview_result.get("valid", false)), "Keyboard movement produces a valid non-default desk position")
	revision = int(renovate._committed_state.revision)
	await key(KEY_ENTER)
	await saved(revision + 1)
	check(game.room.placement_by_id("founder-workstation").grid == Vector2i(8, 16), "Enter commits moved founder desk through the worker")
	var before_invalid := renovate._committed_state.duplicate(true)
	await key(KEY_M)
	await click(game.room.layout_model.world(Vector2i(0, 4)))
	check(renovate.placement_active and not bool(renovate.preview_result.get("valid", true)), "Wall placement is rejected by real input")
	await capture("invalid-wall-preview")
	check(renovate._committed_state == before_invalid and not renovate._save_pending, "Invalid preview dispatches no save and keeps exact committed state")
	await key(KEY_ESCAPE)
	check(not renovate.placement_active and game.room.prop_node("founder-workstation").visible, "Escape cancels invalid preview and restores committed pixels")
	check(renovate._status.text.to_lower().contains("cancel") and not renovate._status.text.contains("click to place"), "Cancel replaces placement instructions with truthful saved-room feedback")
	game.worker_client.refresh_furnishing()
	await frames(30)
	check(renovate._committed_state == before_invalid, "Repeated actual bootstrap does not alter furnishings")
	check(renovate._committed_state.revision == initial_revision + 7, "Only seven successful player mutations advance the revision")

func lose_reply() -> void:
	var renovate := game.office_renovation
	var before := renovate._committed_state.duplicate(true)
	await select_item(PLANT)
	await key(KEY_M)
	await key(KEY_RIGHT)
	check(renovate.preview_grid == CELL + Vector2i.RIGHT and bool(renovate.preview_result.get("valid", false)), "Lost-ack scenario moves an owned decoration to a valid new cell")
	await key(KEY_ENTER)
	await until(func() -> bool: return game.worker_client._restart_count == 1 and game._worker_ready and int(game.worker_client.furnishing_state.get("revision", -1)) == int(before.revision) + 1 and not renovate._save_pending, "Actual worker exit after commit recovers through automatic restart/bootstrap")
	check(OfficeLayout.vector(renovate._committed_state.placements[PLANT].grid) == CELL + Vector2i.RIGHT, "Lost response never loses the already-committed placement")
	check(renovate._pending_mutation.is_empty(), "Authoritative matching bootstrap resolves an interrupted pending transaction")
	check(renovate._committed_state.inventory == before.inventory, "Recovery neither duplicates nor loses owned items")
	check(renovate._history.size() == 1, "Recovered commit has one local Undo step")
	await capture("lost-ack-recovered")

func commit_pointer(revision: int) -> void:
	var renovate := game.office_renovation
	var before := renovate._committed_state.duplicate(true)
	var point := game.room.layout_model.world(renovate.preview_grid)
	await motion(point)
	pointer(point, true)
	check(renovate._save_pending and renovate._status.text.contains("Saving"), "Button down provides immediate truthful pending feedback")
	check(renovate._committed_state == before and game.room.placement_overrides == before.placements, "No optimistic saved state appears before worker acknowledgement")
	check(renovate._move_button.disabled and renovate._rotate_button.disabled and renovate._done_button.disabled, "Mutation controls and Done are disabled while saving")
	pointer(point, false)
	pointer(point, true)
	pointer(point, false)
	key_event(KEY_ENTER, true)
	key_event(KEY_ENTER, false)
	check(renovate._save_pending, "Rapid double click and Enter cannot start a competing action")
	await capture("pending-confirmation")
	check(renovate._save_pending, "Captured pending frame is still awaiting the real acknowledgement")
	await saved(revision)
	check(renovate._status.text.contains("saved") and not renovate.placement_active, "Only worker acknowledgement produces Saved and exits preview")

func saved(revision: int) -> void:
	await until(func() -> bool: return not game.office_renovation._save_pending and int(game.office_renovation._committed_state.get("revision", -1)) == revision, "Worker confirms durable revision %d" % revision)

func select_item(id: String) -> void:
	var picker := game.office_renovation._prop_picker
	var index := -1
	for item: int in range(picker.item_count):
		if str(picker.get_item_metadata(item)) == id: index = item
	check(index >= 0, "Owned picker contains " + id)
	if index < 0: return
	await click(picker.get_global_rect().get_center())
	# Headless embedded popups have no physical OS pointer. Keep the fallback
	# as genuine focused keyboard input, never emit item_selected directly.
	if not picker.get_popup().visible and DisplayServer.get_name() == "headless": await key(KEY_SPACE)
	check(picker.get_popup().visible, "Pointer/focused keyboard input opens the actual dropdown")
	if id == PLANT:
		var popup := picker.get_popup()
		var style := popup.get_theme_stylebox("panel")
		var top := style.get_content_margin(SIDE_TOP)
		var bottom := style.get_content_margin(SIDE_BOTTOM)
		# This owned-item menu has uniform single-line rows with no separators.
		# Hit-test the visible target row; never emit PopupMenu.id_pressed.
		var height := (float(popup.size.y) - top - bottom) / float(picker.item_count)
		var point := Vector2(popup.position) + Vector2(popup.size.x * 0.5, top + (index + 0.5) * height)
		await capture("dropdown-open")
		await click(point)
		check(game.office_renovation.selected_id == id, "Actual pointer selection chooses " + id)
	else:
		for _step: int in range(picker.item_count + 1):
			if picker.get_popup().get_focused_item() == index: break
			await key(KEY_DOWN)
		check(picker.get_popup().get_focused_item() == index, "Real arrows focus the requested furnishing")
		await key(KEY_ENTER)
		check(game.office_renovation.selected_id == id, "Keyboard dropdown selection chooses " + id)
	check(not picker.get_popup().visible, "Selection closes popup and restores game focus")

func button_named(text: String, parent: Node) -> void:
	await frames(4)
	var button := find_button(parent, text)
	check(button != null, "Normal UI exposes " + text)
	if button != null: await click(button.get_global_rect().get_center())

func find_button(parent: Node, text: String) -> Button:
	if parent is Button and parent.text == text: return parent as Button
	for child: Node in parent.get_children():
		var result := find_button(child, text)
		if result != null: return result
	return null

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FURNISHING_CHECK_FAILED " + message)

func until(condition: Callable, message: String) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while not bool(condition.call()) and Time.get_ticks_msec() < deadline: await process_frame
	check(bool(condition.call()), message)

func frames(count: int = 2) -> void:
	for _index: int in range(count): await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	# UI redraw commands are queued until the next frame. Sampling inside the
	# input callback would retain the prior label/button rendering.
	await process_frame
	# A background native window can suppress automatic draw notifications.
	# Force the settled scene frame without changing simulation or input state.
	RenderingServer.force_draw(false)
	var path := OS.get_environment("STARTUP_VALLEY_FURNISHING_ROOT") + "/" + OS.get_environment("STARTUP_VALLEY_FURNISHING_PHASE") + "-" + name + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "Native screenshot saved: " + name)

func scaled_views() -> void:
	var renovate := game.office_renovation
	var before := renovate._committed_state.duplicate(true)
	var cases: Array = []
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(2560, 1440), Vector2i(1600, 1000)]:
		root.size = size
		await frames(6)
		var label := "scale-%dx%d" % [size.x, size.y]
		var transform := root.get_final_transform()
		check(root.size == size and root.get_visible_rect().size == Vector2(1280, 720), label + " preserves internal 1280x720 composition")
		check(is_equal_approx(transform.x.length(), transform.y.length()), label + " remains aspect preserving")
		var rectangles := {}
		for name: String in ["_panel", "_preview_panel", "_prop_picker", "_facing_picker", "_ownership", "_move_button", "_rotate_button", "_store_button", "_undo_button", "_cancel_button", "_done_button", "_status"]:
			var control := renovate.get(name) as Control
			var rect := control.get_global_rect()
			check(Rect2(0, 0, 1150, 720).encloses(rect), label + ": complete " + name + " stays inside playfield")
			rectangles[name] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		await capture(label + "-open")
		await click(renovate._prop_picker.get_global_rect().get_center())
		check(renovate._prop_picker.get_popup().visible, label + " actual scaled pointer opens the furnishing dropdown")
		await capture(label + "-popup")
		await key(KEY_ESCAPE)
		check(renovate.active and not renovate._prop_picker.get_popup().visible, label + " Escape closes only the popup")
		await key(KEY_M)
		await motion(game.room.layout_model.world(Vector2i(8, 14)))
		check(renovate.placement_active and renovate.preview_grid == Vector2i(8, 14) and bool(renovate.preview_result.get("valid", false)), label + " scaled world pointer reaches a valid placement cell")
		await capture(label + "-preview")
		await key(KEY_ESCAPE)
		check(not renovate.placement_active and renovate._committed_state == before, label + " cancel keeps durable layout untouched")
		check(renovate._status.text.to_lower().contains("cancel") and not renovate._status.text.contains("click to place"), label + " canceled preview cannot retain a click-to-place instruction")
		var content := transform * Rect2(0, 0, 1280, 720)
		var texture_size := root.get_texture().get_size()
		cases.append({"window_size": [size.x, size.y], "texture_size": [texture_size.x, texture_size.y], "content_window_rect": [content.position.x, content.position.y, content.size.x, content.size.y], "control_rectangles": rectangles, "fullscreen": false})
	root.size = Vector2i(1280, 720)
	await frames(4)
	var path := OS.get_environment("STARTUP_VALLEY_FURNISHING_ROOT") + "/final_restart-scaling.json"
	var output := FileAccess.open(path, FileAccess.WRITE)
	output.store_string(JSON.stringify({"cases": cases, "failures": failures}, "  ") + "\n")
	output.close()

func motion(point: Vector2) -> void:
	# The capture-only window ignores external native input. Dispatch the
	# test's pointer through Input and normal GUI hit-testing, never an OS warp.
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * point
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames()

func pointer(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = root.get_final_transform() * point
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	# Update both viewport dispatch and Input's held-button state. PopupMenu
	# relies on the latter; Viewport.push_input alone falsely closes on release.
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func click(point: Vector2) -> void:
	await motion(point)
	for down: bool in [true, false]:
		pointer(point, down)
		await process_frame
	await frames()

func key_event(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func key(code: Key) -> void:
	for down: bool in [true, false]:
		key_event(code, down)
		await process_frame
	await frames()
