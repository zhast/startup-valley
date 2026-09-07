extends "res://tools/office_layout_editor.gd"
## Compact adapter: shares the real room and existing preview/commit/R logic.
## Placement mode consumes world input; normal mode leaves GameMain clicks live.
var game: GameMain
var action_buttons: Dictionary[String, Button] = {}

func _ready() -> void:
	room = game.room
	model = room.layout_model
	hire_count = room.unlocked_hires
	overrides = room.placement_overrides.duplicate(true)
	z_index = 2000
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_interface()
	_refresh_placements()
	if not _placements.is_empty(): select_placement(str(_placements[0].id))

func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 622)
	panel.custom_minimum_size = Vector2(1080, 90)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 8, 12, 8)))
	canvas.add_child(panel)
	_inspector = VBoxContainer.new()
	panel.add_child(_inspector)
	var row := HBoxContainer.new()
	_inspector.add_child(row)
	_prop_picker = OptionButton.new()
	_prop_picker.custom_minimum_size = Vector2(196, 40)
	CozyUI.dropdown(_prop_picker)
	_prop_picker.item_selected.connect(_on_prop_selected)
	row.add_child(_prop_picker)
	_facing_picker = OptionButton.new()
	_facing_picker.custom_minimum_size = Vector2(106, 40)
	CozyUI.dropdown(_facing_picker)
	_facing_picker.item_selected.connect(_on_facing_selected)
	row.add_child(_facing_picker)
	_move_button = _action("Move [M]", begin_move, row)
	_cancel_button = _action("Cancel", cancel_move, row)
	_action("Rotate [R]", rotate_preview, row)
	_action("Undo [U]", undo, row)
	_action("Sit", func() -> void: get_parent().send_to_desk(_owner_id()), row)
	_action("Type", func() -> void: get_parent().send_to_desk(_owner_id(), true), row)
	_action("Leave", func() -> void:
		# The actionable conflict message can be followed directly: restore the
		# committed desk before asking its occupant to vacate it.
		if placement_active: cancel_move()
		get_parent().leave_desk(_owner_id())
	, row)
	_save_button = Button.new() # Existing details method retains its handle; no export UI.
	_save_button.hide()
	row.add_child(_save_button)
	_details = Label.new()
	_details.hide()
	_inspector.add_child(_details)
	_status = Label.new()
	CozyUI.label(_status, "meta")
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status.custom_minimum_size.x = 1040
	_status.text = "CALIBRATION ONLY · no worker or saves · normal clicks play; Move/R previews, click commits, Esc cancels."
	_inspector.add_child(_status)

func _action(copy: String, callback: Callable, row: HBoxContainer) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size = Vector2(86, 40)
	CozyUI.button(button)
	button.pressed.connect(callback)
	row.add_child(button)
	action_buttons[copy] = button
	return button

func _owner_id() -> String:
	return str(_placement(selected_id).get("owner_id", ""))

func _on_prop_selected(index: int) -> void:
	select_placement(str(_prop_picker.get_item_metadata(index)))

func _set_status(message: String, valid: bool) -> void:
	_status_text = message
	_status_valid = valid
	if _status != null:
		_status.text = "CALIBRATION · " + message
		_status.tooltip_text = message
		_status.add_theme_color_override("font_color", Color("514334") if valid else Color("8c2714"))

func begin_move() -> void:
	game.job_panel.close_drawer()
	super.begin_move()
	_pause_editing()

func cancel_move() -> void:
	super.cancel_move()
	_pause_editing()

func commit_preview() -> bool:
	var accepted := super.commit_preview()
	_pause_editing()
	return accepted

func _pause_editing() -> void:
	if game == null: return
	game.set_process(not placement_active)
	game.player.input_blocked = placement_active
	game.day_clock.ui_paused = placement_active
	for actor: EmployeeAvatar in game._employees.values(): actor.world_paused = placement_active

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo: return
		if key.keycode == KEY_R:
			rotate_preview()
		elif key.keycode == KEY_M:
			begin_move()
		elif key.keycode == KEY_U:
			undo()
		elif key.keycode == KEY_ESCAPE and placement_active:
			cancel_move()
		else: return
		get_viewport().set_input_as_handled()
	elif placement_active and event is InputEventMouseMotion:
		preview_at(model.cell_at((event as InputEventMouseMotion).position - room.global_position))
	elif placement_active and event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index != MOUSE_BUTTON_LEFT or not click.pressed: return
		preview_at(model.cell_at(click.position - room.global_position))
		commit_preview()
		get_viewport().set_input_as_handled()

func _visual_anchor(placement: Dictionary) -> Vector2:
	return room.global_position + Vector2(placement.anchor)

func _draw() -> void:
	if not placement_active or _candidate.is_empty(): return
	_draw_preview_art(_candidate)
	var color := Color("c1fa81") if bool(preview_result.get("valid", false)) else Color("fa4616")
	for cell: Vector2i in _candidate.occupied:
		draw_rect(Rect2(room.global_position + model.world(cell) - Vector2(16, 16), Vector2(32, 32)), color, false)
