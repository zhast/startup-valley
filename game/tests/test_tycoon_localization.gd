extends SceneTree

## Headless translation loop with the real worker and an isolated company.
## No translation is the default. One optional shelf line spends game cash after
## sales finish and pays one quieter extra sales day on the next day end.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Translate · Spanish edition · $50, one extra sales day"
const SELLING := "Spanish edition · one extra sales day"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-localize-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func button_node(node_name: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Button

func label_named(node_name: String) -> Label:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Label

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

func money(cents: int) -> String:
	var integer := str(absi(cents) / 100)
	var grouped := ""
	for index: int in range(integer.length()):
		if index > 0 and (integer.length() - index) % 3 == 0:
			grouped += ","
		grouped += integer[index]
	return ("-" if cents < 0 else "") + grouped + ".%02d" % (absi(cents) % 100)

func localize_ids(root: String) -> PackedStringArray:
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := root.path_join("read-localize.mjs")
	var script := "import { DatabaseSync } from 'node:sqlite';\nconst db = new DatabaseSync(process.argv[2], { timeout: 3000 });\nconst rows = db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:localize:%' ORDER BY id\").all();\nprocess.stdout.write(rows.map((row) => String(row.id)).join('\\n'));\ndb.close();\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return PackedStringArray()
	file.store_string(script)
	file.close()
	var ids := PackedStringArray()
	for _try: int in range(8):
		var output: Array = []
		var code := OS.execute(node, PackedStringArray(["--no-warnings", script_path, root.path_join("startup-valley.sqlite")]), output, true)
		ids = PackedStringArray()
		if code == 0:
			for line: String in "\n".join(output).split("\n"):
				var trimmed := line.strip_edges()
				if trimmed.begins_with("tycoon:localize:"):
					ids.append(trimmed)
			if not ids.is_empty() or _try == 7:
				return ids
		OS.delay_msec(150)
	return ids

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

func seed_short(root: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := root.path_join("seed-localize.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from " + JSON.stringify(database) + ";\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\nconst have = db.journey.state().company.cashCents;\ndb.journey.recordCompanyChange('drain-localize', 7, -have, 0, 0, 'Drain');\ndb.setClock(7, 480, 0);\nconst offer = db.tycoon.view().history[0].localization;\nconst company = db.journey.state().company;\nconst rows = db.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:localize:%'\").all();\ndb.close();\nif (company.cashCents !== 0 || offer.phase !== '' || offer.enabled !== false || offer.reason !== 'Need $' + '50' || rows.length !== 0) { console.error(JSON.stringify({ company: company, offer: offer, rows: rows })); process.exit(2); }\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the short-cash seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Seeded a finished product with $0 (%s)" % " ".join(output))
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
	check(button_named("Translate") == null, "No translate action before a ship")
	await start_newsletter()
	check(developing().get("localization") == null, "A product on the bench has no translation offer")
	check(button_named("Translate") == null, "No translate action while the product is on the bench")
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "No translation still pays 20700 cents")
	if not released:
		_finish()
		return
	check(company_reputation() == 5, "No translation still pays 5 fans")
	check(int(latest_shipped().get("salesCents", 0)) == 20700, "No translation keeps launch sales at 20700 cents")
	await open_journey()
	var selling := main.company_panel.find_child("Selling_p1", true, false) as Control
	check(selling != null, "Company Journey shows the selling-product card")
	check(button_node("Translate_p1") == null, "Translate stays off the Selling card")
	check(label_named("LocalizeOffer_p1") == null, "The translate line waits until sales finish")
	check(localize_ids(data_dir).is_empty(), "Skipping the translation writes no rows at launch")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the selling card")
	await end_office_day()
	check(company_cash() == 20700, "The release day does not sell twice")
	await open_journey()
	await end_office_day()
	await open_journey()
	check(company_cash() == 33300, "The next office day is still 33300 cents")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "Unsigned sales stay on the old total")
	check(button_node("Translate_p1") == null, "Translate stays hidden while sales continue")
	check(localize_ids(data_dir).is_empty(), "Skipping the translation writes no rows after the next office day")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	var finished := main.company_panel.find_child("Finished_p1", true, false) as Control
	var translate := button_node("Translate_p1")
	var shipped := latest_shipped()
	var offer: Dictionary = shipped.get("localization", {}) if shipped.get("localization") is Dictionary else {}
	check(str(shipped.get("status", "")) == "complete", "Sales finish after four days")
	check(int(shipped.get("salesDays", 0)) == 4, "The sales window stays four days")
	check(finished != null, "Company Journey shows the finished-product card")
	check(str(offer.get("phase", "missing")) == "" and bool(offer.get("enabled", false)) and str(offer.get("edition", "")) == "Spanish edition", "The finished card offers one Spanish edition")
	check(translate != null and not translate.disabled and str(translate.get_meta("cozy_variant", "")) == "secondary" and translate.text == "Translate", "Translate is a secondary action")
	check(label_named("LocalizeOffer_p1") != null and label_named("LocalizeOffer_p1").text == OFFER, "The shipped card names the edition, the fee, and one extra sales day")
	check(label_named("LocalizeLine_p1") == null, "The bought line waits until the fee is paid")
	var shelf := main.company_panel.find_child("ShelfActions_p1", true, false) as Control
	var port := button_node("Port_p1")
	check(shelf != null and port != null and translate.get_parent() == shelf and port.get_parent() == shelf, "Translate shares the shelf row with Port")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary on the finished card")
	var sales_cents := int(shipped.get("salesCents", 0))
	var sales_fans := int(shipped.get("fans", 0))
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(translate)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("LocalizeLine_p1") != null, "The translation line appears")
	var started := latest_shipped()
	var selling_edition: Dictionary = started.get("localization", {}) if started.get("localization") is Dictionary else {}
	check(label_named("LocalizeLine_p1").text == SELLING, "The bought line names one extra sales day")
	check(button_node("Translate_p1") == null, "Buying hides the Translate button")
	check(label_named("LocalizeOffer_p1") == null, "Buying hides the offer line")
	check(str(selling_edition.get("phase", "")) == "selling" and int(selling_edition.get("cents", -1)) == 0, "The payload waits for the next day end")
	check(company_cash() == cash_before - 5000, "The translation charges $50 once")
	check(company_reputation() == fans_before, "The fee adds no fans")
	check(int(started.get("salesCents", -1)) == sales_cents, "The fee does not change sales cash")
	check(int(started.get("fans", -1)) == sales_fans, "The fee does not change sales fans")
	check(int(started.get("salesDays", 0)) == 4, "Starting a translation does not extend the sales window")
	var fee_ids := localize_ids(data_dir)
	check(fee_ids.size() == 1 and fee_ids[0] == "tycoon:localize:p1:fee", "The fee writes one ledger row (%s)" % ",".join(fee_ids))
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$%s" % money(cash_before - 5000)), "The header shows the cash after the fee")
	await end_office_day()
	await open_journey()
	var paid := latest_shipped()
	var sold: Dictionary = paid.get("localization", {}) if paid.get("localization") is Dictionary else {}
	var cents := int(sold.get("cents", 0))
	var fans := int(sold.get("fans", 0))
	check(str(sold.get("phase", "")) == "sold" and cents > 0 and fans >= 1, "The next day end pays the extra sales day")
	check(label_named("LocalizeLine_p1") != null and label_named("LocalizeLine_p1").text == "Spanish edition · $%s" % money(cents), "The bought line names the extra sales")
	check(button_node("Translate_p1") == null, "The paid translation still has no button")
	check(company_cash() == cash_before - 5000 + cents, "The extra day pays its cash once")
	check(company_reputation() == fans_before + fans, "The extra day adds its fans once")
	check(int(paid.get("salesCents", -1)) == sales_cents + cents, "The extra day adds to sales cash")
	check(int(paid.get("fans", -1)) == sales_fans + fans, "The extra day adds to sales fans")
	check(int(paid.get("salesDays", 0)) == 4 and str(paid.get("status", "")) == "complete", "The product stays finished after the translation pays")
	var sale_ids := localize_ids(data_dir)
	check(sale_ids.size() == 2 and sale_ids.has("tycoon:localize:p1:fee") and sale_ids.has("tycoon:localize:p1:sales"), "The extra day writes one sales row (%s)" % ",".join(sale_ids))
	var paid_cash := company_cash()
	var paid_fans := company_reputation()
	await end_office_day()
	await open_journey()
	var held := latest_shipped()
	var held_edition: Dictionary = held.get("localization", {}) if held.get("localization") is Dictionary else {}
	check(company_cash() == paid_cash and company_reputation() == paid_fans, "A later day does not pay the translation again")
	check(int(held_edition.get("cents", -1)) == cents and int(held_edition.get("fans", -1)) == fans, "The stored translation payout stays put")
	check(localize_ids(data_dir).size() == 2, "A later day does not write another localization row")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == paid_cash and company_reputation() == paid_fans, "Reopening does not charge or pay the translation again")
	check(label_named("LocalizeLine_p1") != null and label_named("LocalizeLine_p1").text == "Spanish edition · $%s" % money(cents), "Reopening still shows the bought line")
	check(button_node("Translate_p1") == null, "Reopening does not offer a second translation")
	check(localize_ids(data_dir).size() == 2, "Reopening does not write another localization row")
	var short_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-localize-short-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(short_dir)
	if not seed_short(short_dir):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", short_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	var short_button := button_node("Translate_p1")
	check(company_cash() == 0, "The short-cash company still has $0")
	check(short_button != null and short_button.disabled and str(short_button.get_meta("cozy_variant", "")) == "secondary" and short_button.text == "Translate · Need $50", "Short cash reads Need $50")
	check(label_named("LocalizeOffer_p1") != null and label_named("LocalizeOffer_p1").text == OFFER, "Short cash still shows the offer")
	check(label_named("LocalizeLine_p1") == null, "Short cash draws no bought line")
	main.worker_client.company_request("tycoon.localize", {"productId": "p1"})
	await wait_until(func() -> bool: return notice_text().contains("Need $50") and company_cash() == 0, "Buying with too little cash says Need $50 and writes nothing")
	check(localize_ids(short_dir).is_empty(), "A refused translation writes no rows")
	check(button_node("Translate_p1") != null and button_node("Translate_p1").disabled, "A refused translation keeps the disabled button")
	check(not main.job_panel._connection_panel.visible, "Translations never open Connect")
	print("TYCOON LOCALIZATION ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
