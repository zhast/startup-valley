extends SceneTree

## Headless day plan with the real worker and an isolated company.
## Skipping it leaves the first newsletter alone. An emphasis folds that day's personal craft.

const MAIN := preload("res://world/main.tscn")
const EVEN := "Day plan · Even · design, tech, and hype as usual"
const DESIGN_LINE := "Day plan · Design · today's craft goes to design"
const TECH_LINE := "Day plan · Tech · today's craft goes to tech"
const HYPE_LINE := "Day plan · Hype · today's craft goes to hype"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-day-plan-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func plan_button(id: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("DayPlan_" + id, true, false) as Button

func plan_pressed(button: Button) -> bool:
	if button == null:
		return false
	var box := button.get_theme_stylebox("normal")
	return box is StyleBoxTexture and str((box as StyleBoxTexture).texture.resource_path).ends_with("pressed.png")

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

func plan_stat() -> String:
	var value: Variant = developing().get("dayPlan", null)
	if value is Dictionary:
		return str((value as Dictionary).get("stat", ""))
	return ""

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
	check(label_named("DayPlanOffer") == null and plan_button("design") == null, "The product picker has no day plan")
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
	var script_path := root.path_join("check-day-plan.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { DAY_PLANS, personalForDayPlan } from IMPORT_TYCOON;
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
function dayPlanRows(db) {
  return db.journey.db.prepare('SELECT id FROM company_transactions').all().filter((row) => String(row.id).startsWith('tycoon:dayplan'));
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

if (DAY_PLANS.map((item) => item.id).join(',') !== 'even,design,tech,hype') fail(DAY_PLANS);
const same = personalForDayPlan({ design: 2, tech: 2, hype: 2 }, null);
if (same.design !== 2 || same.tech !== 2 || same.hype !== 2) fail(same);
const folded = personalForDayPlan({ design: 2, tech: 2, hype: 2 }, 'design');
if (folded.design !== 6 || folded.tech !== 0 || folded.hype !== 0) fail(folded);
const mina = personalForDayPlan({ design: 3, tech: 2, hype: 1 }, 'tech');
if (mina.design !== 0 || mina.tech !== 6 || mina.hype !== 0) fail(mina);
mustThrow(() => parseRequest({ kind: 'request', id: 'day-plan', method: 'tycoon.setDayPlan', params: {} }), /Invalid protocol request/, 'empty');
mustThrow(() => parseRequest({ kind: 'request', id: 'day-plan', method: 'tycoon.setDayPlan', params: { stat: 'balanced' } }), /Invalid protocol request/, 'balanced');
mustThrow(() => parseRequest({ kind: 'request', id: 'day-plan', method: 'tycoon.setDayPlan', params: { stat: 'design', extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'day-plan', method: 'tycoon.setDayPlan', params: { stat: 'design' } }).method !== 'tycoon.setDayPlan') fail('parse');

const bare = open('bare');
if (bare.tycoon.view().dayPlanOptions.map((item) => item.id).join(',') !== 'even,design,tech,hype') fail('options');
mustThrow(() => bare.tycoon.setDayPlan('balanced'), /Pick Even, Design, Tech, or Hype\\./, 'bad');
mustThrow(() => bare.tycoon.setDayPlan('design'), /No product is on the bench\\./, 'bare');
if (bare.tycoon.view().developing !== null) fail('developing');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
const fresh = staffText(skip, 'p1');
if (skip.tycoon.view().developing.dayPlan !== null || staff(skip, 'p1').dayPlan !== undefined) fail(staff(skip, 'p1'));
skip.tycoon.setDayPlan('even');
if (staffText(skip, 'p1') !== fresh) fail('even rewrite');
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].dayPlan !== null || staff(skip, 'p1').dayPlan !== undefined) fail({ cash: skip.journey.state().company.cashCents, fans: skip.tycoon.view().history[0].fans });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.setDayPlan('hype'), /No product is on the bench\\./, 'shipped');
if (dayPlanRows(skip).length !== 0) fail('rows');
skip.close();

const fold = open('fold');
fold.tycoon.start('crypto', 'newsletter', []);
const beforeSet = staffText(fold, 'p1');
mustThrow(() => fold.tycoon.setDayPlan('nope'), /Pick Even, Design, Tech, or Hype\\./, 'nope');
if (staffText(fold, 'p1') !== beforeSet) fail('nope rewrite');
const cash = fold.journey.state().company.cashCents;
const tx = txCount(fold);
const clock = fold.clockState().day;
fold.tycoon.setDayPlan('design');
if (fold.clockState().day !== clock || fold.journey.state().company.cashCents !== cash || txCount(fold) !== tx || dayPlanRows(fold).length !== 0) fail('set cost');
const designPlan = fold.tycoon.view().developing.dayPlan;
if (!designPlan || designPlan.id !== 'design' || designPlan.label !== 'Design' || designPlan.stat !== 'design' || staff(fold, 'p1').dayPlan !== 'design') fail(designPlan);
const stored = staffText(fold, 'p1');
fold.tycoon.setDayPlan('design');
fold.tycoon.view();
if (staffText(fold, 'p1') !== stored) fail('idempotent');
fold.endDay(1);
if (points(fold).join(',') !== '6,0,0,1') fail(points(fold));
fold.tycoon.setDayPlan('tech');
if (fold.tycoon.view().developing.dayPlan.stat !== 'tech') fail('tech plan');
fold.endDay(2);
if (points(fold).join(',') !== '6,6,0,2') fail(points(fold));
fold.tycoon.setDayPlan('hype');
fold.endDay(3);
if (points(fold).join(',') !== '6,6,6,3') fail(points(fold));
fold.tycoon.setDayPlan('even');
if (fold.tycoon.view().developing.dayPlan !== null || staff(fold, 'p1').dayPlan !== undefined) fail('cleared');
fold.endDay(4);
if (points(fold).join(',') !== '8,8,8,4') fail(points(fold));
fold.close();

const tools = team('tools');
tools.tycoon.expandOffice();
tools.tycoon.buyUpgrade('standing_desk');
tools.tycoon.buyUpgrade('second_monitor');
tools.tycoon.buyUpgrade('ring_light');
tools.tycoon.start('crypto', 'newsletter', ['founder']);
tools.tycoon.setDayPlan('design');
tools.endDay(1);
if (points(tools).join(',') !== '8,2,1,1') fail({ tools: points(tools) });
tools.tycoon.setDayPlan('tech');
tools.endDay(2);
if (points(tools).join(',') !== '10,10,2,2') fail(points(tools));
tools.tycoon.setDayPlan('hype');
tools.endDay(3);
if (points(tools).join(',') !== '12,12,9,3') fail(points(tools));
tools.close();

const plain = team('plain');
plain.tycoon.expandOffice();
plain.tycoon.buyUpgrade('standing_desk');
plain.tycoon.buyUpgrade('second_monitor');
plain.tycoon.buyUpgrade('ring_light');
plain.tycoon.start('crypto', 'newsletter', ['founder']);
plain.endDay(1);
if (points(plain).join(',') !== '4,4,3,1' || staff(plain, 'p1').dayPlan !== undefined) fail(points(plain));
plain.close();

const trained = open('trained');
trained.journey.recordCompanyChange('dayplan-train-cash', 1, 40000, 0, 0, 'Day plan train cash');
trained.journey.hire('mira', 1);
trained.tycoon.start('crypto', 'newsletter', ['mira']);
trained.tycoon.setDayPlan('design');
trained.tycoon.train('founder', 'tech');
trained.endDay(1);
if (points(trained).join(',') !== '6,0,0,1') fail({ trained: points(trained) });
trained.endDay(2);
if (trained.tycoon.view().developing.design !== 18 || trained.tycoon.view().developing.tech !== 0 || trained.tycoon.view().developing.hype !== 0) fail(points(trained));
trained.close();

const polish = open('polish');
polish.tycoon.start('crypto', 'newsletter', []);
for (let day = 1; day <= 4; day += 1) polish.endDay(day);
if (points(polish).join(',') !== '8,8,8,4') fail(points(polish));
polish.tycoon.setDayPlan('design');
polish.endDay(5);
if (points(polish).join(',') !== '8,8,8,5') fail(points(polish));
polish.close();

const emphasized = open('emphasized');
emphasized.tycoon.start('crypto', 'newsletter', []);
emphasized.tycoon.setDayPlan('hype');
for (let day = 1; day <= 5; day += 1) emphasized.endDay(day);
if (points(emphasized).join(',') !== '0,0,24,5') fail(points(emphasized));
emphasized.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.tycoon.setDayPlan('tech');
const keptFile = root + '/kept/startup-valley.sqlite';
const keptProject = root + '/kept/company-project';
const keptJson = staffText(kept, 'p1');
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (staffText(reopened, 'p1') !== keptJson || reopened.tycoon.view().developing.dayPlan.stat !== 'tech') fail('reopen');
reopened.tycoon.setDayPlan('tech');
if (staffText(reopened, 'p1') !== keptJson) fail('reopen idempotent');
reopened.endDay(1);
if (points(reopened).join(',') !== '0,6,0,1') fail(points(reopened));
mustThrow(() => reopened.tycoon.release('p1'), /needs 1 more office day/, 'early');
reopened.endDay(2);
reopened.tycoon.release('p1');
if (reopened.tycoon.view().history[0].dayPlan !== null || staff(reopened, 'p1').dayPlan !== 'tech') fail('released view');
finishSales(reopened);
reopened.tycoon.sequel('p1');
if (reopened.tycoon.view().developing.dayPlan !== null || staff(reopened, 'p2').dayPlan !== undefined || staff(reopened, 'p1').dayPlan !== 'tech') fail('sequel');
reopened.close();
console.log('DAY PLAN RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("IMPORT_VALIDATION", JSON.stringify(validation))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the day plan rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Day plan rules hold (%s)" % " ".join(output))
	return code == 0

func choices_are_secondary() -> void:
	var ids: Array[String] = ["even", "design", "tech", "hype"]
	var labels: Array[String] = ["Even", "Design", "Tech", "Hype"]
	var line := label_named("DayPlanOffer")
	var previous_end := 0.0 if line == null else line.get_global_rect().position.x
	for index: int in range(ids.size()):
		var choice := plan_button(ids[index])
		check(choice != null and choice.text == labels[index] and not choice.disabled and str(choice.get_meta("cozy_variant", "")) == "secondary", "Day plan %s is a secondary choice" % labels[index])
		if choice == null:
			continue
		check(choice.get_global_rect().position.x >= previous_end - 1.0, "Day plan choices sit in one row")
		if line != null:
			check(choice.get_global_rect().position.y >= line.get_global_rect().end.y - 2.0, "Day plan choices sit under the line")
		previous_end = choice.get_global_rect().end.x

func click_plan(id: String, expected_text: String, expected_stat: String) -> void:
	var cash_before := company_cash()
	var fans_before := company_reputation()
	var day_before := main.company_panel.day
	var dev_before := int(developing().get("devDays", -1))
	await click(plan_button(id))
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == expected_text
	, "Day plan " + id + " updates the line")
	check(company_cash() == cash_before and company_reputation() == fans_before and main.company_panel.day == day_before and int(developing().get("devDays", -1)) == dev_before, "Day plan " + id + " spends nothing")
	check(plan_stat() == expected_stat, "The worker stores the " + id + " plan")
	check(main.company_panel._notice.text.is_empty(), "Day plan " + id + " shows no error")

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
	check(label_named("DayPlanOffer") == null and plan_button("even") == null, "No day plan before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("DayPlanOffer") == null and plan_button("design") == null, "The build screen has no day plan")
	await open_journey()
	var offer := label_named("DayPlanOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var choices := main.company_panel.find_child("DayPlanChoices", true, false) as Control
	check(card != null and offer != null and choices != null and card.is_ancestor_of(offer) and card.is_ancestor_of(choices) and offer.text == EVEN, "The developing card names the even day plan")
	choices_are_secondary()
	check(plan_pressed(plan_button("even")), "Even starts pressed")
	check(not plan_pressed(plan_button("design")), "Design starts unpressed")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the day plan")
	check(button_named("Sign publisher") != null and str(button_named("Sign publisher").get_meta("cozy_variant", "")) == "secondary", "Sign publisher stays secondary")
	check(button_named("Show preview") != null and str(button_named("Show preview").get_meta("cozy_variant", "")) == "secondary", "Show preview stays secondary")
	check(button_named("Add feature") != null and str(button_named("Add feature").get_meta("cozy_variant", "")) == "secondary", "Add feature stays secondary")
	await reveal(offer)
	var footer := main.company_panel._footer
	var even := plan_button("even")
	var new_product := button_named("New Product")
	check(even != null and footer != null and even.get_global_rect().end.y <= footer.get_global_rect().position.y, "Day plan sits above Hire")
	check(new_product != null and even.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Day plan sits above New Product")
	await click_plan("even", EVEN, "")
	check(int(developing().get("devDaysRequired", 0)) == 2 and company_cash() == 0, "Even leaves the two-day build and the cash")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == EVEN and plan_stat().is_empty(), "Skipping the day plan keeps Even")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the day plan still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the day plan still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the day plan keeps launch sales at 20700 cents")
		check(latest_shipped().get("dayPlan") == null, "A released product hides the day plan")
		await open_journey()
		check(label_named("DayPlanOffer") == null and plan_button("design") == null, "The day plan is gone after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "An even newsletter stays on the old total")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300 and int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening the even newsletter keeps 33300 cents")
	check(label_named("DayPlanOffer") == null, "Reopening a shipped product has no day plan")
	await start_newsletter()
	await open_journey()
	check(label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == EVEN, "The next product starts Even")
	await click_plan("design", DESIGN_LINE, "design")
	await click_plan("design", DESIGN_LINE, "design")
	check(plan_button("design") != null and plan_pressed(plan_button("design")) and str(plan_button("design").get_meta("cozy_variant", "")) == "secondary", "Design stays a pressed secondary choice")
	await click_plan("tech", TECH_LINE, "tech")
	await click_plan("hype", HYPE_LINE, "hype")
	await click_plan("even", EVEN, "")
	await click_plan("design", DESIGN_LINE, "design")
	await end_office_day()
	await open_journey()
	check(label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == DESIGN_LINE, "The design plan sticks after the office day")
	check(int(developing().get("design", -1)) == 6 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "The design day folds personal craft to 6/0/0")
	check(int(developing().get("devDays", -1)) == 1, "The design day still counts as one office day")
	var saved_cash := company_cash()
	var saved_fans := company_reputation()
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == DESIGN_LINE and plan_stat() == "design", "Reopening keeps the design plan")
	check(int(developing().get("design", -1)) == 6 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "Reopening keeps the folded points")
	check(company_cash() == saved_cash and company_reputation() == saved_fans, "Reopening does not sell the day again")
	print("TYCOON DAY PLAN ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
