extends SceneTree
## Real UI input verifies the browser's offline character flow without a provider.
var failures: Array[String] = []
var requests: Array[Dictionary] = []
var requested_screen := ""
var history_requests := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for i: int in range(12): await process_frame

func visible_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	for button: Button in node.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and not button.text.is_empty(): result.append(button)
	return result

func click(button: Button) -> void:
	await frames()
	check(button.is_visible_in_tree() and not button.disabled, "Action is visible and enabled")
	var point := button.get_global_rect().get_center()
	check(root.get_visible_rect().has_point(point), "Action fits in viewport")
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func effective_z(item: CanvasItem) -> int:
	var value := item.z_index
	var parent := item.get_parent() as CanvasItem
	if item.z_as_relative and parent != null:
		value += effective_z(parent)
	return value

func check_drawer_rail_layering(team: JobPanel) -> void:
	team.close_drawer(false)
	team.open_drawer()
	team._drawer_tween.custom_step(0.04)
	check(team.drawer_global_rect().intersects(team.rail_global_rect()), "Layering regression exercises a drawer overlapping the rail mid-slide")
	var rail_z := effective_z(team._rail_panel)
	var drawer_top_z := effective_z(team._drawer_panel)
	for item: CanvasItem in team._drawer_panel.find_children("*", "CanvasItem", true, false):
		drawer_top_z = maxi(drawer_top_z, effective_z(item))
	check(rail_z > drawer_top_z, "The entire team rail stays above drawer ornament while sliding; its frame must not cross Mina's face")
	team.close_drawer(false)
	team.open_drawer(false)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var panel := CompanyPanel.new()
	panel.story_mode = true
	root.add_child(panel)
	panel.action_requested.connect(func(method: String, params: Dictionary) -> void: requests.append({"method": method, "params": params}))
	var initial := {"company": {"cashCents": 0}, "candidates": [{"id": "mira", "name": "Mina", "available": true, "hired": false, "costCents": 0}], "tycoon": {}}
	panel.update_state(initial)
	panel.present("journey")
	await frames()
	var actions := visible_buttons(panel)
	check(actions.size() == 1, "First meeting has one action, no contracts or day-end distractions")
	check(panel.find_child("StoryIntroduction", true, false) != null, "First meeting shows character dialogue")
	await click(actions[0])
	check(requests.size() == 1 and requests[0] == {"method": "hiring.complete", "params": {"employeeId": "mira"}}, "Welcome uses the existing durable hiring request exactly once")
	initial.candidates[0].hired = true
	initial.candidates[0].available = false
	panel.update_state(initial)
	panel.present("hired")
	await frames()
	actions = visible_buttons(panel)
	check(actions.size() == 1, "Welcome has one clear action")
	await click(actions[0])
	check(not panel.visible, "Welcome returns to the office")
	var team := JobPanel.new()
	team.story_mode = true
	root.add_child(team)
	team.story_requested.connect(func(mode: String) -> void: requested_screen = mode)
	team.chat_history_requested.connect(func(_id: String) -> void: history_requests += 1)
	var employees: Array[EmployeeRecord] = [EmployeeRecord.from_dictionary({"id": "mira", "name": "Mina"})]
	team.set_worker_ready()
	team.set_journey_state(initial)
	team.configure_employees(employees)
	team.open_chat_for_employee("mira")
	await frames()
	check(team._story_page.is_visible_in_tree(), "Mina opens offline dialogue")
	check(not team._tabs.is_visible_in_tree() and not team._tab_strip.is_visible_in_tree(), "Legacy technical tabs do not appear in character conversation")
	check(history_requests == 0, "Opening a story conversation never requests provider chat")
	check(team._story_line.size.y >= team._story_line.get_minimum_size().y, "Full dialogue fits without clipping")
	check(team.drawer_global_rect().encloses(team._story_action.get_global_rect()), "Next action fits within compact dialogue card")
	check_drawer_rail_layering(team)
	await click(team._story_action)
	check(requested_screen == "product", "Dialogue action opens the existing offline project flow")
	initial.tycoon = {"developing": {"id": "p1", "ready": false}}
	team.set_journey_state(initial)
	check(team._story_action.text == "See our project", "Dialogue follows an active project")
	initial.tycoon.developing.ready = true
	team.set_journey_state(initial)
	check(team._story_action.text == "See what we made", "Dialogue acknowledges readiness from worker state")
	initial.tycoon = {"history": [{"id": "p1"}]}
	team.set_journey_state(initial)
	check(team._story_action.text == "Plan our next project", "Dialogue acknowledges a released project")
	team.close_drawer(false)
	team.open_chat_for_employee("mira")
	await frames()
	check(team._story_page.is_visible_in_tree() and history_requests == 0, "Reopening preserves offline story mode")
	print("Story conversation: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
