extends SceneTree

const IMPORTANT_SCENES: PackedStringArray = [
	"res://actors/player_avatar.tscn",
	"res://actors/employee_avatar.tscn",
	"res://props/desk.tscn",
	"res://props/research_table.tscn",
	"res://world/town_room.tscn",
	"res://ui/job_panel.tscn",
	"res://ui/artifact_viewer.tscn",
	"res://ui/clock_panel.tscn",
	"res://world/main.tscn",
]
const IMPORTANT_TEXTURES: PackedStringArray = [
	"res://assets/runtime/office/main-office-background.png",
]

var _failures: int = 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_validate")

func _fail(message: String) -> void:
	_failures += 1
	push_error(message)

func _validate() -> void:
	for path: String in IMPORTANT_SCENES:
		var resource: Resource = load(path)
		if resource == null or not resource is PackedScene:
			_fail("Could not load important scene: %s" % path)
			continue
		var instance := (resource as PackedScene).instantiate()
		if instance == null:
			_fail("Could not instantiate important scene: %s" % path)
			continue
		if instance.get_script() == null:
			_fail("Important scene root script did not load: %s" % path)
		root.add_child(instance)
		await process_frame
		root.remove_child(instance)
		instance.free()

	for path: String in IMPORTANT_TEXTURES:
		var texture: Resource = load(path)
		if texture == null or not texture is Texture2D:
			_fail("Could not load important texture: %s" % path)

	var layout_file := FileAccess.open("res://data/town.json", FileAccess.READ)
	if layout_file == null:
		_fail("Logical town grid is missing")
	else:
		var layout_value: Variant = JSON.parse_string(layout_file.get_as_text())
		if not layout_value is Dictionary:
			_fail("Logical town grid is not valid JSON")
		else:
			var layout := layout_value as Dictionary
			if int(layout.get("width", 0)) <= 0 or int(layout.get("height", 0)) <= 0:
				_fail("Logical town grid dimensions are invalid")

	if _failures == 0:
		print("validate_project: all important scenes and the logical grid are valid")
	quit(_failures)
