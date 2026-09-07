extends Node
## DEV ONLY. Actual calibration art through the ordinary room/actor pipeline.
## No worker, personal file/settings read, credential access, or production data write.
const FIX := "res://tests/fixtures/furniture-calibration/"
const EDITOR := preload("res://tools/calibrated_workstation_editor.gd")
var main: GameMain
var model: OfficeLayout
var editor: Node2D
var employee_ids: Array[String] = ["mira"]
var initial_facing := "south"
var pose_set_prefix := "dev-calibration-workstations"
var pose_set_id := ""
var ready_ok := false
var errors: Array[String] = []
var previous_no_worker := ""
# Dev-only A/B evidence can omit this capability to reproduce the old fallback.
# Quiet seated-idle frames are reused honestly; no additional art is generated.
var reuse_seated_idle_for_thinking := true
var attach_work_vfx_above_assembly := true

class NullWorker extends WorkerClient:
	var blocked_requests: Array[String] = []
	func start() -> void:
		blocked_requests.append("start blocked")
	func _send_request(method: String, _parameters: Dictionary, _job_id: String = "") -> void:
		blocked_requests.append(method)
		# No transport or persistence is constructed, even if a UI action fires.

func _ready() -> void:
	if not OS.has_feature("editor"):
		errors.append("Calibration fixture requires editor-capable Godot")
		return
	previous_no_worker = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	pose_set_id = "%s-%d" % [pose_set_prefix, get_instance_id()]
	if not CharacterArt.register_calibration_pose_set(pose_set_id, pose_registry(), self):
		errors.append("Actual calibration pose registry rejected")
		return
	main = load("res://world/main.tscn").instantiate() as GameMain
	# Replace the leaf transport before any ready callback. The real GameMain UI,
	# input, scheduling, avatars and navigation still run; no worker can start.
	main.get_node("WorkerClient").set_script(NullWorker)
	add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	main._state_loaded = false
	main._worker_ready = false
	main.job_panel.set_worker_ready()
	main.job_panel.set_credential_status(false)
	main.founder_hud.dismiss_movement_hint()
	# Discard only the temporary worker-disabled starter roster. Otherwise the
	# normal roster reuse path deliberately preserves its old home positions.
	main._spawn_employees([])
	model = OfficeLayout.new()
	model.enable_calibration_preview(self)
	var room_data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	room_data.props = []
	room_data.employees = []
	var records: Array[EmployeeRecord] = []
	for index: int in range(employee_ids.size()):
		var id := employee_ids[index]
		var grid := Vector2i(10 + index * 14, 8)
		room_data.props.append({"id": id + "-workstation", "kind": "desk", "owner_id": id, "grid": [grid.x, grid.y], "facing": initial_facing, "required_hires": 0})
		room_data.employees.append({"id": id, "name": "Mina" if id == "mira" else "Theo", "spawn": [grid.x, 17]})
		var record := EmployeeRecord.new()
		record.id = id
		record.display_name = "Mina" if id == "mira" else "Theo"
		record.desk_grid = grid
		record.morale = 75
		records.append(record)
	catalog.desk.facings = OfficeLayout.FACINGS.duplicate()
	catalog.desk.facing_profiles = {}
	for facing: String in OfficeLayout.FACINGS:
		catalog.desk.facing_profiles[facing] = profile(facing)
	model.configure(room_data, catalog)
	var validation := model.validate_placements(model.resolve_placements(employee_ids.size()))
	if not validation.valid:
		errors.assign(validation.errors)
		return
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main._spawn_employees(records)
	main.job_panel.close_drawer(false)
	for actor: EmployeeAvatar in main._employees.values(): actor.set_seat_transition_preview(true)
	editor = EDITOR.new()
	editor.game = main
	add_child(editor)
	ready_ok = true

func _exit_tree() -> void:
	if main != null and is_instance_valid(main) and main.game_audio != null: main.game_audio.shutdown()
	if model != null: model.disable_calibration_preview(self)
	if not pose_set_id.is_empty(): CharacterArt.unregister_calibration_pose_set(pose_set_id, self)
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", previous_no_worker)

func pose_registry() -> Dictionary:
	var characters := {}
	for id: String in ["mira", "theo"]:
		var sheets := {"south": CharacterArt.seated_sheet(id)}
		for facing: String in ["north", "east", "west"]:
			var suffix := {"mira": {"north": "v2", "east": "v3", "west": "v2"}, "theo": {"north": "v2", "east": "v4", "west": "v3-registered"}}[id][facing] as String
			var source := Image.load_from_file(ProjectSettings.globalize_path(FIX + "characters/%s-%s-seated-%s.png" % [id, facing, suffix]))
			if source == null: return {}
			sheets[facing] = ImageTexture.create_from_image(source)
		characters[id] = sheets
	var facings := {}
	for facing: String in OfficeLayout.FACINGS:
		var poses := {}
		for pose: String in ["seated", "typing"]:
			var count := 2 if pose == "seated" else 4
			var definition := {"sheet": facing, "row": 0, "column": 0 if pose == "seated" else 2, "frames": count}
			if facing != "north" or pose_set_id.begins_with("dev-calibration-complete-north-"):
				var cuts := {}
				for id: String in ["mira", "theo"]:
					var rows: Array[int] = []
					for frame: int in range(count):
						var cut := 52 if facing == "east" else 50
						if facing == "north": cut = 48
						if facing == "west" and id == "theo": cut = 47 if pose == "typing" and frame < 3 else 48
						rows.append(cut)
					cuts[id] = rows
				definition.cuts_by_character = cuts
			poses[pose] = definition
		if reuse_seated_idle_for_thinking:
			var thinking: Dictionary = poses.seated.duplicate(true)
			thinking.reuse_pose = "seated"
			thinking.presentation = "quiet_seated_thinking"
			poses["thinking"] = thinking
		if attach_work_vfx_above_assembly:
			var attachments := work_vfx_anchors(facing, characters)
			for pose: String in ["thinking", "typing"]:
				if poses.has(pose): poses[pose]["work_vfx_anchor_by_character"] = attachments.duplicate(true)
		facings[facing] = poses
	return {"characters": characters, "facings": facings}

func work_vfx_anchors(facing: String, characters: Dictionary) -> Dictionary:
	var geometry := profile(facing)
	var work_foot := Vector2(OfficeLayout.vector(geometry.work_cell)) * 32.0
	var attachment_by_actor := {}
	for id: String in ["mira", "theo"]:
		var sheet: Texture2D = characters[id][facing]
		var image := sheet.get_image()
		var first_ink_y := 80
		for frame: int in range(6):
			var ink := image.get_region(Rect2i(frame * 48, 0, 48, 80)).get_used_rect()
			if ink.has_area(): first_ink_y = mini(first_ink_y, ink.position.y)
		var seat := Vector2(OfficeLayout.vector(geometry.seat_anchor_by_employee[id]))
		# Enclose the real source head both before and after the visual seat
		# correction; the full24px cue clears this and all furniture by4px.
		var head_top := work_foot.y + minf(0, seat.y) - 72.0 + first_ink_y
		var top := minf(float(geometry.visual_bounds[1]), head_top)
		attachment_by_actor[id] = [roundi(work_foot.x + seat.x), floori(top - 4.0 - 12.0)]
	return attachment_by_actor

func layer(name_value: String, path: String, canvas: Vector2i, pivot: Vector2i, attachment: Vector2i, depth: int) -> Dictionary:
	return {"name": name_value, "art": FIX + path, "region": [0, 0, canvas.x, canvas.y], "offset": [attachment.x + canvas.x / 2 - pivot.x, attachment.y + canvas.y / 2 - pivot.y], "z_offset": depth}

func profile(facing: String) -> Dictionary:
	var gaze: Vector2i = {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}[facing]
	var axis := Vector2i(-gaze.y, gaze.x)
	var occupied: Array[Array] = []
	var clearance: Array[Array] = []
	for index: int in range(-1, 2):
		var cell := axis * index
		occupied.append([cell.x, cell.y])
		var back := cell - gaze
		clearance.append([back.x, back.y])
	clearance.append([gaze.x, gaze.y])
	var layers: Array[Dictionary] = []
	for part: String in ["rear", "front"]:
		layers.append(layer("Desk" + part.capitalize(), "modular-desk-v1/%s-%s.png" % [facing, part], Vector2i(192, 224), Vector2i(96, 160), Vector2i.ZERO, -1 if part == "rear" else 1))
	var chair_from_work: Vector2i = {"north": Vector2i(0, -12), "east": Vector2i(12, 0), "south": Vector2i(0, 4), "west": Vector2i(-12, 0)}[facing]
	var chair_from_desk := -gaze * 32 + chair_from_work
	if facing in ["east", "west"]:
		layers.append(layer("ChairRear", "chair-layers-v1/%s-rear.png" % facing, Vector2i(96, 160), Vector2i(48, 112), chair_from_desk, -5))
		layers.append(layer("ChairNearArm", "chair-layers-v1/%s-front.png" % facing, Vector2i(96, 160), Vector2i(48, 112), chair_from_desk, -3))
	else:
		layers.append(layer("ChairWhole", "chair-%s-v%d.png" % [facing, 1 if facing == "north" else 3], Vector2i(96, 160), Vector2i(48, 112), chair_from_desk, 21 if facing == "north" else -2))
	var device_prefix := {"north": "computer-north-v2", "east": "computer-east-v4", "west": "computer-west-v2", "south": "computer-south-peripherals-v2"}[facing] as String
	var device_shift: Vector2i = Vector2i(0, 4) if facing == "north" else Vector2i(6, 0) if facing == "east" else Vector2i.ZERO
	for part: String in ["keyboard", "mouse"]:
		layers.append(layer(part.capitalize(), "kits/%s-%s.png" % [device_prefix, part], Vector2i(192, 224), Vector2i(96, 160), device_shift, 2 if facing in ["north", "south"] else 1))
	var monitor_path := "computer-south-v3.png" if facing == "south" else device_prefix + "-monitor.png"
	var monitor_shift := Vector2i(0, -10) if facing == "north" else Vector2i(0, 3) if facing == "south" else Vector2i.ZERO
	layers.append(layer("Monitor", "kits/" + monitor_path, Vector2i(192, 224), Vector2i(96, 160), monitor_shift, 2 if facing == "north" else 4 if facing == "south" else 3))
	var bounds := Rect2()
	for entry: Dictionary in layers:
		var region := OfficeLayout.rectangle(entry.region)
		var origin := Vector2(OfficeLayout.vector(entry.offset)) - region.size * 0.5
		var ink := OfficeLayout.measured_layer_ink_bounds(entry)
		if ink.has_area():
			var placed := Rect2(origin + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
	var anchors: Dictionary = {"north": {"mira": [0, -20], "theo": [0, -16]}, "east": {"mira": [12, 3], "theo": [12, 4]}, "south": {"mira": [0, 12], "theo": [0, 12]}, "west": {"mira": [-12, 4], "theo": [-12, 8]}}[facing]
	var result := {"status": "calibration_candidate", "review": {"art": false, "geometry": false, "poses": false}, "calibration_limitations": ["Unapproved calibration art; no production activation.", {"north": "Seat support inferred; whole rear chair hides hips; hand samples incomplete.", "east": "Small upper lap strip and Theo borderline key-edge contact remain.", "south": "Monitor naturally hides hands; finish and sit transition not yet approved.", "west": "Theo one-pixel exposed sole/cushion variation remains."}[facing]], "occupied": occupied, "clearance": clearance, "interaction": [gaze.x, gaze.y], "work_cell": [-gaze.x, -gaze.y], "anchor_offset": [0, 0], "visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)], "hit_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)], "seat_anchor": anchors.mira, "seat_anchor_by_employee": anchors, "seat_z_offset": 20 if facing == "north" else 3 if facing == "south" else 2, "pose_set": pose_set_id, "work_facing": facing, "render_layers": layers, "ambient_overlays": []}
	if facing != "north": result.seat_layer_z_offsets = {"upper": 3 if facing == "south" else 2, "lower": 0 if facing == "south" else -4}
	result.seat_pose_depth_lock = true
	return result

func send_to_desk(id: String, typing := false) -> void:
	var actor := main.get_employee(id)
	if actor == null: return
	main.job_panel.close_drawer(false)
	actor.world_paused = false
	if typing and actor.is_at_desk():
		# Reproduce the normal event order. job.started takes the exact-target
		# navigation path, reacquires the seat reservation and resolves in place;
		# the following tool event changes presentation without a fake re-seat.
		var started := WorkerEventRecord.new()
		started.type = &"job.started"
		actor.apply_worker_event(started, main.player.position)
		var event := WorkerEventRecord.new()
		event.type = &"tool.started"
		event.tool = "write_file"
		actor.apply_worker_event(event, main.player.position)
	else:
		actor.has_live_job = typing
		actor.walk_to(actor.desk_position, EmployeeAvatar.WorkState.WALKING_TO_DESK, EmployeeAvatar.WorkState.TYPING if typing else EmployeeAvatar.WorkState.SITTING)

func leave_desk(id: String) -> void:
	var actor := main.get_employee(id)
	if actor == null: return
	main.job_panel.close_drawer(false)
	actor.world_paused = false
	actor.has_live_job = false
	actor.walk_to(actor.home_position, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
