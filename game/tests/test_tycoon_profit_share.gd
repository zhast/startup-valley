extends SceneTree

## Headless profit-share playtest with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. A share cuts later sales and the payday.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-profit-share-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func share_button(staff_id: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("ProfitShare_%s" % staff_id, true, false) as Button

func raise_button(staff_id: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("Raise_%s" % staff_id, true, false) as Button

func let_go_button(staff_id: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("LetGo_%s" % staff_id, true, false) as Button

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

func payroll_cents() -> int:
	var value: Variant = tycoon_state().get("payroll", {})
	return int((value as Dictionary).get("cents", -1)) if value is Dictionary else -1

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
	# The story demo stays the production default. This playtest checks the classic
	# Company Journey, where Hire is the primary action and Train staff is visible.
	main.demo_story_mode = false
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

func text_fits(label: Label, slot: Control) -> bool:
	if label == null or slot == null:
		return false
	var font := label.get_theme_font("font")
	if font == null:
		return false
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font")).x
	return width <= slot.size.x + 1.0

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
	var script_path := root.path_join("check-share.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;
import { payrollCents, profitShareCents, seasonSalaryCents } from IMPORT_TYCOON;

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
const start = source.indexOf('offerProfitShare(staffId: string');
const slice = source.slice(start, source.indexOf('researchSpike()', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
if (!slice.includes('The founder cannot take a profit share.')) fail('founder text');
if (!slice.includes('already has a profit share.')) fail('repeat text');
if (!slice.includes('already has a raise.')) fail('raise text');
if (!slice.includes('is not on the team yet.')) fail('unhired text');
if (profitShareCents(20700) !== 2070 || profitShareCents(9) !== 0) fail('cut');
if (seasonSalaryCents('mira', 'full', false, true) !== 4000 || seasonSalaryCents('mira', 'part', false, true) !== 0) fail('mina salary');
if (payrollCents(['mira'], {}, {}, { mira: true }) !== 4000 || payrollCents(['mira'], { mira: 'part' }, {}, { mira: true }) !== 0) fail('payroll');
if (parseRequest({ kind: 'request', id: 'share', method: 'tycoon.offerProfitShare', params: { staffId: 'mira' } }).method !== 'tycoon.offerProfitShare') fail('parse');
if (parseRequest({ kind: 'request', id: 'share', method: 'tycoon.offerProfitShare', params: { staffId: 'founder' } }).method !== 'tycoon.offerProfitShare') fail('founder parse');
mustThrow(() => parseRequest({ kind: 'request', id: 'share', method: 'tycoon.offerProfitShare', params: { staffId: 'nope' } }), /Invalid protocol request/, 'unknown protocol');
mustThrow(() => parseRequest({ kind: 'request', id: 'share', method: 'tycoon.offerProfitShare', params: {} }), /Invalid protocol request/, 'missing');
mustThrow(() => parseRequest({ kind: 'request', id: 'share', method: 'tycoon.offerProfitShare', params: { staffId: 'mira', extra: true } }), /Invalid protocol request/, 'extra');

const fresh = open('fresh');
mustThrow(() => fresh.tycoon.offerProfitShare('founder'), /The founder cannot take a profit share\\./, 'founder');
mustThrow(() => fresh.tycoon.offerProfitShare('nope'), /Unknown teammate/, 'unknown');
mustThrow(() => fresh.tycoon.offerProfitShare('mira'), /Mina is not on the team yet\\./, 'not hired');
mustThrow(() => fresh.tycoon.offerProfitShare('theo'), /Theo is not on the team yet\\./, 'theo');
if (fresh.tycoon.view().staff.find((person) => person.id === 'founder').profitShare.enabled !== false) fail('founder offer');
if (fresh.tycoon.view().staff.find((person) => person.id === 'mira').profitShare.salaryCents !== 4000) fail('unhired salary');
fresh.close();

const bench = open('bench');
bench.journey.hire('mira', 1);
bench.tycoon.start('crypto', 'newsletter', ['mira']);
bench.endDay(1);
if (bench.tycoon.view().developing.devDays !== 1 || bench.tycoon.view().payroll.cents !== 8000) fail('before share');
const before = bench.journey.db.prepare('SELECT dev_days, design_points, tech_points, hype_points, sales_cents, fans FROM tycoon_products WHERE id = ?').get('p1');
const seed = bench.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed;
const cash = bench.journey.state().company.cashCents;
const fans = bench.journey.state().company.reputation;
bench.tycoon.offerProfitShare('mira');
mustThrow(() => bench.tycoon.offerProfitShare('mira'), /Mina already has a profit share\\./, 'repeat');
mustThrow(() => bench.tycoon.giveRaise('mira'), /Mina already has a profit share\\./, 'stack raise');
if (JSON.stringify(bench.journey.db.prepare('SELECT dev_days, design_points, tech_points, hype_points, sales_cents, fans FROM tycoon_products WHERE id = ?').get('p1')) !== JSON.stringify(before)) fail('posted row');
if (bench.journey.state().company.cashCents !== cash || bench.journey.state().company.reputation !== fans) fail('cash fans');
if (bench.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== seed) fail('seed');
if (bench.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:share%' OR id LIKE 'tycoon:offerProfitShare%'\").all().length !== 0) fail('share command row');
if (bench.tycoon.view().payroll.cents !== 4000) fail('payroll now');
bench.close();

const stacked = open('stacked');
stacked.journey.hire('mira', 1);
stacked.tycoon.giveRaise('mira');
mustThrow(() => stacked.tycoon.offerProfitShare('mira'), /Mina already has a raise\\./, 'stack share');
stacked.close();

const later = open('later');
const control = open('control');
for (const db of [later, control]) {
  db.journey.hire('mira', 1);
  db.tycoon.start('crypto', 'newsletter', ['mira']);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release('p1');
}
const launchCash = later.journey.state().company.cashCents;
const launchSales = later.tycoon.view().history[0].salesCents;
const launchFans = later.tycoon.view().history[0].fans;
later.tycoon.offerProfitShare('mira');
if (later.journey.state().company.cashCents !== launchCash || later.tycoon.view().history[0].salesCents !== launchSales || later.tycoon.view().history[0].fans !== launchFans) fail('posted sale stays');
later.endDay(3);
control.endDay(3);
later.endDay(4);
control.endDay(4);
const daySale = control.tycoon.view().history[0].salesCents - launchSales;
const cut = profitShareCents(daySale);
if (!(daySale > 0 && cut > 0)) fail('follow-up sale');
if (later.tycoon.view().history[0].salesCents !== control.tycoon.view().history[0].salesCents) fail('sales cents');
if (later.journey.state().company.reputation !== control.journey.state().company.reputation) fail('later fans');
if (later.journey.state().company.cashCents !== launchCash + daySale - cut) fail('later cash');
const shareRow = later.journey.db.prepare(\"SELECT cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:share:p1:mira:1'\").get();
if (!shareRow || shareRow.cash_delta !== -cut || shareRow.earned_delta !== 0 || shareRow.reputation_delta !== 0) fail('share row');
later.close();
control.close();

const cleared = open('cleared');
cleared.journey.hire('mira', 1);
cleared.tycoon.offerProfitShare('mira');
cleared.tycoon.letGo('mira');
mustThrow(() => cleared.tycoon.offerProfitShare('mira'), /Mina already left\\./, 'dismissed');
const stored = JSON.parse(cleared.journey.db.prepare('SELECT staff_json FROM tycoon_meta WHERE id = 1').get().staff_json);
if (stored.mira.shared !== undefined) fail('cleared flag');
cleared.journey.hire('mira', cleared.clockState().day);
if (cleared.tycoon.view().payroll.cents !== 8000 || cleared.tycoon.view().staff.find((person) => person.id === 'mira').profitShare.shared !== false) fail('rehire');
cleared.close();

const reopen = open('reopen');
reopen.journey.hire('mira', 1);
reopen.tycoon.offerProfitShare('mira');
const pending = reopen.tycoon.view().staff.find((person) => person.id === 'mira').profitShare;
const file = root + '/reopen/startup-valley.sqlite';
const project = root + '/reopen/company-project';
reopen.close();
const reopened = new GameDatabase(file, project);
const again = reopened.tycoon.view().staff.find((person) => person.id === 'mira').profitShare;
if (JSON.stringify(again) !== JSON.stringify(pending) || reopened.tycoon.view().payroll.cents !== 4000) fail('reopen');
mustThrow(() => reopened.tycoon.offerProfitShare('mira'), /Mina already has a profit share\\./, 'reopen repeat');
reopened.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700) fail('skip launch');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || skip.tycoon.view().history[0].salesCents !== 33300) fail('skip next');
if (skip.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:share%' OR id LIKE 'tycoon:offerProfitShare%'\").all().length !== 0) fail('skip row');
skip.close();
console.log('PROFIT SHARE RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the profit share rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Profit share rules hold (%s)" % " ".join(output))
	return code == 0

func seed_play() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := data_dir.path_join("seed-play.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', ['mira']);\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\nconst mina = db.tycoon.view().staff.find((person) => person.id === 'mira');\ndb.close();\nif (!view || view.devDays !== 1 || view.design !== 5 || view.tech !== 4 || view.hype !== 3 || view.staffIds.join(',') !== 'founder,mira' || !mina || !mina.profitShare || mina.profitShare.enabled !== true || mina.profitShare.salaryCents !== 4000 || mina.profitShare.percent !== 10) process.exit(2);\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the profit share play seed")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded the profit share company (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var card := main.company_panel.find_child("TrainStaff", true, false) as Control
	var share := share_button("mira")
	var line := label_named("ProfitShareLine_mira")
	var give := raise_button("mira")
	var leave := let_go_button("mira")
	var train := main.company_panel.find_child("Train_mira_design", true, false) as Button
	var hire := button_named("Hire Theo")
	var footer := main.company_panel._footer
	var row := main.company_panel.find_child("ProfitShareRow_mira", true, false) as Control
	check(card != null and share != null and card.is_ancestor_of(share), note + " shows Profit share on Train staff")
	if share == null or line == null or give == null or leave == null or train == null or row == null:
		return
	check(secondary(share) and share.text == "Profit share", note + " Profit share is secondary")
	check(share_button("founder") == null, note + " the founder has no profit share button")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(only_hire_primary(), note + " nothing else is primary")
	check(line.text == "Profit share · $40 · 10%" and line.get_line_count() == 1, note + " the hint names the lower salary and the cut")
	check(fits(give, share) and fits(share, train), note + " Profit share sits under Give raise and above Train")
	check(str(train.get_meta("cozy_variant", "")) == "secondary", note + " Train stays secondary")
	check(footer != null and not share.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), note + " the row does not overlap Hire")
	check(inside_view(share) and inside_view(line) and inside_view(give) and inside_view(train), note + " the row stays inside the journey")
	check(share.size.x + 1.0 >= share.get_combined_minimum_size().x, note + " the button text fits")
	check(line.get_global_rect().end.x <= share.get_global_rect().position.x + 1.0 and text_fits(line, line), note + " the hint does not cover Profit share")

func layout_given(note: String) -> void:
	var line := label_named("ProfitShareLine_mira")
	var train := main.company_panel.find_child("Train_mira_design", true, false) as Button
	var footer := main.company_panel._footer
	var card := main.company_panel.find_child("TrainStaff", true, false) as Control
	check(share_button("mira") == null, note + " the button is gone")
	check(raise_button("mira") == null, note + " Give raise is gone after the share")
	check(line != null and card != null and card.is_ancestor_of(line) and line.text == "Sharing · $40 · 10%" and line.get_line_count() == 1, note + " the line names the lower salary")
	if line == null or train == null:
		return
	check(text_fits(line, line), note + " the sharing line fits")
	check(fits(line, train), note + " the sharing line stays above Train")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " the sharing line does not overlap Hire")
	check(inside_view(line) and inside_view(train), note + " the sharing line stays inside the journey")
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
	check(main._employees.has("mira"), "Mina is at a desk")
	var saved := main.company_panel.state.duplicate(true)
	var stripped: Dictionary = saved.duplicate(true)
	var stripped_tycoon: Dictionary = stripped.get("tycoon", {}).duplicate(true)
	var staff: Array = (stripped_tycoon.get("staff", []) as Array).duplicate(true)
	var next_staff: Array = []
	for item: Variant in staff:
		var person: Dictionary = (item as Dictionary).duplicate(true)
		person.erase("profitShare")
		next_staff.append(person)
	stripped_tycoon["staff"] = next_staff
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(share_button("mira") == null and label_named("ProfitShareLine_mira") == null, "A payload without profitShare draws no control")
	check(raise_button("mira") != null, "Give raise still draws when profitShare is absent")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(main.company_panel.find_child("TrainStaff", true, false) as Control)
	layout_offer("Offer")
	check(payroll_cents() == 8000 and int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 3 and int(developing().get("devDays", 0)) == 1, "The offer keeps the earned day and Mina's payroll")
	var day_before := main.day_clock.day
	connect_closed("Connect stays closed before Profit share")
	await click(share_button("mira"))
	var shown := await wait_until(func() -> bool:
		var line := label_named("ProfitShareLine_mira")
		return not main.company_panel.busy and line != null and line.text == "Sharing · $40 · 10%" and share_button("mira") == null and payroll_cents() == 4000
	, "Mina has a profit share and payroll is $40")
	if shown:
		await frames(3)
		await reveal(label_named("ProfitShareLine_mira"))
		layout_given("Set")
		check(company_cash() == 0 and company_reputation() == 0, "A profit share leaves cash and fans")
		check(int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 3 and int(developing().get("devDays", 0)) == 1, "Earned days and points stay")
		check(main.day_clock.day == day_before, "A profit share does not move the clock")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("Spring 2") and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at Spring 2, $0, and 0 reputation")
	connect_closed("Connect stays closed after Profit share")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("ProfitShareLine_mira"))
	layout_given("Reopened")
	check(payroll_cents() == 4000 and int(developing().get("design", 0)) == 5 and company_cash() == 0 and company_reputation() == 0, "Reopening keeps the share, the earned points, and cash")
	connect_closed("Connect stays closed after reopen")
	print("TYCOON PROFIT SHARE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
