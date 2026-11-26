extends SceneTree

## Headless size loop with the real worker and an isolated company.
## Catalog is the default. Short and Long change the build length and the units.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-size-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func size_of(product: Dictionary) -> Dictionary:
	var value: Variant = product.get("size", null)
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
	var catalog := button_id("Size_catalog")
	var short_size := button_id("Size_short")
	var long_size := button_id("Size_long")
	check(catalog != null and not catalog.disabled and str(catalog.get_meta("cozy_variant", "")) == "secondary" and catalog.text == "Catalog", "Catalog is the default size")
	check(short_size != null and not short_size.disabled and str(short_size.get_meta("cozy_variant", "")) == "secondary" and short_size.text == "Short", "Short is a secondary size")
	check(long_size != null and long_size.text == "Long", "Long sits on the same row")
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Catalog · same length", "Catalog shows the same length")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build", "The build line starts plain")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(developing().get("size") == null, "A Catalog product stores no size")
	check(int(developing().get("devDaysRequired", 0)) == 2, "A Catalog newsletter still takes 2 office days")
	check(company_cash() == 0, "Starting Catalog spends nothing")
	check(label_named("SizeLine") == null, "The bench hides the line when the size is Catalog")
	check(label_named("ProductProgress") != null and label_named("ProductProgress").text == "Building · day 0 of 2", "Catalog progress uses 2 days")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Catalog still pays 20700 cents")
	check(company_reputation() == 5, "Catalog still pays 5 fans")
	check(latest_shipped().get("size") == null, "The shipped newsletter keeps no size")
	check(label_named("ReleaseSize") == null, "Release hides the line when the size is Catalog")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	long_size = button_id("Size_long")
	short_size = button_id("Size_short")
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Catalog · same length", "The next picker starts on Catalog")
	await click(long_size)
	await frames(4)
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Long · +1 day · +10% units", "Long shows +1 day and +10% units")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Long", "The build line names Long")
	short_size = button_id("Size_short")
	await click(short_size)
	await frames(4)
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Short · −1 day · −10% units", "Short shows −1 day and −10% units")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Short", "The build line names the size")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays primary beside the size")
	var cash_before_start := company_cash()
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and str(size_of(developing()).get("id", "")) == "short" and not main.company_panel.busy, "The second product starts Short")
	var stored := size_of(developing())
	check(str(stored.get("label", "")) == "Short" and int(stored.get("dayDelta", 0)) == -1 and int(stored.get("unitPercent", 0)) == 90, "The product stores Short, −1 day, and 90% units")
	check(int(developing().get("devDaysRequired", 0)) == 1, "A Short newsletter takes 1 office day")
	check(company_cash() == cash_before_start, "Choosing a size spends nothing")
	check(label_named("SizeLine") != null and label_named("SizeLine").text == "On the build · Short", "The bench names the size")
	check(label_named("ProductProgress") != null and label_named("ProductProgress").text == "Building · day 0 of 1", "Short progress uses 1 day")
	await open_journey()
	check(label_named("SizeJourney") != null and label_named("SizeJourney").text == "On the build · Short", "Journey names the size on the build")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the size")
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "One office day makes the Short newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and size_of(latest_shipped()).get("id", "") == "short", "Release opens the product that used Short")
	var shipped := latest_shipped()
	check(int(size_of(shipped).get("unitPercent", 0)) == 90, "The shipped product keeps the unit cut")
	check(int(shipped.get("salesCents", 0)) > 0 and int(shipped.get("fans", 0)) >= 1, "The Short product still pays cash and fans")
	check(int(shipped.get("salesCents", 0)) != 20700, "The later Short launch is not the catalog launch")
	check(label_named("ReleaseSize") != null and label_named("ReleaseSize").text == "On the build · Short", "Release names the size")
	check(not main.job_panel._connection_panel.visible, "Size never opens Connect")
	print("TYCOON SIZE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
