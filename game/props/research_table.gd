class_name ResearchTable
extends Node2D

const SPRITE_OFFSET := Vector2(0.0, -40.0)

func _ready() -> void:
	z_as_relative = false
	var rear := _furniture_layer("ResearchBenchRear", 0)
	rear.z_as_relative = false
	rear.z_index = z_index - 40
	add_child(rear)
	var front := _furniture_layer("ResearchBenchFront", 1)
	front.z_as_relative = false
	front.z_index = z_index + 1
	add_child(front)
	var ambient := OfficeAmbientOverlay.new()
	ambient.name = "ResearchScan"
	ambient.configure(2, Vector2(0.0, -62.0))
	ambient.z_as_relative = false
	ambient.z_index = z_index + 2
	add_child(ambient)
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

func _furniture_layer(node_name: String, column: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = PolishArt.LAYERED_FURNITURE
	sprite.region_enabled = true
	sprite.region_rect = PolishArt.furniture_region(1, column)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = SPRITE_OFFSET
	return sprite
