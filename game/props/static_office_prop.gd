class_name StaticOfficeProp
extends Node2D

@export var prop_texture: Texture2D
@export var runtime_scale: float = 0.09
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var collision_size: Vector2 = Vector2(64.0, 24.0)
@export var collision_offset: Vector2 = Vector2(0.0, -12.0)
@export var ambient_row: int = -1
@export var ambient_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_as_relative = false
	var sprite := Sprite2D.new()
	sprite.name = "PropSprite"
	sprite.texture = prop_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * runtime_scale
	sprite.position = sprite_offset
	add_child(sprite)
	if ambient_row >= 0:
		var ambient := OfficeAmbientOverlay.new()
		ambient.name = "AmbientOverlay"
		ambient.configure(ambient_row, ambient_offset)
		add_child(ambient)

	if bool(get_meta("catalog_collision", false)): return
	var body := StaticBody2D.new()
	body.name = "PropCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.position = collision_offset
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
