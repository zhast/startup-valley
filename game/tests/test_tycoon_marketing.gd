extends SceneTree

## Headless marketing loop with the real worker and an isolated company.
## No ad is the default. A small ad spends game cash at the start and sells more units.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-marketing-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func check_marketing_secondary() -> void:
	for node_name: String in ["Marketing_none", "Marketing_small", "Marketing_big"]:
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
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	check_marketing_secondary()
	var none := button_id("Marketing_none")
	var small := button_id("Marketing_small")
	var big := button_id("Marketing_big")
	check(none != null and not none.disabled and none.text == "None", "None is the default ad")
	check(small != null and small.disabled and small.text == "Small ad · Need $50", "Small ad is disabled with Need $50")
	check(big != null and big.disabled and big.text == "Big ad · Need $150", "Big ad is disabled with Need $150")
	var effect := label_named("MarketingEffect")
	check(effect != null and effect.text == "None · $0 · no extra units", "No ad shows $0 and no extra units")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(str(developing().get("marketing", "")) == "none", "A starter product stores no ad")
	check(company_cash() == 0, "No ad spends nothing")
	check(label_named("MarketingLine") == null, "The bench hides the line when there is no ad")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "No ad still pays 20700 cents")
	check(company_reputation() == 5, "No ad still pays 5 fans")
	check(str(latest_shipped().get("marketing", "")) == "none", "The shipped newsletter keeps no ad")
	check(label_named("ReleaseMarketing") == null, "Release hides the line when there is no ad")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check_marketing_secondary()
	small = button_id("Marketing_small")
	big = button_id("Marketing_big")
	check(small != null and not small.disabled and small.text == "Small ad", "Small ad is affordable after the newsletter")
	check(big != null and not big.disabled and big.text == "Big ad", "Big ad is affordable after the newsletter")
	await click(big)
	await frames(4)
	check_marketing_secondary()
	effect = label_named("MarketingEffect")
	check(effect != null and effect.text == "Big ad · $150 · +50% units", "Big ad shows $150 and +50% units")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and str(developing().get("marketing", "")) == "big" and not main.company_panel.busy, "The second product stores the big ad")
	check(company_cash() == 5700, "Big ad charges $150 when development starts")
	check(label_named("MarketingLine") != null and label_named("MarketingLine").text == "Big ad · $150 · +50% units", "The bench shows the big ad")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and str(latest_shipped().get("marketing", "")) == "big", "Release opens the advertised product")
	var shipped := latest_shipped()
	check(int(shipped.get("salesCents", 0)) == 26100, "The big ad launch pays 26100 cents")
	check(int(shipped.get("fans", 0)) == 6, "Fans follow the extra units")
	check(label_named("ReleaseMarketing") != null and label_named("ReleaseMarketing").text == "Big ad · $150 · +50% units", "Release shows Big ad · $150 · +50% units")
	check(not main.job_panel._connection_panel.visible, "Marketing never opens Connect")
	print("TYCOON MARKETING ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
