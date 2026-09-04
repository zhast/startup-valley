extends SceneTree

const OUTPUT := "res://tests/output/ui-redesign/reader-hud"
const HUD_PAPER_CELLS: Array[Rect2i] = [Rect2i(32, 11, 108, 40), Rect2i(168, 11, 92, 40), Rect2i(270, 11, 106, 40)]
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []
var hud_ink_samples: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 12) -> void:
	for index: int in range(count): await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	captures.append(name)

func click(position: Vector2, button_index: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	await frames(1)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_index = button_index
		event.pressed = down
		root.push_input(event, true)
		await frames(1)

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
		await frames(1)

func text_size(label: Label) -> Vector2:
	return label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size"))

func centered_baseline(label: Label) -> float:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	return label.global_position.y + (label.size.y - font.get_height(size)) * 0.5 + font.get_ascent(size)

func check_nunito_weight(face: FontVariation, weight: float, role: String, italic: bool = false) -> void:
	check(face.get_font_name().contains("Nunito"), "%s resolves to the bundled Nunito family" % role)
	var expected := FontVariation.new()
	expected.base_font = face.base_font
	expected.fallbacks = face.fallbacks
	expected.variation_opentype = {"weight": weight}
	check(face.variation_opentype.get("weight") == weight and face.get_rids() == expected.get_rids(), "%s resolves to effective Nunito weight %d through the supported variation axis" % [role, int(weight)])
	check(((face.base_font.get_font_style() & TextServer.FONT_ITALIC) != 0) == italic, "%s uses an authored %s face" % [role, "italic" if italic else "upright"])
	check(face.variation_embolden == 0.0 and face.variation_transform == Transform2D.IDENTITY, "%s has no synthetic bold or italic transform" % role)

func hud_ink(image: Image) -> Dictionary:
	var blank := ClockPanel.LEDGER_TEXTURE.get_image()
	var counts: Array[int] = [0, 0, 0]
	var bounds: Array[Rect2i] = [Rect2i(), Rect2i(), Rect2i()]
	var outside := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var source := blank.get_pixel(x, y)
			var actual := image.get_pixel(x, y)
			# Compare actual dark text ink with the native unlettered paper. This
			# ignores transparent outside edges and tiny renderer rounding noise.
			if source.a < 0.99 or source.r + source.g + source.b - actual.r - actual.g - actual.b < 0.2: continue
			var point := Vector2i(x, y)
			var cell_index := -1
			for index: int in range(HUD_PAPER_CELLS.size()):
				if HUD_PAPER_CELLS[index].has_point(point): cell_index = index
			if cell_index == -1:
				outside += 1
			else:
				var pixel := Rect2i(point, Vector2i.ONE)
				bounds[cell_index] = pixel if counts[cell_index] == 0 else bounds[cell_index].merge(pixel)
				counts[cell_index] += 1
	var serialized_bounds: Array[Array] = []
	for bound: Rect2i in bounds: serialized_bounds.append([bound.position.x, bound.position.y, bound.size.x, bound.size.y])
	return {"outside_paper_pixels": outside, "ink_pixels": counts, "ink_bounds": serialized_bounds, "passed": outside == 0 and counts.all(func(count: int) -> bool: return count > 0)}

func check_rendered_hud(clock: ClockPanel, label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(2)
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image().get_region(Rect2i(clock.get_global_rect()))
	var sample := hud_ink(image)
	sample["case"] = label
	hud_ink_samples.append(sample)
	check(bool(sample["passed"]), "Actual HUD ink stays inside all three painted-paper insets: %s (%s)" % [label, sample])

func check_hud_ink_detector() -> void:
	var probe := ClockPanel.LEDGER_TEXTURE.get_image().duplicate() as Image
	for cell: Rect2i in HUD_PAPER_CELLS: probe.set_pixelv(cell.get_center(), Color.BLACK)
	check(bool(hud_ink(probe)["passed"]), "HUD raster detector accepts marked pixels within all three paper cells")
	probe.set_pixel(40, 56, Color.BLACK)
	check(int(hud_ink(probe)["outside_paper_pixels"]) > 0, "HUD raster detector rejects new ink on the bevel even when a Label rect would fit")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	var background := ColorRect.new()
	background.color = Color("887354")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	var clock: ClockPanel = load("res://ui/clock_panel.tscn").instantiate()
	root.add_child(clock)
	var hud := FounderHud.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(hud)
	hud.dismiss_movement_hint()
	var reader: ArtifactViewer = load("res://ui/artifact_viewer.tscn").instantiate()
	root.add_child(reader)
	var preview := Button.new()
	preview.text = "Preview file"
	preview.position = Vector2(24, 660)
	preview.size = Vector2(180, 44)
	CozyUI.button(preview, "secondary")
	root.add_child(preview)
	await frames()
	var copy := "# A clear first offer\n\nAn intentional document has **real bold**, *real italic*, and `inline_code()` alongside readable prose.\n\n## Next steps\n\n- Publish a useful first version.\n- Keep the learning loop short.\n\n### A small experiment\n\n```css\n.card { color: #151515; }\n[fixture] **literal**\n```\n\n"
	var full_path := "research/café–Zoë-évaluation — résumé-and-long-project-validation-recommendations.md"
	preview.pressed.connect(func() -> void: reader.show_artifact(full_path, copy.repeat(14)))
	await click(preview.get_global_rect().get_center())
	await frames(20)
	check(reader.visible and reader._content.is_visible_in_tree(), "Reader and scrolling document are visible before input")
	check(reader._title_label.text == full_path.get_file(), "Reader presents the complete accented filename once, without missing-glyph substitutions")
	check(reader._title_label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "Long file titles elide without widening the notebook")
	check(reader._title_label.get_theme_font("font") == GameFonts.BOLD, "Dynamic reader filename uses proportional Nunito Bold instead of the limited pixel face")
	check(reader._title_label.get_theme_font_size("font_size") == 20, "Reader filename has a distinct fixed 20px section role")
	check(GameFonts.has_glyphs(reader._title_label.get_theme_font("font"), full_path.get_file() + "…"), "Reader filename face covers tested accents, en/em dashes and its elision marker")
	check(GameFonts.BOLD.get_height(20) <= reader._title_label.size.y, "Filename line box contains the actual 20px font metrics")
	check(not reader._title_label.get_global_rect().intersects(reader._close_button.get_global_rect()), "Long reader title does not overlap the close target")
	check_nunito_weight(GameFonts.BODY, 550.0, "Reader body")
	check_nunito_weight(GameFonts.BOLD, 700.0, "Reader bold and filename")
	check_nunito_weight(GameFonts.EMPHASIS, 600.0, "Reader metadata and HUD captions")
	check_nunito_weight(GameFonts.ITALIC, 550.0, "Reader italic", true)
	check_nunito_weight(GameFonts.BOLD_ITALIC, 700.0, "Reader bold italic", true)
	check(reader._caption_label.text == "Job delivery · Read only", "Reader identifies provenance separately from title")
	check(reader._content.get_theme_stylebox("normal") is StyleBoxEmpty, "Document center has no decorative rules or nested frame")
	check(reader._content.get_theme_font("normal_font") == GameFonts.BODY, "Markdown prose uses corrected deterministic body face")
	check(reader._content.get_theme_font("bold_font") == GameFonts.BOLD, "Markdown bold resolves to its explicit weight")
	check(reader._content.get_theme_font("italics_font") == GameFonts.ITALIC, "Markdown italic resolves explicitly")
	check(reader._content.get_theme_font("bold_italics_font") == GameFonts.BOLD_ITALIC, "Markdown combined emphasis resolves to authored bold italic")
	check(reader._content.get_theme_font("mono_font") == GameFonts.MONO, "Fenced and inline code resolve to the bundled mono face")
	check(reader._content.get_theme_font_size("mono_font_size") == 16 and GameFonts.MONO.get_font_name().contains("JetBrains"), "Code retains JetBrains Mono16, not the coarse preview pixel face")
	var body_rid := GameFonts.BODY.get_rids()[0]
	check(GameFonts.BOLD.get_rids()[0] != body_rid, "Effective bold RID is distinct from body, not a fallback alias")
	check(GameFonts.ITALIC.get_rids()[0] != body_rid, "Effective italic RID is distinct from upright body")
	check(GameFonts.MONO.get_rids()[0] != body_rid, "Effective code RID is distinct from proportional body")
	check(reader._content.text.contains("[code]") and reader._content.text.contains("[i]real italic[/i]"), "Markdown parser explicitly marks code and italic spans")
	check(reader._content.get_parsed_text().contains("[fixture] **literal**"), "Code preserves brackets and Markdown punctuation")
	for heading_size: int in [20, 22, 24]:
		check(reader._content.text.contains("[font_size=%d][b]" % heading_size), "Markdown heading level retains proportional bold %dpx hierarchy" % heading_size)
	check(reader._content.get_theme_font_size("normal_font_size") == 18, "Document prose stays 18px")
	check(reader._caption_label.get_theme_font("font") == GameFonts.EMPHASIS and reader._caption_label.get_theme_font_size("font_size") == 14, "Reader functional metadata uses Nunito600 at 14px")
	check(reader._content.get_theme_constant("line_separation") == 6, "Document line spacing is preserved independently of UI paragraph spacing")
	check(reader._close_button.size.x >= 44 and reader._close_button.size.y >= 44, "Reader close target is at least 44px")
	check(reader._close_button.has_focus(), "Reader opens with visible close focus")
	check(reader.modal_fits_viewport(), "Reader modal fits authored viewport")
	var expected_document := reader._content.get_parsed_text()
	await capture("reader-top")
	for label: Label in [reader._title_label, reader._caption_label]:
		var hover := InputEventMouseMotion.new()
		hover.position = label.get_global_rect().get_center()
		hover.global_position = hover.position
		root.push_input(hover, true)
		await frames(2)
		check(root.gui_get_hovered_control() == label, "Pointer reaches filename/provenance tooltip label")
		check(label.get_tooltip().contains(full_path), "Reachable filename/provenance tooltip retains full path")
	var away := InputEventMouseMotion.new()
	away.position = Vector2(1100, 700)
	root.push_input(away, true)
	await key(KEY_TAB)
	check(reader._content.has_focus(), "Tab enters the actual visible document")
	var scroll_before := reader._content.get_v_scroll_bar().value
	for index: int in range(8): await click(reader._content.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	check(reader._content.get_v_scroll_bar().value > scroll_before, "Actual wheel input scrolls the long document")
	await capture("reader-scrolled")
	await key(KEY_TAB)
	check(reader._close_button.has_focus(), "Tab cycles back to close within reader")
	await click(reader._close_button.get_global_rect().get_center())
	await frames(20)
	check(not reader.visible, "Actual close-button click dismisses the reader")
	check(preview.has_focus(), "Close click restores focus to the original visible Preview action")
	await click(preview.get_global_rect().get_center())
	await frames(20)
	check(reader._content.get_parsed_text() == expected_document and not expected_document.is_empty(), "Reopening identical Markdown preserves the rendered text, not only visibility")
	check(reader._content.get_content_height() > reader._content.size.y, "Reopened long Markdown still has a laid-out scrolling document")
	check(is_zero_approx(reader._content.get_v_scroll_bar().value), "Same-file Preview reopens at the top")
	await capture("reader-reopened")
	reader.show_artifact(full_path, copy.repeat(14), "Shared Studio")
	await frames(20)
	check(reader._content.get_parsed_text() == expected_document, "Showing identical content from Studio rebuilds the text after clearing")
	check(reader._content.get_content_height() > reader._content.size.y, "Studio replacement keeps the actual document layout")
	await capture("reader-studio-same-document")
	await key(KEY_ESCAPE)
	await frames(20)
	reader.show_artifact("site/styles.css", "* { box-sizing: border-box; }\n[x] { color: red; }", "Studio file")
	await frames(20)
	check(reader._content.get_parsed_text() == "* { box-sizing: border-box; }\n[x] { color: red; }", "Source is rendered literally rather than parsed as Markdown")
	check(reader._content.get_theme_font("normal_font") == GameFonts.MONO, "Source uses deterministic mono instead of a system fallback")
	check(reader._content.get_theme_font_size("normal_font_size") == 16, "Source uses a readable 16px mono size")
	check(reader._caption_label.text == "Studio file · Read only", "Studio provenance can be shown without another title")
	check(is_zero_approx(reader._content.get_v_scroll_bar().value), "Reopening resets document scroll")
	await capture("reader-source")
	reader.show_artifact("site/styles.css", "* { box-sizing: border-box; }\n[x] { color: red; }", "Studio file")
	await frames(20)
	check(reader._content.get_parsed_text() == "* { box-sizing: border-box; }\n[x] { color: red; }", "Repeated source content neither disappears nor accumulates")
	reader.show_artifact(full_path, copy.repeat(14), "Shared Studio")
	await frames(20)
	check(reader._content.get_parsed_text() == expected_document, "Source-to-Markdown replacement preserves the exact document and formatting")
	check(reader._content.get_theme_font("normal_font") == GameFonts.BODY and reader._content.get_theme_font_size("normal_font_size") == 18, "Source-to-Markdown replacement restores Nunito18 reading metrics")
	check(reader._content.get_theme_font("mono_font") == GameFonts.MONO and reader._content.get_theme_font_size("mono_font_size") == 16, "Source-to-Markdown replacement retains separate JetBrains16 inline/fenced code")
	check(reader._title_label.text == full_path.get_file() and reader._title_label.tooltip_text == full_path, "Source-to-Markdown replacement retains the original Unicode filename and full path")
	await capture("reader-markdown-after-source")
	reader.show_artifact("site/replacement.css", "body { margin: 0; }", "Studio file")
	await frames(20)
	check(reader._content.get_parsed_text() == "body { margin: 0; }" and reader._content.get_theme_font("normal_font") == GameFonts.MONO, "Returning from Markdown to source restores literal content and mono face")
	await key(KEY_ESCAPE)
	await frames(20)
	check(not reader.visible, "Escape dismisses the visible reader")
	check(preview.has_focus(), "Escape restores original Preview even after replacing an already-open document")
	var cjk_path := "company/会社の計画—产品验证—résumé.html"
	var cjk_source := "<main lang=\"ja\">会社の計画 → résumé</main>\n<!-- [source] *literal* -->"
	reader.show_artifact(cjk_path, cjk_source, "Shared Studio")
	await frames(20)
	check(reader._title_label.text == cjk_path.get_file() and reader._title_label.tooltip_text == cjk_path, "CJK filename and full path remain exact, never replaced with code-point notation")
	var missing_characters: Array[String] = []
	for character: String in cjk_path.get_file():
		if not GameFonts.BOLD.has_char(character.unicode_at(0)): missing_characters.append(character)
	check(missing_characters.is_empty(), "Dynamic filename has bundled glyph coverage for the tested CJK text; missing: %s" % [missing_characters])
	check(reader._content.get_parsed_text() == cjk_source, "Unicode source content remains verbatim through the reader")
	check(GameFonts.has_glyphs(GameFonts.MONO, cjk_source), "Source code retains bundled glyph coverage for tested Unicode without modifying its text")
	check(reader._title_label.get_theme_font("font") == GameFonts.BOLD and reader._title_label.get_theme_font_size("font_size") == 20, "CJK filenames keep the same proportional section role without width-dependent resizing")
	check(not reader._title_label.get_global_rect().intersects(reader._close_button.get_global_rect()), "CJK filename keeps the close target unobstructed")
	await capture("reader-unicode-source")
	await key(KEY_ESCAPE)
	await frames(20)
	check(preview.has_focus(), "Unicode document closes back to the original Preview action")
	reader.show_artifact("temporary.md", copy)
	await frames(20)
	preview.disabled = true
	await key(KEY_ESCAPE)
	await frames(20)
	check(not preview.has_focus(), "Closing never restores focus to a now-disabled action")
	preview.disabled = false
	preview.grab_focus()
	reader.show_artifact("temporary.md", copy)
	await frames(20)
	preview.hide()
	await key(KEY_ESCAPE)
	await frames(20)
	check(not preview.has_focus(), "Closing never restores focus to a now-hidden action")
	preview.show()
	preview.grab_focus()
	reader.show_artifact("temporary.md", copy)
	await frames(20)
	preview.queue_free()
	await frames(2)
	await key(KEY_ESCAPE)
	await frames(20)
	check(not reader.visible, "Freed Preview target is safely ignored after closing")
	reader.show_artifact("brief.md", copy)
	await frames(12)
	check(reader._content.get_theme_font("normal_font") == GameFonts.BODY, "Switching source to Markdown restores body face")
	reader.hide()
	check_hud_ink_detector()
	check(clock.size == Vector2(408, 68) and ClockPanel.LEDGER_TEXTURE.get_size() == Vector2(408, 68), "HUD and source artwork retain their native 408 by 68 dimensions")
	check(clock.scale == Vector2.ONE and clock.get_node("LedgerTexture").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "HUD is unscaled with nearest-filtered artwork")
	var values: Array[Label] = [clock._day_label, clock._time_label, clock._earned_label]
	var captions: Array[Label] = [clock._day_caption, clock._time_caption, clock._earned_caption]
	for value: Label in values:
		check(value.get_theme_font("font") == GameFonts.DISPLAY and value.get_theme_font_size("font_size") == 22, "Every HUD value uses the same native 2x Slab22 role")
		check(is_equal_approx(centered_baseline(value), centered_baseline(clock._day_label)), "HUD values share the same measured baseline")
		check(value.get_theme_font("font").get_height(22) <= value.size.y, "HUD value line box contains the actual Slab ascenders and descenders")
		check(value.position.y == 29 and value.size.y == 22 and value.get_theme_constant("line_spacing") == 0, "HUD value uses the approved y29/h22 single-line box: actual %s, minimum %s, font height %s" % [value.get_rect(), value.get_minimum_size(), value.get_theme_font("font").get_height(22)])
	for index: int in range(captions.size()):
		var caption := captions[index]
		check(caption.get_theme_font("font") == GameFonts.EMPHASIS and caption.get_theme_font_size("font_size") == 14, "Every HUD caption uses Nunito600 at fixed 14px")
		check(is_equal_approx(centered_baseline(caption), centered_baseline(clock._day_caption)), "HUD captions share the same measured baseline")
		check(is_equal_approx(caption.get_global_rect().get_center().x, values[index].get_global_rect().get_center().x), "HUD caption is centered above its own value")
		check(text_size(caption).x <= caption.size.x and caption.position.y + caption.size.y <= values[index].position.y, "HUD captions fit without overlapping value glyphs")
		check(caption.position.y == 8 and caption.size.y == 20 and caption.get_theme_constant("line_spacing") == 0, "HUD caption uses the approved y8/h20 box: actual %s, minimum %s, font height %s" % [caption.get_rect(), caption.get_minimum_size(), caption.get_theme_font("font").get_height(14)])
	check([clock._day_caption.text, clock._time_caption.text, clock._earned_caption.text] == ["Day", "Time", "Earned"], "HUD captions clearly identify the three aligned values")
	check(clock._earned_caption.tooltip_text.contains("Gross in-game revenue") and clock._earned_caption.tooltip_text.contains("not company cash"), "Earned caption preserves gross in-game revenue semantics")
	for day: int in [1, 12, 123, 999]:
		clock.show_clock(day, 17 * 60 + 30)
		await frames(1)
		check(clock._day_label.text == str(day) and text_size(clock._day_label).x <= clock._day_label.size.x, "Day %d fits at 22px without a redundant DAY prefix" % day)
		check(clock._day_label.get_theme_font_size("font_size") == 22, "Day %d never shrinks its type" % day)
		await check_rendered_hud(clock, "Day %d" % day)
	for minute: int in [0, 8 * 60, 12 * 60 + 30, 17 * 60 + 30, 23 * 60 + 59]:
		clock.show_clock(999, minute)
		check(text_size(clock._time_label).x <= clock._time_label.size.x, "Time %s fits at 22px" % clock._time_label.text)
		await check_rendered_hud(clock, "Time %s" % clock._time_label.text)
	for amount: float in [0.0, 125.5, 999.99, 1000.0, 9999.99, 123456.78, 999999.99, 1234567890.25, 1234567890123.45]:
		clock.show_money_earned(amount)
		check(text_size(clock._earned_label).x <= clock._earned_label.size.x, "Earned value %s fits without font shrinking" % clock._earned_label.text)
		check(clock._earned_label.get_theme_font_size("font_size") == 22, "Earned value %s retains the shared numeric size" % clock._earned_label.text)
		check(clock._earned_label.tooltip_text.contains("%.2f" % amount), "Exact earned cents remain accessible for %s" % amount)
		check(GameFonts.has_glyphs(GameFonts.DISPLAY, clock._earned_label.text), "Formatted earnings use supported Slab glyphs: %s" % clock._earned_label.text)
		await check_rendered_hud(clock, "Earned %.2f" % amount)
	clock.show_money_earned(125.5)
	check(clock._earned_label.text == "$125.50", "Ordinary earnings retain exact cents in the HUD")
	clock.show_clock(123, 17 * 60 + 30)
	clock.show_money_earned(1234567890.25)
	await check_rendered_hud(clock, "Day 123 / 17:30 / $1.2B")
	await capture("hud-paper-insets")
	hud.show_delivery("fixture", "mira", "Mina", "site/a-long-website-file-name.html ready")
	await frames(20)
	check(hud._notification.size.y == 84, "Delivery toast is compact, not an oversized paper memo")
	var view := hud._notification.get_node("ViewDelivery") as Button
	check(view.is_visible_in_tree() and view.size.y >= 40, "Delivery action is visible with an adequate hit target")
	var delivered: Array[String] = []
	hud.delivery_requested.connect(func(job_id: String, _employee_id: String) -> void: delivered.append(job_id))
	await capture("hud-and-toast")
	await click(view.get_global_rect().get_center())
	check(delivered == ["fixture"], "Actual toast View click requests the correct delivery once")
	hud.hide_delivery()
	check(not hud.delivery_visible() and hud._delivery_job_id.is_empty(), "Toast dismissal clears local notification state")
	var employee := EmployeeAvatar.new()
	employee.display_name = "Mina"
	employee.position = Vector2(300, 340)
	var name_line := ceilf(EmployeeAvatar.NAME_FONT.get_height(EmployeeAvatar.NAME_FONT_SIZE)) + EmployeeAvatar.NAME_INSET.y * 2
	var detail_lines := name_line + EmployeeAvatar.TEXT_LINE_GAP + ceilf(EmployeeAvatar.STATUS_FONT.get_height(EmployeeAvatar.STATUS_FONT_SIZE))
	check(employee.world_label_rect().size.y == ceilf(name_line / 2) * 2, "Idle nameplate reserves actual identity metrics and paper insets")
	employee._label_hold = 0
	check(not employee._labels_visible(), "Idle label expires so it cannot cover the desk permanently")
	employee.set_ui_highlighted(true)
	check(employee._labels_visible(), "Hover or selection reveals contextual identity")
	check(employee.world_label_rect().size.y == ceilf(detail_lines / 2) * 2, "Selection reserves two readable lines in one card")
	employee.set_ui_highlighted(false)
	employee.work_state = EmployeeAvatar.WorkState.WAITING_APPROVAL
	check(employee.world_label_rect().size.y == ceilf(detail_lines / 2) * 2, "Approval attention preserves the same two-line geometry")
	for line: String in employee._wrap_speech("A very long memory sentence must remain readable without covering the whole office", 21):
		check(GameFonts.BODY.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 164, "Speech line fits its 16px text-safe width")
	employee.free()
	var label_examples: Array[EmployeeAvatar] = []
	for index: int in range(3):
		var avatar := EmployeeAvatar.new()
		var record := EmployeeRecord.new()
		record.id = "theo" if index == 1 else "mira"
		record.display_name = "Theo" if index == 1 else "Mina"
		var point := Vector2(360 + index * 240, 380)
		avatar.configure(record, point, point, point)
		root.add_child(avatar)
		avatar.set_physics_process(false)
		avatar._label_hold = 0
		if index == 0: avatar._label_hold = 10
		elif index == 1: avatar.set_ui_highlighted(true)
		else:
			avatar._speech_visible = true
			avatar.memory_line = "A small useful website is a good first step."
		avatar.queue_redraw()
		label_examples.append(avatar)
	await capture("world-label-specimen")
	for avatar: EmployeeAvatar in label_examples: avatar.free()
	var result_name := "results-headless.json" if DisplayServer.get_name() == "headless" else "results.json"
	var output := FileAccess.open(OUTPUT.path_join(result_name), FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "hud_ink_samples": hud_ink_samples, "renderer": DisplayServer.get_name()}, "\t"))
	output.close()
	print("Reader/HUD redesign: %d checks, %d failures" % [checks, failures.size()])
	quit(failures.size())
