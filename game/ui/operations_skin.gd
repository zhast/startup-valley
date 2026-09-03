class_name OperationsSkin
extends RefCounted

const JOURNAL_WORK_CARD: Texture2D = preload("res://assets/runtime/ui/operations/journal-work-card.png")
const JOURNAL_APPROVAL_CARD: Texture2D = preload("res://assets/runtime/ui/operations/journal-approval-card.png")
const JOURNAL_DELIVERY_CARD: Texture2D = preload("res://assets/runtime/ui/operations/journal-delivery-card.png")
const TOKEN_METER_FRAME: Texture2D = preload("res://assets/runtime/ui/operations/token-meter-frame.png")
const ACTIVITY_ROW: Texture2D = preload("res://assets/runtime/ui/operations/activity-row.png")

const ACTIVITY_THINKING: Texture2D = preload("res://assets/runtime/ui/operations/activity-thinking.png")
const ACTIVITY_RESEARCH: Texture2D = preload("res://assets/runtime/ui/operations/activity-research.png")
const ACTIVITY_WRITING: Texture2D = preload("res://assets/runtime/ui/operations/activity-writing.png")
const ACTIVITY_TOOL: Texture2D = preload("res://assets/runtime/ui/operations/activity-tool.png")
const ACTIVITY_APPROVAL: Texture2D = preload("res://assets/runtime/ui/operations/activity-approval.png")
const ACTIVITY_ARTIFACT: Texture2D = preload("res://assets/runtime/ui/operations/activity-artifact.png")
const ACTIVITY_COMPLETE: Texture2D = preload("res://assets/runtime/ui/operations/activity-complete.png")
const ACTIVITY_FAILED: Texture2D = preload("res://assets/runtime/ui/operations/activity-failed.png")

const ARTIFACT_READER_FRAME: Texture2D = preload("res://assets/runtime/ui/operations/artifact-reader-frame.png")
const ARTIFACT_PAPER: Texture2D = preload("res://assets/runtime/ui/operations/artifact-paper.png")
const CLOSE_BUTTON: Texture2D = preload("res://assets/runtime/ui/operations/close-button.png")
const FILE_CARD: Texture2D = preload("res://assets/runtime/ui/operations/file-card.png")
const FILE_CARD_SELECTED: Texture2D = preload("res://assets/runtime/ui/operations/file-card-selected.png")
const ICON_DOCUMENT: Texture2D = preload("res://assets/runtime/ui/operations/icon-document.png")
const ICON_FOLDER: Texture2D = preload("res://assets/runtime/ui/operations/icon-folder.png")
const ICON_DELIVERY: Texture2D = preload("res://assets/runtime/ui/operations/icon-delivery.png")
const ICON_EMPTY_TRAY: Texture2D = preload("res://assets/runtime/ui/operations/icon-empty-tray.png")

const SCROLL_V_TRACK: Texture2D = preload("res://assets/runtime/ui/operations/scroll-v-track.png")
const SCROLL_V_THUMB: Texture2D = preload("res://assets/runtime/ui/operations/scroll-v-thumb.png")
const SCROLL_H_TRACK: Texture2D = preload("res://assets/runtime/ui/operations/scroll-h-track.png")
const SCROLL_H_THUMB: Texture2D = preload("res://assets/runtime/ui/operations/scroll-h-thumb.png")
const SCROLL_CORNER: Texture2D = preload("res://assets/runtime/ui/operations/scroll-corner.png")

const BUTTON_SECONDARY_NORMAL: Texture2D = preload("res://assets/runtime/ui/operations/button-secondary-normal.png")
const BUTTON_SECONDARY_HOVER: Texture2D = preload("res://assets/runtime/ui/operations/button-secondary-hover.png")
const BUTTON_SECONDARY_PRESSED: Texture2D = preload("res://assets/runtime/ui/operations/button-secondary-pressed.png")
const BUTTON_SECONDARY_DISABLED: Texture2D = preload("res://assets/runtime/ui/operations/button-secondary-disabled.png")
const BUTTON_PRIMARY_NORMAL: Texture2D = preload("res://assets/runtime/ui/operations/button-primary-normal.png")
const BUTTON_PRIMARY_HOVER: Texture2D = preload("res://assets/runtime/ui/operations/button-primary-hover.png")
const BUTTON_PRIMARY_PRESSED: Texture2D = preload("res://assets/runtime/ui/operations/button-primary-pressed.png")
const DROPDOWN_FIELD: Texture2D = preload("res://assets/runtime/ui/operations/dropdown-field.png")
const DROPDOWN_SELECTED_ROW: Texture2D = preload("res://assets/runtime/ui/operations/dropdown-selected-row.png")
const FOCUS_RING: Texture2D = preload("res://assets/runtime/ui/operations/focus-ring.png")
const ATTENTION_BADGE: Texture2D = preload("res://assets/runtime/ui/operations/attention-badge.png")
const TRANSPARENT: Texture2D = preload("res://assets/runtime/ui/operations/transparent.png")

const CHAT_FOUNDER_BUBBLE: Texture2D = preload("res://assets/runtime/ui/operations/chat-founder-bubble.png")
const CHAT_EMPLOYEE_BUBBLE: Texture2D = preload("res://assets/runtime/ui/operations/chat-employee-bubble.png")
const CHAT_SYSTEM_STRIP: Texture2D = preload("res://assets/runtime/ui/operations/chat-system-strip.png")

const WORLD_SPEECH_BUBBLE: Texture2D = preload("res://assets/runtime/ui/operations/world-speech-bubble.png")
const WORLD_NAMEPLATE: Texture2D = preload("res://assets/runtime/ui/operations/world-nameplate.png")
const WORLD_STATUS_PLAQUE: Texture2D = preload("res://assets/runtime/ui/operations/world-status-plaque.png")
const WORLD_ATTENTION: Texture2D = preload("res://assets/runtime/ui/operations/world-attention.png")
const WORLD_AVAILABLE: Texture2D = preload("res://assets/runtime/ui/operations/world-available.png")

const ACTIVITY_ICON_PATHS: Dictionary = {
	"thinking": "res://assets/runtime/ui/operations/activity-thinking.png",
	"research": "res://assets/runtime/ui/operations/activity-research.png",
	"writing": "res://assets/runtime/ui/operations/activity-writing.png",
	"tool": "res://assets/runtime/ui/operations/activity-tool.png",
	"approval": "res://assets/runtime/ui/operations/activity-approval.png",
	"artifact": "res://assets/runtime/ui/operations/activity-artifact.png",
	"complete": "res://assets/runtime/ui/operations/activity-complete.png",
	"failed": "res://assets/runtime/ui/operations/activity-failed.png",
}

static func journal_work_card() -> StyleBoxTexture:
	return _style(JOURNAL_WORK_CARD, Vector4(18.0, 18.0, 18.0, 14.0), Vector4(14.0, 17.0, 14.0, 10.0))

static func journal_approval_card() -> StyleBoxTexture:
	return _style(JOURNAL_APPROVAL_CARD, Vector4(18.0, 20.0, 18.0, 15.0), Vector4(13.0, 23.0, 13.0, 10.0))

static func journal_delivery_card() -> StyleBoxTexture:
	return _style(JOURNAL_DELIVERY_CARD, Vector4(31.0, 15.0, 16.0, 14.0), Vector4(32.0, 12.0, 12.0, 9.0))

static func token_meter() -> StyleBoxTexture:
	return _style(TOKEN_METER_FRAME, Vector4(18.0, 10.0, 18.0, 10.0), Vector4(14.0, 8.0, 14.0, 8.0))

static func activity_log() -> StyleBoxTexture:
	return _style(ACTIVITY_ROW, Vector4(13.0, 10.0, 13.0, 10.0), Vector4(12.0, 10.0, 12.0, 10.0))

static func artifact_paper() -> StyleBoxTexture:
	return _style(ARTIFACT_PAPER, Vector4(12.0, 12.0, 12.0, 12.0), Vector4(14.0, 12.0, 14.0, 12.0))

static func file_card(selected: bool = false) -> StyleBoxTexture:
	var texture_value := FILE_CARD_SELECTED if selected else FILE_CARD
	return _style(texture_value, Vector4(16.0, 14.0, 16.0, 14.0), Vector4(14.0, 9.0, 14.0, 9.0))

static func secondary_button(state: String = "normal") -> StyleBoxTexture:
	var texture_value := BUTTON_SECONDARY_NORMAL
	if state == "hover":
		texture_value = BUTTON_SECONDARY_HOVER
	elif state == "pressed":
		texture_value = BUTTON_SECONDARY_PRESSED
	elif state == "disabled":
		texture_value = BUTTON_SECONDARY_DISABLED
	return _style(texture_value, Vector4(14.0, 11.0, 14.0, 11.0), Vector4(12.0, 8.0, 12.0, 8.0))

static func primary_button(state: String = "normal") -> StyleBoxTexture:
	var texture_value := BUTTON_PRIMARY_NORMAL
	if state == "hover":
		texture_value = BUTTON_PRIMARY_HOVER
	elif state == "pressed":
		texture_value = BUTTON_PRIMARY_PRESSED
	return _style(texture_value, Vector4(14.0, 10.0, 14.0, 10.0), Vector4(14.0, 8.0, 14.0, 8.0))

static func dropdown() -> StyleBoxTexture:
	return _style(DROPDOWN_FIELD, Vector4(14.0, 10.0, 38.0, 10.0), Vector4(13.0, 8.0, 38.0, 8.0))

static func dropdown_selected_row() -> StyleBoxTexture:
	return _style(DROPDOWN_SELECTED_ROW, Vector4(14.0, 10.0, 14.0, 10.0), Vector4(12.0, 8.0, 12.0, 8.0))

static func focus_ring() -> StyleBoxTexture:
	return _style(FOCUS_RING, Vector4(11.0, 9.0, 11.0, 9.0), Vector4.ZERO, false)

static func chat_bubble(sender: String) -> StyleBoxTexture:
	if sender == "employee":
		return _style(CHAT_EMPLOYEE_BUBBLE, Vector4(34.0, 13.0, 17.0, 13.0), Vector4(35.0, 10.0, 12.0, 10.0))
	return _style(CHAT_FOUNDER_BUBBLE, Vector4(17.0, 13.0, 34.0, 13.0), Vector4(12.0, 10.0, 35.0, 10.0))

static func chat_system_strip() -> StyleBoxTexture:
	return _style(CHAT_SYSTEM_STRIP, Vector4(13.0, 10.0, 13.0, 10.0), Vector4(14.0, 7.0, 14.0, 7.0))

static func vertical_scroll_track() -> StyleBoxTexture:
	return _style(SCROLL_V_TRACK, Vector4(6.0, 14.0, 6.0, 14.0), Vector4.ZERO)

static func vertical_scroll_thumb() -> StyleBoxTexture:
	return _style(SCROLL_V_THUMB, Vector4(5.0, 10.0, 5.0, 10.0), Vector4.ZERO)

static func horizontal_scroll_track() -> StyleBoxTexture:
	return _style(SCROLL_H_TRACK, Vector4(14.0, 6.0, 14.0, 6.0), Vector4.ZERO)

static func horizontal_scroll_thumb() -> StyleBoxTexture:
	return _style(SCROLL_H_THUMB, Vector4(10.0, 5.0, 10.0, 5.0), Vector4.ZERO)

static func activity_icon_path(event_type: StringName, tool: String = "", ok: bool = true) -> String:
	match event_type:
		&"agent.thinking":
			return str(ACTIVITY_ICON_PATHS["thinking"])
		&"tool.started":
			if tool == "web_search" or tool == "web_fetch":
				return str(ACTIVITY_ICON_PATHS["research"])
			if tool == "write_file" or tool == "edit_file":
				return str(ACTIVITY_ICON_PATHS["writing"])
			return str(ACTIVITY_ICON_PATHS["tool"])
		&"tool.completed":
			return str(ACTIVITY_ICON_PATHS["complete"] if ok else ACTIVITY_ICON_PATHS["failed"])
		&"approval.required":
			return str(ACTIVITY_ICON_PATHS["approval"])
		&"artifact.created":
			return str(ACTIVITY_ICON_PATHS["artifact"])
		&"job.completed":
			return str(ACTIVITY_ICON_PATHS["complete"])
		&"job.blocked", &"job.failed":
			return str(ACTIVITY_ICON_PATHS["failed"])
	return str(ACTIVITY_ICON_PATHS["tool"])

static func style_scroll_container(scroll: ScrollContainer) -> void:
	_style_vertical_scrollbar(scroll.get_v_scroll_bar())
	_style_horizontal_scrollbar(scroll.get_h_scroll_bar())

static func style_rich_text_scrollbar(label: RichTextLabel) -> void:
	_style_vertical_scrollbar(label.get_v_scroll_bar())

static func style_text_edit_scrollbar(editor: TextEdit) -> void:
	_style_vertical_scrollbar(editor.get_v_scroll_bar())
	_style_horizontal_scrollbar(editor.get_h_scroll_bar())

static func _style_vertical_scrollbar(scrollbar: VScrollBar) -> void:
	scrollbar.custom_minimum_size.x = 15.0
	scrollbar.add_theme_stylebox_override("scroll", vertical_scroll_track())
	scrollbar.add_theme_stylebox_override("grabber", vertical_scroll_thumb())
	scrollbar.add_theme_stylebox_override("grabber_highlight", vertical_scroll_thumb())
	scrollbar.add_theme_stylebox_override("grabber_pressed", vertical_scroll_thumb())
	_hide_scrollbar_arrows(scrollbar)

static func _style_horizontal_scrollbar(scrollbar: HScrollBar) -> void:
	scrollbar.custom_minimum_size.y = 14.0
	scrollbar.add_theme_stylebox_override("scroll", horizontal_scroll_track())
	scrollbar.add_theme_stylebox_override("grabber", horizontal_scroll_thumb())
	scrollbar.add_theme_stylebox_override("grabber_highlight", horizontal_scroll_thumb())
	scrollbar.add_theme_stylebox_override("grabber_pressed", horizontal_scroll_thumb())
	_hide_scrollbar_arrows(scrollbar)

static func _hide_scrollbar_arrows(scrollbar: ScrollBar) -> void:
	for icon_name: String in ["decrement", "decrement_highlight", "decrement_pressed", "increment", "increment_highlight", "increment_pressed"]:
		scrollbar.add_theme_icon_override(icon_name, TRANSPARENT)

static func _style(
	texture_value: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4,
	draw_center: bool = true,
	modulate: Color = Color.WHITE
) -> StyleBoxTexture:
	return NotebookSkin.texture_style(texture_value, texture_margins, content_margins, draw_center, modulate)
