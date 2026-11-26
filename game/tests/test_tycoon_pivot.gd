extends SceneTree

## Headless pivot with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. One pivot changes the pair.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Pivot · change topic or type. Days and points stay."
const PICKING := "Pivot · pick a new topic or type."
const DONE := "Pivoted · Fitness Course"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-pivot-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func pivot_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("Pivot", true, false) as Button

func change_pair_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("ChangePair", true, false) as Button

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

func start_newsletter() -> void:
	await open_product()
	check(label_named("PivotOffer") == null and pivot_button() == null, "The product picker has no pivot control")
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
	var script_path := root.path_join("check-pivot.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;

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
function pivotRows(db) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pivot%'").all();
}
const idle = { enabled: true, used: false, reason: '' };
const used = { enabled: false, used: true, reason: '' };
const start = source.indexOf('pivot(topicValue');
const slice = source.slice(start, source.indexOf('addFeature():', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
mustThrow(() => parseRequest({ kind: 'request', id: 'pivot', method: 'tycoon.pivot', params: {} }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'pivot', method: 'tycoon.pivot', params: { topicId: 'fitness', typeId: 'course' } }).method !== 'tycoon.pivot') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.pivot('fitness', 'course'), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
const skipBlock = skip.tycoon.view().developing.pivot;
if (skipBlock.enabled !== idle.enabled || skipBlock.used !== idle.used || skipBlock.reason !== idle.reason) fail(skipBlock);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].pivot !== null) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || pivotRows(skip).length !== 0) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.pivot('fitness', 'course'), /No product is on the bench\\./, 'shipped');
skip.close();

const same = open('same');
same.tycoon.start('crypto', 'newsletter', []);
mustThrow(() => same.tycoon.pivot('crypto', 'newsletter'), /Pick a new topic or type\\./, 'same');
same.close();

const locked = open('locked');
locked.tycoon.start('crypto', 'newsletter', []);
mustThrow(() => locked.tycoon.pivot('sneakers', 'newsletter'), /Sneakers is locked\\. Research it first\\./, 'topic');
mustThrow(() => locked.tycoon.pivot('crypto', 'software'), /Software Tool is locked\\. Research it first\\./, 'type');
locked.close();

const change = open('change');
change.tycoon.start('crypto', 'newsletter', []);
change.endDay(1);
const before = JSON.stringify(txIds(change));
change.tycoon.pivot('fitness', 'course');
if (change.clockState().day !== 2 || change.journey.state().company.cashCents !== 0 || JSON.stringify(txIds(change)) !== before || pivotRows(change).length !== 0) fail('ledger');
const moved = change.tycoon.view().developing;
if (moved.name !== 'Fitness Course' || moved.fit !== 'great' || moved.devDays !== 1 || moved.design !== 2 || moved.tech !== 2 || moved.hype !== 2) fail(moved);
if (moved.pivot.enabled !== used.enabled || moved.pivot.used !== used.used || staff(change, 'p1').pivoted !== true) fail(moved.pivot);
mustThrow(() => change.tycoon.pivot('cooking', 'newsletter'), /Already pivoted\\./, 'second');
const changeFile = root + '/change/startup-valley.sqlite';
const changeProject = root + '/change/company-project';
change.close();
const reopened = new GameDatabase(changeFile, changeProject);
const kept = reopened.tycoon.view().developing;
if (kept.name !== 'Fitness Course' || kept.fit !== 'great' || kept.devDays !== 1 || staff(reopened, 'p1').pivoted !== true || kept.pivot.used !== true) fail('reopen');
reopened.close();

const review = open('review');
review.tycoon.start('crypto', 'newsletter', []);
review.endDay(1);
review.endDay(2);
review.tycoon.pivot('fitness', 'newsletter');
if (review.tycoon.view().developing.name !== 'Fitness Newsletter' || review.tycoon.view().developing.fit !== 'okay' || review.tycoon.view().developing.devDays !== 2) fail('fit');
review.tycoon.release('p1');
if (review.tycoon.view().history[0].fit !== 'okay' || review.tycoon.view().history[0].salesCents === 20700 || review.tycoon.view().history[0].pivot !== null) fail(review.tycoon.view().history[0]);
review.close();

const deal = open('deal');
const offer = deal.tycoon.view().contract;
deal.tycoon.acceptContract();
deal.tycoon.start(offer.topicId, offer.typeId, []);
mustThrow(() => deal.tycoon.pivot(offer.topicId === 'fitness' ? 'crypto' : 'fitness', offer.typeId === 'course' ? 'newsletter' : 'course'), new RegExp('This contract is ' + offer.topicName + ' × ' + offer.typeName + '\\\\.'));
if (deal.tycoon.view().developing.pivot.enabled !== false || deal.tycoon.view().developing.pivot.used !== false) fail(deal.tycoon.view().developing.pivot);
deal.close();
console.log('PIVOT RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the pivot rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Pivot rules hold (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var line := label_named("PivotOffer")
	var button := pivot_button()
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var slip := main.company_panel.find_child("SlipDay", true, false) as Button
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(card != null and line != null and button != null and card.is_ancestor_of(line) and card.is_ancestor_of(button) and line.text == OFFER, note + " names the pivot offer")
	check(secondary(button) and button.text == "Pivot", note + " Pivot is secondary")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays the one primary action")
	check(slip != null and fits(slip, line), note + " Pivot sits under Slip a day")
	check(fits(line, button), note + " The pivot line sits above Pivot")
	check(fits(button, new_product), note + " Pivot sits above New Product")
	check(footer != null and not button.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Pivot does not overlap Hire")
	check(inside_view(line) and inside_view(button) and inside_view(new_product), note + " Pivot and New Product stay inside the journey")
	check(button.size.x + 1.0 >= button.get_combined_minimum_size().x, note + " Pivot text fits the button")
	check(line.get_line_count() == 1, note + " The pivot line stays on one line")

func layout_picker(note: String) -> void:
	var line := label_named("PivotOffer")
	var topics := main.company_panel.find_child("PivotTopics", true, false) as Control
	var types := main.company_panel.find_child("PivotTypes", true, false) as Control
	var confirm := change_pair_button()
	var new_product := button_named("New Product")
	var hire := button_named("Hire Mina")
	var footer := main.company_panel._footer
	check(line != null and line.text == PICKING and pivot_button() == null, note + " shows the picker and hides Pivot")
	check(topics != null and types != null and confirm != null, note + " shows topic, type, and Change pair")
	check(secondary(confirm) or (confirm != null and str(confirm.get_meta("cozy_variant", "")) == "secondary"), note + " Change pair is secondary")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays primary in the picker")
	check(footer != null and confirm != null and not confirm.get_global_rect().intersects(footer.get_global_rect()), note + " Change pair does not overlap Hire")
	check(new_product != null and confirm.get_global_rect().end.y <= new_product.get_global_rect().position.y + 1.0, note + " Change pair sits above New Product")

func layout_done(note: String) -> void:
	var line := label_named("PivotOffer")
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(line != null and line.text == DONE and pivot_button() == null and change_pair_button() == null, note + " shows Pivoted and hides the controls")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays primary after the pivot")
	check(fits(line, new_product), note + " Pivoted sits above New Product")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Pivoted does not overlap Hire")
	check(inside_view(line) and inside_view(new_product), note + " Pivoted stays inside the journey")

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
	check(label_named("PivotOffer") == null and pivot_button() == null, "No pivot control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("PivotOffer") == null and pivot_button() == null, "The build screen has no pivot control")
	await open_journey()
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var stripped_product: Dictionary = stripped_tycoon.get("developing", {}).duplicate(true)
	stripped_product.erase("pivot")
	stripped_tycoon["developing"] = stripped_product
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("PivotOffer") == null and pivot_button() == null, "A payload without pivot draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(label_named("PivotOffer"))
	layout_offer("Day 0")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(pivot_button())
	var picking := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("PivotOffer") != null and label_named("PivotOffer").text == PICKING and change_pair_button() != null
	, "Pivot opens the topic and type picker")
	if picking:
		await frames(3)
		await reveal(label_named("PivotOffer"))
		layout_picker("Picking")
		check(change_pair_button() != null and change_pair_button().disabled, "Change pair stays disabled on the same pair")
		var fitness := main.company_panel.find_child("PivotTopic_fitness", true, false) as Button
		await click(fitness)
		var course := main.company_panel.find_child("PivotType_course", true, false) as Button
		await click(course)
		await wait_until(func() -> bool:
			return change_pair_button() != null and not change_pair_button().disabled
		, "Change pair enables on Fitness Course")
		await click(change_pair_button())
	var done := await wait_until(func() -> bool:
		return not main.company_panel.busy and developing().get("name", "") == "Fitness Course" and label_named("PivotOffer") != null and label_named("PivotOffer").text == DONE
	, "Change pair pivots to Fitness Course")
	if done:
		await frames(3)
		await reveal(label_named("PivotOffer"))
		layout_done("After the pivot")
		check(str(developing().get("fit", "")) == "great" and int(developing().get("devDays", -1)) == 0, "The new pair keeps day 0 and uses the new fit")
		check(company_cash() == cash_before and company_reputation() == fans_before, "Pivot spends no cash and gains no fans")
		var offer: Dictionary = developing().get("pivot", {}) if developing().get("pivot") is Dictionary else {}
		check(bool(offer.get("used", false)) and not bool(offer.get("enabled", false)), "The one pivot is used")
	connect_closed("Connect stays closed after the pivot")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("PivotOffer"))
	layout_done("Reopened")
	check(str(developing().get("name", "")) == "Fitness Course" and str(developing().get("fit", "")) == "great", "Reopening keeps the pivoted pair")
	await open_product()
	check(main.company_panel.screen == "product", "The build screen still opens after the pivot")
	var heading := main.company_panel._header.get_child(0) as Control if main.company_panel._header.get_child_count() > 0 else null
	var title := heading.get_child(0) as Label if heading != null and heading.get_child_count() > 0 else null
	check(title != null and title.text == "Fitness Course", "The build screen names Fitness Course")
	check(label_named("PivotOffer") == null and pivot_button() == null, "The build screen still has no pivot control")
	connect_closed("Connect stays closed after reopen")
	print("TYCOON PIVOT ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
