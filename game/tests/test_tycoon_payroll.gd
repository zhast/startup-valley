extends SceneTree

## Headless payroll with the real worker and an isolated company.
## No hires leaves the Season card quiet. One hire is paid once on Spring 28.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-payroll-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func label_contains(fragment: String) -> bool:
	if main == null or main.company_panel == null:
		return false
	for node: Node in main.company_panel.find_children("*", "Label", true, false):
		if (node as Label).text.contains(fragment):
			return true
	return false

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

func seed_mina(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-payroll.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.setClock(28, 480, 0);\nconst payroll = db.tycoon.view().payroll;\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nif (cash !== 0 || payroll.cents !== 8000 || payroll.payday !== 'Spring 28') { console.error(JSON.stringify({ cash: cash, payroll: payroll })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the payroll seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded Mina on Spring 28 with $0 (%s)" % " ".join(output))
	return code == 0

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(label_named("SeasonPayroll") != null and label_named("SeasonPayroll").text == "No payroll yet", "A company with no hires has no payroll")
	check(label_named("PayrollNotice") == null, "No payday notice before anyone is hired")
	var header := label_named("OfficeDate")
	check(header != null and not header.text.contains("cash is negative"), "Fresh cash is not marked negative")
	var seeded := OS.get_temp_dir().path_join("startup-valley-tycoon-payroll-seed-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_mina(seeded):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot():
		_finish()
		return
	var continue_button := button_named("Continue")
	if continue_button != null:
		await click(continue_button)
	await dismiss_onboarding()
	await open_journey()
	check(label_named("SeasonPayroll") != null and label_named("SeasonPayroll").text == "Payroll · $80 on Spring 28", "The Season card names the payday")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 28") and header.text.contains("$0.00"), "Spring 28 still shows $0.00 before payday")
	check(button_named("Payroll") == null, "Payroll is not a new button")
	var engine := button_named("Buy TownSquare Kit Engine")
	check(engine != null and engine.disabled and engine.text.contains("Need $120"), "The engine stays locked at $0")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending Spring 28 opens the summary")
	check(label_contains("Payroll: Spring"), "The summary names the payroll row")
	check(label_named("PayrollNotice") != null and label_named("PayrollNotice").text == "Paid payroll · −$80", "The payday notice names the amount")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("cash is negative") and header.text.contains("−$80.00"), "The header says cash is negative")
	check(label_named("SeasonPayroll") != null and label_named("SeasonPayroll").text == "Payroll · $80 on Summer 28", "The next payday is Summer 28")
	check(label_named("PayrollNotice") != null and label_named("PayrollNotice").text == "Paid payroll · −$80", "The paid notice stays until the next day ends")
	check(label_named("CashNegative") != null and label_named("CashNegative").text == "Cash is negative", "The Season card says cash is negative")
	engine = button_named("Buy TownSquare Kit Engine")
	check(engine != null and engine.disabled and engine.text.contains("Need $120"), "Negative cash keeps the engine locked")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending Summer 1 opens the summary")
	check(label_named("PayrollNotice") == null, "The payday notice clears when the next day ends")
	check(not label_contains("Payroll: Summer"), "Summer 1 does not pay again")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "The office opens on Summer 2")
	main.day_clock.set_speed(0)
	await open_journey()
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("−$80.00") and header.text.contains("cash is negative"), "Cash stays −$80 after the notice clears")
	check(label_named("PayrollNotice") == null, "The Season card drops the paid notice")
	check(label_named("SeasonPayroll") != null and label_named("SeasonPayroll").text == "Payroll · $80 on Summer 28", "Summer 28 is still the next payday")
	print("TYCOON PAYROLL ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
