extends "res://tools/archive_production_fixture.gd"
## Disposable GameMain room containing only three bare table candidates.

const TABLES := preload("res://tools/passive_table_geometry.gd")
const PLACEMENTS := {
	"low_coffee_table": {"id": "dev-low-table", "grid": [8, 13]},
	"cafe_table": {"id": "dev-cafe-table", "grid": [22, 13]},
	"round_meeting_table": {"id": "dev-round-table", "grid": [29, 13]},
}
var model: OfficeLayout

func _ready() -> void:
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	data.props = []
	for family: String in TABLES.FAMILIES:
		catalog[family] = TABLES.catalog_entry(family)
		var placement: Dictionary = PLACEMENTS[family]
		data.props.append({"id": placement.id, "kind": family, "grid": placement.grid, "facing": "north", "required_hires": 0})
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Passive table live owner rejected")
	for family: String in TABLES.FAMILIES:
		for facing: String in OfficeLayout.FACINGS:
			if not model.authorize_calibration_decorative_profile(family, facing, self):
				errors.append("Candidate rejected: " + family + "/" + facing)
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage))
		if not validation.valid: errors.append("Stage%d: %s" % [stage, str(validation.errors)])
	if not errors.is_empty(): return
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(hires)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 18))
	main.room.navigation.actors["founder"] = main.player.position
	ready_ok = true

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
