class_name YardFence
extends Node2D
## Native 32px boundary pieces connected from the actual navigation floor.
## Visual only: movement, collision and travel remain owned by their systems.
const CELL := 32
const RECIPE_PATH := "res://data/yard_fence.json"
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
var edges: Array[Dictionary] = []
var omitted_edges: Array[Dictionary] = []
var connections: Dictionary = {}
var _recipe: Dictionary = {}
var _texture: Texture2D

static func boundary_edges(floor_cells: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definitions: Array[Array] = [
		[Vector2i.UP, Vector2i.ZERO, Vector2i.RIGHT],
		[Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.ONE],
		[Vector2i.DOWN, Vector2i.DOWN, Vector2i.ONE],
		[Vector2i.LEFT, Vector2i.ZERO, Vector2i.DOWN],
	]
	for cell: Vector2i in floor_cells:
		for definition: Array in definitions:
			if floor_cells.has(cell + definition[0]): continue
			result.append({"from": cell + definition[1], "to": cell + definition[2]})
	return result

static func connection_masks(segments: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for segment: Dictionary in segments:
		var start: Vector2i = segment["from"]
		var finish: Vector2i = segment["to"]
		var horizontal := finish.x != start.x
		result[start] = int(result.get(start, 0)) | (EAST if horizontal else SOUTH)
		result[finish] = int(result.get(finish, 0)) | (WEST if horizontal else NORTH)
	return result

func configure(floor_cells: Dictionary, gates: Array = []) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_recipe = OfficeLayout._read_json(RECIPE_PATH)
	_texture = load(str(_recipe.atlas)) as Texture2D
	assert(int(_recipe.cell_size) == CELL and float(_recipe.runtime_scale) == 1.0 and str(_recipe.sampling) == "nearest" and _texture != null)
	var complete := boundary_edges(floor_cells)
	omitted_edges.clear()
	for gate: Dictionary in gates:
		var start := OfficeLayout.vector(gate["from"])
		var finish := OfficeLayout.vector(gate["to"])
		assert(not str(gate.get("interaction_id", "")).is_empty())
		assert(start.y == finish.y and finish.x - start.x == 2)
		for x: int in range(start.x, finish.x):
			var edge := {"from": Vector2i(x, start.y), "to": Vector2i(x + 1, start.y)}
			assert(complete.has(edge) and not omitted_edges.has(edge))
			omitted_edges.append(edge)
	edges.clear()
	for edge: Dictionary in complete:
		if not omitted_edges.has(edge): edges.append(edge)
	connections = connection_masks(edges)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	for edge: Dictionary in edges:
		var start: Vector2i = edge["from"]
		var finish: Vector2i = edge["to"]
		_piece("horizontal" if start.y == finish.y else "vertical", start)
	for vertex: Vector2i in connections:
		var post := _piece("post", vertex)
		post.set_meta("connection_mask", int(connections[vertex]))

func _piece(kind: String, vertex: Vector2i) -> Sprite2D:
	var specification: Dictionary = _recipe.pieces[kind]
	var piece := Sprite2D.new()
	piece.name = "%s_%d_%d" % [kind, vertex.x, vertex.y]
	piece.texture = _texture
	piece.centered = false
	piece.region_enabled = true
	piece.region_rect = OfficeLayout.rectangle(specification.region)
	piece.position = Vector2(vertex * CELL - OfficeLayout.vector(specification.pivot))
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.z_as_relative = false
	piece.z_index = vertex.y * CELL + (1 if kind == "post" else 0)
	piece.set_meta("vertex", vertex)
	piece.set_meta("kind", kind)
	add_child(piece)
	return piece
