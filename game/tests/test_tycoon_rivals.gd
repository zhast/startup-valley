extends SceneTree

## Headless rival shop with the real worker and an isolated company.
## Skipping the rival topic leaves the first newsletter alone.

const MAIN := preload("res://world/main.tscn")
const RIVAL_LINE := "Rival: Pip's Pop-up is pushing Cooking this season"
const WARNING := "Rival · opening demand drops."
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-rivals-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func boot() -> bool:
	main = MAIN.instantiate()
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads the company")
	if ready:
		main.day_clock.set_speed(0)
	return ready

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

func rules_hold() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tycoon := ProjectSettings.globalize_path("res://../harness/src/tycoon.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-rivals.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { GameDatabase } from %s;
import { salesForDay, openingDemand, rivalForDay, RIVAL_UNIT_PERCENT } from %s;
const root = process.argv[process.argv.length - 1];
function fail(detail) { console.error(JSON.stringify(detail)); process.exit(2); }
function open(name) {
  const dir = root + '/' + name;
  mkdirSync(dir + '/company-project', { recursive: true });
  return new GameDatabase(dir + '/startup-valley.sqlite', dir + '/company-project');
}
function staff(db, id) {
  const row = db.journey.db.prepare('SELECT staff_json FROM tycoon_products WHERE id = ?').get(id);
  return JSON.parse(String(row.staff_json));
}
if (RIVAL_UNIT_PERCENT !== 90) fail({ RIVAL_UNIT_PERCENT });
const spring = rivalForDay(1);
if (JSON.stringify(spring) !== JSON.stringify(rivalForDay(28)) || JSON.stringify(spring) !== JSON.stringify(rivalForDay(113))) fail(spring);
if (spring.shop !== \"Pip's Pop-up\" || spring.topicId !== 'cooking' || spring.topicName !== 'Cooking' || spring.unitPercent !== 90) fail(spring);
const summer = rivalForDay(29);
const fall = rivalForDay(57);
const winter = rivalForDay(85);
if (summer.topicId !== 'trading' || summer.shop !== 'Harbor Goods') fail(summer);
if (fall.topicId !== 'gaming' || fall.shop !== 'Lumen Kiosk') fail(fall);
if (winter.topicId !== 'study_notes' || winter.shop !== 'Sable Shelf') fail(winter);

const crypto = open('crypto');
crypto.tycoon.start('crypto', 'newsletter', []);
crypto.endDay(1);
crypto.endDay(2);
crypto.tycoon.release('p1');
const cryptoCash = crypto.journey.state().company.cashCents;
const cryptoFans = crypto.tycoon.view().history[0].fans;
if (cryptoCash !== 20700 || cryptoFans !== 5 || staff(crypto, 'p1').rivalCut === true) fail({ cryptoCash, cryptoFans, staff: staff(crypto, 'p1') });
crypto.endDay(3);
crypto.endDay(4);
if (crypto.journey.state().company.cashCents !== 33300) fail({ next: crypto.journey.state().company.cashCents });
crypto.close();

const hit = open('hit');
hit.setClock(25, 480, 0);
hit.tycoon.start('cooking', 'newsletter', []);
hit.endDay(25);
hit.endDay(26);
hit.tycoon.release('p1');
const opened = hit.tycoon.view().history[0];
const seed = hit.tycoon.view().seed;
const sale = { seed, productId: 'p1', typeId: 'newsletter', fit: opened.fit, score: opened.review.score, dayIndex: 0, reputation: 0 };
const plain = salesForDay(sale);
const cut = salesForDay({ ...sale, rivalCut: true });
const base = openingDemand(opened.fit, opened.review.score, 0, false);
if (openingDemand(opened.fit, opened.review.score, 0, true) !== Math.max(1, Math.round(base * 90 / 100))) fail({ base });
if (!(cut.cents < plain.cents) || opened.salesCents !== cut.cents || opened.fans !== cut.fans) fail({ plain, cut, opened });
if (staff(hit, 'p1').rivalCut !== true) fail(staff(hit, 'p1'));
const rivalRows = hit.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:rival%%'\").all();
if (rivalRows.length !== 0) fail(rivalRows);
const releaseDay = hit.clockState().day;
const releaseCents = hit.journey.state().company.cashCents;
hit.endDay(releaseDay);
hit.endDay(releaseDay);
if (hit.clockState().day !== releaseDay + 1 || hit.journey.state().company.cashCents !== releaseCents || hit.tycoon.view().history[0].salesCents !== releaseCents) fail({ day: hit.clockState().day, cash: hit.journey.state().company.cashCents });
const releaseFans = hit.journey.state().company.reputation;
const dayOne = salesForDay({ ...sale, dayIndex: 1, reputation: releaseFans, rivalCut: true });
hit.endDay(28);
if (hit.tycoon.view().history[0].salesCents !== releaseCents + dayOne.cents) fail({ sales: hit.tycoon.view().history[0].salesCents, dayOne });
const fansAfter = releaseFans + dayOne.fans;
const summerDay = salesForDay({ ...sale, dayIndex: 2, reputation: fansAfter, rivalCut: true });
const summerPlain = salesForDay({ ...sale, dayIndex: 2, reputation: fansAfter });
hit.endDay(29);
if (!(summerDay.cents < summerPlain.cents) || hit.tycoon.view().history[0].salesCents !== releaseCents + dayOne.cents + summerDay.cents) fail({ summerDay, summerPlain, sales: hit.tycoon.view().history[0].salesCents });
const saved = hit.tycoon.view().history[0].salesCents;
const savedCash = hit.journey.state().company.cashCents;
const file = root + '/hit/startup-valley.sqlite';
const project = root + '/hit/company-project';
hit.close();
const reopened = new GameDatabase(file, project);
reopened.endDay(29);
if (reopened.tycoon.view().history[0].salesCents !== saved || reopened.journey.state().company.cashCents !== savedCash || staff(reopened, 'p1').rivalCut !== true) fail({ saved, now: reopened.tycoon.view().history[0].salesCents });
reopened.close();

const other = open('other');
other.setClock(29, 480, 0);
other.tycoon.start('cooking', 'newsletter', []);
other.endDay(29);
other.endDay(30);
other.tycoon.release('p1');
const quiet = other.tycoon.view().history[0];
const untouched = salesForDay({ seed: other.tycoon.view().seed, productId: 'p1', typeId: 'newsletter', fit: quiet.fit, score: quiet.review.score, dayIndex: 0, reputation: 0 });
if (quiet.salesCents !== untouched.cents || quiet.fans !== untouched.fans || staff(other, 'p1').rivalCut === true) fail({ quiet, untouched, staff: staff(other, 'p1') });
other.close();
""" % [JSON.stringify(database), JSON.stringify(tycoon)]
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the rival rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Rival rules hold (%s)" % " ".join(output))
	return code == 0

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	if not rules_hold():
		_finish()
		return
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	var card := main.company_panel.find_child("SeasonCard", true, false) as Control
	var rival := label_named("SeasonRival")
	check(card != null and rival != null and card.is_ancestor_of(rival) and rival.text == RIVAL_LINE, "The Season card names the rival and the topic")
	check(label_named("SeasonTopics") != null and label_named("SeasonTopics").text == "In season: Fitness, Dating Advice", "The rival line leaves the season topics alone")
	var rival_view: Dictionary = tycoon_state().get("rival", {}) if tycoon_state().get("rival") is Dictionary else {}
	check(str(rival_view.get("shop", "")) == "Pip's Pop-up" and str(rival_view.get("topicId", "")) == "cooking" and int(rival_view.get("unitPercent", 0)) == 90, "The worker rival is Pip's Pop-up on Cooking at 90")
	await open_product()
	check(label_named("RivalWarning") == null, "Fitness shows no rival warning")
	var cooking := button_named("Cooking")
	check(cooking != null and cooking.text == "Cooking", "Cooking stays a plain topic button")
	await click(button_named("Trading"))
	check(label_named("RivalWarning") == null, "Trading shows no rival warning in spring")
	await click(button_named("Crypto Alpha"))
	check(label_named("RivalWarning") == null, "Crypto Alpha shows no rival warning")
	await click(button_named("Cooking"))
	var warning := label_named("RivalWarning")
	check(warning != null and warning.text == WARNING, "Cooking shows the rival warning")
	check(button_named("Cooking") != null and button_named("Cooking").text == "Cooking", "The warning stays off the topic button")
	await click(button_named("Fitness"))
	check(label_named("RivalWarning") == null, "Leaving Cooking hides the warning")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	await open_journey()
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the rival topic still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the rival topic still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the rival topic keeps launch sales at 20700 cents")
		await open_journey()
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "A non-matching topic keeps the old sales total")
		check(label_named("SeasonRival") != null and label_named("SeasonRival").text == RIVAL_LINE, "Spring still names Pip's Pop-up")
	print("TYCOON RIVALS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
