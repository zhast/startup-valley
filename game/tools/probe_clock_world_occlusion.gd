extends "res://tools/capture_founder_occlusion.gd"
## Read-only diagnosis: ordinary top-floor actor behind the persistent ledger.
const PROBE_OUTPUT := "res://tests/output/clock-world-occlusion"
var observations: Dictionary = {}
var cases: Array[Dictionary] = []
var after := false
var output_folder := PROBE_OUTPUT

func run() -> void:
	after = "--after" in OS.get_cmdline_user_args()
	if after: output_folder = PROBE_OUTPUT + "-after"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.notify_mouse_entered()
	for name_value: String in ["day", "time", "earned", "memo-heading", "memo-detail", "memo-blank"]:
		await probe(name_value)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))
	var report := {"checks": checks, "probe_failures": failures, "cases": cases, "production_modified_by_probe": false, "mode": "after_assertions" if after else "before_diagnosis"}
	var file := FileAccess.open(output_folder.path_join("headless.json" if DisplayServer.get_name() == "headless" else "native.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func probe(name_value: String) -> void:
	await setup()
	var mina := main.get_employee("mira")
	var actor_x := 448 if name_value == "day" else 704 if name_value == "earned" else 176 if name_value.begins_with("memo") else 560
	mina.position = Vector2(actor_x, 112)
	mina.work_state = EmployeeAvatar.WorkState.IDLE
	mina._has_target = false
	mina._route.clear()
	mina._animation_elapsed = 0
	mina._facing = &"front"
	mina._update_character_frame()
	main.room.navigation.actors.mira = mina.position
	main.player.position = Vector2(560, 624)
	main.player._physics_process(0)
	main.room.navigation.actors.founder = main.player.position
	check(main.room.navigation.position_is_safe(mina.position, "mira"), "Top-row employee physical feet are on legal unblocked floor")
	check(not main._world_paused(), "Ordinary game UI is not paused")
	var ledger := main.clock_panel.get_node("LedgerTexture") as TextureRect
	var image := ledger.texture.get_image()
	var search := Rect2(actor_x - 20, 40, 40, 32)
	if name_value.begins_with("memo"):
		main.founder_hud.show_delivery("probe-prior-job", "theo", "Theo", "Prior work ready")
		await frames(8)
		# Hold the normally entered toast for input/screenshot, not a fake surface.
		main.founder_hud._notification_tween.kill()
		if name_value == "memo-heading": search = main.founder_hud._notification_heading.get_global_rect()
		elif name_value == "memo-detail": search = main.founder_hud._notification_detail.get_global_rect()
		else: search = Rect2(38, 84, 198, 12)
		search = search.intersection(Rect2(actor_x - 24, 40, 48, 76))
	var point := Vector2.INF
	var texture_point := Vector2i.ZERO
	for y: int in range(int(search.position.y), int(search.end.y), 2):
		for x: int in range(int(search.position.x), int(search.end.x), 2):
			var test := Vector2(x, y)
			if mina.body_surface_at(test) == null: continue
			var pixel := Vector2i.ZERO
			if not name_value.begins_with("memo"):
				var local := (test - ledger.global_position) / ledger.size * Vector2(image.get_size())
				pixel = Vector2i(local)
				if image.get_pixelv(pixel).a < 0.99: continue
			point = test
			texture_point = pixel
			break
		if point.is_finite(): break
	check(point.is_finite(), name_value + " actual opaque employee pixel intersects current HUD material")
	if point.is_finite():
		if DisplayServer.get_name() != "headless": root.warp_mouse(point)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		Input.parse_input_event(motion)
		await frames(1)
		main._process(0)
		var hovered := root.gui_get_hovered_control()
		var before := main.player.position
		var picked := main._interaction_at(point)
		await click(point)
		observations = {
			"case": name_value,
			"point": [point.x, point.y],
			"employee_feet": [mina.position.x, mina.position.y],
			"ledger_rect": str(ledger.get_global_rect()),
			"opaque_ledger_texture_pixel": [texture_point.x, texture_point.y],
			"hovered_control": str(hovered.get_path()) if hovered != null else "",
			"underlying_world_pick": picked,
			"actual_pending_kind": main._pending_kind,
			"actual_pending_id": main._pending_interaction,
			"actual_route_count": main.player.route.size(),
			"employee_hover_highlight": mina._ui_highlighted,
			"founder_position_unchanged_during_input": main.player.position == before,
			"clock_mouse_filter": main.clock_panel.mouse_filter,
			"memo_mouse_filter": main.founder_hud._notification.mouse_filter,
			"worker_blocked": main.worker_client._stdio == null and main.worker_client._process_id == -1,
		}
		if after:
			check(hovered != null, name_value + " real GUI control owns hover over opaque HUD")
			check(not mina._ui_highlighted, name_value + " hidden employee gets no hover highlight")
			check(main._pending_interaction.is_empty() and main.player.route.is_empty(), name_value + " HUD click creates no world action or route")
			if name_value == "earned": check(hovered.tooltip_text.contains("in-game revenue"), "Earned tooltip target remains reachable")
			check(main.player.move_to(Vector2(624, 624)), "Existing route can be set before HUD click")
			var route_before := main.player.route.duplicate()
			await click(point)
			check(main.player.route == route_before, name_value + " HUD click preserves the existing route")
			observations.existing_route_preserved = main.player.route == route_before
			main.player.cancel_route()
		if DisplayServer.get_name() != "headless":
			await frames(2)
			RenderingServer.force_draw(false)
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))
			var rendered_image := root.get_texture().get_image()
			check(rendered_image.save_png(output_folder.path_join(name_value + "-hidden-employee.png")) == OK, "Save actual native overlay evidence")
			var actual := rendered_image.get_pixelv(Vector2i(point))
			observations.rendered_pixel = actual.to_html()
			if not name_value.begins_with("memo"):
				observations.ledger_source_pixel = image.get_pixelv(texture_point).to_html()
				observations.rendered_pixel_matches_opaque_ledger = actual.is_equal_approx(image.get_pixelv(texture_point))
			if after:
				var original := Image.load_from_file(ProjectSettings.globalize_path((PROBE_OUTPUT + "-before").path_join(name_value + "-hidden-employee.png")))
				var crop := Rect2i(24, 18, 310, 84) if name_value.begins_with("memo") else Rect2i(371, 8, 408, 68)
				var same := original.get_region(crop).get_data() == rendered_image.get_region(crop).get_data()
				check(same, name_value + " full HUD crop is byte-identical before/after input correction")
				observations.full_hud_crop_unchanged = same
		if after and name_value == "memo-blank":
			var view := main.founder_hud._notification.get_node("ViewDelivery") as Button
			await click(view.get_global_rect().get_center())
			check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "theo" and main.job_panel._tabs.current_tab == 2, "Real View button opens delivered employee Theo Activity")
			check(not main.founder_hud.delivery_visible(), "View dismisses memo")
			check(main.player.route.is_empty() and main._pending_interaction.is_empty(), "View button never leaks into world movement")
			main.job_panel.close_drawer(false)
			main._process(0)
			await frames(3)
			main.player.input_blocked = false
			await click(point)
			check(main._pending_interaction == "mira" and not main.player.route.is_empty(), "Hidden memo releases its former area to visible employee input")
			main.player.cancel_route()
			await click(Vector2(624, 624))
			check(main._pending_interaction.is_empty() and not main.player.route.is_empty() and main.player._route_target == Vector2(624, 624), "Unobscured floor still receives real click-to-walk")
			observations.view_opened_theo_activity_and_hidden_memo_released = true
		cases.append(observations.duplicate(true))
	main.game_audio.shutdown()
	main.free()
	main = null
	await frames(3)
