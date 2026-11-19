extends SceneTree

## Headless research loop with the real worker and an isolated company.
## Ship a newsletter, spend the points on a locked topic, then start that topic.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-research-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func research_points() -> int:
	return int(tycoon_state().get("researchPoints", -1))

func developing() -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
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

func end_office_day() -> void:
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the day opens the summary")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)

func locked_choice(prefix: String) -> void:
	var button := button_named(prefix)
	check(button != null and button.disabled and button.text.contains("· locked"), prefix + " is listed and locked")

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
	check(research_points() == 0, "A new company starts with 0 research points")
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	for locked_name: String in ["Sneakers", "Reselling", "Sports Betting Picks", "Dating Advice", "Coaching", "Software Tool"]:
		locked_choice(locked_name)
	var crypto := button_named("Crypto Alpha")
	var newsletter := button_named("Newsletter")
	check(crypto != null and not crypto.disabled and not crypto.text.contains("locked"), "Crypto Alpha stays a starter topic")
	check(newsletter != null and not newsletter.disabled and not newsletter.text.contains("locked"), "Newsletter stays a starter type")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	check(label_named("ResearchFitBonus") == null and not label_contains("Research bonus"), "A starter combo shows no research bonus")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	check(int(developing().get("researchBonus", -1)) == 0, "A starter product stores no research bonus")
	check(label_named("ResearchFitJourney") == null and not label_contains("Research bonus"), "A starter product card shows no research bonus")
	await open_journey()
	check(label_named("ResearchFitJourney") == null and not label_contains("Research bonus"), "Company Journey shows no research bonus for a starter product")
	await end_office_day()
	check(research_points() == 1, "One person on the build earns 1 research point")
	await open_product()
	await end_office_day()
	check(research_points() == 2, "The second build day earns another research point")
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and label_contains("+3 research points"), "Release shows +3 research points")
	check(label_named("ReleaseResearch") != null, "Release research line is named")
	check(research_points() == 5, "Release adds floor(score / 2) onto the build points")
	var history: Array = tycoon_state().get("history", []) as Array
	var shipped: Dictionary = history[0] as Dictionary if not history.is_empty() and history[0] is Dictionary else {}
	var review: Dictionary = shipped.get("review", {}) if shipped.get("review") is Dictionary else {}
	check(int(review.get("score", 0)) == 6, "The newsletter review score is 6")
	await open_journey()
	check(label_contains("5 research points"), "Company Journey shows the research balance")
	var research := button_named("Research Sneakers")
	check(research != null and not research.disabled and str(research.get_meta("cozy_variant", "")) == "secondary", "Research Sneakers is an enabled secondary action")
	await click(research)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Unlocked Sneakers. −4 RP"), "Research notice names the unlocked topic")
	check(research_points() == 1, "Sneakers costs 4 research points")
	check(label_named("ResearchNotice") != null, "Research notice is on screen the day of the unlock")
	await open_product()
	var sneakers := button_named("Sneakers")
	check(sneakers != null and not sneakers.disabled and not sneakers.text.contains("locked"), "Unlocked Sneakers is selectable")
	await click(button_named("Sneakers"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var picker_bonus := label_named("ResearchFitBonus")
	check(picker_bonus != null and picker_bonus.text == "Research bonus: +6 fit", "The picker shows Research bonus: +6 fit")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Sneakers Newsletter" and not main.company_panel.busy, "Development starts on the researched topic")
	check(int(developing().get("researchBonus", -1)) == 6, "The product stores a +6 research bonus")
	var card_bonus := label_named("ResearchFitJourney")
	check(card_bonus != null and card_bonus.text == "Research bonus +6 fit", "The product card shows Research bonus +6 fit")
	await open_journey()
	var journey_bonus := label_named("ResearchFitJourney")
	check(journey_bonus != null and journey_bonus.text == "Sneakers Newsletter · Research bonus +6 fit", "Company Journey names the product on the research line")
	check(not main.job_panel._connection_panel.visible, "Research never opens Connect")
	print("TYCOON RESEARCH ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
