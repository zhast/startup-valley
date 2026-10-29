extends SceneTree

## Headless expo booth with the real worker and an isolated company.
## Skipping the booth leaves the first newsletter alone. Booking charges once.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Expo · Whop Creator Fair on Spring 14 · $60 booth, about 3 fans"
const BOOKED := "Booth booked · Whop Creator Fair on Spring 14"
const NEXT_OFFER := "Expo · Whop Creator Fair on Summer 14 · $60 booth, about 3 fans"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-expos-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func notice_text() -> String:
	if main == null or main.company_panel == null or main.company_panel._notice == null:
		return ""
	return main.company_panel._notice.text

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

func continue_company() -> void:
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()

func seed_fair(fair_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := fair_dir.path_join("seed-expo.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('seed:expo-cash', 1, 6000, 0, 0, 'Seed cash');\ndb.tycoon.bookBooth();\ndb.setClock(14, 480, 0);\nconst expo = db.tycoon.view().expo;\nconst company = db.journey.state().company;\ndb.close();\nif (company.cashCents !== 0 || company.reputation !== 0 || expo.booked !== true || expo.when !== 'Spring 14') { console.error(JSON.stringify({ company: company, expo: expo })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the expo seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, fair_dir]), output, true)
	check(code == 0, "Seeded fair-day booth (%s)" % " ".join(output))
	return code == 0

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
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == OFFER, "The Season card names the expo offer")
	var book := button_named("Book booth")
	check(book != null and not book.disabled and str(book.get_meta("cozy_variant", "")) == "secondary", "Book booth is a secondary action")
	check(company_cash() == 0, "A new company has no cash for a booth")
	await click(book)
	await wait_until(func() -> bool: return notice_text().contains("Need $60") and company_cash() == 0 and not main.company_panel.busy, "Short cash says Need $60 and writes nothing")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == OFFER, "A failed booking keeps the offer")
	check(button_named("Book booth") != null and str(button_named("Book booth").get_meta("cozy_variant", "")) == "secondary", "Book booth stays after a failed booking")
	await start_newsletter()
	await open_journey()
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == OFFER, "Skipping the booth keeps the Spring 14 offer")
	await open_product()
	await click(button_named("Release"))
	var fans_after_booking := 0
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the booth still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the booth still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the booth keeps launch sales at 20700 cents")
		await open_journey()
		check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == OFFER, "The offer is still open after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Unsigned sales stay on the old total")
		check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == OFFER, "Day 5 still offers the Spring 14 booth")
		book = button_named("Book booth")
		check(book != null and str(book.get_meta("cozy_variant", "")) == "secondary", "Book booth stays secondary after the sale")
		await click(book)
		await wait_until(func() -> bool: return company_cash() == 27300 and not main.company_panel.busy, "Booking charges $60 once")
		check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == BOOKED, "The Season card names the booked booth")
		check(button_named("Book booth") == null, "A booked fair hides the button")
		check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the booking")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("$273.00"), "The header shows the cash after the fee")
		fans_after_booking = company_reputation()
		check(fans_after_booking > 5, "The next sales day still adds fans and the booth does not")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 27300, "Reopening does not charge the booth again")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == BOOKED, "Reopening still shows the booked booth")
	check(button_named("Book booth") == null, "Reopening does not offer a second booth")
	check(company_reputation() == fans_after_booking, "Reopening does not pay the fair early")
	var fair_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-expos-fair-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(fair_dir)
	if not seed_fair(fair_dir):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", fair_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 0 and company_reputation() == 0, "Spring 14 morning still has the fee and no fans")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == BOOKED, "Spring 14 morning still shows the booked booth")
	check(button_named("Book booth") == null, "Spring 14 morning does not offer another booth")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 14") and header.text.contains("$0.00"), "Spring 14 morning shows the fair and $0")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending Spring 14 opens the summary")
	check(label_contains("Expo: Whop Creator Fair"), "The summary names the fair")
	check(company_reputation() == 3 and company_cash() == 0, "The fair pays 3 fans and no cash")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == NEXT_OFFER, "The next fair is the Summer 14 offer")
	book = button_named("Book booth")
	check(book != null and str(book.get_meta("cozy_variant", "")) == "secondary", "Book booth returns for the next fair")
	check(company_reputation() == 3 and company_cash() == 0, "Summer 1 keeps the 3 fans and $0")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", fair_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_reputation() == 3 and company_cash() == 0, "Reopening does not pay the fair again")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == NEXT_OFFER, "Reopening still offers the next fair")
	check(button_named("Book booth") != null, "Reopening still offers one booth for the next fair")
	print("TYCOON EXPOS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
