class_name EmployeeAvatar
extends Node2D

enum WorkState { IDLE, WALKING_TO_DESK, WORKING, TYPING, WALKING_TO_RESEARCH, WAITING_APPROVAL, DELIVERING }

@export var walk_speed: float = 110.0
var employee_id: String = ""
var display_name: String = "Worker"
var morale: int = 50
var desk_position: Vector2 = Vector2.ZERO
var research_position: Vector2 = Vector2.ZERO
var delivery_position: Vector2 = Vector2.ZERO
var work_state: WorkState = WorkState.IDLE
var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _typing_phase: float = 0.0

func configure(record: EmployeeRecord, start_position: Vector2, desk: Vector2, research: Vector2) -> void:
	employee_id = record.id
	display_name = record.display_name
	morale = record.morale
	position = start_position
	desk_position = desk
	research_position = research
	queue_redraw()

func apply_worker_event(event: WorkerEventRecord, player_position: Vector2) -> void:
	match event.type:
		&"job.started":
			walk_to(desk_position, WorkState.WALKING_TO_DESK)
		&"agent.thinking":
			if work_state == WorkState.IDLE:
				walk_to(desk_position, WorkState.WALKING_TO_DESK)
		&"tool.started":
			if event.tool == "web_search" or event.tool == "web_fetch":
				walk_to(research_position, WorkState.WALKING_TO_RESEARCH)
			elif event.tool == "write_file" or event.tool == "edit_file":
				if position.distance_to(desk_position) > 4.0:
					walk_to(desk_position, WorkState.WALKING_TO_DESK)
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
			walk_to(player_position + Vector2(34.0, 0.0), WorkState.WAITING_APPROVAL)
		&"job.completed":
			delivery_position = player_position + Vector2(38.0, 8.0)
			walk_to(delivery_position, WorkState.DELIVERING)
		&"job.blocked":
			work_state = WorkState.IDLE
			_has_target = false
			queue_redraw()
		&"job.failed":
			work_state = WorkState.IDLE
			_has_target = false
			queue_redraw()

func walk_to(target: Vector2, state: WorkState) -> void:
	_target_position = target
	_has_target = true
	work_state = state
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _has_target:
		position = position.move_toward(_target_position, walk_speed * delta)
		if position.distance_to(_target_position) <= 0.5:
			position = _target_position
			_has_target = false
			if work_state == WorkState.WALKING_TO_DESK or work_state == WorkState.WALKING_TO_RESEARCH:
				work_state = WorkState.WORKING
			elif work_state == WorkState.DELIVERING:
				work_state = WorkState.IDLE
			queue_redraw()
	if work_state == WorkState.TYPING:
		_typing_phase += delta
		if _typing_phase >= 0.2:
			_typing_phase = 0.0
			queue_redraw()

func is_at_desk() -> bool:
	return position.distance_to(desk_position) <= 0.5

func state_label() -> String:
	match work_state:
		WorkState.IDLE:
			return "available"
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
	var body_color := Color("7dc6a7") if employee_id == "mira" else Color("d9a66f")
	if work_state == WorkState.TYPING and _typing_phase < 0.1:
		body_color = body_color.lightened(0.18)
	draw_circle(Vector2(0.0, -7.0), 8.5, Color("e9b98f"))
	draw_rect(Rect2(-9.0, 1.0, 18.0, 21.0), body_color, true)
	draw_rect(Rect2(-9.0, -15.0, 18.0, 5.0), Color("493b4a"), true)
	if work_state == WorkState.TYPING:
		draw_line(Vector2(-12.0, 10.0), Vector2(-18.0, 6.0), Color("f4d6b8"), 3.0)
		draw_line(Vector2(12.0, 10.0), Vector2(18.0, 6.0), Color("f4d6b8"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-32.0, 36.0), display_name, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 12, Color("f5f7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(-45.0, 50.0), state_label(), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 10, Color("aebbd3"))
