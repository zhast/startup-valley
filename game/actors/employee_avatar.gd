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
var _typing_phase: float = 0.0
var _idle_elapsed: float = 0.0
var _idle_cooldown: float = 0.5
var _idle_cycle: int = 0
var _speech_visible: bool = false
var _character_sprite: Sprite2D

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
	_character_sprite = Sprite2D.new()
	_character_sprite.name = "CharacterSprite"
	_character_sprite.texture = CharacterArt.portrait(employee_id)
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.scale = Vector2.ONE * CharacterArt.world_scale(employee_id)
	_character_sprite.position = Vector2(0.0, -10.0)
	add_child(_character_sprite)
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
			walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.WORKING)
		&"agent.thinking":
			if work_state == WorkState.IDLE or work_state == WorkState.SITTING or work_state == WorkState.WANDERING:
				walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.WORKING)
		&"tool.started":
			if event.tool == "web_search" or event.tool == "web_fetch":
				walk_to(research_position, WorkState.WALKING_TO_RESEARCH, WorkState.WORKING)
			elif event.tool == "write_file" or event.tool == "edit_file":
				if position.distance_to(desk_position) > 4.0:
					walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.WORKING)
				else:
					work_state = WorkState.TYPING
					queue_redraw()
			else:
				work_state = WorkState.WORKING
				queue_redraw()
		&"tool.completed":
			work_state = WorkState.WORKING
			queue_redraw()
		&"approval.required":
			walk_to(player_position + Vector2(34.0, 0.0), WorkState.WAITING_APPROVAL, WorkState.WAITING_APPROVAL)
		&"job.completed":
			has_live_job = false
			delivery_position = player_position + Vector2(38.0, 8.0)
			walk_to(delivery_position, WorkState.DELIVERING, WorkState.IDLE)
		&"job.blocked", &"job.failed":
			has_live_job = false
			work_state = WorkState.IDLE
			_has_target = false
			_idle_elapsed = 0.0
			_idle_cooldown = 2.0
			_speech_visible = false
			queue_redraw()
			if schedule_phase != "work":
				set_schedule_phase(schedule_phase)

func walk_to(target: Vector2, state: WorkState, arrival_state: WorkState = WorkState.IDLE) -> void:
	if _character_sprite != null and not is_equal_approx(target.x, position.x):
		_character_sprite.flip_h = target.x < position.x
	_target_position = target
	_arrival_state = arrival_state
	_has_target = true
	work_state = state
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _has_target:
		position = position.move_toward(_target_position, walk_speed * delta)
		if position.distance_to(_target_position) <= 0.5:
			position = _target_position
			_has_target = false
			work_state = _arrival_state
			_idle_elapsed = 0.0
			if work_state == WorkState.IDLE and not has_live_job and schedule_phase != "work":
				set_schedule_phase(schedule_phase)
			queue_redraw()
	if work_state == WorkState.TYPING:
		_typing_phase += delta
		_character_sprite.position.y = -11.0 if _typing_phase < 0.1 else -9.0
		if _typing_phase >= 0.2:
			_typing_phase = 0.0
			queue_redraw()
	elif _character_sprite != null:
		_character_sprite.position.y = -10.0
	if not has_live_job and schedule_phase == "work" and not _has_target:
		_update_idle(delta)
	z_index = int(position.y)

func _update_idle(delta: float) -> void:
	_idle_elapsed += delta
	if work_state == WorkState.IDLE and _idle_elapsed >= _idle_cooldown:
		_idle_elapsed = 0.0
		walk_to(desk_position, WorkState.IDLE_WALKING, WorkState.SITTING)
	elif work_state == WorkState.SITTING:
		var show_memory := not memory_line.is_empty() and _idle_elapsed >= 2.5 and _idle_elapsed < 5.0
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

func is_at_desk() -> bool:
	return position.distance_to(desk_position) <= 0.5

func state_label() -> String:
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
	draw_circle(Vector2(0.0, 18.0), 13.0, Color("15151566"))
	if _speech_visible:
		var speech := memory_line.left(46)
		draw_string(ThemeDB.fallback_font, Vector2(-70.0, -46.0), speech, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 10, Color("f1f1f1"))
	draw_string(ThemeDB.fallback_font, Vector2(-32.0, 38.0), display_name, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 12, Color("f1f1f1"))
	var state_color := Color("c1fa81")
	if work_state == WorkState.WAITING_APPROVAL:
		state_color = Color("fa4616")
	elif work_state == WorkState.OFF_SHIFT:
		state_color = Color("b6b5b0")
	draw_string(ThemeDB.fallback_font, Vector2(-45.0, 51.0), state_label(), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 10, state_color)
