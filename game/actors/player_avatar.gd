class_name PlayerAvatar
extends CharacterBody2D

@export var speed: float = 150.0
var movement_bounds: Rect2 = Rect2(32.0, 56.0, 832.0, 576.0)

func _ready() -> void:
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	position.x = clampf(position.x, movement_bounds.position.x + 14.0, movement_bounds.end.x - 14.0)
	position.y = clampf(position.y, movement_bounds.position.y + 18.0, movement_bounds.end.y - 14.0)

func _draw() -> void:
	draw_circle(Vector2(0.0, -7.0), 9.0, Color("f4c9a8"))
	draw_rect(Rect2(-10.0, 1.0, 20.0, 23.0), Color("5a7fd6"), true)
	draw_rect(Rect2(-11.0, -17.0, 22.0, 7.0), Color("25324a"), true)
	draw_circle(Vector2(-3.0, -8.0), 1.2, Color("172033"))
	draw_circle(Vector2(3.0, -8.0), 1.2, Color("172033"))
	draw_string(ThemeDB.fallback_font, Vector2(-18.0, 39.0), "You", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 12, Color("e8eefc"))
