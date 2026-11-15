class_name StudioWebsitePreview
extends Control
## A read-only, fictional project homepage. No HTML, URLs, provider or save access.

signal closed

const MAX_SIZE := Vector2(944, 624)
const WINDOW_ART := preload("res://assets/runtime/office/architecture/window.png")
const FLOOR_ART := preload("res://assets/runtime/office/architecture/floor.png")
const DESK_BACK := preload("res://assets/runtime/office/workstations-v2/desk-south-rear.png")
const DESK_FRONT := preload("res://assets/runtime/office/workstations-v2/desk-south-front.png")

var _frame: PanelContainer
var _scroll: ScrollContainer
var _hero: GridContainer
var _benefits: GridContainer
var _content: VBoxContainer
var _title: Label
var _studio: Label
var _topic: Label
var _welcome: Label
var _stage: Label
var _close_button: Button
var _back_button: Button
var _focus_return: WeakRef
var _snapshot: Dictionary = {}

class OfficeIllustration extends Control:
	func _ready() -> void:
		custom_minimum_size = Vector2(320, 180)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clip_contents = true

	func _draw() -> void:
		var origin := Vector2(floorf((size.x - 320) * 0.5), 0)
		draw_rect(Rect2(origin, Vector2(320, 180)), Color("eadabd"))
		draw_texture_rect(StudioWebsitePreview.FLOOR_ART, Rect2(origin + Vector2(0, 91), Vector2(320, 89)), true)
		draw_texture(StudioWebsitePreview.WINDOW_ART, origin + Vector2(80, 0))
		draw_texture(StudioWebsitePreview.DESK_BACK, origin + Vector2(64, -20))
		draw_texture(StudioWebsitePreview.DESK_FRONT, origin + Vector2(64, -20))
		draw_texture_rect_region(CharacterArt.locomotion_sheet("mira"), Rect2(origin + Vector2(36, 87), Vector2(48, 80)), Rect2(0, 0, 48, 80))
		draw_texture_rect_region(CharacterArt.locomotion_sheet("founder"), Rect2(origin + Vector2(238, 87), Vector2(48, 80)), Rect2(0, 0, 48, 80))

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = GameFonts.interface_theme()
	var scrim := ColorRect.new()
	scrim.color = Color(0.08, 0.06, 0.035, 0.7)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	_frame = PanelContainer.new()
	_frame.name = "WebsiteFrame"
	_frame.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(24, 18, 24, 18)))
	add_child(_frame)
	# Wrapped labels settle after the first container pass. Re-fit then so their
	# temporary zero-width height cannot leave the modal larger than the viewport.
	_frame.minimum_size_changed.connect(func() -> void: _fit.call_deferred())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_frame.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	_studio = _label("Our little studio", header, "section")
	_studio.name = "StudioName"
	_close_button = Button.new()
	_close_button.name = "CloseWebsitePreview"
	CozyUI.close(_close_button)
	_close_button.tooltip_text = "Close website preview"
	_close_button.pressed.connect(dismiss)
	header.add_child(_close_button)
	_scroll = ScrollContainer.new()
	_scroll.name = "WebsitePage"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	CozyUI.scroll(_scroll)
	column.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 18)
	_scroll.add_child(_content)
	var eyebrow := _label("IN-GAME WEBSITE PREVIEW", _content, "meta")
	eyebrow.name = "PreviewNotice"
	eyebrow.add_theme_color_override("font_color", CozyUI.SUCCESS)
	_hero = GridContainer.new()
	_hero.columns = 2
	_hero.add_theme_constant_override("h_separation", 24)
	_hero.add_theme_constant_override("v_separation", 16)
	_content.add_child(_hero)
	var introduction := VBoxContainer.new()
	introduction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	introduction.add_theme_constant_override("separation", 12)
	_hero.add_child(introduction)
	_topic = _label("A small idea, made with care", introduction, "meta")
	_title = _label("Our next adventure", introduction, "display")
	_title.name = "WebsiteProjectTitle"
	_title.add_theme_font_size_override("font_size", 33)
	_welcome = _label("A little curiosity. A little courage. Something good, made together.", introduction)
	var illustration_frame := PanelContainer.new()
	illustration_frame.add_theme_stylebox_override("panel", CozyUI.card(Vector4(6, 6, 6, 6)))
	_hero.add_child(illustration_frame)
	var illustration := OfficeIllustration.new()
	illustration.name = "StudioIllustration"
	illustration_frame.add_child(illustration)
	_stage = _label("A fresh page in our story", _content, "action")
	_stage.name = "WebsiteProjectStage"
	_benefits = GridContainer.new()
	_benefits.columns = 3
	_benefits.add_theme_constant_override("h_separation", 12)
	_benefits.add_theme_constant_override("v_separation", 12)
	_content.add_child(_benefits)
	_add_benefit("document", "One clear idea", "A small beginning, with room for something wonderful.")
	_add_benefit("folder", "Made together", "A little studio. Shared ideas. Plenty of care.")
	_add_benefit("checked", "Room to grow", "Built one thoughtful day at a time.")
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	var note := _label("A page from your studio’s story.", footer, "meta")
	note.name = "FictionalPreviewCaption"
	_back_button = Button.new()
	_back_button.name = "BackFromWebsitePreview"
	_back_button.text = "Back to our project"
	CozyUI.button(_back_button, "primary")
	_back_button.pressed.connect(dismiss)
	footer.add_child(_back_button)
	_close_button.focus_next = _close_button.get_path_to(_back_button)
	_close_button.focus_previous = _close_button.focus_next
	_back_button.focus_next = _back_button.get_path_to(_close_button)
	_back_button.focus_previous = _back_button.focus_next
	resized.connect(_fit)
	_fit()
	hide()

func _label(value: String, parent: Node, role: String = "body") -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CozyUI.label(label, role)
	parent.add_child(label)
	return label

func _add_benefit(icon: String, heading: String, body: String) -> void:
	var card := PanelContainer.new()
	card.name = "Benefit" + str(_benefits.get_child_count() + 1)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", CozyUI.card(Vector4(16, 14, 16, 14)))
	_benefits.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var art := TextureRect.new()
	art.texture = CozyUI.icon(icon)
	art.stretch_mode = TextureRect.STRETCH_KEEP
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art)
	_label(heading, column, "action")
	_label(body, column)

func _fit() -> void:
	if _frame == null: return
	var available := get_viewport_rect().size
	var margin := 16.0 if available.x < 700 else 32.0
	_frame.size = Vector2(minf(MAX_SIZE.x, available.x - margin * 2), minf(MAX_SIZE.y, available.y - margin * 2))
	_frame.position = ((available - _frame.size) * 0.5).floor()
	var wide := _frame.size.x >= 760
	_hero.columns = 2 if wide else 1
	_benefits.columns = 3 if wide else 1

func present(project: Dictionary, studio_name: String = "Our little studio") -> void:
	assert(is_node_ready(), "Add StudioWebsitePreview to the scene before presenting it")
	_snapshot = project.duplicate(true)
	_focus_return = weakref(get_viewport().gui_get_focus_owner())
	_studio.text = _text(studio_name, "Our little studio", 48)
	var project_name := _text(_snapshot.get("name", ""), "Our next adventure", 120)
	_title.text = project_name
	_title.tooltip_text = project_name
	_title.add_theme_font_override("font", GameFonts.display_font_for(project_name))
	var topic := _text(_snapshot.get("topicName", ""), "A small idea", 48)
	var kind := _text(_snapshot.get("typeName", ""), "Made with care", 32)
	_topic.text = topic + " · " + kind
	var released := str(_snapshot.get("status", "")) in ["released", "complete"]
	var ready := bool(_snapshot.get("ready", false))
	_stage.text = "Made with care. Shared with the valley." if released else "Almost opening day." if ready else "A fresh page in our story."
	_welcome.text = "What began as a little idea now has a place in our story." if released else "A little curiosity. A little courage. Something good, made together."
	_scroll.scroll_vertical = 0
	show()
	_fit()
	_fit.call_deferred()
	_back_button.grab_focus()

func dismiss() -> void:
	if not visible: return
	hide()
	if _focus_return != null:
		var previous := _focus_return.get_ref() as Control
		if previous != null and previous.is_visible_in_tree(): previous.grab_focus()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_PAGEDOWN, KEY_PAGEUP]:
		_scroll.scroll_vertical += roundi(_scroll.size.y * 0.8) * (1 if event.keycode == KEY_PAGEDOWN else -1)
		get_viewport().set_input_as_handled()

static func _text(value: Variant, fallback: String, limit: int) -> String:
	if not value is String: return fallback
	var text := str(value).replace("\n", " ").replace("\t", " ").strip_edges()
	return text.left(limit) if not text.is_empty() else fallback

static func project_from_state(state: Dictionary) -> Dictionary:
	var tycoon: Variant = state.get("tycoon", {})
	if not tycoon is Dictionary: return {}
	var developing: Variant = tycoon.get("developing")
	if developing is Dictionary and not developing.is_empty(): return developing.duplicate(true)
	var history: Variant = tycoon.get("history", [])
	if history is Array:
		for item: Variant in history:
			if item is Dictionary and not item.is_empty(): return item.duplicate(true)
	return {}
