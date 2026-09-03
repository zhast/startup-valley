class_name PlayerAvatar
extends CharacterBody2D

@export var speed: float = 150.0
var movement_bounds: Rect2 = Rect2(32.0, 56.0, 832.0, 576.0)
var _character_sprite: Sprite2D
var _shadow_sprite: Sprite2D
var _animation_elapsed: float = 0.0
var _facing: StringName = &"front"

func _ready() -> void:
	z_as_relative = false
	_shadow_sprite = Sprite2D.new()
	_shadow_sprite.name = "PixelShadow"
	_shadow_sprite.texture = PolishArt.CHARACTER_SHADOWS
	_shadow_sprite.region_enabled = true
	_shadow_sprite.region_rect = PolishArt.shadow_region(0)
	_shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shadow_sprite.position = Vector2(0.0, -2.0)
	add_child(_shadow_sprite)
	_character_sprite = Sprite2D.new()
	_character_sprite.name = "CharacterSprite"
	_character_sprite.texture = CharacterArt.locomotion_sheet("founder")
	_character_sprite.region_enabled = true
	_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, 0)
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.position = Vector2(0.0, -32.0)
	add_child(_character_sprite)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	position.x = clampf(position.x, movement_bounds.position.x + 14.0, movement_bounds.end.x - 14.0)
	position.y = clampf(position.y, movement_bounds.position.y + 18.0, movement_bounds.end.y - 14.0)
	z_index = int(position.y)
	_animation_elapsed += delta
	if not direction.is_zero_approx():
		_facing = _direction_name(direction)
	var frame := int(_animation_elapsed * 8.0) % 4 + 2 if not direction.is_zero_approx() else int(_animation_elapsed * 1.5) % 2
	_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, frame)
	_shadow_sprite.region_rect = PolishArt.shadow_region(1 if not direction.is_zero_approx() else 0)

func _direction_name(direction: Vector2) -> StringName:
	if absf(direction.x) > absf(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
	return &"front" if direction.y > 0.0 else &"back"
