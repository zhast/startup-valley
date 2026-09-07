class_name PlayerAvatar
extends CharacterBody2D

@export var speed: float = 150.0
var movement_bounds: Rect2 = Rect2(32.0, 56.0, 832.0, 576.0)
var _character_sprite: Sprite2D
var _shadow_sprite: Sprite2D
var _animation_elapsed: float = 0.0
var _facing: StringName = &"front"
signal destination_reached
var navigation: OfficeNavigation
var input_blocked := false
var route := PackedVector2Array()
var _route_revision := -1
var _route_target := Vector2.ZERO
var _stuck_elapsed := 0.0

func move_to(point: Vector2) -> bool:
	if navigation == null or input_blocked:
		return false
	route = navigation.path(position, point, "founder")
	_route_target = point
	_route_revision = navigation.revision
	_stuck_elapsed = 0.0
	return not route.is_empty()

func cancel_route() -> void:
	route.clear()
	if navigation != null:
		navigation.release("founder")

func face_direction(direction: Vector2) -> void:
	# Explicit standing-service arrival may face its surface even when the final
	# path segment was sideways. This changes no feet, route, or source artwork.
	if not direction.is_finite() or direction.is_zero_approx(): return
	_facing = _direction_name(direction)
	_animation_elapsed = 0.0
	if _character_sprite != null:
		_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, 0)

func body_surface_at(point: Vector2) -> Sprite2D:
	# The founder has no click action, but opaque body pixels still hide objects
	# behind them. Shadows and transparent cell padding are not body surfaces.
	return _character_sprite if VisibleSurface.painted(_character_sprite, point) else null

func _ready() -> void:
	collision_mask = 3
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
	if input_blocked:
		velocity = Vector2.ZERO
		return
	if not direction.is_zero_approx():
		cancel_route()
	elif not route.is_empty():
		if navigation != null and navigation.revision != _route_revision:
			move_to(_route_target)
		if not route.is_empty():
			var distance := position.distance_to(route[0])
			if distance <= maxf(2.0, speed * delta):
				position = route[0]
				route.remove_at(0)
				if route.is_empty():
					destination_reached.emit()
			if not route.is_empty():
				direction = position.direction_to(route[0])
	var before := position
	velocity = direction * speed
	move_and_slide()
	var moved := position.distance_to(before) > 0.05
	if not route.is_empty() and not moved:
		_stuck_elapsed += delta
		if _stuck_elapsed > 0.25 and navigation != null and navigation.request_passage("founder", position, route[0]):
			_stuck_elapsed = 0.0
		if _stuck_elapsed > 1.0: cancel_route()
	else:
		_stuck_elapsed = 0.0
	if navigation != null:
		navigation.actors["founder"] = position
	position.x = clampf(position.x, movement_bounds.position.x + 14.0, movement_bounds.end.x - 14.0)
	position.y = clampf(position.y, movement_bounds.position.y + 18.0, movement_bounds.end.y - 14.0)
	z_index = int(position.y)
	_animation_elapsed += delta
	if not direction.is_zero_approx():
		_facing = _direction_name(direction)
	var frame := int(_animation_elapsed * 8.0) % 4 + 2 if moved else int(_animation_elapsed * 1.5) % 2
	_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, frame)
	_character_sprite.position = Vector2(0, -32) + position.round() - position
	_shadow_sprite.position = Vector2(0, -2) + position.round() - position
	_shadow_sprite.region_rect = PolishArt.shadow_region(1 if moved else 0)

func _direction_name(direction: Vector2) -> StringName:
	if absf(direction.x) > absf(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
	return &"front" if direction.y > 0.0 else &"back"
