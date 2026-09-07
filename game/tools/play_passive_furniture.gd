extends SceneTree
## Explicit dev-only showroom. Its local candidate placements cannot be saved.
const FIXTURE := preload("res://tools/passive_furniture_fixture.gd")
var fixture: Node
var label_layout_ticks := 0
var label_redraw_ticks := 0
var smoke_checks := 0
var smoke_failures: Array[String] = []
var smoke_samples: Array[Dictionary] = []
var late_layout: Node
var controls_completed := false
const SMOKE_OUTPUT := "res://tests/output/passive-showroom/"

class LateLabelLayout extends Node:
	var layout: Callable
	func _process(_delta: float) -> void:
		if layout.is_valid(): layout.call()

func smoke_check(ok: bool, message: String) -> void:
	smoke_checks += 1
	if not ok:
		smoke_failures.append(message)
		push_error(message)

func _late_editor_labels() -> void:
	if not is_instance_valid(fixture) or not fixture.ready_ok: return
	label_layout_ticks += 1
	fixture.place_editor_labels()
	# The inherited helper changes suppression directly. A suppressed label has
	# no new position to invalidate its cached CanvasItem, so clear that cache
	# explicitly after the main scene's layout, including stationary frames.
	for actor: EmployeeAvatar in fixture.main._employees.values():
		actor._label_layer.queue_redraw()
		label_redraw_ticks += 1

func _check_smoke_labels(phase: String) -> void:
	var toolbar := (fixture.editor._inspector.get_parent() as Control).get_global_rect()
	var sample := {"phase": phase, "toolbar": str(toolbar), "labels": []}
	for actor: EmployeeAvatar in fixture.main._employees.values():
		var painted: Rect2 = actor.world_label_rect()
		var shown := not actor.labels_suppressed and (actor._labels_visible() or actor._speech_visible or actor.attention_cue_visible())
		smoke_check(not shown or not painted.intersects(toolbar), phase + ": complete " + actor.employee_id + " paper/pointer avoids toolbar")
		sample.labels.append({"employee": actor.employee_id, "shown": shown, "suppressed": actor.labels_suppressed, "painted": str(painted)})
	smoke_samples.append(sample)

func _capture_smoke(phase: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	_check_smoke_labels("rendered-" + phase)
	smoke_check(root.get_texture().get_image().save_png(SMOKE_OUTPUT + "smoke-after-" + phase + ".png") == OK, "Save native " + phase + " preview")

func _smoke_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _check_smoke_controls() -> void:
	root.gui_release_focus()
	var start: Vector2 = fixture.main.player.position
	await _smoke_key(KEY_RIGHT, true)
	smoke_check(Input.is_action_pressed("move_right"), "Arrow event reaches existing movement action")
	for tick: int in range(3):
		fixture.main.player._physics_process(1.0 / 30.0)
		await process_frame
	await _smoke_key(KEY_RIGHT, false)
	smoke_check(fixture.main.player.position.x > start.x, "Real arrow input still moves founder")
	await _smoke_key(KEY_M, true)
	await _smoke_key(KEY_M, false)
	smoke_check(fixture.editor.placement_active, "M opens existing move preview")
	var before: String = fixture.editor.preview_facing
	await _smoke_key(KEY_R, true)
	await _smoke_key(KEY_R, false)
	smoke_check(fixture.editor.preview_facing != before, "R cycles actual authored preview facing")
	await _smoke_key(KEY_ESCAPE, true)
	await _smoke_key(KEY_ESCAPE, false)
	smoke_check(not fixture.editor.placement_active, "Escape cancels local preview")
	var prior: Dictionary = fixture.main.room.placement_overrides.duplicate(true)
	await _smoke_key(KEY_U, true)
	await _smoke_key(KEY_U, false)
	smoke_check(fixture.main.room.placement_overrides == prior, "U with empty history does not mutate placements")
	controls_completed = true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var smoke := OS.get_cmdline_user_args().has("--smoke-test")
	if DisplayServer.get_name() == "headless" and not smoke:
		push_error("The interactive showroom needs a window; use --smoke-test for headless verification.")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.title = "Startup Valley — furniture showroom (no worker or saves)"
	fixture = FIXTURE.new()
	fixture.hires = 4
	root.add_child(fixture)
	if not fixture.ready_ok:
		push_error(str(fixture.errors))
		fixture.free()
		fixture = null
		quit(1)
		return
	late_layout = LateLabelLayout.new()
	late_layout.name = "ShowroomLateLabelLayout"
	late_layout.process_priority = 10000
	late_layout.layout = _late_editor_labels
	root.add_child(late_layout)
	if smoke:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SMOKE_OUTPUT))
		for tick: int in range(3): await process_frame
		_check_smoke_labels("initial")
		await _capture_smoke("initial")
		for tick: int in range(9): await process_frame
		_check_smoke_labels("settled")
		await _capture_smoke("settled")
		for tick: int in range(18): await process_frame
		_check_smoke_labels("ongoing")
		var model: OfficeLayout = fixture.model
		var isolated: bool = fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1
		var ready: bool = model.calibration_preview_enabled() and fixture.editor.selected_id == "dev-whiteboard" and label_layout_ticks >= 29 and label_redraw_ticks >= label_layout_ticks * 2
		smoke_check(isolated, "No worker transport or process")
		smoke_check(ready, "Local permit, selection, ongoing late layout and redraw are ready")
		var output := SMOKE_OUTPUT
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			await RenderingServer.frame_post_draw
			_check_smoke_labels("rendered")
			smoke_check(root.get_texture().get_image().save_png(output + "smoke-after.png") == OK, "Save settled native corrected preview")
		await _check_smoke_controls()
		smoke_check(controls_completed, "Every requested input smoke stage completed")
		late_layout.free()
		late_layout = null
		fixture.free()
		fixture = null
		for tick: int in range(3): await process_frame
		var revoked := not model.calibration_preview_enabled()
		smoke_check(revoked, "Local candidate admission revoked after closing preview")
		var file := FileAccess.open(output + ("smoke-headless.json" if DisplayServer.get_name() == "headless" else "smoke-native.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks": smoke_checks, "failures": smoke_failures, "samples": smoke_samples, "layout_ticks": label_layout_ticks, "redraw_ticks": label_redraw_ticks, "isolated": isolated, "ready": ready, "permit_revoked": revoked}, "  "))
		file.close()
		print("Passive showroom smoke: %d checks / %d failures; isolated=%s ready=%s permit_revoked=%s" % [smoke_checks, smoke_failures.size(), isolated, ready, revoked])
		quit(0 if smoke_failures.is_empty() else 1)
