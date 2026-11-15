extends SceneTree

## Headless port loop with the real worker and an isolated company.
## No port is the default. One optional shelf spends game cash after sales finish
## and pays one extra sales day on the next day end.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-ports-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func button_node(node_name: String) -> Button:
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

func money(cents: int) -> String:
	var integer := str(absi(cents) / 100)
	var grouped := ""
	for index: int in range(integer.length()):
		if index > 0 and (integer.length() - index) % 3 == 0:
			grouped += ","
		grouped += integer[index]
	return ("-" if cents < 0 else "") + grouped + ".%02d" % (absi(cents) % 100)

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
	main.day_clock.set_speed(0)
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(button_named("Port") == null, "No port action before a ship")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(developing().get("port") == null, "A product on the bench has no port offer")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "No port still pays 20700 cents")
	check(company_reputation() == 5, "No port still pays 5 fans")
	await open_journey()
	var selling := main.company_panel.find_child("Selling_p1", true, false) as Control
	var early := button_node("Port_p1")
	check(selling != null, "Company Journey shows the selling-product card")
	check(early != null and early.disabled and str(early.get_meta("cozy_variant", "")) == "secondary" and early.text == "Port · Still selling.", "Port stays disabled while the product is selling")
	check(label_named("PortShelf_p1") == null, "The shelf line waits until sales finish")
	check(label_named("PortLine_p1") == null, "The port line waits until the port starts")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Port")
	var launch_cash := company_cash()
	var launch_fans := company_reputation()
	await end_office_day()
	await open_journey()
	check(company_cash() == launch_cash and company_reputation() == launch_fans, "Ending the release day does not sell twice")
	await end_office_day()
	await open_journey()
	check(company_cash() > launch_cash, "The next sales day still pays while the port stays locked")
	check(company_reputation() > launch_fans, "The next sales day still adds fans while the port stays locked")
	await open_journey()
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	var finished := main.company_panel.find_child("Finished_p1", true, false) as Control
	var port := button_node("Port_p1")
	var shipped := latest_shipped()
	var offer: Dictionary = shipped.get("port", {}) if shipped.get("port") is Dictionary else {}
	var review: Dictionary = shipped.get("review", {}) if shipped.get("review") is Dictionary else {}
	check(str(shipped.get("status", "")) == "complete", "Sales finish after four days")
	check(int(shipped.get("salesDays", 0)) == 4, "The sales window stays four days")
	check(finished != null, "Company Journey shows the finished-product card")
	check(int(review.get("score", 0)) == 6, "The first newsletter still scores 6")
	check(str(offer.get("phase", "missing")) == "" and bool(offer.get("enabled", false)), "Skipping the port leaves it ready on the finished card")
	check(port != null and not port.disabled and str(port.get_meta("cozy_variant", "")) == "secondary" and port.text == "Port", "Port is a secondary action")
	check(label_named("PortShelf_p1") != null and label_named("PortShelf_p1").text == "Whop Mobile · $80", "The shipped card names the shelf and the fee")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary on the finished card")
	var sales_cents := int(shipped.get("salesCents", 0))
	var sales_fans := int(shipped.get("fans", 0))
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(port)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("PortLine_p1") != null, "The port line appears")
	var started := latest_shipped()
	var selling_port: Dictionary = started.get("port", {}) if started.get("port") is Dictionary else {}
	check(label_named("PortLine_p1").text == "Port · Whop Mobile · selling 1 day", "The port sells for one day")
	check(str(selling_port.get("phase", "")) == "selling" and int(selling_port.get("cents", -1)) == 0, "The payload waits for the next day end")
	check(company_cash() == cash_before - 8000, "The port charges $80 once")
	check(company_reputation() == fans_before, "The fee adds no fans")
	check(int(started.get("salesCents", -1)) == sales_cents, "The fee does not change sales cash")
	check(int(started.get("fans", -1)) == sales_fans, "The fee does not change sales fans")
	check(int(started.get("salesDays", 0)) == 4, "Starting a port does not extend the sales window")
	var again := button_node("Port_p1")
	check(again != null and again.disabled and again.text == "Port · Already ported.", "A second port stays disabled")
	await end_office_day()
	await open_journey()
	var paid := latest_shipped()
	var sold: Dictionary = paid.get("port", {}) if paid.get("port") is Dictionary else {}
	var cents := int(sold.get("cents", 0))
	var fans := int(sold.get("fans", 0))
	check(str(sold.get("phase", "")) == "sold" and cents > 0 and fans >= 1, "The next day end pays the extra sales day")
	check(label_named("PortLine_p1") != null and label_named("PortLine_p1").text == "Port · Whop Mobile · $%s" % money(cents), "The port line names the extra sales")
	check(company_cash() == cash_before - 8000 + cents, "The extra day pays its cash once")
	check(company_reputation() == fans_before + fans, "The extra day adds its fans once")
	check(int(paid.get("salesCents", -1)) == sales_cents + cents, "The extra day adds to sales cash")
	check(int(paid.get("fans", -1)) == sales_fans + fans, "The extra day adds to sales fans")
	check(int(paid.get("salesDays", 0)) == 4 and str(paid.get("status", "")) == "complete", "The product stays finished after the port pays")
	var paid_cash := company_cash()
	var paid_fans := company_reputation()
	await end_office_day()
	await open_journey()
	var held := latest_shipped()
	var held_port: Dictionary = held.get("port", {}) if held.get("port") is Dictionary else {}
	check(company_cash() == paid_cash and company_reputation() == paid_fans, "A later day does not pay the port again")
	check(int(held_port.get("cents", -1)) == cents and int(held_port.get("fans", -1)) == fans, "The stored port payout stays put")
	check(button_node("Port_p1") != null and button_node("Port_p1").disabled, "The port button stays disabled after it pays")
	check(not main.job_panel._connection_panel.visible, "Ports never open Connect")
	print("TYCOON PORTS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
