extends SceneTree

## Headless publisher deal with the real worker and an isolated company.
## Skipping the deal leaves the first newsletter alone. Signing pays once.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-publishers-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func company_cash() -> int:
	if main == null or main.company_panel == null:
		return 0
	var company: Dictionary = main.company_panel.state.get("company", {}) if main.company_panel.state.get("company") is Dictionary else {}
	return int(company.get("cashCents", 0))

func company_reputation() -> int:
	if main == null or main.company_panel == null:
		return 0
	var company: Dictionary = main.company_panel.state.get("company", {}) if main.company_panel.state.get("company") is Dictionary else {}
	return int(company.get("reputation", 0))

func tycoon_state() -> Dictionary:
	if main == null or main.company_panel == null:
		return {}
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

func start_newsletter() -> void:
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")

func boot() -> bool:
	main = MAIN.instantiate()
	main.demo_story_mode = false
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads the company")
	if ready:
		main.day_clock.set_speed(0)
	return ready

func release_company() -> void:
	if main == null:
		return
	var leaving: Node = main
	main = null
	leaving.queue_free()
	var closed := false
	for _index: int in range(40):
		await frames(1)
		if not is_instance_valid(leaving):
			closed = true
			break
	check(closed, "The previous company closed")
	await frames(4)

func dismiss_onboarding() -> void:
	var quiet := 0
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline and quiet < 4:
		await frames(1)
		if main.job_panel._connection_panel.visible or main.job_panel.drawer_is_open():
			main.job_panel.close_drawer(false)
			quiet = 0
		else:
			quiet += 1

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	check(main.company_panel.find_child("PublisherCard", true, false) == null, "No publisher card before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	await open_journey()
	var offer := label_named("PublisherOffer")
	check(offer != null and offer.text == "Publisher · Creator Collective pays $150 now, takes 30% of sales", "The journey card names the publisher offer")
	var sign := button_named("Sign publisher")
	check(sign != null and not sign.disabled and str(sign.get_meta("cozy_variant", "")) == "secondary", "Sign publisher is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the offer")
	check(company_cash() == 0, "Skipping the deal leaves cash at $0")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("PublisherOffer") != null and button_named("Sign publisher") != null, "The offer stays while the product is in development")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the deal still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the deal still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the deal keeps launch sales at 20700 cents")
		check(latest_shipped().get("publisher") == null, "An unsigned release has no publisher")
		await open_journey()
		check(main.company_panel.find_child("PublisherCard", true, false) == null, "The offer is gone after release")
		check(button_named("Sign publisher") == null, "A released product cannot be signed")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Unsigned sales stay on the old total")
	var signed_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-publishers-signed-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(signed_dir)
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", signed_dir)
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "The signed company opens Journey")
	await start_newsletter()
	await open_journey()
	sign = button_named("Sign publisher")
	check(sign != null and str(sign.get_meta("cozy_variant", "")) == "secondary", "Sign publisher stays secondary")
	await click(sign)
	await wait_until(func() -> bool: return company_cash() == 15000 and not main.company_panel.busy, "Signing pays $150 once")
	check(label_named("PublisherOffer") != null and label_named("PublisherOffer").text == "Published by Creator Collective · 30% cut", "The card names the signed deal")
	check(button_named("Sign publisher") == null, "The sign button hides after the deal")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the deal")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$150.00"), "The header shows the advance")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", signed_dir)
	if not await boot():
		_finish()
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	check(company_cash() == 15000, "Reopening does not pay the advance again")
	check(label_named("PublisherOffer") != null and label_named("PublisherOffer").text == "Published by Creator Collective · 30% cut", "The signed line is still on the card")
	check(button_named("Sign publisher") == null, "Reopening does not offer the button again")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	var cut_release := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 29490, "The signed launch keeps 70% plus the advance")
	if cut_release:
		check(company_reputation() == 5, "The cut leaves the 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 14490, "Posted sales are the net 14490 cents")
		var deal: Variant = latest_shipped().get("publisher")
		check(deal is Dictionary and bool((deal as Dictionary).get("signed", false)), "The shipped product keeps the signed deal")
		await open_journey()
		check(main.company_panel.find_child("PublisherCard", true, false) == null, "A signed product cannot be signed again after release")
		await end_office_day()
		check(company_cash() == 29490, "The signed release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 38310, "The next signed sales day posts the cut")
		check(int(latest_shipped().get("salesCents", 0)) == 23310, "Both sales days are posted net")
	print("TYCOON PUBLISHERS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
