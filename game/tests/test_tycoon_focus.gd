extends SceneTree

## Headless focus loop with the real worker and an isolated company.
## Balanced is the default. Design, Tech, or Hype stores +1 on that stat.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-focus-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func button_id(node_name: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Button

func label_named(node_name: String) -> Label:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Label

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

func tycoon_state() -> Dictionary:
	var value: Variant = main.company_panel.state.get("tycoon", {})
	return value as Dictionary if value is Dictionary else {}

func developing() -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func latest_shipped() -> Dictionary:
	var history: Array = tycoon_state().get("history", []) as Array
	if history.is_empty() or not history[0] is Dictionary:
		return {}
	return history[0] as Dictionary

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

func focus_of(product: Dictionary) -> Dictionary:
	var value: Variant = product.get("focus", null)
	return value as Dictionary if value is Dictionary else {}

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	main = MAIN.instantiate()
	main.demo_story_mode = false
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads a fresh company")
	if not ready:
		_finish()
		return
	main.day_clock.set_speed(0)
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	check(button_id("Engine_none") == null, "The engine choice waits until the kit is owned")
	var balanced := button_id("Focus_balanced")
	var design := button_id("Focus_design")
	var tech := button_id("Focus_tech")
	var hype := button_id("Focus_hype")
	check(balanced != null and not balanced.disabled and str(balanced.get_meta("cozy_variant", "")) == "secondary" and balanced.text == "Balanced", "Balanced is the default focus")
	check(design != null and not design.disabled and str(design.get_meta("cozy_variant", "")) == "secondary" and design.text == "Design", "Design is a secondary focus")
	check(tech != null and tech.text == "Tech" and hype != null and hype.text == "Hype", "Tech and Hype sit on the same row")
	check(label_named("FocusEffect") != null and label_named("FocusEffect").text == "Balanced · no point bump", "Balanced shows no point bump")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build", "The build line starts plain")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(developing().get("focus") == null, "A balanced product stores no focus")
	check(company_cash() == 0, "Starting balanced spends nothing")
	check(int(developing().get("design", -1)) == 0 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "Balanced adds no points on day zero")
	check(label_named("FocusLine") == null, "The bench hides the line when the focus is Balanced")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(int(developing().get("design", 0)) == 4 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 4, "Two founder days stay at 4/4/4")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Balanced still pays 20700 cents")
	check(company_reputation() == 5, "Balanced still pays 5 fans")
	check(latest_shipped().get("focus") == null, "The shipped newsletter keeps no focus")
	check(label_named("ReleaseFocus") == null, "Release hides the line when the focus is Balanced")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	design = button_id("Focus_design")
	check(label_named("FocusEffect") != null and label_named("FocusEffect").text == "Balanced · no point bump", "The next picker starts on Balanced")
	await click(design)
	await frames(4)
	check(label_named("FocusEffect") != null and label_named("FocusEffect").text == "Design · +1 design", "Design shows +1 design")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Design", "The build line names the focus")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays primary beside the focus")
	var cash_before_start := company_cash()
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and str(focus_of(developing()).get("id", "")) == "design" and not main.company_panel.busy, "The second product starts on Design")
	var stored := focus_of(developing())
	check(str(stored.get("label", "")) == "Design" and str(stored.get("stat", "")) == "design" and int(stored.get("bonus", 0)) == 1, "The product stores Design and +1 design")
	check(int(developing().get("design", 0)) == 1 and int(developing().get("tech", 0)) == 0 and int(developing().get("hype", 0)) == 0, "Design shows the point bump before any office day")
	check(company_cash() == cash_before_start, "Choosing a focus spends nothing")
	check(label_named("FocusLine") != null and label_named("FocusLine").text == "On the build · Design · +1 design", "The bench names the focus and the bump")
	await open_journey()
	check(label_named("FocusJourney") != null and label_named("FocusJourney").text == "On the build · Design · +1 design", "Journey names the focus on the build")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the focus")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 4, "Two founder days land on 5/4/4")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and focus_of(latest_shipped()).get("id", "") == "design", "Release opens the product that used Design")
	var shipped := latest_shipped()
	var review: Dictionary = shipped.get("review", {}) if shipped.get("review") is Dictionary else {}
	check(int(focus_of(shipped).get("bonus", 0)) == 1, "The shipped product keeps the point bump")
	check(int(review.get("score", 0)) >= 1 and int(review.get("score", 0)) <= 10, "The review score stays inside 1 to 10")
	check(int(shipped.get("salesCents", 0)) > 0 and int(shipped.get("fans", 0)) >= 1, "The focused product still pays cash and fans")
	check(label_named("ReleaseFocus") != null and label_named("ReleaseFocus").text == "On the build · Design · +1 design", "Release names the focus and the bump")
	check(not main.job_panel._connection_panel.visible, "Focus never opens Connect")
	print("TYCOON FOCUS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
