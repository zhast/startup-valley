class_name OfficeNavigation
extends Node2D

signal changed
signal passage_requested(employee_id: String, destination: Vector2)

var grid := AStarGrid2D.new()
var origin := Vector2.ZERO
var tile_size := 32
var revision := 0
var reservations: Dictionary[String, Vector2i] = {}
var actors: Dictionary[String, Vector2] = {}
var _floor: Dictionary[Vector2i, bool] = {}
var _walls: StaticBody2D

func configure(data: Dictionary, room_origin: Vector2) -> void:
	origin = room_origin
	tile_size = int(data.get("tile_size", 32))
	grid.region = Rect2i(0, 0, int(data.get("width", 26)), int(data.get("height", 18)))
	grid.cell_size = Vector2.ONE * tile_size
	grid.offset = origin + Vector2.ONE * tile_size * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	_floor.clear()
	for rectangle: Array in data.get("walkable_rects", []):
		_mark_floor(rectangle, true)
	for rectangle: Array in data.get("wall_rects", []):
		_mark_floor(rectangle, false)
	if _walls != null:
		_walls.queue_free()
	_walls = StaticBody2D.new()
	_walls.name = "ArchitectureCollision"
	add_child(_walls)
	for y: int in range(grid.region.size.y):
		var run_start := -1
		for x: int in range(grid.region.size.x + 1):
			var blocked: bool = x < grid.region.size.x and not _floor.get(Vector2i(x, y), false)
			if blocked and run_start < 0:
				run_start = x
			if not blocked and run_start >= 0:
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - run_start) * tile_size, tile_size)
				var collision := CollisionShape2D.new()
				collision.shape = shape
				collision.position = origin + Vector2((run_start + x) * tile_size * 0.5, (y + 0.5) * tile_size)
				_walls.add_child(collision)
				run_start = -1
	rebuild([])

func _mark_floor(rectangle: Array, value: bool) -> void:
	if rectangle.size() != 4:
		push_error("Walkability rectangle requires x, y, width, height")
		return
	for y: int in range(int(rectangle[1]), int(rectangle[1]) + int(rectangle[3])):
		for x: int in range(int(rectangle[0]), int(rectangle[0]) + int(rectangle[2])):
			var cell := Vector2i(x, y)
			if grid.region.has_point(cell):
				_floor[cell] = value

func rebuild(obstacles: Array[Rect2]) -> void:
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			var blocked: bool = not _floor.get(cell, false)
			for obstacle: Rect2 in obstacles:
				if obstacle.grow(11.0).has_point(world(cell)):
					blocked = true
			grid.set_point_solid(cell, blocked)
	reservations.clear()
	revision += 1
	changed.emit()

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x - origin.x) / tile_size), floori((point.y - origin.y) / tile_size))

func rebuild_placements(placements: Array[Dictionary]) -> void:
	# Use resolved occupied cells directly, not inferred image/collider bounds.
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not _floor.get(cell, false))
	for placement: Dictionary in placements:
		for cell: Vector2i in placement.occupied:
			if grid.region.has_point(cell): grid.set_point_solid(cell, true)
	reservations.clear()
	revision += 1
	changed.emit()

func position_is_safe(point: Vector2, owner: String = "") -> bool:
	return is_finite(point.x) and is_finite(point.y) and _footprint_clear(point) and _clear_of_actors(owner, point)

func safe_position(point: Vector2, owner: String = "") -> Vector2:
	if position_is_safe(point, owner): return point
	if not is_finite(point.x) or not is_finite(point.y): point = world(Vector2i(grid.region.size.x / 2, grid.region.size.y / 2))
	var cell := nearest(point, owner)
	return world(cell) if cell.x >= 0 else point

func world(cell: Vector2i) -> Vector2:
	return origin + Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5

func walkable(cell: Vector2i) -> bool:
	return grid.region.has_point(cell) and not grid.is_point_solid(cell)

func nearest(point: Vector2, owner: String = "") -> Vector2i:
	var best := Vector2i(-1, -1)
	var distance := INF
	var approach_distance := INF
	for candidate: Vector2i in _floor:
		if not walkable(candidate) or _reserved_by_other(candidate, owner):
			continue
		var current := world(candidate).distance_squared_to(point)
		var approach := world(candidate).distance_squared_to(actors.get(owner, point))
		if current < distance or (is_equal_approx(current, distance) and approach < approach_distance):
			distance = current
			approach_distance = approach
			best = candidate
	return best

func _reserved_by_other(cell: Vector2i, owner: String) -> bool:
	for id: String in reservations:
		if id != owner and reservations[id] == cell:
			return true
	for id: String in actors:
		if id != owner and world(cell).distance_to(actors[id]) < 22.0:
			return true
	return false

func release(owner: String) -> void:
	reservations.erase(owner)

func request_passage(owner: String, current: Vector2, waypoint: Vector2) -> bool:
	for other: String in actors:
		if other == owner or other == "founder" or current.distance_to(actors[other]) > 42.0: continue
		if current.direction_to(waypoint).dot(current.direction_to(actors[other])) < 0.1: continue
		var from := cell_at(actors[other])
		var best := Vector2i(-1, -1)
		var best_score := INF
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				var candidate := from + Vector2i(dx, dy)
				var point := world(candidate)
				if candidate == from or not walkable(candidate) or _reserved_by_other(candidate, other) or not _footprint_clear(point): continue
				if point.distance_to(current) < 32.0: continue
				var requester_cell := cell_at(current)
				var block_requester := requester_cell != from and requester_cell != candidate and walkable(requester_cell)
				if block_requester: grid.set_point_solid(requester_cell, true)
				var can_yield := not grid.get_id_path(from, candidate).is_empty()
				if block_requester: grid.set_point_solid(requester_cell, false)
				if not can_yield: continue
				# Prefer stepping sideways out of the lane, not further into it.
				var score := point.distance_to(actors[other]) + (100.0 if candidate == cell_at(waypoint) else 0.0)
				if score < best_score:
					best_score = score
					best = candidate
		if best.x >= 0:
			passage_requested.emit(other, world(best))
			return true
	return false

func separated_step(owner: String, current: Vector2, proposed: Vector2) -> Vector2:
	# Separation can leave feet off-center. Rejoining a grid route must not cut
	# diagonally through a wall corner between two otherwise walkable waypoints.
	if not _footprint_clear(proposed):
		var horizontal := Vector2(proposed.x, current.y)
		var vertical := Vector2(current.x, proposed.y)
		if _footprint_clear(horizontal) and _clear_of_actors(owner, horizontal): proposed = horizontal
		elif _footprint_clear(vertical) and _clear_of_actors(owner, vertical): proposed = vertical
		else: return current
	for id: String in actors:
		if id == owner: continue
		if proposed.distance_to(actors[id]) < 20.0:
			var forward := current.direction_to(proposed)
			for sign_value: float in [-1.0, 1.0]:
				var side := current + Vector2(-forward.y, forward.x) * current.distance_to(proposed) * sign_value
				if _clear_of_actors(owner, side) and _footprint_clear(side) and side.distance_to(actors[id]) > current.distance_to(actors[id]):
					actors[owner] = side
					return side
			return current
	actors[owner] = proposed
	return proposed

func _clear_of_actors(owner: String, point: Vector2) -> bool:
	for id: String in actors:
		if id != owner and point.distance_to(actors[id]) < 20.0: return false
	return true

func _footprint_clear(point: Vector2) -> bool:
	for offset: Vector2 in [Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]:
		if not walkable(cell_at(point + offset)): return false
	return true

func path(from: Vector2, target: Vector2, owner: String) -> PackedVector2Array:
	var start := nearest(from, owner)
	var end := nearest(target, owner)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	var occupied: Array[Vector2i] = []
	for id: String in actors:
		var cell := cell_at(actors[id])
		if id != owner and cell != start and cell != end and walkable(cell):
			occupied.append(cell)
			grid.set_point_solid(cell, true)
	for id: String in reservations:
		var cell := reservations[id]
		if id != owner and cell != start and cell != end and walkable(cell):
			occupied.append(cell)
			grid.set_point_solid(cell, true)
	var points := grid.get_point_path(start, end)
	for cell: Vector2i in occupied: grid.set_point_solid(cell, false)
	# A teammate standing in a one-cell doorway is transient, not a sealed room.
	# Keep a static route and let separation wait until they move out of the way.
	if points.is_empty() and not occupied.is_empty():
		# Employees can ask teammates to yield, but never push the player. Keep
		# the founder blocked even when falling back around stationary teammates.
		var founder_cell := cell_at(actors.get("founder", Vector2(-1000, -1000)))
		var preserve_founder := owner != "founder" and founder_cell != start and founder_cell != end and walkable(founder_cell)
		if preserve_founder: grid.set_point_solid(founder_cell, true)
		points = grid.get_point_path(start, end)
		if preserve_founder: grid.set_point_solid(founder_cell, false)
	if points.is_empty():
		return points
	reservations[owner] = end
	# Start at the current feet, not at a cell behind the actor.
	if points.size() > 1 and from.distance_to(points[0]) < tile_size and (absf(from.x - points[1].x) < 0.5 or absf(from.y - points[1].y) < 0.5):
		points.remove_at(0)
	return points
