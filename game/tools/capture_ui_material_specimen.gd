extends SceneTree
## Production components, not preview overrides. Keep the real drawer alongside.
const OUTPUT := "res://tests/output/ui-material-specimen"
var board: Control
var captures: Array[String] = []

class CalloutSamples extends Control:
	func _draw() -> void:
		WorldCalloutSkin.draw(self, Rect2(0, 0, 110, 34), Vector2(55, 60))
		draw_string(GameFonts.BOLD, Vector2(10, 23), "Mina", HORIZONTAL_ALIGNMENT_LEFT, 90, 16, CozyUI.INK)
		WorldCalloutSkin.draw(self, Rect2(130, 0, 270, 54), Vector2(410, 26))
		draw_string(GameFonts.BODY, Vector2(142, 24), "One clear offer. One small test.", HORIZONTAL_ALIGNMENT_LEFT, 248, 16, CozyUI.INK)
		WorldCalloutSkin.draw(self, Rect2(438, 0, 170, 44), Vector2(500, 70))
		WorldCalloutSkin.draw_keycap(self, Rect2(446, 8, 26, 28))
		draw_string(GameFonts.BOLD, Vector2(482, 28), "Chat · Mina", HORIZONTAL_ALIGNMENT_LEFT, 118, 16, CozyUI.INK)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func frames(count: int = 4) -> void:
	for index: int in range(count): await process_frame

func text_at(copy: String, point: Vector2, role: String = "body") -> Label:
	var label := Label.new()
	label.text = copy
	label.position = point
	CozyUI.label(label, role)
	board.add_child(label)
	return label

func button_at(copy: String, point: Vector2, width: float, variant: String) -> Button:
	var button := Button.new()
	button.text = copy
	button.position = point
	button.size = Vector2(width, 44)
	CozyUI.button(button, variant)
	board.add_child(button)
	return button

func save_capture(name_value: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(OUTPUT.path_join(name_value + ".png")) == OK)
	captures.append(name_value)

func pointer(point: Vector2, pressed: int = -1) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	if pressed >= 0:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed == 1
		root.push_input(event, true)
	await frames(1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	var main: GameMain = load("res://world/main.tscn").instantiate()
	root.add_child(main)
	await frames(4)
	for signal_value: Signal in [main.job_panel.chat_history_requested, main.job_panel.chat_submitted]:
		for connection: Dictionary in signal_value.get_connections():
			if connection.callable.get_object() == main.worker_client: signal_value.disconnect(connection.callable)
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	main.job_panel.open_chat_for_employee("mira")
	main.job_panel.show_chat_history("mira", [{"sender": "player", "content": "What should we build?"}, {"sender": "employee", "content": "Start with a clear offer and one small test."}])
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	board = Control.new()
	board.position = Vector2(16, 12)
	board.size = Vector2(740, 696)
	board.theme = GameFonts.interface_theme()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(board)
	var background := Panel.new()
	background.size = board.size
	background.add_theme_stylebox_override("panel", CozyUI.paper())
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(background)
	text_at("COMPONENT MATERIALS", Vector2(24, 20), "display")
	text_at("Native size · production skins and typography", Vector2(24, 52), "meta")
	button_at("Start work order", Vector2(24, 88), 216, "primary")
	button_at("Preview file", Vector2(256, 88), 216, "secondary")
	var quiet := button_at("Keep with job", Vector2(488, 88), 224, "quiet")
	var disclosure := button_at("Work details", Vector2(24, 150), 332, "quiet")
	CozyUI.disclosure(disclosure, false)
	disclosure.pressed.connect(func() -> void: CozyUI.disclosure(disclosure, not bool(disclosure.get_meta("cozy_disclosure_expanded"))))
	var expanded := button_at("Usage details", Vector2(380, 150), 332, "quiet")
	CozyUI.disclosure(expanded, true)
	var tab_names := ["Chat", "Assign", "Activity", "Studio"]
	for index: int in range(4):
		var tab := button_at(tab_names[index], Vector2(24 + index * 172, 214), 172, "quiet")
		CozyUI.tab_button(tab, index == 0)
	var field := LineEdit.new()
	field.position = Vector2(24, 280)
	field.size = Vector2(332, 44)
	field.placeholder_text = "Talk through an idea…"
	CozyUI.input(field)
	board.add_child(field)
	var dropdown := OptionButton.new()
	dropdown.position = Vector2(380, 280)
	dropdown.size = Vector2(332, 44)
	dropdown.add_item("Write a custom brief")
	dropdown.add_item("Plan a small experiment")
	dropdown.add_item("Review the offer")
	CozyUI.dropdown(dropdown)
	board.add_child(dropdown)
	for index: int in range(2):
		var panel := Panel.new()
		panel.position = Vector2(24 + index * 356, 346)
		panel.size = Vector2(332, 84)
		panel.add_theme_stylebox_override("panel", CozyUI.card() if index == 0 else CozyUI.bubble("employee"))
		board.add_child(panel)
	text_at("AI spend today", Vector2(38, 356), "action")
	text_at("$0.0198 USD · real money", Vector2(38, 390), "meta")
	text_at("A focused reply on quiet paper.", Vector2(394, 362))
	text_at("The content keeps the attention.", Vector2(394, 396), "meta")
	var slider := HSlider.new()
	slider.position = Vector2(24, 448)
	slider.size = Vector2(332, 44)
	slider.value = 60
	CozyUI.slider(slider)
	board.add_child(slider)
	var disabled := button_at("Unavailable", Vector2(380, 448), 252, "quiet")
	disabled.disabled = true
	var close := button_at("", Vector2(668, 448), 44, "quiet")
	CozyUI.close(close)
	for spec: Array in [["document", 24], ["checked", 70], ["unchecked", 112]]:
		var glyph := TextureRect.new()
		glyph.texture = CozyUI.icon(spec[0])
		glyph.position = Vector2(spec[1], 518)
		glyph.size = glyph.texture.get_size()
		board.add_child(glyph)
	text_at("Native glyphs · no scaled ornaments", Vector2(158, 518), "meta")
	text_at("WORLD CALLOUTS", Vector2(24, 562), "display")
	var callouts := CalloutSamples.new()
	callouts.position = Vector2(24, 602)
	callouts.size = Vector2(690, 70)
	callouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(callouts)
	await frames(20)
	await pointer(Vector2(760, 700))
	await save_capture("normal")
	await pointer(disclosure.get_global_rect().get_center())
	await save_capture("hover")
	await pointer(disclosure.get_global_rect().get_center(), 1)
	await save_capture("pressed")
	await pointer(disclosure.get_global_rect().get_center(), 0)
	await frames(15)
	disclosure.grab_focus()
	await pointer(Vector2(760, 700))
	await save_capture("expanded-focused")
	close.grab_focus()
	await save_capture("close-focused")
	await pointer(dropdown.get_global_rect().get_center(), 1)
	await pointer(dropdown.get_global_rect().get_center(), 0)
	assert(dropdown.get_popup().visible)
	await save_capture("dropdown")
	dropdown.get_popup().hide()
	quiet.grab_focus()
	await save_capture("quiet-focused")
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"productionSkins": true, "productionTypography": true, "workerDisabled": true, "viewport": [1280, 720], "captures": captures, "note": "Component specimen, not completed screen-integration approval."}, "\t"))
	file.close()
	print("Production component specimen: ", captures.size(), " native captures")
	main.queue_free()
	layer.queue_free()
	await frames()
	quit()
