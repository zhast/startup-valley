extends SceneTree
## Three typography studies in the actual game. No production fonts are changed.
## Run: godot --path game --fixed-fps 30 --script res://tools/capture_typography_options.gd

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/typography-options"
const FONT_ROOT := "res://tools/typography-options/fonts/"
const FOUNDER_COPY := "How should we launch our first product?"
const LONG_REPLY := "Yes. I would begin with one clear customer and one useful promise. We can turn the interview notes into a small landing page, then ask five people to try it. Keep the offer simple, explain the result they will get, and give them one obvious next step. After that, we can compare their questions, improve the copy, and decide what to build next. Nothing needs to be perfect yet. A focused first version will teach us more than a big launch."
const SHORT_REPLY := "Yes. Let's choose one customer, write one clear promise, and test a small landing page. Then we can use what we learn to plan the next step."
const SIDEBAR_CROP := Rect2i(784, 0, 496, 720)
const HUD_CROP := Rect2i(371, 8, 408, 68)

var _main: GameMain
var _failures: Array[String] = []
var _options: Array[Dictionary] = []
var _results: Array[Dictionary] = []
var _override_count := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _settle(count: int = 24) -> void:
	for frame: int in range(count): await process_frame

func _load_face(path: String, pixel: bool = false) -> Font:
	var face := load(path) as Font
	if face == null:
		_failures.append("Missing font: " + path)
	elif pixel:
		var bitmap_face := face as FontFile
		if bitmap_face == null or bitmap_face.antialiasing != TextServer.FONT_ANTIALIASING_NONE:
			_failures.append("Pixel font must use its non-antialiased import: " + path)
	return face

func _build_options() -> void:
	var slab := _load_face(FONT_ROOT + "NotJamSlabSerif11.ttf", true)
	var serif := _load_face(FONT_ROOT + "NotJamSerif11.ttf", true)
	var chunky := _load_face(FONT_ROOT + "NotJamChunky8.ttf", true)
	var condensed := _load_face(FONT_ROOT + "NotJamUICondensed16.ttf", true)
	var mono := _load_face(FONT_ROOT + "NotJamMonoClean8.ttf", true)
	var nunito := _load_face("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
	var nunito_medium := _load_face("res://assets/fonts/nunito-sans/NunitoSans-Emphasis.tres")
	var nunito_bold := _load_face("res://assets/fonts/nunito-sans/NunitoSans-Bold.tres")
	var nunito_italic := _load_face("res://assets/fonts/nunito-sans/NunitoSans-BodyItalic.tres")
	var nunito_bold_italic := _load_face("res://assets/fonts/nunito-sans/NunitoSans-BoldItalic.tres")
	_options = [
		{"id": "A", "name": "Warm pixel-serif", "heading": slab, "headingSize": 22, "rich": serif, "richSize": 22, "control": condensed, "text": condensed, "meta": condensed, "metaSize": 16, "bold": serif, "italic": serif, "boldItalic": serif, "mono": mono, "railSlab": true},
		{"id": "B", "name": "Chunky pixel-sans", "heading": chunky, "headingSize": 24, "hudSize": 16, "rich": condensed, "richSize": 16, "control": condensed, "text": condensed, "meta": condensed, "metaSize": 16, "bold": condensed, "italic": condensed, "boldItalic": condensed, "mono": mono, "railSlab": false},
		{"id": "C", "name": "Hybrid pixel headings + Nunito", "heading": slab, "headingSize": 22, "rich": nunito, "richSize": 16, "control": nunito_bold, "text": nunito, "meta": nunito_medium, "metaSize": 14, "bold": nunito_bold, "italic": nunito_italic, "boldItalic": nunito_bold_italic, "mono": mono, "railSlab": true},
	]

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_build_options()
	if not _failures.is_empty():
		_finish()
		return
	for option: Dictionary in _options:
		await _fresh_main()
		await _show_chat(option, LONG_REPLY)
		var long_chat := _chat_diagnostics()
		var long_captures := _capture(str(option.id) + "-long")
		# A native 22px reading face can need more scroll space. Preserve the
		# identical long-copy stress test and also show a complete short exchange.
		await _show_chat(option, SHORT_REPLY)
		var result := _diagnostics(option)
		result["longReply"] = long_chat
		result["longCaptures"] = long_captures
		result["shortReply"] = _chat_diagnostics()
		result["captures"] = _capture(str(option.id))
		_results.append(result)
		print("Typography option %s: %d fit checks, %d flagged; long chat scroll=%s" % [option.id, (result.checks as Array).size(), result.fitWarnings, result.longReply.requiresScroll])
	await _dispose_main()
	_finish()

func _fresh_main() -> void:
	await _dispose_main()
	_main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(_main)
	await _settle(2)
	_main.set_process(false)
	_main.worker_client.set_process(false)
	_main.day_clock.set_speed(0.0)
	_main.day_clock.set_time(12, DayClock.WORK_START)
	_main.game_audio.shutdown()
	for signal_name: String in ["key_submitted", "settings_requested", "journey_requested", "worker_retry_requested", "chat_history_requested", "chat_submitted", "assignment_submitted", "cancel_requested", "steer_submitted", "approval_decided", "artifact_open_requested", "artifact_refresh_requested", "studio_open_requested", "promotion_decided"]:
		for connection: Dictionary in _main.job_panel.get_signal_connection_list(signal_name):
			_main.job_panel.disconnect(signal_name, connection.callable)
	var records := _main.room.placeholder_records()
	_main._spawn_employees(records)
	_main.room.set_hire_count(2)
	_main.room.process_mode = Node.PROCESS_MODE_DISABLED
	_main.player.position = _main.room.grid_to_world_position(_main.room.player_spawn)
	_main.player.set_physics_process(false)
	_main.player.input_blocked = true
	for employee: EmployeeAvatar in _main._employees.values():
		employee.set_physics_process(false)
		employee.world_paused = true
		employee._speech_visible = false
		# These labels draw GameFonts directly instead of using Control themes.
		# Suppress them consistently without changing sprites or production code.
		employee._label_layer.hide()
	_main.artifact_viewer.hide()
	_main.company_panel.hide()
	_main.founder_hud.hide_delivery()
	_main.founder_hud.dismiss_movement_hint()
	_main.job_panel.set_credential_status(true)
	_main.job_panel.set_worker_ready()
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 0
	_main.job_panel.open_drawer(false)
	_main.clock_panel.show_clock(12, 8 * 60)
	_main.clock_panel.show_money_earned(123500.0)
	await _settle(24)

func _dispose_main() -> void:
	if not is_instance_valid(_main): return
	_main.game_audio.shutdown()
	root.remove_child(_main)
	_main.free()
	await _settle(2)

func _show_chat(option: Dictionary, reply: String) -> void:
	# Identical ASCII punctuation avoids missing ellipsis/em-dash glyphs in the
	# pixel candidates. This affects only these disposable design fixtures.
	_main.job_panel._chat_input.placeholder_text = "Talk through an idea..."
	_main.job_panel._chat_helper.text = "Conversation only - no tools or files."
	_main.job_panel.show_chat_history("mira", [
		{"sender": "player", "content": FOUNDER_COPY},
		{"sender": "employee", "content": reply},
	])
	_main.job_panel._chat_follow_tail = false
	_override_count = 0
	_override_tree(_main, option)
	_override_hud(option)
	_override_rail(option)
	await _settle(30)
	_main.job_panel._chat_follow_tail = false
	_main.job_panel._chat_scroll.scroll_vertical = 0
	root.gui_release_focus()
	var pointer := InputEventMouseMotion.new()
	pointer.position = Vector2(32, 320)
	pointer.global_position = pointer.position
	root.push_input(pointer, true)
	await _settle(3)

func _override_tree(node: Node, option: Dictionary) -> void:
	if node is RichTextLabel:
		var rich := node as RichTextLabel
		for role: String in ["normal", "bold", "italics", "bold_italics", "mono"]:
			var key := {"normal": "rich", "bold": "bold", "italics": "italic", "bold_italics": "boldItalic", "mono": "mono"}[role] as String
			rich.add_theme_font_override(role + "_font", option[key] as Font)
			rich.add_theme_font_size_override(role + "_font_size", 16 if role == "mono" else int(option.richSize))
		_override_count += 1
	elif node is Label:
		var label := node as Label
		var role := str(label.get_meta("cozy_text_role", "body"))
		var face := option.text as Font
		var size := 16
		if role == "display":
			face = option.heading as Font
			size = int(option.headingSize)
		elif role == "meta":
			face = option.meta as Font
			size = int(option.metaSize)
		elif role in ["title", "action"]:
			face = option.control as Font
		_set_font(label, face, size)
	elif node is Button:
		_set_font(node as Control, option.control as Font, 16)
		if node is OptionButton:
			var popup := (node as OptionButton).get_popup()
			popup.add_theme_font_override("font", option.meta as Font)
			popup.add_theme_font_size_override("font_size", 16)
	elif node is LineEdit or node is TextEdit:
		_set_font(node as Control, option.text as Font, 16)
		var menu: PopupMenu = node.call("get_menu") as PopupMenu
		menu.add_theme_font_override("font", option.meta as Font)
		menu.add_theme_font_size_override("font_size", 16)
	for child: Node in node.get_children(): _override_tree(child, option)

func _set_font(control: Control, face: Font, size: int) -> void:
	control.add_theme_font_override("font", face)
	control.add_theme_font_size_override("font_size", size)
	_override_count += 1

func _override_hud(option: Dictionary) -> void:
	for label: Label in [_main.clock_panel._day_label, _main.clock_panel._time_label, _main.clock_panel._earned_label]:
		_set_font(label, option.heading as Font, int(option.get("hudSize", option.headingSize)))
	for label: Label in [_main.clock_panel._day_caption, _main.clock_panel._time_caption, _main.clock_panel._earned_caption]:
		_set_font(label, option.meta as Font, int(option.metaSize))
	if str(option.id) == "C":
		# The approved study's paper cells end at y=49, not the Control's y=68.
		# Captions above values keep both ink rows inside those authored cells.
		# Remove inherited paragraph spacing from these single-line HUD labels.
		for label: Label in [_main.clock_panel._day_caption, _main.clock_panel._time_caption, _main.clock_panel._earned_caption]:
			label.add_theme_constant_override("line_spacing", 0)
			label.position.y = 8
			label.size.y = 20
		for label: Label in [_main.clock_panel._day_label, _main.clock_panel._time_label, _main.clock_panel._earned_label]:
			label.add_theme_constant_override("line_spacing", 0)
			label.position.y = 29
			label.size.y = 22

func _override_rail(option: Dictionary) -> void:
	var names: Array[Label] = []
	var heading := _main.job_panel._rail_panel.find_child("TeamHeading", true, false) as Label
	if heading != null: names.append(heading)
	for employee_id: String in _main.job_panel._team_buttons:
		var name_label := _main.job_panel._team_buttons[employee_id].find_child("EmployeeName", true, false) as Label
		if name_label != null: names.append(name_label)
	for label: Label in names:
		var slab := option.heading as Font
		if str(option.id) == "B":
			_set_font(label, slab, 16)
		if bool(option.railSlab) and slab.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(option.headingSize)).x <= label.size.x and slab.get_height(int(option.headingSize)) <= label.size.y:
			_set_font(label, slab, int(option.headingSize))

func _record(checks: Array[Dictionary], name: String, ok: bool, detail: Dictionary = {}) -> void:
	checks.append({"name": name, "passed": ok, "detail": detail})

func _fit(checks: Array[Dictionary], label: Control, copy: String, inset: float = 0.0) -> void:
	var face := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var width := face.get_string_size(copy, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var missing := ""
	for character: String in copy:
		if character.unicode_at(0) > 32 and not face.has_char(character.unicode_at(0)) and not missing.contains(character): missing += character
	_record(checks, "Single-line fit: " + copy, width <= label.size.x - inset + 0.5 and face.get_height(size) <= label.size.y + 0.5, {"width": width, "availableWidth": label.size.x - inset, "fontHeight": face.get_height(size), "availableHeight": label.size.y, "fontSize": size, "font": face.resource_path})
	_record(checks, "Glyph coverage: " + copy, missing.is_empty(), {"missing": missing})

func _baseline(label: Label) -> float:
	var face := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	return label.global_position.y + (label.size.y - face.get_height(size)) * 0.5 + face.get_ascent(size)

func _diagnostics(option: Dictionary) -> Dictionary:
	var checks: Array[Dictionary] = []
	var panel := _main.job_panel
	_fit(checks, panel._employee_name, panel._employee_name.text)
	_record(checks, "Header excludes close target", panel._employee_name.get_global_rect().end.x <= panel._drawer_close_button.get_global_rect().position.x)
	_record(checks, "Header role and status do not overlap", panel._employee_name.get_global_rect().end.y <= panel._employee_meta.get_global_rect().position.y and panel._employee_meta.get_global_rect().end.y <= panel._employee_status.get_global_rect().position.y)
	_record(checks, "Header fits paper", panel._employee_status.get_global_rect().end.y <= panel._header_shell.get_global_rect().end.y - 8)
	for control: Control in [panel._employee_meta, panel._employee_status, panel._chat_helper]:
		_record(checks, "Wrapped label fits: " + control.name, control.get_minimum_size().y <= control.size.y + 0.5, {"minimumHeight": control.get_minimum_size().y, "height": control.size.y})
	for button: Button in panel._tab_buttons + [panel._chat_send_button, panel._settings_button, panel._make_job_button]:
		if not button.is_visible_in_tree(): continue
		var style := button.get_theme_stylebox("normal")
		_fit(checks, button, button.text, style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT))
		_record(checks, "Visible action retains hit area: " + button.text, button.size.y >= 40)
	_record(checks, "Composer retains usable input width", panel._chat_input.size.x >= 160, {"width": panel._chat_input.size.x})
	_record(checks, "Composer helper stays inside paper", panel._chat_helper.get_global_rect().end.y <= panel._chat_composer.get_global_rect().end.y - 8)
	var hud := _main.clock_panel
	for value: Label in [hud._day_label, hud._time_label, hud._earned_label]:
		_fit(checks, value, value.text)
		_record(checks, "HUD common value baseline", is_equal_approx(_baseline(value), _baseline(hud._day_label)))
	for caption: Label in [hud._day_caption, hud._time_caption, hud._earned_caption]: _fit(checks, caption, caption.text)
	var warning_count := 0
	for check: Dictionary in checks:
		if not check.passed: warning_count += 1
	return {"option": option.id, "name": option.name, "headingFont": (option.heading as Font).resource_path, "headingSize": option.headingSize, "richFont": (option.rich as Font).resource_path, "richSize": option.richSize, "controlFont": (option.control as Font).resource_path, "metadataFont": (option.meta as Font).resource_path, "metadataSize": option.metaSize, "overriddenControls": _override_count, "checks": checks, "fitWarnings": warning_count}

func _chat_diagnostics() -> Dictionary:
	var panel := _main.job_panel
	var messages: Array[Dictionary] = []
	for child: Node in panel._chat_log.find_children("*", "RichTextLabel", true, false):
		var rich := child as RichTextLabel
		messages.append({"text": rich.get_parsed_text(), "font": rich.get_theme_font("normal_font").resource_path, "size": rich.get_theme_font_size("normal_font_size"), "width": rich.size.x, "height": rich.size.y, "contentHeight": rich.get_content_height(), "laidOutWithoutInternalClipping": rich.get_content_height() <= rich.size.y + 0.5, "globalRect": _rect(rich.get_global_rect())})
	var bar := panel._chat_scroll.get_v_scroll_bar()
	return {"messages": messages, "requiresScroll": bar.max_value > bar.page + 0.5, "scrollValue": bar.value, "scrollMaximum": bar.max_value, "scrollPage": bar.page, "visibleRect": _rect(panel._chat_scroll.get_global_rect())}

func _rect(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}

func _capture(prefix: String) -> Dictionary:
	if DisplayServer.get_name() == "headless": return {"skipped": "headless"}
	RenderingServer.force_draw(false)
	var full := root.get_texture().get_image()
	var paths := {"full": OUTPUT.path_join(prefix + "-full.png"), "ui": OUTPUT.path_join(prefix + "-ui.png"), "sidebar": OUTPUT.path_join(prefix + "-sidebar.png"), "hud": OUTPUT.path_join(prefix + "-hud.png")}
	if full.get_size() != Vector2i(1280, 720):
		_failures.append("Unexpected viewport size: " + str(full.get_size()))
		return paths
	var sidebar := full.get_region(SIDEBAR_CROP)
	var hud := full.get_region(HUD_CROP)
	var detail := Image.create(496, 800, false, full.get_format())
	detail.fill(Color("151515"))
	detail.blit_rect(hud, Rect2i(Vector2i.ZERO, hud.get_size()), Vector2i(44, 0))
	detail.blit_rect(sidebar, Rect2i(Vector2i.ZERO, sidebar.get_size()), Vector2i(0, 80))
	for key: String in paths:
		var image: Image = full if key == "full" else detail if key == "ui" else sidebar if key == "sidebar" else hud
		if image.save_png(paths[key]) != OK: _failures.append("Could not write: " + str(paths[key]))
	var webp_path := OUTPUT.path_join(prefix + "-ui.webp")
	if detail.save_webp(webp_path, false) != OK:
		_failures.append("Could not write lossless detail: " + webp_path)
	paths["webp"] = webp_path
	if prefix.begins_with("C"):
		paths["hudInk"] = _check_hud_ink(hud)
	return paths

func _check_hud_ink(rendered: Image) -> Dictionary:
	# Label rectangles alone missed caption descenders touching the bevel.
	# Compare the real render against the blank, native-size ledger texture.
	var blank := ClockPanel.LEDGER_TEXTURE.get_image()
	var cells: Array[Rect2i] = [Rect2i(32, 11, 108, 40), Rect2i(168, 11, 92, 40), Rect2i(270, 11, 106, 40)]
	var bounds: Array[Rect2i] = [Rect2i(), Rect2i(), Rect2i()]
	var counts: Array[int] = [0, 0, 0]
	var outside := 0
	for y: int in range(rendered.get_height()):
		for x: int in range(rendered.get_width()):
			var source := blank.get_pixel(x, y)
			var actual := rendered.get_pixel(x, y)
			# Ignore transparent texture edges and near-identical sampling noise.
			if source.a < 0.99 or source.r + source.g + source.b - actual.r - actual.g - actual.b < 0.2:
				continue
			var point := Vector2i(x, y)
			var cell_index := -1
			for index: int in range(cells.size()):
				if cells[index].has_point(point): cell_index = index
			if cell_index == -1:
				outside += 1
			else:
				var pixel := Rect2i(point, Vector2i.ONE)
				bounds[cell_index] = pixel if counts[cell_index] == 0 else bounds[cell_index].merge(pixel)
				counts[cell_index] += 1
	var passed := outside == 0 and counts.all(func(count: int) -> bool: return count > 0)
	if not passed: _failures.append("C HUD ink crossed the safe paper cells: %d pixels" % outside)
	return {"passed": passed, "outsidePixels": outside, "inkPixels": counts,
		"safeCells": cells.map(func(rect: Rect2i) -> Dictionary: return _rect(Rect2(rect))),
		"paintedBounds": bounds.map(func(rect: Rect2i) -> Dictionary: return _rect(Rect2(rect)))}

func _finish() -> void:
	var manifest := {"viewport": {"width": 1280, "height": 720}, "workerDisabled": true, "productionFontsChanged": false, "worldFrozen": true, "worldNameplates": "Hidden identically in every option because their direct canvas drawing is outside the per-Control typography preview.", "pixelScaling": "Native integer font sizes; screenshots and UI/HUD crops are never rescaled.", "uiCrop": {"sidebar": _rect(Rect2(SIDEBAR_CROP)), "hud": _rect(Rect2(HUD_CROP)), "composite": {"width": 496, "height": 800, "hudOffset": [44, 0], "sidebarOffset": [0, 80]}, "note": "The 496px detail omits only the outermost 2px of the 498px drawer/rail silhouette; full screenshots retain the complete game."}, "founderCopy": FOUNDER_COPY, "longReply": LONG_REPLY, "shortReply": SHORT_REPLY, "options": _results, "failures": _failures}
	var output := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	if output == null:
		_failures.append("Cannot write typography manifest")
	else:
		output.store_string(JSON.stringify(manifest, "\t"))
		output.close()
	for failure: String in _failures: push_error(failure)
	print("Typography previews complete: %d variants; %d capture/setup failures. Fit warnings are retained for comparison." % [_results.size(), _failures.size()])
	quit(_failures.size())
