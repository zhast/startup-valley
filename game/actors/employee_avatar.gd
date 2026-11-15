class_name EmployeeAvatar
extends Node2D

class LabelLayer extends Node2D:
	var avatar: EmployeeAvatar
	func _process(_delta: float) -> void:
		if is_instance_valid(avatar): position = avatar.render_position() - avatar.position
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
var has_studio_project := false
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
var _workstation_visual: Dictionary = {}
var _research_visual: Dictionary = {}
var _collaboration_visual: Dictionary = {}
var _collaboration_handoff_active := false
var _collaboration_seat_rest := false
var _seat_transition_preview := false
var _seat_transition_manual_preview := false
var _seat_transition_duration := 0.14
var _seat_transition_elapsed := 0.0
var _seat_transition_active := false
var _seat_transition_serial := 0
var _seat_visual_offset := Vector2.ZERO
var _seat_visual_depth_bias := 0.0
var _seat_transition_from := Vector2.ZERO
var _seat_transition_to := Vector2.ZERO
var _seat_depth_from := 0.0
var _seat_depth_to := 0.0
var _terminal_seat_rest := false
var _seat_handoff_active := false
var _seat_handoff_origin := Vector2.ZERO
var _work_pose_layer_sprites: Dictionary[String, Sprite2D] = {}
var _active_work_pose_layers: Array[Dictionary] = []

func set_seat_transition_preview(enabled: bool, duration_ms: float = 140.0) -> bool:
	# Explicit local calibration only. Exported games never opt into unreviewed
	# seat correction/transition behavior, including debug export templates.
	if enabled and not OS.has_feature("editor"): return false
	if not is_finite(duration_ms) or duration_ms < 80.0 or duration_ms > 180.0: return false
	_seat_transition_manual_preview = enabled
	return _set_seat_transition_enabled(enabled, duration_ms)

func _set_seat_transition_enabled(enabled: bool, duration_ms: float = 140.0) -> bool:
	if not is_finite(duration_ms) or duration_ms < 80.0 or duration_ms > 180.0: return false
	if enabled == _seat_transition_preview and is_equal_approx(duration_ms / 1000.0, _seat_transition_duration): return true
	var previous_offset := seated_render_offset()
	var previous_depth := float(z_index - int(position.y))
	_seat_transition_preview = enabled
	_seat_transition_duration = duration_ms / 1000.0
	_seat_transition_active = false
	_seat_transition_elapsed = 0.0
	_seat_visual_offset = previous_offset if enabled else Vector2.ZERO
	_seat_visual_depth_bias = previous_depth if enabled else 0.0
	_seat_transition_to = _seat_visual_offset
	_seat_depth_to = _seat_visual_depth_bias
	_update_character_frame()
	return true

func configure_workstation_visual(metadata: Dictionary) -> bool:
	var resolved := _validated_work_visual(metadata, ["seated", "typing"])
	if resolved.is_empty(): return false
	_workstation_visual = resolved
	# Reviewed runtime assemblies opt into the same bounded, retargetable seat
	# handoff proven by calibration. Legacy and forged metadata remain instant.
	var reviewed_runtime := _reviewed_seat_transition_admitted(resolved)
	if not _seat_transition_manual_preview: _set_seat_transition_enabled(reviewed_runtime)
	_update_character_frame()
	return true

func configure_collaboration_visual(metadata: Dictionary) -> bool:
	if metadata.is_empty():
		_collaboration_visual.clear()
		_collaboration_handoff_active = false
		_collaboration_seat_rest = false
		_update_character_frame()
		return true
	var fields: Array[String] = [
		"work_facing", "pose_set", "collaboration_capability_revision",
		"seat_anchor", "seat_z_offset", "seat_layer_z_offsets",
		"ground_shadow_z_offset", "prop_anchor", "seat_position",
	]
	if metadata.size() != fields.size():
		_collaboration_visual.clear()
		return false
	for field: String in fields:
		if not metadata.has(field):
			_collaboration_visual.clear()
			return false
	var facing := str(metadata.work_facing)
	var pose_set := str(metadata.pose_set)
	var revision := str(metadata.collaboration_capability_revision)
	var capability := CharacterArt.reviewed_collaboration_capability(pose_set, facing, revision)
	if capability.is_empty() or not (capability.employees as Array).has(employee_id):
		_collaboration_visual.clear()
		return false
	for field: String in ["seat_anchor", "prop_anchor", "seat_position"]:
		var point: Variant = metadata[field]
		if not point is Vector2 or not (point as Vector2).is_finite() or (point as Vector2) != (point as Vector2).round():
			_collaboration_visual.clear()
			return false
	if Vector2(metadata.seat_position).distance_to(lunch_position) > 0.5:
		_collaboration_visual.clear()
		return false
	var depths: Variant = metadata.seat_layer_z_offsets
	if not depths is Dictionary or depths.size() != 2 or not depths.has("lower") or not depths.has("upper"):
		_collaboration_visual.clear()
		return false
	for value: Variant in [metadata.seat_z_offset, metadata.ground_shadow_z_offset, depths.lower, depths.upper]:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floorf(float(value)):
			_collaboration_visual.clear()
			return false
	var seat_depth := int(metadata.seat_z_offset)
	var lower_depth := int(depths.lower)
	var upper_depth := int(depths.upper)
	var shadow_depth := int(metadata.ground_shadow_z_offset)
	if seat_depth != lower_depth or shadow_depth >= lower_depth or lower_depth >= upper_depth:
		_collaboration_visual.clear()
		return false
	var resolved := metadata.duplicate(true)
	resolved.seat_anchor = Vector2(metadata.seat_anchor)
	resolved.prop_anchor = Vector2(metadata.prop_anchor)
	resolved.seat_position = Vector2(metadata.seat_position)
	resolved.seat_z_offset = seat_depth
	resolved.ground_shadow_z_offset = shadow_depth
	resolved.seat_layer_z_offsets = {"lower": lower_depth, "upper": upper_depth}
	_collaboration_visual = resolved
	_update_character_frame()
	return true

func _reviewed_seat_transition_admitted(metadata: Dictionary) -> bool:
	var handoff: Variant = metadata.get("seat_state_handoff", {})
	if not handoff is Dictionary or handoff.is_empty(): return false
	return CharacterArt.reviewed_workstation_option_admitted(
		str(metadata.get("pose_set", "")),
		str(metadata.get("work_facing", "")),
		str(metadata.get("workstation_capability_revision", "")),
		"seat_state_handoff",
		handoff,
	)

func configure_research_visual(metadata: Dictionary) -> bool:
	var resolved := _validated_work_visual(metadata, ["research"])
	if resolved.is_empty(): return false
	_research_visual = resolved
	_update_character_frame()
	return true

func _validated_work_visual(metadata: Dictionary, poses: Array[String]) -> Dictionary:
	var facing := str(metadata.get("work_facing", "south"))
	var pose_set := str(metadata.get("pose_set", CharacterArt.LEGACY_WORK_POSE_SET))
	var revision_value: Variant = metadata.get("workstation_capability_revision", "")
	if not revision_value is String: return {}
	var revision := str(revision_value)
	var calibration_owner_value: Variant = metadata.get("calibration_owner_id", 0)
	if not (calibration_owner_value is int or calibration_owner_value is float) or not is_finite(float(calibration_owner_value)) or float(calibration_owner_value) != floorf(float(calibration_owner_value)): return {}
	var calibration_owner_id := int(calibration_owner_value)
	var calibration := OS.has_feature("editor") and CharacterArt.calibration_pose_belongs_to(pose_set, calibration_owner_id)
	var depth_lock: Variant = metadata.get("seat_pose_depth_lock", false)
	if not depth_lock is bool: return {}
	if depth_lock and not calibration and not CharacterArt.reviewed_workstation_option_admitted(pose_set, facing, revision, "seat_pose_depth_lock", true): return {}
	var state_handoff: Variant = metadata.get("seat_state_handoff", {})
	if not state_handoff is Dictionary: return {}
	if not state_handoff.is_empty():
		var clearance: Variant = state_handoff.get("clearance_pixels")
		var layer_depths: Variant = metadata.get("seat_layer_z_offsets")
		if not calibration and not CharacterArt.reviewed_workstation_option_admitted(pose_set, facing, revision, "seat_state_handoff", state_handoff): return {}
		if not (clearance is int or clearance is float) or not is_finite(float(clearance)) or float(clearance) != floorf(float(clearance)) or int(clearance) < 1 or int(clearance) > 128: return {}
		if not layer_depths is Dictionary: return {}
		var lower_depth: Variant = layer_depths.get("lower")
		if not (lower_depth is int or lower_depth is float) or not is_finite(float(lower_depth)) or float(lower_depth) != floorf(float(lower_depth)): return {}
		if int(lower_depth) < -4096 or int(lower_depth) > 4095: return {}
	var grounded_shadow: Variant = metadata.get("grounded_work_shadow", false)
	if not grounded_shadow is bool: return {}
	var shadow_follow_x: Variant = metadata.get("grounded_work_shadow_follow_seat_x", false)
	if not shadow_follow_x is bool or (shadow_follow_x and not grounded_shadow): return {}
	if grounded_shadow:
		if not calibration and not CharacterArt.reviewed_workstation_option_admitted(pose_set, facing, revision, "grounded_work_shadow", true): return {}
		var shadow_depth: Variant = metadata.get("ground_shadow_z_offset")
		if not (shadow_depth is int or shadow_depth is float) or not is_finite(float(shadow_depth)) or float(shadow_depth) != floorf(float(shadow_depth)): return {}
		if int(shadow_depth) < -4096 or int(shadow_depth) > 4095: return {}
	if shadow_follow_x and not calibration and not CharacterArt.reviewed_workstation_option_admitted(pose_set, facing, revision, "grounded_work_shadow_follow_seat_x", true): return {}
	for pose: String in poses:
		if not CharacterArt.supports_work_pose(employee_id, pose_set, facing, pose): return {}
		var frame := CharacterArt.work_pose_frame(employee_id, pose_set, facing, pose, 0)
		if frame.has("layers"):
			var depths: Variant = metadata.get("seat_layer_z_offsets")
			if not depths is Dictionary: return {}
			for part: Dictionary in frame.layers:
				var depth: Variant = depths.get(str(part.name))
				if not (depth is int or depth is float) or not is_finite(float(depth)) or float(depth) != floorf(float(depth)): return {}
	var offset: Variant = metadata.get("seat_anchor", Vector2.ZERO)
	var correction: Variant = metadata.get("seat_correction", Vector2.ZERO)
	var anchor: Variant = metadata.get("prop_anchor", desk_position + Vector2(0, 32))
	if not offset is Vector2 or not anchor is Vector2 or not correction is Vector2: return {}
	if not (offset as Vector2).is_finite() or not (anchor as Vector2).is_finite() or not (correction as Vector2).is_finite(): return {}
	var resolved := metadata.duplicate(true)
	resolved["work_facing"] = facing
	resolved["pose_set"] = pose_set
	resolved["seat_anchor"] = (offset as Vector2).round()
	resolved["prop_anchor"] = anchor
	resolved["seat_z_offset"] = int(metadata.get("seat_z_offset", -32))
	# Preserve exact legacy metadata dictionaries when this optional calibration
	# field is absent; no employee or facing is assigned an implicit correction.
	if metadata.has("seat_correction"): resolved["seat_correction"] = (correction as Vector2).round()
	if not state_handoff.is_empty(): resolved["seat_state_handoff"] = state_handoff.duplicate(true)
	return resolved

func seated_render_offset() -> Vector2:
	if _seat_transition_preview: return _seat_visual_offset.round()
	if _uses_collaboration_visual(): return _collaboration_visual.seat_anchor
	if not _uses_seated_visual(): return Vector2.ZERO
	return _workstation_visual.get("seat_anchor", Vector2.ZERO)

func render_position() -> Vector2:
	return position.round() + seated_render_offset()

func body_surface_at(point: Vector2) -> Sprite2D:
	# Only the actually painted body; shadows, work cues and callouts do not
	# turn transparent sprite-cell padding into an employee interaction target.
	var sprites: Array[Sprite2D] = [_character_sprite]
	for layer: Sprite2D in _work_pose_layer_sprites.values(): sprites.append(layer)
	return VisibleSurface.top(sprites, point)

func work_vfx_position() -> Vector2:
	# Explicit reviewed/calibration attachments belong to the stationary assembly.
	# A prop-relative anchor stays above its monitor during seat interpolation;
	# legacy/moving/terminal cues retain their original actor-relative origin.
	var anchor: Variant = _work_vfx_anchor()
	if anchor is Vector2: return (Vector2(_workstation_visual.prop_anchor) + anchor).round()
	return position + Vector2(0, -78) + seated_render_offset() + (position.round() - position if _seat_transition_preview else Vector2.ZERO)

func _work_vfx_anchor() -> Variant:
	if has_live_job and _uses_seated_visual() and _activity in [&"thinking", &"typing"]:
		return CharacterArt.workstation_work_vfx_anchor(employee_id, str(_workstation_visual.pose_set), str(_workstation_visual.work_facing), str(_activity), str(_workstation_visual.get("workstation_capability_revision", "")), int(_workstation_visual.get("calibration_owner_id", 0)))
	return null

func work_vfx_rect() -> Rect2:
	# Assembly fallback remains capability-gated. Ordinary legacy event cues
	# expose their painted region separately for shared callout avoidance.
	if not _work_vfx_anchor() is Vector2: return Rect2()
	return visible_world_vfx_rect()

# Compatibility aliases keep the dedicated calibration suites source-stable;
# production code uses the capability-neutral names above.
func _calibration_work_vfx_anchor() -> Variant:
	return _work_vfx_anchor()

func calibration_work_vfx_rect() -> Rect2:
	return work_vfx_rect()

func visible_world_vfx_rect() -> Rect2:
	if _effect_sprite == null or not _effect_sprite.is_visible_in_tree(): return Rect2()
	if _effect_sprite.self_modulate.a <= 0.0 or _effect_sprite.modulate.a <= 0.0: return Rect2()
	# Reserve the complete native animation cell, not its changing ink bounds:
	# names must not jitter or crowd the next, fuller frame of a real event.
	return _effect_sprite.global_transform * _effect_sprite.get_rect()

func _uses_seated_visual() -> bool:
	return _seat_visual_capability_current() and not _has_target and is_at_desk() and (work_state in [WorkState.SITTING, WorkState.TYPING] or _terminal_seat_rest or _uses_seated_thinking())

func _uses_collaboration_visual() -> bool:
	if _collaboration_visual.is_empty() or _has_target: return false
	if work_state != WorkState.LUNCH and not _collaboration_seat_rest: return false
	if position.distance_to(lunch_position) > 0.5 or Vector2(_collaboration_visual.seat_position).distance_to(lunch_position) > 0.5: return false
	var capability := CharacterArt.reviewed_collaboration_capability(
		str(_collaboration_visual.pose_set),
		str(_collaboration_visual.work_facing),
		str(_collaboration_visual.collaboration_capability_revision),
	)
	return not capability.is_empty() and (capability.employees as Array).has(employee_id)

func _collaboration_contact_current() -> bool:
	if _collaboration_visual.is_empty(): return false
	if Vector2(_collaboration_visual.seat_position).distance_to(lunch_position) > 0.5: return false
	return position.distance_to(lunch_position) < 32.0 and not CharacterArt.reviewed_collaboration_capability(
		str(_collaboration_visual.pose_set), str(_collaboration_visual.work_facing),
		str(_collaboration_visual.collaboration_capability_revision)).is_empty()

func _uses_collaboration_handoff() -> bool:
	return _collaboration_handoff_active and _collaboration_contact_current()

func _seat_visual_capability_current() -> bool:
	if _workstation_visual.is_empty(): return false
	var pose_set := str(_workstation_visual.get("pose_set", ""))
	var facing := str(_workstation_visual.get("work_facing", ""))
	return CharacterArt.supports_work_pose(employee_id, pose_set, facing, "seated")

func _seat_state_handoff_admitted() -> bool:
	var handoff: Variant = _workstation_visual.get("seat_state_handoff", {})
	if not handoff is Dictionary or handoff.is_empty() or not _seat_visual_capability_current(): return false
	var pose_set := str(_workstation_visual.get("pose_set", ""))
	if OS.has_feature("editor") and CharacterArt.calibration_pose_belongs_to(pose_set, int(_workstation_visual.get("calibration_owner_id", 0))): return true
	return CharacterArt.reviewed_workstation_option_admitted(pose_set, str(_workstation_visual.get("work_facing", "")), str(_workstation_visual.get("workstation_capability_revision", "")), "seat_state_handoff", handoff)

func _clear_invalid_seat_handoff() -> void:
	if _seat_state_handoff_admitted(): return
	_terminal_seat_rest = false
	_seat_handoff_active = false

func _uses_seated_thinking() -> bool:
	if work_state != WorkState.WORKING or _activity != &"thinking" or not has_live_job: return false
	if _has_target or not is_at_desk() or _workstation_visual.is_empty(): return false
	return CharacterArt.workstation_thinking_reuses_seated(employee_id, str(_workstation_visual.pose_set), str(_workstation_visual.work_facing), str(_workstation_visual.get("workstation_capability_revision", "")), int(_workstation_visual.get("calibration_owner_id", 0)))

func _uses_calibration_seated_thinking() -> bool:
	return _uses_seated_thinking()

func _sync_seat_transition_target() -> void:
	if not _seat_transition_preview: return
	var target := Vector2.ZERO
	var depth := 0.0
	if _uses_collaboration_visual():
		target = _collaboration_visual.seat_anchor
		depth = float(roundi(Vector2(_collaboration_visual.prop_anchor).y) + int(_collaboration_visual.seat_z_offset) - int(position.y))
	elif _uses_seated_visual():
		target = _workstation_visual.get("seat_anchor", Vector2.ZERO) + _workstation_visual.get("seat_correction", Vector2.ZERO)
		var anchor: Vector2 = _workstation_visual.prop_anchor
		depth = float(roundi(anchor.y) + int(_workstation_visual.seat_z_offset) - int(position.y))
	if target == _seat_transition_to and is_equal_approx(depth, _seat_depth_to): return
	# A single retargetable state machine: repeated worker/style updates cannot
	# allocate Tweens, add signals, or restart an already identical transition.
	_seat_transition_from = _seat_visual_offset
	_seat_transition_to = target
	_seat_depth_from = _seat_visual_depth_bias
	_seat_depth_to = depth
	_seat_transition_elapsed = 0.0
	_seat_transition_active = true
	_seat_transition_serial += 1

func _advance_seat_transition(delta: float) -> void:
	_sync_seat_transition_target()
	if not _seat_transition_preview or not _seat_transition_active or world_paused: return
	_seat_transition_elapsed = minf(_seat_transition_duration, _seat_transition_elapsed + maxf(delta, 0.0))
	var progress := clampf(_seat_transition_elapsed / _seat_transition_duration, 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	_seat_visual_offset = _seat_transition_from.lerp(_seat_transition_to, eased)
	_seat_visual_depth_bias = lerpf(_seat_depth_from, _seat_depth_to, eased)
	if progress >= 1.0:
		_seat_transition_active = false
		_seat_visual_offset = _seat_transition_to
		_seat_visual_depth_bias = _seat_depth_to

func _sync_render_transform() -> void:
	_clear_invalid_seat_handoff()
	_sync_seat_transition_target()
	var offset := seated_render_offset()
	var snapped := position.round() - position
	_character_sprite.position = Vector2(0, -32) + offset + snapped
	_effect_sprite.position = work_vfx_position() - position
	z_index = int(position.y)
	var collaboration := _uses_collaboration_visual() or _uses_collaboration_handoff()
	var seat_visual: Dictionary = _collaboration_visual if collaboration else _workstation_visual
	if collaboration:
		z_index = roundi(Vector2(seat_visual.prop_anchor).y) + int(seat_visual.seat_z_offset)
	elif _seat_transition_preview:
		z_index += roundi(_seat_visual_depth_bias)
	elif _uses_seated_visual():
		var anchor: Vector2 = _workstation_visual.prop_anchor
		z_index = roundi(anchor.y) + int(_workstation_visual.seat_z_offset)
	# A dormant collaboration seat owns its own validated prop-relative depth.
	# Do not let the employee's unrelated workstation lock overwrite that depth
	# merely because workstation metadata remains cached while they are at lunch.
	if not collaboration and bool(_workstation_visual.get("seat_pose_depth_lock", false)):
		# Calibration pose ordering is discrete: a seated torso may never tween
		# through a chair/table depth. XY still eases; locomotion sorts by feet.
		if _uses_seated_visual():
			z_index = roundi(Vector2(_workstation_visual.prop_anchor).y) + int(_workstation_visual.seat_z_offset)
		elif _seat_handoff_active:
			var handoff_depths: Dictionary = _workstation_visual.seat_layer_z_offsets
			z_index = roundi(Vector2(_workstation_visual.prop_anchor).y) + int(handoff_depths.lower)
		else:
			z_index = int(position.y)
	for part: Dictionary in _active_work_pose_layers:
		var layer: Sprite2D = _work_pose_layer_sprites[str(part.name)]
		# Source-region offsets are top-left positions within the unchanged cell.
		# Never center a47px/33px region: that would invent half-pixel origins.
		layer.position = Vector2(-24, -72) + offset + snapped + Vector2(part.offset)
		var depths: Dictionary = seat_visual.seat_layer_z_offsets
		layer.z_index = z_index + int(depths[str(part.name)]) - int(seat_visual.seat_z_offset)
	if _label_layer != null: _label_layer.position = render_position() - position
	_sync_work_shadow(offset, snapped)

func _sync_work_shadow(seat_offset: Vector2, snapped: Vector2) -> void:
	if _uses_collaboration_visual() or _uses_collaboration_handoff():
		# The chair anchor can lift the body, but its floor shadow only follows
		# horizontal registration and remains beneath every chair/body layer.
		_shadow_sprite.position = Vector2(seat_offset.x, -2) + snapped
		_shadow_sprite.z_as_relative = false
		_shadow_sprite.z_index = roundi(Vector2(_collaboration_visual.prop_anchor).y) + int(_collaboration_visual.ground_shadow_z_offset)
		return
	if not bool(_workstation_visual.get("grounded_work_shadow", false)):
		# Exact old path for every shipped/legacy profile, including profiles
		# with synthetic seat anchors used by existing regression tests.
		_shadow_sprite.position = Vector2(0, -2) + seat_offset + snapped
		_shadow_sprite.z_as_relative = true
		_shadow_sprite.z_index = 0
		return
	# Ground projection never inherits vertical seat lift. Horizontal seating
	# alignment is a separately admitted policy below; source/alpha stay intact.
	_shadow_sprite.position = Vector2(0, -2) + snapped
	_shadow_sprite.z_as_relative = false
	_shadow_sprite.z_index = int(position.y)
	var pose_set := str(_workstation_visual.get("pose_set", ""))
	var facing := str(_workstation_visual.get("work_facing", ""))
	var pose := "typing" if work_state == WorkState.TYPING else "thinking" if _uses_seated_thinking() else "seated"
	var production := CharacterArt.reviewed_workstation_option_admitted(pose_set, facing, str(_workstation_visual.get("workstation_capability_revision", "")), "grounded_work_shadow", true)
	var calibration := OS.has_feature("editor") and CharacterArt.calibration_pose_belongs_to(pose_set, int(_workstation_visual.get("calibration_owner_id", 0)))
	if (not calibration and not production) or not CharacterArt.supports_work_pose(employee_id, pose_set, facing, pose):
		return # Revoked/missing pose: ordinary physical-floor depth, no stale seat.
	if _uses_seated_visual() or _seat_transition_active:
		_shadow_sprite.z_index = roundi(Vector2(_workstation_visual.prop_anchor).y) + int(_workstation_visual.ground_shadow_z_offset)
		if bool(_workstation_visual.get("grounded_work_shadow_follow_seat_x", false)):
			# Horizontal seat placement is on the floor plane. Follow the same
			# snapped X interpolation as the body; vertical seat lift never
			# becomes a floor-shadow Y offset. This second policy is opt-in.
			_shadow_sprite.position.x += seat_offset.x

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
	var leaving_collaboration := _uses_collaboration_visual()
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
		if has_studio_project:
			walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.SITTING)
			return
		if leaving_collaboration:
			walk_to(desk_position, WorkState.IDLE_WALKING, WorkState.SITTING)
			return
		work_state = WorkState.IDLE
		_has_target = false
		_waiting_for_desk = false
		_route_requires_desk = false
		_idle_cooldown = 0.5
		_update_character_frame()
		queue_redraw()

func set_studio_project(active: bool) -> void:
	# This is a read-only projection of the worker's assigned product team.
	# Offline studio work uses the seated pose, never fake provider/tool events.
	if has_studio_project == active: return
	has_studio_project = active
	_idle_elapsed = 0.0
	if active and schedule_phase == "work" and not has_live_job:
		_speech_visible = false
		walk_to(desk_position, WorkState.WALKING_TO_DESK, WorkState.SITTING)

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
					_terminal_seat_rest = false
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
			var keep_seated_rest := _uses_seated_visual() and _seat_state_handoff_admitted()
			if navigation != null: navigation.release(employee_id)
			has_live_job = false
			_set_activity(&"failure", 1.2)
			_status_override = "work stopped"
			work_state = WorkState.IDLE
			_has_target = false
			_waiting_for_desk = false
			_route_requires_desk = false
			_route.clear()
			_terminal_seat_rest = keep_seated_rest
			_seat_handoff_active = false
			_idle_elapsed = 0.0
			_idle_cooldown = 2.0
			_speech_visible = false
			_hold_label(1.8)
			queue_redraw()
			if schedule_phase != "work":
				set_schedule_phase(schedule_phase)
	_update_character_frame()

func walk_to(target: Vector2, state: WorkState, arrival_state: WorkState = WorkState.IDLE) -> void:
	_clear_invalid_seat_handoff()
	var was_seated := _uses_seated_visual()
	if _uses_collaboration_visual():
		_collaboration_handoff_active = true
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
	# Face the first physical step, not the final destination. Around furniture
	# those directions often differ; using the destination caused a one-frame
	# front-facing flash before the actual side-step away from a chair.
	var facing_target := target
	for waypoint: Vector2 in _route:
		if waypoint.distance_to(position) > 0.5:
			facing_target = waypoint
			break
	var travel := facing_target - position
	if not travel.is_zero_approx():
		_facing = _direction_name(travel)
	else:
		_route.clear()
		_target_position = target
		_requested_target = target
		_has_target = false
		work_state = arrival_state
		_terminal_seat_rest = false
		_seat_handoff_active = false
		_idle_elapsed = 0.0
		_animation_elapsed = 0.0
		_update_character_frame()
		_hold_label()
		queue_redraw()
		return
	_target_position = target
	_arrival_state = arrival_state
	_has_target = true
	_collaboration_seat_rest = false
	if was_seated and _seat_state_handoff_admitted() and target.distance_to(desk_position) > 0.5:
		_seat_handoff_active = true
		_seat_handoff_origin = desk_position
	_terminal_seat_rest = false
	work_state = state
	_animation_elapsed = 0.0
	_update_character_frame()
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
	_update_character_frame()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _character_sprite == null or _shadow_sprite == null or _effect_sprite == null:
		return
	_advance_seat_transition(delta)
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
		if _arrival_state == WorkState.LUNCH and _collaboration_contact_current():
			_collaboration_handoff_active = true
		if not _collaboration_contact_current():
			_collaboration_handoff_active = false
		# The same authored chair/desk depth sandwich protects the final inbound
		# approach. This removes the standing torso-through-chair frame immediately
		# before the seated source takes over, without moving physical feet.
		if _route_requires_desk and _seat_state_handoff_admitted():
			var approach_clearance := float(_workstation_visual.seat_state_handoff.clearance_pixels)
			if position.distance_to(desk_position) < approach_clearance:
				_seat_handoff_active = true
				_seat_handoff_origin = desk_position
		if _seat_handoff_active:
			var handoff: Dictionary = _workstation_visual.seat_state_handoff
			if position.distance_to(_seat_handoff_origin) >= float(handoff.clearance_pixels):
				_seat_handoff_active = false
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
			if _route_requires_desk: _seat_handoff_active = false
			work_state = _arrival_state
			_idle_elapsed = 0.0
			_animation_elapsed = 0.0
			_hold_label()
			if work_state == WorkState.IDLE and not has_live_job and schedule_phase != "work":
				set_schedule_phase(schedule_phase)
			queue_redraw()
	_update_character_frame()
	if navigation != null: navigation.actors[employee_id] = position
	if not world_paused and not has_live_job and schedule_phase == "work" and not _has_target:
		_update_idle(delta)

func _update_idle(delta: float) -> void:
	if _terminal_seat_rest:
		return
	if has_studio_project and work_state == WorkState.SITTING:
		return
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
	var offset := world_position.round() - render_position()
	if _callout_offset == offset: return
	_callout_offset = offset
	queue_redraw()

func has_attention() -> bool:
	# Once projected, business state owns attention. An answered approval can
	# leave its physical pose pending until the next worker event arrives.
	if not _ui_presentation_state.is_empty():
		return _ui_presentation_state in ["needs approval", "delivery ready", "needs retry", "cancelled"]
	return work_state == WorkState.WAITING_APPROVAL

func attention_cue_visible() -> bool:
	# A selected decision/delivery needs a legible cue even when the event burst
	# is held on its nearly-empty first frame. Its animation remains untouched.
	return has_attention() and (_drawer_selected or _effect_sprite == null or not _effect_sprite.visible) and not _labels_visible()

func _sync_attention_presentation() -> void:
	if _effect_sprite == null: return
	# Only paint ownership changes. Do not toggle visible: it controls the
	# event animation timer/expiry in _physics_process, even during a UI pause.
	var stale_approval := _activity == &"approval" and not _ui_presentation_state.is_empty() and _ui_presentation_state != "needs approval"
	_effect_sprite.self_modulate.a = 0.0 if stale_approval or (_drawer_selected and has_attention()) else 1.0

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
	var label := state_label()
	return label.left(1).to_upper() + label.substr(1)

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
	return Rect2(render_position() + local.position, local.size)

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
	# A genuine new state owns the status line. In particular, a new job must
	# never keep "Work stopped" indefinitely after replacing the timed failure
	# effect with a non-expiring thinking or typing cue.
	if kind != &"failure": _status_override = ""
	_activity = kind
	_effect_elapsed = 0.0
	_effect_duration = duration
	_effect_sprite.visible = not kind.is_empty()
	if _effect_sprite.visible:
		_effect_sprite.region_rect = PolishArt.effect_region(kind, 0)
	# A new real event takes paint ownership back from a superseded decision.
	_sync_attention_presentation()
	_hold_label()

func _update_character_frame() -> void:
	if _character_sprite == null:
		return
	_clear_work_pose_layers()
	var walking := _has_target
	var shadow_kind := 1 if walking else 0
	if not walking and _uses_collaboration_visual():
		_collaboration_seat_rest = true
		_set_directional_work_pose("seated", int(_animation_elapsed * 1.5), _collaboration_visual)
		shadow_kind = 2
	elif not walking and _terminal_seat_rest and _seat_state_handoff_admitted():
		_set_directional_work_pose("seated", int(_animation_elapsed * 1.5), _workstation_visual)
		shadow_kind = 2
	elif not walking and work_state == WorkState.SITTING:
		_set_directional_work_pose("seated", int(_animation_elapsed * 1.5), _workstation_visual)
		shadow_kind = 2
	elif not walking and work_state == WorkState.TYPING:
		_set_directional_work_pose("typing", int(_animation_elapsed * 8.0), _workstation_visual)
		shadow_kind = 2
	elif not walking and work_state == WorkState.WAITING_APPROVAL:
		# Approval is a free-standing visit to the founder, not a seated pose.
		_set_directional_work_pose("approval", int(_animation_elapsed * 2.0), {})
	elif not walking and work_state == WorkState.WORKING:
		if _activity == &"research":
			_set_directional_work_pose("research", int(_animation_elapsed * 6.0), _research_visual)
		else:
			var station := _research_visual if position.distance_to(research_position) <= 0.5 and not is_at_desk() else _workstation_visual
			var seated_thinking := _uses_seated_thinking()
			_set_directional_work_pose("thinking", int(_animation_elapsed * (1.5 if seated_thinking else 4.0)), station)
			if seated_thinking: shadow_kind = 2
	elif work_state == WorkState.DELIVERING:
		_set_delivery_frame(int(_animation_elapsed * 8.0) % 4)
	else:
		# A lunch stop without the exact reviewed collaboration capability remains
		# honestly standing; no generic target is allowed to imply a seat.
		_character_sprite.texture = CharacterArt.locomotion_sheet(employee_id)
		var frame := 2 + int(_animation_elapsed * 8.0) % 4 if walking else int(_animation_elapsed * 1.5) % 2
		_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, frame)
	if _uses_collaboration_handoff() and not _uses_collaboration_visual():
		# Preserve the original locomotion cell while passing through the chair.
		# Its lower body stays behind the near furniture edge, and the upper body
		# keeps the same depth as the seated torso until the feet clear the seat.
		var region := _character_sprite.region_rect
		_show_work_pose_layers({"texture": _character_sprite.texture, "layers": [
			{"name": "upper", "region": Rect2(region.position, Vector2(48, 48)), "offset": Vector2.ZERO},
			{"name": "lower", "region": Rect2(region.position + Vector2(0, 48), Vector2(48, 32)), "offset": Vector2(0, 48)},
		]}, _collaboration_visual)
	_shadow_sprite.region_rect = PolishArt.shadow_region(shadow_kind)
	_sync_render_transform()

func _set_directional_work_pose(pose: String, frame: int, metadata: Dictionary) -> void:
	var facing := str(metadata.get("work_facing", "south"))
	var pose_set := str(metadata.get("pose_set", CharacterArt.LEGACY_WORK_POSE_SET))
	var authored := CharacterArt.work_pose_frame(employee_id, pose_set, facing, pose, frame)
	if authored.get("presentation") == "quiet_seated_thinking" and not _uses_seated_thinking():
		authored = {} # No idle-reuse body outside its live, stationary desk state.
	if authored.is_empty():
		# A missing work pose stays visibly standing; never pass off a rotated,
		# mirrored or unrelated south-facing seated sprite as authored support.
		var direction: StringName = {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}.get(facing, &"front")
		_character_sprite.texture = CharacterArt.locomotion_sheet(employee_id)
		_character_sprite.region_rect = CharacterArt.locomotion_region(direction, 0)
		return
	_character_sprite.texture = authored.texture
	_character_sprite.region_rect = authored.region
	if authored.has("layers") and pose in ["seated", "typing", "thinking"] and (_uses_seated_visual() or _uses_collaboration_visual()):
		_show_work_pose_layers(authored, metadata)

func _show_work_pose_layers(authored: Dictionary, metadata: Dictionary) -> void:
	var depths: Variant = metadata.get("seat_layer_z_offsets")
	if not depths is Dictionary: return
	for part: Dictionary in authored.layers:
		if not depths.has(str(part.name)): return
	_active_work_pose_layers.assign(authored.layers)
	for part: Dictionary in _active_work_pose_layers:
		var part_name := str(part.name)
		var layer: Sprite2D = _work_pose_layer_sprites.get(part_name)
		if layer == null:
			layer = Sprite2D.new()
			layer.name = "WorkPose" + part_name.capitalize()
			layer.centered = false
			layer.region_enabled = true
			layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			layer.z_as_relative = false
			add_child(layer)
			_work_pose_layer_sprites[part_name] = layer
		layer.texture = authored.texture
		layer.region_rect = part.region
		layer.show()
	_character_sprite.hide()

func _clear_work_pose_layers() -> void:
	_active_work_pose_layers.clear()
	for layer: Sprite2D in _work_pose_layer_sprites.values(): layer.hide()
	if _character_sprite != null: _character_sprite.show()

func _set_work_frame(row: int, column: int) -> void:
	_character_sprite.texture = CharacterArt.work_sheet(employee_id)
	_character_sprite.region_rect = CharacterArt.work_region(row, column)

func _set_seated_frame(column: int) -> void:
	_character_sprite.texture = CharacterArt.seated_sheet(employee_id)
	_character_sprite.region_rect = Rect2(Vector2(column * 48, 0), CharacterArt.FRAME_SIZE)

func _set_delivery_frame(frame: int) -> void:
	if not CharacterArt.has_work_sheet(employee_id):
		_character_sprite.texture = CharacterArt.locomotion_sheet(employee_id)
		_character_sprite.region_rect = CharacterArt.locomotion_region(_facing, 2 + frame)
		return
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
