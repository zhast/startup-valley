extends SceneTree
## Isolated real Control layout/input test; not clean-journey progression proof.
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var output := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("DIALOGUE_LAYOUT_FAILED " + message)

func settled() -> void:
	await create_timer(0.22).timeout
	for i: int in range(8): await process_frame

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_DIALOGUE_OUTPUT")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://tests/output/story-dialogue-layout")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.unfocusable = true
	root.mouse_passthrough = true
	var panel := CompanyPanel.new()
	panel.story_mode = true
	root.add_child(panel)
	for physical: Vector2i in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1024, 576)]:
		root.size = physical
		await settled()
		for screen: String in ["journey", "hired", "courtyard"]:
			var state := {"company": {"cashCents": 0}, "candidates": [{"id": "mira", "name": "Mina", "available": screen == "journey", "hired": screen != "journey", "costCents": 0}], "tycoon": {}, "story": {"opportunity": {"status": "available"}}}
			panel.update_state(state)
			panel.present(screen)
			await settled()
			var frame := panel._frame.get_global_rect()
			check(absf(frame.get_center().x - panel.size.x * 0.5) <= 0.5, "%s is horizontally centered at %s" % [screen, physical])
			check(frame.size.x >= 640 and frame.size.x <= 720 and frame.size.y >= 220 and frame.size.y <= 260, "%s is content-sized rather than a large empty modal" % screen)
			check(panel._panel_safe_rect().encloses(frame), "Dialogue remains inside shared safe bounds")
			check(not panel._scroll.get_v_scroll_bar().visible, "Portrait dialogue needs no internal scrolling")
			var portrait := panel.find_child("HirePortrait", true, false) as TextureRect
			check(portrait != null and frame.encloses(portrait.get_global_rect()), "Portrait fits the dialogue frame")
			check(portrait.size.x >= 120 and portrait.size.y >= 140, "Compact portrait retains a readable face area")
			var controls: Array[Control] = []
			for node: Node in panel.find_children("*", "Control", true, false):
				if not node.is_visible_in_tree() or not (node is Label or node is Button): continue
				var control := node as Control
				if control is Label and control.text.is_empty(): continue
				controls.append(control)
				check(frame.encloses(control.get_global_rect()), "Visible dialogue text/action fits: " + control.name)
				check(control.size.y + 0.5 >= control.get_combined_minimum_size().y, "Text/action keeps its required height: " + control.name)
				check(not portrait.get_global_rect().intersects(control.get_global_rect()), "Text/action does not overlap the portrait")
			for a: int in range(controls.size()):
				for b: int in range(a + 1, controls.size()):
					check(not controls[a].get_global_rect().intersects(controls[b].get_global_rect()), "Dialogue controls do not overlap")
			var path := output.path_join("%dx%d-%s.png" % [physical.x, physical.y, screen])
			if DisplayServer.get_name() != "headless":
				RenderingServer.force_draw(false)
				check(root.get_texture().get_image().save_png(path) == OK, "Saved actual native layout capture")
			observations.append({"screen": screen, "window": [physical.x, physical.y], "frame": [frame.position.x, frame.position.y, frame.size.x, frame.size.y], "capture": path if DisplayServer.get_name() != "headless" else ""})
	# A real pointer activates the sole invitation once; no direct signal emit.
	panel.update_state({"company": {"cashCents": 0}, "candidates": [{"id": "mira", "name": "Mina", "available": true, "hired": false, "costCents": 0}], "tycoon": {}})
	panel.present("journey")
	await settled()
	var requests: Array[String] = []
	panel.action_requested.connect(func(method: String, _params: Dictionary) -> void: requests.append(method))
	var button := panel._preferred_focus
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	check(requests == ["hiring.complete"], "Compact invitation submits exactly one real UI request")
	panel.update_state({"company": {"cashCents": 5000}, "candidates": [], "tycoon": {"history": [{"id": "p1", "name": "First kit", "review": {"score": 7}, "salesCents": 5000}]}})
	panel.show_release({"furnishingRewards": ["Café table", "Visitor chair"]})
	await settled()
	var rewards := panel.find_child("ReleaseFurnishingRewards", true, false) as Label
	check(rewards != null and rewards.text == "For the studio: Café table, Visitor chair", "Release explains only the newly earned furniture in one line")
	panel.show_release({"furnishingRewards": []})
	await settled()
	check(panel.find_child("ReleaseFurnishingRewards", true, false) == null, "Empty rewards add no empty row or stale list")
	panel.show_release({"furnishingRewards": ["Café table"]})
	panel.hide()
	panel.present("release")
	await settled()
	check(panel.find_child("ReleaseFurnishingRewards", true, false) == null, "Reopening an old release does not claim another furniture grant")
	var result := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	result.store_string(JSON.stringify({"checks": checks, "failures": failures, "observations": observations, "scope": "Isolated production Control layout with fixture projection; native rendered sizes and real pointer input."}, "  ") + "\n")
	result.close()
	print("Dialogue layout: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
