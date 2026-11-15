extends SceneTree
## Current-goal and story-form acceptance, using real control input.
var failures: Array[String] = []
var requests: Array[Dictionary] = []
var goal_mode := ""
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for i: int in range(12): await process_frame

func click(button: Button) -> void:
	await frames()
	check(button.is_visible_in_tree() and not button.disabled, "Action is visible and enabled: " + button.text)
	check(root.get_visible_rect().encloses(button.get_global_rect()), "Action fits viewport: " + button.text)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func button_named(node: Node, text_value: String) -> Button:
	for button: Button in node.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text == text_value: return button
	return null

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	RenderingServer.force_draw(false)
	var folder := ProjectSettings.globalize_path("res://tests/output/story-progression-current")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "Saved visual evidence: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := {"company": {"cashCents": 0}, "candidates": [{"id": "mira", "name": "Mina", "hired": false, "available": true}], "tycoon": {"topics": [{"id": "fitness", "name": "Fitness", "unlocked": true}], "types": [{"id": "course", "name": "Course", "unlocked": true}, {"id": "software", "name": "Software Tool", "unlocked": false}], "fits": [{"topicId": "fitness", "typeId": "course", "fit": "great"}], "staff": [{"id": "founder", "name": "You", "hired": true}, {"id": "mira", "name": "Mina", "hired": true}]}}
	check(StoryMoments.goal(state).completed == 0 and StoryMoments.goal(state).mode == "journey", "Fresh company starts with meeting Mina")
	state.candidates[0].hired = true
	state.candidates[0].available = false
	check(StoryMoments.goal(state).completed == 1, "Hiring advances the story from worker state")
	var hud := FounderHud.new()
	root.add_child(hud)
	hud.goal_requested.connect(func(mode: String) -> void: goal_mode = mode)
	hud.set_story_goal(StoryMoments.goal(state))
	await frames()
	check(hud._next_step_label.text == "Choose your first project", "HUD states the next task directly")
	check(hud._next_step_label.get_minimum_size().x <= hud._next_step_label.size.x, "Goal label fits")
	await capture("01-current-goal")
	await click(hud._goal_action)
	check(goal_mode == "product", "Goal action leads directly to the required screen")
	hud.hide()
	var panel := CompanyPanel.new()
	panel.story_mode = true
	root.add_child(panel)
	panel.action_requested.connect(func(method: String, params: Dictionary) -> void: requests.append({"method": method, "params": params}))
	panel.update_state(state)
	panel.present("journey")
	await frames()
	check(panel.find_child("CurrentStoryGoal", true, false) != null, "Story notebook prioritizes the current goal")
	check(button_named(panel, "Plan with Mina") != null, "Story notebook has a matching direct action")
	check(button_named(panel, "End day + save") == null, "No unrelated day-end action before a project")
	await capture("02-story-notebook")
	await click(button_named(panel, "Plan with Mina"))
	check(panel.screen == "product", "Story action opens project planning")
	var format := panel.find_child("StoryFormat", true, false) as OptionButton
	check(format.item_count == 1 and format.get_item_metadata(format.selected) == "course", "First project defaults to an unlocked format")
	check(not (panel.find_child("ProjectDetails", true, false) as Control).visible, "Advanced project decisions start folded")
	check(panel._staff_ids.has("mira"), "Mina joins the first project by default")
	await capture("03-first-project")
	await click(button_named(panel, "Let’s make it"))
	check(requests.size() == 1 and requests[0].method == "tycoon.start", "Planning uses the existing authoritative start request")
	check(requests[0].params.staffIds == ["founder", "mira"] and requests[0].params.typeId == "course", "Start request includes the selected valid format and both teammates")
	state.tycoon.developing = {"id": "p1", "name": "Fitness Course", "devDays": 1, "devDaysRequired": 3, "progress": 33, "ready": false}
	panel.update_state(state)
	check(StoryMoments.goal(state).completed == 2, "Active project advances to the build goal")
	await capture("04-developing")
	await click(button_named(panel, "Wrap up the day"))
	check(requests[-1].method == "day.end", "Project progress action advances the actual game day")
	state.tycoon.developing.ready = true
	state.tycoon.developing.progress = 100
	panel.update_state(state)
	check(StoryMoments.goal(state).completed == 3, "Ready project advances to release")
	await click(button_named(panel, "Share it with the world"))
	check(requests[-1].method == "tycoon.release" and requests[-1].params.productId == "p1", "Release action uses the existing product ID")
	state.tycoon.history = [state.tycoon.developing.duplicate(true)]
	state.tycoon.developing = null
	panel.update_state(state)
	panel.present("release")
	await frames()
	check(panel.find_child("ReleaseAchievement", true, false) != null, "Release screen celebrates a saved achievement")
	check(StoryMoments.goal(state).completed == 4, "Release completes all four first-story moments")
	await capture("05-release")
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	check(StoryMoments.goal(restored) == StoryMoments.goal(state), "Story progress restores solely from saved worker state")
	await click(button_named(panel, "Back to our studio"))
	check(not panel.visible, "Celebration returns to the office and its next goal")
	print("Story progression: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
