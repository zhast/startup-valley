class_name OfficeUnlockEffect
extends Sprite2D

const FRAME_RATE := 10.0
var _elapsed: float = 0.0

func _ready() -> void:
	texture = PolishArt.OFFICE_UNLOCK
	region_enabled = true
	region_rect = PolishArt.unlock_region(0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_elapsed += delta
	var frame := mini(5, int(_elapsed * FRAME_RATE))
	region_rect = PolishArt.unlock_region(frame)
	if _elapsed >= 6.0 / FRAME_RATE:
		queue_free()
