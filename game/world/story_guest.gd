class_name StoryGuest
extends Node2D
## A story visitor, never a hired-worker projection or a second simulation.

var person_id := "mira"
var display_name := "Mina"
var sprite: Sprite2D
var _elapsed := 0.0
const NAMEPLATE := Rect2(-48, -96, 96, 28)
const BODY := Rect2(-24, -72, 48, 80)

func _ready() -> void:
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shadow := Sprite2D.new()
	shadow.texture = PolishArt.CHARACTER_SHADOWS
	shadow.region_enabled = true
	shadow.region_rect = PolishArt.shadow_region(0)
	shadow.position = Vector2(0, -2)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.texture = CharacterArt.locomotion_sheet(person_id)
	sprite.region_enabled = true
	sprite.region_rect = CharacterArt.locomotion_region(&"front", 0)
	sprite.position = Vector2(0, -32)
	add_child(sprite)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	sprite.region_rect = CharacterArt.locomotion_region(&"front", IdleBlink.frame(_elapsed, person_id))
	z_index = roundi(position.y)

func _draw() -> void:
	draw_style_box(CozyUI.paper(), NAMEPLATE)
	draw_string(GameFonts.BOLD, Vector2(-44, -77), display_name, HORIZONTAL_ALIGNMENT_CENTER, 88, 16, CozyUI.INK)

func hit(point: Vector2) -> bool:
	return is_visible_in_tree() and (VisibleSurface.painted(sprite, point) or (global_transform * NAMEPLATE).has_point(point))

func painted_bounds() -> Rect2:
	return global_transform * NAMEPLATE.merge(BODY)

func set_active(value: bool) -> void:
	visible = value
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
