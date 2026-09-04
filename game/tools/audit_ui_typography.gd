extends SceneTree
## Historical Nunito weight experiment, explicitly reconstructed in memory.
## Current Whop runtime controls are measured separately, never called legacy fonts.
## godot --path game --script res://tools/audit_ui_typography.gd

const OUTPUT := "res://tests/output/whop-typography/legacy-weight-experiment"
const LEGACY_DISPLAY: FontFile = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const LEGACY_BODY: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
const SAMPLE := "Yes. I would group the pain points."

var _diagnostics: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This historical visual diagnostic requires the actual renderer.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var base := LEGACY_BODY.base_font
	var body := FontVariation.new()
	body.base_font = base
	body.variation_opentype = {"wght": 550.0} # The historical ignored-axis defect.
	var ts := TextServerManager.get_primary_interface()
	var intended := _font_variant(base, 550.0)
	var semibold := _font_variant(base, 600.0)
	var weight_tag := ts.name_to_tag("weight")
	var current_weight := float(body.variation_opentype.get("weight", body.variation_opentype.get(weight_tag, base.get_font_weight())))
	var supported: Array[Dictionary] = []
	for tag: Variant in base.get_supported_variation_list():
		var limits: Vector3 = base.get_supported_variation_list()[tag]
		supported.append({"tag": tag, "name": ts.tag_to_name(tag), "minimum": limits.x, "maximum": limits.y, "default": limits.z})
	_diagnostics = {
		"engine": Engine.get_version_info().string,
		"scope": "Historical Nunito/Tiny5 reconstruction; current Whop controls recorded separately",
		"legacyBaseResource": base.resource_path,
		"legacyReconstructedAxes": body.variation_opentype,
		"supportedAxes": supported,
		"baseWeight": base.get_font_weight(),
		"legacyResolvedWeight": current_weight,
		"legacyResolvesToDefaultFont": body.get_rids() == base.get_rids(),
		"legacyResolvesToIntended550": body.get_rids() == intended.get_rids(),
		"sample": SAMPLE,
		"samples": [],
		"currentRuntimeControls": [],
		"runtimeChanged": false,
	}
	for size_value: int in [14, 16, 18]:
		for entry: Dictionary in [{"name": "legacyIgnoredAxis", "font": body}, {"name": "legacyWeight550", "font": intended}, {"name": "legacyWeight600", "font": semibold}]:
			var font: Font = entry.font
			var metrics := font.get_string_size(SAMPLE, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value)
			_diagnostics.samples.append({"variant": entry.name, "size": size_value, "width": metrics.x, "height": metrics.y})
	# Resolve real controls, including the RichTextLabel font role slots that do
	# not necessarily follow Theme.default_font. No worker or provider is started.
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await process_frame
	await process_frame
	main.job_panel._append_chat_line("employee", "Mina", SAMPLE + " **Bold evidence.**")
	await process_frame
	_record_control("employee role", main.job_panel._employee_meta, "font")
	_record_control("chat input", main.job_panel._chat_input, "font")
	_record_control("assign button", main.job_panel._assign_button, "font")
	var messages := main.job_panel._chat_log.find_children("*", "RichTextLabel", true, false)
	if not messages.is_empty():
		var message := messages.back() as RichTextLabel
		for role: String in ["normal_font", "bold_font", "italics_font", "mono_font"]:
			_record_control("chat " + role, message, role)
	main.artifact_viewer.show_artifact("audit.md", "# Heading\nBody **bold** and plain copy.")
	for role: String in ["normal_font", "bold_font", "italics_font", "mono_font"]:
		_record_control("reader " + role, main.artifact_viewer._content, role)
	main.game_audio.shutdown()
	main.queue_free()
	await process_frame
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	viewport.add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.color = Color("e5e1d7")
	backdrop.size = canvas.size
	canvas.add_child(backdrop)
	_label(canvas, "Historical experiment — the Nunito Sans weight correction", Rect2(24, 12, 1216, 40), semibold, 24)
	_label(canvas, "Legacy recreation only. Current runtime uses Acid Grotesk + Inter; current controls are recorded separately.", Rect2(24, 53, 1216, 28), intended, 16)
	var variants: Array[Dictionary] = [
		{"title": "LEGACY BUG: effective weight %d" % int(current_weight), "font": body},
		{"title": "LEGACY FIX: weight = 550", "font": intended},
		{"title": "LEGACY COMPARISON: weight = 600", "font": semibold},
	]
	for index: int in range(variants.size()):
		var x := 24.0 + index * 416.0
		var value: Dictionary = variants[index]
		var font: Font = value.font
		_label(canvas, value.title, Rect2(x, 94, 392, 28), semibold, 16)
		var plain := ColorRect.new()
		plain.position = Vector2(x, 131)
		plain.size = Vector2(392, 241)
		plain.color = Color("f4ddb0")
		canvas.add_child(plain)
		_specimen(plain, font, "Plain parchment color")
		var paper := Panel.new()
		paper.position = Vector2(x, 392)
		paper.size = Vector2(392, 241)
		paper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		paper.add_theme_stylebox_override("panel", NotebookSkin.parchment())
		canvas.add_child(paper)
		_specimen(paper, font, "Existing parchment texture")
	_label(canvas, "Legacy display: Tiny5 18", Rect2(24, 654, 398, 40), LEGACY_DISPLAY, 18)
	_label(canvas, "Legacy Tiny5 20", Rect2(440, 654, 398, 40), LEGACY_DISPLAY, 20)
	_label(canvas, "Legacy action — Nunito 600 / 18", Rect2(856, 654, 398, 40), semibold, 18)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	var output_path := OUTPUT + "/font-comparison.png"
	if picture == null or picture.is_empty():
		push_error("Typography specimen requires the actual renderer, not --headless.")
		quit(1)
		return
	picture.save_png(output_path)
	_diagnostics["specimen"] = output_path
	var output := FileAccess.open(OUTPUT + "/diagnostics.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(_diagnostics, "\t") + "\n")
	output.close()
	print(JSON.stringify(_diagnostics, "\t"))
	quit()

func _font_variant(base: Font, weight: float) -> FontVariation:
	var variant := FontVariation.new()
	variant.base_font = base
	variant.variation_opentype = {"weight": weight}
	return variant

func _label(parent: Control, content: String, box: Rect2, font: Font, font_size: int, color: Color = Color("151515")) -> Label:
	var label := Label.new()
	label.position = box.position
	label.size = box.size
	label.text = content
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _specimen(parent: Control, font: Font, heading: String) -> void:
	_label(parent, heading, Rect2(20, 15, 352, 26), font, 18)
	_label(parent, "16 px body: Yes. I would group the pain points, pick one narrow promise, and write a validation plan.", Rect2(20, 52, 352, 80), font, 16)
	_label(parent, "18 px body: What are we building?", Rect2(20, 139, 352, 28), font, 18)
	_label(parent, "14 px metadata: Product + research", Rect2(20, 180, 352, 24), font, 14, Color("354b98"))
	_label(parent, "14 px status: AVAILABLE", Rect2(20, 208, 352, 24), font, 14, Color("365d1f"))

func _record_control(label: String, control: Control, role: String) -> void:
	var font := control.get_theme_font(role)
	_diagnostics.currentRuntimeControls.append({
		"control": label,
		"fontName": font.get_font_name(),
		"fontStyle": font.get_font_style_name(),
		"resource": font.resource_path,
		"effectiveWeight": font.get_font_weight(),
		"sameRidAsBody": font.get_rids() == GameFonts.BODY.get_rids(),
		"fontSize": control.get_theme_font_size(role + "_size" if control is RichTextLabel else "font_size"),
	})
