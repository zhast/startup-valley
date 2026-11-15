extends SceneTree
## Read-only project selection, modal input, responsive layout and optional rendered proof.

const Preview := preload("res://ui/studio_website_preview.gd")
const OUTPUT := "res://tests/output/studio-website-preview-current"
var failures: Array[String] = []
var checks := 0
var closed_count := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for i: int in range(8): await process_frame

func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	check(root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png")) == OK, "Save rendered evidence: " + name)

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func check_layout(preview: StudioWebsitePreview, description: String) -> void:
	var viewport := root.get_visible_rect()
	check(viewport.encloses(preview._frame.get_global_rect()), description + ": frame stays on screen")
	check(preview._frame.get_global_rect().encloses(preview._back_button.get_global_rect()), description + ": back button stays inside frame")
	check(preview._frame.get_global_rect().encloses(preview._close_button.get_global_rect()), description + ": close button stays inside frame")
	check(preview._content.size.x <= preview._scroll.size.x + 1, description + ": page never requires horizontal scrolling")
	check(preview._back_button.size.y >= 44 and preview._close_button.size.y >= 44, description + ": actions retain usable targets")
	check(preview._title.size.y >= preview._title.get_line_height(), description + ": title is visible")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var background := ColorRect.new()
	background.color = Color("8d9874")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var return_button := Button.new()
	return_button.text = "Our project"
	return_button.position = Vector2(48, 48)
	root.add_child(return_button)
	var preview := Preview.new()
	root.add_child(preview)
	preview.closed.connect(func() -> void: closed_count += 1)
	await frames()
	check(not preview.visible, "Preview starts hidden")
	var project := {"id": "product-1", "name": "Little Steps Fitness", "topicName": "Fitness", "typeName": "Course", "status": "developing", "ready": false, "staffIds": ["mira"]}
	var original := project.duplicate(true)
	return_button.grab_focus()
	preview.present(project, "The Little Lantern Studio")
	await frames()
	check(preview._title.text == "Little Steps Fitness", "Title comes from the selected project")
	check(preview._studio.text == "The Little Lantern Studio", "Studio name is passed by the caller")
	check(preview._topic.text == "Fitness · Course", "Page reflects the selected product topic and type")
	check((preview.find_child("PreviewNotice", true, false) as Label).text == "IN-GAME WEBSITE PREVIEW", "Page explicitly identifies itself as an in-game preview")
	check(preview._benefits.get_child_count() == 3, "Page has three short benefit cards")
	check(preview.find_children("*", "Button", true, false).size() == 2, "Only close and back controls are interactive; there is no fake publish action")
	check(root.gui_get_focus_owner() == preview._back_button, "Opening moves keyboard focus into the preview")
	check_layout(preview, "Desktop")
	check(preview._hero.columns == 2 and preview._benefits.columns == 3, "Desktop presents a compact two-column hero and three cards")
	await screenshot("website-developing")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == preview._close_button, "Tab stays inside the preview")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == preview._back_button, "Tab loops to the back action")
	await key(KEY_ESCAPE)
	check(not preview.visible and closed_count == 1, "Escape dismisses exactly once")
	check(root.gui_get_focus_owner() == return_button, "Dismissal returns focus to the originating action")
	check(project == original, "Presenting and dismissing leave the input snapshot unchanged")
	var state := {"tycoon": {"developing": project, "history": [{"id": "older", "name": "Valley Notes", "status": "released"}]}}
	var selected := Preview.project_from_state(state)
	check(selected.id == "product-1", "Selection prefers the current project")
	selected.staffIds.append("theo")
	check(project.staffIds == ["mira"], "Selection returns a deep copy of nested project data")
	state.tycoon.developing = null
	var released := Preview.project_from_state(state)
	check(released.id == "older", "Selection falls back to the most recent saved release")
	preview.present(released, "The Little Lantern Studio")
	await frames()
	check(preview._stage.text == "Made with care. Shared with the valley.", "Released copy reflects existing worker state")
	await screenshot("website-released")
	await click(preview._back_button)
	check(not preview.visible and closed_count == 2, "Pointer activates the visible back action")
	check(Preview.project_from_state({"tycoon": "invalid"}).is_empty(), "Malformed tycoon data has a safe empty fallback")
	check(Preview.project_from_state({"tycoon": {"history": [null, 7, {}]}}).is_empty(), "Malformed history entries are ignored")
	preview.present({"name": 123, "topicName": null, "typeName": []})
	await frames()
	check(preview._title.text == "Our next adventure", "Malformed names use friendly fallback copy")
	preview.dismiss()
	root.size = Vector2i(640, 640)
	root.content_scale_size = Vector2i(640, 640)
	await frames()
	preview.present({"name": "A Small Studio's Very Big Book of Ideas and Adventures for Our Friends in the Valley", "ready": true})
	await frames()
	check_layout(preview, "Narrow")
	check(preview._hero.columns == 1 and preview._benefits.columns == 1, "Narrow layout stacks hero and benefit cards")
	check(preview._stage.text == "Almost opening day.", "Ready copy does not claim that an unreleased product is published")
	await screenshot("website-narrow")
	await key(KEY_PAGEDOWN)
	check(preview._scroll.scroll_vertical > 0, "Keyboard users can scroll the stacked page")
	await click(preview._close_button)
	check(not preview.visible, "Top close target works after scrolling")
	print("Studio website preview: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
