class_name EmployeeAvatar
extends Node2D

class LabelLayer extends Node2D:
	var avatar: EmployeeAvatar
	func _process(_delta: float) -> void:
		if is_instance_valid(avatar): position = avatar.position.round() - avatar.position
	func _draw() -> void:
		if is_instance_valid(avatar):
			avatar.draw_labels(self)

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

# Canvas labels use the same semantic roles as the native interface. The
# different weights and line boxes are deliberate, not inherited theme state.
const NAME_FONT: Font = GameFonts.BOLD
const STATUS_FONT: Font = GameFonts.EMPHASIS
const SPEECH_FONT: Font = GameFonts.BODY
const NAME_FONT_SIZE := 16
const STATUS_FONT_SIZE := 14
const SPEECH_FONT_SIZE := 16
const NAME_INSET := Vector2(8, 4)
const SPEECH_INSET := Vector2(12, 8)
const TEXT_LINE_GAP := 2.0
const SPEECH_WIDTH := 188.0

@export var walk_speed: float = 110.0
var employee_id: String = ""
var display_name: String = "Worker"
var morale: int = 50
var home_position: Vector2 = Vector2.ZERO
var desk_position: Vector2 = Vector2.ZERO
var research_position: Vector2 = Vector2.ZERO
var lunch_position: Vector2 = Vector2.ZERO
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
var _ui_highlighted: bool = false
var _drawer_selected: bool = false
var _callout_offset := Vector2(INF, INF)
var _ui_presentation_state: String = ""
var _status_override: String = ""
var navigation: OfficeNavigation
var world_paused := false
var labels_suppressed := false
var _route := PackedVector2Array()
var _route_revision := -1
var _requested_target := Vector2.ZERO
var _stuck_elapsed := 0.0
var _progress_waypoint := Vector2(INF, INF)
var _progress_distance := INF
var _label_layer: LabelLayer
var _waiting_for_desk := false
var _desk_retry_elapsed := 0.0
var _route_requires_desk := false
var _desk_travel_state: WorkState = WorkState.WALKING_TO_DESK

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
	lunch_position = research
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var footprint := CircleShape2D.new()
	footprint.radius = 9.0
	collider.shape = footprint
	body.add_child(collider)
	add_child(body)
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
	_label_layer = LabelLayer.new()
	_label_layer.avatar = self
	_label_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_label_layer.z_as_relative = false
	_label_layer.z_index = 3000
	add_child(_label_layer)
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
		walk_to(lunch_position, WorkState.LUNCH, WorkState.LUNCH)
	elif phase == "off":
		walk_to(home_position, WorkState.OFF_SHIFT, WorkState.OFF_SHIFT)
	else:
		work_state = WorkState.IDLE
		_has_target = false
		_waiting_for_desk = false
		_route_requires_desk = false
		_idle_cooldown = 0.5
		queue_redraw()

func apply_worker_event(event: WorkerEventRecord, player_position: Vector2) -> void:
	if not has_live_job and event.type in [&"agent.thinking", &"tool.started", &"tool.completed", &"approval.required"]:
		return
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
				if _waiting_for_desk: _arrival_state = WorkState.WORKING
				else: work_state = WorkState.WORKING
				queue_redraw()
		&"tool.completed":
			_set_activity(&"thinking")
			if _has_target or _waiting_for_desk: _arrival_state = WorkState.WORKING
			else: work_state = WorkState.WORKING
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
			if navigation != null: navigation.release(employee_id)
			has_live_job = false
			_set_activity(&"failure", 1.2)
			_status_override = "work stopped"
			work_state = WorkState.IDLE
			_has_target = false
			_waiting_for_desk = false
			_route_requires_desk = false
			_route.clear()
			_idle_elapsed = 0.0
			_idle_cooldown = 2.0
			_speech_visible = false
			_hold_label(1.8)
			queue_redraw()
			if schedule_phase != "work":
				set_schedule_phase(schedule_phase)

func walk_to(target: Vector2, state: WorkState, arrival_state: WorkState = WorkState.IDLE) -> void:
	_route_requires_desk = state in [WorkState.WALKING_TO_DESK, WorkState.IDLE_WALKING]
	_waiting_for_desk = false
	_desk_retry_elapsed = 0.0
	if _route_requires_desk:
		# A reservation fallback is not a new workstation. Only TownRoom may
		# update the authored desk position when its validated layout changes.
		target = desk_position
		_desk_travel_state = state
	_arrival_state = arrival_state
	_requested_target = target
	_stuck_elapsed = 0.0
	_progress_waypoint = Vector2(INF, INF)
	_progress_distance = INF
	if navigation != null:
		if _route_requires_desk and not _desk_available():
			_wait_for_desk()
			return
		_route = navigation.path(position, target, employee_id)
		_route_revision = navigation.revision
		if _route.is_empty() or (_route_requires_desk and _route[-1].distance_to(desk_position) > 0.5):
			_has_target = false
			navigation.release(employee_id)
			if _route_requires_desk: _wait_for_desk()
			return
		target = _route[-1]
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

func _desk_available() -> bool:
	if navigation == null: return true
	if not navigation.position_is_safe(desk_position, employee_id): return false
	var seat := navigation.cell_at(desk_position)
	for owner: String in navigation.reservations:
		if owner != employee_id and navigation.reservations[owner] == seat: return false
	return true

func _wait_for_desk() -> void:
	_waiting_for_desk = true
	_desk_retry_elapsed = 0.0
	_has_target = false
	_route.clear()
	if navigation != null: navigation.release(employee_id)
	work_state = _desk_travel_state
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
	if _waiting_for_desk and not world_paused:
		_desk_retry_elapsed += delta
		if _desk_retry_elapsed >= 0.2:
			walk_to(desk_position, _desk_travel_state, _arrival_state)
	if _has_target and not world_paused:
		if navigation != null and navigation.revision != _route_revision:
			if _route_requires_desk:
				walk_to(desk_position, _desk_travel_state, _arrival_state)
				if not _has_target: return
			_route = navigation.path(position, _requested_target, employee_id)
			_route_revision = navigation.revision
			if _route.is_empty():
				_has_target = false
				if _route_requires_desk: _wait_for_desk()
				return
			if _route_requires_desk and _route[-1].distance_to(desk_position) > 0.5:
				_wait_for_desk()
				return
			_target_position = _route[-1]
		var waypoint := _route[0] if not _route.is_empty() else _target_position
		var travel := waypoint - position
		if waypoint != _progress_waypoint:
			_progress_waypoint = waypoint
			_progress_distance = travel.length()
			_stuck_elapsed = 0.0
		if not travel.is_zero_approx():
			_facing = _direction_name(travel)
		var next := position.move_toward(waypoint, walk_speed * delta)
		position = navigation.separated_step(employee_id, position, next) if navigation != null else next
		# Measure net progress over time, not one frame's sideways shuffle.
		if _progress_distance - position.distance_to(waypoint) < 2.0:
			_stuck_elapsed += delta
			if _stuck_elapsed > 0.8:
				if navigation != null: navigation.request_passage(employee_id, position, waypoint)
				walk_to(_requested_target, _desk_travel_state if _route_requires_desk else work_state, _arrival_state)
				return
		else:
			_stuck_elapsed = 0.0
			_progress_distance = position.distance_to(waypoint)
		if position.distance_to(waypoint) <= 0.5 and not _route.is_empty():
			_route.remove_at(0)
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
	_character_sprite.position = Vector2(0, -32) + position.round() - position
	_shadow_sprite.position = Vector2(0, -2) + position.round() - position
	if navigation != null: navigation.actors[employee_id] = position
	if not world_paused and not has_live_job and schedule_phase == "work" and not _has_target:
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
	if _speech_suppressed == suppressed and not (suppressed and _speech_visible):
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

func set_ui_highlighted(highlighted: bool) -> void:
	if _ui_highlighted == highlighted: return
	_ui_highlighted = highlighted
	queue_redraw()

func set_drawer_selected(selected: bool) -> void:
	if _drawer_selected == selected: return
	_drawer_selected = selected
	if selected: _speech_visible = false
	_sync_attention_presentation()
	queue_redraw()

func set_callout_position(world_position: Vector2) -> void:
	var offset := world_position.round() - position.round()
	if _callout_offset == offset: return
	_callout_offset = offset
	queue_redraw()

func has_attention() -> bool:
	return _ui_presentation_state in ["needs approval", "delivery ready", "needs retry", "cancelled"] or work_state == WorkState.WAITING_APPROVAL

func attention_cue_visible() -> bool:
	# A selected decision/delivery needs a legible cue even when the event burst
	# is held on its nearly-empty first frame. Its animation remains untouched.
	return has_attention() and (_drawer_selected or _effect_sprite == null or not _effect_sprite.visible) and not _labels_visible()

func _sync_attention_presentation() -> void:
	if _effect_sprite == null: return
	# Only paint ownership changes. Do not toggle visible: it controls the
	# event animation timer/expiry in _physics_process, even during a UI pause.
	_effect_sprite.self_modulate.a = 0.0 if _drawer_selected and has_attention() else 1.0

func set_ui_presentation_state(value: String) -> void:
	if _ui_presentation_state == value: return
	_ui_presentation_state = value
	_sync_attention_presentation()
	queue_redraw()

func presentation_label() -> String:
	# Business attention survives the physical delivery walk and save hydration.
	# This cached UI wording never changes the avatar's route or animation state.
	match _ui_presentation_state:
		"needs approval": return "Needs approval"
		"delivery ready": return "Delivery ready"
		"needs retry": return "Needs retry"
		"cancelled": return "Cancelled"
		"queued": return "Queued"
		"at lunch": return "At lunch"
		"off shift": return "Off shift"
		"working":
			if work_state == WorkState.WALKING_TO_DESK: return "Waiting for desk" if _waiting_for_desk else "To desk"
			if work_state == WorkState.TYPING: return "Typing"
			if work_state == WorkState.WALKING_TO_RESEARCH: return "Researching"
			return "Working"
	if work_state == WorkState.WAITING_APPROVAL: return "Needs approval"
	return state_label().capitalize()

func is_at_desk() -> bool:
	return position.distance_to(desk_position) <= 0.5

func state_label() -> String:
	if not _status_override.is_empty():
		return _status_override
	match work_state:
		WorkState.IDLE:
			return "available"
		WorkState.IDLE_WALKING:
			return "to seat"
		WorkState.SITTING:
			return "sitting"
		WorkState.WANDERING:
			return "wandering"
		WorkState.LUNCH:
			return "to lunch" if _has_target else "at lunch"
		WorkState.OFF_SHIFT:
			return "off shift"
		WorkState.WALKING_TO_DESK:
			return "to desk"
		WorkState.WORKING:
			return "working"
		WorkState.TYPING:
			return "typing"
		WorkState.WALKING_TO_RESEARCH:
			return "researching"
		WorkState.WAITING_APPROVAL:
			return "approve?"
		WorkState.DELIVERING:
			return "delivering"
	return "available"

func _draw() -> void:
	if _label_layer != null: _label_layer.queue_redraw()

func draw_labels(canvas: Node2D) -> void:
	if labels_suppressed: return
	if attention_cue_visible():
		var cue := _attention_rect()
		WorldCalloutSkin.draw(canvas, cue, WorldCalloutSkin.ACTOR_BOUNDS.get_center())
		# Native miniature artwork, not the nearly empty first frame of a burst.
		var icon := CozyUI.icon("document") if _ui_presentation_state == "delivery ready" else OperationsSkin.WORLD_ATTENTION
		canvas.draw_texture(icon, cue.position + Vector2(4, 4))
		return
	if _speech_visible and not _drawer_selected:
		var speech_lines := _wrap_speech(memory_line, 21)
		WorldCalloutSkin.draw(canvas, _speech_rect(), WorldCalloutSkin.ACTOR_BOUNDS.get_center())
		for line_index: int in range(speech_lines.size()):
			canvas.draw_string(SPEECH_FONT, _speech_baseline(line_index), speech_lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, SPEECH_WIDTH - SPEECH_INSET.x * 2, SPEECH_FONT_SIZE, Color("151515"))
	if not _labels_visible():
		return
	var detail := _label_detail_visible()
	var width := _name_width()
	var rect := _nameplate_rect()
	WorldCalloutSkin.draw(canvas, rect, WorldCalloutSkin.ACTOR_BOUNDS.get_center())
	var name_text := _fit_label(display_name, width - NAME_INSET.x * 2, NAME_FONT, NAME_FONT_SIZE)
	canvas.draw_string(NAME_FONT, _name_baseline(), name_text, HORIZONTAL_ALIGNMENT_CENTER, width - NAME_INSET.x * 2, NAME_FONT_SIZE, Color("151515"))
	if detail:
		var attention := has_attention()
		var status := presentation_label()
		var state_color := Color("963014") if attention else Color("51463a")
		canvas.draw_string(STATUS_FONT, _status_baseline(), status, HORIZONTAL_ALIGNMENT_CENTER, width - NAME_INSET.x * 2, STATUS_FONT_SIZE, state_color)

func _name_width() -> float:
	if _label_detail_visible(): return 132.0
	var measured := NAME_FONT.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	# An even card width keeps its centered left edge on a whole world pixel.
	return clampf(ceilf((measured + 24.0) * 0.5) * 2.0, 64.0, 132.0)

func _nameplate_rect() -> Rect2:
	var height := ceilf(NAME_FONT.get_height(NAME_FONT_SIZE)) + NAME_INSET.y * 2
	if _label_detail_visible(): height += TEXT_LINE_GAP + ceilf(STATUS_FONT.get_height(STATUS_FONT_SIZE))
	var offset := _callout_offset if _callout_offset.is_finite() else Vector2(-_name_width() * 0.5, 15)
	return Rect2(offset, Vector2(_name_width(), ceilf(height * 0.5) * 2))

func _name_baseline() -> Vector2:
	return _nameplate_rect().position + NAME_INSET + Vector2(0, ceilf(NAME_FONT.get_ascent(NAME_FONT_SIZE)))

func _status_baseline() -> Vector2:
	return _nameplate_rect().position + NAME_INSET + Vector2(0, ceilf(NAME_FONT.get_height(NAME_FONT_SIZE)) + TEXT_LINE_GAP + ceilf(STATUS_FONT.get_ascent(STATUS_FONT_SIZE)))

func _speech_rect() -> Rect2:
	var line_count := maxi(1, _wrap_speech(memory_line, 21).size())
	var height := ceilf(SPEECH_FONT.get_height(SPEECH_FONT_SIZE)) * line_count + TEXT_LINE_GAP * (line_count - 1) + SPEECH_INSET.y * 2
	height = ceilf(height * 0.5) * 2
	var offset := _callout_offset if _callout_offset.is_finite() else Vector2(-SPEECH_WIDTH * 0.5, -72 - height - 11)
	return Rect2(offset, Vector2(SPEECH_WIDTH, height))

func _attention_rect() -> Rect2:
	return Rect2(_callout_offset if _callout_offset.is_finite() else Vector2(-16, -119), Vector2(32, 36))

func _speech_baseline(line: int) -> Vector2:
	return _speech_rect().position + SPEECH_INSET + Vector2(0, ceilf(SPEECH_FONT.get_ascent(SPEECH_FONT_SIZE)) + line * (ceilf(SPEECH_FONT.get_height(SPEECH_FONT_SIZE)) + TEXT_LINE_GAP))

func _label_detail_visible() -> bool:
	return not _drawer_selected and (_interaction_highlighted or _ui_highlighted or work_state == WorkState.WAITING_APPROVAL or (not _status_override.is_empty() and _label_hold > 0))

func world_label_body_rect() -> Rect2:
	return _attention_rect() if attention_cue_visible() else _speech_rect() if _speech_visible and not _drawer_selected else _nameplate_rect()

func world_label_rect() -> Rect2:
	var local := world_label_body_rect()
	local = WorldCalloutSkin.bounds(local, WorldCalloutSkin.ACTOR_BOUNDS.get_center())
	# Occlusion/hit-testing must use the same snapped geometry as LabelLayer.
	return Rect2(position.round() + local.position, local.size)

func _labels_visible() -> bool:
	# Keep the existing contextual lifetime so even a small name cannot sit over
	# a workstation forever. Hover/selection/attention reveal its second line.
	return not labels_suppressed and not _drawer_selected and not _speech_visible and (_interaction_highlighted or _ui_highlighted or _label_hold > 0 or work_state == WorkState.WAITING_APPROVAL)

func _fit_label(value: String, width: float, font: Font, font_size: int) -> String:
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width: return value
	var result := value
	while not result.is_empty() and font.get_string_size(result + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		result = result.left(-1)
	return result + "…"

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
	if not walking and work_state == WorkState.SITTING:
		_set_seated_frame(int(_animation_elapsed * 1.5) % 2)
		shadow_kind = 2
	elif not walking and work_state == WorkState.LUNCH:
		_set_work_frame(0, int(_animation_elapsed * 1.5) % 2)
		shadow_kind = 2
	elif not walking and work_state == WorkState.TYPING:
		_set_seated_frame(2 + int(_animation_elapsed * 8.0) % 4)
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

func _set_seated_frame(column: int) -> void:
	_character_sprite.texture = CharacterArt.seated_sheet(employee_id)
	_character_sprite.region_rect = Rect2(Vector2(column * 48, 0), CharacterArt.FRAME_SIZE)

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

func _wrap_speech(value: String, _max_characters: int) -> PackedStringArray:
	var lines := _speech_words(value)
	var safe_width := SPEECH_WIDTH - SPEECH_INSET.x * 2
	var fits := lines.size() <= 2
	for line: String in lines:
		if SPEECH_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEECH_FONT_SIZE).x > safe_width: fits = false
	if fits and not lines.is_empty(): return lines
	# Ambient speech is a complete intentional thought, not a chopped memory.
	# The worker-owned memory remains untouched and is never rewritten here.
	var ambient := "Let's test what works." if employee_id == "theo" else "One clear idea at a time."
	return _speech_words(ambient)

func _speech_words(value: String) -> PackedStringArray:
	var lines := PackedStringArray()
	var current := ""
	var words := value.replace("\r", " ").replace("\n", " ").split(" ", false)
	var safe_width := SPEECH_WIDTH - SPEECH_INSET.x * 2
	for index: int in range(words.size()):
		var word := words[index]
		var candidate := word if current.is_empty() else "%s %s" % [current, word]
		if SPEECH_FONT.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEECH_FONT_SIZE).x > safe_width and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty(): lines.append(current)
	return lines
