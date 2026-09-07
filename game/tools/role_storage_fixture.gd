extends "res://tools/archive_production_fixture.gd"
## DEV ONLY: one role insert on unchanged archive geometry in an actual room.
## Independent scenes allow a native side-by-side comparison without inventing
## a production variant schema or mutating the shared prop-scene registry.
var role := "legal"
var south_insert_path := ""
var model: OfficeLayout

class RoleEditor extends "res://tools/archive_production_fixture.gd".ProductionEditor:
	func _build_interface() -> void:
		super._build_interface()
		_status.text = "%s STORAGE STUDY · new South insert; N/E/W common reuse · no specialist functionality" % str(get_parent().role).to_upper()
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null: _status.text = "UNAPPROVED ROLE STUDY · " + "\n".join(message.split("\n").slice(0, 2))

func _ready() -> void:
	show_editor = false
	super._ready()
	if not ready_ok: return
	ready_ok = false
	if role not in ["legal", "creative"] or not ResourceLoader.exists(south_insert_path):
		errors.append("A real imported legal/creative registered South insert is required; no fallback art is substituted")
		return
	var native := load(south_insert_path) as Texture2D
	if native == null or native.get_size() != Vector2(192, 288):
		errors.append("Role insert must retain the registered192×288 archive canvas")
		return
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	for side: String in OfficeLayout.FACINGS:
		var profile: Dictionary = catalog.artifact_archive.facing_profiles[side]
		profile.status = "calibration_candidate"
		profile.review = {"art": false, "geometry": false}
		profile.calibration_limitations = ["Role front is unapproved visual decor, not new specialist functionality.", "North/East/West are exact approved common archive components reused unchanged, not new drawings."]
		if side == "south":
			for layer: Dictionary in profile.render_layers:
				if layer.name == "ArchiveInsert": layer.art = south_insert_path
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self):
		errors.append("Role study requires live editor-scoped ownership")
		return
	for side: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_service_profile("artifact_archive", side, self):
			errors.append("Exact role profile admission failed: " + side)
	if not errors.is_empty(): return
	var validation := model.validate_placements(model.resolve_placements(hires))
	if not validation.valid:
		errors.assign(validation.errors)
		return
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(hires)
	editor = RoleEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement("artifact-archive")
	ready_ok = true

func _exit_tree() -> void:
	if model != null: model.disable_calibration_preview(self)
	super._exit_tree()
