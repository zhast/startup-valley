extends SceneTree

## Headless research-spike playtest with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Research spike · tomorrow's craft becomes research points"
const PENDING := "Spike set · tomorrow's craft becomes research points"
const DONE := "Spike done · +6 research points"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-research-spike-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func spike_button() -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("ResearchSpike", true, false) as Button

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

func spike_block() -> Dictionary:
	var value: Variant = developing().get("researchSpike", {})
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
	check(label_named("ResearchSpikeOffer") == null and spike_button() == null, "The product picker has no research spike control")
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
	var script_path := root.path_join("check-research-spike.mjs")
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
function message(fn) {
  try { fn(); return ''; } catch (error) { return error.message; }
}
function mustThrow(fn, pattern, label) {
  const text = message(fn);
  if (!pattern.test(text)) fail({ label, text });
}
const idle = { enabled: true, pending: false, used: false, reason: '', points: 0 };
const start = source.indexOf('researchSpike():');
const slice = source.slice(start, source.indexOf('addFeature():', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
if (!slice.includes('No product is on the bench.')) fail('bench copy');
if (!slice.includes('A research spike is already set.')) fail('pending copy');
if (!slice.includes('This build already used its research spike.')) fail('used copy');
mustThrow(() => parseRequest({ kind: 'request', id: 'spike', method: 'tycoon.researchSpike', params: { extra: true } }), /Invalid protocol request/, 'extra');
if (parseRequest({ kind: 'request', id: 'spike', method: 'tycoon.researchSpike', params: {} }).method !== 'tycoon.researchSpike') fail('parse');

const bare = open('bare');
mustThrow(() => bare.tycoon.researchSpike(), /No product is on the bench\\./, 'bare');
bare.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
if (JSON.stringify(skip.tycoon.view().developing.researchSpike) !== JSON.stringify(idle)) fail(skip.tycoon.view().developing.researchSpike);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700 || skip.tycoon.view().history[0].researchSpike !== null) fail({ cash: skip.journey.state().company.cashCents });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300) fail({ next: skip.journey.state().company.cashCents });
mustThrow(() => skip.tycoon.researchSpike(), /No product is on the bench\\./, 'shipped');
skip.close();

const kept = open('kept');
kept.tycoon.start('crypto', 'newsletter', []);
kept.endDay(1);
if (kept.tycoon.view().developing.design !== 2 || kept.tycoon.view().researchPoints !== 1) fail('earned');
kept.tycoon.researchSpike();
mustThrow(() => kept.tycoon.researchSpike(), /already set/, 'pending');
if (kept.tycoon.view().developing.design !== 2 || kept.tycoon.view().developing.devDays !== 1 || kept.tycoon.view().researchPoints !== 1) fail('held');
kept.endDay(2);
if (kept.tycoon.view().developing.devDays !== 2 || kept.tycoon.view().developing.design !== 2 || kept.tycoon.view().developing.tech !== 2 || kept.tycoon.view().developing.hype !== 2 || kept.tycoon.view().researchPoints !== 8 || kept.tycoon.view().developing.researchSpike.points !== 6 || kept.tycoon.view().developing.researchSpike.used !== true) fail(kept.tycoon.view());
mustThrow(() => kept.tycoon.researchSpike(), /already used/, 'used');
kept.endDay(3);
if (kept.tycoon.view().developing.design !== 4 || kept.tycoon.view().developing.tech !== 4 || kept.tycoon.view().developing.hype !== 4 || kept.tycoon.view().researchPoints !== 9) fail('after');
kept.close();

const fresh = open('fresh');
fresh.tycoon.start('crypto', 'newsletter', []);
fresh.tycoon.researchSpike();
fresh.endDay(1);
if (fresh.tycoon.view().developing.devDays !== 1 || fresh.tycoon.view().developing.design !== 0 || fresh.tycoon.view().developing.tech !== 0 || fresh.tycoon.view().developing.hype !== 0 || fresh.tycoon.view().researchPoints !== 7 || fresh.tycoon.view().developing.researchSpike.points !== 6) fail(fresh.tycoon.view());
fresh.endDay(2);
if (fresh.tycoon.view().developing.design !== 2 || fresh.tycoon.view().developing.tech !== 2 || fresh.tycoon.view().developing.hype !== 2 || fresh.tycoon.view().researchPoints !== 8) fail('normal');
fresh.close();

const reopen = open('reopen');
reopen.tycoon.start('crypto', 'newsletter', []);
reopen.tycoon.researchSpike();
const pending = JSON.stringify(reopen.tycoon.view().developing.researchSpike);
const file = root + '/reopen/startup-valley.sqlite';
const project = root + '/reopen/company-project';
reopen.close();
const reopened = new GameDatabase(file, project);
if (JSON.stringify(reopened.tycoon.view().developing.researchSpike) !== pending) fail('reopen pending');
reopened.endDay(1);
const used = JSON.stringify(reopened.tycoon.view().developing.researchSpike);
if (reopened.tycoon.view().developing.researchSpike.used !== true || reopened.tycoon.view().developing.researchSpike.points !== 6 || reopened.tycoon.view().researchPoints !== 7) fail('landed');
reopened.close();
const again = new GameDatabase(file, project);
if (JSON.stringify(again.tycoon.view().developing.researchSpike) !== used) fail('reopen used');
mustThrow(() => again.tycoon.researchSpike(), /already used/, 'used again');
again.tycoon.cancelBuild();
mustThrow(() => again.tycoon.researchSpike(), /No product is on the bench\\./, 'cancelled');
again.close();
console.log('RESEARCH SPIKE RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the research spike rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Research spike rules hold (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var line := label_named("ResearchSpikeOffer")
	var button := spike_button()
	var team := label_named("TeamOffer")
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	check(card != null and line != null and button != null and card.is_ancestor_of(line) and card.is_ancestor_of(button) and line.text == OFFER, note + " names the research spike")
	check(secondary(button) and button.text == "Research spike", note + " Research spike is secondary")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(str(button.get_meta("cozy_variant", "")) != "primary", note + " Research spike is not primary")
	check(team != null and fits(team, line), note + " Research spike sits under Team")
	check(absf(line.get_global_rect().position.y - button.get_global_rect().position.y) < 48.0, note + " The spike line sits with the button")
	check(fits(line, new_product) and fits(button, new_product), note + " Research spike sits above New Product")
	check(footer != null and not button.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), note + " Research spike does not overlap Hire")
	check(inside_view(line) and inside_view(button) and inside_view(new_product), note + " Research spike and New Product stay inside the journey")
	check(button.size.x + 1.0 >= button.get_combined_minimum_size().x, note + " Research spike text fits the button")
	check(line.get_line_count() == 1, note + " The spike line stays on one line")

func layout_done(note: String) -> void:
	var line := label_named("ResearchSpikeOffer")
	var new_product := button_named("New Product")
	var footer := main.company_panel._footer
	var hire := button_named("Hire")
	check(line != null and line.text == DONE and spike_button() == null, note + " shows the gained points")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(fits(line, new_product), note + " The done line sits above New Product")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " The done line does not overlap Hire")
	check(inside_view(line) and inside_view(new_product), note + " The done line and New Product stay inside the journey")
	check(line.get_line_count() == 1, note + " The done line stays on one line")

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
	check(label_named("ResearchSpikeOffer") == null and spike_button() == null, "No research spike control before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	connect_closed("Connect stays closed before a product")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("ResearchSpikeOffer") == null and spike_button() == null, "The build screen has no research spike control")
	await open_journey()
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var stripped_product: Dictionary = stripped_tycoon.get("developing", {}).duplicate(true)
	stripped_product.erase("researchSpike")
	stripped_tycoon["developing"] = stripped_product
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(label_named("ResearchSpikeOffer") == null and spike_button() == null, "A payload without researchSpike draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(label_named("ResearchSpikeOffer"))
	layout_offer("Day 0")
	check(bool(spike_block().get("enabled", false)) and not bool(spike_block().get("pending", true)) and not bool(spike_block().get("used", true)) and str(spike_block().get("reason", "x")) == "" and int(spike_block().get("points", -1)) == 0, "Day 0 research spike is offered")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	var days_before := int(developing().get("devDays", -1))
	await click(spike_button())
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("ResearchSpikeOffer") != null and label_named("ResearchSpikeOffer").text == PENDING and spike_button() == null
	, "Research spike marks tomorrow")
	if shown:
		await frames(3)
		await reveal(label_named("ResearchSpikeOffer"))
		check(label_named("ResearchSpikeOffer").get_line_count() == 1, "The pending line stays on one line")
		check(inside_view(label_named("ResearchSpikeOffer")) and inside_view(button_named("New Product")), "The pending line and New Product stay inside the journey")
		check(company_cash() == cash_before and company_reputation() == fans_before and int(developing().get("devDays", -1)) == days_before, "Marking the spike spends nothing and adds no day")
		check(int(developing().get("design", -1)) == 0 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "Marking the spike leaves earned points")
		check(bool(spike_block().get("pending", false)) and int(spike_block().get("points", -1)) == 0, "The payload stays pending with no points yet")
	connect_closed("Connect stays closed after the spike is set")
	await end_office_day()
	await open_journey()
	await reveal(label_named("ResearchSpikeOffer"))
	layout_done("After the spike day")
	check(int(developing().get("devDays", -1)) == 1 and int(developing().get("design", -1)) == 0 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "The spike day counts and converts craft")
	check(int(tycoon_state().get("researchPoints", -1)) == 7 and int(spike_block().get("points", -1)) == 6 and bool(spike_block().get("used", false)), "The spike day stores the craft and the usual point")
	check(label_named("ResearchPoints") != null and label_named("ResearchPoints").text == "7 research points", "The Research card shows the balance")
	check(company_cash() == 0 and company_reputation() == 0, "The spike day leaves cash and fans")
	connect_closed("Connect stays closed after the spike day")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("ResearchSpikeOffer"))
	layout_done("Reopened")
	check(str(label_named("ResearchSpikeOffer").text) == DONE and bool(spike_block().get("used", false)) and int(spike_block().get("points", -1)) == 6 and int(developing().get("devDays", -1)) == 1, "Reopening keeps the used spike")
	check(int(tycoon_state().get("researchPoints", -1)) == 7 and company_cash() == 0 and company_reputation() == 0, "Reopening keeps the research points, cash, and fans")
	connect_closed("Connect stays closed after reopen")
	await end_office_day()
	await open_journey()
	await reveal(label_named("ResearchSpikeOffer"))
	check(label_named("ResearchSpikeOffer") != null and label_named("ResearchSpikeOffer").text == DONE and spike_button() == null, "The day after the spike keeps the done line")
	check(int(developing().get("design", -1)) == 2 and int(developing().get("tech", -1)) == 2 and int(developing().get("hype", -1)) == 2 and int(developing().get("devDays", -1)) == 2, "The next office day adds craft again")
	check(int(tycoon_state().get("researchPoints", -1)) == 8 and int(spike_block().get("points", -1)) == 6, "The next office day adds the usual point and keeps the spike points")
	connect_closed("Connect stays closed after the normal day")
	print("TYCOON RESEARCH SPIKE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
