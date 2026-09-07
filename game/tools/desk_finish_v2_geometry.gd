extends "res://tools/modular_desk_geometry.gd"
## Isolated finish study: unchanged v1 geometry, material pixels and alpha masks.
const BASE := preload("res://tools/modular_desk_geometry.gd")
const METAL_FACE := Color("44443e")
const METAL_EDGE := Color("53524a")
const METAL_DARK := Color("282622")

static func finish_parts(direction: String, layer_name: String) -> Array[Dictionary]:
	var original: Dictionary = BASE.profile(direction)
	var result: Array[Dictionary] = []
	if original.is_empty() or layer_name not in ["rear", "front"]: return result
	var apron := Rect2i(-48, -16, 96, 4 if direction == "north" else 10)
	if direction in ["east", "west"]: apron = Rect2i(-16, 16, 32, 6)
	for part: Dictionary in original[layer_name]:
		var rect: Rect2i = part.rect
		if rect.size != Vector2i(6, 30): continue
		# The original apron occludes the tops of the near legs. Do not paint
		# metal through that wood just because both belong to the Front layer.
		if layer_name == "front":
			rect = Rect2i(rect.position.x, apron.end.y, rect.size.x, rect.end.y - apron.end.y)
		# An inset face, short joint and rubber foot stay inside the same leg.
		result.append(BASE.piece(Rect2i(rect.position + Vector2i(1, 1), Vector2i(4, rect.size.y - 2)), METAL_FACE))
		result.append(BASE.piece(Rect2i(rect.position + Vector2i(1, 4), Vector2i(1, rect.size.y - 8)), METAL_EDGE))
		result.append(BASE.piece(Rect2i(rect.position + Vector2i(1, 2), Vector2i(4, 2)), METAL_DARK))
		result.append(BASE.piece(Rect2i(rect.position + Vector2i(1, 2), Vector2i(1, 1)), METAL_EDGE))
		result.append(BASE.piece(Rect2i(rect.position + Vector2i(1, rect.size.y - 3), Vector2i(4, 2)), METAL_DARK))
	if layer_name == "front":
		# One interior seam, not a new drawer or protruding hardware.
		result.append(BASE.piece(Rect2i(apron.position + Vector2i(2, 2), Vector2i(apron.size.x - 4, 1)), BASE.SHADE))
	return result

func configure(direction: String, horizontal_tile: Texture2D = null, vertical_tile: Texture2D = null) -> bool:
	if not super.configure(direction, horizontal_tile, vertical_tile): return false
	for layer_name: String in ["rear", "front"]:
		var node: Node2D = rear if layer_name == "rear" else front
		node.parts.append_array(finish_parts(direction, layer_name))
		node.queue_redraw()
	return true
