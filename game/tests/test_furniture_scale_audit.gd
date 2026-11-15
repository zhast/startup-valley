extends SceneTree
## Same-scene native comparison. This audit records deficiencies; it does not
## admit art or change production sizing. Red crosses are declared ground pivots.

var surface: SubViewport
var room: TownRoom
var output: String
var facts: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []

class Board extends Node2D:
	var captions: Array[Dictionary] = []
	var floor_art: Texture2D = preload("res://assets/runtime/office/architecture/floor.png")
	func _draw() -> void:
		for y: int in range(0, 720, 32):
			for x: int in range(0, 1280, 32): draw_texture_rect_region(floor_art, Rect2(x, y, 32, 32), Rect2(0, 0, 32, 32))
		for y: int in [272, 592]: draw_line(Vector2(40, y), Vector2(1230, y), Color("ac504b"), 1)
		for item: Dictionary in captions:
			var point: Vector2 = item.point
			draw_line(point - Vector2(6, 0), point + Vector2(6, 0), Color("ac504b"), 1)
			draw_line(point - Vector2(0, 6), point + Vector2(0, 6), Color("ac504b"), 1)
			draw_string(GameFonts.BODY, item.label_point, item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("3b2c25"))
		draw_string(GameFonts.BOLD, Vector2(40, 35), "FURNITURE SCALE AUDIT · native pixels · all nodes 1× · red line/cross = declared ground", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3b2c25"))
		draw_string(GameFonts.BODY, Vector2(40, 380), "Bottom: office chair uses its work-cell ground datum; occupied desks use actual EmployeeAvatar seating.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("3b2c25"))

var board: Board

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func label(text: String, point: Vector2, offset: Vector2 = Vector2(-55, 88)) -> void:
	board.captions.append({"point": point, "label_point": point + offset, "label": text})

func actor_reference(id: String, point: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = CharacterArt.locomotion_sheet(id)
	sprite.region_enabled = true
	sprite.region_rect = CharacterArt.locomotion_region(&"front", 0)
	sprite.position = point + Vector2(0, -32)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	surface.add_child(sprite)
	sprite.z_index = int(point.y)
	var ink := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect)).get_used_rect()
	facts.append({"id": id, "frame": "front idle 0", "canvas": [48, 80], "ink": [ink.position.x, ink.position.y, ink.size.x, ink.size.y], "declared_feet": [point.x, point.y]})
	label(id, point, Vector2(-20, 88))

func prop(kind: String, facing: String, grid: Vector2i, id: String) -> Dictionary:
	var value := room.layout_model.resolve({"id": id, "kind": kind, "grid": [grid.x, grid.y], "facing": facing, "owner_id": "mira" if id.begins_with("occupied") else ""})
	check(value.direction_errors.is_empty(), id + " resolves actual production profile")
	var node := Node2D.new()
	node.position = value.anchor
	node.z_index = int(node.position.y)
	surface.add_child(node)
	room._apply_profile(node, value)
	room.resolved_placements.append(value)
	for child: Node in node.get_children():
		if child is Sprite2D:
			check(child.scale == Vector2.ONE and child.rotation == 0, id + " native unit scale")
			var sprite := child as Sprite2D
			var ink := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect)).get_used_rect()
			facts.append({"id": id, "layer": child.name, "canvas": [sprite.region_rect.size.x, sprite.region_rect.size.y], "ink": [ink.position.x, ink.position.y, ink.size.x, ink.size.y], "offset": [sprite.position.x, sprite.position.y], "anchor": [node.position.x, node.position.y], "scale": [sprite.scale.x, sprite.scale.y]})
	return value

func occupied(facing: String, grid: Vector2i) -> void:
	var id := "occupied-" + facing
	var value := prop("desk", facing, grid, id)
	var record := EmployeeRecord.new()
	record.id = "mira"
	record.display_name = "Mina"
	record.desk_grid = grid
	var point := room.grid_to_world_position(value.work_cell)
	var actor := load("res://actors/employee_avatar.tscn").instantiate() as EmployeeAvatar
	actor.configure(record, point, point, point)
	surface.add_child(actor)
	check(actor.configure_workstation_visual(room._workstation_visual(id)), "Actual occupied " + facing + " metadata validates")
	actor.world_paused = true
	actor.labels_suppressed = true
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._update_character_frame()
	label("Mina seated / " + facing, value.anchor, Vector2(-60, 104))

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_SCALE_OUTPUT")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.unfocusable = true
	root.mouse_passthrough = true
	surface = SubViewport.new()
	surface.size = root.size
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	board = Board.new()
	board.z_index = -1000
	surface.add_child(board)
	room = TownRoom.new()
	surface.add_child(room)
	room.layout_model = OfficeLayout.new()
	check(room.layout_model.load_files(), "Actual catalogs load")
	actor_reference("founder", Vector2(80, 272))
	actor_reference("mira", Vector2(144, 272))
	var desk := prop("desk", "south", Vector2i(9, 8), "desk-south")
	label("Desk + office chair", desk.anchor)
	var cafe := prop("cafe_chair", "south", Vector2i(15, 8), "cafe-chair")
	label("Café chair", cafe.anchor)
	var visitor := prop("visitor_chair", "south", Vector2i(20, 8), "visitor-chair")
	label("Visitor chair", visitor.anchor)
	var booth := prop("phone_booth", "south", Vector2i(27, 8), "phone-booth")
	label("Phone booth", booth.anchor)
	actor_reference("founder", Vector2(1008, 272))
	# Repeat the same desk chair pixels at the host's work-cell ground anchor;
	# no image resize/repaint or invented freestanding furniture profile.
	for layer: Dictionary in desk.render_layers:
		if not str(layer.name).begins_with("Chair"): continue
		var sprite := Sprite2D.new()
		sprite.texture = load(layer.art)
		sprite.region_enabled = true
		sprite.region_rect = OfficeLayout.rectangle(layer.region)
		sprite.position = Vector2(176, 624) + Vector2(OfficeLayout.vector(layer.offset))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		surface.add_child(sprite)
	label("Office chair", Vector2(176, 592))
	actor_reference("mira", Vector2(240, 592))
	var east := prop("visitor_chair", "east", Vector2i(12, 18), "visitor-east")
	label("Visitor / east", east.anchor)
	occupied("south", Vector2i(22, 18))
	occupied("east", Vector2i(32, 18))
	board.queue_redraw()
	await create_timer(0.4).timeout
	RenderingServer.force_draw(false)
	check(surface.get_texture().get_image().save_png(output.path_join("native-lineup.png")) == OK, "Native lineup saved")
	actor_reference("founder", Vector2(880, 328))
	label("Door comparison only; no entry action", Vector2(880, 328), Vector2(-115, 75))
	board.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	check(surface.get_texture().get_image().save_png(output.path_join("booth-door-reference.png")) == OK, "Booth opening reference saved")
	var file := FileAccess.open(output.path_join("scale-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "native furniture comparison, not visual approval", "engine": Engine.get_version_info(), "checks": checks, "failures": failures, "facts": facts}, "  "))
	file.close()
	surface.queue_free()
	await process_frame
	print("Furniture audit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
