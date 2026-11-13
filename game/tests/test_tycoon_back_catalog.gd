extends SceneTree

## Headless back-catalog playtest with the real worker and an isolated company.
## Skipping the listing leaves the first newsletter at 20700 cents and 5 fans.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-back-catalog-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func catalog_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	var listed := main.company_panel.find_child("DelistCatalog", true, false) as Button
	if listed != null and listed.is_visible_in_tree():
		return listed
	return main.company_panel.find_child("ListCatalog", true, false) as Button

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

func catalog_state() -> Dictionary:
	var value: Variant = tycoon_state().get("catalog", {})
	return value as Dictionary if value is Dictionary else {}

func shipped_sales() -> int:
	var history: Array = tycoon_state().get("history", []) as Array
	for item: Variant in history:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == "p1":
			return int((item as Dictionary).get("salesCents", 0))
	return -1

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

func boot() -> bool:
	main = MAIN.instantiate()
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads the company", 40000)
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

func only_hire_primary() -> bool:
	if main == null or main.company_panel == null:
		return false
	var found := false
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree():
			continue
		if str(button.get_meta("cozy_variant", "")) != "primary":
			continue
		if not button.text.begins_with("Hire"):
			return false
		found = true
	return found

func text_fits(label: Label) -> bool:
	if label == null:
		return false
	var font := label.get_theme_font("font")
	if font == null:
		return false
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font")).x
	return width <= label.size.x + 1.0 and label.get_line_count() == 1

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
	var script_path := root.path_join("check-back-catalog.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;
import { catalogCheckCents } from IMPORT_TYCOON;

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
function message(fn) {
  try { fn(); return ''; } catch (error) { return error.message; }
}
function mustThrow(fn, pattern, label) {
  const text = message(fn);
  if (!pattern.test(text)) fail({ label, text });
}
function ship(db) {
  db.tycoon.start('crypto', 'newsletter', []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release('p1');
}
function salesOf(db, id) {
  const row = db.tycoon.view().history.find((item) => item.id === id);
  return row ? row.salesCents : null;
}
const start = source.indexOf('listCatalog(productId: string');
const slice = source.slice(start, source.indexOf('letGo(staffId: string', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
if (!slice.includes('This product is not finished.')) fail('unfinished text');
if (!slice.includes('Already listed.')) fail('already text');
if (!slice.includes('A product is already listed.')) fail('swap text');
if (!slice.includes('Nothing is listed.')) fail('delist text');
if (catalogCheckCents(6) !== 1200 || catalogCheckCents(0) !== 0) fail('check math');
if (parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.listCatalog', params: { productId: 'p1' } }).method !== 'tycoon.listCatalog') fail('parse list');
if (parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.delistCatalog', params: {} }).method !== 'tycoon.delistCatalog') fail('parse delist');
mustThrow(() => parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.listCatalog', params: {} }), /Invalid protocol request/, 'missing');
mustThrow(() => parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.listCatalog', params: { productId: 'nope' } }), /Invalid protocol request/, 'bad id');
mustThrow(() => parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.listCatalog', params: { productId: 'p1', extra: true } }), /Invalid protocol request/, 'extra');
mustThrow(() => parseRequest({ kind: 'request', id: 'catalog', method: 'tycoon.delistCatalog', params: { productId: 'p1' } }), /Invalid protocol request/, 'delist extra');

const fresh = open('fresh');
mustThrow(() => fresh.tycoon.listCatalog('p1'), /No product with that id\\./, 'unknown');
mustThrow(() => fresh.tycoon.listCatalog('p99'), /No product with that id\\./, 'unknown high');
mustThrow(() => fresh.tycoon.delistCatalog(), /Nothing is listed\\./, 'empty delist');
fresh.tycoon.start('crypto', 'newsletter', []);
mustThrow(() => fresh.tycoon.listCatalog('p1'), /This product is not finished\\./, 'unfinished');
if (fresh.tycoon.view().catalog.list.enabled !== false) fail('bench offer');
fresh.tycoon.cancelBuild();
mustThrow(() => fresh.tycoon.listCatalog('p1'), /No product with that id\\./, 'cancelled');
fresh.close();

const listed = open('listed');
const plain = open('plain');
ship(listed);
ship(plain);
const launched = listed.tycoon.view().history[0];
if (listed.journey.state().company.cashCents !== 20700 || launched.fans !== 5 || launched.salesCents !== 20700 || launched.review.score !== 6) fail('launch');
const before = {
  day: listed.clockState().day,
  cash: listed.journey.state().company.cashCents,
  fans: listed.journey.state().company.reputation,
  sales: launched.salesCents,
  seed: listed.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed,
  txs: listed.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n,
};
listed.tycoon.listCatalog('p1');
mustThrow(() => listed.tycoon.listCatalog('p1'), /Already listed\\./, 'already');
const after = listed.tycoon.view().catalog;
if (after.productId !== 'p1' || after.checkCents !== 1200 || after.score !== 6 || after.delist.enabled !== true || after.list.enabled !== false) fail('listed view');
if (listed.clockState().day !== before.day || listed.journey.state().company.cashCents !== before.cash || listed.journey.state().company.reputation !== before.fans) fail('list mutates company');
if (salesOf(listed, 'p1') !== before.sales || listed.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== before.seed) fail('list mutates sale or seed');
if (listed.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n !== before.txs) fail('list ledger');
listed.endDay(3);
plain.endDay(3);
listed.endDay(4);
plain.endDay(4);
if (listed.journey.state().company.cashCents !== 33300 || plain.journey.state().company.cashCents !== 33300) fail('next sale');
if (salesOf(listed, 'p1') !== salesOf(plain, 'p1') || listed.journey.state().company.reputation !== plain.journey.state().company.reputation) fail('posted sales');
if (listed.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'\").all().length !== 0) fail('early check');
listed.setClock(28, 480, 0);
plain.setClock(28, 480, 0);
listed.tycoon.tickDay(28);
plain.tycoon.tickDay(28);
const check = listed.journey.db.prepare(\"SELECT cash_delta, earned_delta, reputation_delta, label FROM company_transactions WHERE id = 'tycoon:catalog:1-spring'\").get();
if (!check || check.cash_delta !== 1200 || check.earned_delta !== 0 || check.reputation_delta !== 0 || check.label !== 'Catalog: Crypto Alpha Newsletter') fail({ check });
if (listed.journey.state().company.cashCents !== plain.journey.state().company.cashCents + 1200) fail('payday cash');
if (listed.journey.state().company.reputation !== plain.journey.state().company.reputation || salesOf(listed, 'p1') !== salesOf(plain, 'p1')) fail('payday sales');
listed.tycoon.tickDay(28);
if (listed.journey.state().company.cashCents !== plain.journey.state().company.cashCents + 1200) fail('replay');
listed.tycoon.delistCatalog();
mustThrow(() => listed.tycoon.delistCatalog(), /Nothing is listed\\./, 'delisted');
if (listed.tycoon.view().catalog.productId !== null) fail('cleared');
listed.tycoon.tickDay(56);
plain.tycoon.tickDay(56);
if (listed.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id = 'tycoon:catalog:1-summer'\").get()) fail('check after delist');
if (listed.journey.state().company.cashCents !== plain.journey.state().company.cashCents + 1200) fail('delist cash');
if (salesOf(listed, 'p1') !== salesOf(plain, 'p1') || listed.journey.state().company.reputation !== plain.journey.state().company.reputation) fail('delist sales');
listed.close();
plain.close();

const second = open('second');
ship(second);
second.tycoon.start('fitness', 'newsletter', []);
second.endDay(3);
second.endDay(4);
second.tycoon.release('p2');
if (second.tycoon.view().catalog.list.productId !== 'p2' || second.tycoon.view().catalog.list.enabled !== true) fail('newest offer');
second.tycoon.listCatalog('p1');
mustThrow(() => second.tycoon.listCatalog('p2'), /A product is already listed\\./, 'one listing');
if (second.tycoon.view().catalog.productId !== 'p1') fail('kept first');
second.close();

const draw = open('draw');
const drawTwin = open('draw-twin');
ship(draw);
ship(drawTwin);
draw.tycoon.listCatalog('p1');
draw.tycoon.start('fitness', 'newsletter', []);
drawTwin.tycoon.start('fitness', 'newsletter', []);
draw.endDay(3);
drawTwin.endDay(3);
draw.endDay(4);
drawTwin.endDay(4);
draw.tycoon.release('p2');
drawTwin.tycoon.release('p2');
const drawn = draw.tycoon.view().history.find((item) => item.id === 'p2');
const twinDrawn = drawTwin.tycoon.view().history.find((item) => item.id === 'p2');
if (!drawn || !twinDrawn || drawn.review.score !== twinDrawn.review.score || salesOf(draw, 'p1') !== salesOf(drawTwin, 'p1')) fail('rng');
if (draw.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== drawTwin.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed) fail('seed');
draw.close();
drawTwin.close();

const sameDay = open('same-day');
ship(sameDay);
sameDay.setClock(28, 480, 0);
sameDay.tycoon.listCatalog('p1');
if (sameDay.tycoon.view().catalog.payday !== 'Summer 28') fail('same-day payday');
sameDay.tycoon.tickDay(28);
if (sameDay.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'\").all().length !== 0) fail('same-day check');
sameDay.tycoon.tickDay(56);
const summer = sameDay.journey.db.prepare(\"SELECT cash_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:catalog:1-summer'\").get();
if (!summer || summer.cash_delta !== 1200 || summer.reputation_delta !== 0) fail({ summer });
sameDay.close();

const reopen = open('reopen');
ship(reopen);
reopen.tycoon.listCatalog('p1');
const pending = JSON.stringify(reopen.tycoon.view().catalog);
const file = root + '/reopen/startup-valley.sqlite';
const project = root + '/reopen/company-project';
reopen.close();
const reopened = new GameDatabase(file, project);
if (JSON.stringify(reopened.tycoon.view().catalog) !== pending) fail('reopen payload');
if (reopened.journey.state().company.cashCents !== 20700 || reopened.journey.state().company.reputation !== 5 || salesOf(reopened, 'p1') !== 20700) fail('reopen numbers');
reopened.close();

const skip = open('skip');
ship(skip);
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700) fail('skip launch');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || skip.tycoon.view().history[0].salesCents !== 33300) fail('skip next');
if (skip.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'\").all().length !== 0) fail('skip row');
skip.close();
console.log('BACK CATALOG RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the back-catalog rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Back-catalog rules hold (%s)" % " ".join(output))
	return code == 0

func seed_play() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := data_dir.path_join("seed-play.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.journey.hire('mira', db.clockState().day);\nconst catalog = db.tycoon.view().catalog;\nconst company = db.journey.state().company;\nconst day = db.clockState().day;\nconst sales = db.tycoon.view().history[0];\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\nconst ok = day === 3 && company.cashCents === 20700 && company.reputation === 5 && sales && sales.salesCents === 20700 && sales.fans === 5 && sales.review.score === 6 && catalog.list.enabled === true && catalog.list.productId === 'p1' && catalog.checkCents === 1200 && catalog.name === 'Crypto Alpha Newsletter' && catalog.payday === 'Spring 28' && catalog.productId === null;\nif (!ok) { console.error(JSON.stringify({ day, company, catalog, sales })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the back-catalog play seed")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded the back-catalog company (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var card := main.company_panel.find_child("SeasonCard", true, false) as Control
	var line := label_named("CatalogLine")
	var button := catalog_button()
	var payroll := label_named("SeasonPayroll")
	var loan := main.company_panel.find_child("TakeLoan", true, false) as Button
	var footer := main.company_panel._footer
	check(card != null and line != null and button != null and card.is_ancestor_of(line) and card.is_ancestor_of(button), note + " shows the catalog row on the Season card")
	check(button.name == "ListCatalog" and button.text == "List in catalog" and secondary(button), note + " List in catalog is secondary")
	check(line.text == "Crypto Alpha Newsletter · next check $12 on Spring 28" and text_fits(line), note + " the next check is one readable line")
	check(payroll != null and fits(payroll, line) and fits(line, button) and loan != null and fits(button, loan), note + " the row sits under payroll and above the loan")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()) and not button.get_global_rect().intersects(footer.get_global_rect()), note + " the row does not overlap Hire")
	check(inside_view(line) and inside_view(button) and inside_view(loan), note + " the row stays inside the journey")
	check(only_hire_primary(), note + " Hire stays the one primary action")

func layout_listed(note: String) -> void:
	var line := label_named("CatalogLine")
	var button := catalog_button()
	var loan := main.company_panel.find_child("TakeLoan", true, false) as Button
	var footer := main.company_panel._footer
	check(line != null and line.text == "Listed · Crypto Alpha Newsletter · next check $12 on Spring 28" and text_fits(line), note + " names the listed product and the next check")
	check(button != null and button.name == "DelistCatalog" and button.text == "Delist" and secondary(button), note + " Delist is secondary")
	check(main.company_panel.find_child("ListCatalog", true, false) == null, note + " the list button is gone")
	check(loan != null and fits(line, button) and fits(button, loan), note + " Delist stays above the loan")
	check(footer != null and not button.get_global_rect().intersects(footer.get_global_rect()), note + " Delist does not overlap Hire")
	check(inside_view(line) and inside_view(button), note + " the listed row stays inside the journey")
	check(only_hire_primary(), note + " Hire stays the one primary action")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	if not rules_hold() or not seed_play():
		_finish()
		return
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 20700 and company_reputation() == 5 and shipped_sales() == 20700, "The shipped newsletter is still 20700 cents and 5 fans")
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	stripped_tycoon.erase("catalog")
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("CatalogLine") == null and catalog_button() == null, "A payload without catalog draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(main.company_panel.find_child("SeasonCard", true, false) as Control)
	await reveal(catalog_button())
	layout_offer("Offer")
	var day_before := main.day_clock.day
	connect_closed("Connect stays closed before listing")
	await click(catalog_button())
	var shown := await wait_until(func() -> bool:
		var line := label_named("CatalogLine")
		var button := catalog_button()
		return not main.company_panel.busy and line != null and line.text.begins_with("Listed") and button != null and button.text == "Delist" and company_cash() == 20700 and company_reputation() == 5
	, "Listing names the product and leaves cash and fans")
	if shown:
		await frames(3)
		await reveal(catalog_button())
		layout_listed("Listed")
		check(shipped_sales() == 20700, "Listing does not rewrite the posted sale")
		check(main.day_clock.day == day_before, "Listing does not move the clock")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("Spring 3") and header.text.contains("$207.00") and header.text.contains("5 reputation"), "The header stays at Spring 3, $207.00, and 5 reputation")
	connect_closed("Connect stays closed after listing")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(catalog_button())
	layout_listed("Reopened")
	check(company_cash() == 20700 and company_reputation() == 5 and shipped_sales() == 20700, "Reopening keeps the listing, the sale, and the fans")
	var listed_payload := catalog_state()
	check(str(listed_payload.get("productId", "")) == "p1" and int(listed_payload.get("checkCents", 0)) == 1200, "Reopening keeps the catalog payload")
	connect_closed("Connect stays closed after reopen")
	await click(catalog_button())
	var cleared := await wait_until(func() -> bool:
		var line := label_named("CatalogLine")
		var button := catalog_button()
		return not main.company_panel.busy and line != null and not line.text.begins_with("Listed") and button != null and button.text == "List in catalog" and company_cash() == 20700
	, "Delist restores the list control")
	if cleared:
		await frames(3)
		await reveal(catalog_button())
		layout_offer("Delisted")
		check(company_reputation() == 5 and shipped_sales() == 20700 and main.day_clock.day == day_before, "Delist leaves fans, sales, and the clock")
	connect_closed("Connect stays closed after delist")
	print("TYCOON BACK CATALOG ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
