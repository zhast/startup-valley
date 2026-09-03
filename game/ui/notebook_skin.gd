class_name NotebookSkin
extends RefCounted

const WOOD_FILL: Texture2D = preload("res://assets/runtime/ui/notebook/wood-fill.png")
const OUTER_FRAME: Texture2D = preload("res://assets/runtime/ui/notebook/outer-frame.png")
const PARCHMENT_PANEL: Texture2D = preload("res://assets/runtime/ui/notebook/parchment-panel.png")
const NOTEBOOK_PAGE: Texture2D = preload("res://assets/runtime/ui/notebook/notebook-page.png")
const TAB_WOOD: Texture2D = preload("res://assets/runtime/ui/notebook/tab-wood.png")
const TAB_VERMILION: Texture2D = preload("res://assets/runtime/ui/notebook/tab-vermilion.png")
const BUTTON_INDIGO: Texture2D = preload("res://assets/runtime/ui/notebook/button-indigo.png")
const INPUT_FRAME: Texture2D = preload("res://assets/runtime/ui/notebook/input-frame.png")
const PORTRAIT_FRAME: Texture2D = preload("res://assets/runtime/ui/notebook/portrait-frame.png")
const CONTENT_FRAME: Texture2D = preload("res://assets/runtime/ui/notebook/content-frame.png")
const NAME_PLAQUE: Texture2D = preload("res://assets/runtime/ui/notebook/name-plaque.png")

static func wood_surface(content: Vector4 = Vector4(10.0, 10.0, 10.0, 10.0)) -> StyleBoxTexture:
	return texture_style(WOOD_FILL, Vector4(5.0, 5.0, 5.0, 5.0), content)

static func parchment(content: Vector4 = Vector4(12.0, 10.0, 12.0, 10.0)) -> StyleBoxTexture:
	return texture_style(PARCHMENT_PANEL, Vector4(10.0, 10.0, 10.0, 10.0), content)

static func notebook(content: Vector4 = Vector4(18.0, 12.0, 10.0, 12.0)) -> StyleBoxTexture:
	return texture_style(NOTEBOOK_PAGE, Vector4(17.0, 10.0, 9.0, 10.0), content)

static func wood_tab() -> StyleBoxTexture:
	return texture_style(TAB_WOOD, Vector4(10.0, 9.0, 10.0, 9.0), Vector4(7.0, 7.0, 7.0, 7.0))

static func selected_tab() -> StyleBoxTexture:
	return texture_style(TAB_VERMILION, Vector4(10.0, 9.0, 10.0, 9.0), Vector4(7.0, 7.0, 7.0, 7.0))

static func indigo_button() -> StyleBoxTexture:
	return texture_style(BUTTON_INDIGO, Vector4(13.0, 10.0, 13.0, 10.0), Vector4(14.0, 8.0, 14.0, 8.0))

static func input_field() -> StyleBoxTexture:
	return texture_style(INPUT_FRAME, Vector4(11.0, 9.0, 11.0, 9.0), Vector4(12.0, 9.0, 12.0, 9.0))

static func portrait_frame() -> StyleBoxTexture:
	return texture_style(PORTRAIT_FRAME, Vector4(9.0, 9.0, 9.0, 9.0), Vector4(9.0, 9.0, 9.0, 9.0), false)

static func content_frame() -> StyleBoxTexture:
	return texture_style(CONTENT_FRAME, Vector4(13.0, 11.0, 13.0, 11.0), Vector4(14.0, 10.0, 14.0, 10.0))

static func name_plaque() -> StyleBoxTexture:
	return texture_style(NAME_PLAQUE, Vector4(8.0, 7.0, 8.0, 7.0), Vector4(8.0, 5.0, 8.0, 5.0))

static func texture_style(
	texture_value: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4,
	draw_center: bool = true,
	modulate: Color = Color.WHITE
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture_value
	style.draw_center = draw_center
	style.modulate_color = modulate
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style
