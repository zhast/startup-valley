extends "res://tools/archive_production_fixture.gd"
## One scoped passive model, ordinary room/actors/UI and no real worker or saves.
const DIVIDER := preload("res://tools/acoustic_divider_geometry.gd")
const PASSIVE := preload("res://tools/passive_furniture_fixture.gd")
var model: OfficeLayout

class DividerEditor extends "res://tools/passive_furniture_fixture.gd".PassiveEditor:
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null: _status.text = "DIVIDER STUDY · " + "\n".join(message.split("\n").slice(0, 2))

func _ready() -> void:
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	catalog["acoustic_divider"] = DIVIDER.catalog_entry()
	data.props.append({"id": "dev-divider", "kind": "acoustic_divider", "grid": [22, 15], "facing": "south", "required_hires": 0})
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Divider live owner rejected")
	for facing: String in DIVIDER.SIDES:
		if not model.authorize_calibration_decorative_profile("acoustic_divider", facing, self): errors.append("Candidate " + facing + ": " + str(model.resolve_profile("acoustic_divider", facing).errors))
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
	main.room.navigation.actors.founder = main.player.position
	editor = DividerEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement("dev-divider")
	ready_ok = true

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
