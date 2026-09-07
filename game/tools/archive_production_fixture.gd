extends Node
## DEV-ONLY transport isolation around the actual unmodified production room,
## catalogue, roster placement and interfaces. No calibration art authorization.
const TRANSPORT := preload("res://tools/calibrated_workstation_fixture.gd")
const SERVICE_FIXTURE := preload("res://tools/calibrated_service_fixture.gd")
var main: GameMain
var editor: Node2D
var hires := 2
var show_editor := false
var ready_ok := false
var errors: Array[String] = []
var previous_no_worker := ""

class ProductionEditor extends "res://tools/calibrated_service_fixture.gd".ServiceEditor:
	func _build_interface() -> void:
		super._build_interface()
		_status.text = "PRODUCTION ARCHIVE REVIEW · no worker or saves · Move/R previews, click commits, Esc cancels."
	func _set_status(message: String, valid: bool) -> void:
		super._set_status(message, valid)
		if _status != null:
			_status.text = "PRODUCTION REVIEW · " + "\n".join(message.split("\n").slice(0, 2))

func _ready() -> void:
	if not OS.has_feature("editor"):
		errors.append("Production review fixture requires editor-capable Godot")
		return
	previous_no_worker = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(TRANSPORT.NullWorker)
	add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	main._state_loaded = false
	main._worker_ready = false
	main.job_panel.set_worker_ready()
	main.founder_hud.dismiss_movement_hint()
	# Reconcile the ordinary authored roster; no room/catalogue replacement.
	var records := main.room.placeholder_records()
	records.resize(mini(hires, records.size()))
	main._spawn_employees(records)
	if hires > records.size(): main.room.set_hire_count(hires)
	main.job_panel.close_drawer(false)
	main.company_panel.hide()
	var validation := main.room.layout_model.validate_placements(main.room.resolved_placements)
	if not validation.valid: errors.assign(validation.errors)
	if show_editor:
		editor = ProductionEditor.new()
		editor.game = main
		add_child(editor)
		editor.select_placement("artifact-archive")
	ready_ok = errors.is_empty()

func leave_desk(_id: String = "") -> void:
	main.job_panel.close_drawer(false)
	main.player.input_blocked = false
	main.player.move_to(main.room.layout_model.world(main.room.player_spawn))

func send_to_desk(_id: String, _typing := false) -> void:
	pass # Hidden development buttons; service props never invent work poses.

func place_editor_labels() -> void:
	if not is_instance_valid(editor): return
	# The optional dev toolbar is not a production HUD component. Include its
	# actual paper bounds in the existing callout placement solver, without
	# moving actors or changing any normal-room UI behavior when it is absent.
	var blocked := main._world_ui_obstacles()
	blocked.append((editor._inspector.get_parent() as Control).get_global_rect())
	blocked.append(WorldCalloutSkin.actor_rect(main.player.position))
	for actor: EmployeeAvatar in main._employees.values(): blocked.append(WorldCalloutSkin.actor_rect(actor.render_position()))
	for actor: EmployeeAvatar in main._employees.values():
		var candidate := WorldCalloutSkin.place(actor.render_position(), actor.world_label_body_rect().size, blocked, Rect2(18, 82, 1114, 620), actor._speech_visible or actor.attention_cue_visible())
		actor.labels_suppressed = not candidate.has_area()
		if candidate.has_area():
			actor.set_callout_position(candidate.position)
			if actor._labels_visible(): blocked.append(actor.world_label_rect())

func _exit_tree() -> void:
	if is_instance_valid(main): main.game_audio.shutdown()
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", previous_no_worker)
