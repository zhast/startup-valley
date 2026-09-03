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
	"res://assets/runtime/office/office-shell-base.png",
	"res://assets/runtime/office/employee-workstation.png",
	"res://assets/runtime/office/research-bench.png",
	"res://assets/runtime/office/layered-furniture.png",
	"res://assets/runtime/office/collaboration-cluster.png",
	"res://assets/runtime/office/coffee-station.png",
	"res://assets/runtime/office/approval-console.png",
	"res://assets/runtime/office/artifact-archive.png",
	"res://assets/runtime/office/prototype-bench.png",
	"res://assets/runtime/characters/founder-locomotion.png",
	"res://assets/runtime/characters/mira-locomotion.png",
	"res://assets/runtime/characters/theo-locomotion.png",
	"res://assets/runtime/characters/mira-work.png",
	"res://assets/runtime/characters/theo-work.png",
	"res://assets/runtime/effects/world-state-vfx.png",
	"res://assets/runtime/effects/ambient-office.png",
	"res://assets/runtime/effects/character-shadows.png",
	"res://assets/runtime/effects/office-unlock.png",
	"res://assets/concepts/office-town-characters-sheet.png",
	"res://assets/concepts/ui/team-roster-brand-palette-concept.png",
	"res://assets/concepts/ui/employee-profile-brand-palette-concept.png",
]
const IMPORTANT_FONTS: PackedStringArray = [
	"res://assets/fonts/tiny5/Tiny5-Regular.ttf",
	"res://assets/fonts/nunito-sans/NunitoSans-Variable.ttf",
]
const IMPORTANT_SCRIPTS: PackedStringArray = [
	"res://character_art.gd",
	"res://polish_art.gd",
	"res://props/office_ambient_overlay.gd",
	"res://props/office_unlock_effect.gd",
	"res://ui/game_fonts.gd",
]
const EXACT_TEXTURE_SIZES: Dictionary = {
	"res://assets/runtime/characters/founder-locomotion.png": Vector2i(288, 320),
	"res://assets/runtime/characters/mira-locomotion.png": Vector2i(288, 320),
	"res://assets/runtime/characters/theo-locomotion.png": Vector2i(288, 320),
	"res://assets/runtime/characters/mira-work.png": Vector2i(384, 320),
	"res://assets/runtime/characters/theo-work.png": Vector2i(384, 320),
	"res://assets/runtime/office/employee-workstation.png": Vector2i(132, 88),
	"res://assets/runtime/office/research-bench.png": Vector2i(138, 92),
	"res://assets/runtime/office/layered-furniture.png": Vector2i(256, 192),
	"res://assets/runtime/office/collaboration-cluster.png": Vector2i(138, 92),
	"res://assets/runtime/office/coffee-station.png": Vector2i(142, 94),
	"res://assets/runtime/office/approval-console.png": Vector2i(132, 88),
	"res://assets/runtime/office/prototype-bench.png": Vector2i(140, 140),
	"res://assets/runtime/office/artifact-archive.png": Vector2i(136, 90),
	"res://assets/runtime/effects/world-state-vfx.png": Vector2i(96, 144),
	"res://assets/runtime/effects/ambient-office.png": Vector2i(128, 160),
	"res://assets/runtime/effects/character-shadows.png": Vector2i(96, 16),
	"res://assets/runtime/effects/office-unlock.png": Vector2i(384, 64),
}
const RUNTIME_ATLASES: Array[Dictionary] = [
	{
		"path": "res://assets/runtime/characters/founder-locomotion.png",
		"cell": Vector2i(48, 80), "columns": 6, "rows": 4,
		"spans": [[0, 0, 2], [0, 2, 4], [1, 0, 2], [1, 2, 4], [2, 0, 2], [2, 2, 4], [3, 0, 2], [3, 2, 4]],
	},
	{
		"path": "res://assets/runtime/characters/mira-locomotion.png",
		"cell": Vector2i(48, 80), "columns": 6, "rows": 4,
		"spans": [[0, 0, 2], [0, 2, 4], [1, 0, 2], [1, 2, 4], [2, 0, 2], [2, 2, 4], [3, 0, 2], [3, 2, 4]],
	},
	{
		"path": "res://assets/runtime/characters/theo-locomotion.png",
		"cell": Vector2i(48, 80), "columns": 6, "rows": 4,
		"spans": [[0, 0, 2], [0, 2, 4], [1, 0, 2], [1, 2, 4], [2, 0, 2], [2, 2, 4], [3, 0, 2], [3, 2, 4]],
	},
	{
		"path": "res://assets/runtime/characters/mira-work.png",
		"cell": Vector2i(48, 80), "columns": 8, "rows": 4,
		"spans": [[0, 0, 2], [0, 2, 4], [0, 6, 2], [1, 0, 4], [1, 4, 4], [2, 0, 4], [2, 4, 4], [3, 0, 4], [3, 4, 4]],
	},
	{
		"path": "res://assets/runtime/characters/theo-work.png",
		"cell": Vector2i(48, 80), "columns": 8, "rows": 4,
		"spans": [[0, 0, 2], [0, 2, 4], [0, 6, 2], [1, 0, 4], [1, 4, 4], [2, 0, 4], [2, 4, 4], [3, 0, 4], [3, 4, 4]],
	},
	{
		"path": "res://assets/runtime/effects/world-state-vfx.png",
		"cell": Vector2i(24, 24), "columns": 4, "rows": 6,
		"spans": [[0, 0, 4], [1, 0, 4], [2, 0, 4], [3, 0, 4], [4, 0, 4], [5, 0, 4]],
	},
	{
		"path": "res://assets/runtime/effects/ambient-office.png",
		"cell": Vector2i(32, 32), "columns": 4, "rows": 5,
		"spans": [[0, 0, 4], [1, 0, 4], [2, 0, 4], [3, 0, 4], [4, 0, 4]],
	},
	{
		"path": "res://assets/runtime/effects/character-shadows.png",
		"cell": Vector2i(32, 16), "columns": 3, "rows": 1,
		"spans": [[0, 0, 3]],
	},
	{
		"path": "res://assets/runtime/effects/office-unlock.png",
		"cell": Vector2i(64, 64), "columns": 6, "rows": 1,
		"spans": [[0, 0, 5]], "empty_cells": [5],
	},
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
			continue
		if EXACT_TEXTURE_SIZES.has(path):
			var expected_size: Vector2i = EXACT_TEXTURE_SIZES[path]
			var actual_size := Vector2i((texture as Texture2D).get_size())
			if actual_size != expected_size:
				_fail("Runtime texture %s is %s; expected %s" % [path, actual_size, expected_size])

	for path: String in IMPORTANT_FONTS:
		var font: Resource = load(path)
		if font == null or not font is Font:
			_fail("Could not load bundled font: %s" % path)

	for path: String in IMPORTANT_SCRIPTS:
		var script: Resource = load(path)
		if script == null or not script is Script:
			_fail("Could not load important script: %s" % path)

	if not FileAccess.file_exists("res://assets/fonts/tiny5/OFL.txt"):
		_fail("Tiny5 license is missing")
	if not FileAccess.file_exists("res://assets/fonts/nunito-sans/OFL.txt"):
		_fail("Nunito Sans license is missing")

	for atlas: Dictionary in RUNTIME_ATLASES:
		_validate_runtime_atlas(atlas)

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

func _validate_runtime_atlas(spec: Dictionary) -> void:
	var path := str(spec.get("path", ""))
	var texture := load(path) as Texture2D
	if texture == null:
		_fail("Could not load runtime atlas: %s" % path)
		return
	var image := texture.get_image()
	var cell: Vector2i = spec.get("cell", Vector2i.ZERO)
	var columns := int(spec.get("columns", 0))
	var rows := int(spec.get("rows", 0))
	if image.get_size() != Vector2i(cell.x * columns, cell.y * rows):
		_fail("Runtime atlas grid does not match its declared cells: %s" % path)
		return
	var empty_cells_value: Variant = spec.get("empty_cells", [])
	var empty_cells := empty_cells_value as Array if empty_cells_value is Array else []
	for row: int in range(rows):
		for column: int in range(columns):
			var index := row * columns + column
			var frame := image.get_region(Rect2i(Vector2i(column * cell.x, row * cell.y), cell))
			var has_pixels := _image_has_visible_pixel(frame)
			if index in empty_cells:
				if has_pixels:
					_fail("Runtime atlas cell %d should be clear: %s" % [index, path])
			elif not has_pixels:
				_fail("Runtime atlas cell %d is empty: %s" % [index, path])
	var spans_value: Variant = spec.get("spans", [])
	if spans_value is Array:
		for span_value: Variant in spans_value as Array:
			if not span_value is Array or (span_value as Array).size() != 3:
				continue
			var span := span_value as Array
			var fingerprints: Dictionary[String, bool] = {}
			for column: int in range(int(span[1]), int(span[1]) + int(span[2])):
				var frame := image.get_region(Rect2i(Vector2i(column * cell.x, int(span[0]) * cell.y), cell))
				fingerprints[str(hash(frame.get_data()))] = true
			if fingerprints.size() < 2:
				_fail("Runtime atlas animation row %d columns %d-%d is static: %s" % [int(span[0]), int(span[1]), int(span[1]) + int(span[2]) - 1, path])

func _image_has_visible_pixel(image: Image) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.01:
				return true
	return false
