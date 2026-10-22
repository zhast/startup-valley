extends SceneTree

## Headless ship-a-product loop with the real worker and an isolated company.
## No fake provider and no credential. Pick Crypto Alpha × Newsletter, build
## across office days, release, and watch game cash and reputation rise.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func button_named(prefix: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.to_lower().begins_with(prefix.to_lower()):
			return button
	return null

func label_named(node_name: String) -> Label:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Label

func label_contains(fragment: String) -> bool:
	if main == null or main.company_panel == null:
		return false
	for node: Node in main.company_panel.find_children("*", "Label", true, false):
		if (node as Label).text.contains(fragment):
			return true
	return false

func reveal(control: Control) -> void:
	if control == null or main == null or main.company_panel == null:
		return
	var content := main.company_panel._content
	if content == null or not content.is_ancestor_of(control):
		return
	var top := control.position.y
	var current := control.get_parent()
	while current != null and current != content:
		if current is Control:
			top += (current as Control).position.y
		current = current.get_parent()
	main.company_panel._scroll.scroll_vertical = maxi(0, int(top) - 8)
	await frames(3)

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled), "Click target is visible and enabled: " + (str(control.name) if control != null else "missing") + ((" / " + (control as Button).text) if control is Button else ""))
	if control == null:
		return
	await reveal(control)
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
	await frames(8)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	viewport.push_input(event, true)
	await frames(1)

func company_cash() -> int:
	var company: Dictionary = main.company_panel.state.get("company", {})
	return int(company.get("cashCents", 0))

func company_reputation() -> int:
	var company: Dictionary = main.company_panel.state.get("company", {})
	return int(company.get("reputation", 0))

func developing() -> Dictionary:
	var tycoon: Dictionary = main.company_panel.state.get("tycoon", {})
	var value: Variant = tycoon.get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func open_journey() -> void:
	if main.company_panel.visible and main.company_panel.screen == "journey":
		return
	if main.company_panel.visible:
		var back := button_named("Back to office")
		if back != null:
			await click(back)
			await frames(8)
	await key(KEY_J, true)
	await key(KEY_J, false)
	await wait_until(func() -> bool: return main.company_panel.visible and main.company_panel.screen == "journey", "J opens Company Journey")

func open_product() -> void:
	await open_journey()
	if main.company_panel.screen != "product":
		await click(button_named("New Product"))
		await wait_until(func() -> bool: return main.company_panel.screen == "product" and not main.company_panel.busy, "New Product opens the ship screen")

func end_office_day() -> void:
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the day opens the summary")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)

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
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads a fresh company")
	if not ready:
		_finish()
		return
	check(main.company_panel.screen == "title", "Fresh company opens on the title screen")
	check(company_cash() == 0 and company_reputation() == 0, "A new company starts with no cash and no fans")
	main.day_clock.set_speed(0)
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	var fit := label_named("ProductFit")
	check(fit != null and fit.text.contains("Bad"), "Fitness × Software Tool starts as a bad fit")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	fit = label_named("ProductFit")
	check(fit != null and fit.text.contains("Great"), "Crypto Alpha × Newsletter shows a great fit: " + (fit.text if fit != null else "missing"))
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	var progress := label_named("ProductProgress")
	check(progress != null and str(progress.text).begins_with("Building"), "The bench shows building progress")
	check(int(developing().get("devDays", -1)) == 0, "The first morning has not built yet")
	await end_office_day()
	await open_product()
	check(int(developing().get("devDays", -1)) == 1 and int(developing().get("design", -1)) == 2, "One office day adds the founder's design points")
	await end_office_day()
	await open_product()
	progress = label_named("ProductProgress")
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	check(progress != null and progress.text == "Ready to ship", "The bench says Ready to ship")
	check(int(developing().get("design", 0)) == 4 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 4, "Founder-only craft is 4 / 4 / 4")
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() > 0, "Release opens the results card and pays launch sales")
	if released:
		var score := label_named("ReleaseScore")
		check(score != null and score.text.begins_with("Score ") and score.text.contains("/ 10"), "Release card shows a score out of 10")
		check(label_contains("Whop Weekly"), "Whop Weekly reviews the launch")
		check(label_contains("Discord Dave"), "Discord Dave reviews the launch")
		check(label_contains("Margin Call Molly"), "Margin Call Molly reviews the launch")
		check(label_contains("Cohort Casey"), "Cohort Casey reviews the launch")
		check(label_contains("Launch sales"), "Release card shows launch sales")
		var launch_cash := company_cash()
		var launch_fans := company_reputation()
		check(launch_cash > 0 and launch_fans > 0, "Launch sales raise cash and reputation (%d cents, %d fans)" % [launch_cash, launch_fans])
		check(label_contains("Crypto Alpha Newsletter"), "The shelf names the shipped product")
		await open_journey()
		await end_office_day()
		check(company_cash() == launch_cash, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		check(company_cash() > launch_cash and company_reputation() > launch_fans, "The next office day keeps selling (%d cents, %d fans)" % [company_cash(), company_reputation()])
	check(not main.job_panel._connection_panel.visible, "Shipping a product never opens Connect")
	check(main.job_panel.active_job_id().is_empty(), "No chapter work order is submitted")
	print("TYCOON ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
