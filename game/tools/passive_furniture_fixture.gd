extends "res://tools/archive_production_fixture.gd"
## Disposable real GameMain with two locally admitted passive candidate families.
const PROFILES := preload("res://tools/passive_furniture_profiles.gd")
var model: OfficeLayout

class PassiveEditor extends "res://tools/calibrated_workstation_editor.gd":
	func _build_interface() -> void:
		super._build_interface()
		var panel := _inspector.get_parent() as PanelContainer
		panel.position.y = 610
		panel.custom_minimum_size.y = 102
		for label_value: String in ["Sit", "Type", "Leave"]: action_buttons[label_value].hide()
		_facing_picker.tooltip_text = "Physical orientation only. Passive furniture has no use action."
		_set_status("Passive furniture preview · no actions, worker or saves", true)
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null: _status.text = "PASSIVE PREVIEW · " + "\n".join(message.split("\n").slice(0, 2))
	func export_layout(_path := "") -> bool:
		_set_status("Export disabled: these local candidates are not production-approved", false)
		return false
	func _draw() -> void:
		super._draw()
		if not placement_active: return
		for point: Dictionary in _candidate.get("standing_viewpoints", []):
			var bounds: Rect2 = point.world_visual_bounds
			bounds.position += room.global_position
			draw_rect(bounds, Color("6196c1"), false, 1)

func _ready() -> void:
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	for kind: String in PROFILES.FAMILIES: catalog[kind] = PROFILES.catalog_entry(kind)
	data.props.append({"id": "dev-whiteboard", "kind": "mobile_whiteboard", "grid": [22, 15], "facing": "south", "required_hires": 0})
	data.props.append({"id": "dev-pedestal", "kind": "rolling_storage_pedestal", "grid": [13, 18], "facing": "south", "required_hires": 0})
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Live passive model owner rejected")
	for kind: String in PROFILES.FAMILIES:
		for facing: String in OfficeLayout.FACINGS:
			if not model.authorize_calibration_decorative_profile(kind, facing, self): errors.append("Passive candidate rejected: " + kind + "/" + facing + " " + str(model.resolve_profile(kind, facing).errors))
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage))
		if not validation.valid: errors.append("Stage%d: %s" % [stage, str(validation.errors)])
	if not errors.is_empty(): return
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(hires)
	main.player.cancel_route()
	main.player.position = model.world(main.room.player_spawn)
	main.room.navigation.actors["founder"] = main.player.position
	editor = PassiveEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement("dev-whiteboard")
	ready_ok = true

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
