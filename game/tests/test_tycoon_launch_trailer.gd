extends SceneTree

## Headless launch trailer with the real worker and an isolated company.
## Skipping the cut leaves the first newsletter alone. Making it charges once.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Trailer · TownSquare Creator Cut · $25, about 6 fans"
const MADE := "Trailer made · TownSquare Creator Cut"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-trailer-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func trailer_ids(root: String) -> PackedStringArray:
	var script_path := root.path_join("read-trailer.mjs")
	var script := "import { DatabaseSync } from 'node:sqlite';\nconst db = new DatabaseSync(process.argv[2], { timeout: 3000 });\nconst rows = db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:trailer:%' ORDER BY id\").all();\nprocess.stdout.write(rows.map((row) => String(row.id)).join('\\n'));\ndb.close();\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the trailer reader")
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
				if trimmed.begins_with("tycoon:trailer:"):
					ids.append(trimmed)
			return ids
		OS.delay_msec(150)
	check(false, "Could not read trailer rows")
	return PackedStringArray()

func seed_company(root: String, body: String, message: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := root.path_join("seed-trailer.mjs")
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the trailer seed script")
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
	check(label_named("TrailerOffer_p1") == null, "No trailer before a product is selling")
	check(button_named("Make trailer") == null, "No trailer button before a product is selling")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	await open_journey()
	check(label_named("TrailerOffer_p1") == null, "A product on the bench has no trailer offer")
	check(button_named("Make trailer") == null, "A product on the bench has no trailer button")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the trailer still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the trailer still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the trailer keeps launch sales at 20700 cents")
		await open_journey()
		var selling := main.company_panel.find_child("Selling_p1", true, false) as Control
		var offer := label_named("TrailerOffer_p1")
		check(selling != null and offer != null and selling.is_ancestor_of(offer) and offer.text == OFFER, "The Selling card names the trailer offer")
		var make := button_named("Make trailer")
		check(make != null and not make.disabled and str(make.get_meta("cozy_variant", "")) == "secondary", "Make trailer is a secondary action")
		check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the offer")
		check(button_named("Patch") != null and str(button_named("Patch").get_meta("cozy_variant", "")) == "secondary", "Patch stays secondary beside the trailer")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Trailer-free sales stay on the old total")
		check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == OFFER, "The offer stays while the product is selling")
	await release_company()
	var skipped := trailer_ids(data_dir)
	check(skipped.is_empty(), "Skipping the trailer writes no trailer rows")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300, "Reopening before the trailer keeps 33300 cents")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening before the trailer keeps the sale")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == OFFER, "Reopening a selling product still offers the trailer")
	var fans_before := company_reputation()
	var make_live := button_named("Make trailer")
	await click(make_live)
	await wait_until(func() -> bool: return company_cash() == 30800 and company_reputation() == fans_before + 6 and not main.company_panel.busy, "The trailer charges $25 once and grants 6 fans once")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "The trailer does not change the sale")
	check(int(latest_shipped().get("fans", 0)) == int(product_by_id("p1").get("fans", 0)), "The product fan count is separate from the company total")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == MADE, "The Selling card names the made trailer")
	check(button_named("Make trailer") == null, "A made trailer hides the button")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the trailer")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$308.00") and header.text.contains("%d reputation" % (fans_before + 6)), "The header shows the cash and fans after the trailer")
	var fans_after := company_reputation()
	await release_company()
	var charged := trailer_ids(data_dir)
	check(charged.size() == 1 and charged[0] == "tycoon:trailer:p1:fee", "The trailer writes one fee row")
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 30800 and company_reputation() == fans_after, "Reopening does not charge or grant the trailer again")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == MADE, "Reopening still shows the made line")
	check(button_named("Make trailer") == null, "Reopening does not offer a second trailer")
	await open_product()
	await click(button_named("Fitness"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Fitness Newsletter" and not main.company_panel.busy, "The next product starts")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(str(product_by_id("p1").get("status", "")) == "complete", "The first product finishes selling")
	check(label_named("TrailerOffer_p1") == null, "A finished product does not keep the trailer offer")
	check(button_named("Make trailer") == null, "Nothing selling means no trailer button")
	await open_product()
	await click(button_named("Release"))
	var second := await wait_until(func() -> bool: return main.company_panel.screen == "release" and not main.company_panel.busy, "The next product releases")
	if second:
		await open_journey()
		var next_offer := label_named("TrailerOffer_p2")
		var next_selling := main.company_panel.find_child("Selling_p2", true, false) as Control
		check(next_selling != null and next_offer != null and next_selling.is_ancestor_of(next_offer) and next_offer.text == OFFER, "The next product offers the trailer again")
		var next_make := button_named("Make trailer")
		check(next_make != null and str(next_make.get_meta("cozy_variant", "")) == "secondary", "Make trailer stays secondary on the next product")
		var next_cash := company_cash()
		var next_fans := company_reputation()
		await click(next_make)
		await wait_until(func() -> bool: return company_cash() == next_cash - 2500 and company_reputation() == next_fans + 6 and not main.company_panel.busy, "The next trailer charges once and grants fans once")
		check(label_named("TrailerOffer_p2") != null and label_named("TrailerOffer_p2").text == MADE, "The next Selling card names the made trailer")
		check(button_named("Make trailer") == null, "The next trailer hides the button")
	await release_company()
	var both := trailer_ids(data_dir)
	check(both.size() == 2 and both[0] == "tycoon:trailer:p1:fee" and both[1] == "tycoon:trailer:p2:fee", "Each product writes its own fee row")
	var short_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-trailer-short-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(short_dir)
	var short_body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.journey.recordCompanyChange('seed:trailer-short', db.clockState().day, 2499 - 20700, 0, 0, 'Drain');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst ok = company.cashCents === 2499 && company.reputation === 5 && product && product.trailer && product.trailer.made === false && product.salesCents === 20700;\nif (!ok) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n"
	if not seed_company(short_dir, short_body, "Seeded a selling newsletter with $24.99 (%s)"):
		_finish()
		return
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", short_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 2499 and company_reputation() == 5, "The short-cash company has $24.99 and 5 fans")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == OFFER, "Short cash still shows the offer")
	await click(button_named("Make trailer"))
	await wait_until(func() -> bool: return notice_text().contains("Need $25") and company_cash() == 2499 and company_reputation() == 5 and not main.company_panel.busy, "Short cash says Need $25 and writes nothing")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == OFFER, "A failed trailer keeps the offer")
	check(button_named("Make trailer") != null and str(button_named("Make trailer").get_meta("cozy_variant", "")) == "secondary", "Make trailer stays after a failed cut")
	await release_company()
	check(trailer_ids(short_dir).is_empty(), "Short cash writes no trailer row")
	var made_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-trailer-made-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(made_dir)
	var made_body := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.tycoon.makeTrailer('p1');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst ok = company.cashCents === 18200 && company.reputation === 11 && product && product.trailer && product.trailer.made === true && product.salesCents === 20700 && product.fans === 5;\nif (!ok) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n"
	if not seed_company(made_dir, made_body, "Seeded a made trailer (%s)"):
		_finish()
		return
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", made_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 18200 and company_reputation() == 11, "A seeded trailer already has the fee and 6 fans")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == MADE, "A seeded trailer shows the made line")
	check(button_named("Make trailer") == null, "A seeded trailer has no button")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$182.00") and header.text.contains("11 reputation"), "Spring morning shows the trailer fee and fans")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the trailer day opens the summary")
	check(label_contains("Trailer: TownSquare Creator Cut"), "The summary names the trailer")
	check(company_reputation() == 11 and company_cash() == 18200, "Ending the day does not charge or grant again")
	# The summary frame shrinks after it is shown. A click before that misses Begin next day.
	await frames(8)
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == MADE, "The next morning still shows the made line")
	check(button_named("Make trailer") == null, "The next morning does not offer another trailer")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring") and header.text.contains("$182.00") and header.text.contains("11 reputation"), "The next morning is still Spring with the same cash and fans")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", made_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 18200 and company_reputation() == 11, "Reopening the next morning does not charge or grant again")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == MADE, "Reopening the next morning still shows the made line")
	check(trailer_ids(made_dir).size() == 1, "Replaying the trailer day keeps one fee row")
	print("TYCOON LAUNCH TRAILER ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
