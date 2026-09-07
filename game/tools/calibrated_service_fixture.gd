extends Node
## DEV ONLY: real standing-service art, room, navigation, UI and editor. No worker,
## personal bootstrap/settings/save, seated capability, or production approval.
const GEOMETRY := preload("res://tools/modular_cabinet_geometry.gd")
const EXPORTS := "res://tests/fixtures/furniture-calibration/modular-archive-v1/"
const TRANSPORT := preload("res://tools/calibrated_workstation_fixture.gd")
var main: GameMain
var model: OfficeLayout
var editor: Node2D
var ready_ok := false
var errors: Array[String] = []
var initial_facing := "south"
var previous_no_worker := ""

class ServiceEditor extends "res://tools/calibrated_workstation_editor.gd":
	func _build_interface() -> void:
		super._build_interface()
		var panel := _inspector.get_parent() as PanelContainer
		panel.position.y = 610
		panel.custom_minimum_size.y = 102
		action_buttons["Sit"].hide()
		action_buttons["Type"].hide()
		action_buttons["Leave"].text = "Step away"
		action_buttons["Leave"].custom_minimum_size.x = 108
		_facing_picker.tooltip_text = "Service side; the standing founder faces the opposite gaze on arrival."
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		# The five-stage validator can repeat the same failure on several lines.
		# Show the heading plus the first actionable reason; retain every detail
		# in the tooltip and preview_result instead of growing off the viewport.
		if _status != null:
			_status.text = "CALIBRATION · " + "\n".join(message.split("\n").slice(0, 2))
	func _draw() -> void:
		super._draw()
		if placement_active and str(_candidate.get("profile_kind", "")) == "service":
			var bounds: Rect2 = _candidate.get("world_approach_visual_bounds", Rect2())
			bounds.position += room.global_position
			draw_rect(bounds, Color("6196c1"), false, 1)

func _ready() -> void:
	if not OS.has_feature("editor"):
		errors.append("Service fixture requires editor-capable Godot")
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
	# Credential state is already false. Calling the first-run notification
	# setter here would queue a connection modal after this fixture closes it.
	# Do not invent a configured key or dispatch onboarding in an art fixture.
	main.founder_hud.dismiss_movement_hint()
	main._spawn_employees([])
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	data.player_spawn = [17, 17]
	data.props = [{"id": "artifact-archive", "kind": "artifact_archive", "grid": [10, 15], "facing": initial_facing, "required_hires": 0}]
	data.employees = []
	var records: Array[EmployeeRecord] = []
	for index: int in range(2):
		var id := "mira" if index == 0 else "theo"
		var grid := Vector2i(10 + index * 14, 8)
		data.props.append({"id": id + "-workstation", "kind": "desk", "owner_id": id, "grid": [grid.x, grid.y], "facing": "south", "required_hires": 0})
		data.employees.append({"id": id, "name": "Mina" if index == 0 else "Theo", "spawn": [7 + index * 18, 17]})
		var record := EmployeeRecord.new()
		record.id = id
		record.display_name = "Mina" if index == 0 else "Theo"
		record.desk_grid = grid
		record.morale = 75
		records.append(record)
	catalog.artifact_archive.facings = OfficeLayout.FACINGS.duplicate()
	catalog.artifact_archive.facing_profiles = {}
	for facing: String in OfficeLayout.FACINGS:
		catalog.artifact_archive.facing_profiles[facing] = service_profile(facing)
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self):
		errors.append("Live model ownership rejected")
		return
	for facing: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_service_profile("artifact_archive", facing, self):
			errors.append("Exact archive candidate admission rejected: " + facing + " " + str(model.resolve_profile("artifact_archive", facing).errors))
	if not errors.is_empty(): return
	var validation := model.validate_placements(model.resolve_placements(2))
	if not validation.valid:
		errors.assign(validation.errors)
		return
	main.room.layout_model = model
	main.room.player_spawn = Vector2i(17, 17)
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main._spawn_employees(records)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 17))
	main.room.navigation.actors["founder"] = main.player.position
	main.job_panel.close_drawer(false)
	editor = ServiceEditor.new()
	editor.game = main
	add_child(editor)
	ready_ok = true

static func service_profile(side: String) -> Dictionary:
	var p: Dictionary = GEOMETRY.profile("archive", side)
	var layers: Array[Dictionary] = []
	for part: String in ["carcass", "top", "front", "plinth", "insert"]:
		layers.append({"name": "Archive" + part.capitalize(), "art": EXPORTS + side + "-" + part + ".png",
			"region": [0, 0, 192, 288], "offset": [0, -80], "z_offset": 0})
	var occupied: Array[Array] = []
	var clearance: Array[Array] = []
	for cell: Vector2i in p.occupied: occupied.append([cell.x, cell.y])
	for cell: Vector2i in p.clearance: clearance.append([cell.x, cell.y])
	var bounds := Rect2()
	for layer: Dictionary in layers:
		var ink := OfficeLayout.measured_layer_ink_bounds(layer)
		if ink.has_area():
			var placed := Rect2(Vector2(0, -80) - Vector2(96, 144) + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
	return {"profile_kind": "service", "status": "calibration_candidate", "review": {"art": false, "geometry": false},
		"service_side": side, "approach_gaze": p.approach_gaze, "approach_visual_bounds": [-24, -72, 48, 80],
		"occupied": occupied, "clearance": clearance, "interaction": [p.service_cell.x, p.service_cell.y],
		"anchor_offset": [0, 0], "visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
		"render_layers": layers, "ambient_overlays": [],
		"calibration_limitations": ["Archive candidate, not production approval.", "Standing service uses existing locomotion; there is no seated/reaching pose.", "Tall archive intentionally occludes an actor approaching from behind."]}

func send_to_desk(_employee_id: String, _typing := false) -> void:
	# Hidden inherited workstation buttons cannot create a false service pose.
	pass

func leave_desk(_employee_id: String) -> void:
	main.job_panel.close_drawer(false)
	main.player.input_blocked = false
	main.player.move_to(model.world(Vector2i(17, 17)))

func _exit_tree() -> void:
	if main != null and is_instance_valid(main) and main.game_audio != null: main.game_audio.shutdown()
	if model != null: model.disable_calibration_preview(self)
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", previous_no_worker)
