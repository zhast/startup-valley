extends SceneTree
## Real production sprites, texture alpha and absolute scene depth, not a mock
## chair. Optional --capture records the same scenes through the renderer.

const OUTPUT := "res://tests/output/seated-chair-composition"
var main: GameMain
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var capture_enabled := false

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for tick: int in range(3): await process_frame

func prop_sprites(prop: Node) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child: Node in prop.get_children():
		if child is Sprite2D: result.append(child)
	return result

func is_chair(sprite: Sprite2D) -> bool:
	return sprite != null and str(sprite.name).begins_with("Chair")

func is_desk(sprite: Sprite2D) -> bool:
	return sprite != null and str(sprite.name).begins_with("Desk")

func measure(prop: Node, actor: EmployeeAvatar) -> Dictionary:
	var furniture := prop_sprites(prop)
	var all := furniture.duplicate()
	var without_lower := furniture.duplicate()
	var upper: Sprite2D = actor._work_pose_layer_sprites.upper
	var lower: Sprite2D = actor._work_pose_layer_sprites.lower
	all.append(upper)
	all.append(lower)
	without_lower.append(upper)
	var anchor: Vector2 = actor._workstation_visual.prop_anchor
	var result := {"chair_visible": 0, "chair_body_overlap": 0, "chair_hidden_by_body": 0,
		"desk_body_overlap": 0, "desk_hidden_by_body": 0, "head_pixels": 0, "head_obscured": 0}
	for y: int in range(-96, 40):
		for x: int in range(-64, 64):
			var point := anchor + Vector2(x + 0.5, y + 0.5)
			var top := VisibleSurface.top(all, point)
			if is_chair(top): result.chair_visible += 1
			if not VisibleSurface.painted(lower, point): continue
			# A near chair part must remain visible over the seated lower body.
			# South is intentionally the far chair, behind the whole character.
			var exposed := VisibleSurface.top(without_lower, point)
			var facing := str(actor._workstation_visual.work_facing)
			var near_chair := exposed != null and ((facing == "north" and str(exposed.name) == "ChairWhole") or (facing in ["east", "west"] and str(exposed.name) == "ChairNearArm"))
			if near_chair:
				result.chair_body_overlap += 1
				if top != exposed: result.chair_hidden_by_body += 1
			if is_desk(exposed):
				result.desk_body_overlap += 1
				if top == lower: result.desk_hidden_by_body += 1
	# The first32 source rows hold the head/face in every admitted pose. Use
	# actual alpha so blank padding cannot make this protection pass vacuously.
	for y: int in range(32):
		for x: int in range(48):
			var point := upper.to_global(Vector2(x + 0.5, y + 0.5))
			if not VisibleSurface.painted(upper, point): continue
			result.head_pixels += 1
			if VisibleSurface.top(all, point) != upper: result.head_obscured += 1
	return result

func empty_chair_desk_overlap(prop: Node) -> Dictionary:
	var all := prop_sprites(prop)
	var chairs: Array[Sprite2D] = []
	var desks: Array[Sprite2D] = []
	for sprite: Sprite2D in all:
		if is_chair(sprite): chairs.append(sprite)
		if is_desk(sprite): desks.append(sprite)
	var result := {"overlap": 0, "chair_over_desk": 0}
	for y: int in range(-96, 40):
		for x: int in range(-64, 64):
			var point: Vector2 = prop.global_position + Vector2(x + 0.5, y + 0.5)
			if VisibleSurface.top(chairs, point) == null or VisibleSurface.top(desks, point) == null: continue
			result.overlap += 1
			if is_chair(VisibleSurface.top(all, point)): result.chair_over_desk += 1
	return result

func capture(facing: String, state_name: String) -> void:
	if not capture_enabled: return
	await frames()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Capture keeps native1280x720 viewport")
	check(image.save_png(OUTPUT.path_join(facing + "-" + state_name + ".png")) == OK, "Write actual room capture")
	for id: String in ["mira", "theo"]:
		var anchor: Vector2 = main.room.placement_by_id(id + "-workstation").anchor
		var detail := image.get_region(Rect2i(Vector2i(anchor) + Vector2i(-88, -136), Vector2i(176, 192)))
		detail.resize(528, 576, Image.INTERPOLATE_NEAREST)
		check(detail.save_png(OUTPUT.path_join(facing + "-" + state_name + "-" + id + ".png")) == OK, "Write nearest3x detail")

func pose(actor: EmployeeAvatar, typing: bool, frame: int) -> void:
	actor.position = actor.desk_position
	actor._has_target = false
	actor._route.clear()
	actor.has_live_job = typing
	actor.work_state = EmployeeAvatar.WorkState.TYPING if typing else EmployeeAvatar.WorkState.SITTING
	actor._animation_elapsed = 0
	actor._update_character_frame()
	actor._physics_process(0.15)
	actor._animation_elapsed = float(frame) / (8.0 if typing else 1.5)
	actor._update_character_frame()

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.unfocusable = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	check(not capture_enabled or DisplayServer.get_name() != "headless", "Captures require a real renderer")
	if capture_enabled and DisplayServer.get_name() == "headless":
		quit(1)
		return
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames()
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.player.set_physics_process(false)
	main.player.hide()
	main.get_node("Interface").hide()
	main.room.set_hire_count(2)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Composition is provider-free")
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
		actor.hide()
		actor.labels_suppressed = true
		actor._label_layer.hide()
	for facing: String in ["north", "south", "east", "west"]:
		check(main.room.set_placement_overrides({"mira-workstation": {"grid": [10, 8], "facing": facing}, "theo-workstation": {"grid": [20, 8], "facing": facing}}), "Production placement resolves: " + facing)
		main._on_room_placements_changed()
		for actor: EmployeeAvatar in main._employees.values(): actor.hide()
		await capture(facing, "empty")
		for id: String in ["mira", "theo"]:
			var prop := main.room.prop_node(id + "-workstation")
			var empty := empty_chair_desk_overlap(prop)
			check(empty.chair_over_desk == 0, id + "/" + facing + " empty chair stays behind desk")
			if facing == "north":
				check(empty.overlap > 0, "North empty-chair test samples real desk intersection")
				var chair := prop.get_node("ChairWhole") as Sprite2D
				var original_depth := chair.z_index
				chair.z_index = roundi(prop.global_position.y) + 1
				check(empty_chair_desk_overlap(prop).chair_over_desk > 0, "Negative control rejects raising whole chair through desktop")
				chair.z_index = original_depth
			main.get_employee(id).show()
		for typing: bool in [false, true]:
			for frame: int in range(4 if typing else 2):
				for id: String in ["mira", "theo"]:
					var actor := main.get_employee(id)
					pose(actor, typing, frame)
					var prop := main.room.prop_node(id + "-workstation")
					var result := measure(prop, actor)
					var label := "%s/%s/%s/%d" % [id, facing, "typing" if typing else "idle", frame]
					observations.append({"pose": label, "pixels": result})
					check(result.chair_visible > 0, label + " chair remains visible")
					check(result.chair_hidden_by_body == 0, label + " near chair remains in front of lower body")
					check(result.desk_hidden_by_body == 0, label + " desk covers seated lower body")
					check(result.head_pixels > 0 and result.head_obscured == 0, label + " actual head pixels stay clear")
					if facing == "north":
						check(result.chair_body_overlap > 0, label + " samples real chair/body intersection")
						var lower: Sprite2D = actor._work_pose_layer_sprites.lower
						var original_depth := lower.z_index
						lower.z_index = roundi(Vector2(actor._workstation_visual.prop_anchor).y)
						check(measure(prop, actor).chair_hidden_by_body > 0, label + " reproduces old disappearing backrest at original depth")
						lower.z_index = original_depth
				if frame == 0: await capture(facing, "typing" if typing else "seated")
	var report := {"checks": checks, "failures": failures, "observations": observations, "rendered": capture_enabled}
	FileAccess.open(OUTPUT.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	print("Seated chair composition: %d checks, %d failures; %d real poses" % [checks, failures.size(), observations.size()])
	main.game_audio.shutdown()
	main.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
