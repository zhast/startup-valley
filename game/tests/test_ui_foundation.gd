extends SceneTree
## Effective typography, actual control input, texture geometry and rendered ink.
const OUTPUT := "res://tests/output/ui-redesign/foundation"
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []
var canvas: Control
var main_action: Button

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func label_at(copy: String, point: Vector2, role: String = "body") -> Label:
	var label := Label.new()
	label.text = copy
	label.position = point
	CozyUI.label(label, role)
	canvas.add_child(label)
	return label

func button_at(copy: String, point: Vector2, variant: String) -> Button:
	var button := Button.new()
	button.text = copy
	button.position = point
	button.size = Vector2(208, 44)
	CozyUI.button(button, variant)
	canvas.add_child(button)
	return button

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	captures.append(name)

func pointer(point: Vector2, down: int = -1) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	if down >= 0:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down == 1
		root.push_input(event, true)
	await frames(1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	canvas = Control.new()
	canvas.size = Vector2(1280, 720)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.theme = GameFonts.interface_theme()
	root.add_child(canvas)
	var paper := Panel.new()
	paper.size = canvas.size
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", CozyUI.paper())
	canvas.add_child(paper)
	label_at("STARTUP VALLEY / UI KIT", Vector2(32, 20), "display")
	label_at("Live text, quiet paper, one fixed-corner control family", Vector2(32, 63), "title")
	label_at("Body / Nunito Sans / 16px", Vector2(32, 108))
	label_at("Metadata / 14px / only secondary information", Vector2(32, 140), "meta")
	var paragraph := RichTextLabel.new()
	paragraph.position = Vector2(32, 176)
	paragraph.size = Vector2(1160, 80)
	paragraph.bbcode_enabled = true
	paragraph.text = "A clearer offer starts with [b]good evidence[/b], [i]a small experiment[/i], and [code]site/index.html[/code].\nNormal, bold, italic and code resolve to distinct bundled font faces."
	CozyUI.rich_text(paragraph, 18)
	canvas.add_child(paragraph)
	main_action = button_at("Start work order", Vector2(32, 280), "primary")
	button_at("Preview file", Vector2(264, 280), "secondary")
	button_at("Cancel work", Vector2(496, 280), "danger")
	var disabled := button_at("Unavailable", Vector2(728, 280), "secondary")
	disabled.disabled = true
	var close := Button.new()
	close.position = Vector2(980, 280)
	CozyUI.close(close)
	canvas.add_child(close)
	var input := LineEdit.new()
	input.position = Vector2(32, 354)
	input.size = Vector2(440, 44)
	input.placeholder_text = "Talk through an idea…"
	CozyUI.input(input)
	canvas.add_child(input)
	var dropdown := OptionButton.new()
	dropdown.position = Vector2(496, 354)
	dropdown.size = Vector2(440, 44)
	dropdown.add_item("AI cap · 12,000 tokens")
	dropdown.add_item("AI cap · 24,000 tokens")
	CozyUI.dropdown(dropdown)
	canvas.add_child(dropdown)
	var slider := HSlider.new()
	slider.position = Vector2(32, 420)
	slider.size = Vector2(440, 44)
	slider.value = 60
	CozyUI.slider(slider)
	canvas.add_child(slider)
	label_at("Effects volume · 60%", Vector2(496, 430))
	label_at("Fixed corners at 96px, 208px and 432px widths", Vector2(32, 492), "action")
	var sample_positions: Array[Vector2] = [Vector2(32, 534), Vector2(156, 534), Vector2(392, 534)]
	var sample_sizes: Array[Vector2] = [Vector2(96, 48), Vector2(208, 64), Vector2(432, 88)]
	for index: int in range(3):
		var sample := Panel.new()
		sample.position = sample_positions[index]
		sample.size = sample_sizes[index]
		sample.add_theme_stylebox_override("panel", CozyUI.control_style("secondary"))
		canvas.add_child(sample)
	var multiline := button_at("Review delivery\nbefore adding to Studio", Vector2(852, 534), "secondary")
	multiline.size = Vector2(396, 88)
	label_at("Focus is indigo; success remains green. Hover/press never resize controls.", Vector2(32, 662), "meta")
	await frames(12)
	for spec: Array in [[GameFonts.BODY, 550.0], [GameFonts.EMPHASIS, 600.0], [GameFonts.BOLD, 700.0]]:
		var face := spec[0] as FontVariation
		check(face.get_font_name().contains("Nunito") and face.variation_opentype.get("weight") == spec[1], "Nunito role has its explicit effective weight: " + face.resource_path)
		check(face.get_rids()[0] != face.base_font.get_rids()[0], "Requested variable weight creates a distinct effective face")
	check(GameFonts.DISPLAY.get_font_name().contains("Slab"), "Controlled display uses the approved Slab face")
	check(GameFonts.DISPLAY.antialiasing == TextServer.FONT_ANTIALIASING_NONE and GameFonts.DISPLAY.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED, "Slab uses crisp integer pixel sampling")
	check(GameFonts.DISPLAY.hinting == TextServer.HINTING_NONE and not GameFonts.DISPLAY.generate_mipmaps and GameFonts.DISPLAY.oversampling == 1.0, "Slab native grid is not hinted, mipmapped, or oversampled")
	check(not GameFonts.DISPLAY.allow_system_fallback, "Slab never silently uses a system font")
	check(GameFonts.DISPLAY_LARGE == 22 and GameFonts.DISPLAY_MEDIUM == 22 and GameFonts.DISPLAY_SMALL == 22, "Every Slab display role stays native22")
	check(GameFonts.display_font_for("Company Journey") == GameFonts.DISPLAY, "Controlled ASCII heading keeps Slab")
	check(GameFonts.display_font_for("Welcome, Éloïse") == GameFonts.BOLD, "Accented dynamic heading deliberately uses Nunito")
	check(GameFonts.has_glyphs(GameFonts.BOLD, "résumé–validation… 東京の企画 🚀 →"), "Bundled fallback chain covers accented, CJK, emoji and symbol filenames")
	check(GameFonts.has_glyphs(GameFonts.BOLD, "会社の計画 产品验证 한글 Привет γειά"), "Dynamic filenames retain Chinese, Japanese, Hangul, Cyrillic and Greek coverage")
	for size: int in [14, 16, 18, 20, 22, 24]:
		check(GameFonts.BODY.get_height(size) == GameFonts.BODY.base_font.get_height(size), "Unused fallback glyphs cannot inflate Nunito line boxes at %dpx" % size)
	for spec: Array in [["section", 20, GameFonts.BOLD], ["numeric", 20, GameFonts.BOLD], ["identity", 16, GameFonts.BOLD], ["body", 16, GameFonts.BODY], ["meta", 14, GameFonts.EMPHASIS]]:
		var sample := Label.new()
		sample.text = "Mina"
		CozyUI.label(sample, spec[0])
		check(sample.get_theme_font_size("font_size") == spec[1] and sample.get_theme_font("font") == spec[2], "Semantic C role is explicit: " + str(spec[0]))
		sample.free()
	for face: FontVariation in [GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.BOLD, GameFonts.ITALIC, GameFonts.BOLD_ITALIC]:
		var source := face.base_font as FontFile
		check(source != null and source.antialiasing != TextServer.FONT_ANTIALIASING_NONE, "Nunito prose remains antialiased: " + face.resource_path)
		check(source != null and not source.allow_system_fallback, "Nunito has deterministic local glyph coverage: " + face.resource_path)
		check(not face.fallbacks.is_empty(), "Dynamic roles include bundled glyph fallbacks: " + face.resource_path)
	check((GameFonts.ITALIC.get_font_style() & TextServer.FONT_ITALIC) != 0, "Body italic is a real italic face")
	check((GameFonts.BOLD_ITALIC.get_font_style() & TextServer.FONT_ITALIC) != 0, "Semibold italic is a real italic face")
	check(GameFonts.BOLD.get_rids() != GameFonts.BODY.get_rids(), "Bold is a distinct effective face")
	check(GameFonts.ITALIC.get_rids() != GameFonts.BODY.get_rids(), "Italic is a distinct effective face")
	check(GameFonts.MONO.get_rids() != GameFonts.BODY.get_rids(), "Code is a distinct bundled face")
	for role: String in ["normal", "bold", "italics", "bold_italics", "mono"]:
		check(paragraph.get_theme_font_size(role + "_font_size") == (16 if role == "mono" else 18), "Rich text preserves18px reading and16px code: " + role)
	check(main_action.get_theme_font("font").get_rids() == GameFonts.BOLD.get_rids(), "Button uses effective bold face")
	check(dropdown.get_popup().get_theme_font("font") == GameFonts.EMPHASIS, "Popup uses explicit Nunito Emphasis")
	check(slider.get_theme_icon("grabber").get_size() == Vector2(24, 24), "Slider thumb has a24px silhouette")
	check(close.size.x >= 44 and close.size.y >= 44, "Authored close icon has44px click target")
	var multiline_bounds := GameFonts.BOLD.get_multiline_string_size(multiline.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	check(multiline_bounds.x <= multiline.size.x - 24 and multiline_bounds.y <= multiline.size.y - 16, "Multiline action copy fits its real text-safe insets without shrinking")
	check(multiline.get_theme_font_size("font_size") == 16 and multiline.size.y >= multiline.get_combined_minimum_size().y, "Multiline action preserves readable type and its full minimum height")
	var activation: Array[int] = []
	main_action.pressed.connect(func() -> void: activation.append(1))
	for index: int in range(12): CozyUI.button(main_action, "primary")
	check(main_action.button_down.get_connections().size() == 1, "Repeated restyles bind button-down once")
	check(main_action.button_up.get_connections().size() == 1, "Repeated restyles bind button-up once")
	await pointer(Vector2(1100, 680))
	await capture("components-normal")
	var original := main_action.get_global_rect()
	await pointer(original.get_center())
	await capture("components-hover")
	await pointer(original.get_center(), 1)
	check(main_action.is_pressed(), "Visible action receives actual button-down")
	check(main_action.get_global_rect() == original and main_action.scale == Vector2.ONE, "Press does not move or scale text")
	check(main_action.self_modulate != Color.WHITE, "Press feedback occurs within one rendered frame")
	await capture("components-pressed")
	await pointer(original.get_center(), 0)
	await frames(16)
	check(activation.size() == 1, "One real click produces one activation after12restyles")
	check(main_action.self_modulate.is_equal_approx(Color.WHITE), "Release settles to unchanged geometry and tint")
	await pointer(disabled.get_global_rect().get_center(), 1)
	await pointer(disabled.get_global_rect().get_center(), 0)
	check(not disabled.is_pressed(), "Disabled visible button ignores input")
	main_action.grab_focus()
	await pointer(Vector2(1100, 680))
	check(main_action.has_focus(), "Focus belongs to an actual visible enabled control")
	await capture("components-focused")
	await pointer(input.get_global_rect().get_center())
	for down: bool in [true, false]:
		var context_click := InputEventMouseButton.new()
		context_click.position = input.get_global_rect().get_center()
		context_click.global_position = context_click.position
		context_click.button_index = MOUSE_BUTTON_RIGHT
		context_click.pressed = down
		root.push_input(context_click, true)
		await frames(1)
	check(input.get_menu().visible, "Actual right-click opens the visible text input menu")
	check(input.get_menu().get_theme_font("font") == GameFonts.EMPHASIS, "Text context menu uses the shared font")
	check(input.get_menu().get_theme_stylebox("panel").get_meta("cozy_material", "") == "popup", "Text context menu uses the shared paper popup material")
	await capture("input-context-menu")
	input.get_menu().hide()
	check(canvas.theme.get_font("font", "TooltipLabel") == GameFonts.EMPHASIS, "Tooltip text uses bundled Nunito Emphasis")
	check(canvas.theme.get_font_size("font_size", "TooltipLabel") >= 14, "Tooltip metadata stays14px")
	_check_material_family()
	var normal: Image = (load(CozyUI.ART_ROOT + "secondary-normal.png") as Texture2D).get_image()
	for variant: String in ["secondary", "primary", "danger"]:
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var texture := load(CozyUI.ART_ROOT + variant + "-" + state + ".png") as Texture2D
			var pixels := texture.get_image()
			check(texture.get_size() == Vector2(96, 48), "%s/%s native size" % [variant, state])
			var invalid_alpha := 0
			for y: int in range(48):
				for x: int in range(96):
					var color := pixels.get_pixel(x, y)
					if (color.a != 0 and color.a != 1) or color.a != normal.get_pixel(x, y).a: invalid_alpha += 1
			check(invalid_alpha == 0, "%s/%s exact binary silhouette shared across states" % [variant, state])
			var foreground := CozyUI.MUTED if state == "disabled" else (CozyUI.ALERT if variant == "danger" else CozyUI.INK)
			var worst := 100.0
			for y: int in range(8, 40):
				for x: int in range(12, 84):
					var background := pixels.get_pixel(x, y)
					var tint := Color(0.94, 0.94, 0.94) if state == "pressed" else Color.WHITE
					worst = minf(worst, contrast(foreground * tint, background * tint))
			check(worst >= 4.5, "%s/%s actual textured text-safe interior contrast%.2f" % [variant, state, worst])
			var imports := ConfigFile.new()
			imports.load(CozyUI.ART_ROOT + variant + "-" + state + ".png.import")
			check(imports.get_value("params", "compress/mode") == 0 and not imports.get_value("params", "mipmaps/generate"), "Lossless nonmipmapped control import")
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		var screen := root.get_texture().get_image()
		for index: int in range(3):
			var errors := 0
			for y: int in range(6):
				for x: int in range(6):
					var source := normal.get_pixel(x, y)
					if source.a == 1 and color_distance(source, screen.get_pixelv(Vector2i(sample_positions[index]) + Vector2i(x, y))) > 0.025: errors += 1
			check(errors == 0, "Rendered source corner survives width%s without stretch" % sample_sizes[index].x)
		var paper_image := NotebookSkin.PARCHMENT_PANEL.get_image()
		var worst_paper := 100.0
		for y: int in range(14, paper_image.get_height() - 14):
			for x: int in range(14, paper_image.get_width() - 14): worst_paper = minf(worst_paper, contrast(CozyUI.MUTED, paper_image.get_pixel(x, y)))
		check(worst_paper >= 4.5, "Metadata ink contrasts with actual reused paper%.2f" % worst_paper)
	var result := {"checks": checks, "failures": failures, "captures": captures, "renderer": DisplayServer.get_name()}
	var output := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	print(JSON.stringify(result))
	canvas.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

func _check_material_family() -> void:
	for variant: String in ["primary", "secondary", "quiet", "danger"]:
		var resting := CozyUI.control_style(variant)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var style := CozyUI.control_style(variant, state)
			check(style.get_meta("cozy_family", "") == CozyUI.MATERIAL_FAMILY and style.get_meta("cozy_material", "") == "control-" + variant, "Every action role belongs to the same authored family: " + variant + "/" + state)
			check(style.get_minimum_size() == resting.get_minimum_size(), "Action-state transitions cannot resize content: " + variant + "/" + state)
	var quiet_image := CozyUI.icon("quiet-normal").get_image()
	for state: String in ["hover", "pressed", "disabled"]:
		var pixels := CozyUI.icon("quiet-" + state).get_image()
		var mismatched := 0
		for y: int in range(pixels.get_height()):
			for x: int in range(pixels.get_width()):
				if pixels.get_pixel(x, y).a != quiet_image.get_pixel(x, y).a: mismatched += 1
		check(mismatched == 0, "Quiet state uses the identical protected silhouette: " + state)
		check(contrast(CozyUI.MUTED if state == "disabled" else CozyUI.INK, pixels.get_pixel(48, 24)) >= 4.5, "Quiet state center has accessible live-ink contrast: " + state)
	for kind: String in ["card", "field", "readonly", "bubble-employee", "bubble-player", "popup", "selection"]:
		var style := CozyUI.surface(kind)
		var pixels := CozyUI.icon(kind).get_image()
		check(style.get_meta("cozy_material") == kind and pixels.get_size() == Vector2i(48, 48), "Paper role keeps its native part and explicit hierarchy: " + kind)
		check(contrast(CozyUI.MUTED, pixels.get_pixel(24, 24)) >= 4.5, "Paper role protects metadata contrast: " + kind)
		var fractional_alpha := 0
		for y: int in range(48):
			for x: int in range(48):
				var alpha := pixels.get_pixel(x, y).a
				if alpha != 0 and alpha != 1: fractional_alpha += 1
		check(fractional_alpha == 0, "Native paper edges are hard pixels, not antialiased halos: " + kind)
	var focused := CozyUI.icon("focus").get_image()
	check(focused.get_pixel(24, 24).a == 0 and focused.get_pixel(0, 0).a == 0, "Focus is hollow and follows stepped corners")
	check(focused.get_pixel(24, 2).a == 1 and contrast(CozyUI.INDIGO, CozyUI.PAPER_LIGHT) >= 4.5, "Inset focus retains a conspicuous indigo edge")
	for selected: bool in [false, true]:
		var resting := CozyUI.tab_style(selected)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var style := CozyUI.tab_style(selected, state)
			check(style.get_minimum_size() == resting.get_minimum_size(), "Tabs have state-invariant geometry")
	var tab := Button.new()
	CozyUI.tab_button(tab, false)
	for index: int in range(12): CozyUI.tab_button(tab, index % 2 == 0)
	check(tab.get_meta("cozy_variant") == "navigation" and tab.button_down.get_connections().size() == 1 and tab.button_up.get_connections().size() == 1, "Repeated navigation refreshes retain role and bind press feedback only once")
	tab.free()
	for spec: Array in [["document", Vector2(24, 28)], ["folder", Vector2(32, 24)], ["close", Vector2(16, 16)], ["checked", Vector2(16, 16)], ["unchecked", Vector2(16, 16)]]:
		check(CozyUI.icon(spec[0]).get_size() == spec[1], "Miniature glyph is authored at native resolution: " + spec[0])
	var field := CozyUI.icon("field").get_image()
	var card := CozyUI.icon("card").get_image()
	check(luminance(field.get_pixel(24, 1)) < luminance(field.get_pixel(24, 45)), "Editable paper uses a recessed upper edge")
	check(luminance(card.get_pixel(24, 1)) > luminance(card.get_pixel(24, 45)), "Read-only cards use a raised upper edge")

func luminance(value: Color) -> float:
	var linear := value.srgb_to_linear()
	return linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722

func contrast(first: Color, second: Color) -> float:
	var a := luminance(first)
	var b := luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

func color_distance(first: Color, second: Color) -> float:
	return maxf(absf(first.r - second.r), maxf(absf(first.g - second.g), absf(first.b - second.b)))
