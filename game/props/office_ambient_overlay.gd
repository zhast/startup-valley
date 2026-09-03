class_name OfficeAmbientOverlay
extends Sprite2D

var atlas_row: int = 0
var _elapsed: float = 0.0

func configure(row: int, offset: Vector2) -> void:
	atlas_row = row
	position = offset
	texture = PolishArt.AMBIENT_OFFICE
	region_enabled = true
	region_rect = PolishArt.ambient_region(atlas_row, 0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_elapsed += delta
	region_rect = PolishArt.ambient_region(atlas_row, int(_elapsed * 5.0) % 4)
