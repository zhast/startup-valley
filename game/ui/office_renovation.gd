class_name OfficeRenovation
extends Node2D

## Player-facing office placement. This deliberately consumes the
## same resolved profiles and validation used by the room; it never rotates,
## mirrors, scales, or invents a missing directional bitmap.
signal closed
signal save_requested(operation_id: String, expected_revision: int, placements: Dictionary, actor_cells: Array)

const VALID := Color("c1fa81")
const INVALID := Color("fa4616")
const INK := Color("514334")

var game: GameMain
var active := false
var placement_active := false
var selected_id := ""
var preview_grid := Vector2i.ZERO
var preview_facing := "south"
var preview_result: Dictionary = {}
var _candidate: Dictionary = {}
var _placements: Array[Dictionary] = []
var _history: Array[Dictionary] = []
var _texture_cache: Dictionary[String, Texture2D] = {}
var _committed_state: Dictionary = {}
var _pending_mutation: Dictionary = {}
var _save_pending := false
var _transport_available := false
var _pending_undo := false
var _last_save_error := ""
var _preview_panel: PanelContainer
var _preview_canvas: Control
var _ownership: Label
var _store_button: Button
var _cancel_button: Button
var _retry_button: Button

var _layer: CanvasLayer
var _input_surface: Control
var _panel: PanelContainer
var _prop_picker: OptionButton
var _facing_picker: OptionButton
var _move_button: Button
var _rotate_button: Button
var _undo_button: Button
var _done_button: Button
var _status: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_as_relative = false
	z_index = 1900
	_build_interface()
	_layer.hide()
	hide()

func _build_interface() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 180
	add_child(_layer)
	_input_surface = Control.new()
	_input_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_input_surface.theme = GameFonts.interface_theme()
	_input_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_input_surface.focus_mode = Control.FOCUS_ALL
	_input_surface.mouse_default_cursor_shape = Control.CURSOR_CROSS
	_input_surface.gui_input.connect(_on_world_gui_input)
	_layer.add_child(_input_surface)
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 540)
	_panel.size = Vector2(1110, 168)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 9, 12, 9)))
	_input_surface.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	_panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	column.add_child(row)
	_prop_picker = OptionButton.new()
	_prop_picker.custom_minimum_size = Vector2(310, 44)
	_prop_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_picker.tooltip_text = "Choose an owned furnishing. Stored decorations can be placed again."
	CozyUI.dropdown(_prop_picker)
	_prop_picker.item_selected.connect(_on_prop_selected)
	row.add_child(_prop_picker)
	_facing_picker = OptionButton.new()
	_facing_picker.custom_minimum_size = Vector2(118, 42)
	_facing_picker.tooltip_text = "Only reviewed, authored directions are listed."
	CozyUI.dropdown(_facing_picker)
	_facing_picker.item_selected.connect(_on_facing_selected)
	row.add_child(_facing_picker)
	_ownership = Label.new()
	_ownership.custom_minimum_size = Vector2(470, 28)
	CozyUI.label(_ownership, "meta")
	row.add_child(_ownership)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	column.add_child(actions)
	_move_button = _button("Move  M", begin_move, actions)
	_rotate_button = _button("Rotate  R", rotate_preview, actions)
	_store_button = _button("Store", store_selected, actions)
	_undo_button = _button("Undo  U", undo, actions)
	_cancel_button = _button("Cancel", cancel_preview, actions)
	_retry_button = _button("Retry save", retry_save, actions)
	_done_button = _button("Done", close, actions, "primary")
	_status = Label.new()
	_status.custom_minimum_size = Vector2(1060, 28)
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status.tooltip_text = ""
	CozyUI.label(_status, "meta")
	column.add_child(_status)
	_preview_panel = PanelContainer.new()
	_preview_panel.position = Vector2(920, 90)
	_preview_panel.custom_minimum_size = Vector2(210, 264)
	_preview_panel.add_theme_stylebox_override("panel", CozyUI.paper())
	_input_surface.add_child(_preview_panel)
	var preview_column := VBoxContainer.new()
	_preview_panel.add_child(preview_column)
	var preview_label := Label.new()
	preview_label.text = "Furnishing preview"
	CozyUI.label(preview_label, "body")
	preview_column.add_child(preview_label)
	_preview_canvas = Control.new()
	_preview_canvas.custom_minimum_size = Vector2(186, 208)
	_preview_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_canvas.draw.connect(_draw_picker_preview)
	preview_column.add_child(_preview_canvas)

func _button(copy: String, callback: Callable, parent: Control, variant: String = "secondary") -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size = Vector2(132, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	CozyUI.button(button, variant)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func open() -> void:
	if game == null or game.room == null or game.room.layout_model == null: return
	active = true
	placement_active = false
	_candidate.clear()
	_history.clear()
	_refresh_placements()
	if _placements.is_empty():
		_set_status("No unlocked furniture is available to renovate.", false)
	else:
		select_placement(str(_placements[0].get("id", "")))
		_set_status("Choose a furnishing. Move or rotate it; click to place. Changes save to your company.", true)
	if not _can_save(): _set_status("Office preview only. Reconnect the worker to save furnishings.", false)
	elif not str(_committed_state.get("recovery", "")).is_empty(): _set_status(str(_committed_state.recovery), false)
	show()
	_layer.show()
	_prop_picker.grab_focus()
	queue_redraw()

func close() -> void:
	if not active: return
	if _save_pending:
		_set_status("Saving the office… wait for confirmation before closing Renovate.", true)
		return
	cancel_preview()
	active = false
	_layer.hide()
	hide()
	closed.emit()

func reset_layout() -> void:
	_save_pending = false
	_pending_mutation.clear()
	if active: close()
	_history.clear()
	# New Company bootstrap already supplied its authoritative new layout.

func select_placement(id: String) -> void:
	if _save_pending: return
	if placement_active: cancel_preview()
	var placement := _placement(id)
	if placement.is_empty(): return
	selected_id = id
	preview_grid = placement.get("grid", Vector2i.ZERO)
	preview_facing = str(placement.get("facing", "south"))
	for index: int in range(_prop_picker.item_count):
		if str(_prop_picker.get_item_metadata(index)) == id:
			_prop_picker.select(index)
	_refresh_facing_picker(placement)
	_refresh_controls()

func begin_move() -> void:
	if not active or selected_id.is_empty() or _save_pending: return
	placement_active = true
	var prop := game.room.prop_node(selected_id)
	if prop != null: prop.hide()
	preview_at(preview_grid)
	_input_surface.grab_focus()
	_refresh_controls()

func rotate_preview() -> void:
	if not active or selected_id.is_empty() or _save_pending: return
	var facings := _available_facings()
	if facings.size() < 2:
		_set_status("This furniture has only one reviewed view. A bitmap rotation is never substituted.", false)
		return
	if not placement_active: begin_move()
	var index := facings.find(preview_facing)
	preview_facing = facings[(maxi(index, 0) + 1) % facings.size()]
	for option: int in range(_facing_picker.item_count):
		if str(_facing_picker.get_item_metadata(option)) == preview_facing:
			_facing_picker.select(option)
	preview_at(preview_grid)

func preview_at(grid: Vector2i) -> Dictionary:
	preview_grid = grid
	var proposed := _with_candidate()
	preview_result = _validate_all_stages(proposed)
	var conflicts := game.room.placement_actor_conflicts(proposed)
	var occupied_owner := _current_workstation_occupant()
	if not occupied_owner.is_empty() and not conflicts.any(func(value: Dictionary) -> bool: return str(value.get("actor_id", "")) == str(occupied_owner.actor_id)):
		conflicts.append(occupied_owner)
	preview_result["actor_conflicts"] = conflicts
	for conflict: Dictionary in conflicts:
		preview_result.errors.append(_actor_conflict_message(conflict))
	preview_result["valid"] = preview_result.errors.is_empty()
	_candidate.clear()
	for placement: Dictionary in game.room.layout_model.resolve_placements(game.room.unlocked_hires, proposed):
		if str(placement.get("id", "")) == selected_id:
			_candidate = placement
			break
	var errors: Array = preview_result.get("errors", [])
	if bool(preview_result.get("valid", false)):
		_set_status("Valid position — click to place. Walls, routes, interactions, and future unlocks remain clear.", true)
	else:
		_set_status(_friendly_error(errors[0]) if not errors.is_empty() else "That position is unavailable.", false)
	_status.tooltip_text = "\n".join(errors)
	queue_redraw()
	return preview_result

func _current_workstation_occupant() -> Dictionary:
	var committed := _placement(selected_id)
	var owner_id := str(committed.get("owner_id", ""))
	if owner_id.is_empty() or not game._employees.has(owner_id) or not committed.has("work_position"): return {}
	var employee := game._employees[owner_id] as EmployeeAvatar
	if employee == null or employee._has_target or employee.position.distance_to(Vector2(committed.work_position) + game.room.global_position) > 1.0: return {}
	return {"actor_id": owner_id, "display_name": employee.display_name, "position": employee.position, "placement_id": selected_id}

func commit_preview() -> bool:
	if not active or not placement_active or _save_pending: return false
	preview_at(preview_grid)
	if not bool(preview_result.get("valid", false)): return false
	var proposed := _with_candidate()
	return _submit_layout(proposed, false)

func cancel_preview() -> void:
	if _save_pending: return
	var was_placing := placement_active
	placement_active = false
	_candidate.clear()
	var committed := _placement(selected_id)
	if not committed.is_empty():
		preview_grid = committed.get("grid", preview_grid)
		preview_facing = str(committed.get("facing", preview_facing))
		var prop := game.room.prop_node(selected_id) if game != null and game.room != null else null
		if prop != null: prop.show()
		_refresh_facing_picker(committed)
	if was_placing: _set_status("Placement canceled. Your saved room is unchanged.", true)
	_refresh_controls()
	queue_redraw()

func undo() -> void:
	if _save_pending: return
	if placement_active: cancel_preview()
	if _history.is_empty():
		_set_status("Nothing to undo in this renovation visit.", true)
		return
	var previous := _history[-1] as Dictionary
	var conflicts := game.room.placement_actor_conflicts(previous)
	if not conflicts.is_empty():
		_set_status("Undo paused. " + _actor_conflict_message(conflicts[0]), false)
		return
	_submit_layout(previous, true)
func _with_candidate() -> Dictionary:
	var proposed: Dictionary = _committed_state.get("placements", game.room.placement_overrides).duplicate(true)
	proposed[selected_id] = {"grid": [preview_grid.x, preview_grid.y], "facing": preview_facing}
	return proposed

func _can_save() -> bool:
	return _transport_available and int(_committed_state.get("version", 0)) == 1

func receive_state(state: Dictionary, operation_id: String = "") -> void:
	if int(state.get("version", 0)) != 1: return
	_transport_available = true
	var was_pending := not _pending_mutation.is_empty()
	var acknowledged: bool = was_pending and operation_id == str(_pending_mutation.operationId)
	var matches: bool = was_pending and _same_placements(state.get("placements", {}), _pending_mutation.placements) and (acknowledged or int(state.get("revision", 0)) > int(_pending_mutation.expectedRevision))
	if matches:
		if _pending_undo:
			if not _history.is_empty(): _history.pop_back()
		else:
			_history.append(_pending_mutation.previous.duplicate(true))
	elif was_pending and (operation_id.is_empty() or acknowledged):
		# Bootstrap is authoritative after a disconnect. Retain a failed request
		# for explicit idempotent Retry unless another change superseded it.
		_save_pending = false
		if acknowledged or int(state.get("revision", 0)) != int(_pending_mutation.expectedRevision):
			_pending_mutation.clear()
			_last_save_error = "The office changed. Its saved layout is restored; choose a new placement."
	_committed_state = state.duplicate(true)
	if matches:
		_save_pending = false
		_pending_mutation.clear()
		placement_active = false
		_candidate.clear()
		_pending_undo = false
		_last_save_error = ""
	elif not was_pending:
		placement_active = false
		_candidate.clear()
	if active:
		_refresh_placements()
		if not _save_pending: select_placement(selected_id)
		var recovery := str(state.get("recovery", ""))
		_set_status(recovery if not recovery.is_empty() else ("Office saved. Your arrangement will be here when you return." if matches else "Saved office restored."), recovery.is_empty())
		if was_pending and not matches: _set_status(_last_save_error if not _last_save_error.is_empty() else "Saved room restored. Retry the last change or choose a new placement.", false)
		queue_redraw()

static func _same_placements(left: Dictionary, right: Dictionary) -> bool:
	# JSON numbers arrive as floats, while a snapped preview uses integers.
	# Compare the authored grid/facing values, not Variant container types.
	if left.size() != right.size(): return false
	for id: Variant in left:
		if not right.has(id) or not left[id] is Dictionary or not right[id] is Dictionary: return false
		if OfficeLayout.vector(left[id].get("grid")) != OfficeLayout.vector(right[id].get("grid")): return false
		if str(left[id].get("facing", "")) != str(right[id].get("facing", "")): return false
	return true

func save_failed(operation_id: String, message: String) -> void:
	if not _pending_mutation.is_empty() and not operation_id.is_empty() and operation_id != str(_pending_mutation.operationId): return
	_save_pending = false
	_last_save_error = message
	# Keep the operation ID: Retry is the same transaction even after lost ack.
	cancel_preview()
	_set_status(message, false)
	_refresh_controls()

func connection_lost() -> void:
	_transport_available = false
	_save_pending = false
	_set_status("Worker disconnected. The last saved room is kept; reconnect to check the latest save.", false)
	_refresh_controls()

func _submit_layout(proposed: Dictionary, is_undo: bool) -> bool:
	if not _can_save():
		_set_status("Reconnect the worker before saving furnishings. The saved room is unchanged.", false)
		return false
	if not bool(_validate_all_stages(proposed).get("valid", false)):
		_set_status("That layout blocks furniture or access. Nothing was saved.", false)
		return false
	var conflicts := game.room.placement_actor_conflicts(proposed)
	if not conflicts.is_empty():
		_set_status(_actor_conflict_message(conflicts[0]), false)
		return false
	_pending_undo = is_undo
	_last_save_error = ""
	_pending_mutation = {"operationId": "furnish-%x-%x" % [Time.get_ticks_usec(), randi()], "expectedRevision": int(_committed_state.get("revision", 0)), "placements": proposed.duplicate(true), "previous": _committed_state.get("placements", {}).duplicate(true)}
	_dispatch_pending()
	return true

func _dispatch_pending() -> void:
	_save_pending = true
	_set_status("Saving office…", true)
	_refresh_controls()
	if not _pending_mutation.has("actorCells"):
		var actors: Array = []
		for actor_id: String in game.room.navigation.actors:
			var position: Vector2 = game.room.navigation.actors[actor_id]
			var cell := game.room.navigation.cell_at(position)
			actors.append({"id": actor_id, "grid": [cell.x, cell.y], "position": [position.x, position.y]})
		_pending_mutation["actorCells"] = actors
	# Freeze the entire request, not only its ID, across an uncertain retry.
	save_requested.emit(str(_pending_mutation.operationId), int(_pending_mutation.expectedRevision), _pending_mutation.placements.duplicate(true), _pending_mutation.actorCells.duplicate(true))

func retry_save() -> void:
	if _save_pending or _pending_mutation.is_empty() or not _can_save(): return
	# A failed edit can be left open or revisited after actors have moved.
	# Never replay its old founder-position snapshot into a newer world state.
	# Keep the original request immutable; the next placement gets a fresh ID.
	if not _retry_actors_unchanged():
		_pending_mutation.clear()
		_pending_undo = false
		_last_save_error = "Someone moved since that save attempt. Choose the placement again to save your current room."
		_set_status(_last_save_error, false)
		_refresh_controls()
		return
	var conflicts := game.room.placement_actor_conflicts(_pending_mutation.placements)
	if not conflicts.is_empty():
		_set_status(_actor_conflict_message(conflicts[0]), false)
		return
	_dispatch_pending()

func _retry_actors_unchanged() -> bool:
	var previous: Array = _pending_mutation.get("actorCells", [])
	if previous.size() != game.room.navigation.actors.size(): return false
	for actor: Dictionary in previous:
		var id := str(actor.get("id", ""))
		if not game.room.navigation.actors.has(id): return false
		var position: Vector2 = game.room.navigation.actors[id]
		var saved: Variant = actor.get("position")
		if not saved is Array or saved.size() != 2: return false
		if not position.is_equal_approx(Vector2(float(saved[0]), float(saved[1]))): return false
	return true

func store_selected() -> void:
	if _save_pending or placement_active or selected_id.is_empty(): return
	var item := _inventory_item(selected_id)
	if item.is_empty() or bool(item.get("essential", true)):
		_set_status("This station is needed by your company and cannot be stored.", false)
		return
	var proposed: Dictionary = _committed_state.get("placements", {}).duplicate(true)
	if not proposed.has(selected_id): return
	proposed.erase(selected_id)
	_submit_layout(proposed, false)

func _inventory_item(id: String) -> Dictionary:
	for item: Dictionary in _committed_state.get("inventory", []):
		if str(item.get("id", "")) == id: return item
	return {}

func _validate_all_stages(proposed: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for stage: int in range(5):
		var result := game.room.layout_model.validate_placements(game.room.layout_model.resolve_placements(stage, proposed, true))
		for value: Variant in result.get("errors", []):
			var message := "Stage %d: %s" % [stage, str(value)]
			if not errors.has(message): errors.append(message)
	return {"valid": errors.is_empty(), "errors": errors}

func _actor_conflict_message(conflict: Dictionary) -> String:
	var actor_id := str(conflict.get("actor_id", ""))
	var display_name := str(conflict.get("display_name", actor_id.capitalize()))
	var placement := _placement(str(conflict.get("placement_id", "")))
	if str(placement.get("owner_id", "")) == actor_id:
		return "%s must leave this desk before it can move or rotate." % display_name
	return "Move %s clear before placing this furniture." % display_name

func _friendly_error(message: String) -> String:
	var value := message
	if value.contains("Artwork extends into a wall"): return "The artwork would overlap a wall. Move it farther into the room."
	if value.contains("Footprint intersects a wall"): return "The furniture would cross a wall or room edge."
	if value.contains("Overlaps") or value.contains("Blocks chair"): return "That space overlaps furniture or an interaction area."
	if value.contains("reserved circulation"): return "Keep the main office walkway clear."
	if value.contains("Cannot reach") or value.contains("isolates part"): return "That position would block a route through the office."
	return value.trim_prefix("Stage 0: ").trim_prefix("Stage 1: ").trim_prefix("Stage 2: ").trim_prefix("Stage 3: ").trim_prefix("Stage 4: ")

func _refresh_placements() -> void:
	_placements = game.room.layout_model.resolve_placements(game.room.unlocked_hires, game.room.placement_overrides)
	for item: Dictionary in _committed_state.get("inventory", []):
		if not _placement(str(item.get("id", ""))).is_empty(): continue
		var raw := {"id": str(item.id), "kind": str(item.kind), "grid": [6, 17], "facing": "south", "owner_id": str(item.get("ownerId", "")), "required_hires": 0}
		var stored := game.room.layout_model.resolve(raw)
		stored["stored"] = true
		_placements.append(stored)
	_prop_picker.clear()
	for placement: Dictionary in _placements:
		_prop_picker.add_item(_display_name(placement) + (" — stored" if bool(placement.get("stored", false)) else ""))
		_prop_picker.set_item_metadata(_prop_picker.item_count - 1, str(placement.id))
		if str(placement.id) == selected_id: _prop_picker.select(_prop_picker.item_count - 1)
	_refresh_controls()

func _refresh_facing_picker(placement: Dictionary) -> void:
	_facing_picker.clear()
	for facing: String in game.room.layout_model.available_facings(str(placement.get("kind", ""))):
		_facing_picker.add_item(facing.capitalize())
		_facing_picker.set_item_metadata(_facing_picker.item_count - 1, facing)
		if facing == preview_facing: _facing_picker.select(_facing_picker.item_count - 1)

func _available_facings() -> Array[String]:
	var placement := _placement(selected_id)
	return game.room.layout_model.available_facings(str(placement.get("kind", ""))) if not placement.is_empty() else []

func _placement(id: String) -> Dictionary:
	for placement: Dictionary in _placements:
		if str(placement.get("id", "")) == id: return placement
	return {}

func _display_name(placement: Dictionary) -> String:
	var item := _inventory_item(str(placement.get("id", "")))
	if not str(item.get("name", "")).is_empty(): return str(item.name)
	var id := str(placement.get("id", "Furniture")).trim_prefix("decor-").replace("mira", "Mina").replace("-", " ").replace("_", " ")
	return id.capitalize()

func _refresh_controls() -> void:
	if _move_button == null: return
	var selected := _placement(selected_id)
	var stored := bool(selected.get("stored", false))
	_move_button.text = "Place  M" if stored else "Move  M"
	_move_button.disabled = _save_pending or placement_active or selected_id.is_empty()
	_rotate_button.disabled = _save_pending or selected_id.is_empty()
	_undo_button.disabled = _save_pending or _history.is_empty() or not _can_save()
	_prop_picker.disabled = _save_pending or placement_active
	_facing_picker.disabled = _save_pending or selected_id.is_empty()
	_store_button.disabled = _save_pending or placement_active or stored or bool(_inventory_item(selected_id).get("essential", true)) or not _can_save()
	_cancel_button.disabled = _save_pending or not placement_active
	_retry_button.visible = not _pending_mutation.is_empty() and not _save_pending
	_retry_button.disabled = not _can_save()
	_done_button.disabled = _save_pending
	_ownership.text = "1 owned  |  %s" % ("1 in storage" if stored else "1 placed")
	if bool(_inventory_item(selected_id).get("essential", false)): _ownership.text += "  |  Required station"
	if not _can_save(): _ownership.text = "Preview only — worker not connected"
	_preview_panel.visible = not placement_active and not selected.is_empty()
	_preview_canvas.queue_redraw()

func _set_status(message: String, valid: bool) -> void:
	if _status == null: return
	_status.text = message
	_status.tooltip_text = message
	_status.add_theme_color_override("font_color", INK if valid else Color("8c2714"))

func _on_prop_selected(index: int) -> void:
	select_placement(str(_prop_picker.get_item_metadata(index)))

func _on_facing_selected(index: int) -> void:
	if index < 0: return
	if not placement_active: begin_move()
	preview_facing = str(_facing_picker.get_item_metadata(index))
	preview_at(preview_grid)

func _on_world_gui_input(event: InputEvent) -> void:
	if not active: return
	if _save_pending:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if placement_active and _room_rect().has_point(motion.position):
			var cell := game.room.layout_model.cell_at(motion.position - game.room.global_position)
			# Profile validation measures native alpha and checks five office
			# stages. Run it once per snapped cell, not on every mouse pixel.
			if cell != preview_grid: preview_at(cell)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			if placement_active and _room_rect().has_point(click.position):
				preview_at(game.room.layout_model.cell_at(click.position - game.room.global_position))
				commit_preview()
			elif not placement_active:
				_select_at(click.position)
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey: return
	var key := event as InputEventKey
	if not key.pressed or key.echo: return
	if _save_pending:
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_ESCAPE:
		if placement_active: cancel_preview()
		else: close()
	elif key.keycode == KEY_M:
		begin_move()
	elif key.keycode == KEY_R:
		rotate_preview()
	elif key.keycode == KEY_U or ((key.ctrl_pressed or key.meta_pressed) and key.keycode == KEY_Z):
		undo()
	elif placement_active and key.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		var step := Vector2i.LEFT if key.keycode == KEY_LEFT else Vector2i.RIGHT if key.keycode == KEY_RIGHT else Vector2i.UP if key.keycode == KEY_UP else Vector2i.DOWN
		preview_at(preview_grid + step)
	elif placement_active and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		commit_preview()
	else:
		return
	get_viewport().set_input_as_handled()

func _select_at(point: Vector2) -> void:
	# Use actual alpha and live layer depth, matching ordinary world clicks. A
	# transparent atlas corner must never select a different-looking prop.
	var top_sprite: Sprite2D
	var selected: Dictionary = {}
	for placement: Dictionary in _placements:
		var prop := game.room.prop_node(str(placement.id))
		if prop == null: continue
		for layer: Dictionary in placement.get("render_layers", []):
			var sprite := prop.get_node_or_null(NodePath(str(layer.name))) as Sprite2D
			if not VisibleSurface.painted(sprite, point) or not VisibleSurface.in_front(sprite, top_sprite): continue
			top_sprite = sprite
			selected = placement
	if not selected.is_empty():
		select_placement(str(selected.id))
		_set_status("Selected %s. Press M to move or R to rotate." % _display_name(selected), true)

func _room_rect() -> Rect2:
	return Rect2(game.room.global_position, Vector2(game.room.layout_model.width, game.room.layout_model.height) * game.room.layout_model.tile_size)

func _draw() -> void:
	if not active or not placement_active or _candidate.is_empty(): return
	var tint := Color(VALID if bool(preview_result.get("valid", false)) else INVALID, 0.58)
	var anchor := game.room.global_position + Vector2(_candidate.get("anchor", Vector2.ZERO))
	for layer: Dictionary in _candidate.get("render_layers", []):
		var path := str(layer.get("art", ""))
		if not ResourceLoader.exists(path, "Texture2D"): continue
		var texture: Texture2D = _texture_cache.get(path)
		if texture == null:
			texture = load(path) as Texture2D
			if texture != null: _texture_cache[path] = texture
		if texture == null: continue
		var source := OfficeLayout.rectangle(layer.get("region"))
		var offset := Vector2(OfficeLayout.vector(layer.get("offset")))
		draw_texture_rect_region(texture, Rect2(anchor + offset - source.size * 0.5, source.size), source, tint)
	for cell: Vector2i in _candidate.get("occupied", []):
		var rect := Rect2(game.room.global_position + game.room.layout_model.world(cell) - Vector2(16, 16), Vector2(32, 32))
		draw_rect(rect.grow(-1), tint, false, 2.0)

func _draw_picker_preview() -> void:
	var placement := _placement(selected_id)
	if placement.is_empty(): return
	var bounds: Rect2 = placement.get("visual_bounds", Rect2())
	var origin := (_preview_canvas.size * 0.5 - bounds.get_center()).round()
	# Native pixels, not a scaled thumbnail. Approved envelopes fit this panel.
	for layer: Dictionary in placement.get("render_layers", []):
		var path := str(layer.get("art", ""))
		if not ResourceLoader.exists(path, "Texture2D"): continue
		var texture: Texture2D = _texture_cache.get(path)
		if texture == null:
			texture = load(path) as Texture2D
			if texture != null: _texture_cache[path] = texture
		if texture == null: continue
		var source := OfficeLayout.rectangle(layer.get("region"))
		var offset := Vector2(OfficeLayout.vector(layer.get("offset")))
		_preview_canvas.draw_texture_rect_region(texture, Rect2(origin + offset - source.size * 0.5, source.size), source)
