extends SceneTree

## Headless part-time playtest with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. Part-time halves later craft and salary.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-part-time-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func pace_button(staff_id: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child("Pace_%s" % staff_id, true, false) as Button

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
	var script_path := root.path_join("check-part-time.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { GameDatabase } from IMPORT_DATABASE;
import { parseRequest } from IMPORT_VALIDATION;
import { pacedCraft, payrollCents } from IMPORT_TYCOON;

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
const start = source.indexOf('setPace(staffId: string');
const slice = source.slice(start, source.indexOf('letGo(staffId: string', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
if (!slice.includes('The founder stays full time.')) fail('founder text');
if (!slice.includes('Pick full time or part-time.')) fail('bad pace text');
if (!slice.includes('already part-time.')) fail('noop part');
if (!slice.includes('already full time.')) fail('noop full');
if (pacedCraft({ design: 3, tech: 2, hype: 1 }, 'part').design !== 1 || pacedCraft({ design: 3, tech: 2, hype: 1 }, 'part').tech !== 1 || pacedCraft({ design: 3, tech: 2, hype: 1 }, 'part').hype !== 0) fail('floor');
if (payrollCents(['mira'], { mira: 'part' }) !== 4000 || payrollCents(['theo'], { theo: 'part' }) !== 5000 || payrollCents(['creative'], { creative: 'part' }) !== 6000 || payrollCents(['mira']) !== 8000) fail('salary floor');
if (parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'mira', pace: 'part' } }).method !== 'tycoon.setPace') fail('parse');
if (parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'founder', pace: 'full' } }).method !== 'tycoon.setPace') fail('founder parse');
mustThrow(() => parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'nope', pace: 'part' } }), /Invalid protocol request/, 'unknown protocol');
mustThrow(() => parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'mira', pace: 'half' } }), /Invalid protocol request/, 'bad pace protocol');
mustThrow(() => parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'mira' } }), /Invalid protocol request/, 'missing');
mustThrow(() => parseRequest({ kind: 'request', id: 'pace', method: 'tycoon.setPace', params: { staffId: 'mira', pace: 'part', extra: true } }), /Invalid protocol request/, 'extra');

const fresh = open('fresh');
mustThrow(() => fresh.tycoon.setPace('founder', 'part'), /The founder stays full time\\./, 'founder part');
mustThrow(() => fresh.tycoon.setPace('founder', 'full'), /The founder stays full time\\./, 'founder full');
mustThrow(() => fresh.tycoon.setPace('founder', 'sideways'), /Pick full time or part-time\\./, 'founder bad');
mustThrow(() => fresh.tycoon.setPace('nope', 'part'), /Unknown teammate/, 'unknown');
mustThrow(() => fresh.tycoon.setPace('nope', 'sideways'), /Unknown teammate/, 'unknown wins');
mustThrow(() => fresh.tycoon.setPace('mira', 'part'), /Mina is not on the team yet\\./, 'not hired');
mustThrow(() => fresh.tycoon.setPace('mira', 'full'), /Mina is not on the team yet\\./, 'not hired full');
mustThrow(() => fresh.tycoon.setPace('theo', 'part'), /Theo is not on the team yet\\./, 'theo');
mustThrow(() => fresh.tycoon.setPace('mira', 'half'), /Pick full time or part-time\\./, 'bad pace');
const founderPace = fresh.tycoon.view().staff.find((person) => person.id === 'founder').pace;
const minaPace = fresh.tycoon.view().staff.find((person) => person.id === 'mira').pace;
if (founderPace.value !== 'full' || founderPace.enabled !== false) fail('founder offer');
if (minaPace.value !== 'full' || minaPace.enabled !== false) fail('not hired offer');
fresh.close();

const bench = open('bench');
bench.journey.hire('mira', 1);
bench.tycoon.start('crypto', 'newsletter', ['mira']);
bench.endDay(1);
const worked = bench.tycoon.view().developing;
if (!worked || worked.devDays !== 1 || worked.design !== 5 || worked.tech !== 4 || worked.hype !== 3 || bench.tycoon.view().researchPoints !== 2) fail('earned');
if (bench.tycoon.view().payroll.cents !== 8000) fail('payroll before');
mustThrow(() => bench.tycoon.setPace('mira', 'full'), /Mina is already full time\\./, 'noop full');
const beforeTx = bench.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n;
const beforeDay = bench.clockState().day;
const beforeCash = bench.journey.state().company.cashCents;
const beforeStaff = bench.journey.db.prepare(\"SELECT staff_json FROM tycoon_products WHERE id = 'p1'\").get().staff_json;
bench.tycoon.setPace('mira', 'part');
mustThrow(() => bench.tycoon.setPace('mira', 'part'), /Mina is already part-time\\./, 'noop part');
const offered = bench.tycoon.view().staff.find((person) => person.id === 'mira').pace;
if (offered.value !== 'part' || offered.enabled !== true) fail('part offer');
if (bench.tycoon.view().payroll.cents !== 4000) fail('half salary');
const stayed = bench.tycoon.view().developing;
if (stayed.design !== 5 || stayed.tech !== 4 || stayed.hype !== 3 || stayed.devDays !== 1) fail('earlier day');
if (bench.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n !== beforeTx) fail('ledger');
if (bench.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pace%' OR id LIKE 'tycoon:setPace%' OR id LIKE 'tycoon:setpace%'\").all().length !== 0) fail('pace row');
if (bench.clockState().day !== beforeDay || bench.journey.state().company.cashCents !== beforeCash) fail('clock or cash');
if (bench.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== 26021) fail('seed');
if (bench.journey.db.prepare(\"SELECT staff_json FROM tycoon_products WHERE id = 'p1'\").get().staff_json !== beforeStaff) fail('product staff');
const meta = JSON.parse(bench.journey.db.prepare('SELECT staff_json FROM tycoon_meta WHERE id = 1').get().staff_json);
if (meta.mira.pace !== 'part' || meta.founder.pace !== undefined) fail('stored pace');
bench.endDay(bench.clockState().day);
const halved = bench.tycoon.view().developing;
if (halved.devDays !== 2 || halved.design !== 8 || halved.tech !== 7 || halved.hype !== 5 || bench.tycoon.view().researchPoints !== 4) fail('later day');
bench.tycoon.setPace('mira', 'full');
mustThrow(() => bench.tycoon.setPace('mira', 'full'), /Mina is already full time\\./, 'restored noop');
if (bench.tycoon.view().payroll.cents !== 8000 || bench.tycoon.view().developing.design !== 8) fail('switch back');
const restoredMeta = JSON.parse(bench.journey.db.prepare('SELECT staff_json FROM tycoon_meta WHERE id = 1').get().staff_json);
if (restoredMeta.mira.pace !== undefined) fail('full omits pace');
bench.endDay(bench.clockState().day);
const restored = bench.tycoon.view().developing;
if (restored.devDays !== 3 || restored.design !== 13 || restored.tech !== 11 || restored.hype !== 8) fail('full day again');
bench.close();

const reopen = open('reopen');
reopen.journey.hire('mira', 1);
reopen.tycoon.setPace('mira', 'part');
const file = root + '/reopen/startup-valley.sqlite';
const project = root + '/reopen/company-project';
reopen.close();
const reopened = new GameDatabase(file, project);
const again = reopened.tycoon.view().staff.find((person) => person.id === 'mira').pace;
if (again.value !== 'part' || again.enabled !== true || reopened.tycoon.view().payroll.cents !== 4000) fail('reopen');
mustThrow(() => reopened.tycoon.setPace('mira', 'part'), /Mina is already part-time\\./, 'reopen noop');
reopened.tycoon.letGo('mira');
mustThrow(() => reopened.tycoon.setPace('mira', 'part'), /Mina already left\\./, 'dismissed');
const left = reopened.tycoon.view().staff.find((person) => person.id === 'mira').pace;
if (left.value !== 'full' || left.enabled !== false) fail('dismissed offer');
reopened.journey.hire('mira', reopened.clockState().day);
const hiredAgain = reopened.tycoon.view().staff.find((person) => person.id === 'mira').pace;
if (hiredAgain.value !== 'full' || hiredAgain.enabled !== true || reopened.tycoon.view().payroll.cents !== 8000) fail('rehire full');
reopened.close();

const payday = open('payday');
payday.journey.hire('mira', 1);
payday.tycoon.setPace('mira', 'part');
payday.setClock(27, 480, 0);
payday.endDay(27);
payday.tycoon.tickDay(28);
if (payday.journey.state().company.cashCents !== -4000) fail('payday cash');
if (payday.journey.db.prepare(\"SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'\").get().cash_delta !== -4000) fail('payday row');
payday.tycoon.tickDay(28);
if (payday.journey.state().company.cashCents !== -4000) fail('payday replay');
payday.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700) fail('skip launch');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || skip.tycoon.view().history[0].salesCents !== 33300) fail('skip next');
if (skip.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pace%' OR id LIKE 'tycoon:setPace%' OR id LIKE 'tycoon:setpace%'\").all().length !== 0) fail('skip row');
skip.close();
console.log('PART TIME RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("IMPORT_TYCOON", JSON.stringify(tycoon)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the part-time rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Part-time rules hold (%s)" % " ".join(output))
	return code == 0

func seed_play() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := data_dir.path_join("seed-play.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', ['mira']);\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\nconst mina = db.tycoon.view().staff.find((person) => person.id === 'mira');\ndb.close();\nif (!view || view.devDays !== 1 || view.design !== 5 || view.staffIds.join(',') !== 'founder,mira' || !mina || !mina.pace || mina.pace.value !== 'full' || mina.pace.enabled !== true) process.exit(2);\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the part-time play seed")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded the part-time company (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var card := main.company_panel.find_child("TrainStaff", true, false) as Control
	var pace := pace_button("mira")
	var leave := let_go_button("mira")
	var train := main.company_panel.find_child("Train_mira_design", true, false) as Button
	var hire := button_named("Hire Theo")
	var footer := main.company_panel._footer
	var row := main.company_panel.find_child("LetGoRow_mira", true, false) as Control
	var stats := label_named("StaffLine_mira")
	check(card != null and pace != null and card.is_ancestor_of(pace), note + " shows Part-time on Train staff")
	check(secondary(pace) and pace.text == "Part-time", note + " Part-time is secondary")
	check(leave != null and secondary(leave) and row != null and row.is_ancestor_of(pace) and row.is_ancestor_of(leave), note + " Part-time sits beside Let go")
	check(pace_button("founder") == null, note + " the founder has no pace button")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(only_hire_primary(), note + " nothing else is primary")
	check(train != null and str(train.get_meta("cozy_variant", "")) == "secondary" and fits(pace, train) and fits(leave, train), note + " the pace row sits above Train")
	check(footer != null and not pace.get_global_rect().intersects(footer.get_global_rect()) and not leave.get_global_rect().intersects(footer.get_global_rect()), note + " the row does not overlap Hire")
	check(inside_view(pace) and inside_view(leave) and inside_view(train) and inside_view(stats), note + " the row stays inside the journey")
	check(pace.size.x + 1.0 >= pace.get_combined_minimum_size().x and leave.size.x + 1.0 >= leave.get_combined_minimum_size().x, note + " the button text fits")
	check(stats != null and stats.get_line_count() == 1 and not stats.text.contains("part-time"), note + " the name stays one full-time line")
	check(stats != null and stats.get_global_rect().end.x <= pace.get_global_rect().position.x + 1.0 and pace.get_global_rect().end.x <= leave.get_global_rect().position.x + 1.0, note + " the name does not cover the buttons")
	check(text_fits(stats, stats), note + " the name text fits its slot")

func layout_part(note: String) -> void:
	var pace := pace_button("mira")
	var leave := let_go_button("mira")
	var stats := label_named("StaffLine_mira")
	var train := main.company_panel.find_child("Train_mira_design", true, false) as Button
	var footer := main.company_panel._footer
	check(secondary(pace) and pace.text == "Full time", note + " the button offers Full time")
	check(stats != null and stats.text.contains("part-time") and stats.get_line_count() == 1, note + " the status says part-time on one line")
	check(leave != null and pace.get_global_rect().end.x <= leave.get_global_rect().position.x + 1.0, note + " Full time stays beside Let go")
	check(stats.get_global_rect().end.x <= pace.get_global_rect().position.x + 1.0 and text_fits(stats, stats), note + " the status does not cover the buttons")
	check(fits(pace, train) and footer != null and not pace.get_global_rect().intersects(footer.get_global_rect()), note + " the status row stays above Train and clear of Hire")
	check(inside_view(pace) and inside_view(stats) and inside_view(leave), note + " the part-time row stays inside the journey")
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
		person.erase("pace")
		next_staff.append(person)
	stripped_tycoon["staff"] = next_staff
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	var stripped_line := label_named("StaffLine_mira")
	check(pace_button("mira") == null and (stripped_line == null or not stripped_line.text.contains("part-time")), "A payload without pace draws no control")
	check(let_go_button("mira") != null, "Let go still draws when pace is absent")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(main.company_panel.find_child("TrainStaff", true, false) as Control)
	layout_offer("Offer")
	check(payroll_cents() == 8000 and int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 3 and int(developing().get("devDays", 0)) == 1, "The offer keeps the earned day and Mina's payroll")
	var day_before := main.day_clock.day
	connect_closed("Connect stays closed before Part-time")
	await click(pace_button("mira"))
	var shown := await wait_until(func() -> bool:
		var line := label_named("StaffLine_mira")
		var pace := pace_button("mira")
		return not main.company_panel.busy and line != null and line.text.contains("part-time") and pace != null and pace.text == "Full time" and payroll_cents() == 4000
	, "Mina is part-time and payroll is half")
	if shown:
		await frames(3)
		await reveal(pace_button("mira"))
		layout_part("Set")
		check(company_cash() == 0 and company_reputation() == 0, "Part-time leaves cash and fans")
		check(int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 3 and int(developing().get("devDays", 0)) == 1, "Earned days and points stay")
		check(main.day_clock.day == day_before, "Part-time does not move the clock")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("Spring 2") and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at Spring 2, $0, and 0 reputation")
	connect_closed("Connect stays closed after Part-time")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("StaffLine_mira"))
	layout_part("Reopened")
	check(payroll_cents() == 4000 and int(developing().get("design", 0)) == 5 and company_cash() == 0, "Reopening keeps part-time, the earned points, and cash")
	connect_closed("Connect stays closed after reopen")
	await click(pace_button("mira"))
	var restored := await wait_until(func() -> bool:
		var line := label_named("StaffLine_mira")
		var pace := pace_button("mira")
		return not main.company_panel.busy and line != null and not line.text.contains("part-time") and pace != null and pace.text == "Part-time" and payroll_cents() == 8000
	, "Full time restores payroll and the button")
	if restored:
		await frames(3)
		await reveal(pace_button("mira"))
		layout_offer("Restored")
		check(int(developing().get("design", 0)) == 5 and int(developing().get("devDays", 0)) == 1 and company_cash() == 0, "Switching back leaves the earned day")
	connect_closed("Connect stays closed after switching back")
	print("TYCOON PART TIME ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
