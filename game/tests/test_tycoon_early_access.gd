extends SceneTree

## Headless early access with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. Shipping early starts sales that day.

const MAIN := preload("res://world/main.tscn")
const DAY0 := "Early access · Work one office day first."
const READY := "Early access · Required days are done. Use Release."
const OFFER := "Early access · ship now, −1 score"
const MARK := "Early access"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-early-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func ship_early_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("ShipEarly", true, false) as Button

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

func early_block(product: Dictionary) -> Dictionary:
	var value: Variant = product.get("earlyAccess", null)
	return value as Dictionary if value is Dictionary else {}

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

func wait_quiet(predicate: Callable, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await frames(1)
		if predicate.call():
			return true
	return false

func end_office_day() -> void:
	await click(button_named("End day"))
	if not await wait_quiet(func() -> bool: return main.company_panel.screen == "summary", 8000):
		await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the day opens the summary")
	await frames(10)
	await click(button_named("Begin next day"))
	if not await wait_quiet(func() -> bool: return not main.company_panel.visible, 4000):
		await click(button_named("Begin next day"))
	if await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office"):
		main.day_clock.set_speed(0)

func start_newsletter() -> void:
	await open_product()
	check(label_named("EarlyAccessOffer") == null and ship_early_button() == null, "The product picker has no early access control")
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

func connect_closed(note: String) -> void:
	check(main != null and main.job_panel != null and not main.job_panel._connection_panel.visible, note)

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
	var validation := ProjectSettings.globalize_path("res://../harness/src/validation.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-early-access.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { GameDatabase } from IMPORT_DATABASE;
import { EARLY_ACCESS_PENALTY_CAP, earlyAccessPenalty, reviewProduct, salesForDay } from IMPORT_TYCOON;
import { parseRequest } from IMPORT_VALIDATION;

const root = process.argv[process.argv.length - 1];
function fail(detail) {
  console.error(typeof detail === 'string' ? detail : JSON.stringify(detail));
  process.exit(2);
}
function open(name) {
  const dir = root + '/' + name;
  mkdirSync(dir + '/company-project', { recursive: true });
  return new GameDatabase(dir + '/startup-valley.sqlite', dir + '/company-project');
}
function staff(db, id) {
  const row = db.journey.db.prepare('SELECT staff_json FROM tycoon_products WHERE id = ?').get(id);
  return JSON.parse(String(row.staff_json));
}
function staffText(db, id) {
  const row = db.journey.db.prepare('SELECT staff_json FROM tycoon_products WHERE id = ?').get(id);
  return String(row.staff_json);
}
function message(fn) {
  try { fn(); return ''; } catch (error) { return error.message; }
}
function mustThrow(fn, pattern, label) {
  const text = message(fn);
  if (!pattern.test(text)) fail({ label, text });
}
function txCount(db) {
  return Number(db.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n);
}
function earlyRows(db) {
  return db.journey.db.prepare('SELECT id FROM company_transactions').all().filter((row) => String(row.id).startsWith('tycoon:early'));
}
function finishSales(db) {
  for (let guard = 0; guard < 8; guard += 1) {
    if (db.tycoon.view().history[0] && db.tycoon.view().history[0].status === 'complete') return;
    db.endDay(db.clockState().day);
  }
  fail('sales did not finish');
}

if (EARLY_ACCESS_PENALTY_CAP !== 3) fail('cap');
if (earlyAccessPenalty(0) !== 0 || earlyAccessPenalty(1) !== 1 || earlyAccessPenalty(3) !== 3 || earlyAccessPenalty(4) !== 3 || earlyAccessPenalty(9) !== 3) fail('penalty');
const rich = { seed: 26021, productId: 'p1', topicId: 'crypto', typeId: 'newsletter', design: 40, tech: 40, hype: 40, devDays: 2 };
const plainRich = reviewProduct(rich);
const cutRich = reviewProduct({ ...rich, earlyPenalty: 4 });
if (cutRich.score !== plainRich.score - 3) fail({ rich: plainRich.score, cut: cutRich.score });
const floored = reviewProduct({ ...rich, design: 0, tech: 0, hype: 0, earlyPenalty: 3 });
const flooredPlain = reviewProduct({ ...rich, design: 0, tech: 0, hype: 0 });
if (floored.score < 1 || floored.score > flooredPlain.score) fail({ floored: floored.score, plain: flooredPlain.score });
mustThrow(() => parseRequest({ kind: 'request', id: 'early', method: 'tycoon.earlyAccess', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'early', method: 'tycoon.earlyAccess', params: {} }).method !== 'tycoon.earlyAccess') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.earlyAccess(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
const freshOffer = skip.tycoon.view().developing.earlyAccess;
if (!freshOffer || freshOffer.enabled !== false || freshOffer.reason !== 'Work one office day first.' || freshOffer.daysLeft !== 2 || freshOffer.penalty !== 0) fail(freshOffer);
const fresh = staffText(skip, 'p1');
if (staff(skip, 'p1').earlyAccess !== undefined || staff(skip, 'p1').earlyDays !== undefined) fail('fresh keys');
skip.tycoon.view();
if (staffText(skip, 'p1') !== fresh) fail('read');
const freshTx = txCount(skip);
mustThrow(() => skip.tycoon.earlyAccess(), /Work one office day first\\./, 'day0');
if (staffText(skip, 'p1') !== fresh || txCount(skip) !== freshTx || skip.clockState().day !== 1) fail('day0 write');
skip.endDay(1);
skip.endDay(2);
const ready = skip.tycoon.view().developing.earlyAccess;
if (!ready || ready.enabled !== false || ready.reason !== 'Required days are done. Use Release.' || ready.daysLeft !== 0 || ready.penalty !== 0) fail(ready);
const readyJson = staffText(skip, 'p1');
mustThrow(() => skip.tycoon.earlyAccess(), /Required days are done\\. Use Release\\./, 'ready');
if (staffText(skip, 'p1') !== readyJson) fail('ready write');
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].earlyAccess !== null) fail({ cash: skip.journey.state().company.cashCents });
if (staff(skip, 'p1').earlyAccess !== undefined || staff(skip, 'p1').earlyDays !== undefined) fail('skip keys');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.earlyAccess(), /No product is on the bench\\./, 'shipped');
if (earlyRows(skip).length !== 0) fail('rows');
skip.close();

const ship = open('ship');
ship.tycoon.start('crypto', 'newsletter', []);
ship.endDay(1);
const offer = ship.tycoon.view().developing.earlyAccess;
if (ship.tycoon.view().developing.devDays !== 1 || !offer || offer.enabled !== true || offer.reason !== '' || offer.daysLeft !== 1 || offer.penalty !== 1) fail(offer);
const before = staffText(ship, 'p1');
ship.tycoon.view();
if (staffText(ship, 'p1') !== before) fail('offer read');
const day = ship.clockState().day;
const tx = txCount(ship);
ship.tycoon.earlyAccess();
if (ship.clockState().day !== day || ship.tycoon.view().developing !== null) fail('clock');
const shipped = ship.tycoon.view().history[0];
if (!shipped || shipped.status !== 'released' || shipped.releasedDay !== day || shipped.salesDays !== 1) fail(shipped);
if (staff(ship, 'p1').earlyAccess !== true || staff(ship, 'p1').earlyDays !== 1) fail(staff(ship, 'p1'));
const block = shipped.earlyAccess;
if (!block || block.enabled !== false || block.reason !== '' || block.daysLeft !== 0 || block.penalty !== 1) fail(block);
const reviewInput = { seed: ship.tycoon.view().seed, productId: 'p1', topicId: 'crypto', typeId: 'newsletter', design: 2, tech: 2, hype: 2, devDays: 2 };
const expected = reviewProduct({ ...reviewInput, earlyPenalty: 1 });
const uncut = reviewProduct(reviewInput);
if (JSON.stringify(shipped.review) !== JSON.stringify(expected) || expected.score !== uncut.score - 1 || expected.score < 1) fail({ expected, got: shipped.review });
const sale = salesForDay({ seed: ship.tycoon.view().seed, productId: 'p1', typeId: 'newsletter', fit: 'great', score: expected.score, dayIndex: 0, reputation: 0 });
if (shipped.salesCents !== sale.cents || shipped.fans !== sale.fans || ship.journey.state().company.cashCents !== sale.cents || ship.journey.state().company.reputation !== sale.fans || !(sale.cents < 20700)) fail({ sale, shipped });
if (earlyRows(ship).length !== 0 || !(txCount(ship) > tx)) fail('sale rows');
const launchCash = ship.journey.state().company.cashCents;
const stored = staffText(ship, 'p1');
ship.tycoon.view();
if (staffText(ship, 'p1') !== stored) fail('shipped read');
mustThrow(() => ship.tycoon.earlyAccess(), /No product is on the bench\\./, 'again');
ship.endDay(day);
if (ship.tycoon.view().history[0].salesCents !== launchCash || ship.tycoon.view().history[0].salesDays !== 1) fail('same day');
ship.endDay(day + 1);
if (ship.tycoon.view().history[0].salesDays !== 2 || !(ship.tycoon.view().history[0].salesCents > launchCash) || staff(ship, 'p1').earlyDays !== 1) fail('next day');
ship.close();

const deal = open('deal');
const contract = deal.tycoon.view().contract;
deal.tycoon.acceptContract();
deal.tycoon.start(contract.topicId, contract.typeId, []);
deal.endDay(1);
const dealDay = deal.clockState().day;
deal.tycoon.earlyAccess();
const launch = deal.tycoon.view().history[0];
if (!launch || launch.contract.bonusCents !== contract.bonusCents) fail(launch);
if (deal.journey.state().company.cashCents !== launch.salesCents + contract.bonusCents) fail({ cash: deal.journey.state().company.cashCents, sales: launch.salesCents, bonus: contract.bonusCents });
if (deal.journey.state().company.earnedCents !== launch.salesCents + contract.bonusCents) fail('earned');
if (deal.journey.state().company.reputation !== launch.fans) fail('fans');
const paid = Number(deal.journey.db.prepare(\"SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:contract:p1'\").get().n);
if (paid !== 1) fail({ paid });
mustThrow(() => deal.tycoon.earlyAccess(), /No product is on the bench\\./, 'deal again');
deal.endDay(dealDay);
deal.endDay(dealDay + 1);
const paidAgain = Number(deal.journey.db.prepare(\"SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:contract:p1'\").get().n);
if (paidAgain !== 1 || earlyRows(deal).length !== 0) fail({ paidAgain });
deal.close();

const cap = open('cap');
cap.tycoon.start('fitness', 'course', [], 100, 'none', 'none', 'balanced', 'everyone', 'long');
cap.tycoon.addFeature();
if (cap.tycoon.view().developing.devDaysRequired !== 5) fail('required');
cap.endDay(1);
const capOffer = cap.tycoon.view().developing.earlyAccess;
if (!capOffer || capOffer.enabled !== true || capOffer.daysLeft !== 4 || capOffer.penalty !== 3) fail(capOffer);
cap.tycoon.earlyAccess();
const capped = staff(cap, 'p1');
if (capped.earlyAccess !== true || capped.earlyDays !== 4 || capped.feature !== true || capped.featureDemand !== true) fail(capped);
const capHistory = cap.tycoon.view().history[0];
if (!capHistory || capHistory.earlyAccess.penalty !== 3 || capHistory.review.score < 1) fail(capHistory);
const capExpected = reviewProduct({ seed: cap.tycoon.view().seed, productId: 'p1', topicId: 'fitness', typeId: 'course', design: 2, tech: 2, hype: 2, devDays: 5, earlyPenalty: 4 });
if (JSON.stringify(capHistory.review) !== JSON.stringify(capExpected)) fail({ expected: capExpected, got: capHistory.review });
cap.close();

const lop = open('lop');
lop.tycoon.start('crypto', 'newsletter', []);
lop.tycoon.setDayPlan('design');
lop.endDay(1);
lop.tycoon.earlyAccess();
if (staff(lop, 'p1').bugs !== 1 || lop.tycoon.view().history[0].bugs !== 1) fail('bugs');
const lopExpected = reviewProduct({ seed: lop.tycoon.view().seed, productId: 'p1', topicId: 'crypto', typeId: 'newsletter', design: 6, tech: 0, hype: 0, devDays: 2, bugs: 1, earlyPenalty: 1 });
if (JSON.stringify(lop.tycoon.view().history[0].review) !== JSON.stringify(lopExpected)) fail('lop review');
lop.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.endDay(1);
kept.tycoon.earlyAccess();
const keptFile = root + '/kept/startup-valley.sqlite';
const keptProject = root + '/kept/company-project';
const keptJson = staffText(kept, 'p1');
const keptSales = kept.tycoon.view().history[0].salesCents;
const keptBlock = JSON.stringify(kept.tycoon.view().history[0].earlyAccess);
kept.tycoon.view();
if (staffText(kept, 'p1') !== keptJson) fail('kept read');
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (staffText(reopened, 'p1') !== keptJson || reopened.tycoon.view().history[0].salesCents !== keptSales || JSON.stringify(reopened.tycoon.view().history[0].earlyAccess) !== keptBlock) fail('reopen');
reopened.tycoon.view();
if (staffText(reopened, 'p1') !== keptJson) fail('reopen read');
finishSales(reopened);
reopened.tycoon.sequel('p1');
if (staff(reopened, 'p2').earlyAccess !== undefined || staff(reopened, 'p2').earlyDays !== undefined) fail('sequel keys');
const sequelOffer = reopened.tycoon.view().developing.earlyAccess;
if (!sequelOffer || sequelOffer.enabled !== false || sequelOffer.reason !== 'Work one office day first.' || sequelOffer.daysLeft !== 1 || sequelOffer.penalty !== 0) fail(sequelOffer);
if (staff(reopened, 'p1').earlyAccess !== true || staff(reopened, 'p1').earlyDays !== 1) fail('original kept');
reopened.close();
console.log('EARLY ACCESS RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("IMPORT_VALIDATION", JSON.stringify(validation))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the early access rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Early access rules hold (%s)" % " ".join(output))
	return code == 0

func fits(control: Control, above: Control) -> bool:
	return control != null and above != null and control.get_global_rect().end.y <= above.get_global_rect().position.y + 1.0 and not control.get_global_rect().intersects(above.get_global_rect())

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
	await dismiss_onboarding()
	check(label_named("EarlyAccessOffer") == null and ship_early_button() == null, "No early access control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("EarlyAccessOffer") == null and ship_early_button() == null, "The build screen has no early access control")
	await open_journey()
	var offer := label_named("EarlyAccessOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var crunch := main.company_panel.find_child("Crunch", true, false) as Button
	check(card != null and offer != null and card.is_ancestor_of(offer) and offer.text == DAY0, "Day 0 names why early access waits")
	check(ship_early_button() == null, "Day 0 hides Ship early")
	await reveal(offer)
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	check(crunch != null and fits(crunch, offer), "Early access sits under Crunch")
	check(fits(offer, new_product), "The waiting line sits above New Product")
	check(footer != null and offer.get_global_rect().end.y <= footer.get_global_rect().position.y and not offer.get_global_rect().intersects(footer.get_global_rect()), "The waiting line does not overlap Hire")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("EarlyAccessOffer") != null and label_named("EarlyAccessOffer").text == READY, "A finished build points at Release")
	check(ship_early_button() == null, "A finished build hides Ship early")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping early access still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping early access still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping early access keeps launch sales at 20700 cents")
		check(label_named("ReleaseEarly") == null, "A normal release does not say Early access")
		check(latest_shipped().get("earlyAccess") == null, "A normal release stores no early access block")
		await open_journey()
		check(label_named("EarlyAccessOffer") == null and ship_early_button() == null, "The early access control is gone after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
	connect_closed("Connect stays closed after a normal release")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300, "Reopening the even newsletter keeps 33300 cents")
	await start_newsletter()
	await open_journey()
	check(label_named("EarlyAccessOffer") != null and label_named("EarlyAccessOffer").text == DAY0, "The next product waits for an office day")
	await end_office_day()
	await open_journey()
	offer = label_named("EarlyAccessOffer")
	var ship := ship_early_button()
	card = main.company_panel.find_child("PublisherCard", true, false) as Control
	crunch = main.company_panel.find_child("Crunch", true, false) as Button
	check(card != null and offer != null and card.is_ancestor_of(offer) and offer.text == OFFER, "The developing card names the early access offer")
	check(ship != null and card.is_ancestor_of(ship) and not ship.disabled and str(ship.get_meta("cozy_variant", "")) == "secondary" and ship.text == "Ship early", "Ship early is a secondary button")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Ship early")
	var early := early_block(developing())
	check(bool(early.get("enabled", false)) and int(early.get("penalty", 0)) == 1 and int(early.get("daysLeft", 0)) == 1 and str(early.get("reason", "x")) == "", "The worker offers a one-point early ship")
	await reveal(offer)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(crunch != null and fits(crunch, offer), "The offer sits under Crunch")
	check(fits(offer, ship), "The offer line sits above Ship early")
	check(fits(ship, new_product), "Ship early sits above New Product")
	check(footer != null and ship.get_global_rect().end.y <= footer.get_global_rect().position.y and not ship.get_global_rect().intersects(footer.get_global_rect()), "Ship early does not overlap Hire")
	var cash_before := company_cash()
	await click(ship)
	var shipped := await wait_until(func() -> bool:
		return not main.company_panel.busy and main.company_panel.screen == "release" and label_named("ReleaseEarly") != null
	, "Shipping early opens the release card")
	if shipped:
		check(label_named("ReleaseEarly").text == MARK, "The release card says Early access")
		check(company_cash() > cash_before and company_cash() < cash_before + 20700, "Launch-day sales are quieter than a full newsletter")
		check(developing().is_empty(), "The bench is clear after the early ship")
		var shipped_block := early_block(latest_shipped())
		check(not bool(shipped_block.get("enabled", true)) and int(shipped_block.get("penalty", 0)) == 1 and int(latest_shipped().get("salesDays", 0)) == 1, "The shipped product keeps the penalty and starts sales")
		await open_journey()
		check(label_named("SellingEarly_p2") != null and label_named("SellingEarly_p2").text == MARK, "The selling card says Early access")
		check(label_named("SellingEarly_p1") == null, "The full newsletter does not say Early access")
		await open_product()
		check(label_named("EarlyAccessHistory_p2") != null and label_named("EarlyAccessHistory_p2").text == MARK, "The shipped list says Early access")
		check(label_named("EarlyAccessHistory_p1") == null, "The shipped list leaves the full newsletter unmarked")
	connect_closed("Connect stays closed after an early ship")
	var kept_cash := company_cash()
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == kept_cash, "Reopening keeps the early-ship cash")
	check(label_named("SellingEarly_p2") != null and label_named("SellingEarly_p2").text == MARK, "Reopening keeps Early access on the selling card")
	check(int(early_block(latest_shipped()).get("penalty", 0)) == 1, "Reopening keeps the stored penalty")
	connect_closed("Connect stays closed after reopen")
	print("TYCOON EARLY ACCESS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
