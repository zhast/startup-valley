extends SceneTree
## Worker-free integrated UI state projection; physical animation remains separate.

var checks := 0
var failures: Array[String] = []
var main: GameMain
var captures: Array[String] = []
var capture_states: Array[Dictionary] = []
const OUTPUT := "res://tests/output/ui-material-world"

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func fixture() -> void:
	if main != null:
		main.game_audio.shutdown()
		main.free()
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	main.game_audio.set_volumes(0, 0)
	# Completed-event follow-ups cannot reach a process; omit the expected offline UI error.
	main.worker_client.request_failed.disconnect(main.job_panel.set_error)
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	main.job_panel.select_employee("mira")
	main.job_panel.open_drawer(false)
	for employee: EmployeeAvatar in main._employees.values(): employee.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Fixture never starts a worker or opens saved company state")

func event(kind: StringName, tool_name: String = "") -> void:
	var record := WorkerEventRecord.new()
	record.type = kind
	record.tool = tool_name
	record.approval_id = "fixture-approval" if kind == &"approval.required" else ""
	if kind == &"approval.required": record.action = "Publish the launch brief to the shared Studio for Theo to review."
	main._on_job_event("fixture-job", record)

func begin() -> void:
	main._job_employees["fixture-job"] = "mira"
	main.job_panel.begin_job("fixture-job", "mira")
	main.job_panel.accept_submission("fixture-job")

func project(expected: String) -> void:
	var employee := main.get_employee("mira")
	main.job_panel.select_employee("mira")
	main.job_panel.open_drawer(false)
	var before := [employee.position, employee.work_state, employee._has_target, employee._route.duplicate(), employee._arrival_state, employee.has_live_job]
	main._process(0)
	check(employee.presentation_label() == expected, "World label uses business presentation: %s (actual %s)" % [expected, employee.presentation_label()])
	check([employee.position, employee.work_state, employee._has_target, employee._route, employee._arrival_state, employee.has_live_job] == before, "UI projection does not change route, position or work animation")
	check(employee._drawer_selected and not employee._labels_visible() and not employee._label_detail_visible(), "Open drawer suppresses redundant world identity and status")
	if employee.has_attention():
		check(employee.attention_cue_visible() or employee._effect_sprite.visible, "Selected employee retains one non-text world attention cue")
	employee.set_drawer_selected(false)
	employee.set_ui_highlighted(true)
	check(EmployeeAvatar.STATUS_FONT.get_string_size(expected, HORIZONTAL_ALIGNMENT_LEFT, -1, EmployeeAvatar.STATUS_FONT_SIZE).x <= employee._name_width() - 16, "Projected wording fits native world-label width: " + expected)
	check_name_geometry(employee)
	employee.set_drawer_selected(true)
	employee.set_ui_highlighted(false)

func line_box(font: Font, size: int, value: String, baseline: Vector2, width: float) -> Rect2:
	var measured := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return Rect2(baseline + Vector2((width - measured) * 0.5, -font.get_ascent(size)), Vector2(measured, font.get_height(size)))

func check_name_geometry(employee: EmployeeAvatar) -> void:
	var rect := employee._nameplate_rect()
	var inset := EmployeeAvatar.NAME_INSET
	var safe := Rect2(rect.position + inset, rect.size - inset * 2)
	var name_text := employee._fit_label(employee.display_name, safe.size.x, EmployeeAvatar.NAME_FONT, EmployeeAvatar.NAME_FONT_SIZE)
	var name_box := line_box(EmployeeAvatar.NAME_FONT, EmployeeAvatar.NAME_FONT_SIZE, name_text, employee._name_baseline(), safe.size.x)
	check(rect.position == rect.position.round() and rect.size == rect.size.round(), "Centered world name card has whole-pixel edges")
	check(employee._name_baseline() == employee._name_baseline().round(), "Name baseline uses a snapped canvas origin")
	check(safe.encloses(name_box), "Name's full font metrics stay inside paper insets: %s in %s" % [name_box, safe])
	check(GameFonts.has_glyphs(EmployeeAvatar.NAME_FONT, name_text), "Visible world name has bundled glyph coverage: " + name_text)
	if employee._label_detail_visible():
		var label := employee.presentation_label()
		var status_box := line_box(EmployeeAvatar.STATUS_FONT, EmployeeAvatar.STATUS_FONT_SIZE, label, employee._status_baseline(), safe.size.x)
		check(employee._status_baseline() == employee._status_baseline().round(), "Status baseline uses a snapped canvas origin")
		check(safe.encloses(status_box), "Status metrics stay inside paper insets: %s in %s" % [status_box, safe])
		check(name_box.end.y + EmployeeAvatar.TEXT_LINE_GAP <= status_box.position.y + 0.01, "World name and status have distinct line boxes with a readable gap")
		check(GameFonts.has_glyphs(EmployeeAvatar.STATUS_FONT, label), "World status has bundled glyph coverage")

func check_world_typography() -> void:
	check(EmployeeAvatar.NAME_FONT == GameFonts.BOLD and EmployeeAvatar.NAME_FONT_SIZE == 16, "World identity explicitly uses Nunito Bold16")
	check(EmployeeAvatar.STATUS_FONT == GameFonts.EMPHASIS and EmployeeAvatar.STATUS_FONT_SIZE == 14, "World status explicitly uses Nunito metadata14")
	check(EmployeeAvatar.SPEECH_FONT == GameFonts.BODY and EmployeeAvatar.SPEECH_FONT_SIZE == 16, "World speech explicitly uses Nunito body16")
	var employee := EmployeeAvatar.new()
	for identity: String in ["Mina", "Theo", "Alexandria Customer Research", "Zoë – 顾客研究 🚀"]:
		employee.display_name = identity
		for detail: bool in [false, true]:
			employee.set_ui_highlighted(detail)
			check_name_geometry(employee)
			check(employee.display_name == identity, "World elision does not alter the original employee identity")
	for position: Vector2 in [Vector2(300, 340), Vector2(300.49, 340.72), Vector2(300.5, 340.5)]:
		employee.position = position
		var expected := WorldCalloutSkin.bounds(employee._nameplate_rect(), WorldCalloutSkin.ACTOR_BOUNDS.get_center())
		expected.position += position.round()
		check(employee.world_label_rect() == expected, "World UI occlusion uses the same snapped card as painting")
	for speech: String in ["One clear offer.", "A very long memory sentence must remain readable without covering the whole office", "https://example.com/a-very-long-unbroken-memory-reference followed by more context", "Zoë reviews résumé–validation…\n顾客研究 🚀 → next steps"]:
		employee.memory_line = speech
		employee._speech_visible = true
		var rect := employee._speech_rect()
		var safe := Rect2(rect.position + EmployeeAvatar.SPEECH_INSET, rect.size - EmployeeAvatar.SPEECH_INSET * 2)
		var lines := employee._wrap_speech(speech, 21)
		check(lines.size() > 0 and lines.size() <= 2, "Speech remains a bounded two-line contextual card")
		check(not " ".join(lines).ends_with("…"), "Ambient speech never clips a memory midway through a thought")
		var line_height := ceilf(EmployeeAvatar.SPEECH_FONT.get_height(EmployeeAvatar.SPEECH_FONT_SIZE))
		var expected_height := line_height * lines.size() + EmployeeAvatar.TEXT_LINE_GAP * (lines.size() - 1) + EmployeeAvatar.SPEECH_INSET.y * 2
		check(rect.size.y == ceilf(expected_height * 0.5) * 2, "Speech paper hugs its actual one/two-line metrics")
		var previous := Rect2()
		for index: int in range(lines.size()):
			var baseline := employee._speech_baseline(index)
			var bounds := line_box(EmployeeAvatar.SPEECH_FONT, EmployeeAvatar.SPEECH_FONT_SIZE, lines[index], baseline, safe.size.x)
			check(baseline == baseline.round(), "Speech uses a whole-pixel baseline")
			check(safe.encloses(bounds), "Speech font metrics fit painted paper including long first tokens: %s in %s" % [bounds, safe])
			check(GameFonts.has_glyphs(EmployeeAvatar.SPEECH_FONT, lines[index]), "Speech has bundled glyph coverage")
			if index > 0: check(previous.end.y + EmployeeAvatar.TEXT_LINE_GAP <= bounds.position.y + 0.01, "Speech lines do not overlap")
			previous = bounds
		check(employee.memory_line == speech, "Speech wrapping preserves the original memory text")
		var painted := WorldCalloutSkin.bounds(rect, WorldCalloutSkin.ACTOR_BOUNDS.get_center())
		check(employee.world_label_rect() == Rect2(employee.position.round() + painted.position, painted.size), "Speech occlusion includes its fixed native pointer")
	employee.free()

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var path := OUTPUT.path_join(name_value + ".png")
	check(root.get_texture().get_image().save_png(path) == OK, "Native callout capture saved: " + name_value)
	captures.append(path)
	var callouts: Array[Dictionary] = []
	for actor: EmployeeAvatar in main._employees.values():
		callouts.append({"employee": actor.employee_id, "drawerSelected": actor._drawer_selected, "identityVisible": actor._labels_visible(), "speechVisible": actor._speech_visible and not actor.labels_suppressed, "attentionCue": actor.attention_cue_visible() and not actor.labels_suppressed, "eventEffectVisible": actor._effect_sprite.visible, "eventEffectPainted": actor._effect_sprite.visible and actor._effect_sprite.self_modulate.a > 0, "body": str(actor.world_label_body_rect()), "paintedWorldBounds": str(actor.world_label_rect()), "suppressed": actor.labels_suppressed})
	capture_states.append({"name": name_value, "path": path, "callouts": callouts, "promptVisible": main.founder_hud.interaction_visible(), "promptBounds": str(main.founder_hud.interaction_rect())})

func click(point: Vector2, capture_prefix: String = "") -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	root.push_input(move, true)
	await frames(1)
	if not capture_prefix.is_empty(): await capture(capture_prefix + "-hover")
	for down: bool in [true, false]:
		# Capturing a held button yields rendered frames; keep the test pointer
		# at the intended hit target rather than inheriting an OS mouse position.
		root.push_input(move, true)
		await frames(1)
		var event_value := InputEventMouseButton.new()
		event_value.position = point
		event_value.button_index = MOUSE_BUTTON_LEFT
		event_value.pressed = down
		root.push_input(event_value, true)
		await frames(1)
		if down and not capture_prefix.is_empty(): await capture(capture_prefix + "-pressed")

func safe_callout(rect: Rect2, message: String) -> void:
	for obstacle: Rect2 in main._world_ui_obstacles():
		check(not rect.intersects(obstacle), message + " clears furniture and UI")
	check(not rect.intersects(WorldCalloutSkin.actor_rect(main.player.position)), message + " clears founder")
	for actor: EmployeeAvatar in main._employees.values():
		check(not rect.intersects(WorldCalloutSkin.actor_rect(actor.position)), message + " clears " + actor.display_name)

func check_callout_integration() -> void:
	fixture()
	main.job_panel.close_drawer(false)
	var employee := main.get_employee("mira")
	var other := main.get_employee("theo")
	employee.position = Vector2(368, 528)
	other.position = Vector2(752, 528)
	main.player.position = Vector2(436, 592)
	main._process(0)
	check(main.founder_hud.interaction_visible(), "Audited founder-desk approach still offers a visible Chat prompt")
	safe_callout(main.founder_hud.interaction_rect(), "Prompt including pointer")
	var prompt := main.founder_hud._interaction_prompt.get_node("ChatAction") as Button
	check(prompt.size.x >= 44 and prompt.size.y >= 44 and prompt.focus_mode == Control.FOCUS_ALL, "Prompt keeps44px input target and keyboard focus")
	check(prompt.tooltip_text == "Chat with Mina (E)", "Prompt exposes both target name and E shortcut")
	await capture("prompt-desk-clear")
	prompt.grab_focus()
	check(prompt.has_focus(), "World prompt has an explicit keyboard-focus target")
	await capture("prompt-focused")
	prompt.release_focus()
	var before := main.player.position
	var requests: Array[String] = []
	main.founder_hud.chat_requested.connect(func(id: String) -> void: requests.append(id))
	await click(prompt.get_global_rect().get_center(), "prompt")
	await frames(15)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Real prompt click opens the intended employee once")
	check(requests == ["mira"], "One actual mouse release emits exactly one employee interaction")
	check(main.player.position == before and main.player.route.is_empty(), "Prompt click does not leak into world movement")
	main._process(0)
	check(not employee._labels_visible() and not employee._speech_visible, "Chat drawer removes redundant employee callouts")
	await capture("drawer-no-duplicate")
	main.job_panel.show_pending_promotions([{"jobId": "world-delivery", "employeeId": "mira", "title": "Website", "summary": "Ready"}])
	main._process(0)
	check(employee.attention_cue_visible() and not employee.labels_suppressed, "Restored delivery keeps a compact visible cue while drawer is selected")
	safe_callout(employee.world_label_rect(), "Selected delivery cue")
	await capture("drawer-delivery-cue")
	main.job_panel.show_pending_promotions([])
	main.job_panel.close_drawer(false)
	main.player.position = Vector2(560, 620)
	main._process(0)
	employee.memory_line = "Yesterday's customer notes point to one clear promise for the website."
	employee._speech_visible = true
	main._update_label_visibility("")
	check(not employee.labels_suppressed, "Audited speech fixture has a furniture-clear placement")
	safe_callout(employee.world_label_rect(), "Complete speech including pointer")
	check(" ".join(employee._wrap_speech(employee.memory_line, 21)) == "One clear idea at a time.", "Overlong ambient memory uses a deliberate complete thought")
	await capture("speech-complete-desk-clear")
	employee.memory_line = "One clear offer."
	main._update_label_visibility("")
	check(employee._wrap_speech(employee.memory_line, 21) == PackedStringArray(["One clear offer."]), "Short original thought is shown whole")
	await capture("speech-one-line")
	var blocked: Array[Rect2] = [Rect2(0, 0, 1280, 720)]
	check(not WorldCalloutSkin.place(employee.position, Vector2(188, 64), blocked, Rect2(18, 82, 1114, 620), true).has_area(), "No safe placement suppresses rather than covering a face")
	main.founder_hud.update_interaction(employee.position + Vector2(48, 0), main._employees, true, blocked)
	check(not main.founder_hud.interaction_visible() and main.founder_hud.interaction_target_id() == "mira", "Crowded prompt keeps the E target and rail alternative without painting over furniture")
	employee.set_speech_suppressed(true)
	employee._speech_visible = true
	employee.set_speech_suppressed(true)
	check(not employee._speech_visible, "Repeated suppression refresh enforces its invariant after a stale fixture/event")
	for down: bool in [true, false]:
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_E
		key_event.physical_keycode = KEY_E
		key_event.pressed = down
		root.push_input(key_event, true)
		await frames(1)
	await frames(15)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Actual E input still opens Chat when the visual prompt has no safe slot")
	check(requests == ["mira", "mira"], "The hidden-prompt E press emits exactly one interaction")
	main.job_panel.close_drawer(false)
	for position_value: Vector2 in [Vector2(80, 176), Vector2(1072, 624), Vector2(496, 384)]:
		employee.position = position_value
		main.player.position = position_value + Vector2(32, 0)
		main._process(0)
		if main.founder_hud.interaction_visible(): safe_callout(main.founder_hud.interaction_rect(), "Edge/crowded prompt")
		if not employee.labels_suppressed: safe_callout(employee.world_label_rect(), "Edge/crowded employee callout")

func check_live_attention() -> void:
	for kind: StringName in [&"approval.required", &"job.completed"]:
		fixture()
		var employee := main.get_employee("mira")
		employee.position = Vector2(448, 592)
		main.get_employee("theo").position = Vector2(752, 592)
		main.player.position = Vector2(560, 624)
		begin()
		event(&"job.started")
		event(kind)
		main.job_panel.open_drawer(false)
		main.job_panel._tabs.current_tab = 2
		check(employee._effect_sprite.visible and employee._effect_elapsed == 0, "Live event starts a real first-frame burst: " + kind)
		var unchanged := [employee.position, employee.work_state, employee._route.duplicate(), employee._has_target, employee._activity, employee._effect_duration, employee._effect_elapsed, employee._effect_sprite.region_rect, main.day_clock.minute_of_day]
		main._process(0)
		check(employee._drawer_selected and employee.world_paused, "Actual event fixture selects employee with world clock paused")
		check(employee.attention_cue_visible() and not employee.labels_suppressed, "Live selected attention uses the readable anchored cue")
		check(employee._effect_sprite.visible and employee._effect_sprite.self_modulate.a == 0, "Burst stays active for timing but does not paint a duplicate speck")
		check(not employee._labels_visible(), "Live selected attention does not restore a duplicate name/status card")
		check([employee.position, employee.work_state, employee._route, employee._has_target, employee._activity, employee._effect_duration, employee._effect_elapsed, employee._effect_sprite.region_rect, main.day_clock.minute_of_day] == unchanged, "Cue ownership changes no event, movement, timer or clock state")
		safe_callout(employee.world_label_rect(), "Live selected attention")
		# Observe the settled production drawer/toast, not a frame mid-entrance.
		# This waits only in the fixture; event timing and actor pose stay intact.
		await create_timer(0.22).timeout
		await capture("drawer-live-approval-cue" if kind == &"approval.required" else "drawer-live-delivery-cue")
		main.job_panel.close_drawer(false)
		main._process(0)
		check(employee._effect_sprite.visible and employee._effect_sprite.self_modulate.a == 1, "Closing the drawer restores existing burst paint without restarting it")
		check(not employee.attention_cue_visible(), "Returning to the world still paints only one attention cue")
		check(employee._effect_elapsed == unchanged[6], "Returning to the world does not reset or advance event timing")

func check_answered_approval() -> void:
	fixture()
	var employee := main.get_employee("mira")
	employee.position = Vector2(448, 592)
	main.get_employee("theo").position = Vector2(752, 592)
	main.player.position = Vector2(560, 624)
	begin()
	event(&"job.started")
	event(&"approval.required")
	main.job_panel.open_drawer(false)
	main.job_panel._tabs.current_tab = 2
	main._process(0)
	await create_timer(0.22).timeout
	check(employee.has_attention() and employee.attention_cue_visible() and not employee.labels_suppressed, "An unanswered live approval retains its selected world cue")
	var decisions: Array[bool] = []
	main.job_panel.approval_decided.connect(func(_job: String, _approval: String, approved: bool) -> void: decisions.append(approved))
	var approve: Button
	for candidate: Node in main.job_panel._approval_box.find_children("*", "Button", true, false):
		if (candidate as Button).text == "Approve": approve = candidate as Button
	check(approve != null, "Live approval exposes a real Approve button")
	if approve == null: return
	main.job_panel._activity_scroll.ensure_control_visible(approve)
	await frames(3)
	check(approve.is_visible_in_tree() and not approve.disabled and main.job_panel._activity_scroll.get_global_rect().encloses(approve.get_global_rect()), "Approve has a visible, enabled, unclipped hit target")
	var unchanged := [employee.position, employee.work_state, employee._route.duplicate(), employee._has_target, employee._activity, employee._effect_duration, employee._effect_elapsed, employee._effect_sprite.region_rect, main.day_clock.minute_of_day]
	await click(approve.get_global_rect().get_center())
	main._process(0)
	check(decisions == [true], "Actual Approve mouse release dispatches one decision")
	check(main.job_panel._employee_ui_state("mira") == "working" and employee.presentation_label() == "Working", "Answered approval agrees with the Activity and rail business state")
	check(not employee.has_attention() and not employee.attention_cue_visible(), "Answered approval immediately clears the anchored world attention cue")
	check(employee._effect_sprite.visible and employee._effect_sprite.self_modulate.a == 0, "Stale physical approval burst stops painting without changing its timer ownership")
	check([employee.position, employee.work_state, employee._route, employee._has_target, employee._activity, employee._effect_duration, employee._effect_elapsed, employee._effect_sprite.region_rect, main.day_clock.minute_of_day] == unchanged, "Answering approval changes no pose, route, activity, effect timing or clock state")
	await create_timer(0.22).timeout
	await capture("drawer-approval-answered")
	main.job_panel.close_drawer(false)
	main._process(0)
	check(not employee.attention_cue_visible() and employee._effect_sprite.self_modulate.a == 0, "Closing the drawer cannot resurrect an answered approval cue")
	main.job_panel.open_drawer(false)
	main.job_panel._tabs.current_tab = 2
	main._process(0)
	event(&"tool.started", "write_file")
	check(employee._activity == &"typing" and employee._effect_sprite.visible and employee._effect_sprite.self_modulate.a == 1, "The next real tool event immediately restores its own working effect")
	main._process(0)
	check(not employee.has_attention() and not employee.attention_cue_visible(), "Resumed tool activity does not revive a decision cue")
	await create_timer(0.22).timeout
	await capture("drawer-approval-tool-resumed")
	event(&"approval.required")
	main._process(0)
	check(employee.has_attention() and employee.attention_cue_visible() and employee._effect_sprite.self_modulate.a == 0, "A later genuine pending approval is not hidden by the earlier answer")

func run() -> void:
	root.size = Vector2i(1280, 720)
	check_world_typography()
	await check_callout_integration()
	await check_live_attention()
	await check_answered_approval()
	fixture()
	begin()
	event(&"job.started")
	project("Waiting for desk" if main.get_employee("mira")._waiting_for_desk else "To desk")
	event(&"job.completed")
	var employee := main.get_employee("mira")
	employee.world_paused = false
	for frame: int in range(900):
		if not employee._has_target: break
		employee._physics_process(1.0 / 60.0)
	check(not employee._has_target and employee.work_state == EmployeeAvatar.WorkState.IDLE, "Real deterministic delivery route reaches idle arrival")
	project("Delivery ready")
	check(main.job_panel._employee_ui_state("mira") == "delivery ready", "World and drawer agree after delivery arrival")

	fixture()
	main.job_panel.show_pending_promotions([{"jobId": "saved-delivery", "employeeId": "mira", "title": "Saved website", "summary": "Ready for review"}])
	project("Delivery ready")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.IDLE, "Hydrated pending delivery does not restart its completed animation")
	main.job_panel.show_pending_promotions([])
	project("Available")

	fixture()
	main.day_clock.set_time(1, 18 * 60)
	project("Off shift")
	begin()
	main.job_panel.mark_job_queued("fixture-job")
	project("Queued")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.OFF_SHIFT, "Queued wording leaves off-shift physical schedule intact")

	fixture()
	main.day_clock.set_time(1, DayClock.LUNCH_START)
	project("At lunch")

	fixture()
	begin()
	event(&"job.started")
	event(&"approval.required")
	project("Needs approval")
	event(&"job.failed")
	project("Needs retry")

	fixture()
	main.job_panel.restore_job("saved-running", "running", "Restored work", "mira")
	project("Working")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.IDLE, "Cached running label does not invent a physical animation")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var result_name := "results-headless.json" if DisplayServer.get_name() == "headless" else "results.json"
	var file := FileAccess.open(OUTPUT.path_join(result_name), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "viewport": [1280, 720], "captures": capture_states, "limitations": ["Godot input events, not physical OS hardware.", "Crowded callouts suppress if none of eight nearby placements avoids actors, furniture and UI; E and rail remain available."]}, "\t"))
	file.close()
	print("World UI presentation: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
