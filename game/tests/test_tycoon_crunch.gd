extends SceneTree

## Headless crunch with the real worker and an isolated company.
## Skipping Crunch leaves the balanced newsletter. Arming it doubles the next craft day.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Crunch · double craft tomorrow, then a rest day and +1 bug"
const ARMED := "Crunching · tomorrow's craft counts double"
const RESTING := "Resting · team recovers tomorrow"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-crunch-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func crunch_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("Crunch", true, false) as Button

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

func crunch_payload() -> Dictionary:
	var value: Variant = developing().get("crunch", null)
	return value as Dictionary if value is Dictionary else {}

func bugs_payload() -> Dictionary:
	var value: Variant = developing().get("bugs", null)
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
	check(label_named("CrunchOffer") == null and crunch_button() == null, "The product picker has no crunch control")
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

func rules_hold() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tycoon := ProjectSettings.globalize_path("res://../harness/src/tycoon.ts")
	var validation := ProjectSettings.globalize_path("res://../harness/src/validation.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-crunch.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { liveBugs } from IMPORT_TYCOON;
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
function crunchRows(db) {
  return db.journey.db.prepare('SELECT id FROM company_transactions').all().filter((row) => String(row.id).startsWith('tycoon:crunch'));
}
function finishSales(db) {
  for (let guard = 0; guard < 8; guard += 1) {
    if (db.tycoon.view().history[0] && db.tycoon.view().history[0].status === 'complete') return;
    db.endDay(db.clockState().day);
  }
  fail('sales did not finish');
}
function points(db) {
  const developing = db.tycoon.view().developing;
  return [developing.design, developing.tech, developing.hype, developing.devDays];
}
function team(name) {
  const dir = root + '/' + name;
  mkdirSync(dir + '/company-project', { recursive: true });
  const file = dir + '/startup-valley.sqlite';
  const project = dir + '/company-project';
  let db = new GameDatabase(file, project);
  db.journey.hire('mira', 1);
  db.close();
  const sql = new DatabaseSync(file);
  sql.prepare("UPDATE milestone_progress SET completed = 1 WHERE id = 'website'").run();
  sql.close();
  db = new GameDatabase(file, project);
  db.journey.recordCompanyChange('office-team-cash', 1, 250000, 0, 0, 'Office team cash');
  db.journey.hire('theo', 1);
  return db;
}

if (liveBugs({ design: 4, tech: 4, hype: 4 }, 0, 0) !== 0) fail('balanced');
if (liveBugs({ design: 4, tech: 4, hype: 4 }, 1, 0) !== 1) fail('crunch bug');
if (liveBugs({ design: 20, tech: 0, hype: 0 }, 3, 0) !== 5) fail('cap');
mustThrow(() => parseRequest({ kind: 'request', id: 'crunch', method: 'tycoon.crunch', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'crunch', method: 'tycoon.crunch', params: {} }).method !== 'tycoon.crunch') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.crunch(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
if (JSON.stringify(skip.tycoon.view().developing.crunch) !== JSON.stringify({ state: 'idle' }) || staff(skip, 'p1').crunch !== undefined || staff(skip, 'p1').crunchBugs !== undefined) fail('fresh');
const fresh = staffText(skip, 'p1');
skip.tycoon.view();
if (staffText(skip, 'p1') !== fresh) fail('read');
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].crunch !== null) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.crunch(), /No product is on the bench\\./, 'shipped');
if (crunchRows(skip).length !== 0) fail('rows');
skip.close();

const even = open('even');
even.tycoon.start('crypto', 'newsletter', []);
even.endDay(1);
even.endDay(2);
even.tycoon.release('p1');
const evenCash = even.journey.state().company.cashCents;
const evenScore = even.tycoon.view().history[0].review.score;
even.close();

const early = open('early');
early.tycoon.start('crypto', 'newsletter', []);
const cash = early.journey.state().company.cashCents;
const tx = txCount(early);
const clock = early.clockState().day;
early.tycoon.crunch();
if (early.clockState().day !== clock || early.journey.state().company.cashCents !== cash || txCount(early) !== tx || crunchRows(early).length !== 0) fail('set cost');
if (early.tycoon.view().developing.crunch.state !== 'armed' || staff(early, 'p1').crunch !== 'armed') fail('armed');
const armed = staffText(early, 'p1');
early.tycoon.crunch();
early.tycoon.view();
if (staffText(early, 'p1') !== armed) fail('idempotent');
early.endDay(1);
if (points(early).join(',') !== '4,4,4,1' || early.tycoon.view().researchPoints !== 1 || early.tycoon.view().developing.crunch.state !== 'resting' || staff(early, 'p1').crunchBugs !== 1) fail(points(early));
if (JSON.stringify(early.tycoon.view().developing.bugs) !== JSON.stringify({ count: 1, cleared: 0, fixing: false })) fail(early.tycoon.view().developing.bugs);
const resting = staffText(early, 'p1');
mustThrow(() => early.tycoon.crunch(), /The team is still tired\\./, 'tired');
if (staffText(early, 'p1') !== resting) fail('tired write');
early.endDay(2);
if (points(early).join(',') !== '4,4,4,2' || early.tycoon.view().developing.crunch.state !== 'idle' || staff(early, 'p1').crunch !== undefined || staff(early, 'p1').crunchBugs !== 1 || early.tycoon.view().researchPoints !== 2) fail(points(early));
early.tycoon.release('p1');
if (staff(early, 'p1').bugs !== 1 || early.tycoon.view().history[0].bugs !== 1) fail('stored');
if (!(early.tycoon.view().history[0].review.score < evenScore) || !(early.journey.state().company.cashCents < evenCash)) fail({ score: early.tycoon.view().history[0].review.score, cash: early.journey.state().company.cashCents });
early.close();

const tools = team('tools');
tools.tycoon.expandOffice();
tools.tycoon.buyUpgrade('standing_desk');
tools.tycoon.buyUpgrade('second_monitor');
tools.tycoon.buyUpgrade('ring_light');
tools.tycoon.start('crypto', 'newsletter', ['founder']);
tools.tycoon.setDayPlan('design');
tools.tycoon.crunch();
tools.endDay(1);
if (points(tools).join(',') !== '14,2,1,1' || tools.tycoon.view().developing.crunch.state !== 'resting') fail(points(tools));
tools.endDay(2);
if (points(tools).join(',') !== '16,4,2,2' || tools.tycoon.view().developing.crunch.state !== 'idle' || staff(tools, 'p1').crunch !== undefined || staff(tools, 'p1').crunchBugs !== 1) fail(points(tools));
tools.close();

const polish = open('polish');
polish.tycoon.start('crypto', 'newsletter', []);
for (let day = 1; day <= 4; day += 1) polish.endDay(day);
polish.tycoon.crunch();
polish.endDay(5);
if (points(polish).join(',') !== '8,8,8,5' || polish.tycoon.view().developing.crunch.state !== 'resting' || staff(polish, 'p1').crunchBugs !== 1 || polish.tycoon.view().developing.bugs.count !== 1 || polish.tycoon.view().researchPoints !== 5) fail(points(polish));
polish.close();

const both = open('both');
both.tycoon.start('crypto', 'newsletter', []);
both.tycoon.setDayPlan('design');
both.endDay(1);
both.tycoon.crunch();
both.tycoon.fixBugs();
both.endDay(2);
if (points(both).join(',') !== '6,0,0,2' || staff(both, 'p1').bugsCleared !== 3 || staff(both, 'p1').crunch !== 'resting' || staff(both, 'p1').crunchBugs !== 1 || staff(both, 'p1').fixBugs !== undefined) fail({ points: points(both), staff: staff(both, 'p1') });
both.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.tycoon.crunch();
const keptFile = root + '/kept/startup-valley.sqlite';
const keptProject = root + '/kept/company-project';
const keptJson = staffText(kept, 'p1');
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (staffText(reopened, 'p1') !== keptJson || reopened.tycoon.view().developing.crunch.state !== 'armed') fail('reopen');
reopened.endDay(1);
reopened.close();
const again = new GameDatabase(keptFile, keptProject);
if (again.tycoon.view().developing.crunch.state !== 'resting' || staff(again, 'p1').crunchBugs !== 1) fail('reopen rest');
again.endDay(2);
again.tycoon.release('p1');
finishSales(again);
again.tycoon.sequel('p1');
if (again.tycoon.view().developing.crunch.state !== 'idle' || staff(again, 'p2').crunch !== undefined || staff(again, 'p2').crunchBugs !== undefined || staff(again, 'p1').crunchBugs !== 1) fail('sequel');
again.close();
console.log('CRUNCH RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("IMPORT_VALIDATION", JSON.stringify(validation))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the crunch rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Crunch rules hold (%s)" % " ".join(output))
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
	check(label_named("CrunchOffer") == null and crunch_button() == null, "No crunch control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("CrunchOffer") == null and crunch_button() == null, "The build screen has no crunch control")
	await open_journey()
	var offer := label_named("CrunchOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var bugs := label_named("BugsOffer")
	check(card != null and offer != null and card.is_ancestor_of(offer) and offer.text == OFFER, "The developing card names the crunch offer")
	check(crunch_button() != null and not crunch_button().disabled and str(crunch_button().get_meta("cozy_variant", "")) == "secondary" and crunch_button().text == "Crunch", "Crunch is a secondary button")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside crunch")
	await reveal(offer)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(bugs != null and bugs.get_global_rect().end.y <= offer.get_global_rect().position.y + 1.0, "Crunch sits under Bugs")
	check(offer.get_global_rect().end.y <= crunch_button().get_global_rect().position.y + 1.0, "The crunch line sits above the button")
	check(crunch_button().get_global_rect().end.y <= footer.get_global_rect().position.y, "Crunch sits above Hire")
	check(new_product != null and crunch_button().get_global_rect().end.y <= new_product.get_global_rect().position.y, "Crunch sits above New Product")
	check(not crunch_button().get_global_rect().intersects(footer.get_global_rect()), "Crunch does not overlap Hire")
	check(not offer.get_global_rect().intersects(crunch_button().get_global_rect()), "The crunch line does not overlap the button")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("CrunchOffer") != null and label_named("CrunchOffer").text == OFFER, "Skipping Crunch keeps the offer line")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping Crunch still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping Crunch still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping Crunch keeps launch sales at 20700 cents")
		await open_journey()
		check(label_named("CrunchOffer") == null and crunch_button() == null, "The crunch control is gone after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300, "Reopening the even newsletter keeps 33300 cents")
	await start_newsletter()
	await open_journey()
	check(label_named("CrunchOffer") != null and label_named("CrunchOffer").text == OFFER, "The next product starts idle")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	var day_before := main.company_panel.day
	await click(crunch_button())
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("CrunchOffer") != null and label_named("CrunchOffer").text == ARMED
	, "Arming Crunch shows the crunching line")
	check(company_cash() == cash_before and company_reputation() == fans_before and main.company_panel.day == day_before and int(developing().get("devDays", -1)) == 0, "Crunch spends nothing")
	check(crunch_button() == null, "The Crunch button hides once armed")
	check(str(crunch_payload().get("state", "")) == "armed", "The worker stores the armed crunch")
	await end_office_day()
	await open_journey()
	check(label_named("CrunchOffer") != null and label_named("CrunchOffer").text == RESTING, "The next office day shows the resting line")
	check(crunch_button() == null, "Resting hides Crunch")
	check(int(developing().get("design", -1)) == 4 and int(developing().get("tech", -1)) == 4 and int(developing().get("hype", -1)) == 4, "The crunch day doubled personal craft")
	check(int(developing().get("devDays", -1)) == 1, "The crunch day still counts as an office day")
	check(str(crunch_payload().get("state", "")) == "resting", "The worker stores the rest day")
	check(int(bugs_payload().get("count", -1)) == 1, "The crunch day adds one live bug")
	await reveal(label_named("CrunchOffer"))
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	var resting := label_named("CrunchOffer")
	check(resting != null and new_product != null and resting.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Resting sits above New Product")
	check(footer != null and resting.get_global_rect().end.y <= footer.get_global_rect().position.y, "Resting sits above Hire")
	check(not resting.get_global_rect().intersects(new_product.get_global_rect()), "Resting does not overlap New Product")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(label_named("CrunchOffer") != null and label_named("CrunchOffer").text == RESTING, "Reopening keeps the resting line")
	check(str(crunch_payload().get("state", "")) == "resting", "Reopening keeps the resting crunch")
	check(int(developing().get("design", -1)) == 4, "Reopening keeps the doubled craft")
	print("TYCOON CRUNCH ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
