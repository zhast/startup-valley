extends SceneTree

## Headless seasons with the real worker and an isolated company.
## The Season card and the date label move forward when the office day ends.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-seasons-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func tycoon_state() -> Dictionary:
	var value: Variant = main.company_panel.state.get("tycoon", {})
	return value as Dictionary if value is Dictionary else {}

func calendar() -> Dictionary:
	var value: Variant = tycoon_state().get("calendar", {})
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
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(main.company_panel.find_child("SeasonCard", true, false) != null, "The Season card is on Company Journey")
	var office_date := label_named("OfficeDate")
	check(office_date != null and office_date.text.contains("Spring 1 · Year 1"), "The date label reads Spring 1 · Year 1")
	check(label_named("SeasonTopics") != null and label_named("SeasonTopics").text == "In season: Fitness, Dating Advice", "Spring favors Fitness and Dating Advice")
	check(label_named("SeasonEvent") != null and label_named("SeasonEvent").text == "Creator Fair in 12 days", "Creator Fair is 12 days away on Spring 1")
	check(str(calendar().get("season", "")) == "spring" and int(calendar().get("dayOfSeason", 0)) == 1 and int(calendar().get("year", 0)) == 1, "The worker calendar is Spring 1, Year 1")
	check(calendar().get("event") == null, "Spring 1 has no event")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the day opens the summary")
	check(label_contains("Spring 1 · Year 1"), "The day summary names the season date that just ended")
	check(not label_contains("Spring 2"), "The summary stays on Spring 1")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	office_date = label_named("OfficeDate")
	check(office_date != null and office_date.text.contains("Spring 2 · Year 1"), "The date label reads Spring 2 · Year 1 after End day")
	check(label_named("SeasonTopics") != null and label_named("SeasonTopics").text == "In season: Fitness, Dating Advice", "Spring still favors the same topics")
	check(label_named("SeasonEvent") != null and label_named("SeasonEvent").text == "Creator Fair in 11 days", "Creator Fair is one day closer")
	check(int(calendar().get("dayOfSeason", 0)) == 2 and int(calendar().get("year", 0)) == 1, "The worker calendar moved to Spring 2")
	hire = button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary the next morning")
	check(not main.job_panel._connection_panel.visible, "The season card never opens Connect")
	await open_product()
	var fitness := button_named("Fitness")
	var dating := button_named("Dating Advice")
	var crypto := button_named("Crypto Alpha")
	check(fitness != null and fitness.text.contains("in season"), "Fitness is tagged in season")
	check(dating != null and dating.disabled and dating.text.contains("locked") and dating.text.contains("in season"), "Locked Dating Advice is still tagged in season")
	check(crypto != null and not crypto.disabled and not crypto.text.contains("in season"), "Crypto Alpha is not in season in Spring")
	check(not main.job_panel._connection_panel.visible, "The product picker stays offline")
	print("TYCOON SEASONS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
