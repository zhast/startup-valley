class_name ResearchTable
extends Node2D

const RESEARCH_TEXTURE: Texture2D = preload("res://assets/runtime/office/research-bench.png")
const RUNTIME_SCALE := 0.09
const SPRITE_OFFSET := Vector2(0.0, -37.0)

func _ready() -> void:
	z_as_relative = false
	var sprite := Sprite2D.new()
	sprite.name = "ResearchBenchSprite"
	sprite.texture = RESEARCH_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * RUNTIME_SCALE
	sprite.position = SPRITE_OFFSET
	add_child(sprite)
	var body := StaticBody2D.new()
	body.name = "ResearchCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(94.0, 34.0)
	collision.position = Vector2(0.0, -17.0)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
