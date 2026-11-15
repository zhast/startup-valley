extends SceneTree
## Native renderer regression: cursor textures must die before renderer exit.

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

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.unfocusable = true
	var first := RefCounted.new()
	var second := RefCounted.new()
	GameCursor.install(first)
	var arrow: WeakRef = weakref(GameCursor._arrow_texture)
	var hand: WeakRef = weakref(GameCursor._hand_texture)
	GameCursor.install(first)
	check(GameCursor._owners.size() == 1, "Repeated installation is idempotent")
	check(GameCursor._arrow_texture == arrow.get_ref(), "Repeated installation reuses textures")
	GameCursor.install(second)
	GameCursor.release(first)
	GameCursor.release(first)
	check(GameCursor._owners.size() == 1 and arrow.get_ref() != null, "One owner cannot clear another owner's cursor")
	GameCursor.release(second)
	check(GameCursor._owners.is_empty(), "Last owner releases registration")
	check(arrow.get_ref() == null and hand.get_ref() == null, "Input and script references both release texture resources")
	var scene := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(scene)
	await process_frame
	check(GameCursor._owners.size() == 1, "Actual main scene owns cursor resources")
	arrow = weakref(GameCursor._arrow_texture)
	hand = weakref(GameCursor._hand_texture)
	scene.game_audio.shutdown()
	scene.free()
	await process_frame
	check(GameCursor._owners.is_empty() and arrow.get_ref() == null and hand.get_ref() == null, "Scene teardown clears both custom cursors")
	scene = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(scene)
	await process_frame
	check(GameCursor._owners.size() == 1, "A subsequent scene can reinstall cursors")
	arrow = weakref(GameCursor._arrow_texture)
	hand = weakref(GameCursor._hand_texture)
	scene.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(GameCursor._owners.is_empty() and arrow.get_ref() == null and hand.get_ref() == null, "Normal close releases both textures before quitting")
	print("Cursor lifecycle: %d checks, %d failures; normal close follows" % [checks, failures.size()])
	if not failures.is_empty(): quit(1)
