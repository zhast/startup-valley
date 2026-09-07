extends "res://tools/calibrated_service_fixture.gd"
## DEV ONLY: the actual office, navigation and rotation editor around one
## four-facing collaboration-table candidate. This never grants production
## approval, starts the worker, or reads/writes personal save data.

const TABLE_GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const TABLE_EXPORTS := "res://tests/fixtures/furniture-calibration/collaboration-table-v1/"
const TABLE_ID := "collaboration-cluster"

class CollaborationEditor extends "res://tools/calibrated_service_fixture.gd".ServiceEditor:
	func _build_interface() -> void:
		super._build_interface()
		_status.text = "COLLABORATION TABLE · dev review · no worker or saves"
		_facing_picker.tooltip_text = "Named service side. Every view is independently authored; no bitmap rotation."

func _ready() -> void:
	if not OS.has_feature("editor"):
		errors.append("Collaboration-table fixture requires editor-capable Godot")
		return
	previous_no_worker = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(TRANSPORT.NullWorker)
	add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	main._state_loaded = false
	main._worker_ready = false
	main.job_panel.set_worker_ready()
	main.founder_hud.dismiss_movement_hint()
	main._spawn_employees([])
	main.job_panel.close_drawer(false)
	main.company_panel.hide()

	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	data.player_spawn = [17, 18]
	# Reuse the production collaboration zone. Its five-by-two footprint and
	# service clearance are already outside the protected circulation spine.
	data.props = [{"id": TABLE_ID, "kind": "collaboration_cluster", "grid": [10, 13], "facing": initial_facing, "required_hires": 0}]
	data.employees = []
	catalog.collaboration_cluster.facings = OfficeLayout.FACINGS.duplicate()
	catalog.collaboration_cluster.facing_profiles = {}
	for facing: String in OfficeLayout.FACINGS:
		catalog.collaboration_cluster.facing_profiles[facing] = collaboration_profile(facing)

	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self):
		errors.append("Collaboration-table live model ownership rejected")
		return
	for facing: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_service_profile("collaboration_cluster", facing, self):
			errors.append("Collaboration-table candidate rejected: " + facing + " " + str(model.resolve_profile("collaboration_cluster", facing).errors))
	for stage: int in range(5):
		var validation := model.validate_placements(model.resolve_placements(stage))
		if not validation.valid: errors.append("Stage%d: %s" % [stage, str(validation.errors)])
	if not errors.is_empty(): return

	main.room.layout_model = model
	main.room.player_spawn = Vector2i(17, 18)
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(0)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 18))
	main.room.navigation.actors["founder"] = main.player.position
	editor = CollaborationEditor.new()
	editor.game = main
	add_child(editor)
	editor.select_placement(TABLE_ID)
	ready_ok = true

static func collaboration_profile(side: String) -> Dictionary:
	var geometry := TABLE_GEOMETRY.profile(side)
	if geometry.is_empty(): return {}
	var layers: Array[Dictionary] = []
	var depths := {"floor_shadow": -1, "rear_structure": 0, "front_structure": 1}
	for part: String in ["floor_shadow", "rear_structure", "front_structure"]:
		layers.append({
			"name": part.to_pascal_case(),
			"art": TABLE_EXPORTS + side + "-" + part + ".png",
			"region": [0, 0, TABLE_GEOMETRY.CANVAS.x, TABLE_GEOMETRY.CANVAS.y],
			"offset": [0, -40],
			"z_offset": depths[part],
		})
	var bounds := Rect2()
	for layer: Dictionary in layers:
		var ink := OfficeLayout.measured_layer_ink_bounds(layer)
		if not ink.has_area(): continue
		var destination := Vector2(OfficeLayout.vector(layer.offset)) - Vector2(TABLE_GEOMETRY.CANVAS) * 0.5 + ink.position
		var placed := Rect2(destination, ink.size)
		bounds = bounds.merge(placed) if bounds.has_area() else placed
	return {
		"profile_kind": "service",
		"status": "calibration_candidate",
		"review": {"art": false, "geometry": false},
		"service_side": side,
		"approach_gaze": OfficeLayout.OPPOSITE_GAZE[side],
		"approach_visual_bounds": [-24, -72, 48, 80],
		"occupied": geometry.occupied.duplicate(true),
		"clearance": geometry.clearance.duplicate(true),
		"interaction": geometry.interaction.duplicate(true),
		"anchor_offset": [0, 0],
		"visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
		"render_layers": layers,
		"ambient_overlays": [],
		"calibration_limitations": [
			"One standing lunch/service socket is represented; multi-seat character poses remain separate work.",
			"Candidate art and geometry are not production-approved by this fixture.",
		],
	}
