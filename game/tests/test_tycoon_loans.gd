extends SceneTree

## Headless loan with the real worker and an isolated company.
## Skipping the loan changes nothing. Taking it pays once and repays once.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-loans-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func company_cash() -> int:
	if main == null or main.company_panel == null:
		return 0
	var company: Dictionary = main.company_panel.state.get("company", {}) if main.company_panel.state.get("company") is Dictionary else {}
	return int(company.get("cashCents", 0))

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

func seed_company(data_dir: String, take_loan: bool, day: int) -> bool:
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
	var script_path := data_dir.path_join("seed-loan.mjs")
	var take := "true" if take_loan else "false"
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\nif (%s) db.tycoon.takeLoan();\ndb.setClock(%d, 480, 0);\nconst loan = db.tycoon.view().loan;\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nconst expectedCash = %s ? 50000 : 0;\nif (cash !== expectedCash || loan.outstanding !== %s) { console.error(JSON.stringify({ cash: cash, loan: loan })); process.exit(2); }\n" % [JSON.stringify(database), take, day, take, take]
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the loan seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded loan company (%s)" % " ".join(output))
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
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan · $500, repay $550 on Spring 28", "The Season card names the loan offer")
	var take := button_named("Take loan")
	check(take != null and not take.disabled and str(take.get_meta("cozy_variant", "")) == "secondary", "Take loan is a secondary action")
	check(company_cash() == 0, "Skipping the loan leaves cash at $0")
	await click(take)
	await wait_until(func() -> bool: return company_cash() == 50000 and not main.company_panel.busy, "Taking the loan adds $500")
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan due · $550 on Spring 28", "The Season card names the due loan")
	check(button_named("Take loan") == null, "The take button hides while a loan is out")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$500.00"), "The header shows the loan cash")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the loan")
	var seeded := OS.get_temp_dir().path_join("startup-valley-tycoon-loans-seed-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_company(seeded, true, 28):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot():
		_finish()
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	check(company_cash() == 50000, "The seeded loan is still $500 on Spring 28")
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan due · $550 on Spring 28", "Spring 28 still shows the due loan")
	check(button_named("Take loan") == null, "Spring 28 does not offer a second loan")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 28") and header.text.contains("$500.00"), "Spring 28 still shows the loan cash")
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending Spring 28 opens the summary")
	check(label_contains("Loan repaid"), "The summary names the repayment")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("cash is negative") and header.text.contains("−$50.00"), "Repayment leaves cash at −$50")
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan · $500, repay $550 on Summer 28", "After repayment a new loan is offered")
	take = button_named("Take loan")
	check(take != null and str(take.get_meta("cozy_variant", "")) == "secondary", "Take loan returns as a secondary action")
	await click(take)
	await wait_until(func() -> bool: return company_cash() == 45000 and not main.company_panel.busy, "A second loan pays after the first is repaid")
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan due · $550 on Summer 28", "The second loan is due on Summer 28")
	check(button_named("Take loan") == null, "A second outstanding loan hides the button")
	print("TYCOON LOANS ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
