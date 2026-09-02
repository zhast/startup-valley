class_name OfficeDesk
extends Node2D

const WORKSTATION_TEXTURE: Texture2D = preload("res://assets/runtime/office/employee-workstation.png")
const RUNTIME_SCALE := 0.085
const SPRITE_OFFSET := Vector2(0.0, -31.5)

var owner_name: String = "Desk"

func configure(label: String) -> void:
	owner_name = label

func _ready() -> void:
	z_as_relative = false
	var sprite := Sprite2D.new()
	sprite.name = "WorkstationSprite"
	sprite.texture = WORKSTATION_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * RUNTIME_SCALE
	sprite.position = SPRITE_OFFSET
	add_child(sprite)
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
