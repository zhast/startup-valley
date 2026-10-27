extends SceneTree

## Headless engine loop with the real worker and an isolated company.
## No engine is the default. Buying Whop Kit Engine once lets a later product store +1 score.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-engines-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func engine_of(product: Dictionary) -> Dictionary:
	var value: Variant = product.get("engine", null)
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
	var price := label_named("EnginePrice")
	var buy := button_id("Buy_engine")
	check(price != null and price.text == "Whop Kit Engine · $120", "The engine card names Whop Kit Engine and $120")
	check(buy != null and buy.disabled and str(buy.get_meta("cozy_variant", "")) == "secondary" and buy.text == "Buy Whop Kit Engine · Need $120", "Buy stays disabled with Need $120")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	check(button_id("Engine_none") == null and button_id("Engine_whop_kit") == null, "The engine choice waits until the kit is owned")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build", "The build line starts with no engine")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(developing().get("engine") == null, "A starter product stores no engine")
	check(company_cash() == 0, "Starting with no engine spends nothing")
	check(label_named("EngineLine") == null, "The bench hides the line when there is no engine")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "No engine still pays 20700 cents")
	check(company_reputation() == 5, "No engine still pays 5 fans")
	check(latest_shipped().get("engine") == null, "The shipped newsletter keeps no engine")
	check(label_named("ReleaseEngine") == null, "Release hides the line when there is no engine")
	await open_journey()
	buy = button_id("Buy_engine")
	check(buy != null and not buy.disabled and str(buy.get_meta("cozy_variant", "")) == "secondary" and buy.text == "Buy Whop Kit Engine · $120", "Buy Whop Kit Engine is an enabled secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the engine")
	await click(buy)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("EngineNotice") != null, "The purchase notice appears")
	check(label_named("EngineNotice").text == "Bought Whop Kit Engine. −$120", "The notice names the engine and $120")
	check(company_cash() == 8700, "The engine charges $120 once")
	var offer: Dictionary = tycoon_state().get("engine", {}) if tycoon_state().get("engine") is Dictionary else {}
	check(bool(offer.get("owned", false)) and not bool(offer.get("enabled", true)) and str(offer.get("reason", "")) == "Already owned.", "The payload says the engine is already owned")
	var again := button_id("Buy_engine")
	check(again != null and again.disabled and again.text == "Buy Whop Kit Engine · Already owned.", "A second buy stays disabled")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var none := button_id("Engine_none")
	var kit := button_id("Engine_whop_kit")
	check(none != null and not none.disabled and str(none.get_meta("cozy_variant", "")) == "secondary" and none.text == "None", "None is the default engine")
	check(kit != null and not kit.disabled and str(kit.get_meta("cozy_variant", "")) == "secondary" and kit.text == "Whop Kit Engine", "Whop Kit Engine is a secondary choice")
	check(label_named("EngineEffect") != null and label_named("EngineEffect").text == "None · no score bump", "None shows no score bump")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build", "The build line stays plain until an engine is chosen")
	await click(kit)
	await frames(4)
	check(label_named("EngineEffect") != null and label_named("EngineEffect").text == "Whop Kit Engine · +1 score", "The chosen engine shows +1 score")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Whop Kit Engine", "The build line names the engine")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays primary beside the engine choice")
	var cash_before_start := company_cash()
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "The second product starts on the engine")
	var stored := engine_of(developing())
	check(str(stored.get("id", "")) == "whop_kit" and str(stored.get("name", "")) == "Whop Kit Engine" and int(stored.get("scoreBonus", 0)) == 1, "The product stores Whop Kit Engine and +1 score")
	check(company_cash() == cash_before_start, "Starting on the engine does not charge again")
	check(label_named("EngineLine") != null and label_named("EngineLine").text == "On the build · Whop Kit Engine · +1 score", "The bench names the engine and the score bump")
	await open_journey()
	check(label_named("EngineJourney") != null and label_named("EngineJourney").text == "On the build · Whop Kit Engine · +1 score", "Journey names the engine on the build")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and engine_of(latest_shipped()).get("id", "") == "whop_kit", "Release opens the product that used the engine")
	var shipped := latest_shipped()
	var review: Dictionary = shipped.get("review", {}) if shipped.get("review") is Dictionary else {}
	check(int(engine_of(shipped).get("scoreBonus", 0)) == 1, "The shipped product keeps the score bump")
	check(int(review.get("score", 0)) >= 1 and int(review.get("score", 0)) <= 10, "The review score stays inside 1 to 10")
	check(int(shipped.get("salesCents", 0)) > 0 and int(shipped.get("fans", 0)) >= 1, "The engine product still pays cash and fans")
	check(label_named("ReleaseEngine") != null and label_named("ReleaseEngine").text == "On the build · Whop Kit Engine · +1 score", "Release names the engine and the score bump")
	check(not main.job_panel._connection_panel.visible, "Engines never open Connect")
	print("TYCOON ENGINES ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
