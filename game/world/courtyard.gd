class_name Courtyard
extends Node2D
## A bounded shared neighborhood yard, using the office's native terrain cells.
## No office placements or worker entities are moved into this scene.

const LAYOUT_PATH := "res://data/courtyard_layout.json"
const SPAWN := Vector2(496, 560)
const THEO_POSITION := Vector2(624, 336)
const THEO_APPROACH := Vector2(624, 384)
const BOUNDS := Rect2(96, 96, 800, 544)
var navigation: OfficeNavigation
var guest: StoryGuest
var return_sign: StoryWaypoint
var decoration_bounds: Array[Rect2] = []
var terrain: VillageTerrain

func _ready() -> void:
	var data: Dictionary = OfficeLayout._read_json(LAYOUT_PATH)
	terrain = VillageTerrain.new()
	add_child(terrain)
	terrain.configure(data)
	navigation = OfficeNavigation.new()
	navigation.name = "CourtyardNavigation"
	add_child(navigation)
	navigation.configure(data, Vector2.ZERO)
	var catalogue := OfficeLayout.new()
	catalogue.load_files()
	for prop: Dictionary in data.props:
		_add_decoration(catalogue, str(prop.kind), (Vector2(OfficeLayout.vector(prop.grid)) + Vector2(0.5, 0.5)) * 32)
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
