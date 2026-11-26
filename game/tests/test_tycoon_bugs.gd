extends SceneTree

## Headless bugs with the real worker and an isolated company.
## A balanced founder newsletter stays at 0 bugs. Fix bugs spends tomorrow's craft.

const MAIN := preload("res://world/main.tscn")
const BALANCED := "Bugs · 0 · build looks balanced"
const OFFER := "Bugs · 1 · Fix bugs spends tomorrow's craft"
const FIXING := "Fixing bugs · next office day clears craft into bugfix"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-bugs-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func fix_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("FixBugs", true, false) as Button

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
	check(label_named("BugsOffer") == null and fix_button() == null, "The product picker has no bugs control")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")

func boot() -> bool:
	main = MAIN.instantiate()
	main.demo_story_mode = false
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
	var script_path := root.path_join("check-bugs.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { bugCount, bugsClearedGain } from IMPORT_TYCOON;
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
function bugRows(db) {
  return db.journey.db.prepare('SELECT id FROM company_transactions').all().filter((row) => String(row.id).startsWith('tycoon:bugs') || String(row.id).startsWith('tycoon:fixBugs'));
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
function bugs(db) {
  return db.tycoon.view().developing.bugs;
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

if (bugCount({ design: 4, tech: 4, hype: 4 }) !== 0) fail('balanced');
if (bugCount({ design: 12, tech: 0, hype: 0 }) !== 3) fail('lopsided');
if (bugsClearedGain(6) !== 1 || bugsClearedGain(0) !== 0) fail('gain');
mustThrow(() => parseRequest({ kind: 'request', id: 'bugs', method: 'tycoon.fixBugs', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'bugs', method: 'tycoon.fixBugs', params: {} }).method !== 'tycoon.fixBugs') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.fixBugs(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
if (JSON.stringify(bugs(skip)) !== JSON.stringify({ count: 0, cleared: 0, fixing: false })) fail(bugs(skip));
mustThrow(() => skip.tycoon.fixBugs(), /No bugs to fix\\./, 'zero');
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].bugs !== null || staff(skip, 'p1').bugs !== undefined) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.fixBugs(), /No product is on the bench\\./, 'shipped');
if (bugRows(skip).length !== 0) fail('rows');
skip.close();

const even = open('even');
even.tycoon.start('crypto', 'newsletter', []);
even.endDay(1);
even.endDay(2);
even.tycoon.release('p1');
const evenCash = even.journey.state().company.cashCents;
const evenScore = even.tycoon.view().history[0].review.score;
even.close();

const lop = open('lop');
lop.tycoon.start('crypto', 'newsletter', []);
lop.tycoon.setDayPlan('design');
lop.endDay(1);
if (JSON.stringify(bugs(lop)) !== JSON.stringify({ count: 1, cleared: 0, fixing: false }) || points(lop).join(',') !== '6,0,0,1') fail({ bugs: bugs(lop), points: points(lop) });
lop.endDay(2);
if (JSON.stringify(bugs(lop)) !== JSON.stringify({ count: 3, cleared: 0, fixing: false }) || points(lop).join(',') !== '12,0,0,2') fail(bugs(lop));
const cash = lop.journey.state().company.cashCents;
const tx = txCount(lop);
const clock = lop.clockState().day;
lop.tycoon.fixBugs();
if (lop.clockState().day !== clock || lop.journey.state().company.cashCents !== cash || txCount(lop) !== tx || bugRows(lop).length !== 0) fail('set cost');
if (JSON.stringify(bugs(lop)) !== JSON.stringify({ count: 3, cleared: 0, fixing: true }) || staff(lop, 'p1').fixBugs !== true) fail(bugs(lop));
const armed = staffText(lop, 'p1');
lop.tycoon.fixBugs();
lop.tycoon.view();
if (staffText(lop, 'p1') !== armed) fail('idempotent');
lop.endDay(3);
if (points(lop).join(',') !== '12,0,0,3') fail(points(lop));
if (JSON.stringify(bugs(lop)) !== JSON.stringify({ count: 2, cleared: 1, fixing: false }) || staff(lop, 'p1').bugsCleared !== 1 || staff(lop, 'p1').fixBugs !== undefined) fail(bugs(lop));
lop.tycoon.release('p1');
if (staff(lop, 'p1').bugs !== 2 || lop.tycoon.view().history[0].bugs !== 2) fail('stored');
if (!(lop.tycoon.view().history[0].review.score < evenScore) || !(lop.journey.state().company.cashCents < evenCash)) fail({ score: lop.tycoon.view().history[0].review.score, cash: lop.journey.state().company.cashCents });
lop.close();

const tools = team('tools');
tools.tycoon.expandOffice();
tools.tycoon.buyUpgrade('standing_desk');
tools.tycoon.buyUpgrade('second_monitor');
tools.tycoon.buyUpgrade('ring_light');
tools.tycoon.start('crypto', 'newsletter', ['founder']);
tools.tycoon.setDayPlan('design');
tools.endDay(1);
if (points(tools).join(',') !== '8,2,1,1') fail(points(tools));
tools.tycoon.fixBugs();
tools.endDay(2);
if (points(tools).join(',') !== '10,4,2,2') fail(points(tools));
if (JSON.stringify(bugs(tools)) !== JSON.stringify({ count: 1, cleared: 1, fixing: false })) fail(bugs(tools));
tools.close();

const polish = open('polish');
polish.tycoon.start('crypto', 'newsletter', []);
polish.tycoon.setDayPlan('design');
for (let day = 1; day <= 4; day += 1) polish.endDay(day);
if (JSON.stringify(bugs(polish)) !== JSON.stringify({ count: 5, cleared: 0, fixing: false })) fail(bugs(polish));
polish.tycoon.fixBugs();
polish.endDay(5);
if (points(polish).join(',') !== '24,0,0,5' || JSON.stringify(bugs(polish)) !== JSON.stringify({ count: 5, cleared: 0, fixing: false }) || staff(polish, 'p1').fixBugs !== undefined) fail(bugs(polish));
polish.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.tycoon.setDayPlan('design');
kept.endDay(1);
kept.endDay(2);
kept.tycoon.fixBugs();
kept.endDay(3);
const keptFile = root + '/kept/startup-valley.sqlite';
const keptProject = root + '/kept/company-project';
const keptJson = staffText(kept, 'p1');
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (staffText(reopened, 'p1') !== keptJson || JSON.stringify(bugs(reopened)) !== JSON.stringify({ count: 2, cleared: 1, fixing: false })) fail('reopen');
reopened.tycoon.release('p1');
finishSales(reopened);
reopened.tycoon.sequel('p1');
if (JSON.stringify(bugs(reopened)) !== JSON.stringify({ count: 0, cleared: 0, fixing: false }) || staff(reopened, 'p2').bugsCleared !== undefined || staff(reopened, 'p1').bugs !== 2) fail('sequel');
reopened.close();
console.log('BUGS RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("IMPORT_VALIDATION", JSON.stringify(validation))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the bugs rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Bugs rules hold (%s)" % " ".join(output))
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
	check(label_named("BugsOffer") == null and fix_button() == null, "No bugs control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("BugsOffer") == null and fix_button() == null, "The build screen has no bugs control")
	await open_journey()
	var offer := label_named("BugsOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	check(card != null and offer != null and card.is_ancestor_of(offer) and offer.text == BALANCED, "The developing card names balanced bugs")
	check(fix_button() == null, "Balanced builds hide Fix bugs")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside bugs")
	await reveal(offer)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(offer != null and footer != null and offer.get_global_rect().end.y <= footer.get_global_rect().position.y, "Bugs sits above Hire")
	check(new_product != null and offer.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Bugs sits above New Product")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == BALANCED, "Skipping Fix bugs keeps a balanced line")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping Fix bugs still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping Fix bugs still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping Fix bugs keeps launch sales at 20700 cents")
		check(latest_shipped().get("bugs") == null, "A balanced release stores no bugs")
		await open_journey()
		check(label_named("BugsOffer") == null and fix_button() == null, "The bugs control is gone after release")
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
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == BALANCED, "The next product starts balanced")
	var design := main.company_panel.find_child("DayPlan_design", true, false) as Button
	await click(design)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == "Day plan · Design · today's craft goes to design"
	, "Design day plan is set")
	await end_office_day()
	await open_journey()
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == OFFER, "A design day shows one live bug")
	check(fix_button() != null and not fix_button().disabled and str(fix_button().get_meta("cozy_variant", "")) == "secondary", "Fix bugs is a secondary button")
	check(int(bugs_payload().get("count", -1)) == 1 and int(bugs_payload().get("cleared", -1)) == 0 and not bool(bugs_payload().get("fixing", true)), "The worker stores one live bug")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	var day_before := main.company_panel.day
	var dev_before := int(developing().get("devDays", -1))
	await click(fix_button())
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("BugsOffer") != null and label_named("BugsOffer").text == FIXING
	, "Arming Fix bugs shows the fixing line")
	check(company_cash() == cash_before and company_reputation() == fans_before and main.company_panel.day == day_before and int(developing().get("devDays", -1)) == dev_before, "Fix bugs spends nothing")
	check(fix_button() == null, "The Fix bugs button hides once armed")
	check(bool(bugs_payload().get("fixing", false)), "The worker stores the armed fix")
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == FIXING, "The fixing line stays after arming")
	await end_office_day()
	await open_journey()
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == BALANCED, "The fix day clears the live bug")
	check(int(developing().get("design", -1)) == 6 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "The fix day adds no personal craft")
	check(int(developing().get("devDays", -1)) == 2, "The fix day still counts as an office day")
	check(int(bugs_payload().get("count", -1)) == 0 and int(bugs_payload().get("cleared", -1)) == 1 and not bool(bugs_payload().get("fixing", true)), "The worker stores one cleared bug")
	check(fix_button() == null, "A cleared build hides Fix bugs")
	var saved_cash := company_cash()
	var saved_fans := company_reputation()
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(label_named("BugsOffer") != null and label_named("BugsOffer").text == BALANCED, "Reopening keeps the cleared bugs line")
	check(int(bugs_payload().get("cleared", -1)) == 1, "Reopening keeps bugsCleared")
	check(company_cash() == saved_cash and company_reputation() == saved_fans, "Reopening does not sell the day again")
	print("TYCOON BUGS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
