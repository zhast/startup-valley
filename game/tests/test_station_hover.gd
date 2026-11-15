extends "res://tests/test_visible_surface_picking.gd"
## Actual input through production GameMain, no saved state or worker transport.
const HOVER_OUTPUT := "res://tests/output/station-hover-current"
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
		var highlighted: Array[Sprite2D] = main.interaction_highlight.active_sources()
		check(not highlighted.is_empty(), "Interactive station has a visible warm highlight")
		for source: Sprite2D in highlighted:
			check(source.get_parent() == main.room.prop_node(spec[2]), "Only the picked station's registered body layers glow")
			check(source.material == null, "Hover does not replace the station's original material")
		if spec[2] == "founder-workstation":
			main.interaction_highlight.sync([])
			await capture("founder-workstation-before-glow")
			main._update_hover_highlight(main._interaction_at(spec[0]))
		await capture(spec[2])
		await click(spec[0])
		check(main._pending_interaction == spec[2], "Showing a hover callout does not steal the actual station click")
		check(main.click_feedback.position == spec[0], "Station click feedback stays at the pointer, not the navigation socket")
		main.player.cancel_route()
	check(state() == geometry, "Hover does not alter poses, feet, routing, clock or office geometry")
	main.player.input_blocked = true
	await frames(1)
	verify("", "")
	main.player.input_blocked = false
	await hover(Vector2(210, 466))
	verify("", "")
	check(main.interaction_highlight.active_sources().is_empty(), "Transparent sprite padding does not activate glow")
	await hover(Vector2(336, 194))
	verify("", "")
	check(actor._ui_highlighted, "Visible face shows employee hover, never desk discovery")
	check(main.interaction_highlight.active_sources().has(actor.body_surface_at(Vector2(336, 194))), "Hover highlights the visible employee body layer")
	check(not main.interaction_highlight.active_sources().has(actor._shadow_sprite) and not main.interaction_highlight.active_sources().has(actor._effect_sprite), "Employee shadows and work effects never glow")
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
	check(main.interaction_highlight.active_sources().is_empty(), "Opening the employee drawer clears hover glow")
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
	check(main.interaction_highlight.active_sources().is_empty(), "Modal settings clear hover glow")
	main.company_panel.hide()
	await hover(Vector2(132, 400))
	verify("Studio", "artifact-archive")
	# Removal is ordinary room rebuild; same cursor must not retain stale target.
	main.room.set_hire_count(0)
	await hover(Vector2(132, 400))
	verify("", "")
	check(main.interaction_highlight.active_sources().is_empty(), "Removing a hovered station releases its destroyed source layers")
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
	check(main.interaction_highlight.active_sources().is_empty(), "UI over a station prevents world highlight")
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
	check(main.interaction_highlight.active_sources().is_empty(), "Moving to empty ground clears every glow layer")
	await capture("pointer-left-clears")
	await click(Vector2(707, 625))
	check(not main.player.route.is_empty(), "Non-centered ground click still starts navigation")
	check(main.click_feedback.position == Vector2(707, 625), "Ground click feedback stays at the pointer instead of the nearest tile center")
	main.player.cancel_route()
	check(samples.size() >= 9, "All expected hover scenarios completed")
	cleanup()
	await check_highlight_frame_boundaries()
	var results := {"checks": checks, "failures": failures, "samples": samples, "captures": captures}
	var file := FileAccess.open(HOVER_OUTPUT.path_join("headless.json" if DisplayServer.get_name() == "headless" else "results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  "))
	print(JSON.stringify(results))
	quit(0 if failures.is_empty() else 1)

func check_highlight_frame_boundaries() -> void:
	# A deliberately opaque adjacent atlas cell makes texture bleeding visible;
	# the chosen cell has just a two-pixel-wide body in its center.
	var holder := Node2D.new()
	root.add_child(holder)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(64, 64)
	backdrop.size = Vector2(64, 64)
	backdrop.color = Color("182030")
	holder.add_child(backdrop)
	var atlas := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	atlas.fill_rect(Rect2i(3, 3, 2, 2), Color.WHITE)
	atlas.fill_rect(Rect2i(8, 0, 8, 8), Color.WHITE)
	var source := Sprite2D.new()
	source.texture = ImageTexture.create_from_image(atlas)
	source.centered = false
	source.position = Vector2(80, 80)
	source.region_enabled = true
	source.region_rect = Rect2(0, 0, 8, 8)
	var original_material := CanvasItemMaterial.new()
	source.material = original_material
	holder.add_child(source)
	var highlight := preload("res://world/interaction_highlight.gd").new()
	highlight.sync([source])
	var overlay := source.get_node("InteractionGlow") as Sprite2D
	check(source.material == original_material and source.position == Vector2(80, 80), "Highlight preserves original material and sprite transform")
	check(overlay.texture == source.texture and overlay.region_rect == source.region_rect, "Highlight uses the current animated texture region")
	check(VisibleSurface.depth(overlay) == VisibleSurface.depth(source), "Glow stays at the painted layer's occlusion depth")
	if DisplayServer.get_name() != "headless":
		await frames(3)
		RenderingServer.force_draw(false)
		var rendered := root.get_texture().get_image()
		var background := rendered.get_pixel(78, 83)
		check(rendered.get_pixel(87, 83) == background, "Adjacent opaque atlas frame cannot bleed into highlight")
		check(rendered.get_pixel(82, 83) != background, "Actual opaque body receives a one-pixel warm rim")
	source.region_rect = Rect2(8, 0, 8, 8)
	highlight.sync([source])
	check(overlay.region_rect == source.region_rect, "An animation frame change updates the existing glow")
	source.self_modulate.a = 0
	highlight.sync([source])
	check(highlight.active_sources().is_empty(), "An alpha-hidden body cannot glow")
	source.self_modulate.a = 1
	highlight.sync([source])
	source.hide()
	highlight.sync([source])
	check(highlight.active_sources().is_empty(), "A hidden body cannot glow")
	source.show()
	highlight.sync([source])
	source.free()
	highlight.sync([])
	check(highlight.active_sources().is_empty(), "Destroyed source cleanup retains no stale glow")
	holder.free()
