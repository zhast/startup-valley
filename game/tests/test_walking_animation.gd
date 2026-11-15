extends SceneTree
## Offline regression: exercise the real physics callbacks, input, navigation,
## and sprite regions. A changing whole-frame hash alone cannot prove a gait.

const DIRECTIONS: Array[Dictionary] = [
	{"action": "move_right", "vector": Vector2.RIGHT, "name": &"right"},
	{"action": "move_down", "vector": Vector2.DOWN, "name": &"front"},
	{"action": "move_left", "vector": Vector2.LEFT, "name": &"left"},
	{"action": "move_up", "vector": Vector2.UP, "name": &"back"},
]
const EMPLOYEES: Array[String] = ["mira", "theo", "creative"]
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func column(sprite: Sprite2D) -> int:
	return int(sprite.region_rect.position.x / CharacterArt.FRAME_SIZE.x)

func record_frame(frames: Dictionary, sprite: Sprite2D, direction: StringName) -> void:
	var frame := column(sprite)
	if frame >= 2 and frame <= 5:
		frames[frame] = true
		check(sprite.region_rect == CharacterArt.locomotion_region(direction, frame), "Walking selects the requested direction and a complete native cell")

func run() -> void:
	# A clear disposable room keeps furniture collisions and saved games out of
	# the timing check while retaining the shipped path planner and actor code.
	var navigation := OfficeNavigation.new()
	root.add_child(navigation)
	navigation.configure({"width": 80, "height": 80, "walkable_rects": [[0, 0, 80, 80]]}, Vector2.ZERO)
	var player := load("res://actors/player_avatar.tscn").instantiate() as PlayerAvatar
	player.position = Vector2(400, 400)
	player.movement_bounds = Rect2(0, 0, 2560, 2560)
	player.navigation = navigation
	root.add_child(player)
	var actors: Array[EmployeeAvatar] = []
	for id: String in EMPLOYEES:
		var actor := EmployeeAvatar.new()
		root.add_child(actor)
		actor.configure(EmployeeRecord.from_dictionary({"id": id}), Vector2(816 + 384 * actors.size(), 400), Vector2.ZERO, Vector2.ZERO)
		actor.navigation = navigation
		# Suppress the idle schedule after arrival without changing locomotion.
		actor.has_live_job = true
		actors.append(actor)
	await physics_frame
	for spec: Dictionary in DIRECTIONS:
		var start := player.position
		var frames: Dictionary = {"founder": {}}
		var starts: Dictionary = {}
		for actor: EmployeeAvatar in actors:
			frames[actor.employee_id] = {}
			starts[actor.employee_id] = actor.position
			actor.walk_to(actor.position + spec.vector * 96, EmployeeAvatar.WorkState.WANDERING)
			check(actor._has_target and not actor._route.is_empty(), actor.employee_id + " starts a real navigation route")
		Input.action_press(spec.action)
		# More than one full cycle; sample every physics tick to avoid aliasing a
		# 0.5-second walk cycle into apparently identical screenshots.
		for tick: int in range(40):
			await physics_frame
			if tick == 0: continue
			record_frame(frames.founder, player._character_sprite, spec.name)
			for actor: EmployeeAvatar in actors:
				record_frame(frames[actor.employee_id], actor._character_sprite, spec.name)
		Input.action_release(spec.action)
		check((player.position - start).dot(spec.vector) > 70.0, "Founder physically moves while animating " + str(spec.name))
		for id: String in frames:
			check(frames[id].size() == 4, "%s %s visits all four walking columns over real physics ticks" % [id, spec.name])
		for actor: EmployeeAvatar in actors:
			check((actor.position - Vector2(starts[actor.employee_id])).dot(spec.vector) > 50.0, actor.employee_id + " physically advances along its route")
		for tick: int in range(30): await physics_frame
		check(column(player._character_sprite) in [0, 1], "Releasing movement returns Founder to idle")
		for actor: EmployeeAvatar in actors:
			check(not actor._has_target and actor.position.distance_to(Vector2(starts[actor.employee_id]) + spec.vector * 96) < 0.5, actor.employee_id + " reaches its requested destination")
			check(column(actor._character_sprite) in [0, 1], actor.employee_id + " returns to idle on arrival")
	var click_start := player.position
	check(player.move_to(click_start + Vector2(128, 0)), "Founder accepts a click-style route")
	var click_frames := {}
	for tick: int in range(40):
		await physics_frame
		if tick > 0: record_frame(click_frames, player._character_sprite, &"right")
	check(click_frames.size() == 4 and player.position.x > click_start.x + 70, "Click navigation advances Founder through the entire walk cycle")
	for tick: int in range(25): await physics_frame
	check(player.route.is_empty() and column(player._character_sprite) in [0, 1], "Click arrival returns Founder to idle")
	player.free()
	for actor: EmployeeAvatar in actors: actor.free()
	navigation.free()
	print("walking_animation: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
