extends "res://tools/desk_grain_v2_fixture.gd"
## DEV ONLY. Complete North lifecycle candidate using the already-generated,
## source-registered North desk, chair, computer and employee sheets.

func _ready() -> void:
	quiet_grain = true
	employee_ids.assign(["mira", "theo"])
	initial_facing = "north"
	pose_set_prefix = "dev-calibration-complete-north"
	super._ready()

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	if facing == "north":
		# The source chair is a single rear view. Treat it honestly as rear
		# structure rather than painting the complete chair over the employee.
		# Source-aware body partitions then keep legs behind DeskFront while the
		# torso stays above the worksurface and monitor.
		for layer: Dictionary in result.render_layers:
			if str(layer.get("name", "")).begins_with("Chair"):
				layer.z_offset = -2
		result.seat_layer_z_offsets = {"lower": 0, "upper": 3}
	result.grounded_work_shadow = true
	result.grounded_work_shadow_follow_seat_x = true
	result.seat_state_handoff = {"clearance_pixels": 32}
	return result
