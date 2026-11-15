extends SceneTree
## Headless topology, pixel-join and navigation invariants; not visual approval.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		print("FENCE_CHECK_FAILED " + message)

func blend_piece(canvas: Image, atlas: Image, recipe: Dictionary, kind: String, point: Vector2i) -> void:
	var piece: Dictionary = recipe.pieces[kind]
	var rect := Rect2i(OfficeLayout.rectangle(piece.region))
	canvas.blend_rect(atlas, rect, point + Vector2i(80, 80) - OfficeLayout.vector(piece.pivot))

func one_connected_silhouette(image: Image) -> bool:
	var opaque: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5: opaque[Vector2i(x, y)] = true
	if opaque.is_empty(): return false
	var queue: Array[Vector2i] = [opaque.keys()[0]]
	var reached: Dictionary = {}
	var index := 0
	while index < queue.size():
		var point := queue[index]
		index += 1
		if reached.has(point) or not opaque.has(point): continue
		reached[point] = true
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			queue.append(point + direction)
	return reached.size() == opaque.size()

func run() -> void:
	var court := Courtyard.new()
	root.add_child(court)
	court.set_active(true)
	var floor_cells: Dictionary = court.navigation._floor.duplicate()
	check(floor_cells.size() == 373, "Original courtyard floor has exactly373 cells")
	var route := court.navigation.path(Courtyard.SPAWN, Vector2(144, 112), "founder")
	check(not route.is_empty(), "Original northwest route exists")
	var fence: YardFence = court.fence
	check(fence != null and fence.scale == Vector2.ONE, "Production courtyard uses native fence renderer")
	check(fence.edges.size() == 80 and fence.connections.size() == 81, "Original perimeter keeps80 rails and81 posts around the two-cell gate")
	var expected_opening: Array[Dictionary] = [{"from": Vector2i(15, 20), "to": Vector2i(16, 20)}, {"from": Vector2i(16, 20), "to": Vector2i(17, 20)}]
	check(fence.omitted_edges == expected_opening, "Only the two Studio entrance edges are omitted")
	for edge: Dictionary in YardFence.boundary_edges(floor_cells):
		check(fence.edges.has(edge) != expected_opening.has(edge), "Every other original boundary edge remains covered")
	check(fence.connections.get(Vector2i(15, 20)) == YardFence.WEST and fence.connections.get(Vector2i(17, 20)) == YardFence.EAST, "Gate has correctly connected terminal posts")
	check(not fence.connections.has(Vector2i(16, 20)), "No post blocks the center of the existing entrance")
	var data: Dictionary = OfficeLayout._read_json(Courtyard.LAYOUT_PATH)
	var gate: Dictionary = data.boundary_gates[0]
	var interaction := court.interaction_at(court.return_sign.position)
	check(gate.interaction_id == interaction.get("id") and interaction.get("point") == Courtyard.SPAWN, "Declared opening belongs to the real Studio return interaction")
	check(court.return_sign.position == Vector2(496, 608) and Courtyard.SPAWN == Vector2(496, 560), "Existing return sign and approach are unchanged")
	var seen: Dictionary = {}
	for edge: Dictionary in fence.edges:
		var start: Vector2i = edge["from"]
		var finish: Vector2i = edge["to"]
		check(start.distance_to(finish) == 1, "Fence segment spans one grid edge")
		var key := str(start) + str(finish)
		check(not seen.has(key), "Each exposed edge has exactly one rail")
		seen[key] = true
		var opposite := start + (Vector2i.UP if start.y == finish.y else Vector2i.LEFT)
		check(floor_cells.has(start) != floor_cells.has(opposite), "Fence separates actual floor from non-floor, never an internal lane")
	for vertex: Vector2i in fence.connections:
		var mask := int(fence.connections[vertex])
		if vertex in [Vector2i(15, 20), Vector2i(17, 20)]:
			check(mask in [2, 8], "Gate terminal has one explicit neighbor")
		else:
			check(mask in [3, 5, 6, 9, 10, 12], "Every non-gate post has two explicit neighbor connections")
	for child: Node in fence.get_children():
		check(child is Sprite2D and child.get_child_count() == 0, "Fence has no collision or gameplay nodes")
		check((child as Sprite2D).scale == Vector2.ONE and not (child as Sprite2D).z_as_relative, "Every module retains native scale and ground-based depth")
	check(court.navigation._floor == floor_cells and court.navigation.path(Courtyard.SPAWN, Vector2(144, 112), "founder") == route, "Fence creates no navigation mutation")
	var recipe: Dictionary = OfficeLayout._read_json(YardFence.RECIPE_PATH)
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(str(recipe.atlas)))
	check(atlas != null and atlas.get_size() == Vector2i(64, 64), "Registered original fence atlas loads")
	for mask: int in range(1, 16):
		var canvas := Image.create(160, 160, false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		var endpoints: Array[Vector2i] = [Vector2i.ZERO]
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var bit := YardFence.NORTH if direction == Vector2i.UP else YardFence.EAST if direction == Vector2i.RIGHT else YardFence.SOUTH if direction == Vector2i.DOWN else YardFence.WEST
			if (mask & bit) == 0: continue
			var endpoint := direction * YardFence.CELL
			var start := endpoint if direction in [Vector2i.UP, Vector2i.LEFT] else Vector2i.ZERO
			blend_piece(canvas, atlas, recipe, "horizontal" if direction.x != 0 else "vertical", start)
			endpoints.append(endpoint)
		for endpoint: Vector2i in endpoints: blend_piece(canvas, atlas, recipe, "post", endpoint)
		check(one_connected_silhouette(canvas), "Actual source pixels connect without gaps for neighbor mask%d" % mask)
	var broken := Image.create(160, 160, false, Image.FORMAT_RGBA8)
	broken.fill(Color.TRANSPARENT)
	blend_piece(broken, atlas, recipe, "post", Vector2i.ZERO)
	blend_piece(broken, atlas, recipe, "horizontal", Vector2i(16, 0))
	check(not one_connected_silhouette(broken), "Negative control rejects a displaced rail disconnected from its post")
	court.queue_free()
	await process_frame
	var report_path := OS.get_environment("STARTUP_VALLEY_FENCE_REPORT")
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		file.store_string(JSON.stringify({"scope": "headless exact-boundary topology, real pixel connectivity and navigation invariants; visual review remains separate", "checks": checks, "failures": failures, "engine": Engine.get_version_info(), "display": DisplayServer.get_name()}, "  "))
		file.close()
	print("Yard fence: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
