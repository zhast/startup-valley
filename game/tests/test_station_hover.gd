extends "res://tests/test_visible_surface_picking.gd"
## Actual input through production GameMain, no saved state or worker transport.
const HOVER_OUTPUT := "res://tests/output/station-hover"
var samples: Array[Dictionary] = []

func hover(point: Vector2) -> void:
	# Native windows query their real cursor; headless uses Input's event cache.
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await frames(1)
	main._process(0)
	check(root.get_mouse_position() == point, "Real motion updates the viewport cursor used by the production picker")

func verify(label: String, target: String) -> void:
	var hud := main.founder_hud
	check(hud.station_hover_target_id() == target, "Hover selects %s, got %s" % [target, hud.station_hover_target_id()])
	if target.is_empty():
		check(not hud.station_hover_rect().has_area(), "Absent/blocked target has no lingering paper")
		return
	check(hud._station_callout.caption == label, "Station action reads " + label)
	var painted := hud.station_hover_rect()
	check(painted.has_area(), "Station callout is visibly placed")
	check(Rect2(18, 82, 1114, 620).encloses(painted), "Paper and pointer remain inside unobscured playfield")
	var occupied := main._world_ui_obstacles()
	occupied.append(WorldCalloutSkin.actor_rect(main.player.position))
	for actor: EmployeeAvatar in main._employees.values(): occupied.append(WorldCalloutSkin.actor_rect(actor.render_position()))
	for obstacle: Rect2 in occupied: check(not painted.intersects(obstacle), "Station paper/pointer never covers furniture, actors, HUD or rail")
	check(not hud.interaction_visible(), "Station hover never duplicates employee Chat paper")
	check(hud._station_callout.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Callout cannot steal world or UI clicks")
	var font := GameFonts.BOLD
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	check(width <= hud._station_callout.size.x - 24, "Whole action label fits its measured quiet paper")
	check(hud._station_callout.position == hud._station_callout.position.round(), "Station paper is integer-snapped")
	for actor: EmployeeAvatar in main._employees.values():
		if not actor.labels_suppressed: check(not painted.intersects(actor.world_label_rect()), "World identity yields to station discovery")
	samples.append({"target": target, "caption": label, "painted": str(painted), "body": str(hud._station_callout.get_global_rect()), "point": str(root.get_mouse_position())})

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	RenderingServer.force_draw(false)
	var path := HOVER_OUTPUT.path_join(name_value + ".png")
	check(root.get_texture().get_image().save_png(path) == OK, "Save station evidence " + name_value)
	captures.append(path)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.notify_mouse_entered()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HOVER_OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(FIXTURE.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	await settle()
	main.room.set_hire_count(4)
	var actor := main.get_employee("mira")
	actor.position = actor.desk_position
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._has_target = false
	actor._route.clear()
	actor._animation_elapsed = 0
	actor._update_character_frame()
	main.player.position = Vector2(272, 496)
	var geometry := state()
	for spec: Array in [[Vector2(132, 400), "Studio", "artifact-archive"], [Vector2(272, 522), "Company Journey", "founder-workstation"], [Vector2(944, 376), "Activity", "approval-console"], [Vector2(336, 234), "Assign", "mira-workstation"]]:
		await hover(spec[0])
		verify(spec[1], spec[2])
		await capture(spec[2])
		await click(spec[0])
		check(main._pending_interaction == spec[2], "Showing a hover callout does not steal the actual station click")
		main.player.cancel_route()
	check(state() == geometry, "Hover does not alter poses, feet, routing, clock or office geometry")
	main.player.input_blocked = true
	await frames(1)
	verify("", "")
	main.player.input_blocked = false
	await hover(Vector2(210, 466))
	verify("", "")
	await hover(Vector2(336, 194))
	verify("", "")
	check(actor._ui_highlighted, "Visible face shows employee hover, never desk discovery")
	await capture("visible-face-not-desk")
	main.player.position = Vector2(400, 240)
	await hover(Vector2(336, 234))
	verify("Assign", "mira-workstation")
	check(main.founder_hud.interaction_target_id() == "mira", "Station discovery preserves nearby employee E interaction")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.physical_keycode = KEY_E
	key_event.pressed = true
	root.push_input(key_event, true)
	key_event.pressed = false
	root.push_input(key_event, true)
	await frames(1)
	main._process(0)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Real E still opens nearby employee Chat while station paper is shown")
	verify("", "")
	main.job_panel.close_drawer(false)
	main.player.position = Vector2(272, 496)
	main.job_panel.begin_job("hover-local-job", "mira")
	main.job_panel.close_drawer(false)
	await hover(Vector2(336, 234))
	verify("Activity", "mira-workstation")
	var event := WorkerEventRecord.new()
	event.type = &"approval.required"
	event.approval_id = "hover-local-approval"
	event.action = "Review this local fixture"
	main.job_panel.on_job_event("hover-local-job", event)
	await hover(Vector2(944, 376))
	verify("Review approval", "approval-console")
	await capture("pending-approval")
	main.job_panel.open_chat_for_employee("mira")
	await hover(Vector2(944, 376))
	verify("", "")
	await create_timer(0.22).timeout
	await capture("drawer-suppressed")
	main.job_panel.close_drawer(false)
	main.company_panel.present("settings")
	await hover(Vector2(132, 400))
	verify("", "")
	main.company_panel.hide()
	await hover(Vector2(132, 400))
	verify("Studio", "artifact-archive")
	# Removal is ordinary room rebuild; same cursor must not retain stale target.
	main.room.set_hire_count(0)
	await hover(Vector2(132, 400))
	verify("", "")
	await capture("removed-station")
	main.room.set_hire_count(4)
	# Crowd the upper archive candidate with a physical founder silhouette.
	main.player.position = Vector2(144, 348)
	await hover(Vector2(132, 400))
	verify("Studio", "artifact-archive")
	await capture("archive-crowded")
	# Actual approved service profile near the left wall, plus right-rail console.
	await hover(Vector2(944, 376))
	verify("Review approval", "approval-console")
	await capture("console-near-rail")
	var ui_cover := Button.new()
	ui_cover.position = Vector2(910, 350)
	ui_cover.size = Vector2(70, 50)
	ui_cover.text = "Fixture"
	main.get_node("Interface").add_child(ui_cover)
	await frames(3)
	await hover(Vector2(944, 376))
	verify("", "")
	await click(Vector2(944, 376))
	check(main.player.route.is_empty(), "Interactive UI over a station owns the click")
	ui_cover.queue_free()
	await frames()
	# A fully occupied local perimeter fails closed, never covering a face to
	# force a label. This is a placement-only helper case, not fabricated room art.
	main.founder_hud.update_station_hover("fixture-crowded", "Studio", Rect2(300, 250, 96, 96), true, [Rect2(18, 82, 1114, 620)])
	verify("", "")
	await hover(Vector2(500, 420))
	verify("", "")
	await capture("pointer-left-clears")
	check(samples.size() >= 9, "All expected hover scenarios completed")
	var results := {"checks": checks, "failures": failures, "samples": samples, "captures": captures}
	var file := FileAccess.open(HOVER_OUTPUT.path_join("headless.json" if DisplayServer.get_name() == "headless" else "results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  "))
	print(JSON.stringify(results))
	cleanup()
	quit(0 if failures.is_empty() else 1)
