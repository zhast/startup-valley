extends Node2D
## DEV-ONLY geometry study. No production profile, collision, or pose registry.
## Texture inputs are native material tiles, never finished prop renders.
## Caller must place its background below Rear (-1 relative to this node), and
## place the body reference between Rear/Front. The showroom uses bg z=-100.

const DIRECTIONS: Array[String] = ["north", "east", "south", "west"]
const INK := Color("282622")
const LEG := Color("383833")
const LEG_LIGHT := Color("53524a")
const WOOD := Color("a87742")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const SHADE := Color("583d28")

var facing := "south"
var resolved: Dictionary = {}
var rear: Node2D
var front: Node2D
var material_ready := false

class GeometryLayer extends Node2D:

	var parts: Array = []
	var top := Rect2i()
	var top_tile: Texture2D

	func _draw() -> void:
		for part: Dictionary in parts:
			draw_rect(Rect2(part.rect), part.color)
		if top.has_area():
			draw_rect(Rect2(top), INK)
			var interior := Rect2(top.grow(-2))
			if top_tile != null:
				draw_texture_rect(top_tile, interior, true)
			else:
				draw_rect(interior, WOOD)
			# Fixed screen-space lighting: top/left highlights, bottom/right shade.
			draw_rect(Rect2(top.position + Vector2i(1, 1), Vector2i(top.size.x - 2, 1)), LIGHT)
			draw_rect(Rect2(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), LIGHT)
			draw_rect(Rect2(top.position + Vector2i(2, top.size.y - 2), Vector2i(top.size.x - 3, 1)), SHADE)
			draw_rect(Rect2(top.position + Vector2i(top.size.x - 2, 2), Vector2i(1, top.size.y - 3)), SHADE)

static func piece(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

static func profile(direction: String) -> Dictionary:
	# These are independently specified camera-space constructions. Nothing is
	# obtained by rotating a rendered image, layer node, or drawing transform.
	match direction:
		"north":
			return {
				"facing": direction, "top": Rect2i(-48, -48, 96, 32),
				"floor": Rect2i(-48, -16, 96, 32), "contact_y": 16,
				"work_gaze": Vector2i.UP, "seat_reference": Vector2i(0, 24), "top_layer": "rear",
				"material_axis": "horizontal",
				"rear": [piece(Rect2i(-44, -46, 6, 30), LEG), piece(Rect2i(38, -46, 6, 30), LEG)],
				"front": [piece(Rect2i(-44, -14, 6, 30), INK), piece(Rect2i(38, -14, 6, 30), INK),
					piece(Rect2i(-43, -12, 2, 26), LEG_LIGHT), piece(Rect2i(39, -12, 2, 26), LEG_LIGHT),
					piece(Rect2i(-48, -16, 96, 4), EDGE), piece(Rect2i(-46, -15, 92, 1), LIGHT)],
			}
		"east":
			return {
				"facing": direction, "top": Rect2i(-16, -80, 32, 96),
				"floor": Rect2i(-16, -48, 32, 96), "contact_y": 48,
				"work_gaze": Vector2i.RIGHT, "seat_reference": Vector2i(-24, 0), "top_layer": "rear",
				"material_axis": "vertical",
				"rear": [piece(Rect2i(-12, -78, 6, 30), LEG), piece(Rect2i(6, -78, 6, 30), LEG)],
				"front": [piece(Rect2i(-12, 18, 6, 30), INK), piece(Rect2i(6, 18, 6, 30), INK),
					piece(Rect2i(-11, 20, 2, 26), LEG_LIGHT), piece(Rect2i(7, 20, 2, 26), LEG_LIGHT),
					piece(Rect2i(-16, 16, 32, 6), EDGE), piece(Rect2i(-14, 17, 28, 1), LIGHT),
					piece(Rect2i(12, -76, 3, 92), SHADE)],
			}
		"south":
			return {
				"facing": direction, "top": Rect2i(-48, -48, 96, 32),
				"floor": Rect2i(-48, -16, 96, 32), "contact_y": 16,
				"work_gaze": Vector2i.DOWN, "seat_reference": Vector2i(0, -8), "top_layer": "front",
				"material_axis": "horizontal",
				"rear": [piece(Rect2i(-44, -46, 6, 30), LEG), piece(Rect2i(38, -46, 6, 30), LEG)],
				"front": [piece(Rect2i(-44, -14, 6, 30), INK), piece(Rect2i(38, -14, 6, 30), INK),
					piece(Rect2i(-43, -12, 2, 26), LEG_LIGHT), piece(Rect2i(39, -12, 2, 26), LEG_LIGHT),
					piece(Rect2i(-48, -16, 96, 10), EDGE), piece(Rect2i(-46, -15, 92, 1), LIGHT),
					piece(Rect2i(-44, -8, 88, 1), SHADE)],
			}
		"west":
			return {
				"facing": direction, "top": Rect2i(-16, -80, 32, 96),
				"floor": Rect2i(-16, -48, 32, 96), "contact_y": 48,
				"work_gaze": Vector2i.LEFT, "seat_reference": Vector2i(24, 0), "top_layer": "rear",
				"material_axis": "vertical",
				"rear": [piece(Rect2i(-12, -78, 6, 30), LEG), piece(Rect2i(6, -78, 6, 30), LEG)],
				"front": [piece(Rect2i(-12, 18, 6, 30), INK), piece(Rect2i(6, 18, 6, 30), INK),
					piece(Rect2i(-11, 20, 2, 26), LEG_LIGHT), piece(Rect2i(7, 20, 2, 26), LEG_LIGHT),
					piece(Rect2i(-16, 16, 32, 6), EDGE), piece(Rect2i(-14, 17, 28, 1), LIGHT),
					piece(Rect2i(-15, -76, 3, 92), LIGHT)],
			}
	return {}

func configure(direction: String, horizontal_tile: Texture2D = null, vertical_tile: Texture2D = null) -> bool:
	var next := profile(direction)
	if next.is_empty():
		return false
	for material: Texture2D in [horizontal_tile, vertical_tile]:
		if material != null and material.get_size() != Vector2(32, 32):
			return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	facing = direction
	resolved = next
	material_ready = horizontal_tile != null and vertical_tile != null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	rotation = 0.0
	for layer_name: String in ["rear", "front"]:
		var layer := GeometryLayer.new()
		layer.name = layer_name.capitalize()
		layer.parts = next[layer_name].duplicate(true)
		layer.z_index = -1 if layer_name == "rear" else 1
		if layer_name == next.top_layer:
			layer.top = next.top
			layer.top_tile = horizontal_tile if next.material_axis == "horizontal" else vertical_tile
		add_child(layer)
		if layer_name == "rear": rear = layer
		else: front = layer
	return true
