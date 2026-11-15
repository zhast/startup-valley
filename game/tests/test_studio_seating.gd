extends SceneTree
## Exercises project-team projection in the shipped room, not provider events.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func reach_seat(actor: EmployeeAvatar) -> void:
	for i: int in range(900):
		await physics_frame
		if actor.is_at_desk() and actor.work_state == EmployeeAvatar.WorkState.SITTING: return
	check(false, "Assigned teammate reaches their real desk seat")

func run() -> void:
	var main := load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(FIXTURE.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	var mina := main.get_employee("mira")
	main._on_journey({"tycoon": {"developing": {"staffIds": ["founder", "mira"]}}})
	check(mina.has_studio_project, "Worker's project roster assigns Mina")
	check(not main.get_employee("theo").has_studio_project, "Unassigned teammates keep their normal routine")
	check(not mina.has_live_job, "Offline project never masquerades as a provider job")
	await reach_seat(mina)
	check(mina._uses_seated_visual(), "Real desk admission uses the seated character layers")
	mina._update_idle(9.0)
	check(not mina._has_target and mina.work_state == EmployeeAvatar.WorkState.SITTING, "Assigned teammate stays seated beyond normal idle-wander timeout")
	mina.set_schedule_phase("lunch")
	check(mina.work_state == EmployeeAvatar.WorkState.LUNCH and mina._has_target, "Lunch still sends the teammate away from the desk")
	mina.set_schedule_phase("work")
	await reach_seat(mina)
	check(mina._uses_seated_visual(), "Teammate returns to the real seat after lunch")
	main._on_journey({"tycoon": {"developing": null}})
	check(not mina.has_studio_project, "Releasing or cancelling a project releases its assignment")
	mina._update_idle(9.0)
	check(mina._has_target and mina.work_state == EmployeeAvatar.WorkState.WANDERING, "Unassigned teammate resumes ordinary idle routine")
	main.game_audio.shutdown()
	main.free()
	print("Studio seating: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
