extends SceneTree

## Headless contract loop with the real worker and an isolated company.
## No contract is the default. Accepting one locks the next product and pays a bonus on release.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-contracts-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func button_choice(title: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree():
			continue
		if button.text == title or button.text.begins_with(title + " ·"):
			return button
	return null

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

func contract_state() -> Dictionary:
	var value: Variant = tycoon_state().get("contract", {})
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
	var offer := contract_state()
	var accept := button_named("Accept contract")
	check(main.company_panel.find_child("ContractCard", true, false) != null, "Company Journey shows one contract card")
	check(label_named("ContractClient") != null and label_named("ContractClient").text == str(offer.get("client", "")), "The card names the client")
	check(label_named("ContractPair") != null and label_named("ContractPair").text == "%s × %s" % [str(offer.get("topicName", "")), str(offer.get("typeName", ""))], "The card names topic × type")
	check(label_named("ContractBonus") != null and label_named("ContractBonus").text == "Bonus $%d on release" % int(int(offer.get("bonusCents", 0)) / 100), "The card names the bonus")
	check(accept != null and not accept.disabled and str(accept.get_meta("cozy_variant", "")) == "secondary", "Accept contract is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await open_product()
	var fitness := button_choice("Fitness")
	var crypto := button_choice("Crypto Alpha")
	check(fitness != null and not fitness.disabled and not fitness.text.contains("contract"), "Ignoring the offer leaves Fitness free")
	check(crypto != null and not crypto.disabled and not crypto.text.contains("contract"), "Ignoring the offer leaves Crypto Alpha free")
	await click(crypto)
	await frames(4)
	await click(button_choice("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(developing().get("contract") == null, "A free product stores no contract")
	await open_journey()
	accept = button_named("Accept contract")
	check(accept != null and accept.disabled and str(accept.get_meta("cozy_variant", "")) == "secondary", "Accept stays secondary and disabled while a product is on the bench")
	check(label_named("ContractReason") != null and label_named("ContractReason").text == "Ship the product on the bench first.", "The card says to ship the product on the bench first")
	await open_product()
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "No contract still pays 20700 cents")
	check(company_reputation() == 5, "No contract still pays 5 fans")
	check(latest_shipped().get("contract") == null, "The shipped newsletter has no contract")
	check(label_named("ReleaseContract") == null, "Release hides the contract line when there is no contract")
	await open_journey()
	check(str(contract_state().get("id", "")) == str(offer.get("id", "")), "Ignoring the offer keeps the same client")
	accept = button_named("Accept contract")
	check(accept != null and not accept.disabled, "Accept is open again after the launch")
	await click(accept)
	await wait_until(func() -> bool: return str(contract_state().get("status", "")) == "accepted" and not main.company_panel.busy, "Accept locks the contract")
	check(button_named("Accept contract") == null, "Accept hides once the contract is taken")
	check(label_named("ContractReason") != null and label_named("ContractReason").text == "Accepted. The next product uses this pair.", "The card says the next product uses this pair")
	await open_product()
	var topic_name := str(offer.get("topicName", ""))
	var type_name := str(offer.get("typeName", ""))
	var topic_button := button_choice(topic_name)
	var type_button := button_choice(type_name)
	check(topic_button != null and not topic_button.disabled, "The contract topic stays enabled")
	check(type_button != null and not type_button.disabled, "The contract type stays enabled")
	check(label_named("ContractLock") != null and label_named("ContractLock").text.contains(str(offer.get("client", ""))), "The picker names the contract")
	var other_locked := false
	for item: Variant in tycoon_state().get("topics", []) as Array:
		if not item is Dictionary: continue
		var topic := item as Dictionary
		if str(topic.get("id", "")) == str(offer.get("topicId", "")): continue
		if not bool(topic.get("unlocked", false)): continue
		var other := button_choice(str(topic.get("name", "")))
		if other != null and other.disabled and other.text.contains("· contract"):
			other_locked = true
	check(other_locked, "Another topic is disabled with · contract")
	var other_type := false
	for item: Variant in tycoon_state().get("types", []) as Array:
		if not item is Dictionary: continue
		var kind := item as Dictionary
		if str(kind.get("id", "")) == str(offer.get("typeId", "")): continue
		if not bool(kind.get("unlocked", false)): continue
		var other_kind := button_choice(str(kind.get("name", "")))
		if other_kind != null and other_kind.disabled and other_kind.text.contains("· contract"):
			other_type = true
	check(other_type, "Another product type is disabled with · contract")
	await click(topic_button)
	await frames(4)
	type_button = button_choice(type_name)
	check(type_button != null and not type_button.disabled, "The contract type is still enabled after the topic click")
	await click(type_button)
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return str(developing().get("topicId", "")) == str(offer.get("topicId", "")) and not main.company_panel.busy, "The contracted product starts")
	var deal: Dictionary = developing().get("contract", {}) if developing().get("contract") is Dictionary else {}
	check(str(deal.get("client", "")) == str(offer.get("client", "")) and int(deal.get("bonusCents", 0)) == int(offer.get("bonusCents", 0)), "The bench stores the client and the bonus")
	var guard := 0
	while not bool(developing().get("ready", false)) and guard < 6:
		await end_office_day()
		await open_product()
		guard += 1
	check(bool(developing().get("ready", false)), "The contract product is ready to release")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and label_named("ReleaseContract") != null, "Release shows the contract bonus")
	var shipped := latest_shipped()
	var shipped_deal: Dictionary = shipped.get("contract", {}) if shipped.get("contract") is Dictionary else {}
	var bonus := int(shipped_deal.get("bonusCents", 0))
	var sales := int(shipped.get("salesCents", 0))
	var fans := int(shipped.get("fans", 0))
	check(label_named("ReleaseContract").text == "Contract: %s · +$%d" % [str(offer.get("client", "")), int(bonus / 100)], "Release names the contract bonus")
	check(sales > 0 and company_cash() == cash_before + sales + bonus, "The bonus is paid once, on top of launch sales")
	check(company_reputation() == fans_before + fans, "The bonus does not add fans")
	check(not main.job_panel._connection_panel.visible, "Contracts never open Connect")
	print("TYCOON CONTRACTS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
