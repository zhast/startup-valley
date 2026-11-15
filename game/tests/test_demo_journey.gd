extends SceneTree
## Production scenes + production worker. Only injected input changes gameplay.
## Launched by scripts/test-demo-godot.mjs with an isolated save directory.
const MAIN := preload("res://world/main.tscn")
class InjectedInputRelay extends Node:
	var target: SubViewport
	var window: Window
	var forwarding := false
	func _input(event: InputEvent) -> void:
		if not forwarding: return
		# A direct SubViewport retains its injected pointer independently of the
		# OS cursor. Input still updates held keys and generates touch emulation.
		# Window dispatch has already removed its stretch/letterbox transform
		# before Node._input; applying it twice breaks non-1280 viewports.
		target.push_input(event, true)
		window.set_input_as_handled()

var game: GameMain
var viewport: SubViewport
var input_relay: InjectedInputRelay
var failures: Array[String] = []
var checks := 0
var actions: Array[Dictionary] = []
var captures: Array[String] = []
var capture_details: Array[Dictionary] = []
var completed: Dictionary = {}
var request_observations: Array[Dictionary] = []
var restored_snapshot: Dictionary = {}
var phase := ""
var output_dir := ""
var input_mode := "pointer"
var stopped := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures.append(message)
		print("DEMO_CHECK_FAILED " + message)
	return value

func wait_for(predicate: Callable, message: String, seconds := 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not bool(predicate.call()) and Time.get_ticks_msec() < deadline:
		await process_frame
	return check(bool(predicate.call()), message)

func frames(count := 4) -> void:
	for i: int in range(count): await process_frame

func run() -> void:
	phase = OS.get_environment("STARTUP_VALLEY_DEMO_PHASE")
	output_dir = OS.get_environment("STARTUP_VALLEY_DEMO_OUTPUT")
	input_mode = OS.get_environment("STARTUP_VALLEY_DEMO_INPUT")
	if phase.is_empty() or output_dir.is_empty() or OS.get_environment("STARTUP_VALLEY_DATA_DIR").is_empty() or OS.get_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS") != "1":
		push_error("Use scripts/test-demo-godot.mjs with disposable saves")
		quit(1)
		return
	root.size = Vector2i(int(OS.get_environment("STARTUP_VALLEY_DEMO_WIDTH")), int(OS.get_environment("STARTUP_VALLEY_DEMO_HEIGHT")))
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	root.unfocusable = true
	root.mouse_passthrough = true
	root.always_on_top = false
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_embed_subwindows = true
	root.add_child(viewport)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	input_relay = InjectedInputRelay.new()
	input_relay.target = viewport
	input_relay.window = root
	root.add_child(input_relay)
	game = MAIN.instantiate() as GameMain
	if game == null:
		push_error("Production main scene could not instantiate")
		quit(1)
		return
	viewport.add_child(game)
	game.worker_client.company_action_completed.connect(func(method: String, result: Dictionary) -> void: completed[method] = result.duplicate(true))
	game.worker_client.company_action_failed.connect(func(method: String, message: String) -> void: check(false, method + ": " + message))
	game.worker_client.request_failed.connect(func(message: String) -> void: check(false, "Worker: " + message))
	game.worker_client.job_event_received.connect(func(_id: String, _event: WorkerEventRecord) -> void: check(false, "Offline demo emitted a provider job event"))
	game.company_panel.action_requested.connect(func(method: String, _params: Dictionary) -> void:
		request_observations.append({"method": method, "busy": game.company_panel.busy})
		check(game.company_panel.busy, "Action immediately enters busy state: " + method)
	)
	if not await wait_for(func() -> bool: return game._state_loaded and game._worker_ready, "Production worker reaches actual title"):
		await finish()
		return
	await frames(10)
	if not check(game.company_panel.story_mode and game.job_panel.story_mode, "Production native scene and rail use the demo story flow"):
		await finish()
		return
	check(game.company_panel.visible and game.company_panel.screen == "title", "Fresh process opens one title modal")
	var expected_path := OS.get_environment("STARTUP_VALLEY_DEMO_EXPECTED")
	if not expected_path.is_empty():
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		restored_snapshot = snapshot().duplicate(true)
		var wanted: Dictionary = expected.get("snapshot", {})
		for field: String in wanted:
			if field == "player":
				var before := Vector2(float(wanted.player.x), float(wanted.player.y))
				var after := Vector2(float(restored_snapshot.player.x), float(restored_snapshot.player.y))
				check(before.distance_to(after) < 0.01 and wanted.player.movementSeen == restored_snapshot.player.movementSeen, "Restart restores player to subpixel serialization precision: %s -> %s" % [before, after])
			else:
				check(restored_snapshot.get(field) == wanted[field], "Restart restores exact " + field)
	await capture("title")
	match phase:
		"arrival":
			check(game._employees.is_empty() and int(game._journey.company.cashCents) == 0, "Clean save starts with no hires or reward")
			await enter()
			if not await wait_for(func() -> bool: return not game.company_panel.visible, "Start company reveals the playable studio", 3.0):
				await finish()
				return
			await move_pointer(game.arrival_guest.position + Vector2(0, -32))
			await frames(4)
			check(game.interaction_highlight.active_sources().has(game.arrival_guest.sprite), "Visible Mina visitor receives pointer highlight")
			check(not game.founder_hud._station_callout.get_global_rect().intersects(game.arrival_guest.painted_bounds()), "Mina's hover paper clears her face and nameplate")
			await click(Vector2(560, 432))
			await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(560, 432)) < 25, "Real floor click moves Founder to the selected clear floor")
			var before := game.player.position
			var event := InputEventKey.new()
			event.keycode = KEY_D
			event.physical_keycode = KEY_D
			event.pressed = true
			inject(event)
			await create_timer(0.25).timeout
			event = event.duplicate() as InputEventKey
			event.pressed = false
			inject(event)
			await frames(3)
			check(game.player.position.x > before.x + 5, "Held D moves the actual Founder")
			check(game.founder_hud._movement_seen, "Movement tutorial is recorded by gameplay")
			await capture("arrival-movement")
			await activate(find_button("Settings"))
			await wait_for(func() -> bool: return game.company_panel.visible and game.company_panel.screen == "settings", "Native story rail opens game Settings")
			check(not game.job_panel._connection_panel.visible, "Settings does not open optional credential setup")
			await capture("settings")
			await key(KEY_ESCAPE)
			check(not game.company_panel.visible, "Escape closes Settings back to the studio")
		"hire": await hire()
		"start": await start_project()
		"mid": await work_day()
		"release": await release_project()
		"visit": await visit_courtyard()
		"outdoor": await outdoor()
		"viewport": await viewport_guard()
		"motion": await standing_motion()
		"compatibility": await compatibility()
		"compatibility_restored":
			await enter()
			check(game.room.layout_model.floor_cells().size() == 614, "Restarted compatibility company retains the full office geometry")
			await capture("restored-full-office")
		"reset": await reset_company()
		"reset_restored":
			await enter()
			check(not game.company_panel.visible and not game.founder_hud._movement_seen, "Restarted new company returns to its untouched arrival tutorial")
			check(game._employees.is_empty() and int(game._journey.company.cashCents) == 0, "Restart after New Company does not restore old hires or rewards")
		"restored":
			await enter()
			check(not game.company_panel.visible, "Reloaded company resumes without replaying a reward modal")
			await capture("resumed")
			await activate(game.founder_hud._goal_action)
			check(game.company_panel._topic_id == "reselling" and game.company_panel._type_id == "template_pack", "Saved opportunity opens the intended unlocked project")
			await capture("next-opportunity")
			await activate(find_button("Let’s make it"))
			await wait_for(func() -> bool: return game._journey.tycoon.get("developing") is Dictionary, "The courtyard opportunity can start a real project")
			check(game._journey.tycoon.developing.topicId == "reselling" and game._journey.tycoon.developing.typeId == "template_pack", "Started project matches Theo's opportunity")
			check(str(game._journey.story.opportunity.status) == "developing", "Worker associates the real next project with the story opportunity")
		_: check(false, "Unknown phase: " + phase)
	await finish()

func enter() -> void:
	var button := find_button("Continue")
	if button == null: button = find_button("Start company")
	await activate(button)

func standing_motion() -> void:
	# Diagnostic only: observe real idle animation without changing actor state.
	await enter()
	await move_pointer(Vector2(950, 700))
	await settle_interface()
	if not check(DisplayServer.get_name() != "headless", "Motion evidence requires native rendering"): return
	var samples: Array[Dictionary] = []
	var started := Time.get_ticks_msec()
	var seen := {"mina": {}, "founder": {}}
	for index: int in range(90):
		await create_timer(0.06).timeout
		RenderingServer.force_draw(false)
		var rendered := viewport.get_texture().get_image()
		var sample := {"elapsedMs": Time.get_ticks_msec() - started, "actors": {}}
		for id: String in ["mina", "founder"]:
			var actor: Node2D = game.arrival_guest if id == "mina" else game.player
			var sprite: Sprite2D = game.arrival_guest.sprite if id == "mina" else game.player._character_sprite
			var cell := int(sprite.region_rect.position.x / 48)
			seen[id][cell] = true
			var crop := Rect2i(Vector2i(actor.position) + Vector2i(-40, -78), Vector2i(80, 88))
			var path := output_dir.path_join("motion-%s-%03d.png" % [id, index])
			check(rendered.get_region(crop).save_png(path) == OK, "Save native motion sample")
			sample.actors[id] = {"cell": cell, "region": [sprite.region_rect.position.x, sprite.region_rect.position.y], "crop": [crop.position.x, crop.position.y, crop.size.x, crop.size.y], "path": path}
		samples.append(sample)
	for id: String in ["mina", "founder"]:
		check(seen[id].has(0) and seen[id].has(1), "Native standing motion includes open and closed eyes: " + id)
	var contact := Image.create(1280, 704, false, Image.FORMAT_RGBA8)
	var selected: Array[Dictionary] = []
	for row: int in range(2):
		var id := "mina" if row == 0 else "founder"
		var closed := -1
		for index: int in range(samples.size()):
			if int(samples[index].actors[id].cell) == 1:
				closed = index
				break
		if closed < 0: continue
		var indexes := [maxi(0, closed - 1), closed, mini(samples.size() - 1, closed + 1), mini(samples.size() - 1, closed + 3)]
		for column: int in range(indexes.size()):
			var sample: Dictionary = samples[indexes[column]]
			var frame := Image.load_from_file(str(sample.actors[id].path))
			frame.resize(320, 352, Image.INTERPOLATE_NEAREST)
			contact.blit_rect(frame, Rect2i(0, 0, 320, 352), Vector2i(column * 320, row * 352))
			selected.append({"actor": id, "sample": indexes[column], "elapsedMs": sample.elapsedMs, "cell": sample.actors[id].cell})
	check(contact.save_png(output_dir.path_join("motion-contact.png")) == OK, "Save native motion contact sheet")
	var evidence := FileAccess.open(output_dir.path_join("motion-samples.json"), FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"samples": samples, "selected": selected, "contactRows": ["Mina", "Founder"], "note": "Actual native viewport pixels; observed atlas cells only, no animation setters. Contact uses nearest-neighbor enlargement."}, "  ") + "\n")
	evidence.close()

func compatibility() -> void:
	var fixture_path := OS.get_environment("STARTUP_VALLEY_DEMO_FIXTURE")
	if not check(not fixture_path.is_empty(), "Compatibility phase requires an explicit labeled fixture"): return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	check(game._journey.company == expected.company, "Fixture company values survive actual worker migration")
	var migrated_furnishing: Dictionary = expected.furnishing.duplicate(true)
	# Both fixtures and protocol objects come from JSON, whose numbers are
	# floats in Godot. Preserve that type for the deep Dictionary comparison.
	migrated_furnishing.revision = float(migrated_furnishing.revision) + float(expected.get("migrationRevisionDelta", 0))
	check(game.worker_client.furnishing_state == migrated_furnishing, "Fixture furniture and inventory survive migration with exactly the declared stale-edit revision bump")
	var saved_position := Vector2(float(expected.player.x), float(expected.player.y))
	check(game.player.position.distance_to(saved_position) < 0.01, "Fixture position survives actual worker migration")
	await enter()
	if expected.kind == "legacy":
		check(game.room.layout_model.floor_cells().size() == 614, "Pre-cottage save hydrates the original full office")
		await capture("legacy-full-office")
		await click(Vector2(560, 624))
		await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(560, 624)) < 25, "Migrated office remains navigable through actual input")
	else:
		check(game.room.layout_model.floor_cells().size() == 288, "Expansion fixture starts in the compact office")
		await capture("compact-before-expansion")
		await activate(find_button("Settings"))
		await activate(find_button("Company Journey"))
		await scroll_to_action("Studio plans")
		await activate(find_button("Studio plans"))
		await scroll_to_action("Invite Theo")
		await capture("expansion-invitation")
		await activate(find_button("Invite Theo"))
		await capture("after-invitation-input")
		await wait_for(func() -> bool: return game.get_employee("theo") != null and str(game.worker_client.furnishing_state.get("layoutId", "")) == "startup-office", "Actual invitation expands the compact room and hires Theo")
		check(game.room.layout_model.floor_cells().size() == 614, "Live expansion updates actual room navigation")
		check(int(game._journey.company.cashCents) == int(expected.company.cashCents) - 30000, "Expansion invitation charges exactly once")
		for item: Dictionary in expected.furnishing.inventory:
			var retained := false
			for current: Dictionary in game.worker_client.furnishing_state.inventory:
				if current.id == item.id: retained = true
			check(retained, "Expansion retains owned item: " + str(item.id))
		await key(KEY_ESCAPE)
		await capture("expanded-full-office")
		await click(Vector2(560, 624))
		await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(560, 624)) < 25, "Expanded office remains navigable through actual input")

func scroll_to_action(label: String) -> void:
	await settle_interface()
	var button := find_button(label)
	if not check(button != null, "Scroll target exists: " + label): return
	var ancestor := button.get_parent()
	while ancestor != null and not ancestor is ScrollContainer: ancestor = ancestor.get_parent()
	if ancestor == null: return
	var scroll := ancestor as ScrollContainer
	for attempt: int in range(50):
		if scroll.get_global_rect().encloses(button.get_global_rect()): return
		var down := button.get_global_rect().get_center().y > scroll.get_global_rect().get_center().y
		var event := InputEventMouseButton.new()
		event.position = root.get_final_transform() * scroll.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
		event.pressed = true
		event.factor = 2.0
		inject(event)
		# Balance synthetic wheel press/release just as the platform does. A
		# held wheel bit can leave subsequent clicks captured by the root GUI.
		event = event.duplicate() as InputEventMouseButton
		event.pressed = false
		inject(event)
		await frames(3)
	check(false, "Wheel scrolling reaches action: " + label)

func hire() -> void:
	await enter()
	if not game.company_panel.visible:
		await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return find_button("Invite Mina") != null, "Walking to Mina opens her actual introduction")
	await capture("Mina-invitation")
	var previous: Dictionary = completed.get("hiring.complete", {})
	await activate(find_button("Invite Mina"))
	await wait_for(func() -> bool: return completed.get("hiring.complete", {}) != previous, "Invitation completes through production worker")
	check(game._employees.size() == 1 and game.get_employee("mira") != null, "Exactly one Mina joins the studio")
	check(int(game._journey.company.cashCents) == 0, "Free invitation grants no duplicate cash")
	await capture("Mina-welcome")

func open_project() -> void:
	await enter()
	if not game.company_panel.visible:
		await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.screen == "product" and game.company_panel.visible, "Current objective opens project screen")

func start_project() -> void:
	await open_project()
	await capture("first-idea")
	await activate(find_button("Let’s make it"))
	await wait_for(func() -> bool: return game._journey.get("tycoon", {}).get("developing") is Dictionary, "First project starts through worker")
	var product: Dictionary = game._journey.tycoon.developing
	check(product.staffIds == ["founder", "mira"], "First project assigns Founder and Mina exactly once")
	check(int(product.progress) == 0, "New project starts at zero progress")
	await capture("project-started")
	await key(KEY_ESCAPE)
	var mina := game.get_employee("mira")
	await wait_for(func() -> bool: return mina.is_at_desk() and mina.work_state == EmployeeAvatar.WorkState.SITTING, "Mina walks to her real assigned seat", 18.0)
	check(mina.has_studio_project and not mina.has_live_job, "Offline project seating is independent of provider activity")
	await create_timer(9.0 if OS.get_environment("STARTUP_VALLEY_DEMO_RUN") == "1" else 1.0).timeout
	check(mina.is_at_desk() and mina.work_state == EmployeeAvatar.WorkState.SITTING, "Assigned teammate holds the seat beyond normal wander delay")
	await capture("Mina-seated")
	for repeat: int in range(2):
		await activate(game.job_panel._team_buttons["mira"])
		await wait_for(func() -> bool: return game.job_panel.drawer_is_open(), "Rail opens Mina's conversation")
		check(not game.company_panel.visible, "Conversation has no second company modal beneath it")
		await capture("Mina-conversation-%d" % repeat)
		await key(KEY_ESCAPE)
		await wait_for(func() -> bool: return not game.job_panel.drawer_is_open(), "Escape closes the conversation")
		check(not game.company_panel.visible, "Escape closes one layer without opening Settings")

func work_day() -> void:
	await open_project()
	await end_day()
	check(int(game._journey.tycoon.developing.progress) == 33, "First completed day advances actual project to 33 percent")
	await capture("mid-development")

func end_day() -> void:
	var before := game.day_clock.day
	await activate(find_button("Wrap up the day"))
	await wait_for(func() -> bool: return game.day_clock.day == before + 1 and game.company_panel.screen == "summary", "Day advances once and opens saved summary")
	await capture("day-%d-summary" % before)
	await activate(find_button("Begin next day"))
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.screen == "product", "Next day resumes the project objective")

func release_project() -> void:
	await open_project()
	for i: int in range(3):
		if bool(game._journey.tycoon.developing.get("ready", false)): break
		await end_day()
	check(bool(game._journey.tycoon.developing.get("ready", false)), "Real day progression makes the first product ready")
	await capture("ready-to-release")
	await activate(find_button("Share it with the world"))
	await wait_for(func() -> bool: return game._journey.tycoon.get("developing") == null and not (game._journey.tycoon.get("history", []) as Array).is_empty(), "Release commits once through production worker")
	check((game._journey.tycoon.history as Array).size() == 1, "Exactly one product has been released")
	check(int(game._journey.company.cashCents) > 0 and int(game._journey.company.reputation) > 0, "Real release earns cash and reputation")
	await capture("first-release")

func visit_courtyard() -> void:
	await enter()
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return str(game._journey.get("story", {}).get("location", "")) == "courtyard", "Walking to the exit travels to the real courtyard", 18.0)
	check(game.courtyard.visible and not game.room.visible, "Courtyard replaces office rendering and navigation")
	await wait_for(func() -> bool: return not game._story_busy, "Travel acknowledgement clears pending state")
	await frames(4)
	await move_pointer(game.courtyard.guest.position + Vector2(0, -32))
	await frames(4)
	check(game.interaction_highlight.active_sources().has(game.courtyard.guest.sprite), "Theo's visible sprite receives pointer highlight")
	check(not game.founder_hud._station_callout.get_global_rect().intersects(game.courtyard.guest.painted_bounds()), "Theo's hover paper clears his face and nameplate")
	await capture("courtyard-arrival")
	await move_pointer(game.courtyard.return_sign.position + Vector2(0, -12))
	await frames(4)
	check(game.courtyard.return_sign.hovered, "Return sign highlights under the pointer")
	await frames(8)
	await click(Vector2(144, 112))
	await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(144, 112)) < 25, "Courtyard northwest path reaches legal save coordinates", 18.0)
	await capture("courtyard-northwest-save")

func outdoor() -> void:
	await enter()
	var company: Dictionary = game._journey.company.duplicate(true)
	var inventory: Array = game.worker_client.furnishing_state.inventory.duplicate(true)
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.visible and game.company_panel.screen == "courtyard", "Walking to Theo opens his invitation", 18.0)
	await capture("Theo-opportunity")
	await activate(find_button("Let’s make the Market Day Kit"))
	await wait_for(func() -> bool: return str(game._journey.story.opportunity.status) == "accepted", "Theo's opportunity commits through the worker")
	await capture("opportunity-accepted")
	await activate(find_button("Back to our studio"))
	await wait_for(func() -> bool: return str(game._journey.story.location) == "office", "Walking home restores the office", 18.0)
	check(game.room.visible and not game.courtyard.visible, "Return restores office rendering")
	check(game._journey.company == company, "Courtyard visit does not duplicate first-release rewards")
	check(game.worker_client.furnishing_state.inventory == inventory, "Courtyard visit preserves owned furniture")
	await capture("outdoor-return")

func viewport_guard() -> void:
	var guard := game.find_child("DemoViewportGuard", true, false) as Control
	if not check(guard != null and guard.is_visible_in_tree(), "Small viewport shows deliberate supported-size guidance"): return
	var before := snapshot()
	await capture("small-display-guidance")
	var start := find_button("Start company")
	if start != null: await touch(start.get_global_rect().get_center())
	await key(KEY_ENTER)
	check(game.company_panel.screen == "title" and game.company_panel.visible and snapshot() == before, "Guard consumes touch and keyboard without activating underlying game")
	root.size = Vector2i(1280, 720)
	await frames(8)
	check(not guard.visible, "Resizing to supported dimensions removes the guidance")
	input_mode = "touch"
	await enter()
	check(not game.company_panel.visible, "Injected touch activates Start in a supported viewport")
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return find_button("Invite Mina") != null, "Injected touch objective reaches Mina", 18.0)
	await capture("touch-Mina-invitation")

func reset_company() -> void:
	await enter()
	await activate(find_button("Settings"))
	await activate(find_button("Title screen"))
	await activate(find_button("New company"))
	await capture("new-company-confirmation")
	var confirm := find_button("Start new company")
	if confirm == null: confirm = find_button("Back up + start new")
	await activate(confirm)
	await wait_for(func() -> bool: return completed.has("game.new"), "Confirmed New Company completes through the production worker")
	check(game._employees.is_empty(), "New Company removes all previous hires")
	check(int(game._journey.company.cashCents) == 0 and int(game._journey.company.reputation) == 0, "New Company resets actual rewards")
	check((game._journey.tycoon.history as Array).is_empty() and game._journey.tycoon.get("developing") == null, "New Company resets released and in-progress products")
	check(not game.founder_hud._movement_seen, "New Company restores the movement hint")
	check(str(game._journey.story.location) == "office" and not bool(game._journey.story.courtyardUnlocked), "New Company restores the office arrival story")
	check(not game.company_panel.visible and not game.job_panel._connection_panel.visible, "Reset returns to playable arrival without a credential or hire modal")
	await capture("new-company-arrival")

func find_button(prefix: String) -> Button:
	for node: Node in game.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.begins_with(prefix): return button
	return null

func activate(button: Button) -> void:
	await settle_interface()
	if button != null:
		var deadline := Time.get_ticks_msec() + 2500
		while is_instance_valid(button) and (not button.is_visible_in_tree() or button.disabled) and Time.get_ticks_msec() < deadline:
			await process_frame
	if not check(button != null and button.is_visible_in_tree() and not button.disabled, "Required action is visible and enabled" + (": " + button.text if button != null else "")): return
	# Scroll/layout updates can continue after the first enclosed frame. Wait
	# for a stable measured rectangle, not an FPS-dependent frame count.
	var rectangle := button.get_global_rect()
	var stable_since := Time.get_ticks_msec()
	var layout_deadline := stable_since + 2500
	while Time.get_ticks_msec() - stable_since < 150 and Time.get_ticks_msec() < layout_deadline:
		await process_frame
		var current_rectangle := button.get_global_rect()
		if current_rectangle != rectangle:
			rectangle = current_rectangle
			stable_since = Time.get_ticks_msec()
	check(Time.get_ticks_msec() - stable_since >= 150, "Action geometry settles before input: " + button.text)
	check(root.get_visible_rect().encloses(button.get_global_rect()), "Action fits logical viewport: " + button.text)
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor as Control).clip_contents:
			check((ancestor as Control).get_global_rect().encloses(button.get_global_rect()), "Action is not clipped by its scroll/container: " + button.text)
		ancestor = ancestor.get_parent()
	var point := button.get_global_rect().get_center()
	var actual_input := input_mode
	if input_mode == "keyboard" and viewport.gui_get_focus_owner() == null:
		# Godot does not initialize Tab focus across a CanvasLayer from the
		# unfocused world. Exercise the shipped Escape shortcut for Settings;
		# other world affordances remain pointer-driven. Dialogs use Tab/Space.
		actual_input = "keyboard_escape" if button == game.job_panel._settings_button else "pointer_world"
	actions.append({"input": actual_input, "action": button.text, "point": [point.x, point.y]})
	if actual_input == "touch": await touch(point)
	elif actual_input == "keyboard_escape": await key(KEY_ESCAPE)
	elif actual_input == "keyboard":
		for i: int in range(80):
			if viewport.gui_get_focus_owner() == button: break
			await key(KEY_TAB)
		if check(viewport.gui_get_focus_owner() == button, "Keyboard Tab reaches action: " + button.text): await key(KEY_SPACE)
	else: await click(point)
	await frames(12)

func settle_interface() -> void:
	# Native and headless frame rates differ; animation duration is wall time.
	await wait_for(func() -> bool:
		var panel_tween := game.company_panel._transition
		var drawer_tween := game.job_panel._drawer_tween
		return (panel_tween == null or not panel_tween.is_running()) and (drawer_tween == null or not drawer_tween.is_running()),
		"Interface transitions settle before input", 3.0)
	await frames(2)

func click(point: Vector2) -> void:
	await move_pointer(point)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = root.get_final_transform() * point
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		inject(event)
		await frames(2)

func move_pointer(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * point
	motion.global_position = motion.position
	inject(motion)
	await frames(1)

func touch(point: Vector2) -> void:
	for down: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = root.get_final_transform() * point
		event.index = 0
		event.pressed = down
		inject(event)
		await frames(2)

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		inject(event)
		await frames(2)
	await frames(6)

func inject(event: InputEvent) -> void:
	input_relay.forwarding = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	input_relay.forwarding = false

func snapshot() -> Dictionary:
	var tycoon: Dictionary = game._journey.get("tycoon", {})
	var product: Dictionary = tycoon.get("developing", {}) if tycoon.get("developing") is Dictionary else {}
	var history: Array = []
	for item: Dictionary in tycoon.get("history", []):
		history.append({"id": item.id, "name": item.name, "releasedDay": item.releasedDay, "salesCents": item.salesCents})
	var hires: Array = []
	for candidate: Dictionary in game._journey.get("candidates", []):
		if bool(candidate.get("hired", false)): hires.append(candidate.id)
	return {"company": game._journey.get("company", {}), "day": game.day_clock.day, "hires": hires,
		"product": {"id": product.get("id"), "progress": product.get("progress"), "staffIds": product.get("staffIds"), "ready": product.get("ready")},
		"history": history, "furnishing": game.worker_client.furnishing_state,
		"story": game._journey.get("story", {}), "player": {"x": game.player.position.x, "y": game.player.position.y, "movementSeen": game.founder_hud._movement_seen}}

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await settle_interface()
	await frames(4)
	RenderingServer.force_draw(false)
	var file := output_dir.path_join(phase + "-" + name_value + ".png")
	var image := root.get_texture().get_image()
	check(image.save_png(file) == OK, "Native capture: " + name_value)
	captures.append(file)
	capture_details.append({"path": file, "window": [root.size.x, root.size.y], "image": [image.get_width(), image.get_height()], "logicalViewport": [viewport.size.x, viewport.size.y]})

func finish() -> void:
	if stopped: return
	stopped = true
	await capture("final")
	var file := FileAccess.open(output_dir.path_join(phase + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase": phase, "checks": checks, "failures": failures, "actions": actions, "requests": request_observations, "captures": captures, "captureDetails": capture_details,
		"engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(),
		"workerPid": game.worker_client._process_id,
		"inputRouting": "Input.parse_input_event -> isolated root relay -> direct SubViewport; no OS cursor movement",
		"window": [root.size.x, root.size.y], "logicalViewport": [viewport.size.x, viewport.size.y],
		"restoredSnapshot": restored_snapshot, "snapshot": snapshot() if game._state_loaded else {}}, "  ") + "\n")
	file.close()
	print("DEMO_PHASE_RESULT %s checks=%d failures=%d" % [phase, checks, failures.size()])
	if not failures.is_empty():
		game.queue_free()
		await frames(4)
		quit(1)
		return
	# The ordinary close path durably saves player position and closes worker stdin.
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
