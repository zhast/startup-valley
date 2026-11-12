extends SceneTree

## Headless sale-price playtest with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. Changing it touches only later days.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Sale price · $9.00 · remaining days"
const SET := "Sale price · −20% · $7.20"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-sale-price-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func sale_button(percent: int) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("SalePrice_p1_%d" % percent, true, false) as Button

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

func sale_block() -> Dictionary:
	var value: Variant = latest_shipped().get("salePrice", {})
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
	check(label_named("SalePriceOffer_p1") == null and sale_button(80) == null, "The product picker has no sale price control")
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
	var script_path := root.path_join("check-sale-price.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;
import { salesForDay } from IMPORT_TYCOON;

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
const start = source.indexOf('salePrice(productId: string');
const slice = source.slice(start, source.indexOf('makeTrailer(productId: string', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
mustThrow(() => parseRequest({ kind: 'request', id: 'sale', method: 'tycoon.salePrice', params: { productId: 'p1', pricePercent: 90 } }), /Invalid protocol request/, 'invalid percent');
mustThrow(() => parseRequest({ kind: 'request', id: 'sale', method: 'tycoon.salePrice', params: { productId: 'p1' } }), /Invalid protocol request/, 'missing');
mustThrow(() => parseRequest({ kind: 'request', id: 'sale', method: 'tycoon.salePrice', params: { productId: 'p1', pricePercent: 80, extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'sale', method: 'tycoon.salePrice', params: { productId: 'p1', pricePercent: 80 } }).method !== 'tycoon.salePrice') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.salePrice('p1', 80), /No product with that id\\./, 'missing id');
bare.close();

const bench = open('bench');
bench.tycoon.start('crypto', 'newsletter', []);
if (bench.tycoon.view().developing.salePrice !== null) fail('bench block');
mustThrow(() => bench.tycoon.salePrice('p1', 80), /No product is selling\\./, 'bench');
bench.close();

const skip = open('skip');
ship(skip);
const launched = skip.tycoon.view().history[0];
if (skip.journey.state().company.cashCents !== 20700 || launched.fans !== 5 || launched.salesCents !== 20700) fail({ cash: skip.journey.state().company.cashCents, launched });
if (!launched.salePrice || launched.salePrice.enabled !== true || launched.salePrice.used !== false || launched.salePrice.currentPercent !== 100 || launched.salePrice.reason !== '') fail(launched.salePrice);
mustThrow(() => skip.tycoon.salePrice('p1', 100), /Price is unchanged\\./, 'unchanged');
mustThrow(() => skip.tycoon.salePrice('p1', 90), /Pick −20%/, 'bad percent');
if (skip.journey.state().company.cashCents !== 20700 || launched.salesCents !== 20700) fail('unchanged cash');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || skip.tycoon.view().history[0].salesCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
skip.close();

const sold = open('sold');
ship(sold);
const beforeTx = sold.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n;
const beforeDay = sold.clockState().day;
sold.tycoon.salePrice('p1', 80);
mustThrow(() => sold.tycoon.salePrice('p1', 120), /A sale price was already set\\./, 'double');
mustThrow(() => sold.tycoon.salePrice('p1', 80), /A sale price was already set\\./, 'repeat');
mustThrow(() => sold.tycoon.salePrice('p1', 90), /A sale price was already set\\./, 'repeat invalid');
if (sold.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n !== beforeTx) fail('ledger');
if (sold.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:saleprice%' OR id LIKE 'tycoon:salePrice%'\").all().length !== 0) fail('sale row');
if (sold.clockState().day !== beforeDay) fail('clock');
if (sold.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== 26021) fail('seed');
if (sold.journey.state().company.cashCents !== 20700 || sold.tycoon.view().history[0].salesCents !== 20700 || sold.tycoon.view().history[0].fans !== 5) fail('posted');
if (sold.journey.db.prepare(\"SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:0'\").get().cash_delta !== 20700) fail('old day');
sold.endDay(3);
if (sold.tycoon.view().history[0].salesCents !== 20700) fail('release day');
const priced = salesForDay({ seed: 26021, productId: 'p1', typeId: 'newsletter', fit: 'great', score: 6, dayIndex: 1, reputation: 5, pricePercent: 80 });
const catalog = salesForDay({ seed: 26021, productId: 'p1', typeId: 'newsletter', fit: 'great', score: 6, dayIndex: 1, reputation: 5, pricePercent: 100 });
if (priced.cents === catalog.cents) fail('same cents');
sold.endDay(4);
if (sold.tycoon.view().history[0].salesCents - 20700 !== priced.cents) fail({ sales: sold.tycoon.view().history[0].salesCents, priced });
if (sold.journey.db.prepare(\"SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:0'\").get().cash_delta !== 20700) fail('old day after');
if (sold.journey.db.prepare(\"SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:1'\").get().cash_delta !== priced.cents) fail('new day');
sold.endDay(5);
sold.endDay(6);
if (sold.tycoon.view().history[0].salePrice !== null) fail('finished block');
mustThrow(() => sold.tycoon.salePrice('p1', 120), /No product is selling\\./, 'complete');
sold.close();

const cheap = open('cheap');
cheap.tycoon.start('crypto', 'newsletter', [], 80);
cheap.endDay(1);
cheap.endDay(2);
cheap.tycoon.release('p1');
const cheapSales = cheap.tycoon.view().history[0].salesCents;
mustThrow(() => cheap.tycoon.salePrice('p1', 80), /Price is unchanged\\./, 'cheap same');
cheap.tycoon.salePrice('p1', 100);
if (cheap.tycoon.view().history[0].pricePercent !== 80 || cheap.tycoon.view().history[0].salePrice.currentPercent !== 100 || cheap.tycoon.view().history[0].salesCents !== cheapSales) fail('cheap change');
cheap.close();

const reopen = open('reopen');
ship(reopen);
reopen.tycoon.salePrice('p1', 80);
const pending = JSON.stringify(reopen.tycoon.view().history[0].salePrice);
const file = root + '/reopen/startup-valley.sqlite';
const project = root + '/reopen/company-project';
reopen.close();
const reopened = new GameDatabase(file, project);
if (JSON.stringify(reopened.tycoon.view().history[0].salePrice) !== pending) fail('reopen');
if (reopened.journey.state().company.cashCents !== 20700 || reopened.tycoon.view().history[0].salesCents !== 20700) fail('reopen cash');
mustThrow(() => reopened.tycoon.salePrice('p1', 120), /A sale price was already set\\./, 'reopen repeat');
reopened.endDay(3);
reopened.endDay(4);
if (reopened.tycoon.view().history[0].salesCents - 20700 !== priced.cents) fail('reopen day');
reopened.close();
console.log('SALE PRICE RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the sale price rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Sale price rules hold (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var line := label_named("SalePriceOffer_p1")
	var cheap := sale_button(80)
	var catalog := sale_button(100)
	var premium := sale_button(120)
	var trailer := label_named("TrailerOffer_p1")
	var make := button_named("Make trailer")
	var patch := button_named("Patch")
	var hire := button_named("Hire")
	var card := main.company_panel.find_child("Selling_p1", true, false) as Control
	var footer := main.company_panel._footer
	check(card != null and line != null and card.is_ancestor_of(line) and line.text == OFFER, note + " names the sale price")
	check(secondary(cheap) and cheap.text == "−20%", note + " −20% is secondary")
	check(secondary(premium) and premium.text == "+20%", note + " +20% is secondary")
	check(catalog == null, note + " hides the current percent")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(only_hire_primary(), note + " nothing else is primary")
	check(make != null and str(make.get_meta("cozy_variant", "")) == "secondary", note + " Make trailer stays")
	check(patch != null and str(patch.get_meta("cozy_variant", "")) == "secondary", note + " Patch stays secondary")
	check(trailer != null and make != null and fits(trailer, line) and fits(make, line), note + " Sale price sits under the trailer")
	check(fits(line, cheap) and fits(line, premium), note + " the buttons sit under the line")
	check(fits(cheap, patch) and fits(premium, patch), note + " Sale price sits above Patch")
	check(not cheap.get_global_rect().intersects(premium.get_global_rect()), note + " the price buttons do not overlap")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()) and not cheap.get_global_rect().intersects(footer.get_global_rect()) and not premium.get_global_rect().intersects(footer.get_global_rect()), note + " Sale price does not overlap Hire")
	check(inside_view(line) and inside_view(cheap) and inside_view(premium) and inside_view(patch), note + " Sale price and Patch stay inside the journey")
	check(line.get_line_count() == 1, note + " The sale price line stays on one line")
	check(cheap.size.x + 1.0 >= cheap.get_combined_minimum_size().x and premium.size.x + 1.0 >= premium.get_combined_minimum_size().x, note + " price text fits the buttons")

func layout_set(note: String) -> void:
	var line := label_named("SalePriceOffer_p1")
	var patch := button_named("Patch")
	var hire := button_named("Hire")
	var footer := main.company_panel._footer
	check(line != null and line.text == SET and sale_button(80) == null and sale_button(100) == null and sale_button(120) == null, note + " shows the new percent")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(only_hire_primary(), note + " nothing else is primary")
	check(patch != null and str(patch.get_meta("cozy_variant", "")) == "secondary" and fits(line, patch), note + " the set line sits above Patch")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " the set line does not overlap Hire")
	check(inside_view(line) and inside_view(patch), note + " the set line and Patch stay inside the journey")
	check(line.get_line_count() == 1, note + " the set line stays on one line")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	if not rules_hold():
		_finish()
		return
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	await dismiss_onboarding()
	check(label_named("SalePriceOffer_p1") == null and sale_button(80) == null, "No sale price control before a product is selling")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("SalePriceOffer_p1") == null, "The build screen has no sale price control")
	await open_journey()
	check(label_named("SalePriceOffer_p1") == null and sale_button(80) == null, "A product on the bench has no sale price control")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Release still pays 20700 cents")
	if not released:
		_finish()
		return
	check(company_reputation() == 5 and int(latest_shipped().get("salesCents", 0)) == 20700 and int(latest_shipped().get("fans", 0)) == 5, "Release still pays 5 fans and 20700 cents of sales")
	await open_journey()
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var history: Array = (stripped_tycoon.get("history", []) as Array).duplicate(true)
	var stripped_product: Dictionary = (history[0] as Dictionary).duplicate(true)
	stripped_product.erase("salePrice")
	history[0] = stripped_product
	stripped_tycoon["history"] = history
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("SalePriceOffer_p1") == null and sale_button(80) == null and sale_button(120) == null, "A payload without salePrice draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(label_named("SalePriceOffer_p1"))
	layout_offer("Offer")
	check(bool(sale_block().get("enabled", false)) and not bool(sale_block().get("used", true)) and int(sale_block().get("currentPercent", 0)) == 100 and str(sale_block().get("reason", "x")) == "", "The payload offers the launch percent")
	var day_before := main.day_clock.day
	await click(sale_button(80))
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("SalePriceOffer_p1") != null and label_named("SalePriceOffer_p1").text == SET and sale_button(80) == null and sale_button(120) == null
	, "Sale price shows −20%")
	if shown:
		await frames(3)
		await reveal(label_named("SalePriceOffer_p1"))
		layout_set("Set")
		check(company_cash() == 20700 and company_reputation() == 5 and int(latest_shipped().get("salesCents", 0)) == 20700 and int(latest_shipped().get("fans", 0)) == 5, "The change leaves posted sales, cash, and fans")
		check(main.day_clock.day == day_before, "The change does not move the clock")
		check(bool(sale_block().get("used", false)) and not bool(sale_block().get("enabled", true)) and int(sale_block().get("currentPercent", 0)) == 80, "The payload stores the new percent")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("Spring 3") and header.text.contains("$207.00") and header.text.contains("5 reputation"), "The header stays at Spring 3, $207, and 5 reputation")
	connect_closed("Connect stays closed after the sale price")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("SalePriceOffer_p1"))
	layout_set("Reopened")
	check(company_cash() == 20700 and company_reputation() == 5 and int(latest_shipped().get("salesCents", 0)) == 20700 and int(sale_block().get("currentPercent", 0)) == 80 and bool(sale_block().get("used", false)), "Reopening keeps the sale price and the posted sale")
	connect_closed("Connect stays closed after reopen")
	print("TYCOON SALE PRICE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
