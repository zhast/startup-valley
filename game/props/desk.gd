class_name OfficeDesk
extends Node2D

const SPRITE_OFFSET := Vector2(0.0, -40.0)

var owner_name: String = "Desk"

func configure(label: String) -> void:
	owner_name = label

func _ready() -> void:
	z_as_relative = false
	var rear := _furniture_layer("WorkstationRear", 0)
	rear.z_as_relative = false
	rear.z_index = z_index - 40
	add_child(rear)
	var front := _furniture_layer("WorkstationFront", 1)
	front.z_as_relative = false
	front.z_index = z_index + 1
	add_child(front)
	var ambient := OfficeAmbientOverlay.new()
	ambient.name = "MonitorActivity"
	ambient.configure(1, Vector2(-8.0, -70.0))
	ambient.z_as_relative = false
	ambient.z_index = z_index + 2
	add_child(ambient)
	var body := StaticBody2D.new()
	body.name = "DeskCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(94.0, 34.0)
	collision.position = Vector2(0.0, -19.0)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _furniture_layer(node_name: String, column: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = PolishArt.LAYERED_FURNITURE
	sprite.region_enabled = true
	sprite.region_rect = PolishArt.furniture_region(0, column)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = SPRITE_OFFSET
	return sprite
