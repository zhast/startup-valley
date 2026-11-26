extends SceneTree

## Headless cancel-build with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. Dropping a build clears the bench.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Cancel · drop this build. Days worked are gone."
const ASK := "Drop this build? Days worked are gone."
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-cancel-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func cancel_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("CancelBuild", true, false) as Button

func keep_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("KeepBuild", true, false) as Button

func drop_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("DropBuild", true, false) as Button

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
	check(label_named("CancelOffer") == null and cancel_button() == null, "The product picker has no cancel control")
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
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-cancel.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { GameDatabase } from IMPORT_DATABASE;
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
function cancelRows(db) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:cancel%'").all();
}
function countProducts(db) {
  return Number(db.journey.db.prepare('SELECT COUNT(*) AS n FROM tycoon_products').get().n);
}
function finishNewsletter(db) {
  db.tycoon.start('crypto', 'newsletter', []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release('p1');
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
}

mustThrow(() => parseRequest({ kind: 'request', id: 'cancel', method: 'tycoon.cancelBuild', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'cancel', method: 'tycoon.cancelBuild', params: {} }).method !== 'tycoon.cancelBuild') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.cancelBuild(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
const offerBlock = skip.tycoon.view().developing.cancel;
if (!offerBlock || offerBlock.enabled !== true || offerBlock.reason !== '') fail(offerBlock);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].cancel !== null) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || cancelRows(skip).length !== 0) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.cancelBuild(), /No product is on the bench\\./, 'shipped');
skip.close();

const drop = open('drop');
drop.tycoon.start('crypto', 'newsletter', []);
drop.endDay(1);
if (drop.tycoon.view().developing.devDays !== 1 || drop.tycoon.view().developing.design !== 2) fail('worked');
const points = drop.tycoon.view().researchPoints;
const founder = drop.tycoon.view().staff.find((person) => person.id === 'founder').design;
const cash = drop.journey.state().company.cashCents;
const fans = drop.journey.state().company.reputation;
const day = drop.clockState().day;
const before = JSON.stringify(txIds(drop));
drop.tycoon.cancelBuild();
if (drop.clockState().day !== day || drop.tycoon.view().developing !== null || drop.tycoon.view().history.length !== 0 || countProducts(drop) !== 0) fail('bench');
if (JSON.stringify(txIds(drop)) !== before || cancelRows(drop).length !== 0) fail('ledger');
if (drop.tycoon.view().researchPoints !== points || drop.tycoon.view().staff.find((person) => person.id === 'founder').design !== founder) fail('staff');
if (drop.journey.state().company.cashCents !== cash || drop.journey.state().company.reputation !== fans) fail('money');
mustThrow(() => drop.tycoon.cancelBuild(), /No product is on the bench\\./, 'again');
mustThrow(() => drop.tycoon.release('p1'), /No product is on the bench\\./, 'release');
mustThrow(() => drop.tycoon.award('p1'), /No product with that id\\./, 'award');
mustThrow(() => drop.tycoon.sequel('p1'), /No product with that id\\./, 'sequel');
mustThrow(() => drop.tycoon.port('p1'), /No product with that id\\./, 'port');
mustThrow(() => drop.tycoon.patch('p1'), /No product with that id\\./, 'patch');
drop.tycoon.start('crypto', 'newsletter', []);
const next = drop.tycoon.view().developing;
if (!next || next.id !== 'p2' || next.devDays !== 0 || next.design !== 0 || !next.cancel || next.cancel.enabled !== true || next.cancel.reason !== '') fail(next);
if (drop.tycoon.view().researchPoints !== points) fail('restart');
drop.close();

const fresh = open('fresh');
fresh.tycoon.start('crypto', 'newsletter', []);
fresh.tycoon.cancelBuild();
fresh.tycoon.start('crypto', 'newsletter', []);
if (fresh.tycoon.view().developing.id !== 'p1' || fresh.tycoon.view().developing.devDays !== 0) fail('reuse');
fresh.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.endDay(1);
const keptPoints = kept.tycoon.view().researchPoints;
const keptCash = kept.journey.state().company.cashCents;
const keptFans = kept.journey.state().company.reputation;
const keptDay = kept.clockState().day;
kept.tycoon.cancelBuild();
const keptFile = root + '/kept/startup-valley.sqlite';
const keptProject = root + '/kept/company-project';
kept.close();
const reopened = new GameDatabase(keptFile, keptProject);
if (reopened.tycoon.view().developing !== null || reopened.tycoon.view().history.length !== 0 || countProducts(reopened) !== 0) fail('reopen bench');
if (reopened.tycoon.view().researchPoints !== keptPoints || reopened.journey.state().company.cashCents !== keptCash || reopened.journey.state().company.reputation !== keptFans || reopened.clockState().day !== keptDay) fail('reopen state');
reopened.tycoon.view();
if (countProducts(reopened) !== 0) fail('reopen read');
reopened.tycoon.start('fitness', 'newsletter', []);
if (!reopened.tycoon.view().developing || reopened.tycoon.view().developing.id !== 'p2') fail('reopen start');
reopened.close();

const deal = open('deal');
const contract = deal.tycoon.view().contract;
deal.tycoon.acceptContract();
deal.tycoon.start(contract.topicId, contract.typeId, []);
if (deal.tycoon.view().contract.status !== 'building' || deal.tycoon.view().developing.contract.bonusCents !== contract.bonusCents) fail('building');
const dealCash = deal.journey.state().company.cashCents;
const dealFans = deal.journey.state().company.reputation;
const dealTx = JSON.stringify(txIds(deal));
deal.tycoon.cancelBuild();
if (deal.tycoon.view().developing !== null || deal.tycoon.view().history.length !== 0) fail('deal bench');
if (deal.journey.state().company.cashCents !== dealCash || deal.journey.state().company.reputation !== dealFans || JSON.stringify(txIds(deal)) !== dealTx) fail('deal money');
const returned = deal.tycoon.view().contract;
if (returned.status !== 'offered' || returned.id !== contract.id || returned.enabled !== true) fail(returned);
const paid = Number(deal.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id LIKE 'tycoon:contract:%'").get().n);
if (paid !== 0) fail({ paid });
deal.tycoon.acceptContract();
deal.tycoon.start(returned.topicId, returned.typeId, []);
if (deal.tycoon.view().developing.contract.bonusCents !== contract.bonusCents || deal.tycoon.view().contract.status !== 'building') fail('again');
deal.close();

const published = open('published');
published.tycoon.start('crypto', 'newsletter', []);
published.tycoon.signPublisher();
published.tycoon.showPressDemo();
if (published.journey.state().company.cashCents !== 12000 || published.journey.state().company.reputation !== 4) fail('advance');
const publishedTx = JSON.stringify(txIds(published));
published.tycoon.cancelBuild();
if (published.tycoon.view().developing !== null || published.tycoon.view().history.length !== 0) fail('void');
if (published.journey.state().company.cashCents !== 12000 || published.journey.state().company.reputation !== 4 || JSON.stringify(txIds(published)) !== publishedTx) fail('kept fees');
const advance = Number(published.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:publisher:p1:advance'").get().n);
const preview = Number(published.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:pressdemo:p1:fee'").get().n);
if (advance !== 1 || preview !== 1) fail({ advance, preview });
published.tycoon.start('crypto', 'newsletter', []);
const second = published.tycoon.view().developing;
if (!second || second.id !== 'p2' || second.publisher.signed !== false || second.pressDemo.shown !== false) fail(second);
published.close();

const shipped = open('shipped');
shipped.tycoon.start('crypto', 'newsletter', []);
shipped.endDay(1);
shipped.endDay(2);
shipped.tycoon.release('p1');
const history = JSON.stringify(shipped.tycoon.view().history[0]);
const shippedCash = shipped.journey.state().company.cashCents;
const shippedFans = shipped.journey.state().company.reputation;
shipped.tycoon.start('fitness', 'newsletter', []);
shipped.tycoon.cancelBuild();
if (JSON.stringify(shipped.tycoon.view().history[0]) !== history || shipped.tycoon.view().history.length !== 1 || shipped.tycoon.view().history[0].id !== 'p1') fail('history');
if (shipped.journey.state().company.cashCents !== shippedCash || shipped.journey.state().company.reputation !== shippedFans || shipped.tycoon.view().developing !== null) fail('shipped money');
mustThrow(() => shipped.tycoon.award('p2'), /No product with that id\\./, 'award2');
mustThrow(() => shipped.tycoon.sequel('p2'), /No product with that id\\./, 'sequel2');
mustThrow(() => shipped.tycoon.port('p2'), /No product with that id\\./, 'port2');
mustThrow(() => shipped.tycoon.localize('p2'), /No product with that id\\./, 'localize');
mustThrow(() => shipped.tycoon.patch('p2'), /No product with that id\\./, 'patch2');
mustThrow(() => shipped.tycoon.makeTrailer('p2'), /No product with that id\\./, 'trailer');
mustThrow(() => shipped.tycoon.writeDiary('p2'), /No product with that id\\./, 'diary');
mustThrow(() => shipped.tycoon.release('p2'), /No product is on the bench\\./, 'release2');
shipped.close();

const sequel = open('sequel');
finishNewsletter(sequel);
sequel.tycoon.sequel('p1');
if (sequel.tycoon.view().developing.id !== 'p2' || staff(sequel, 'p1').sequelId !== 'p2') fail('sequel start');
sequel.tycoon.cancelBuild();
if (staff(sequel, 'p1').sequelId !== undefined || sequel.tycoon.view().developing !== null || sequel.tycoon.view().history[0].id !== 'p1') fail('sequel clear');
sequel.tycoon.sequel('p1');
if (sequel.tycoon.view().developing.id !== 'p2' || staff(sequel, 'p1').sequelId !== 'p2') fail('sequel again');
sequel.close();
console.log('CANCEL RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the cancel rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Cancel rules hold (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var line := label_named("CancelOffer")
	var button := cancel_button()
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var early := label_named("EarlyAccessOffer")
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire Mina")
	check(card != null and line != null and button != null and card.is_ancestor_of(line) and card.is_ancestor_of(button) and line.text == OFFER, note + " names the cancel offer")
	check(secondary(button) and button.text == "Cancel build", note + " Cancel build is secondary")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire Mina stays the one primary action")
	check(early != null and fits(early, line), note + " Cancel sits under Early access")
	check(fits(line, button), note + " The cancel line sits above Cancel build")
	check(fits(button, new_product), note + " Cancel build sits above New Product")
	check(footer != null and not button.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Cancel build does not overlap Hire")
	check(inside_view(line) and inside_view(button) and inside_view(new_product), note + " Cancel build and New Product stay inside the journey")
	check(button.size.x + 1.0 >= button.get_combined_minimum_size().x, note + " Cancel build text fits the button")

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
	check(label_named("CancelOffer") == null and cancel_button() == null, "No cancel control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("CancelOffer") == null and cancel_button() == null, "The build screen has no cancel control")
	await open_journey()
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var stripped_product: Dictionary = stripped_tycoon.get("developing", {}).duplicate(true)
	stripped_product.erase("cancel")
	stripped_tycoon["developing"] = stripped_product
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("CancelOffer") == null and cancel_button() == null, "A payload without cancel draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(label_named("CancelOffer"))
	layout_offer("Day 0")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(cancel_button())
	var asked := await wait_until(func() -> bool:
		return label_named("CancelOffer") != null and label_named("CancelOffer").text == ASK and keep_button() != null and drop_button() != null and not main.company_panel.busy
	, "Cancel build asks before it drops the product")
	if asked:
		await frames(3)
		await reveal(label_named("CancelOffer"))
		var keep := keep_button()
		var drop := drop_button()
		var hire := button_named("Hire Mina")
		var footer := main.company_panel._footer
		var new_product := button_named("New Product")
		check(keep.has_focus(), "Keep building takes focus")
		check(secondary(keep) and keep.text == "Keep building", "Keep building is secondary")
		check(secondary(drop) and drop.text == "Drop the build", "Drop the build is secondary")
		check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary during the confirm")
		check(fits(keep, drop), "Keep building sits above Drop the build")
		check(keep.size.x + 1.0 >= keep.get_combined_minimum_size().x and drop.size.x + 1.0 >= drop.get_combined_minimum_size().x, "The confirm buttons fit their labels")
		check(footer != null and not keep.get_global_rect().intersects(footer.get_global_rect()) and not drop.get_global_rect().intersects(footer.get_global_rect()), "The confirm does not overlap Hire")
		check(inside_view(keep) and inside_view(drop) and inside_view(new_product) and fits(drop, new_product), "The confirm sits above New Product")
		check(developing().get("name", "") == "Crypto Alpha Newsletter" and company_cash() == cash_before and company_reputation() == fans_before, "The confirm leaves the bench, cash, and fans")
		await click(keep)
		await wait_until(func() -> bool: return label_named("CancelOffer") != null and label_named("CancelOffer").text == OFFER and cancel_button() != null, "Keep building restores Cancel build")
		check(developing().get("name", "") == "Crypto Alpha Newsletter", "Keep building leaves the product on the bench")
	await end_office_day()
	await open_journey()
	var early_button := main.company_panel.find_child("ShipEarly", true, false) as Button
	await reveal(label_named("EarlyAccessOffer"))
	check(early_button != null and secondary(early_button), "Ship early stays secondary beside Cancel build")
	check(fits(early_button, label_named("CancelOffer")), "Cancel sits under Ship early")
	layout_offer("After one office day")
	await end_office_day()
	await open_journey()
	check(label_named("CancelOffer") != null and label_named("CancelOffer").text == OFFER and cancel_button() != null, "A finished build can still be cancelled")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping cancel still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping cancel still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700 and int(latest_shipped().get("fans", 0)) == 5, "Skipping cancel keeps launch sales at 20700 cents and 5 fans")
		check(latest_shipped().get("cancel") == null, "A normal release stores no cancel block")
		check(label_named("CancelOffer") == null and cancel_button() == null, "The release card has no cancel control")
		await open_journey()
		check(label_named("CancelOffer") == null and cancel_button() == null, "The cancel control is gone after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300 and str(latest_shipped().get("name", "")) == "Crypto Alpha Newsletter", "The newsletter's second sales day totals 33300 cents")
	connect_closed("Connect stays closed after a normal release")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300, "Reopening the newsletter keeps 33300 cents")
	check(label_named("CancelOffer") == null and developing().is_empty() and int(latest_shipped().get("salesCents", 0)) == 33300 and str(latest_shipped().get("name", "")) == "Crypto Alpha Newsletter", "Reopening keeps the shipped newsletter and an empty bench")
	await start_newsletter()
	await open_journey()
	cash_before = company_cash()
	fans_before = company_reputation()
	var history_sales := int(latest_shipped().get("salesCents", 0))
	var history_fans := int(latest_shipped().get("fans", -1))
	await click(cancel_button())
	asked = await wait_until(func() -> bool: return keep_button() != null and drop_button() != null and label_named("CancelOffer") != null and label_named("CancelOffer").text == ASK, "The second build asks before the drop")
	if asked:
		check(keep_button().has_focus(), "Keep building takes focus on the second build")
		await click(drop_button())
		var dropped := await wait_until(func() -> bool:
			return not main.company_panel.busy and main.company_panel.screen == "journey" and developing().is_empty() and label_named("CancelOffer") == null
		, "Drop the build clears the bench")
		if dropped:
			check(company_cash() == cash_before and company_reputation() == fans_before, "Dropping the build leaves cash and fans")
			check(int(latest_shipped().get("salesCents", 0)) == history_sales and int(latest_shipped().get("fans", -1)) == history_fans and str(latest_shipped().get("name", "")) == "Crypto Alpha Newsletter", "The shipped newsletter stays in history")
			check(button_named("New Product") != null and not button_named("New Product").disabled, "New Product is available after the drop")
	connect_closed("Connect stays closed after the drop")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(developing().is_empty() and label_named("CancelOffer") == null, "Reopening keeps the empty bench")
	check(company_cash() == 33300 and company_reputation() == fans_before and int(latest_shipped().get("salesCents", 0)) == history_sales, "Reopening keeps the newsletter cash, fans, and sales")
	await start_newsletter()
	check(developing().get("name", "") == "Crypto Alpha Newsletter" and int(developing().get("devDays", -1)) == 0, "A new product can start after the cancelled build")
	connect_closed("Connect stays closed after starting again")
	print("TYCOON CANCEL ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
