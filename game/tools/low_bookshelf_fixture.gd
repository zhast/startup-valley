extends "res://tools/archive_production_fixture.gd"
## Instance-only passive shelf; ordinary room and actor sources, no saved state.
const SHELF := preload("res://tools/low_bookshelf_geometry.gd")
var model: OfficeLayout

class ShelfEditor extends "res://tools/passive_furniture_fixture.gd".PassiveEditor:
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null: _status.text = "LOW SHELF STUDY · " + "\n".join(message.split("\n").slice(0, 2))

func _ready() -> void:
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	catalog["low_bookshelf"] = SHELF.catalog_entry()
	data.props.append({"id": "dev-low-shelf", "kind": "low_bookshelf", "grid": [22, 15], "facing": "south", "required_hires": 0})
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Shelf live owner rejected")
	for facing: String in SHELF.SIDES:
		if not model.authorize_calibration_decorative_profile("low_bookshelf", facing, self): errors.append("Candidate " + facing + ": " + str(model.resolve_profile("low_bookshelf", facing).errors))
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
	editor = ShelfEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement("dev-low-shelf")
	ready_ok = true

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
