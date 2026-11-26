extends SceneTree

## Headless let-go playtest with the real worker and an isolated company.
## Skipping it leaves the balanced newsletter. Dismissing someone drops them from the build.

const MAIN := preload("res://world/main.tscn")
const NOTICE := "Mina left the company."
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-let-go-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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
	var script_path := root.path_join("check-let-go.mjs")
	var body := """import { mkdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
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
function ids(db) {
  return db.tycoon.view().developing.staffIds.join(',');
}
const start = source.indexOf('letGo(staffId: string');
const slice = source.slice(start, source.indexOf('researchSpike()', start));
if (/fetch|https?:|Connect|credential|openrouter/iu.test(slice)) fail('connect');
if (parseRequest({ kind: 'request', id: 'letgo', method: 'tycoon.letGo', params: { staffId: 'mira' } }).method !== 'tycoon.letGo') fail('parse');
if (parseRequest({ kind: 'request', id: 'letgo', method: 'tycoon.letGo', params: { staffId: 'founder' } }).method !== 'tycoon.letGo') fail('founder parse');
mustThrow(() => parseRequest({ kind: 'request', id: 'letgo', method: 'tycoon.letGo', params: { staffId: 'nope' } }), /Invalid protocol request/, 'unknown protocol');
mustThrow(() => parseRequest({ kind: 'request', id: 'letgo', method: 'tycoon.letGo', params: {} }), /Invalid protocol request/, 'missing');
mustThrow(() => parseRequest({ kind: 'request', id: 'letgo', method: 'tycoon.letGo', params: { staffId: 'mira', extra: true } }), /Invalid protocol request/, 'extra');

const fresh = open('fresh');
mustThrow(() => fresh.tycoon.letGo('founder'), /The founder stays\\./, 'founder');
mustThrow(() => fresh.tycoon.letGo('nope'), /Unknown teammate/, 'unknown');
mustThrow(() => fresh.tycoon.letGo('mira'), /Mina is not on the team yet\\./, 'not hired');
if (fresh.tycoon.view().staff.find((person) => person.id === 'founder').letGo.enabled !== false) fail('founder offer');
if (fresh.tycoon.view().letGoNotice !== '') fail('fresh notice');
fresh.close();

const bench = open('bench');
bench.journey.hire('mira', 1);
bench.tycoon.start('crypto', 'newsletter', ['mira']);
bench.endDay(1);
if (ids(bench) !== 'founder,mira' || bench.tycoon.view().developing.design !== 5 || bench.tycoon.view().developing.tech !== 4 || bench.tycoon.view().developing.hype !== 3 || bench.tycoon.view().developing.devDays !== 1) fail('earned');
if (bench.tycoon.view().payroll.cents !== 8000) fail('payroll before');
const beforeTx = bench.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n;
const beforeDay = bench.clockState().day;
const beforeCash = bench.journey.state().company.cashCents;
bench.tycoon.letGo('mira');
mustThrow(() => bench.tycoon.letGo('mira'), /Mina already left\\./, 'repeat');
if (ids(bench) !== 'founder') fail('dropped');
if (bench.tycoon.view().developing.design !== 5 || bench.tycoon.view().developing.tech !== 4 || bench.tycoon.view().developing.hype !== 3 || bench.tycoon.view().developing.devDays !== 1) fail('points moved');
if (bench.journey.db.prepare('SELECT COUNT(*) AS n FROM company_transactions').get().n !== beforeTx) fail('ledger');
if (bench.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:letgo%' OR id LIKE 'tycoon:letGo%'\").all().length !== 0) fail('letgo row');
if (bench.clockState().day !== beforeDay || bench.journey.state().company.cashCents !== beforeCash) fail('clock or cash');
if (bench.journey.db.prepare('SELECT seed FROM tycoon_meta WHERE id = 1').get().seed !== 26021) fail('seed');
if (bench.tycoon.view().payroll.cents !== 0 || bench.tycoon.view().letGoNotice !== 'Mina left the company.') fail('notice');
if (bench.bootstrap().employees.some((person) => person.id === 'mira')) fail('roster');
bench.endDay(bench.clockState().day);
if (bench.tycoon.view().developing.design !== 7 || bench.tycoon.view().developing.tech !== 6 || bench.tycoon.view().developing.hype !== 5) fail('later day');
const file = root + '/bench/startup-valley.sqlite';
const project = root + '/bench/company-project';
bench.close();
const reopened = new GameDatabase(file, project);
if (reopened.tycoon.view().letGoNotice !== 'Mina left the company.' || ids(reopened) !== 'founder') fail('reopen');
mustThrow(() => reopened.tycoon.letGo('mira'), /Mina already left\\./, 'reopen repeat');
reopened.journey.hire('mira', reopened.clockState().day);
if (reopened.tycoon.view().payroll.cents !== 8000 || reopened.tycoon.view().letGoNotice !== '' || reopened.tycoon.view().staff.find((person) => person.id === 'mira').letGo.enabled !== true) fail('rehire');
reopened.tycoon.letGo('mira');
mustThrow(() => reopened.tycoon.letGo('mira'), /Mina already left\\./, 'third');
reopened.close();

const payday = open('payday');
payday.journey.hire('mira', 1);
payday.setClock(27, 480, 0);
payday.endDay(27);
payday.tycoon.letGo('mira');
payday.tycoon.tickDay(28);
if (payday.journey.state().company.cashCents !== 0) fail('payday cash');
if (payday.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'\").all().length !== 0) fail('payday row');
payday.close();

const gated = open('gated');
gated.journey.db.prepare(\"UPDATE employees SET employment_status = 'hired', hired_day = 1 WHERE id = 'theo'\").run();
gated.tycoon.letGo('theo');
mustThrow(() => gated.journey.hire('theo', 1), /Candidate is not available yet/, 'theo gate');
gated.close();

const alone = open('alone');
alone.journey.hire('mira', 1);
alone.tycoon.start('crypto', 'newsletter', ['mira']);
alone.tycoon.assignTeam(['mira']);
alone.endDay(1);
alone.tycoon.letGo('mira');
if (ids(alone) !== '') fail('empty team');
const kept = alone.tycoon.view().developing.design;
alone.endDay(alone.clockState().day);
if (alone.tycoon.view().developing.design !== kept || alone.tycoon.view().developing.devDays !== 2) fail('empty day');
alone.close();

const shipped = open('shipped');
shipped.journey.hire('mira', 1);
shipped.tycoon.start('crypto', 'newsletter', ['mira']);
shipped.endDay(1);
shipped.endDay(2);
shipped.tycoon.release('p1');
const posted = shipped.tycoon.view().history[0].salesCents;
const postedStaff = shipped.journey.db.prepare(\"SELECT staff_json FROM tycoon_products WHERE id = 'p1'\").get().staff_json;
shipped.tycoon.letGo('mira');
if (shipped.tycoon.view().history[0].salesCents !== posted) fail('posted sales');
if (shipped.journey.db.prepare(\"SELECT staff_json FROM tycoon_products WHERE id = 'p1'\").get().staff_json !== postedStaff) fail('shipped staff');
shipped.close();

const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].salesCents !== 20700) fail('skip launch');
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || skip.tycoon.view().history[0].salesCents !== 33300) fail('skip next');
skip.close();
console.log('LET GO RULES OK');
"""
	body = body.replace("IMPORT_DATABASE", JSON.stringify(database)).replace("IMPORT_VALIDATION", JSON.stringify(validation)).replace("TYCOON_FILE", JSON.stringify(tycoon))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the let go rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Let go rules hold (%s)" % " ".join(output))
	return code == 0

func seed_play() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var script_path := data_dir.path_join("seed-play.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', ['mira']);\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\ndb.close();\nif (!view || view.devDays !== 1 || view.design !== 5 || view.staffIds.join(',') !== 'founder,mira') process.exit(2);\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the let go play seed")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded the let go company (%s)" % " ".join(output))
	return code == 0

func layout_offer(note: String) -> void:
	var card := main.company_panel.find_child("TrainStaff", true, false) as Control
	var leave := let_go_button("mira")
	var train := main.company_panel.find_child("Train_mira_design", true, false) as Button
	var hire := button_named("Hire Theo")
	var footer := main.company_panel._footer
	var row := main.company_panel.find_child("LetGoRow_mira", true, false) as Control
	check(card != null and leave != null and card.is_ancestor_of(leave), note + " shows Let go on Train staff")
	check(secondary(leave) and leave.text == "Let go", note + " Let go is secondary")
	check(let_go_button("founder") == null, note + " the founder has no Let go button")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", note + " Hire stays the one primary action")
	check(only_hire_primary(), note + " nothing else is primary")
	check(train != null and str(train.get_meta("cozy_variant", "")) == "secondary" and fits(leave, train), note + " Let go sits above Train")
	check(footer != null and not leave.get_global_rect().intersects(footer.get_global_rect()), note + " Let go does not overlap Hire")
	check(inside_view(leave) and inside_view(train), note + " Let go stays inside the journey")
	check(leave.size.x + 1.0 >= leave.get_combined_minimum_size().x, note + " Let go text fits the button")
	var stats := row.get_child(0) as Control if row != null and row.get_child_count() > 0 else null
	check(stats != null and stats.get_global_rect().end.x <= leave.get_global_rect().position.x + 1.0, note + " the name does not cover Let go")

func layout_done(note: String) -> void:
	var line := label_named("LetGoNotice")
	var card := main.company_panel.find_child("TrainStaff", true, false) as Control
	var hire := button_named("Hire")
	var footer := main.company_panel._footer
	check(line != null and line.text == NOTICE and card != null and card.is_ancestor_of(line), note + " says Mina left")
	check(let_go_button("mira") == null and let_go_button("founder") == null, note + " the Let go button is gone")
	check(line.get_line_count() == 1, note + " the status stays on one line")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary" and only_hire_primary(), note + " Hire stays the one primary action")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), note + " the status does not overlap Hire")
	check(inside_view(line), note + " the status stays inside the journey")

func staff_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	var value: Variant = developing().get("staffIds", [])
	if value is Array:
		for item: Variant in value as Array:
			ids.append(str(item))
	return ids

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
		person.erase("letGo")
		next_staff.append(person)
	stripped_tycoon["staff"] = next_staff
	stripped_tycoon.erase("letGoNotice")
	stripped["tycoon"] = stripped_tycoon
	main.company_panel.update_state(stripped)
	await frames(4)
	check(let_go_button("mira") == null and label_named("LetGoNotice") == null, "A payload without letGo draws no control")
	main.company_panel.update_state(saved)
	await frames(4)
	await reveal(main.company_panel.find_child("TrainStaff", true, false) as Control)
	layout_offer("Offer")
	check(payroll_cents() == 8000 and int(developing().get("design", 0)) == 5 and int(developing().get("devDays", 0)) == 1, "The offer keeps the earned day and Mina's payroll")
	check(staff_ids() == PackedStringArray(["founder", "mira"]), "Mina is still on the build")
	var day_before := main.day_clock.day
	connect_closed("Connect stays closed before Let go")
	await click(let_go_button("mira"))
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("LetGoNotice") != null and label_named("LetGoNotice").text == NOTICE and let_go_button("mira") == null and not main._employees.has("mira")
	, "Mina left the company and left the office")
	if shown:
		await frames(3)
		await reveal(label_named("LetGoNotice"))
		layout_done("Done")
		check(company_cash() == 0 and company_reputation() == 0 and payroll_cents() == 0, "Dismissal leaves cash and drops payroll")
		check(int(developing().get("design", 0)) == 5 and int(developing().get("tech", 0)) == 4 and int(developing().get("hype", 0)) == 3 and int(developing().get("devDays", 0)) == 1, "Earned days and points stay")
		check(staff_ids() == PackedStringArray(["founder"]), "The build drops Mina")
		check(main.day_clock.day == day_before, "Dismissal does not move the clock")
		var header := label_named("OfficeDate")
		check(header != null and header.text.contains("Spring 2") and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at Spring 2, $0, and 0 reputation")
	connect_closed("Connect stays closed after Let go")
	await release_company()
	await create_timer(2.0).timeout
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	await reveal(label_named("LetGoNotice"))
	layout_done("Reopened")
	check(not main._employees.has("mira") and staff_ids() == PackedStringArray(["founder"]) and payroll_cents() == 0, "Reopening keeps Mina off the team and out of the office")
	check(int(developing().get("design", 0)) == 5 and company_cash() == 0, "Reopening keeps the earned points and cash")
	connect_closed("Connect stays closed after reopen")
	await click(button_named("Hire Mina"))
	var rehired := await wait_until(func() -> bool:
		return not main.company_panel.busy and main._employees.has("mira")
	, "Hiring Mina again uses the usual hire")
	if rehired:
		var journey := button_named("Company Journey")
		if journey != null:
			await click(journey)
		else:
			await open_journey()
		await wait_until(func() -> bool: return main.company_panel.screen == "journey" and let_go_button("mira") != null, "Let go returns after the rehire")
		check(payroll_cents() == 8000 and label_named("LetGoNotice") == null and secondary(let_go_button("mira")), "The rehire restores payroll and Let go")
		check(only_hire_primary(), "Hire stays the one primary action after the rehire")
	connect_closed("Connect stays closed after the rehire")
	print("TYCOON LET GO ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
