extends SceneTree
## Safe interactive browser; smoke mode is separate from normal play.
const FIXTURE := preload("res://tools/furniture_catalogue_fixture.gd")
const ENTRY := preload("res://tools/play_passive_furniture.gd")
const OUTPUT := "res://tests/output/furniture-catalogue/"
var fixture: Node
var late_layout: Node
var force_smoke := false
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var retired_models: Array[OfficeLayout] = []
var switches := 0
var layout_ticks := 0
var switching := false
var pending_kind := ""

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for tick: int in range(count): await process_frame

func _switch_requested(kind: String) -> void:
	if kind not in FIXTURE.FAMILIES: return
	pending_kind = kind
	if switching: return
	switching = true
	call_deferred("_apply_requested")

func _apply_requested() -> void:
	var kind := pending_kind
	pending_kind = ""
	replace_fixture(kind)

func replace_fixture(kind: String) -> void:
	if kind not in FIXTURE.FAMILIES:
		switching = false
		return
	if is_instance_valid(fixture):
		fixture.editor.cancel_move()
		retired_models.append(fixture.model)
		fixture.free()
		fixture = null
	fixture = FIXTURE.new()
	fixture.hires = 4
	fixture.prototype_kind = kind
	fixture.prototype_requested.connect(_switch_requested)
	root.add_child(fixture)
	if not fixture.ready_ok:
		push_error(str(fixture.errors))
		fixture.free()
		fixture = null
		quit(1)
		return
	switches += 1
	switching = false

func _late_labels() -> void:
	if not is_instance_valid(fixture) or not fixture.ready_ok: return
	layout_ticks += 1
	fixture.disable_worker_controls()
	fixture.place_editor_labels()
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor._label_layer.queue_redraw()
	# A native popup owns arrows while open; Input's polled state must not move
	# the founder beneath it. Production input resumes through GameMain on close.
	if fixture.editor._prop_picker.get_popup().visible or fixture.editor._facing_picker.get_popup().visible:
		fixture.main.player.input_blocked = true
		for actor: EmployeeAvatar in fixture.main._employees.values(): actor.world_paused = true

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await frames(1)
	await frames(1)

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await frames()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await frames(1)
	await frames()

func capture(name_value: String) -> void:
	await frames(3)
	var toolbar: Rect2 = fixture.editor._inspector.get_parent().get_global_rect()
	check(Rect2(0, 0, 1150, 720).encloses(toolbar), name_value + ": toolbar fits playfield outside rail")
	for node: Node in fixture.editor._inspector.get_children():
		if node is Label and node.visible:
			var label := node as Label
			var line_bottom := label.global_position.y + label.get_line_height() * label.get_line_count()
			check(line_bottom <= toolbar.end.y - 6, name_value + ": actual toolbar text lines fit paper")
	for control: Control in [fixture.editor._prop_picker, fixture.editor._facing_picker, fixture.editor._move_button, fixture.editor._cancel_button]:
		check(toolbar.encloses(control.get_global_rect()), name_value + ": native control stays within paper")
	for actor: EmployeeAvatar in fixture.main._employees.values():
		if not actor.labels_suppressed:
			check(not actor.world_label_rect().intersects(toolbar), name_value + ": full actor card/pointer avoids toolbar")
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(OUTPUT + name_value + ".png") == OK, "Save " + name_value)
	captures.append(name_value + ".png")

func choose(index: int) -> void:
	var picker: OptionButton = fixture.editor._prop_picker
	picker.grab_focus()
	await key(KEY_SPACE)
	var popup := picker.get_popup()
	check(popup.visible, "Real input opens prototype menu")
	for attempt: int in range(6):
		if popup.get_focused_item() == index: break
		await key(KEY_DOWN)
	check(popup.get_focused_item() == index, "Real arrows focus requested prototype")
	await key(KEY_ENTER)
	await frames(4)
	check(fixture.prototype_kind == FIXTURE.FAMILIES[index], "Native menu selects the requested prototype")
	for model: OfficeLayout in retired_models: check(not model.calibration_preview_enabled(), "Switch revokes prior local owner")
	check(fixture.main.player.route.is_empty(), "Prototype UI input never creates a world route")

func smoke() -> void:
	for index: int in range(FIXTURE.FAMILIES.size()):
		if index > 0: await choose(index)
		var kind: String = FIXTURE.FAMILIES[index]
		check(fixture.ready_ok, kind + ": isolated fixture ready")
		check(fixture.editor._prop_picker.item_count == 4 and fixture.editor._facing_picker.item_count == 4, "Four clear prototype names and four facings")
		check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1 and not fixture.main._state_loaded, "No worker transport or saved company")
		check(fixture.main.job_panel._settings_button.disabled and fixture.main.job_panel._assign_button.disabled and fixture.main.job_panel._chat_send_button.disabled, "Connect and paid-work controls are inert in preview")
		var staged := 0
		for prop: Dictionary in fixture.main.room.resolved_placements:
			if str(prop.kind) in FIXTURE.FAMILIES: staged += 1
		check(staged == 1, "Exactly one prototype in room, never a pile")
		check(fixture.editor._history.is_empty(), "Switch starts with empty local Undo history")
		var placement: Dictionary = fixture.main.room.placement_by_id(FIXTURE.PROTOTYPE_ID)
		var prop: Node2D = fixture.main.room.prop_node(FIXTURE.PROTOTYPE_ID)
		for layer: Dictionary in placement.render_layers:
			var sprite := prop.get_node(str(layer.name)) as Sprite2D
			check(sprite.scale == Vector2.ONE and sprite.rotation == 0 and not sprite.flip_h and not sprite.flip_v, "Registered source stays native without bitmap rotation")
		for cell: Vector2i in placement.occupied: check(not fixture.main.room.navigation.walkable(cell), "Prototype occupied cell blocks actual navigation")
		await capture(kind + "-south")
		for turn: int in range(3):
			root.gui_release_focus()
			await key(KEY_R)
			check(fixture.editor.placement_active and fixture.editor.preview_result.valid, "R previews valid authored direction")
			var facing: String = fixture.editor.preview_facing
			await click(fixture.model.world(fixture.editor.preview_grid))
			check(not fixture.editor.placement_active and fixture.main.room.placement_by_id(FIXTURE.PROTOTYPE_ID).facing == facing, "Click commits " + facing)
			await capture(kind + "-" + facing)
		var before: Dictionary = fixture.main.room.placement_overrides.duplicate(true)
		await key(KEY_M)
		await click(fixture.model.world(Vector2i(1, 3)))
		check(fixture.editor.placement_active and not fixture.editor.preview_result.valid and fixture.main.room.placement_overrides == before, "Wall collision rejects without changing layout")
		await capture(kind + "-invalid-wall")
		await key(KEY_ESCAPE)
		check(not fixture.editor.placement_active and fixture.main.room.placement_overrides == before, "Escape restores committed native prop")
		var destination := Vector2i(-1, -1)
		for cell: Vector2i in [Vector2i(21, 15), Vector2i(22, 14), Vector2i(20, 15), Vector2i(23, 14)]:
			var candidate := before.duplicate(true)
			candidate[FIXTURE.PROTOTYPE_ID] = {"grid": [cell.x, cell.y], "facing": fixture.editor.preview_facing}
			if fixture.editor.validate_all_stages(candidate).valid and fixture.main.room.placement_actor_conflicts(candidate).is_empty():
				destination = cell
				break
		check(destination.x >= 0, "A real unoccupied local destination is available")
		await key(KEY_M)
		await click(fixture.model.world(destination))
		check(not fixture.editor.placement_active and fixture.main.room.placement_overrides != before, "Actual Move and click change the local cell")
		await key(KEY_U)
		check(fixture.main.room.placement_overrides == before, "Actual Undo restores exact prior cell and facing")
		await capture(kind + "-undo")
		check(not fixture.editor.export_layout() and fixture.editor.last_export_path.is_empty(), "No candidate layout export")
	await choose(0)
	check(fixture.main.room.placement_overrides.is_empty(), "Returning to a prototype resets unsaved layout as disclosed")
	var prior_switches := switches
	# Three UI requests arriving before the deferred replacement coalesce. These
	# test lifecycle ordering, separately from the real menu events above.
	_switch_requested(FIXTURE.FAMILIES[1])
	_switch_requested(FIXTURE.FAMILIES[2])
	_switch_requested(FIXTURE.FAMILIES[3])
	await frames(3)
	check(switches == prior_switches + 1 and fixture.prototype_kind == FIXTURE.FAMILIES[3], "Rapid A/B/C requests create only the final requested fixture")
	check(fixture.main._employees.size() == 2 and root.get_child_count() == 2, "Rapid selection does not duplicate actors or scene owners")
	for model: OfficeLayout in retired_models: check(not model.calibration_preview_enabled(), "Rapid selection leaves only the newest owner admitted")
	check(layout_ticks > 20, "Late toolbar label placement remains active")
	await capture("final-catalogue")
	retired_models.append(fixture.model)
	late_layout.free()
	fixture.free()
	fixture = null
	await frames(3)
	for model: OfficeLayout in retired_models: check(not model.calibration_preview_enabled(), "Closing revokes every local permit")
	check(root.get_child_count() == 0, "No fixture or late-layout node left behind")
	var file := FileAccess.open(OUTPUT + ("headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "switches": switches, "layout_ticks": layout_ticks, "worker_started": false, "production_opt_in": false, "source_art_changed": false}, "  "))
	file.close()
	print("Furniture catalogue: %d checks / %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	var smoke_mode := force_smoke or OS.get_cmdline_user_args().has("--smoke-test")
	if DisplayServer.get_name() == "headless" and not smoke_mode:
		push_error("Interactive catalogue needs a window; use --smoke-test for automated checks.")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.title = "Startup Valley — prototype catalogue (no worker or saves)"
	replace_fixture(FIXTURE.FAMILIES[0])
	if not is_instance_valid(fixture): return
	late_layout = ENTRY.LateLabelLayout.new()
	late_layout.process_priority = 10000
	late_layout.layout = _late_labels
	root.add_child(late_layout)
	if smoke_mode:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
		await frames(5)
		await smoke()
