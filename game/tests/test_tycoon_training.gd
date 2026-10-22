extends SceneTree

## Headless staff-training loop with the real worker and an isolated company.
## Ship a newsletter for game cash, train Founder Tech, then start a second
## product and prove the new snapshot uses the trained stat.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-train-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func developing() -> Dictionary:
	var tycoon: Dictionary = main.company_panel.state.get("tycoon", {})
	var value: Variant = tycoon.get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func founder_staff() -> Dictionary:
	var tycoon: Dictionary = main.company_panel.state.get("tycoon", {})
	for item: Variant in tycoon.get("staff", []) as Array:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == "founder":
			return item as Dictionary
	return {}

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

func pick_newsletter() -> void:
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)

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
	main.day_clock.set_speed(0)
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	await pick_newsletter()
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	var first_tech := int(developing().get("tech", 0))
	check(first_tech == 4, "Founder-only tech before training is 4 after two days")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() > 0, "Release pays launch sales")
	await open_journey()
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(company_cash() >= 30000, "Second sales day covers a $300 Tech lesson (%d cents)" % company_cash())
	var train := button_named("Train Tech")
	check(train != null and not train.disabled, "Train Tech is enabled once cash covers the cost")
	var cash_before := company_cash()
	await click(train)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Founder trained Tech to 3"), "Training notice names the new Tech level")
	check(int(founder_staff().get("tech", 0)) == 3, "Founder Tech is 3 after the lesson")
	check(company_cash() == cash_before - 30000, "Training deducts $300 game cash")
	check(bool(founder_staff().get("trainedToday", false)), "Founder is in training for the rest of the day")
	var train_again := button_named("Train Design")
	check(train_again != null and train_again.disabled, "A second lesson the same day stays disabled")
	await end_office_day()
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed while starting the next product")
	await pick_newsletter()
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return str(developing().get("id", "")) == "p2" and not main.company_panel.busy, "A second product starts after training")
	await end_office_day()
	await open_product()
	check(int(developing().get("design", 0)) == 2, "The next product still uses founder Design 2")
	check(int(developing().get("tech", 0)) == 3, "The next product uses the trained Tech 3 snapshot")
	check(int(developing().get("hype", 0)) == 2, "The next product still uses founder Hype 2")
	check(not main.job_panel._connection_panel.visible, "Training never opens Connect")
	print("TYCOON TRAIN ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
