extends SceneTree
## Portrait identity must follow the same character shown in the office.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var portrait := CharacterArt.portrait("creative")
	var bust := CharacterArt.bust_portrait("creative")
	check(portrait.atlas == CharacterArt.locomotion_sheet("creative"), "Creative's full portrait uses their own office character")
	check(bust.atlas == portrait.atlas, "Creative's team bust does not fall back to Founder")
	check(portrait.region == Rect2(Vector2.ZERO, CharacterArt.FRAME_SIZE), "Full portrait uses exactly the front-idle frame")
	check(portrait.region.encloses(bust.region) and bust.region.encloses(CharacterArt.CHAT_FACE_REGION), "Bust retains the complete face inside one native frame")
	check(bust.filter_clip and portrait.filter_clip, "Atlas portraits do not bleed adjacent animation frames")
	for id: String in ["founder", "mira", "theo"]:
		var existing := CharacterArt.portrait(id)
		check(existing.atlas == CharacterArt.CHARACTER_SHEET and existing.region == CharacterArt.PORTRAIT_REGIONS[id], id + " keeps its authored concept portrait")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var main := load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(FIXTURE.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	main.job_panel.set_worker_ready()
	main.job_panel.open_chat_for_employee("creative")
	main.job_panel.open_drawer(false)
	for i: int in range(8): await process_frame
	check((main.job_panel._employee_portrait.texture as AtlasTexture).atlas == portrait.atlas, "Actual Creative drawer shows the correct identity")
	var found := false
	for image: TextureRect in main.job_panel._team_buttons["creative"].find_children("*", "TextureRect", true, false):
		if image.texture is AtlasTexture and (image.texture as AtlasTexture).atlas == portrait.atlas: found = true
	check(found, "Actual Creative team card shows the correct identity")
	var output := OS.get_environment("STARTUP_VALLEY_PORTRAIT_CAPTURE")
	if not output.is_empty() and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		check(root.get_texture().get_image().save_png(output) == OK, "Portrait review capture is saved")
	main.game_audio.shutdown()
	main.free()
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
	for i: int in range(3): await process_frame
	print("Character portraits: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
