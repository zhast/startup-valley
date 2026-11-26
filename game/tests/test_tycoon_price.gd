extends SceneTree

## Headless launch-price loop with the real worker and an isolated company.
## Catalog is the default. A −20% nudge stores on the product and sells more units.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-price-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func check_price_buttons_secondary() -> void:
	for node_name: String in ["Price_80", "Price_100", "Price_120"]:
		var button := button_id(node_name)
		check(button != null and str(button.get_meta("cozy_variant", "")) == "secondary", node_name + " is a secondary action")

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
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check_price_buttons_secondary()
	var catalog := button_id("Price_100")
	check(catalog != null and catalog.text == "Catalog", "Catalog is the middle price step")
	var effect := label_named("PriceEffect")
	check(effect != null and effect.text == "$9.00 · catalog units", "Catalog shows $9.00 · catalog units")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(int(developing().get("pricePercent", -1)) == 100, "A starter product stores catalog price")
	check(int(developing().get("priceCents", -1)) == 900, "A starter product stores the $9 unit price")
	check(label_named("LaunchPrice") != null and label_named("LaunchPrice").text == "$9.00 · catalog units", "The bench shows the catalog price line")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Catalog launch still pays 20700 cents")
	check(company_reputation() == 5, "Catalog launch still pays 5 fans")
	check(label_named("ReleasePrice") != null and label_named("ReleasePrice").text == "$9.00 · catalog units", "Release shows the catalog price line")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_id("Price_80"))
	await frames(4)
	check_price_buttons_secondary()
	effect = label_named("PriceEffect")
	check(effect != null and effect.text == "$7.20 · +20% units", "−20% shows $7.20 · +20% units")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and int(developing().get("pricePercent", -1)) == 80 and not main.company_panel.busy, "The second product stores −20%")
	check(int(developing().get("priceCents", -1)) == 720, "The second product stores the $7.20 unit price")
	check(label_named("LaunchPrice") != null and label_named("LaunchPrice").text == "$7.20 · +20% units", "The bench shows the cheaper price line")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and int(latest_shipped().get("pricePercent", -1)) == 80, "Release opens the cheaper product")
	var shipped := latest_shipped()
	check(int(shipped.get("priceCents", -1)) == 720, "The shipped product keeps the $7.20 unit price")
	check(int(shipped.get("salesCents", 0)) > 0 and int(shipped.get("salesCents", 0)) != 20700, "A cheaper launch pays a different cash amount")
	check(int(shipped.get("fans", 0)) >= 1, "Fans still follow units")
	check(label_named("ReleasePrice") != null and label_named("ReleasePrice").text == "$7.20 · +20% units", "Release shows $7.20 · +20% units")
	check(not main.job_panel._connection_panel.visible, "Price never opens Connect")
	print("TYCOON PRICE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
