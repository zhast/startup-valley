extends Node
## DEV ONLY: the exported coffee candidate through the real GameMain/TownRoom
## native-layer path. It uses owner-scoped calibration admission and null worker;
## no production catalogue, save, credential, or coffee action is changed.
const COFFEE := preload("res://tools/coffee_station_geometry.gd")
const TRANSPORT := preload("res://tools/calibrated_workstation_fixture.gd")
const EXPORT := "res://tests/fixtures/furniture-calibration/coffee-station-code-v1/"
var main: GameMain
var model: OfficeLayout
var ready_ok := false
var errors: Array[String] = []
var initial_facing := "south"
var initial_grid := Vector2i(10, 15)
var previous_no_worker := ""

func _ready() -> void:
	if not OS.has_feature("editor"):
		errors.append("Coffee candidate fixture requires editor-capable Godot")
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
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	data.player_spawn = [17, 17]
	data.props = [{"id": "coffee-station", "kind": "coffee_station", "grid": [initial_grid.x, initial_grid.y], "facing": initial_facing, "required_hires": 0}]
	data.employees = []
	catalog.coffee_station.facings = OfficeLayout.FACINGS.duplicate()
	catalog.coffee_station.facing_profiles = {}
	for side: String in OfficeLayout.FACINGS:
		catalog.coffee_station.facing_profiles[side] = service_profile(side)
	model = OfficeLayout.new()
	model.configure(data, catalog)
	if not model.enable_calibration_preview(self):
		errors.append("Live calibration ownership rejected")
		return
	for side: String in OfficeLayout.FACINGS:
		if not model.authorize_calibration_service_profile("coffee_station", side, self):
			errors.append("Coffee candidate admission rejected: " + side + " " + str(model.resolve_profile("coffee_station", side).errors))
	if not errors.is_empty(): return
	var validation := model.validate_placements(model.resolve_placements(0))
	if not validation.valid:
		errors.assign(validation.errors)
		return
	main.room.layout_model = model
	main.room.player_spawn = Vector2i(17, 17)
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(0)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(17, 17))
	main.room.navigation.actors["founder"] = main.player.position
	main.job_panel.close_drawer(false)
	main.company_panel.hide()
	ready_ok = main.room.prop_node("coffee-station") != null
	if not ready_ok: errors.append("Actual TownRoom did not build the candidate prop")

static func layer_path(side: String, layer_name: String) -> String:
	return EXPORT + side + "-" + layer_name.to_snake_case() + ".png"

static func service_profile(side: String) -> Dictionary:
	var geometry: Dictionary = COFFEE.profile(side)
	if geometry.is_empty(): return {}
	var order: Array[String] = ["FloorShadow", "CounterCarcass", "CounterTop", "CounterFront", "CounterPlinth", "ServicePanel"]
	for component: String in geometry.component_order: order.append(component)
	var layers: Array[Dictionary] = []
	var visual := Rect2()
	var hit := Rect2()
	var destination_origin := Vector2(-96, -192)
	for layer_name: String in order:
		var layer := {"name": "Coffee" + layer_name, "art": layer_path(side, layer_name),
			"region": [0, 0, COFFEE.CANVAS.x, COFFEE.CANVAS.y], "offset": [0, -64],
			"z_offset": -1 if layer_name == "FloorShadow" else 0}
		layers.append(layer)
		var ink := OfficeLayout.measured_layer_ink_bounds(layer)
		if ink.has_area():
			var placed := Rect2(destination_origin + ink.position, ink.size)
			visual = visual.merge(placed) if visual.has_area() else placed
			if layer_name != "FloorShadow": hit = hit.merge(placed) if hit.has_area() else placed
	var occupied: Array[Array] = []
	var clearance: Array[Array] = []
	for cell: Vector2i in geometry.occupied: occupied.append([cell.x, cell.y])
	for cell: Vector2i in geometry.clearance: clearance.append([cell.x, cell.y])
	return {"profile_kind": "service", "status": "calibration_candidate",
		"review": {"art": false, "geometry": false}, "service_side": side,
		"approach_gaze": geometry.approach_gaze, "approach_visual_bounds": [-24, -72, 48, 80],
		"occupied": occupied, "clearance": clearance,
		"interaction": [geometry.service_cell.x, geometry.service_cell.y], "anchor_offset": [0, 0],
		"visual_bounds": [int(visual.position.x), int(visual.position.y), int(visual.size.x), int(visual.size.y)],
		"hit_bounds": [int(hit.position.x), int(hit.position.y), int(hit.size.x), int(hit.size.y)],
		"render_layers": layers, "ambient_overlays": [],
		"calibration_limitations": ["Code-native coffee candidate; not production catalogue registration.", "Existing standing locomotion only; no reaching, pouring or drinking pose.", "Coffee remains decorative until a separate product decision supplies an action."]}

func set_facing(side: String) -> bool:
	if not ready_ok or side not in OfficeLayout.FACINGS: return false
	return main.room.set_placement_overrides({"coffee-station": {"grid": [initial_grid.x, initial_grid.y], "facing": side}})

func _exit_tree() -> void:
	if main != null and is_instance_valid(main) and main.game_audio != null: main.game_audio.shutdown()
	if model != null: model.disable_calibration_preview(self)
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", previous_no_worker)
