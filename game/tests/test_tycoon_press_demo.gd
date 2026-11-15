extends SceneTree

## Headless press demo with the real worker and an isolated company.
## Skipping the preview leaves the first newsletter alone. Showing it charges once.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Press demo · TownSquare Weekly Preview · $30, about 4 fans"
const SHOWN := "Preview shown · TownSquare Weekly Preview"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-press-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func node_bin() -> String:
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	return node

func press_ids(root: String) -> PackedStringArray:
	var script_path := root.path_join("read-press.mjs")
	var script := "import { DatabaseSync } from 'node:sqlite';\nconst db = new DatabaseSync(process.argv[2], { timeout: 3000 });\nconst rows = db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pressdemo:%' ORDER BY id\").all();\nprocess.stdout.write(rows.map((row) => String(row.id)).join('\\n'));\ndb.close();\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the press demo reader")
		return PackedStringArray()
	file.store_string(script)
	file.close()
	for _try: int in range(8):
		var output: Array = []
		var code := OS.execute(node_bin(), PackedStringArray(["--no-warnings", script_path, root.path_join("startup-valley.sqlite")]), output, true)
		if code == 0:
			var ids := PackedStringArray()
			for line: String in "\n".join(output).split("\n"):
				var trimmed := line.strip_edges()
				if trimmed.begins_with("tycoon:pressdemo:"):
					ids.append(trimmed)
			return ids
		OS.delay_msec(150)
	check(false, "Could not read press demo rows")
	return PackedStringArray()

func seed_press(root: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := root.path_join("seed-press.mjs")
	var body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.journey.recordCompanyChange('seed:press-cash', 1, 3000, 0, 0, 'Seed cash');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.tycoon.showPressDemo();\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst ok = company.cashCents === 0 && company.reputation === 4 && view && view.pressDemo && view.pressDemo.shown === true && view.pressDemo.fans === 4 && view.pressDemo.costCents === 3000;\nif (!ok) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the press demo seed script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Seeded a shown press demo (%s)" % " ".join(output))
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
	check(label_named("PressDemoOffer") == null, "No press demo before a product is on the bench")
	check(button_named("Show preview") == null, "No preview button before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	await open_journey()
	var offer := label_named("PressDemoOffer")
	check(offer != null and offer.text == OFFER, "The journey card names the press demo offer")
	var show := button_named("Show preview")
	check(show != null and not show.disabled and str(show.get_meta("cozy_variant", "")) == "secondary", "Show preview is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the offer")
	check(button_named("Sign publisher") != null and str(button_named("Sign publisher").get_meta("cozy_variant", "")) == "secondary", "Sign publisher stays secondary beside the preview")
	check(company_cash() == 0, "A new company has no cash for the preview")
	await click(show)
	await wait_until(func() -> bool: return notice_text().contains("Need $30") and company_cash() == 0 and not main.company_panel.busy, "Short cash says Need $30 and writes nothing")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == OFFER, "A failed preview keeps the offer")
	check(button_named("Show preview") != null and str(button_named("Show preview").get_meta("cozy_variant", "")) == "secondary", "Show preview stays after a failed preview")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("PressDemoOffer") != null and button_named("Show preview") != null, "The offer stays while the product is in development")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the preview still pays 20700 cents")
	var fans_before := 0
	if released:
		check(company_reputation() == 5, "Skipping the preview still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the preview keeps launch sales at 20700 cents")
		check(latest_shipped().get("pressDemo") == null, "An unshown release has no press demo")
		await open_journey()
		check(label_named("PressDemoOffer") == null, "The offer is gone after release")
		check(button_named("Show preview") == null, "A released product cannot be previewed")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Preview-free sales stay on the old total")
		fans_before = company_reputation()
	await release_company()
	var skipped := press_ids(data_dir)
	check(skipped.is_empty(), "Skipping the preview writes no press demo rows")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300, "Reopening before the preview keeps 33300 cents")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening before the preview keeps the sale")
	check(label_named("PressDemoOffer") == null, "Reopening a shipped product still has no offer")
	await start_newsletter()
	await open_journey()
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == OFFER, "The next product offers the press demo again")
	show = button_named("Show preview")
	check(show != null and str(show.get_meta("cozy_variant", "")) == "secondary", "Show preview stays secondary on the next product")
	fans_before = company_reputation()
	await click(show)
	await wait_until(func() -> bool: return company_cash() == 30300 and company_reputation() == fans_before + 4 and not main.company_panel.busy, "The preview charges $30 once and grants 4 fans once")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "The preview does not change the earlier sale")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == SHOWN, "The card names the shown preview")
	check(button_named("Show preview") == null, "A shown preview hides the button")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the preview")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$303.00") and header.text.contains("%d reputation" % (fans_before + 4)), "The header shows the cash and fans after the preview")
	var fans_after := company_reputation()
	await release_company()
	var charged := press_ids(data_dir)
	check(charged.size() == 1 and charged[0] == "tycoon:pressdemo:p2:fee", "The preview writes one fee row for the next product")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 30300 and company_reputation() == fans_after, "Reopening does not charge or grant the preview again")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == SHOWN, "Reopening still shows the taken line")
	check(button_named("Show preview") == null, "Reopening does not offer a second preview")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening keeps the sale")
	var shown_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-press-shown-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(shown_dir)
	if not seed_press(shown_dir):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", shown_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 0 and company_reputation() == 4, "A seeded preview already has the fee and 4 fans")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == SHOWN, "A seeded preview shows the taken line")
	check(button_named("Show preview") == null, "A seeded preview has no button")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$0.00") and header.text.contains("4 reputation"), "Spring morning shows the preview fee and fans")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the preview day opens the summary")
	check(label_contains("Press demo: TownSquare Weekly Preview"), "The summary names the press demo")
	check(company_reputation() == 4 and company_cash() == 0, "Ending the day does not charge or grant again")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == SHOWN, "The next morning still shows the taken line")
	check(button_named("Show preview") == null, "The next morning does not offer another preview")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$0.00") and header.text.contains("4 reputation"), "The next morning is still Spring with the same cash and fans")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", shown_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 0 and company_reputation() == 4, "Reopening the next morning does not charge or grant again")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == SHOWN, "Reopening the next morning still shows the taken line")
	check(press_ids(shown_dir).size() == 1, "Replaying the preview day keeps one fee row")
	print("TYCOON PRESS DEMO ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
