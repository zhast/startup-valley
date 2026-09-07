extends SceneTree
## Native production-room proof for all research-bench views and both employees.

const OUTPUT := "res://tests/output/research-bench-production"
const G := preload("res://tools/research_bench_geometry.gd")
var main: GameMain
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count := 2) -> void:
	for _i: int in range(count): await process_frame

func pose(actor: EmployeeAvatar) -> void:
	actor.world_paused = false
	actor.has_live_job = true
	var event := WorkerEventRecord.new(); event.type = &"tool.started"; event.tool = "web_search"
	actor.apply_worker_event(event, main.player.position)
	actor.position = actor.research_position
	actor._has_target = false
	actor.work_state = EmployeeAvatar.WorkState.WORKING
	actor._update_character_frame()

func common_pivot() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for y: int in range(4, main.room.layout_model.height - 2):
		for x: int in range(2, main.room.layout_model.width - 2):
			var candidate := Vector2i(x, y); var valid := true
			for side: String in OfficeLayout.FACINGS:
				if not main.room.layout_model.validate_candidate("research-bench", candidate, side, 2).valid: valid = false; break
			if valid and candidate.distance_squared_to(Vector2i(29, 8)) < best_distance:
				best = candidate; best_distance = candidate.distance_squared_to(Vector2i(29, 8))
	return best

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main); await frames(5)
	main.day_clock.set_speed(0); main.game_audio.set_volumes(0, 0); main.founder_hud.dismiss_movement_hint(); main.job_panel.close_drawer(false); main.company_panel.hide(); main.room.set_hire_count(2)
	var pivot := common_pivot(); check(pivot.x >= 0, "Common four-facing production pivot exists")
	var contact := Image.create(G.CANVAS.x * 2, G.CANVAS.y * 4, false, Image.FORMAT_RGBA8); contact.fill(Color("151515"))
	for index: int in range(OfficeLayout.FACINGS.size()):
		var side := OfficeLayout.FACINGS[index]
		check(main.room.set_placement_overrides({"research-bench": {"grid": [pivot.x, pivot.y], "facing": side}}), side + " placement commits")
		main._on_room_placements_changed(); await frames(3)
		var placement := main.room.placement_by_id("research-bench")
		check(placement.facing == side and main.room.navigation.walkable(placement.interaction), side + " profile and interaction")
		for employee_id: String in ["mira", "theo"]:
			var actor := main.get_employee(employee_id)
			check(actor != null and actor.configure_research_visual(main.room.research_visual()), employee_id + " accepts " + side + " research pose")
		for employee_id: String in ["mira", "theo"]:
			for id: String in ["mira", "theo"]:
				var actor := main.get_employee(id); actor.visible = id == employee_id; actor.labels_suppressed = true; actor._speech_visible = false; actor._label_hold = 0
			var active := main.get_employee(employee_id); pose(active); active._animation_elapsed = 0.22; active._update_character_frame()
			await frames(2); await RenderingServer.frame_post_draw
			var frame_a := root.get_texture().get_image(); var path_a := OUTPUT.path_join(side + "-" + employee_id + "-a.png")
			check(frame_a.save_png(path_a) == OK, "Save " + side + " " + employee_id + " A")
			active._animation_elapsed = 0.55; active._update_character_frame(); await frames(1); await RenderingServer.frame_post_draw
			var frame_b := root.get_texture().get_image(); var path_b := OUTPUT.path_join(side + "-" + employee_id + "-b.png")
			check(frame_b.save_png(path_b) == OK, "Save " + side + " " + employee_id + " B")
			var origin := Vector2i(placement.anchor) - G.PIVOT
			var detail_a := frame_a.get_region(Rect2i(origin, G.CANVAS)); var detail_b := frame_b.get_region(Rect2i(origin, G.CANVAS))
			check(detail_a.get_data() != detail_b.get_data(), side + " " + employee_id + " sampled research frames differ")
			contact.blit_rect(detail_a, Rect2i(Vector2i.ZERO, G.CANVAS), Vector2i(0 if employee_id == "mira" else G.CANVAS.x, index * G.CANVAS.y))
	check(contact.save_png(OUTPUT.path_join("four-facing-contact-sheet.png")) == OK, "Save contact sheet")
	var file := FileAccess.open(OUTPUT.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "worker_disabled": true, "production_registered": true}, "\t") + "\n")
	main.game_audio.shutdown(); main.queue_free(); await frames(); print("Research bench production capture: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
