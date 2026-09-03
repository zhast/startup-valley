class_name EmployeeAvatar
extends Node2D

enum WorkState {
	IDLE,
	IDLE_WALKING,
	SITTING,
	WANDERING,
	LUNCH,
	OFF_SHIFT,
	WALKING_TO_DESK,
	WORKING,
	TYPING,
	WALKING_TO_RESEARCH,
	WAITING_APPROVAL,
	DELIVERING,
}

@export var walk_speed: float = 110.0
var employee_id: String = ""
var display_name: String = "Worker"
var morale: int = 50
var home_position: Vector2 = Vector2.ZERO
var desk_position: Vector2 = Vector2.ZERO
var research_position: Vector2 = Vector2.ZERO
var delivery_position: Vector2 = Vector2.ZERO
var work_state: WorkState = WorkState.IDLE
var schedule_phase: String = "work"
var has_live_job: bool = false
var memory_line: String = ""
var _target_position: Vector2 = Vector2.ZERO
var _arrival_state: WorkState = WorkState.IDLE
var _has_target: bool = false
var _animation_elapsed: float = 0.0
var _idle_elapsed: float = 0.0
var _idle_cooldown: float = 0.5
var _idle_cycle: int = 0
var _speech_visible: bool = false
var _speech_suppressed: bool = false
var _character_sprite: Sprite2D
var _shadow_sprite: Sprite2D
var _effect_sprite: Sprite2D
var _facing: StringName = &"front"
var _activity: StringName = &""
var _effect_elapsed: float = 0.0
var _effect_duration: float = -1.0
var _label_hold: float = 1.2
var _interaction_highlighted: bool = false
var _status_override: String = ""

func configure(record: EmployeeRecord, start_position: Vector2, desk: Vector2, research: Vector2) -> void:
	z_as_relative = false
	employee_id = record.id
	display_name = record.display_name
	morale = record.morale
	memory_line = record.memory_line
	position = start_position
	home_position = start_position
	desk_position = desk
	research_position = research
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
	_character_sprite.texture = CharacterArt.locomotion_sheet(employee_id)
	_character_sprite.region_enabled = true
	_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, 0)
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.position = Vector2(0.0, -32.0)
	add_child(_character_sprite)
	_effect_sprite = Sprite2D.new()
	_effect_sprite.name = "WorkerEventEffect"
	_effect_sprite.texture = PolishArt.WORLD_VFX
	_effect_sprite.region_enabled = true
	_effect_sprite.region_rect = PolishArt.effect_region(&"thinking", 0)
	_effect_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_effect_sprite.position = Vector2(0.0, -78.0)
	_effect_sprite.visible = false
	add_child(_effect_sprite)
	queue_redraw()

func set_schedule_phase(phase: String) -> void:
	var phase_changed := phase != schedule_phase
	schedule_phase = phase
	if has_live_job or work_state == WorkState.DELIVERING:
		return
	if not phase_changed:
		if phase == "work":
			return
		if phase == "lunch" and work_state == WorkState.LUNCH:
			return
		if phase == "off" and work_state == WorkState.OFF_SHIFT:
			return
	_idle_elapsed = 0.0
	_speech_visible = false
	_activity = &""
	_hold_label()
	if phase == "lunch":
		walk_to(research_position, WorkState.LUNCH, WorkState.LUNCH)
	elif phase == "off":
		walk_to(home_position, WorkState.OFF_SHIFT, WorkState.OFF_SHIFT)
	else:
		work_state = WorkState.IDLE
		_has_target = false
		_idle_cooldown = 0.5
		queue_redraw()

func apply_worker_event(event: WorkerEventRecord, player_position: Vector2) -> void:
	match event.type:
		&"job.started":
			has_live_job = true
			_speech_visible = false
			_set_activity(&"thinking")
			walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.WORKING)
		&"agent.thinking":
			_set_activity(&"thinking")
			if work_state == WorkState.IDLE or work_state == WorkState.SITTING or work_state == WorkState.WANDERING:
				walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.WORKING)
		&"tool.started":
			if event.tool == "web_search" or event.tool == "web_fetch":
				_set_activity(&"research")
				walk_to(research_position, WorkState.WALKING_TO_RESEARCH, WorkState.WORKING)
			elif event.tool == "write_file" or event.tool == "edit_file":
				_set_activity(&"typing")
				if position.distance_to(desk_position) > 4.0:
					walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.TYPING)
				else:
					work_state = WorkState.TYPING
					_hold_label()
					queue_redraw()
			else:
				_set_activity(&"thinking")
				work_state = WorkState.WORKING
				queue_redraw()
		&"tool.completed":
			_set_activity(&"thinking")
			work_state = WorkState.WORKING
			queue_redraw()
		&"approval.required":
			_set_activity(&"approval")
			walk_to(player_position + Vector2(34.0, 0.0), WorkState.WAITING_APPROVAL, WorkState.WAITING_APPROVAL)
		&"job.completed":
			has_live_job = false
			_set_activity(&"completion", 1.2)
			delivery_position = player_position + Vector2(38.0, 8.0)
			walk_to(delivery_position, WorkState.DELIVERING, WorkState.IDLE)
		&"job.blocked", &"job.failed":
			has_live_job = false
			_set_activity(&"failure", 1.2)
			_status_override = "work stopped"
			work_state = WorkState.IDLE
			_has_target = false
			_idle_elapsed = 0.0
			_idle_cooldown = 2.0
			_speech_visible = false
			_hold_label(1.8)
			queue_redraw()
			if schedule_phase != "work":
				set_schedule_phase(schedule_phase)

func walk_to(target: Vector2, state: WorkState, arrival_state: WorkState = WorkState.IDLE) -> void:
	var travel := target - position
	if not travel.is_zero_approx():
		_facing = _direction_name(travel)
	_target_position = target
	_arrival_state = arrival_state
	_has_target = true
	work_state = state
	_animation_elapsed = 0.0
	_hold_label()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _character_sprite == null or _shadow_sprite == null or _effect_sprite == null:
		return
	_animation_elapsed += delta
	if _label_hold > 0.0:
		_label_hold = maxf(0.0, _label_hold - delta)
		if is_zero_approx(_label_hold):
			queue_redraw()
	if _effect_sprite.visible:
		_effect_elapsed += delta
		_effect_sprite.region_rect = PolishArt.effect_region(_activity, int(_effect_elapsed * 8.0) % 4)
		if _effect_duration > 0.0 and _effect_elapsed >= _effect_duration:
			_effect_sprite.visible = false
			_effect_duration = -1.0
			_activity = &""
			_status_override = ""
			queue_redraw()
	if _has_target:
		var travel := _target_position - position
		if not travel.is_zero_approx():
			_facing = _direction_name(travel)
		position = position.move_toward(_target_position, walk_speed * delta)
		if position.distance_to(_target_position) <= 0.5:
			position = _target_position
			_has_target = false
			work_state = _arrival_state
			_idle_elapsed = 0.0
			_animation_elapsed = 0.0
			_hold_label()
			if work_state == WorkState.IDLE and not has_live_job and schedule_phase != "work":
				set_schedule_phase(schedule_phase)
			queue_redraw()
	_update_character_frame()
	if not has_live_job and schedule_phase == "work" and not _has_target:
		_update_idle(delta)
	z_index = int(position.y)

func _update_idle(delta: float) -> void:
	_idle_elapsed += delta
	if work_state == WorkState.IDLE and _idle_elapsed >= _idle_cooldown:
		_idle_elapsed = 0.0
		walk_to(desk_position, WorkState.IDLE_WALKING, WorkState.SITTING)
	elif work_state == WorkState.SITTING:
		var show_memory := not _speech_suppressed and not memory_line.is_empty() and _idle_elapsed >= 2.5 and _idle_elapsed < 5.0
		if show_memory != _speech_visible:
			_speech_visible = show_memory
			queue_redraw()
		if _idle_elapsed >= 7.0:
			_idle_elapsed = 0.0
			_idle_cycle += 1
			_speech_visible = false
			var direction := -1.0 if (_idle_cycle + employee_id.length()) % 2 == 0 else 1.0
			var wander_target := desk_position + Vector2(48.0 * direction, 34.0)
			walk_to(wander_target, WorkState.WANDERING, WorkState.IDLE)

func set_speech_suppressed(suppressed: bool) -> void:
	if _speech_suppressed == suppressed:
		return
	_speech_suppressed = suppressed
	if suppressed:
		_speech_visible = false
	queue_redraw()

func set_interaction_highlighted(highlighted: bool) -> void:
	if _interaction_highlighted == highlighted:
		return
	_interaction_highlighted = highlighted
	if highlighted:
		_hold_label(2.0)
	queue_redraw()

func is_at_desk() -> bool:
	return position.distance_to(desk_position) <= 0.5

func state_label() -> String:
	if not _status_override.is_empty():
		return _status_override
	match work_state:
		WorkState.IDLE:
			return "available"
		WorkState.IDLE_WALKING:
			return "finding a seat"
		WorkState.SITTING:
			return "sitting"
		WorkState.WANDERING:
			return "wandering"
		WorkState.LUNCH:
			return "at lunch"
		WorkState.OFF_SHIFT:
			return "off shift"
		WorkState.WALKING_TO_DESK:
			return "heading to desk"
		WorkState.WORKING:
			return "working"
		WorkState.TYPING:
			return "typing"
		WorkState.WALKING_TO_RESEARCH:
			return "researching"
		WorkState.WAITING_APPROVAL:
			return "needs approval"
		WorkState.DELIVERING:
			return "delivering"
	return "available"

func _draw() -> void:
	if _speech_visible:
		var speech := memory_line if memory_line.length() <= 38 else "%s..." % memory_line.left(35)
		draw_texture_rect(OperationsSkin.WORLD_SPEECH_BUBBLE, Rect2(-86.0, -122.0, 172.0, 90.0), false)
		var speech_lines := _wrap_speech(speech, 21)
		for line_index: int in range(speech_lines.size()):
			draw_string(GameFonts.BODY, Vector2(-72.0, -86.0 + line_index * 18.0), speech_lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, 144.0, GameFonts.BODY_META, Color("151515"))
	if not _labels_visible():
		return
	draw_texture_rect(OperationsSkin.WORLD_NAMEPLATE, Rect2(-58.0, 9.0, 116.0, 36.0), false)
	draw_string(GameFonts.DISPLAY, Vector2(-50.0, 35.0), display_name, HORIZONTAL_ALIGNMENT_CENTER, 100.0, GameFonts.DISPLAY_SMALL, Color("151515"))
	draw_texture_rect(OperationsSkin.WORLD_STATUS_PLAQUE, Rect2(-64.0, 42.0, 128.0, 31.0), false)
	var state_color := Color("354b98")
	if work_state == WorkState.WAITING_APPROVAL:
		state_color = Color("963014")
	elif work_state == WorkState.OFF_SHIFT:
		state_color = Color("151515")
	if work_state == WorkState.IDLE:
		draw_texture_rect(OperationsSkin.WORLD_AVAILABLE, Rect2(-55.0, 49.0, 15.0, 15.0), false)
	if work_state == WorkState.WAITING_APPROVAL:
		draw_texture_rect(OperationsSkin.WORLD_ATTENTION, Rect2(34.0, 4.0, 20.0, 23.0), false)
	draw_string(GameFonts.BODY, Vector2(-40.0, 64.0), state_label(), HORIZONTAL_ALIGNMENT_CENTER, 96.0, GameFonts.BODY_META, state_color)

func _labels_visible() -> bool:
	# Active work is already communicated by the authored pose and event VFX.
	# Keep plaques contextual so a busy office does not become a wall of labels.
	return not _speech_visible and (_interaction_highlighted or _label_hold > 0.0 or work_state == WorkState.WAITING_APPROVAL)

func _hold_label(duration: float = 1.2) -> void:
	_label_hold = maxf(_label_hold, duration)
	queue_redraw()

func _set_activity(kind: StringName, duration: float = -1.0) -> void:
	_activity = kind
	_effect_elapsed = 0.0
	_effect_duration = duration
	_effect_sprite.visible = not kind.is_empty()
	if _effect_sprite.visible:
		_effect_sprite.region_rect = PolishArt.effect_region(kind, 0)
	_hold_label()

func _update_character_frame() -> void:
	if _character_sprite == null:
		return
	var walking := _has_target
	var shadow_kind := 1 if walking else 0
	if not walking and (work_state == WorkState.SITTING or work_state == WorkState.LUNCH):
		_set_work_frame(0, int(_animation_elapsed * 1.5) % 2)
		shadow_kind = 2
	elif not walking and work_state == WorkState.TYPING:
		_set_work_frame(0, 2 + int(_animation_elapsed * 8.0) % 4)
		shadow_kind = 2
	elif not walking and work_state == WorkState.WAITING_APPROVAL:
		_set_work_frame(0, 6 + int(_animation_elapsed * 2.0) % 2)
	elif not walking and work_state == WorkState.WORKING:
		if _activity == &"research":
			_set_work_frame(1, int(_animation_elapsed * 6.0) % 4)
		else:
			_set_work_frame(1, 4 + int(_animation_elapsed * 4.0) % 4)
	elif work_state == WorkState.DELIVERING:
		_set_delivery_frame(int(_animation_elapsed * 8.0) % 4)
	else:
		_character_sprite.texture = CharacterArt.locomotion_sheet(employee_id)
		var frame := 2 + int(_animation_elapsed * 8.0) % 4 if walking else int(_animation_elapsed * 1.5) % 2
		_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, frame)
	_shadow_sprite.region_rect = PolishArt.shadow_region(shadow_kind)

func _set_work_frame(row: int, column: int) -> void:
	_character_sprite.texture = CharacterArt.work_sheet(employee_id)
	_character_sprite.region_rect = CharacterArt.work_region(row, column)

func _set_delivery_frame(frame: int) -> void:
	var row := 2
	var column := frame
	match _facing:
		&"back":
			column += 4
		&"left":
			row = 3
		&"right":
			row = 3
			column += 4
	_set_work_frame(row, column)

func _direction_name(direction: Vector2) -> StringName:
	if absf(direction.x) > absf(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
	return &"front" if direction.y > 0.0 else &"back"

func _wrap_speech(value: String, max_characters: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var current := ""
	for word: String in value.split(" ", false):
		var candidate := word if current.is_empty() else "%s %s" % [current, word]
		if candidate.length() > max_characters and not current.is_empty():
			lines.append(current)
			current = word
			if lines.size() >= 2:
				break
		else:
			current = candidate
	if not current.is_empty() and lines.size() < 2:
		lines.append(current)
	return lines
