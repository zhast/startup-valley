extends SceneTree
## Read-only comparison. The left side reconstructs the old UI; right is current.
const OUTPUT := "res://tests/output/whop-typography"
const LEGACY_DISPLAY: FontFile = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const LEGACY_BODY: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
const LEGACY_BOLD: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Bold.tres")
var canvas: Control
var diagnostics: Dictionary = {"runtimeChanged": false, "workerDisabled": true, "viewport": [1280, 720], "hud": [], "currentHudFit": [], "legacyDayFit": []}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func label_at(copy: String, point: Vector2, font: Font, pixels: int, width: float = 580) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = point
	label.size = Vector2(width, 48)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", CozyUI.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(label)
	return label

func clock_at(point: Vector2) -> ClockPanel:
	var clock := load("res://ui/clock_panel.tscn").instantiate() as ClockPanel
	canvas.add_child(clock)
	clock.position = point
	clock.show_clock(12, 8 * 60)
	clock.show_money_earned(600)
	return clock

func font_details(font: Font) -> Dictionary:
	var base: Font = (font as FontVariation).base_font if font is FontVariation else font
	return {"resource": font.resource_path, "family": font.get_font_name(), "style": font.get_font_style_name(),
		# Variable-font metadata can report the base weight; it is not a measurement
		# of the rendered variation. Current TownSquare faces are static and exact.
		"metadataWeight": font.get_font_weight(), "baseWeight": base.get_font_weight(),
		"requestedWeight": (font as FontVariation).variation_opentype.get("weight", base.get_font_weight()) if font is FontVariation else font.get_font_weight(),
		"effectiveRidCount": font.get_rids().size(), "sameRidAsBase": font.get_rids() == base.get_rids()}

func record(label: Label, role: String, side: String) -> void:
	var font := label.get_theme_font("font")
	diagnostics.hud.append({"side": side, "role": role, "text": label.text, "font": font_details(font), "size": label.get_theme_font_size("font_size"),
		"localRect": [label.position.x, label.position.y, label.size.x, label.size.y]})

func legacy_clock_at(point: Vector2) -> ClockPanel:
	var clock := clock_at(point)
	# Explicitly reconstruct pre-TownSquare fonts and geometry on the old ledger art.
	# The production ClockPanel on the right receives none of these overrides.
	clock._day_caption.hide()
	clock._time_caption.hide()
	for entry: Array in [[clock._day_label, Rect2(26, 13, 116, 42), LEGACY_DISPLAY, 30], [clock._time_label, Rect2(166, 13, 96, 42), LEGACY_DISPLAY, 30], [clock._earned_label, Rect2(270, 10, 110, 28), LEGACY_BOLD, 20], [clock._earned_caption, Rect2(270, 37, 110, 20), LEGACY_BODY, 14]]:
		var label := entry[0] as Label
		var rect: Rect2 = entry[1]
		label.position = rect.position
		label.size = rect.size
		label.add_theme_font_override("font", entry[2] as Font)
		label.add_theme_font_size_override("font_size", int(entry[3]))
	clock._day_label.text = "DAY 12"
	clock._earned_caption.text = "Game earned"
	return clock

func record_fit(label: Label, role: String) -> void:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var measured := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	diagnostics.currentHudFit.append({"role": role, "text": label.text, "font": font_details(font), "size": size,
		"measuredSize": [measured.x, measured.y], "availableSize": [label.size.x, label.size.y],
		"fits": measured.x <= label.size.x and measured.y <= label.size.y})

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This visual diagnostic requires the real renderer.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	canvas = Control.new()
	canvas.size = Vector2(1280, 720)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.theme = GameFonts.interface_theme()
	root.add_child(canvas)
	var paper := Panel.new()
	paper.size = canvas.size
	paper.add_theme_stylebox_override("panel", CozyUI.paper())
	canvas.add_child(paper)
	label_at("Startup Valley: legacy and TownSquare typography", Vector2(24, 12), GameFonts.DISPLAY, 26, 1200)
	label_at("The same paper and ledger art. Legacy fonts are loaded explicitly; the right-hand HUD is the actual runtime control.", Vector2(24, 50), GameFonts.BODY, 16, 1216)
	label_at("Before (legacy reconstruction)", Vector2(24, 88), GameFonts.BOLD, 20)
	label_at("Implemented TownSquare typography", Vector2(656, 88), GameFonts.BOLD, 20)
	var legacy := legacy_clock_at(Vector2(24, 130))
	var current := clock_at(Vector2(656, 130))
	for entry: Array in [[legacy._day_label, "day"], [legacy._time_label, "time"], [legacy._earned_label, "earned"], [legacy._earned_caption, "earned caption"]]:
		record(entry[0] as Label, str(entry[1]), "legacy reconstruction")
	for entry: Array in [[current._day_label, "day"], [current._time_label, "time"], [current._earned_label, "earned"], [current._day_caption, "day caption"], [current._time_caption, "time caption"], [current._earned_caption, "earned caption"]]:
		record(entry[0] as Label, str(entry[1]), "implemented runtime")
	for day_value: int in [1, 12, 123, 999]:
		var copy := "DAY %d" % day_value
		var width := LEGACY_DISPLAY.get_string_size(copy, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		diagnostics.legacyDayFit.append({"text": copy, "measuredWidth": width, "availableWidth": legacy._day_label.size.x, "fits": width <= legacy._day_label.size.x})
		current.show_clock(day_value, 8 * 60)
		record_fit(current._day_label, "day")
	for minute: int in [0, 8 * 60, 17 * 60 + 30, 23 * 60 + 59]:
		current.show_clock(12, minute)
		record_fit(current._time_label, "time")
	for amount: float in [0.0, 600.0, 999.99, 1000.0, 999999.0, 1234567890.0]:
		current.show_money_earned(amount)
		record_fit(current._earned_label, "earned")
	for caption: Label in [current._day_caption, current._time_caption, current._earned_caption]: record_fit(caption, "caption")
	current.show_clock(12, 8 * 60)
	current.show_money_earned(600)
	label_at("Tiny5 30 / Nunito Bold 20 / Body 14", Vector2(24, 202), LEGACY_BODY, 16)
	label_at("Inter Semibold 24 values / Medium 14 captions", Vector2(656, 202), GameFonts.BODY, 16)
	label_at("Mina    Theo", Vector2(24, 260), LEGACY_DISPLAY, 30)
	label_at("Mina    Theo", Vector2(656, 260), GameFonts.DISPLAY, 26)
	label_at("TEAM    MINA    THEO", Vector2(24, 326), LEGACY_DISPLAY, 20)
	label_at("Team    Mina    Theo", Vector2(656, 326), GameFonts.BOLD, 18)
	label_at("COMPANY JOURNEY", Vector2(24, 392), LEGACY_DISPLAY, 30)
	label_at("Company Journey", Vector2(656, 392), GameFonts.DISPLAY, 26)
	label_at("CONNECT AI", Vector2(24, 458), LEGACY_DISPLAY, 30)
	label_at("Connect AI", Vector2(656, 458), GameFonts.DISPLAY, 26)
	label_at("Let's choose a clear offer and one useful next step.", Vector2(24, 532), LEGACY_BODY, 16)
	label_at("Let's choose a clear offer and one useful next step.", Vector2(656, 532), GameFonts.BODY, 16)
	label_at("Legacy Nunito Sans 550 / 16px prose", Vector2(24, 574), LEGACY_BODY, 14)
	label_at("Implemented Inter Regular / 16px prose", Vector2(656, 574), GameFonts.EMPHASIS, 14)
	label_at("Read-only developer comparison. The legacy side is a reconstruction, not a current-runtime screenshot. No saved-state access.", Vector2(24, 648), GameFonts.EMPHASIS, 14, 1216)
	for index: int in range(12): await process_frame
	RenderingServer.force_draw(false)
	var path := OUTPUT.path_join("typography-comparison.png")
	var error := root.get_texture().get_image().save_png(path)
	diagnostics["capture"] = path
	diagnostics["engine"] = Engine.get_version_info().string
	diagnostics["comparison"] = {"left": "Before (legacy reconstruction)", "right": "Implemented TownSquare typography; unmodified current ClockPanel"}
	diagnostics["currentFonts"] = {"display": font_details(GameFonts.DISPLAY), "body": font_details(GameFonts.BODY), "emphasis": font_details(GameFonts.EMPHASIS), "action": font_details(GameFonts.BOLD)}
	diagnostics["legacyFonts"] = {"display": font_details(LEGACY_DISPLAY), "body": font_details(LEGACY_BODY), "action": font_details(LEGACY_BOLD)}
	diagnostics["legacyTiny5Import"] = {"antialiasing": LEGACY_DISPLAY.antialiasing, "hinting": LEGACY_DISPLAY.hinting, "oversampling": LEGACY_DISPLAY.oversampling}
	diagnostics["currentHudFits"] = diagnostics.currentHudFit.all(func(value: Dictionary) -> bool: return bool(value.fits))
	var file := FileAccess.open(OUTPUT.path_join("diagnostics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(diagnostics, "\t"))
	file.close()
	print(JSON.stringify(diagnostics))
	quit(error if error != OK else 0 if diagnostics.currentHudFits else 1)
