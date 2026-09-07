extends "res://tools/archive_production_fixture.gd"
## One disposable prototype at a time. No production catalogue or saved layout.
signal prototype_requested(kind: String)
const PASSIVE := preload("res://tools/passive_furniture_profiles.gd")
const DIVIDER := preload("res://tools/acoustic_divider_geometry.gd")
const SHELF := preload("res://tools/low_bookshelf_geometry.gd")
const FAMILIES: Array[String] = ["mobile_whiteboard", "rolling_storage_pedestal", "acoustic_divider", "low_bookshelf"]
const NAMES: Array[String] = ["Planning whiteboard", "Rolling pedestal", "Acoustic divider", "Low resource shelf"]
const NOTES: Array[String] = [
	"Planning is visible only from South; other views show the rear or thin edge.",
	"Drawers are visible only from South. Side storage, not under-desk storage.",
	"Double-sided: North/South match; East/West match. Thin edges are intentional.",
	"Books are visible only from South; East/West are matching closed ends.",
]
const PROTOTYPE_ID := "catalogue-prototype"
var prototype_kind := "mobile_whiteboard"
var model: OfficeLayout

class CatalogueEditor extends "res://tools/passive_furniture_fixture.gd".PassiveEditor:
	func _build_interface() -> void:
		super._build_interface()
		_prop_picker.custom_minimum_size.x = 244
		_prop_picker.tooltip_text = "Choose one staged prototype. Switching starts a fresh local layout and clears Undo."
		_facing_picker.tooltip_text = "Physical orientation: no bitmap rotation or hidden front-face substitution."
		var note := Label.new()
		CozyUI.label(note, "meta")
		note.text = NOTES[FAMILIES.find(get_parent().prototype_kind)]
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		note.tooltip_text = note.text
		_inspector.add_child(note)
		(_inspector.get_parent() as Control).position.y = 600
		(_inspector.get_parent() as Control).custom_minimum_size.y = 112
	func _refresh_placements() -> void:
		super._refresh_placements()
		_prop_picker.clear()
		for index: int in range(FAMILIES.size()):
			_prop_picker.add_item(NAMES[index])
			_prop_picker.set_item_metadata(index, FAMILIES[index])
		_prop_picker.select(FAMILIES.find(get_parent().prototype_kind))
	func _on_prop_selected(index: int) -> void:
		var kind := str(_prop_picker.get_item_metadata(index))
		if kind != get_parent().prototype_kind:
			get_parent().prototype_requested.emit(kind)
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null:
			_status.text = "DEV ONLY · no worker, saves or export · " + message.split("\n")[0]
			_status.tooltip_text = message
	func export_layout(_path := "") -> bool:
		_set_status("Export disabled. These are staged prototypes, not production furniture.", false)
		return false

func _ready() -> void:
	if prototype_kind not in FAMILIES:
		errors.append("Unknown furniture catalogue prototype")
		return
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	match prototype_kind:
		"mobile_whiteboard", "rolling_storage_pedestal": catalog[prototype_kind] = PASSIVE.catalog_entry(prototype_kind)
		"acoustic_divider": catalog[prototype_kind] = DIVIDER.catalog_entry()
		"low_bookshelf": catalog[prototype_kind] = SHELF.catalog_entry()
	data.props.append({"id": PROTOTYPE_ID, "kind": prototype_kind, "grid": [22, 15], "facing": "south", "required_hires": 0})
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self): errors.append("Catalogue live owner rejected")
	for facing: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_decorative_profile(prototype_kind, facing, self): errors.append("Candidate rejected: " + facing)
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage))
		if not validation.valid: errors.append("Stage%d: %s" % [stage, str(validation.errors)])
	if not errors.is_empty(): return
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(hires)
	main.player.cancel_route()
	# The normal entrance is under this optional dev toolbar. Use an existing
	# clear circulation cell for this disposable viewer only; no production spawn
	# or navigation geometry is changed to make the UI fit.
	main.player.position = model.world(Vector2i(17, 16))
	main.room.navigation.actors["founder"] = main.player.position
	editor = CatalogueEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement(PROTOTYPE_ID)
	editor._set_status("Move [M], rotate [R], click to place, Undo [U]. Switching resets the layout.", true)
	disable_worker_controls()
	ready_ok = true

func disable_worker_controls() -> void:
	if main == null: return
	main.job_panel._settings_button.disabled = true
	main.job_panel._settings_button.text = "Preview"
	main.job_panel._settings_button.tooltip_text = "Furniture preview only. AI connection and work orders are disabled."
	main.job_panel._assign_button.disabled = true
	main.job_panel._chat_send_button.disabled = true
	main.job_panel._chat_input.editable = false

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
