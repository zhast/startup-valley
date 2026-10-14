extends SceneTree

## Title → Chapter 1 website → Theo / ads → incorporate → chapter-complete.
## Uses the worker offline/fake provider. No paid model call.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	OS.set_environment("STARTUP_VALLEY_FAKE_PROVIDER", "1")
	if OS.get_environment("STARTUP_VALLEY_DATA_DIR").is_empty():
		var data_dir := OS.get_temp_dir().path_join("startup-valley-full-path-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
		DirAccess.make_dir_recursive_absolute(data_dir)
		OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failures.append(message)
		push_error("FAIL " + message)

func frames(count: int = 2) -> void:
	for _index: int in range(count):
		await process_frame

func wait_until(predicate: Callable, message: String, timeout_ms: int = 20000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await frames(1)
		if predicate.call():
			return true
	check(false, message)
	return false

func any_button(prefix: String, root: Node = null) -> Button:
	var search := root if root != null else main
	if search == null:
		return null
	for node: Node in search.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.to_lower().begins_with(prefix.to_lower()):
			return button
	return null

func button_named(prefix: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return any_button(prefix, main.company_panel)

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled), "Click target is visible and enabled: " + (str(control.name) if control != null else "missing") + ((" / " + (control as Button).text) if control is Button else ""))
	if control == null:
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		viewport.push_input(event, true)
		await frames(1)
	if is_instance_valid(control) and control is BaseButton and (control as BaseButton).is_visible_in_tree() and not (control as BaseButton).disabled:
		(control as BaseButton).pressed.emit()
	await frames(8)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	viewport.push_input(event, true)
	await frames(1)

func milestone(id: String) -> Dictionary:
	for item: Dictionary in main._journey.get("milestones", []):
		if str(item.get("id", "")) == id:
			return item
	return {}

func close_overlays() -> void:
	if main.job_panel._connection_panel != null and main.job_panel._connection_panel.visible:
		main.job_panel._close_connection_settings()
		await frames(4)
	if main.job_panel.drawer_is_open():
		main.job_panel.close_drawer(false)
		await frames(6)

func open_journey() -> void:
	await close_overlays()
	if not main.company_panel.visible or main.company_panel.screen not in ["journey", "complete"]:
		main.company_panel.present("journey")
		await frames(8)

func resolve_work_order(employee_id: String, milestone_id: String) -> void:
	await wait_until(func() -> bool: return str(milestone(milestone_id).get("jobStatus", "")) == "completed" and main.job_panel.active_job_id().is_empty(), "Work order completed for " + milestone_id)
	main.job_panel.open_journal_for_employee(employee_id)
	await frames(12)
	var promote := any_button("Add to Studio", main.job_panel)
	var promote_deadline := Time.get_ticks_msec() + 12000
	while (promote == null or promote.disabled) and Time.get_ticks_msec() < promote_deadline:
		await frames(4)
		promote = any_button("Add to Studio", main.job_panel)
	await click(promote)
	await frames(16)
	main.job_panel.close_drawer(false)
	await frames(6)
	await open_journey()
	var evaluate := button_named("Evaluate result")
	await wait_until(func() -> bool: return button_named("Evaluate result") != null and not button_named("Evaluate result").disabled, "Evaluate result is ready for " + milestone_id)
	evaluate = button_named("Evaluate result")
	await click(evaluate)
	await wait_until(func() -> bool: return button_named("Complete milestone") != null and not main.company_panel.busy, "Passing review offers Complete milestone for " + milestone_id)
	await click(button_named("Complete milestone"))
	await wait_until(func() -> bool: return str(milestone(milestone_id).get("state", "")) == "completed", "Milestone completed: " + milestone_id)

func assign_current_milestone(expected_id: String) -> void:
	await open_journey()
	check(str(CompanyPanel.open_milestone(main._journey).get("id", "")) == expected_id, "Journey current milestone is " + expected_id)
	var prepare := button_named("Prepare work order")
	await click(prepare)
	await frames(16)
	check(not main.company_panel.visible and main.job_panel.drawer_is_open(), "Prepare work order opens Assign for " + expected_id)
	check(main.job_panel.milestone_id == expected_id, "Assign is bound to " + expected_id)
	check(main.job_panel._credential_configured, "Offline provider is treated as connected")
	if main.job_panel._connection_panel != null and main.job_panel._connection_panel.visible:
		main.job_panel._close_connection_settings()
		await frames(4)
	await wait_until(func() -> bool: return main.job_panel._assign_button != null and main.job_panel._assign_button.is_visible_in_tree() and not main.job_panel._assign_button.disabled, "Start work order is enabled for " + expected_id)
	await click(main.job_panel._assign_button)
	await wait_until(func() -> bool: return not main.job_panel.active_job_id().is_empty() or str(milestone(expected_id).get("jobStatus", "")) in ["running", "queued", "completed"], "Work order submitted for " + expected_id)
	check(main.job_panel.active_job_id().is_empty() or not main.job_panel._connection_panel.visible, "Offline assign does not dead-end on Connect")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	main = MAIN.instantiate()
	viewport.add_child(main)
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await frames(1)
		if main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty():
			break
	check(main._state_loaded and main._worker_ready, "Worker bootstrap loads a fresh company")
	check(main.company_panel.visible and main.company_panel.screen == "title", "Fresh company opens on the title screen")
	main.day_clock.set_speed(0)
	var start := button_named("Start company")
	await click(start)
	await wait_until(func() -> bool: return main.company_panel.visible and main.company_panel.screen == "journey", "Start company opens Journey for the first hire")
	await wait_until(func() -> bool: return main.job_panel._credential_configured and main.job_panel._offline_provider, "Offline provider reports credentials configured")
	await close_overlays()
	check(main.job_panel._offline_provider, "Connect copy uses the offline test provider")
	var next_step := CompanyPanel.next_step_line(main._journey)
	check(next_step.to_lower().contains("mina") or next_step.to_lower().contains("hire"), "On-screen guidance names the first hire: " + next_step)
	await click(button_named("Hire Mina"))
	await wait_until(func() -> bool: return main.company_panel.screen == "hired" and main._employees.has("mira"), "Hiring Mina confirms")
	check(main._employees.has("mira") and not main._employees.has("theo"), "Only Mina joins the office")
	await click(button_named("Meet Mina"))
	await frames(12)
	check(not main.company_panel.visible, "Meet Mina returns to the office")
	if main.founder_hud._next_step_label != null:
		next_step = main.founder_hud._next_step_label.text
	check(main.founder_hud._next_step_hint.visible and next_step.to_lower().contains("website"), "Office hint names the website work order: " + next_step)
	await assign_current_milestone("website")
	await resolve_work_order("mira", "website")
	check(int((main._journey.get("company", {}) as Dictionary).get("cashCents", 0)) >= 30000, "Website reward funds the Theo hire")
	await open_journey()
	check(button_named("Hire Theo") != null, "Theo hire is the next content after the website")
	await click(button_named("Hire Theo"))
	await frames(30)
	check(main._employees.has("theo"), "Theo joins the office")
	await click(button_named("Meet Theo"))
	await frames(12)
	await open_journey()
	await click(button_named("End day"))
	await frames(30)
	check(main.company_panel.screen == "summary", "Ending day 1 reaches the day summary")
	await click(button_named("Begin next day"))
	await frames(16)
	check(not main.company_panel.visible, "Begin next day returns to the office")
	check(main.day_clock.day == 2, "Day 2 has started")
	if main.founder_hud._next_step_label != null:
		next_step = main.founder_hud._next_step_label.text
	check(next_step.to_lower().contains("ads") or next_step.to_lower().contains("advert"), "Day 2 guidance names the ads milestone: " + next_step)
	await assign_current_milestone("ads")
	await resolve_work_order("theo", "ads")
	await open_journey()
	await click(button_named("End day"))
	await frames(30)
	await click(button_named("Begin next day"))
	await frames(16)
	check(main.day_clock.day == 3, "Day 3 has started")
	await assign_current_milestone("incorporate")
	await resolve_work_order("mira", "incorporate")
	await wait_until(func() -> bool: return main.company_panel.visible and main.company_panel.screen == "complete", "Chapter-complete screen is presented")
	check(int((main._journey.get("company", {}) as Dictionary).get("chapter", 1)) == 2, "Company chapter advances after incorporation")
	var heading := ""
	for node: Node in main.company_panel._header.find_children("*", "Label", true, false):
		var label := node as Label
		if str(label.get_meta("cozy_text_role", "")) == "display":
			heading = label.text
			break
	check(heading.to_lower().contains("chapter complete"), "Win state heading names Chapter complete: " + heading)
	check(button_named("Back to office") != null, "Chapter-complete screen can return to the office")
	check(CompanyPanel.next_step_line(main._journey).to_lower().contains("chapter is complete"), "Guidance reports the chapter is complete")
	print("FULLPATH ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	var exit_code := 0 if failures.is_empty() else 1
	if exit_code == 0:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
