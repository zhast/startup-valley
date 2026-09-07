extends "res://tests/test_seat_transition.gd"
## Mechanism-only native evidence with existing south art. Not an accepted
## furniture assembly or directional-pose preview.

const OUTPUT := "res://tests/output/seat-transition"
var actors: Array[EmployeeAvatar] = []
var captures: Array[String] = []
var caption: Label
var scene: Node2D
var ui: CanvasLayer

class FootGuides extends Node2D:
	func _draw() -> void:
		for point: Vector2 in [Vector2(400, 360), Vector2(816, 360)]:
			draw_rect(Rect2(point - Vector2(24, 72), Vector2(48, 80)), Color("6196C1"), false, 1.0)
			draw_line(point - Vector2(8, 0), point + Vector2(8, 0), Color("FA4616"), 1.0)
			draw_line(point - Vector2(0, 8), point + Vector2(0, 8), Color("FA4616"), 1.0)

func paper(text_value: String, at: Vector2, width: float) -> Label:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(width, 44)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(16, 12, 16, 12)))
	var label := Label.new()
	CozyUI.label(label, "body")
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	ui.add_child(panel)
	return label

func build() -> void:
	scene = Node2D.new()
	root.add_child(scene)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	scene.add_child(room)
	room.load_layout()
	room.set_hire_count(0)
	room.get_node("Props").hide()
	var guides := FootGuides.new()
	guides.z_index = 2000
	scene.add_child(guides)
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	paper("SEAT TRANSITION MECHANISM · geometry-only offsets using existing SOUTH art", Vector2(176, 120), 864)
	paper("Red cross = unchanged physical foot · blue box = original standing cell", Vector2(206, 510), 804)
	paper("No north pose, chair support, hand contact or production facing is approved here.", Vector2(166, 574), 884)
	caption = paper("Standing", Vector2(304, 202), 608)
	for index: int in range(2):
		var actor := actor_for("mira" if index == 0 else "theo")
		actor.position = Vector2(400 + 416 * index, 360)
		actor.desk_position = actor.position
		actor.navigation.actors[actor.employee_id] = actor.position
		actor.navigation.reservations[actor.employee_id] = actor.navigation.cell_at(actor.position)
		actor.configure_workstation_visual(geometry(actor, -16 if index == 0 else 16))
		actor.set_seat_transition_preview(true)
		actor._set_activity(&"typing")
		actor.set_interaction_highlighted(true)
		actors.append(actor)

func snap(name_value: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Mechanism capture keeps native1280×720 composition")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save mechanism evidence " + name_value)
	captures.append(name_value + ".png")
	print("Seat transition capture: " + name_value)

func advance(phase: String, count: int) -> void:
	for step: int in range(count):
		var offsets: Array[String] = []
		for actor: EmployeeAvatar in actors:
			var before := physical(actor)
			actor._physics_process(1.0 / 60.0)
			check(physical(actor) == before, "Native transition leaves physical navigation unchanged")
			shared_geometry(actor)
			offsets.append("%s: %dpx / z%d" % [actor.display_name, actor.seated_render_offset().y, actor.z_index])
		caption.text = "%s · %s" % [phase, " · ".join(offsets)]
		await RenderingServer.frame_post_draw

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	if DisplayServer.get_name() == "headless":
		print("Use test_seat_transition.gd for headless checks; this is a rendered-only dev capture.")
		quit(0)
		return
	build()
	await snap("standing")
	for actor: EmployeeAvatar in actors: enter(actor)
	await snap("seat-start")
	await advance("Sitting down", 4)
	await snap("seat-middle")
	await advance("Seated", 5)
	await snap("seated")
	await advance("Seated", 20)
	for actor: EmployeeAvatar in actors:
		actor.apply_worker_event(event(&"job.failed", "", "Cancelled by player"), actor.position)
	await snap("stand-start")
	await advance("Standing up after cancellation", 4)
	await snap("stand-middle")
	await advance("Standing", 5)
	await snap("stand-complete")
	await advance("Standing", 15)
	for actor: EmployeeAvatar in actors: enter(actor)
	await advance("Sit interrupted", 3)
	for actor: EmployeeAvatar in actors:
		actor.walk_to(actor.position + Vector2(64, 0), EmployeeAvatar.WorkState.WANDERING)
	await snap("interrupted-current-position")
	await advance("Reversing without a snap", 9)
	await snap("interrupted-standing")
	var file := FileAccess.open(OUTPUT.path_join("results-rendered.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "workerDisabled": true, "geometryOnly": true, "registeredFacings": ["south"], "previewDefaultOff": true, "durationMs": 140, "renderer": DisplayServer.get_name()}, "\t"))
	for actor: EmployeeAvatar in actors: actor.free()
	scene.free()
	ui.free()
	print("seat_transition_rendered: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
