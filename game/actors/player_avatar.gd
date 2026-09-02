class_name PlayerAvatar
extends CharacterBody2D

@export var speed: float = 150.0
var movement_bounds: Rect2 = Rect2(32.0, 56.0, 832.0, 576.0)
var _character_sprite: Sprite2D

func _ready() -> void:
	_character_sprite = Sprite2D.new()
	_character_sprite.name = "CharacterSprite"
	_character_sprite.texture = CharacterArt.portrait("founder")
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.scale = Vector2.ONE * CharacterArt.world_scale("founder")
	_character_sprite.position = Vector2(0.0, -10.0)
	add_child(_character_sprite)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	position.x = clampf(position.x, movement_bounds.position.x + 14.0, movement_bounds.end.x - 14.0)
	position.y = clampf(position.y, movement_bounds.position.y + 18.0, movement_bounds.end.y - 14.0)
	if direction.x != 0.0:
		_character_sprite.flip_h = direction.x < 0.0

func _draw() -> void:
	draw_circle(Vector2(0.0, 18.0), 13.0, Color("15151566"))
	draw_string(ThemeDB.fallback_font, Vector2(-30.0, 40.0), "Founder", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 11, Color("f1f1f1"))
