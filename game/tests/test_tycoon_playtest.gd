extends SceneTree

## Headless playtest with the real worker and an isolated company.
## Skipping it, and using it, both leave the balanced newsletter.

const MAIN := preload("res://world/main.tscn")
const WAITING := "Playtest · Work one office day first."
const OFFER := "Playtest · see the likely review band."
const RESULT := "Playtest: likely mid reviews"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-playtest-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func playtest_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("Playtest", true, false) as Button

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
		await wait_until(func() -> bool: return main.company_panel.screen == "product" and not main.company_panel.busy, "New Product opens the build screen")

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
	check(label_named("PlaytestOffer") == null and playtest_button() == null, "The product picker has no playtest control")
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

func connect_closed(note: String) -> void:
	check(main != null and main.job_panel != null and not main.job_panel._connection_panel.visible, note)

func secondary(button: Button) -> bool:
	return button != null and not button.disabled and str(button.get_meta("cozy_variant", "")) == "secondary"

func fits(control: Control, above: Control) -> bool:
	return control != null and above != null and control.get_global_rect().end.y <= above.get_global_rect().position.y + 1.0 and not control.get_global_rect().intersects(above.get_global_rect())

func inside_view(control: Control) -> bool:
	if control == null or main == null or main.company_panel == null:
		return false
	var view := main.company_panel._scroll.get_global_rect().grow(2.0)
	return view.encloses(control.get_global_rect())

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
	var validation := ProjectSettings.globalize_path("res://../harness/src/validation.ts")
	var tycoon := ProjectSettings.globalize_path("res://../harness/src/tycoon.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-playtest.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;
import { reviewBand } from IMPORT_TYCOON;

const root = process.argv[process.argv.length - 1];
const source = readFileSync(TYCOON_FILE, 'utf8');
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
function message(fn) {
  try { fn(); return ''; } catch (error) { return error.message; }
}
function mustThrow(fn, pattern, label) {
  const text = message(fn);
  if (!pattern.test(text)) fail({ label, text });
}
function txIds(db) {
  return db.journey.db.prepare('SELECT id FROM company_transactions ORDER BY id').all().map((row) => row.id);
}
const waiting = { enabled: false, band: null, reason: 'Work one office day first.' };
const start = source.indexOf('playtest():');
const slice = source.slice(start, source.indexOf('pivot(topicValue', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
mustThrow(() => parseRequest({ kind: 'request', id: 'playtest', method: 'tycoon.playtest', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'playtest', method: 'tycoon.playtest', params: {} }).method !== 'tycoon.playtest') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.playtest(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
if (JSON.stringify(skip.tycoon.view().developing.playtest) !== JSON.stringify(waiting)) fail(skip.tycoon.view().developing.playtest);
mustThrow(() => skip.tycoon.playtest(), /Work one office day first\\./, 'zero');
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].playtest !== null) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.playtest(), /No product is on the bench\\./, 'shipped');
skip.close();

const looked = open('looked');
looked.tycoon.start('crypto', 'newsletter', []);
looked.endDay(1);
looked.tycoon.playtest();
looked.endDay(2);
const before = JSON.stringify(txIds(looked));
const saved = JSON.stringify(staff(looked, 'p1'));
const block = looked.tycoon.view().developing.playtest;
looked.tycoon.playtest();
looked.tycoon.playtest();
const mid = looked.tycoon.view().developing;
if (mid.playtest.band !== 'mid' || mid.design !== 4 || mid.tech !== 4 || mid.hype !== 4 || mid.devDays !== 2) fail(mid.playtest);
if (JSON.stringify(txIds(looked)) !== before || JSON.stringify(staff(looked, 'p1')) !== saved || staff(looked, 'p1').playtest !== undefined) fail('ledger');
looked.tycoon.release('p1');
if (looked.journey.state().company.cashCents !== 20700 || looked.tycoon.view().history[0].fans !== 5 || reviewBand(looked.tycoon.view().history[0].review.score) !== 'mid') fail('release');
looked.endDay(3);
looked.endDay(4);
if (looked.journey.state().company.cashCents !== 33300) fail({ next: looked.journey.state().company.cashCents });
looked.close();

const low = open('low');
low.tycoon.start('crypto', 'newsletter', []);
low.tycoon.setDayPlan('design');
low.endDay(1);
low.endDay(2);
if (low.tycoon.view().developing.playtest.band !== 'low') fail(low.tycoon.view().developing.playtest);
low.tycoon.playtest();
low.tycoon.release('p1');
if (reviewBand(low.tycoon.view().history[0].review.score) !== 'low') fail('low-release');
low.close();

const high = open('high');
high.tycoon.start('crypto', 'newsletter', []);
high.endDay(1);
high.endDay(2);
high.endDay(3);
high.endDay(4);
if (high.tycoon.view().developing.playtest.band !== 'high') fail(high.tycoon.view().developing.playtest);
high.tycoon.playtest();
high.tycoon.release('p1');
if (reviewBand(high.tycoon.view().history[0].review.score) !== 'high') fail('high-release');
high.close();

const moved = open('pivot');
moved.tycoon.start('crypto', 'newsletter', []);
moved.endDay(1);
moved.endDay(2);
if (moved.tycoon.view().developing.playtest.band !== 'mid') fail('pre-pivot');
moved.tycoon.pivot('fitness', 'course');
const pivoted = moved.tycoon.view().developing;
if (pivoted.playtest.band !== 'low' || pivoted.design !== 4 || pivoted.devDays !== 2) fail(pivoted.playtest);
moved.close();

const pushed = open('crunch');
pushed.tycoon.start('crypto', 'newsletter', []);
pushed.endDay(1);
if (pushed.tycoon.view().developing.playtest.band !== 'low') fail('pre-crunch');
pushed.tycoon.crunch();
if (pushed.tycoon.view().developing.playtest.band !== 'low') fail('armed');
pushed.endDay(2);
if (pushed.tycoon.view().developing.playtest.band !== 'high') fail(pushed.tycoon.view().developing.playtest);
pushed.close();

const kept = open('reopen');
kept.tycoon.start('crypto', 'newsletter', []);
kept.endDay(1);
kept.endDay(2);
kept.tycoon.playtest();
const keptBlock = JSON.stringify(kept.tycoon.view().developing.playtest);
const keptFile = root + '/reopen/startup-valley.sqlite';
const keptProject = root + '/reopen/company-project';
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (JSON.stringify(reopened.tycoon.view().developing.playtest) !== keptBlock) fail('reopen');
reopened.close();
console.log('PLAYTEST RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the playtest rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Playtest rules hold (%s)" % " ".join(output))
	return code == 0

func layout_waiting(note: String) -> void:
	var line := label_named("PlaytestOffer")
	var pivot := main.company_panel.find_child("Pivot", true, false) as Button
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(line != null and line.text == WAITING and playtest_button() == null, note + " names the wait and hides Playtest")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays the one primary action")
	check(pivot != null and fits(pivot, line), note + " Playtest sits under Pivot")
	check(fits(line, new_product), note + " Playtest sits above New Product")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Playtest does not overlap Hire")
	check(inside_view(line) and inside_view(new_product), note + " Playtest and New Product stay inside the journey")
	check(line.get_line_count() == 1, note + " The playtest line stays on one line")

func layout_offer(note: String) -> void:
	var line := label_named("PlaytestOffer")
	var button := playtest_button()
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var pivot := main.company_panel.find_child("Pivot", true, false) as Button
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(card != null and line != null and button != null and card.is_ancestor_of(line) and card.is_ancestor_of(button) and line.text == OFFER, note + " names the playtest offer")
	check(secondary(button) and button.text == "Playtest", note + " Playtest is secondary")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays the one primary action")
	check(pivot != null and fits(pivot, line), note + " Playtest sits under Pivot")
	check(fits(line, button), note + " The playtest line sits above Playtest")
	check(fits(button, new_product), note + " Playtest sits above New Product")
	check(footer != null and not button.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Playtest does not overlap Hire")
	check(inside_view(line) and inside_view(button) and inside_view(new_product), note + " Playtest and New Product stay inside the journey")
	check(button.size.x + 1.0 >= button.get_combined_minimum_size().x, note + " Playtest text fits the button")
	check(line.get_line_count() == 1, note + " The playtest line stays on one line")

func layout_result(note: String) -> void:
	var line := label_named("PlaytestOffer")
	var button := playtest_button()
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(line != null and line.text == RESULT and secondary(button), note + " shows the mid band and keeps Playtest")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays primary after the look")
	check(fits(line, button) and fits(button, new_product), note + " The band line stays above Playtest and New Product")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()) and not button.get_global_rect().intersects(footer.get_global_rect()), note + " The band line does not overlap Hire")
	check(inside_view(line) and inside_view(button), note + " The band line stays inside the journey")
	check(line.get_line_count() == 1, note + " The band line stays on one line")

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
	check(label_named("PlaytestOffer") == null and playtest_button() == null, "No playtest control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("PlaytestOffer") == null and playtest_button() == null, "The build screen has no playtest control")
	await open_journey()
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var stripped_product: Dictionary = stripped_tycoon.get("developing", {}).duplicate(true)
	stripped_product.erase("playtest")
	stripped_tycoon["developing"] = stripped_product
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("PlaytestOffer") == null and playtest_button() == null, "A payload without playtest draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(label_named("PlaytestOffer"))
	layout_waiting("Day 0")
	var block: Dictionary = developing().get("playtest", {}) if developing().get("playtest") is Dictionary else {}
	check(not bool(block.get("enabled", true)) and block.get("band") == null and str(block.get("reason", "")) == "Work one office day first.", "Day 0 playtest is waiting")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	await reveal(label_named("PlaytestOffer"))
	layout_offer("After two office days")
	var offer: Dictionary = developing().get("playtest", {}) if developing().get("playtest") is Dictionary else {}
	check(bool(offer.get("enabled", false)) and str(offer.get("band", "")) == "mid" and str(offer.get("reason", "x")) == "", "Two even days are a mid band")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	var days_before := int(developing().get("devDays", -1))
	await click(playtest_button())
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("PlaytestOffer") != null and label_named("PlaytestOffer").text == RESULT
	, "Playtest shows the likely mid band")
	if shown:
		await frames(3)
		await reveal(label_named("PlaytestOffer"))
		layout_result("After the look")
		check(company_cash() == cash_before and company_reputation() == fans_before and int(developing().get("devDays", -1)) == days_before, "Playtest spends nothing and adds no day")
		check(int(developing().get("design", -1)) == 4 and int(developing().get("tech", -1)) == 4 and int(developing().get("hype", -1)) == 4, "Playtest leaves the points")
		await click(playtest_button())
		await wait_until(func() -> bool:
			return not main.company_panel.busy and label_named("PlaytestOffer") != null and label_named("PlaytestOffer").text == RESULT
		, "Looking again keeps the current band")
	connect_closed("Connect stays closed after the look")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("PlaytestOffer"))
	layout_offer("Reopened")
	var kept: Dictionary = developing().get("playtest", {}) if developing().get("playtest") is Dictionary else {}
	check(str(kept.get("band", "")) == "mid" and bool(kept.get("enabled", false)) and int(developing().get("devDays", -1)) == 2, "Reopening keeps the same playtest block")
	check(company_cash() == 0 and company_reputation() == 0, "Reopening keeps the cash and fans")
	connect_closed("Connect stays closed after reopen")
	print("TYCOON PLAYTEST ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
