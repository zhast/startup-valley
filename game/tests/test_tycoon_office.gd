extends SceneTree

## Headless office expansion with the real worker and an isolated company.
## The Garage Loft card is locked. A seeded team then buys the Open Floor.

const MAIN := preload("res://world/main.tscn")
const SPARE := ["spare-compact-a", "spare-compact-b", "spare-workbench"]
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	var data_dir := OS.get_temp_dir().path_join("startup-valley-tycoon-office-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func company_cash() -> int:
	var company: Dictionary = main.company_panel.state.get("company", {})
	return int(company.get("cashCents", 0))

func office_state() -> Dictionary:
	var tycoon: Variant = main.company_panel.state.get("tycoon", {})
	if not tycoon is Dictionary:
		return {}
	var office: Variant = (tycoon as Dictionary).get("office", {})
	return office as Dictionary if office is Dictionary else {}

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

func spare_present() -> int:
	var count := 0
	for id: String in SPARE:
		if main.room.prop_node(id) != null:
			count += 1
	return count

var spare_problem := ""

func _has_structure_layer(node: Node, role: String) -> bool:
	var needle := role.replace("_", "")
	for child: Node in node.get_children():
		if child is Sprite2D and str(child.name).to_lower().replace("_", "").contains(needle):
			return true
	return false

func spare_clear() -> bool:
	spare_problem = ""
	for id: String in SPARE:
		var placement := main.room.placement_by_id(id)
		if placement.is_empty() or str(placement.get("facing", "")) != "south":
			spare_problem = "%s facing %s" % [id, str(placement.get("facing", "missing"))]
			return false
		var node := main.room.prop_node(id)
		if node == null:
			spare_problem = "%s has no prop" % id
			return false
		for layer_name: String in ["floor_shadow", "rear_structure", "front_structure"]:
			if not _has_structure_layer(node, layer_name):
				spare_problem = "%s missing %s" % [id, layer_name]
				return false
		var bounds: Rect2 = placement.get("world_visual_bounds", Rect2())
		var occupied: Array = placement.get("occupied", [])
		for other: Dictionary in main.room.resolved_placements:
			if str(other.get("id", "")) == id:
				continue
			var other_bounds: Rect2 = other.get("world_visual_bounds", Rect2())
			if bounds.intersects(other_bounds):
				spare_problem = "%s bounds %s hit %s %s" % [id, bounds, str(other.get("id", "")), other_bounds]
				return false
			for cell: Variant in occupied:
				if (other.get("occupied", []) as Array).has(cell):
					spare_problem = "%s shares %s with %s" % [id, str(cell), str(other.get("id", ""))]
					return false
	return true

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

## Missing-key onboarding opens Connect over a hired company and blocks J.
## Close it the same way the product screen does, then let the office card be judged on its own.
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

func seed_team(data_dir: String) -> bool:
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
	var script_path := data_dir.path_join("seed-office.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('office-test-cash', 1, 90000, 0, 0, 'Office test cash');\ndb.journey.hire('theo', 1);\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nif (cash !== 60000) { console.error('expected 60000 cash, got ' + cash); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the office seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded Mina, Theo, and $600 (%s)" % " ".join(output))
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
	var expand := button_named("Expand office")
	check(main.company_panel.find_child("OfficeCard", true, false) != null, "The Office card is on Company Journey")
	check(label_named("OfficeName") != null and label_named("OfficeName").text == "Garage Loft", "The office starts as the Garage Loft")
	check(label_named("OfficeDesks") != null and label_named("OfficeDesks").text == "Desks: 1/4", "Desk capacity starts at 1/4")
	check(label_named("OfficeNext") != null and label_named("OfficeNext").text == "Open Floor · $600", "The next expansion is the Open Floor for $600")
	check(label_named("OfficeReason") != null and label_named("OfficeReason").text == "Hire 2 people first.", "The locked reason asks for two hires")
	check(expand != null and expand.disabled and expand.text == "Expand office" and str(expand.get_meta("cozy_variant", "")) == "secondary", "Expand office starts as a disabled secondary button")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	check(spare_present() == 0, "Spare desks stay out of the Garage Loft")
	var seeded := OS.get_temp_dir().path_join("startup-valley-tycoon-office-team-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_team(seeded):
		_finish()
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot():
		_finish()
		return
	var continue_button := button_named("Continue")
	check(continue_button != null, "A hired team continues into the office")
	if continue_button != null:
		await click(continue_button)
	await dismiss_onboarding()
	await open_journey()
	check(label_named("OfficeDesks") != null and label_named("OfficeDesks").text == "Desks: 3/4", "Two hires fill 3 of 4 desks")
	check(company_cash() == 60000, "The seeded team has $600 game cash")
	expand = button_named("Expand office")
	check(expand != null and not expand.disabled and str(expand.get_meta("cozy_variant", "")) == "secondary", "Expand office is enabled once cash and hires are met")
	check(spare_present() == 0, "Spare desks stay hidden until the purchase")
	await click(expand)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("OfficeName") != null and label_named("OfficeName").text == "Open Floor" and spare_present() == 3
	, "Expand office moves the company into the Open Floor")
	check(label_named("OfficeDesks") != null and label_named("OfficeDesks").text == "Desks: 3/7", "The Open Floor lists 3 of 7 desks")
	check(label_named("OfficeNext") == null and button_named("Expand office") == null, "The max office hides the next expansion")
	check(company_cash() == 0, "The expansion spends the $600")
	check(int(office_state().get("level", 0)) == 2, "The journey reports office level 2")
	check(spare_clear(), "The new desks face south, use the layered sprites, and do not overlap other props" + ("" if spare_problem.is_empty() else " (%s)" % spare_problem))
	var compact_a := main.room.placement_by_id("spare-compact-a")
	var compact_b := main.room.placement_by_id("spare-compact-b")
	var bench := main.room.placement_by_id("spare-workbench")
	check(compact_a.get("grid", Vector2i.ZERO) == Vector2i(20, 17) and compact_b.get("grid", Vector2i.ZERO) == Vector2i(25, 17) and bench.get("grid", Vector2i.ZERO) == Vector2i(23, 14), "Spare desks use the authored Open Floor cells")
	check(not main.job_panel._connection_panel.visible, "Expanding the office never opens Connect")
	print("TYCOON OFFICE ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.queue_free()
		await frames(8)
	quit(exit_code)
