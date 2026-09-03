class_name CharacterArt
extends RefCounted

const CHARACTER_SHEET: Texture2D = preload("res://assets/concepts/office-town-characters-sheet.png")

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

static func world_scale(character_id: String) -> float:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	return float(WORLD_HEIGHTS.get(character_id, 64.0)) / region.size.y
