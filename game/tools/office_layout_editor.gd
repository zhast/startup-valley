class_name DevOfficeLayoutEditor
extends Node2D

## Standalone development tool. No production scene references this script.
## Export creates a reviewable JSON file; it never mutates game or worker saves.
const ROOM_ORIGIN := Vector2(0, 48)
const EXPORT_DIRECTORY := "res://tests/output/office-layout"
const EXPORT_PATH := EXPORT_DIRECTORY + "/office-layout.json"
const ROOM_SCENE: PackedScene = preload("res://world/town_room.tscn")
const BODY_FONT: Font = preload("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
const INK := Color("f1f1f1")
const VALID := Color("c1fa81")
const INVALID := Color("fa4616")
const CLEARANCE := Color("6196c1")
const OCCUPIED := Color("fa4616")

var room: TownRoom
var model: OfficeLayout
var hire_count: int = 2
var overrides: Dictionary = {}
var selected_id: String = ""
var preview_grid := Vector2i.ZERO
var preview_facing: String = "south"
var preview_result: Dictionary = {}
var placement_active: bool = false
var show_grid: bool = true
var show_footprints: bool = true
var show_clearance: bool = true
var show_walls: bool = true
var show_interactions: bool = true
var show_routes: bool = false
var show_visual_bounds: bool = false
var last_export_path: String = ""
var _history: Array[Dictionary] = []
var _placements: Array[Dictionary] = []
var _candidate: Dictionary = {}
var _routes: Array[PackedVector2Array] = []
var _inspector: VBoxContainer
var _stage_picker: OptionButton
var _prop_picker: OptionButton
var _facing_picker: OptionButton
var _details: Label
var _status: Label
var _save_button: Button
var _move_button: Button
var _cancel_button: Button
var _status_text: String = "Select furniture, then Move. Click a valid grid cell to place."
var _status_valid: bool = true

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room = ROOM_SCENE.instantiate() as TownRoom
	room.position = ROOM_ORIGIN
	room.z_as_relative = false
	room.z_index = 0
	add_child(room)
	room.load_layout()
	model = room.layout_model
	room.set_hire_count(hire_count)
	# This overlay stays above all prop depth layers. Native textures are used
	# beneath it; grid/debug graphics are intentionally development-only.
	z_index = 1500
	_build_interface()
	_refresh_placements()
	if not _placements.is_empty():
		select_placement(str(_placements[0].get("id", "")))
	queue_redraw()

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2000
	add_child(layer)
	var heading := Label.new()
	heading.text = "OFFICE LAYOUT · DEVELOPMENT ONLY     |     Native 32 px grid · no worker · no save access"
	heading.position = Vector2(16, 8)
	heading.add_theme_font_override("font", BODY_FONT)
	heading.add_theme_font_size_override("font_size", 22)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(heading)
	var panel := PanelContainer.new()
	panel.position = Vector2(1288, 48)
	panel.size = Vector2(304, 736)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("252525")
	background.content_margin_left = 12
	background.content_margin_right = 12
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", background)
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 16
	panel.theme = theme
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_inspector = VBoxContainer.new()
	_inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector.add_theme_constant_override("separation", 5)
	scroll.add_child(_inspector)
	_label("Office stage")
	_stage_picker = OptionButton.new()
	for stage: int in range(5):
		_stage_picker.add_item(["Founder only", "Mina hired", "Mina + Theo", "Dev stage 3", "Dev stage 4"][stage], stage)
	_stage_picker.select(hire_count)
	_stage_picker.item_selected.connect(set_stage)
	_inspector.add_child(_stage_picker)
	_label("Furniture")
	_prop_picker = OptionButton.new()
	_prop_picker.item_selected.connect(func(index: int) -> void: select_placement(_prop_picker.get_item_metadata(index)))
	_inspector.add_child(_prop_picker)
	_label("Authored facing")
	_facing_picker = OptionButton.new()
	_facing_picker.item_selected.connect(_on_facing_selected)
	_inspector.add_child(_facing_picker)
	var row := HBoxContainer.new()
	_inspector.add_child(row)
	_move_button = _button("Move [M]", begin_move, row)
	_cancel_button = _button("Cancel [Esc]", cancel_move, row)
	_details = _label("")
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size.x = 265
	_status = _label(_status_text)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(265, 82)
	_label("Inspect")
	_toggle("Grid [G]", "show_grid")
	_toggle("Occupied floor [F]", "show_footprints")
	_toggle("Clearance [C]", "show_clearance")
	_toggle("Walls / circulation [B]", "show_walls")
	_toggle("Interaction points [I]", "show_interactions")
	_toggle("Entrance routes [N]", "show_routes")
	_toggle("Art bounds / layers [V]", "show_visual_bounds")
	_save_button = _button("Export layout [Ctrl+S]", export_default, _inspector)
	_button("Undo [Ctrl+Z]", undo, _inspector)
	var note := _label("Export only: tests/output/office-layout/office-layout.json\nReview the diff before replacing data/office_layout.json. Original data and company saves are never overwritten.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 265
	note.add_theme_font_size_override("font_size", 14)

func _label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	_inspector.add_child(label)
	return label

func _button(text_value: String, action: Callable, parent: Control) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 36
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _toggle(text_value: String, property_name: String) -> void:
	var check := CheckButton.new()
	check.text = text_value
	check.add_theme_constant_override("h_separation", 0)
	check.add_theme_font_size_override("font_size", 15)
	check.button_pressed = bool(get(property_name))
	check.toggled.connect(func(enabled: bool) -> void:
		set(property_name, enabled)
		queue_redraw()
	)
	check.set_meta("debug_property", property_name)
	_inspector.add_child(check)

func _refresh_placements() -> void:
	_placements = model.resolve_placements(hire_count, overrides)
	_prop_picker.clear()
	for placement: Dictionary in _placements:
		var id := str(placement.get("id", ""))
		_prop_picker.add_item(id)
		_prop_picker.set_item_metadata(_prop_picker.item_count - 1, id)
		if id == selected_id:
			_prop_picker.select(_prop_picker.item_count - 1)
	_update_routes()
	queue_redraw()

func set_stage(stage: int) -> void:
	cancel_move()
	hire_count = clampi(stage, 0, 4)
	_stage_picker.select(hire_count)
	room.set_hire_count(hire_count)
	_refresh_placements()
	if _placement(selected_id).is_empty() and not _placements.is_empty():
		selected_id = str(_placements[0].get("id", ""))
	select_placement(selected_id)

func _placement(id: String) -> Dictionary:
	for placement: Dictionary in _placements:
		if str(placement.get("id", "")) == id:
			return placement
	return {}

func select_placement(id: String) -> void:
	cancel_move()
	var placement := _placement(id)
	if placement.is_empty():
		return
	selected_id = id
	preview_grid = placement.get("grid", Vector2i.ZERO)
	preview_facing = str(placement.get("facing", "south"))
	for index: int in range(_prop_picker.item_count):
		if _prop_picker.get_item_metadata(index) == id:
			_prop_picker.select(index)
	var profile: Dictionary = placement.get("profile", {})
	_facing_picker.clear()
	for facing: Variant in profile.get("facings", ["south"]):
		_facing_picker.add_item(str(facing))
		if str(facing) == preview_facing:
			_facing_picker.select(_facing_picker.item_count - 1)
	_update_details()
	queue_redraw()

func begin_move() -> void:
	if selected_id.is_empty():
		return
	placement_active = true
	var prop := room.prop_node(selected_id)
	if prop != null:
		prop.visible = false
	preview_at(preview_grid)

func cancel_move() -> void:
	placement_active = false
	_candidate = {}
	if room != null:
		var prop := room.prop_node(selected_id)
		if prop != null:
			prop.visible = true
	if _details != null:
		_update_details()
	queue_redraw()

func preview_at(grid: Vector2i, facing: String = "") -> Dictionary:
	preview_grid = grid
	if not facing.is_empty():
		preview_facing = facing
	var proposed := _with_candidate()
	preview_result = validate_all_stages(proposed)
	_candidate = {}
	for placement: Dictionary in model.resolve_placements(hire_count, proposed):
		if str(placement.get("id", "")) == selected_id:
			_candidate = placement
	var errors: Array = preview_result.get("errors", [])
	_set_status("VALID — click to place. Every office stage remains reachable." if bool(preview_result.get("valid", false)) else "INVALID — placement rejected.\n" + "\n".join(errors.slice(0, 2)), bool(preview_result.get("valid", false)))
	_status.tooltip_text = "\n".join(errors)
	_update_details()
	queue_redraw()
	return preview_result

func _with_candidate() -> Dictionary:
	var proposed := overrides.duplicate(true)
	proposed[selected_id] = {"grid": [preview_grid.x, preview_grid.y], "facing": preview_facing}
	return proposed

func validate_all_stages(proposed: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage, proposed))
		for error: Variant in validation.get("errors", []):
			var reason := "Stage %d: %s" % [stage, str(error)]
			if not errors.has(reason):
				errors.append(reason)
	return {"valid": errors.is_empty(), "errors": errors}

func commit_preview() -> bool:
	if not placement_active:
		return false
	preview_at(preview_grid)
	if not bool(preview_result.get("valid", false)):
		return false
	var proposed := _with_candidate()
	if not room.set_placement_overrides(proposed):
		_set_status("Runtime resolver rejected this layout. Nothing was moved.", false)
		return false
	_history.append(overrides.duplicate(true))
	overrides = proposed
	placement_active = false
	_candidate = {}
	_refresh_placements()
	select_placement(selected_id)
	_set_status("Placed %s at (%d, %d). All five office stages validate." % [selected_id, preview_grid.x, preview_grid.y], true)
	return true

func undo() -> void:
	if _history.is_empty():
		_set_status("No placement changes to undo.", true)
		return
	cancel_move()
	var previous := _history.pop_back() as Dictionary
	if room.set_placement_overrides(previous):
		overrides = previous
		_refresh_placements()
		select_placement(selected_id)
		_set_status("Previous validated layout restored.", true)

func export_default() -> void:
	export_layout(EXPORT_PATH)

func export_layout(path: String = EXPORT_PATH) -> bool:
	# Keep export scope intentionally narrow, including calls from tests.
	var normalized := path.simplify_path()
	if not normalized.begins_with(EXPORT_DIRECTORY + "/") or not normalized.ends_with(".json"):
		_set_status("Export rejected: use the developer output directory and a .json filename.", false)
		return false
	if placement_active:
		_set_status("Place or cancel the preview before exporting. No preview is silently saved.", false)
		return false
	var validation := validate_all_stages(overrides)
	if not bool(validation.get("valid", false)):
		_set_status("Export rejected: layout is invalid.\n" + "\n".join(validation.get("errors", [])), false)
		return false
	var exported := model.data.duplicate(true)
	for prop_value: Variant in exported.get("props", []):
		var prop := prop_value as Dictionary
		var id := str(prop.get("id", ""))
		if overrides.has(id):
			var change: Dictionary = overrides[id]
			prop["grid"] = change.get("grid", prop.get("grid"))
			prop["facing"] = change.get("facing", prop.get("facing", "south"))
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(normalized.get_base_dir()))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		_set_status("Could not create developer export directory.", false)
		return false
	var file := FileAccess.open(normalized, FileAccess.WRITE)
	if file == null:
		_set_status("Could not write validated layout: %s" % error_string(FileAccess.get_open_error()), false)
		return false
	file.store_string(JSON.stringify(exported, "\t") + "\n")
	file.close()
	last_export_path = normalized
	_set_status("Exported all-stage validated layout. Review JSON before replacing production room data.", true)
	return true

func _on_facing_selected(index: int) -> void:
	preview_facing = _facing_picker.get_item_text(index)
	if placement_active:
		preview_at(preview_grid)

func _set_status(message: String, valid: bool) -> void:
	_status_text = message
	_status_valid = valid
	if _status != null:
		_status.text = message
		_status.add_theme_color_override("font_color", VALID if valid else INVALID)

func _update_details() -> void:
	var placement := _candidate if not _candidate.is_empty() else _placement(selected_id)
	var grid: Vector2i = placement.get("grid", preview_grid)
	var profile: Dictionary = placement.get("profile", {})
	_details.text = "Grid (%d, %d) · %s\n%d occupied · %d clearance cells\n%s" % [grid.x, grid.y, preview_facing, (placement.get("occupied", []) as Array).size(), (placement.get("clearance", []) as Array).size(), "Preview: click to place; Esc cancels." if placement_active else "Select on canvas or use Move [M]."]
	_details.tooltip_text = "Occlusion layers: " + str(profile.get("layers", {}))
	_move_button.disabled = placement_active
	_cancel_button.disabled = not placement_active
	_save_button.disabled = placement_active

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if placement_active and _room_rect().has_point(motion.position):
			preview_at(Vector2i(floori((motion.position.x - ROOM_ORIGIN.x) / model.tile_size), floori((motion.position.y - ROOM_ORIGIN.y) / model.tile_size)))
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index != MOUSE_BUTTON_LEFT or not click.pressed or not _room_rect().has_point(click.position):
			return
		if placement_active:
			preview_at(Vector2i(floori((click.position.x - ROOM_ORIGIN.x) / model.tile_size), floori((click.position.y - ROOM_ORIGIN.y) / model.tile_size)))
			commit_preview()
		else:
			var local_point := click.position - ROOM_ORIGIN
			for index: int in range(_placements.size() - 1, -1, -1):
				var placement := _placements[index]
				if _visual_rect(placement).has_point(local_point):
					select_placement(str(placement.get("id", "")))
					break
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.ctrl_pressed or key.meta_pressed:
			if key.keycode == KEY_S:
				export_default()
			elif key.keycode == KEY_Z:
				undo()
			return
		match key.keycode:
			KEY_ESCAPE: cancel_move()
			KEY_M: begin_move()
			KEY_G: _flip("show_grid")
			KEY_F: _flip("show_footprints")
			KEY_C: _flip("show_clearance")
			KEY_B: _flip("show_walls")
			KEY_I: _flip("show_interactions")
			KEY_N: _flip("show_routes")
			KEY_V: _flip("show_visual_bounds")

func _flip(property_name: String) -> void:
	set(property_name, not bool(get(property_name)))
	for child: Node in _inspector.get_children():
		if child is CheckButton and child.get_meta("debug_property", "") == property_name:
			(child as CheckButton).set_pressed_no_signal(bool(get(property_name)))
	queue_redraw()

func _room_rect() -> Rect2:
	return Rect2(ROOM_ORIGIN, Vector2(model.width * model.tile_size, model.height * model.tile_size))

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(ROOM_ORIGIN + Vector2(cell * model.tile_size), Vector2.ONE * model.tile_size)

func _visual_rect(placement: Dictionary) -> Rect2:
	# This is room-local even though the model calls it world_visual_bounds.
	# Resolve owns visual overhang/anchor offsets; footprints remain grid-aligned.
	return placement.get("world_visual_bounds", Rect2())

func _visual_anchor(placement: Dictionary) -> Vector2:
	return ROOM_ORIGIN + Vector2(placement.get("anchor", model.world(placement.get("grid", Vector2i.ZERO))))

func _cell_center(cell: Vector2i) -> Vector2:
	return ROOM_ORIGIN + Vector2(cell * model.tile_size) + Vector2.ONE * model.tile_size * 0.5

func _draw() -> void:
	if model == null:
		return
	if show_walls:
		for y: int in range(model.height):
			for x: int in range(model.width):
				var cell := Vector2i(x, y)
				if not model.is_floor(cell):
					draw_rect(_cell_rect(cell), Color(1, 0.3, 0.1, 0.12))
		for entry: Vector2i in model.entrance_cells():
			draw_rect(_cell_rect(entry), Color(0.75, 0.98, 0.5, 0.2))
		for rect_value: Variant in model.data.get("circulation_rects", []):
			var values := rect_value as Array
			var bounds := Rect2(ROOM_ORIGIN + Vector2(values[0], values[1]) * model.tile_size, Vector2(values[2], values[3]) * model.tile_size)
			draw_rect(bounds, Color(0.75, 0.98, 0.5, 0.05))
			draw_rect(bounds, Color(0.75, 0.98, 0.5, 0.35), false, 1.0)
	if show_grid:
		for x: int in range(model.width + 1):
			draw_line(ROOM_ORIGIN + Vector2(x * model.tile_size, 0), ROOM_ORIGIN + Vector2(x * model.tile_size, model.height * model.tile_size), Color(1, 1, 1, 0.12))
		for y: int in range(model.height + 1):
			draw_line(ROOM_ORIGIN + Vector2(0, y * model.tile_size), ROOM_ORIGIN + Vector2(model.width * model.tile_size, y * model.tile_size), Color(1, 1, 1, 0.12))
	for placement: Dictionary in _placements:
		if placement_active and str(placement.get("id", "")) == selected_id:
			continue
		_draw_placement_overlay(placement, false)
	if show_routes:
		for route: PackedVector2Array in _routes:
			if route.size() >= 2:
				draw_polyline(route, Color(0.75, 0.98, 0.5, 0.85), 2.0)
	if placement_active and not _candidate.is_empty():
		_draw_preview_art(_candidate)
		_draw_placement_overlay(_candidate, true)
		var anchor := _cell_center(preview_grid)
		draw_circle(anchor, 4.0, VALID if bool(preview_result.get("valid", false)) else INVALID)

func _draw_placement_overlay(placement: Dictionary, preview: bool) -> void:
	var selected := str(placement.get("id", "")) == selected_id
	var color := VALID if bool(preview_result.get("valid", false)) else INVALID
	if show_footprints or preview:
		for cell: Vector2i in placement.get("occupied", []):
			draw_rect(_cell_rect(cell).grow(-1), Color(color, 0.28) if preview else Color(OCCUPIED, 0.18))
			draw_rect(_cell_rect(cell).grow(-1), color if preview else Color(OCCUPIED, 0.75), false, 2.0 if selected else 1.0)
	if show_clearance or preview:
		for cell: Vector2i in placement.get("clearance", []):
			draw_rect(_cell_rect(cell).grow(-3), Color(CLEARANCE, 0.18))
			draw_rect(_cell_rect(cell).grow(-3), CLEARANCE, false)
	if show_interactions:
		var point := _cell_center(placement.get("interaction", Vector2i.ZERO))
		draw_circle(point, 6, CLEARANCE)
		draw_circle(point, 3, Color("151515"))
	if show_visual_bounds or selected:
		var rect := _visual_rect(placement)
		rect.position += ROOM_ORIGIN
		draw_rect(rect, Color(1, 1, 1, 0.7 if selected else 0.3), false)
		var anchor := _visual_anchor(placement)
		draw_line(anchor - Vector2(7, 0), anchor + Vector2(7, 0), INK)
		draw_line(anchor - Vector2(0, 7), anchor + Vector2(0, 7), INK)
		if show_visual_bounds:
			var profile: Dictionary = placement.get("profile", {})
			var layers: Dictionary = profile.get("layers", {})
			for key: String in ["rear_z_offset", "front_z_offset", "seat_z_offset"]:
				if layers.has(key):
					var y := anchor.y + float(layers[key])
					draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(1, 0.9, 0.6, 0.85))

func _draw_preview_art(placement: Dictionary) -> void:
	var tint := Color(VALID if bool(preview_result.get("valid", false)) else INVALID, 0.55)
	for layer: Dictionary in _preview_layers(placement):
		draw_texture_rect_region(layer.texture, layer.destination, layer.source, tint)

func _preview_layers(placement: Dictionary) -> Array[Dictionary]:
	# Expose the same native rectangles used by drawing so regression tests can
	# compare the ghost with actual placed Sprite2D layers, including atlas rows.
	var result: Array[Dictionary] = []
	var profile: Dictionary = placement.get("profile", {})
	var art_path := str(profile.get("art", ""))
	if art_path.is_empty():
		return result
	var texture := load(art_path) as Texture2D
	if texture == null:
		return result
	var anchor := _visual_anchor(placement)
	var offset := Vector2(OfficeLayout.vector(profile.get("sprite_offset", [0, 0])))
	if profile.has("atlas_cell"):
		var cell_size := Vector2(OfficeLayout.vector(profile["atlas_cell"]))
		var row := int(profile.get("atlas_row", 0))
		var dest := Rect2(anchor + offset - cell_size * 0.5, cell_size)
		var layers: Dictionary = profile.get("layers", {})
		var column_count := 2 if layers.has("rear_z_offset") or layers.has("front_z_offset") else 1
		for column: int in range(column_count):
			result.append({"texture": texture, "destination": dest, "source": Rect2(Vector2(column, row) * cell_size, cell_size)})
	else:
		result.append({"texture": texture, "destination": Rect2(anchor + offset - texture.get_size() * 0.5, texture.get_size()), "source": Rect2(Vector2.ZERO, texture.get_size())})
	return result

func _update_routes() -> void:
	_routes.clear()
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, model.width, model.height)
	grid.cell_size = Vector2.ONE * model.tile_size
	grid.offset = ROOM_ORIGIN + Vector2.ONE * model.tile_size * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y: int in range(model.height):
		for x: int in range(model.width):
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not model.is_floor(cell))
	for placement: Dictionary in _placements:
		for cell: Vector2i in placement.get("occupied", []):
			if grid.region.has_point(cell):
				grid.set_point_solid(cell)
	var entrances: Array[Vector2i] = model.entrance_cells()
	if entrances.is_empty():
		return
	var start := entrances[0]
	for placement: Dictionary in _placements:
		var target: Vector2i = placement.get("interaction", Vector2i.ZERO)
		if grid.region.has_point(target) and not grid.is_point_solid(target):
			_routes.append(grid.get_point_path(start, target))
