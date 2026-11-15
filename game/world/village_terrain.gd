class_name VillageTerrain
extends Node2D
## Shared native-size terrain cells. Source crops are declared, never a room painting.
const RECIPE_PATH := "res://data/village_terrain.json"
const CELL := 32
var ground: TileMapLayer
var boundary: TileMapLayer
var _samples: Dictionary = {}
var _source_ids: Dictionary = {}
var _tiles: TileSet
var _grass_patch := Vector2i.ONE

func configure(data: Dictionary, office := false) -> bool:
	if int(data.get("tile_size", 0)) != CELL:
		push_error("Village terrain requires the shared 32px grid")
		return false
	var recipe: Dictionary = OfficeLayout._read_json(RECIPE_PATH)
	if int(recipe.get("tile_size", 0)) != CELL or float(recipe.get("runtime_scale", 0)) != 1.0:
		push_error("Village terrain recipe must preserve native size")
		return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	scale = Vector2.ONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -1000
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(CELL, CELL)
	_samples.clear()
	_source_ids.clear()
	_grass_patch = Vector2i(int(recipe.get("grass_patch_columns", 1)), int(recipe.get("grass_patch_rows", 1)))
	for material: String in recipe.materials:
		var specification: Dictionary = recipe.materials[material]
		var region_size := OfficeLayout.vector(specification.region_size)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = load(str(recipe.source)) as Texture2D
		atlas.texture_region_size = region_size
		_samples[material] = []
		for rect: Array in specification.samples:
			if rect.size() != 4 or int(rect[0]) % region_size.x != 0 or int(rect[1]) % region_size.y != 0 or int(rect[2]) != region_size.x or int(rect[3]) != region_size.y:
				push_error("Terrain crop must be a grid-aligned native module")
				return false
			var coordinate := Vector2i(int(rect[0]) / region_size.x, int(rect[1]) / region_size.y)
			if not atlas.has_tile(coordinate): atlas.create_tile(coordinate)
			atlas.get_tile_data(coordinate, 0).texture_origin = OfficeLayout.vector(specification.texture_origin)
			_samples[material].append(coordinate)
		var source_id := _tiles.get_next_source_id()
		_tiles.add_source(atlas, source_id)
		_source_ids[material] = source_id
	if _grass_patch.x < 1 or _grass_patch.y < 1 or _grass_patch.x * _grass_patch.y != _samples["grass"].size():
		push_error("Grass patch dimensions must match its native cells")
		return false
	ground = _layer("Ground")
	boundary = _layer("Boundary")
	var width := int(data.get("width", 40))
	var height := int(data.get("height", 23))
	for y: int in range(height):
		for x: int in range(width): _paint(ground, Vector2i(x, y), "grass")
	if office:
		# The apron meets the actual doorway and leaves the scene through its
		# lower edge. The surrounding yard is scenery, never an extra exit.
		for door: Dictionary in data.get("doors", []):
			if not bool(door.get("entrance", false)): continue
			var cell := OfficeLayout.vector(door.grid)
			for y: int in range(cell.y, height):
				for x: int in range(cell.x, cell.x + int(door.get("width", 1))): _paint(ground, Vector2i(x, y), "paving")
	else:
		var floor_cells: Dictionary = {}
		for rect: Array in data.get("walkable_rects", []):
			for y: int in range(int(rect[1]), int(rect[1]) + int(rect[3])):
				for x: int in range(int(rect[0]), int(rect[0]) + int(rect[2])): floor_cells[Vector2i(x, y)] = true
		for rect: Array in data.get("paving_rects", []):
			for y: int in range(int(rect[1]), int(rect[1]) + int(rect[3])):
				for x: int in range(int(rect[0]), int(rect[0]) + int(rect[2])):
					if floor_cells.has(Vector2i(x, y)): _paint(ground, Vector2i(x, y), "paving")
	# These low, wide shrubs join horizontally. Plant a few authored groups;
	# repeating them vertically would leave a visible gap at every grid step.
	for row: Array in data.get("terrain_plantings", []):
		for x: int in range(int(row[0]), int(row[0]) + int(row[2])):
			_paint(boundary, Vector2i(x, int(row[1])), "hedge")
	return true

func _layer(label: String) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = label
	layer.tile_set = _tiles
	add_child(layer)
	return layer

func _paint(layer: TileMapLayer, cell: Vector2i, material: String) -> void:
	var samples: Array = _samples[material]
	# Stable spatial variation; no random generator or save-dependent texture drift.
	var index := posmod(cell.x * 73856093 ^ cell.y * 19349663, samples.size())
	if material == "grass": index = posmod(cell.x, _grass_patch.x) + posmod(cell.y, _grass_patch.y) * _grass_patch.x
	layer.set_cell(cell, int(_source_ids[material]), samples[index])
