class_name StaticOfficeProp
extends Node2D

@export var prop_texture: Texture2D
@export var runtime_scale: float = 0.09
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var collision_size: Vector2 = Vector2(64.0, 24.0)
@export var collision_offset: Vector2 = Vector2(0.0, -12.0)
@export var chroma_key_enabled: bool = false
@export var chroma_key_color: Color = Color(1.0, 0.0, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var chroma_tolerance: float = 0.24

const CHROMA_SHADER: Shader = preload("res://props/chroma_key.gdshader")

func _ready() -> void:
	z_as_relative = false
	var sprite := Sprite2D.new()
	sprite.name = "PropSprite"
	sprite.texture = prop_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * runtime_scale
	sprite.position = sprite_offset
	if chroma_key_enabled:
		var material := ShaderMaterial.new()
		material.shader = CHROMA_SHADER
		material.set_shader_parameter("key_color", Vector3(chroma_key_color.r, chroma_key_color.g, chroma_key_color.b))
		material.set_shader_parameter("tolerance", chroma_tolerance)
		sprite.material = material
	add_child(sprite)

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
