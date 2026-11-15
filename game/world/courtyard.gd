class_name Courtyard
extends Node2D
## The approved campus artwork becomes a bounded, navigable garden visit.
## No office placements or worker entities are moved into this scene.

const BACKGROUND: Texture2D = preload("res://assets/runtime/office/campus-surround.png")
const SPAWN := Vector2(496, 560)
const THEO_POSITION := Vector2(624, 336)
const THEO_APPROACH := Vector2(624, 384)
const BOUNDS := Rect2(96, 96, 800, 544)
var navigation: OfficeNavigation
var guest: StoryGuest
var return_sign: StoryWaypoint
var decoration_bounds: Array[Rect2] = []

func _draw() -> void:
	# Reuse native stone-path pixels from the existing campus. A short path and
	# small meeting terrace make the destination readable without new bitmap art.
	for y: int in range(288, 417, 32):
		for x: int in range(480, 705, 32):
			draw_texture_rect_region(BACKGROUND, Rect2(x, y, 32, 32), Rect2(400, 580, 32, 32))
	for y: int in range(448, 577, 32):
		draw_texture_rect_region(BACKGROUND, Rect2(480, y, 32, 32), Rect2(400, 580, 32, 32))

func _ready() -> void:
	var background := Sprite2D.new()
	background.texture = BACKGROUND
	background.centered = false
	background.z_index = -1000
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	navigation = OfficeNavigation.new()
	navigation.name = "CourtyardNavigation"
	add_child(navigation)
	navigation.configure({"width": 40, "height": 23, "tile_size": 32, "walkable_rects": [[4, 3, 22, 6], [3, 9, 24, 7], [4, 16, 21, 2], [5, 18, 19, 1], [10, 19, 12, 1]]}, Vector2.ZERO)
	var catalogue := OfficeLayout.new()
	catalogue.load_files()
	_add_decoration(catalogue, "cafe_table", Vector2(560, 304))
	_add_decoration(catalogue, "cafe_chair", Vector2(528, 368))
	_add_decoration(catalogue, "cafe_chair", Vector2(592, 368))
	_add_decoration(catalogue, "broadleaf_planter", Vector2(464, 336))
	_add_decoration(catalogue, "broadleaf_planter", Vector2(720, 336))
	navigation.rebuild(decoration_bounds)
	guest = StoryGuest.new()
	guest.name = "TheoVisitor"
	guest.person_id = "theo"
	guest.display_name = "Theo"
	guest.position = THEO_POSITION
	add_child(guest)
	navigation.actors["courtyard-theo"] = THEO_POSITION
	return_sign = StoryWaypoint.new()
	return_sign.name = "ReturnToStudio"
	return_sign.caption = "← Studio"
	return_sign.position = Vector2(496, 608)
	add_child(return_sign)
	set_active(false)

func _add_decoration(catalogue: OfficeLayout, kind: String, anchor: Vector2) -> void:
	var resolved := catalogue.resolve_profile(kind, "south")
	if not resolved.errors.is_empty():
		push_error("Courtyard decoration profile rejected: " + kind)
		return
	var profile: Dictionary = resolved.profile
	var prop := Node2D.new()
	prop.name = kind
	prop.position = anchor
	add_child(prop)
	for layer: Dictionary in profile.render_layers:
		var sprite := Sprite2D.new()
		sprite.texture = load(str(layer.art)) as Texture2D
		sprite.region_enabled = true
		sprite.region_rect = OfficeLayout.rectangle(layer.region)
		sprite.position = Vector2(OfficeLayout.vector(layer.offset))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_as_relative = false
		sprite.z_index = int(anchor.y) + int(layer.z_offset)
		prop.add_child(sprite)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	prop.add_child(body)
	for value: Variant in profile.occupied:
		var offset := Vector2(OfficeLayout.vector(value)) * 32.0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(32, 32)
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = offset
		body.add_child(collision)
		decoration_bounds.append(Rect2(anchor + offset - Vector2(16, 16), Vector2(32, 32)))

func set_active(value: bool) -> void:
	visible = value
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED

func interaction_at(point: Vector2) -> Dictionary:
	if guest.hit(point): return {"id": "courtyard-theo", "kind": "story", "point": THEO_APPROACH}
	if return_sign.hit(point): return {"id": "office-return", "kind": "story", "point": SPAWN}
	return {}
