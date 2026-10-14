class_name OfficeArchitecture
extends Node2D

# Every visible architectural cell is sampled at native size from the same
# model which creates wall collision and navigation. There is no room bitmap.
var layout: OfficeLayout
var blockout := false
var floor_art: Texture2D
var wall_art: Texture2D
var trim_art: Texture2D
var window_art: Texture2D
var door_art: Texture2D
const ART_ROOT := "res://assets/runtime/office/architecture/"
const DEFAULT_THEME := "office"
const PARTS: PackedStringArray = ["floor", "wall", "trim", "window", "door"]
## Unprefixed files are the shipped oak office. A named theme uses "{id}-".
## Registered Settings looks are oak, cafe, loft, studio, and evening. Oak stays
## the day-1 default. These looks are not journey steps.
const THEME_ORDER: PackedStringArray = ["office", "cafe", "loft", "studio", "evening"]
const THEME_LABELS: Dictionary = {"office": "Oak office", "cafe": "Cafe", "loft": "Loft", "studio": "Studio", "evening": "Evening"}
const THEME_PREFIXES: Dictionary = {"office": "", "cafe": "cafe-", "loft": "loft-", "studio": "studio-", "evening": "evening-"}
var theme_id := DEFAULT_THEME

static func theme_label(theme: String) -> String:
	return str(THEME_LABELS.get(theme, theme))

static func theme_path(theme: String, part: String) -> String:
	if not THEME_PREFIXES.has(theme) or not PARTS.has(part): return ""
	return ART_ROOT + str(THEME_PREFIXES[theme]) + part + ".png"

static func theme_available(theme: String) -> bool:
	if not THEME_PREFIXES.has(theme): return false
	for part: String in PARTS:
		if not ResourceLoader.exists(theme_path(theme, part)): return false
	return true

func apply_theme(theme: String) -> bool:
	if not theme_available(theme): return false
	var loaded: Dictionary = {}
	for part: String in PARTS:
		var texture := load(theme_path(theme, part)) as Texture2D
		if texture == null: return false
		loaded[part] = texture
	floor_art = loaded["floor"]
	wall_art = loaded["wall"]
	trim_art = loaded["trim"]
	window_art = loaded["window"]
	door_art = loaded["door"]
	theme_id = theme
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	return true

func configure(model: OfficeLayout) -> void:
	layout = model
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var requested := DEFAULT_THEME
	if model != null:
		var authored := str(model.data.get("architecture_theme", "")).strip_edges()
		if not authored.is_empty(): requested = authored
	if not apply_theme(requested) and requested != DEFAULT_THEME:
		apply_theme(DEFAULT_THEME)
	queue_redraw()

func _draw() -> void:
	if layout == null: return
	if blockout or floor_art == null:
		_draw_blockout()
		return
	for y: int in range(layout.height):
		for x: int in range(layout.width):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * layout.tile_size), Vector2.ONE * layout.tile_size)
			if layout.is_floor(cell):
				draw_texture_rect_region(floor_art, rect, Rect2((x % 4) * 32, (y % 4) * 32, 32, 32))
				continue
			var wall_distance := _north_face_distance(cell)
			if wall_distance > 0:
				draw_texture_rect_region(wall_art, rect, Rect2((x % 4) * 32, (3 - wall_distance) * 32, 32, 32))
			else:
				var tile := _trim_cell(cell)
				draw_texture_rect_region(trim_art, rect, Rect2((tile % 4) * 32, (tile / 4) * 32, 32, 32))
	# Windows occupy solid wall cells; scenery exists only inside their panes.
	for window: Dictionary in layout.data.get("windows", []):
		var cell := OfficeLayout.vector(window.grid)
		draw_texture(window_art, Vector2(cell * layout.tile_size))
	for door: Dictionary in layout.data.get("doors", []):
		var cell := OfficeLayout.vector(door.grid)
		draw_texture(door_art, Vector2(cell * layout.tile_size))

func _north_face_distance(cell: Vector2i) -> int:
	for distance: int in range(1, 4):
		if layout.is_floor(cell + Vector2i(0, distance)): return distance
	return 0

func _trim_cell(cell: Vector2i) -> int:
	if layout.is_floor(cell + Vector2i.RIGHT): return 0
	if layout.is_floor(cell + Vector2i.LEFT): return 1
	if layout.is_floor(cell + Vector2i.UP): return 2
	if layout.is_floor(cell + Vector2i(1, 1)): return 4
	if layout.is_floor(cell + Vector2i(-1, 1)): return 5
	if layout.is_floor(cell + Vector2i(1, -1)): return 6
	if layout.is_floor(cell + Vector2i(-1, -1)): return 7
	return 3

func _draw_blockout() -> void:
	for y: int in range(layout.height):
		for x: int in range(layout.width):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * layout.tile_size), Vector2.ONE * layout.tile_size)
			var color := Color("ad9774") if layout.is_floor(cell) else Color("484b52")
			draw_rect(rect, color)
			draw_rect(rect, Color(0.1, 0.1, 0.1, 0.14), false, 1)
	for window: Dictionary in layout.data.get("windows", []):
		var grid: Array = window.grid
		draw_rect(Rect2(Vector2(int(grid[0]), int(grid[1])) * layout.tile_size + Vector2(4, 8), Vector2(int(window.width) * layout.tile_size - 8, int(window.height) * layout.tile_size - 20)), Color("6196c1"))
