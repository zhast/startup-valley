extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func closed_time(id: String) -> float:
	for step: int in range(400):
		var time := float(step) / 100.0
		if IdleBlink.frame(time, id) == 1: return time + 0.02
	return -1

func verify_eye_pixels() -> void:
	var before := Image.load_from_file("res://assets/source/blink-polish-v3/mira-locomotion-before.png")
	var after := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/characters/mira-locomotion.png"))
	before.convert(Image.FORMAT_RGBA8)
	after.convert(Image.FORMAT_RGBA8)
	check(after.get_size() == Vector2i(288, 320), "Mina preserves48x80 grid and four facings")
	var changes := 0
	var outside := 0
	var alpha_changes := 0
	for y: int in range(320):
		for x: int in range(288):
			var old := before.get_pixel(x, y)
			var pixel := after.get_pixel(x, y)
			if old.a != pixel.a: alpha_changes += 1
			if old == pixel: continue
			changes += 1
			if not (x >= 48 and x < 96 and y % 80 >= 20 and y % 80 < 34 and int(y / 80) in [0, 2, 3]): outside += 1
	check(changes > 0, "Standing blink actually replaces defective source pixels")
	check(outside == 0, "Open frames, back view, all walks, feet and body stay pixel-identical")
	check(alpha_changes == 0, "Blink never changes silhouette or alpha")
	for eye: Vector2i in [Vector2i(66, 27), Vector2i(75, 27), Vector2i(64, 186), Vector2i(78, 266)]:
		var dark := 0
		var below := 0
		for x: int in range(4):
			var lid := after.get_pixelv(eye + Vector2i(x, 0))
			var skin := after.get_pixelv(eye + Vector2i(x, 1))
			if lid.r < 0.32 and lid.g < 0.30: dark += 1
			if skin.r < 0.32 and skin.g < 0.30: below += 1
		check(dark == 4, "Closed lid is visible at original pupil height: " + str(eye))
		check(below == 0, "No open pupil survives below the closed lid: " + str(eye))
	# These same regions contain lower-pupil ink in the prior defective cells.
	check(before.get_pixel(69, 28).r < 0.32, "Negative control sees the old open pupil")
	var founder_before := Image.load_from_file("res://assets/source/blink-polish-v3/founder-locomotion-before.png")
	var founder := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/characters/founder-locomotion.png"))
	founder_before.convert(Image.FORMAT_RGBA8)
	founder.convert(Image.FORMAT_RGBA8)
	outside = 0
	alpha_changes = 0
	for y: int in range(320):
		for x: int in range(288):
			if founder.get_pixel(x, y).a != founder_before.get_pixel(x, y).a: alpha_changes += 1
			if founder.get_pixel(x, y) == founder_before.get_pixel(x, y): continue
			if not (y >= 24 and y < 30 and (x >= 64 and x < 70 or x >= 75 and x < 81)): outside += 1
	check(outside == 0 and alpha_changes == 0, "Founder changes only two front closed-eye patches with unchanged alpha")
	for start: int in [65, 76]:
		for x: int in range(start, start + 4):
			check(founder.get_pixel(x, 26).r < 0.32, "Founder thin lid remains visible")
			check(founder.get_pixel(x, 27).r > 0.32, "Founder lid has no second dark row")
	check(founder_before.get_pixel(65, 27).r < 0.32, "Negative control sees former thick Founder eyelid")

func run() -> void:
	verify_eye_pixels()
	for id: String in ["founder", "mira", "theo", "creative"]:
		var closed := 0
		var longest := 0
		var streak := 0
		for tick: int in range(1200):
			var frame := IdleBlink.frame(float(tick) / 100.0, id)
			closed += frame
			streak = streak + 1 if frame == 1 else 0
			longest = maxi(longest, streak)
		check(closed >= 33 and closed <= 39, id + " closes for about120ms per4s")
		check(longest <= 13, id + " never holds a long squint")
		check(IdleBlink.frame(0, id) == 0, id + " starts with open eyes")
		check(closed_time(id) >= 0, id + " actually blinks")
	check(closed_time("mira") != closed_time("theo"), "Visitors do not blink in lockstep")
	check(int(1200 / 2) > 39, "Previous50percent-duty cadence fails this contract")
	root.size = Vector2i(1280, 720)
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.player.set_physics_process(false)
	for direction: StringName in [&"front", &"back", &"left", &"right"]:
		main.player._facing = direction
		main.player.input_blocked = true
		main.player._blink_elapsed = closed_time("founder")
		main.player._physics_process(0)
		check(int(main.player._character_sprite.region_rect.position.x / 48) == 1, str(direction) + " blocked founder still displays brief blink")
		main.player._physics_process(0.2)
		check(int(main.player._character_sprite.region_rect.position.x / 48) == 0, str(direction) + " modal cannot freeze founder eyes closed")
	for id: String in ["mira", "theo", "creative"]:
		var actor := EmployeeAvatar.new()
		var record := EmployeeRecord.new()
		record.id = id
		record.display_name = id
		main.add_child(actor)
		actor.configure(record, Vector2(500, 500), Vector2(500, 500), Vector2(600, 500))
		actor.set_physics_process(false)
		for direction: StringName in [&"front", &"back", &"left", &"right"]:
			actor._facing = direction
			for phase: int in range(2):
				actor._blink_elapsed = closed_time(id) if phase else 0
				actor._update_character_frame()
				check(actor._character_sprite.region_rect == CharacterArt.locomotion_region(direction, phase), id + "/" + str(direction) + " shares idle blink cadence")
		actor.free()
	for guest: StoryGuest in [main.arrival_guest, main.courtyard.guest]:
		guest._elapsed = closed_time(guest.person_id)
		guest._process(0)
		check(guest.sprite.region_rect.position.x == 48, guest.person_id + " story visitor closes authored eye frame")
		guest._process(0.2)
		check(guest.sprite.region_rect.position.x == 0, guest.person_id + " story visitor reopens promptly")
	main.room.set_hire_count(2)
	for facing: String in ["north", "east", "south", "west"]:
		check(main.room.set_placement_overrides({"mira-workstation": {"grid": [10, 8], "facing": facing}, "theo-workstation": {"grid": [20, 8], "facing": facing}}), facing + " actual workstation applies")
		main._on_room_placements_changed()
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			actor.set_physics_process(false)
			actor.position = actor.desk_position
			actor._has_target = false
			actor.work_state = EmployeeAvatar.WorkState.SITTING
			for phase: int in range(2):
				actor._blink_elapsed = closed_time(id) if phase else 0
				actor._update_character_frame()
				check(actor._character_sprite.region_rect.position.x == phase * 48, id + "/" + facing + " seated uses short blink phase")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("Idle blink: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
