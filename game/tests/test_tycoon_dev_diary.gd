extends SceneTree

## Headless dev diary with the real worker and an isolated company.
## Skipping the writeup leaves the first newsletter alone. Writing it charges once.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Diary · Whop Post-Mortem · $15, about 1 fan"
const WRITTEN := "Diary written · Whop Post-Mortem"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-diary-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func product_by_id(product_id: String) -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
	if value is Dictionary and str((value as Dictionary).get("id", "")) == product_id:
		return value as Dictionary
	for item: Variant in tycoon_state().get("history", []) as Array:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == product_id:
			return item as Dictionary
	return {}

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

func diary_ids(root: String) -> PackedStringArray:
	var script_path := root.path_join("read-diary.mjs")
	var script := "import { DatabaseSync } from 'node:sqlite';\nconst db = new DatabaseSync(process.argv[2], { timeout: 3000 });\nconst rows = db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:diary:%' ORDER BY id\").all();\nprocess.stdout.write(rows.map((row) => String(row.id)).join('\\n'));\ndb.close();\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the diary reader")
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
				if trimmed.begins_with("tycoon:diary:"):
					ids.append(trimmed)
			return ids
		OS.delay_msec(150)
	check(false, "Could not read diary rows")
	return PackedStringArray()

func seed_company(root: String, body: String, message: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := root.path_join("seed-diary.mjs")
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the diary seed script")
		return false
	file.store_string(body % JSON.stringify(database))
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, message % " ".join(output))
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
	check(label_named("DiaryOffer_p1") == null, "No diary before a product is shipped")
	check(button_named("Write diary") == null, "No diary button before a product is shipped")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	await open_journey()
	check(label_named("DiaryOffer_p1") == null, "A product on the bench has no diary offer")
	check(button_named("Write diary") == null, "A product on the bench has no diary button")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the diary still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the diary still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the diary keeps launch sales at 20700 cents")
		await open_journey()
		check(label_named("DiaryOffer_p1") == null, "A selling product has no diary offer")
		check(button_named("Write diary") == null, "A selling product has no diary button")
		check(main.company_panel.find_child("Selling_p1", true, false) != null, "Company Journey shows the selling-product card")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Diary-free sales stay on the old total")
		check(label_named("DiaryOffer_p1") == null, "The diary stays off while the product is selling")
		await end_office_day()
		await open_journey()
		await end_office_day()
		await open_journey()
		check(str(latest_shipped().get("status", "")) == "complete", "Sales finish after four days")
		var finished := main.company_panel.find_child("Finished_p1", true, false) as Control
		var offer := label_named("DiaryOffer_p1")
		check(finished != null and offer != null and finished.is_ancestor_of(offer) and offer.text == OFFER, "The Shipped card names the diary offer")
		var write := button_named("Write diary")
		check(write != null and not write.disabled and str(write.get_meta("cozy_variant", "")) == "secondary", "Write diary is a secondary action")
		var shelf := main.company_panel.find_child("ShelfActions_p1", true, false)
		check(write != null and shelf != null and not shelf.is_ancestor_of(write), "Write diary sits off the four-button shelf row")
		check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the offer")
		check(button_named("Sequel") != null and str(button_named("Sequel").get_meta("cozy_variant", "")) == "secondary", "Sequel stays on the shelf row")
	await release_company()
	var skipped := diary_ids(data_dir)
	check(skipped.is_empty(), "Skipping the diary writes no diary rows")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 46800, "Reopening before the diary keeps 46800 cents")
	check(company_reputation() == 11, "Reopening before the diary keeps 11 fans")
	check(int(latest_shipped().get("salesCents", 0)) == 46800, "Reopening before the diary keeps the sale")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == OFFER, "Reopening a finished product still offers the diary")
	var fans_before := company_reputation()
	var write_live := button_named("Write diary")
	await click(write_live)
	await wait_until(func() -> bool: return company_cash() == 45300 and company_reputation() == fans_before + 1 and not main.company_panel.busy, "The diary charges $15 once and grants 1 fan once")
	check(int(latest_shipped().get("salesCents", 0)) == 46800, "The diary does not change the sale")
	check(int(latest_shipped().get("fans", 0)) == 11, "The product fan count is separate from the company total")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "The Shipped card names the written diary")
	check(button_named("Write diary") == null, "A written diary hides the button")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the diary")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$453.00") and header.text.contains("%d reputation" % (fans_before + 1)), "The header shows the cash and fans after the diary")
	var fans_after := company_reputation()
	await release_company()
	var charged := diary_ids(data_dir)
	check(charged.size() == 1 and charged[0] == "tycoon:diary:p1:fee", "The diary writes one fee row")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 45300 and company_reputation() == fans_after, "Reopening does not charge or grant the diary again")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "Reopening still shows the written line")
	check(button_named("Write diary") == null, "Reopening does not offer a second diary")
	await release_company()
	var next_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-diary-next-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(next_dir)
	var next_body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\ndb.tycoon.writeDiary('p1');\nconst day = db.clockState().day;\ndb.tycoon.start('fitness', 'newsletter', []);\ndb.endDay(day);\ndb.endDay(day + 1);\ndb.tycoon.release('p2');\nconst releasedDay = db.clockState().day;\ndb.endDay(releasedDay);\ndb.endDay(releasedDay + 1);\ndb.endDay(releasedDay + 2);\ndb.endDay(releasedDay + 3);\nconst p1 = db.tycoon.view().history.find((row) => row.id === 'p1');\nconst p2 = db.tycoon.view().history.find((row) => row.id === 'p2');\nconst company = db.journey.state().company;\ndb.close();\nconst ok = p1 && p1.diary && p1.diary.written === true && p2 && p2.status === 'complete' && p2.diary && p2.diary.written === false && company.cashCents > 1500;\nif (!ok) { console.error(JSON.stringify({ company: company, p1: p1, p2: p2 })); process.exit(2); }\n"
	if not seed_company(next_dir, next_body, "Seeded a second finished newsletter (%s)"):
		_finish()
		return
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", next_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	var next_offer := label_named("DiaryOffer_p2")
	var next_finished := main.company_panel.find_child("Finished_p2", true, false) as Control
	check(next_finished != null and next_offer != null and next_finished.is_ancestor_of(next_offer) and next_offer.text == OFFER, "The next product offers the diary again")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "The first product keeps the written line")
	var next_write := button_named("Write diary")
	check(next_write != null and str(next_write.get_meta("cozy_variant", "")) == "secondary", "Write diary stays secondary on the next product")
	var next_cash := company_cash()
	var next_fans := company_reputation()
	await click(next_write)
	await wait_until(func() -> bool: return company_cash() == next_cash - 1500 and company_reputation() == next_fans + 1 and not main.company_panel.busy, "The next diary charges once and grants fans once")
	check(label_named("DiaryOffer_p2") != null and label_named("DiaryOffer_p2").text == WRITTEN, "The next Shipped card names the written diary")
	check(button_named("Write diary") == null, "The next diary hides the button")
	await release_company()
	var both := diary_ids(next_dir)
	check(both.size() == 2 and both[0] == "tycoon:diary:p1:fee" and both[1] == "tycoon:diary:p2:fee", "Each product writes its own fee row")
	var short_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-diary-short-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(short_dir)
	var short_body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\nconst finished = db.journey.state().company.cashCents;\ndb.journey.recordCompanyChange('seed:diary-short', db.clockState().day, 1499 - finished, 0, 0, 'Drain');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst ok = company.cashCents === 1499 && company.reputation === 11 && product && product.diary && product.diary.written === false && product.salesCents === 46800;\nif (!ok) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n"
	if not seed_company(short_dir, short_body, "Seeded a finished newsletter with $14.99 (%s)"):
		_finish()
		return
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", short_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 1499 and company_reputation() == 11, "The short-cash company has $14.99 and 11 fans")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == OFFER, "Short cash still shows the offer")
	await click(button_named("Write diary"))
	await wait_until(func() -> bool: return notice_text().contains("Need $15") and company_cash() == 1499 and company_reputation() == 11 and not main.company_panel.busy, "Short cash says Need $15 and writes nothing")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == OFFER, "A failed diary keeps the offer")
	check(button_named("Write diary") != null and str(button_named("Write diary").get_meta("cozy_variant", "")) == "secondary", "Write diary stays after a failed write")
	await release_company()
	check(diary_ids(short_dir).is_empty(), "Short cash writes no diary row")
	var written_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-diary-written-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(written_dir)
	var written_body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\ndb.tycoon.writeDiary('p1');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst ok = company.cashCents === 45300 && company.reputation === 12 && product && product.diary && product.diary.written === true && product.salesCents === 46800 && product.fans === 11;\nif (!ok) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n"
	if not seed_company(written_dir, written_body, "Seeded a written diary (%s)"):
		_finish()
		return
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", written_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 45300 and company_reputation() == 12, "A seeded diary already has the fee and 1 fan")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "A seeded diary shows the written line")
	check(button_named("Write diary") == null, "A seeded diary has no button")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$453.00") and header.text.contains("12 reputation"), "Spring morning shows the diary fee and fans")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the diary day opens the summary")
	check(label_contains("Diary: Whop Post-Mortem"), "The summary names the diary")
	check(company_reputation() == 12 and company_cash() == 45300, "Ending the day does not charge or grant again")
	await frames(8)
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "The next morning still shows the written line")
	check(button_named("Write diary") == null, "The next morning does not offer another diary")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$453.00") and header.text.contains("12 reputation"), "The next morning is still Spring with the same cash and fans")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", written_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 45300 and company_reputation() == 12, "Reopening the next morning does not charge or grant again")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == WRITTEN, "Reopening the next morning still shows the written line")
	check(diary_ids(written_dir).size() == 1, "Replaying the diary day keeps one fee row")
	print("TYCOON DEV DIARY ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
