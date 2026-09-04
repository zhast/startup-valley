class_name CharacterArt
extends RefCounted

const CHARACTER_SHEET: Texture2D = preload("res://assets/concepts/office-town-characters-sheet.png")
const FOUNDER_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/founder-locomotion.png")
const MIRA_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/mira-locomotion.png")
const THEO_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/theo-locomotion.png")
const MIRA_WORK: Texture2D = preload("res://assets/runtime/characters/mira-work.png")
const THEO_WORK: Texture2D = preload("res://assets/runtime/characters/theo-work.png")
const MIRA_SEATED: Texture2D = preload("res://assets/runtime/characters/mira-seated.png")
const THEO_SEATED: Texture2D = preload("res://assets/runtime/characters/theo-seated.png")
const FRAME_SIZE := Vector2(48.0, 80.0)
const CHAT_FACE_REGION := Rect2(8.0, 4.0, 32.0, 32.0)

# The source artwork is intentionally kept as one lossless sheet. Atlas regions let
# the office and UI share the exact same character art without derivative PNGs.
const PORTRAIT_REGIONS: Dictionary = {
	"founder": Rect2(13.0, 76.0, 112.0, 224.0),
	"mira": Rect2(14.0, 372.0, 112.0, 244.0),
	"theo": Rect2(13.0, 676.0, 112.0, 252.0),
}

const WORLD_HEIGHTS: Dictionary = {
	"founder": 68.0,
	"mira": 70.0,
	"theo": 70.0,
}

static func portrait(character_id: String) -> AtlasTexture:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	var texture := AtlasTexture.new()
	texture.atlas = CHARACTER_SHEET
	texture.region = region
	texture.filter_clip = true
	return texture

static func bust_portrait(character_id: String) -> AtlasTexture:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	var texture := AtlasTexture.new()
	texture.atlas = CHARACTER_SHEET
	texture.region = Rect2(region.position, Vector2(region.size.x, region.size.y * 0.68))
	texture.filter_clip = true
	return texture

static func chat_face(character_id: String) -> AtlasTexture:
	# Reuse the front-idle art at its authored pixel size. A native head crop
	# keeps facial features legible without shrinking a large framed bust.
	var texture := AtlasTexture.new()
	texture.atlas = locomotion_sheet(character_id)
	texture.region = CHAT_FACE_REGION
	texture.filter_clip = true
	return texture

static func world_scale(character_id: String) -> float:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	return float(WORLD_HEIGHTS.get(character_id, 64.0)) / region.size.y

static func locomotion_sheet(character_id: String) -> Texture2D:
	match character_id:
		"mira":
			return MIRA_LOCOMOTION
		"theo":
			return THEO_LOCOMOTION
	return FOUNDER_LOCOMOTION

static func work_sheet(character_id: String) -> Texture2D:
	return THEO_WORK if character_id == "theo" else MIRA_WORK

static func seated_sheet(character_id: String) -> Texture2D:
	return THEO_SEATED if character_id == "theo" else MIRA_SEATED

static func locomotion_region(direction: StringName, column: int) -> Rect2:
	var row := 0
	match direction:
		&"back":
			row = 1
		&"left":
			row = 2
		&"right":
			row = 3
	return Rect2(Vector2(float(clampi(column, 0, 5)) * FRAME_SIZE.x, float(row) * FRAME_SIZE.y), FRAME_SIZE)

static func work_region(row: int, column: int) -> Rect2:
	return Rect2(
		Vector2(float(clampi(column, 0, 7)) * FRAME_SIZE.x, float(clampi(row, 0, 3)) * FRAME_SIZE.y),
		FRAME_SIZE
	)
