extends SceneTree

## Headless upgrades shop with the real worker and an isolated company.
## Ship a newsletter, buy Ring Light, end the day, and keep the owned line.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-upgrades-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func tycoon_state() -> Dictionary:
	var value: Variant = main.company_panel.state.get("tycoon", {})
	return value as Dictionary if value is Dictionary else {}

func developing() -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func upgrade_named(upgrade_id: String) -> Dictionary:
	for item: Variant in tycoon_state().get("upgrades", []) as Array:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == upgrade_id:
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
	check(tycoon_state().get("upgrades", []).size() == 4, "Company Journey lists the four office upgrades")
	var ring := button_named("Buy Ring Light")
	var desk := button_named("Buy Oak Standing Desk")
	var hire := button_named("Hire Mina")
	check(ring != null and ring.disabled and str(ring.get_meta("cozy_variant", "")) == "secondary", "Buy Ring Light starts disabled")
	check(desk != null and desk.disabled, "Buy Oak Standing Desk starts disabled")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(main.company_panel.find_child("UpgradesCard", true, false) != null, "The Upgrades card is on Company Journey")
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Release pays the $207 launch")
	await open_journey()
	check(button_named("Buy Ring Light") != null and button_named("Buy Ring Light").disabled, "Ring Light stays unaffordable on launch day")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(company_cash() == 33300, "The second sales day brings cash to $333")
	var desk_ready := button_named("Buy Oak Standing Desk")
	var ring_waiting := button_named("Buy Ring Light")
	check(desk_ready != null and not desk_ready.disabled, "Oak Standing Desk is affordable at $333")
	check(ring_waiting != null and ring_waiting.disabled, "Ring Light still costs more than $333")
	await end_office_day()
	await open_journey()
	check(company_cash() == 41400, "The third sales day brings cash to $414")
	ring = button_named("Buy Ring Light")
	check(ring != null and not ring.disabled and ring.text == "Buy Ring Light · $400", "Buy Ring Light · $400 is enabled")
	check(button_named("Buy Nicer Checkout Page") != null and button_named("Buy Nicer Checkout Page").disabled, "Nicer Checkout Page stays disabled")
	var cash_before := company_cash()
	await click(ring)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Bought Ring Light. −$400"), "Purchase notice names Ring Light")
	check(company_cash() == cash_before - 40000, "Ring Light deducts $400 game cash")
	check(bool(upgrade_named("ring_light").get("owned", false)), "Ring Light is owned")
	check(label_named("UpgradeNotice") != null, "Purchase notice is on screen the day of the buy")
	check(label_named("Owned_ring_light") != null and label_named("Owned_ring_light").text.contains("Ring Light"), "The owned line names Ring Light")
	check(button_named("Buy Ring Light") == null, "The buy button hides once the upgrade is owned")
	check(button_named("Buy Oak Standing Desk") != null, "Unowned upgrades keep their buy buttons")
	hire = button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the purchase")
	await end_office_day()
	await open_journey()
	check(label_named("UpgradeNotice") == null, "Purchase notice is gone after End day")
	check(not label_contains("Bought Ring Light"), "The purchase line does not linger into the next office day")
	check(label_named("Owned_ring_light") != null, "The owned line stays on the next office day")
	check(not main.job_panel._connection_panel.visible, "Buying an upgrade never opens Connect")
	print("TYCOON UPGRADES ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
