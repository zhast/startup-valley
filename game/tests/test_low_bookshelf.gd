extends SceneTree
## Bounded native construction and actual passive room/editor/path study.
const ART := preload("res://tools/low_bookshelf_geometry.gd")
const FIXTURE := preload("res://tools/low_bookshelf_fixture.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/low-bookshelf"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var walks: Array[Dictionary] = []
var rendered := false
var native_insert: Image

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count := 2) -> void:
	for index: int in range(count): await process_frame

func parts(side: String) -> Dictionary[String, Image]:
	return ART.layers(side, native_insert if side == "south" else null)

func exports(write_files := false) -> void:
	if write_files:
		var valid_insert := native_insert != null and native_insert.get_size() == Vector2i(70, 24) and native_insert.detect_alpha() == Image.ALPHA_NONE
		check(valid_insert, "Actual measured-fit insert is intentionally opaque70×24; not a claimed88×24 export")
		if not valid_insert: return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART.ROOT))
	var hashes := {}
	var fake := Image.create(70, 24, false, Image.FORMAT_RGB8)
	fake.fill(Color.WHITE)
	check(ART.layers("east", fake).is_empty(), "A hidden South insert cannot be pasted onto an end")
	check(ART.profile("diagonal").is_empty(), "Unknown projection rejected")
	for side: String in ART.SIDES:
		var p := ART.profile(side)
		var layers := parts(side)
		check(layers.size() == 5, side + " five registered layers")
		var whole := ART.whole(layers)
		check(whole.get_size() == ART.CANVAS and whole.detect_alpha() == Image.ALPHA_BIT, side + " native binary alpha")
		check(whole.get_used_rect() == Rect2i(Vector2i(p.visual_bounds.position) + ART.PIVOT, p.visual_bounds.size), side + " exact opaque volume bounds")
		check(p.top.position == p.floor.position - Vector2i(0, 32) and p.top.end.y == p.face.position.y, side + " constant32px rise and exact top/face junction")
		check(p.plinth.size.y == 4 and p.plinth.end.y == p.floor.end.y, side + " solid plinth ends on actual ground boundary")
		check(whole.get_used_rect().position.x > 0 and whole.get_used_rect().position.y > 0 and whole.get_used_rect().end.x < ART.CANVAS.x and whole.get_used_rect().end.y < ART.CANVAS.y, side + " protected transparent padding")
		var tile := Image.load_from_file(ProjectSettings.globalize_path(p.top_material))
		var field: Rect2i = p.top_interior
		var matches := true
		for y: int in range(field.size.y):
			for x: int in range(field.size.x):
				if whole.get_pixelv(field.position + Vector2i(x, y) + ART.PIVOT) != tile.get_pixel(x % 32, y % 32): matches = false
		check(matches, side + " exact original axis tile at native size")
		check(whole.get_pixelv(Vector2i(p.top.position) + Vector2i.ONE + ART.PIVOT) == ART.LIGHT, side + " fixed screen upper-left light")
		if side == "south" and native_insert != null:
			check(whole.get_region(Rect2i(ART.PIVOT + Vector2i(p.content.position), p.content.size)).get_data() == PIXELS.rgba(native_insert).get_data(), "Registered South source pixels are exact")
			check(p.insert.size == Vector2i(88, 24) and p.content.position.x - p.insert.position.x == 9 and p.insert.end.x - p.content.end.x == 9, "Unchanged88×24bay has equal9px side gutters")
			check(whole.get_pixelv(ART.PIVOT + Vector2i(p.insert.position)) == ART.BAY and whole.get_pixelv(ART.PIVOT + Vector2i(p.insert.end) - Vector2i.ONE) == ART.BAY, "New geometry bay fill uses actual dominant source background")
		if side != "south": check(not layers.Insert.get_used_rect().has_area(), side + " no fabricated front content")
		hashes[side] = PIXELS.digest(whole.get_data())
		if write_files:
			for label: String in ART.LAYERS:
				var path := ART.ROOT + side + "-" + label.to_snake_case() + ".png"
				check(layers[label].save_png(path) == OK, "Export " + path)
				check(PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path))).get_data() == layers[label].get_data(), "Decoded native part identity")
			check(whole.save_png(ART.ROOT + side + "-whole.png") == OK, side + " whole export")
	check(hashes.east == hashes.west and hashes.south != hashes.north and hashes.north != hashes.east, "Plain end equivalence explicit; rear/front remain distinct")
	if write_files:
		var file := FileAccess.open(ART.ROOT + "manifest.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"status": "staged_unapproved", "native_canvas": [192, 224], "floor_pivot": [96, 160], "views": hashes, "equivalent_pairs": [["east", "west"]], "generated_content_source": ART.INSERT, "source_decoded_sha256": PIXELS.digest(PIXELS.rgba(native_insert).get_data()), "axis_tiles": [ART.OAK_HORIZONTAL, ART.OAK_VERTICAL], "layer_order": ART.LAYERS, "claims": "Only South has separately generated front content. No service/worker interaction, seat, cast shadow or production approval."}, "\t"))

func freeze() -> void:
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor.set_physics_process(false)

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func click(point: Vector2) -> void:
	var hover := InputEventMouseMotion.new()
	hover.position = point
	hover.global_position = point
	root.push_input(hover, true)
	await frames()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func capture(label: String, exact := false, detail := false) -> void:
	if not rendered: return
	fixture.place_editor_labels()
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), label + " native resolution")
	check(image.save_png(OUTPUT.path_join(label + ".png")) == OK, label + " saved")
	captures.append(label + ".png")
	var placement: Dictionary = fixture.main.room.placement_by_id("dev-low-shelf")
	if exact:
		var whole := ART.whole(parts(str(placement.facing)))
		var mismatches := 0
		for y: int in range(ART.CANVAS.y):
			for x: int in range(ART.CANVAS.x):
				var expected := whole.get_pixel(x, y)
				if expected.a < 0.99: continue
				var actual := image.get_pixelv(Vector2i(placement.anchor) - ART.PIVOT + Vector2i(x, y))
				if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatches += 1
		check(mismatches == 0, label + " actual room matches exact opaque layer union; mismatches " + str(mismatches))
	if detail:
		var bounds: Rect2 = placement.world_visual_bounds
		var crop := image.get_region(Rect2i(Vector2i(bounds.position) - Vector2i(24, 24), Vector2i(bounds.size) + Vector2i(48, 48)))
		crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
		check(crop.save_png(OUTPUT.path_join(label + "-4x.png")) == OK, label + " nearest4×")
		captures.append(label + "-4x.png")

func canonical() -> void:
	var model: OfficeLayout = fixture.model
	for side: String in ART.SIDES:
		var result := model.resolve_profile("low_bookshelf", side)
		check(result.errors.is_empty(), side + " exact local decorative admission")
		var p: Dictionary = result.profile
		check(p.clearance.is_empty() and not p.has("standing_viewpoints") and not p.has("interaction") and not p.has("work_cell") and not p.has("service_side"), side + " no fictional service or viewpoint")
		check(not p.review.art and not p.review.geometry, side + " candidate never claims approval")
		for layer: Dictionary in p.render_layers:
			var imported := PIXELS.rgba((load(layer.art) as Texture2D).get_image())
			check(imported.get_data() == PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(layer.art))).get_data(), side + " exact imported padding and pixels")
	check(fixture.main.room.interaction_world_position("dev-low-shelf") == Vector2(INF, INF), "No passive action destination")
	check(fixture.main.room.prop_node("dev-low-shelf") != null, "Canonical generic layer factory instantiated")
	check(not fixture.main._state_loaded and not fixture.main._worker_ready, "Disposable fixture avoids live worker and personal state")
	for stage: int in range(5): check(model.validate_placements(model.resolve_placements(stage)).valid, "Shelf preserves stage%d geometry" % stage)
	await capture("south-room", true, true)
	for index: int in range(4):
		await key(KEY_R)
		check(fixture.editor.placement_active and fixture.editor.preview_result.valid, "Actual R previews next physical orientation")
		var facing := str(fixture.editor._candidate.facing)
		await click(model.world(fixture.editor.preview_grid))
		freeze()
		check(not fixture.editor.placement_active and fixture.main.room.placement_by_id("dev-low-shelf").facing == facing, "Actual click commits " + facing)
		await capture(facing + "-committed", true, true)
		for id: String in ["founder", "mira", "theo"]:
			for front: bool in [false, true]: await actor_walk(id, front)
	var saved: Dictionary = fixture.main.room.placement_overrides.duplicate(true)
	await key(KEY_M)
	await click(model.world(Vector2i(1, 3)))
	check(fixture.editor.placement_active and not fixture.editor.preview_result.valid and fixture.main.room.placement_overrides == saved, "Wall placement rejected atomically")
	await capture("invalid-wall")
	await key(KEY_ESCAPE)
	await key(KEY_R)
	await click(model.world(fixture.editor.preview_grid))
	await key(KEY_U)
	freeze()
	check(fixture.main.room.placement_overrides == saved, "Real Undo restores exact committed placement")
	var saved_position: Vector2 = fixture.main.player.position
	var p: Dictionary = fixture.main.room.placement_by_id("dev-low-shelf")
	fixture.main.player.position = p.anchor + Vector2(0, 32)
	fixture.main.room.navigation.actors.founder = fixture.main.player.position
	await key(KEY_R)
	check(not fixture.editor.preview_result.valid, "Rotation rejects the founder in a newly blocked physical cell")
	await click(model.world(fixture.editor.preview_grid))
	check(fixture.main.room.placement_overrides == saved and fixture.main.player.position == p.anchor + Vector2(0, 32), "Occupied rotation rejects without changing layout or teleporting founder")
	await capture("occupied-rotation-rejected")
	await key(KEY_ESCAPE)
	fixture.main.player.position = saved_position
	fixture.main.room.navigation.actors.founder = saved_position
	freeze()
	check(not fixture.editor.export_layout(), "Candidate cannot export into a production layout")

func actor_walk(id: String, front: bool) -> void:
	var main: GameMain = fixture.main
	var room: TownRoom = main.room
	var pivot: Vector2 = room.placement_by_id("dev-low-shelf").anchor
	var side := str(room.placement_by_id("dev-low-shelf").facing)
	var radius := 32 if side in ["north", "south"] else 64
	var y := radius if front else -radius
	var start := pivot + Vector2(-96, y)
	var target := pivot + Vector2(96, y)
	var actor: Node2D = main.player if id == "founder" else main.get_employee(id)
	var before := actor.position
	actor.position = start
	actor.z_index = int(start.y)
	room.navigation.release(id)
	room.navigation.actors[id] = start
	if id == "founder":
		main.player.input_blocked = false
		await click(target)
		check(not main.player.route.is_empty() and main._pending_interaction.is_empty(), "Founder actual ground click walks, no passive action")
	else:
		var employee := actor as EmployeeAvatar
		employee.world_paused = false
		employee._idle_cooldown = 999
		employee.walk_to(target, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
	var label := side + "-" + id + ("-front" if front else "-behind")
	var positions: Array[Vector2] = [start]
	await capture(label + "-start")
	var middle := false
	var blocked := false
	var ticks := 0
	for index: int in range(180):
		actor._physics_process(1.0 / 30.0)
		ticks += 1
		if not room.navigation.position_is_safe(actor.position, id): blocked = true
		if not middle and actor.position.x >= pivot.x:
			positions.append(actor.position)
			await capture(label + "-middle", false, true)
			var overlap := 0
			var wrong_order := 0
			var bounds: Rect2 = room.placement_by_id("dev-low-shelf").world_visual_bounds
			for yy: int in range(int(bounds.position.y), int(bounds.end.y)):
				for xx: int in range(int(bounds.position.x), int(bounds.end.x)):
					var point := Vector2(xx + 0.5, yy + 0.5)
					var body: Sprite2D = actor.body_surface_at(point)
					var surface := room.surface_at(point)
					if body == null or surface.get("sprite") == null or (surface.sprite as Node).get_parent() != room.prop_node("dev-low-shelf"): continue
					overlap += 1
					if VisibleSurface.in_front(body, surface.sprite) != front: wrong_order += 1
			check(overlap > 0 and wrong_order == 0, label + " actual opaque actor/prop layering; overlap%d wrong%d" % [overlap, wrong_order])
			middle = true
		if rendered: await process_frame
		if actor.position.distance_to(target) < 1: break
	positions.append(actor.position)
	check(not blocked and actor.position.distance_to(target) < 1, label + " actual navigation stays clear and arrives")
	check(positions.size() == 3 and positions[0] != positions[1] and positions[1] != positions[2], label + " distinct actual motion checkpoints")
	await capture(label + "-end")
	walks.append({"name": label, "ticks": ticks, "positions": positions.map(func(p: Vector2) -> Array: return [p.x, p.y])})
	actor.position = before
	actor.z_index = int(before.y)
	room.navigation.actors[id] = before
	room.navigation.release(id)
	if id == "founder": main.player.cancel_route()
	freeze()

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	if FileAccess.file_exists(ART.INSERT): native_insert = Image.load_from_file(ProjectSettings.globalize_path(ART.INSERT))
	if "--export" in OS.get_cmdline_user_args() or "--preflight" in OS.get_cmdline_user_args():
		exports("--export" in OS.get_cmdline_user_args())
		print("Low bookshelf export: %d checks, %d failures" % [checks, failures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	rendered = DisplayServer.get_name() != "headless"
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(3)
	check(fixture.ready_ok, "Disposable shelf fixture: " + str(fixture.errors))
	if not fixture.ready_ok: fixture.queue_free(); await frames(); quit(1); return
	freeze()
	await canonical()
	var model: OfficeLayout = fixture.model
	fixture.queue_free()
	await frames(3)
	check(not model.resolve_profile("low_bookshelf", "south").errors.is_empty(), "Candidate permits revoked with fixture owner")
	var ordinary := OfficeLayout.new()
	ordinary.load_files()
	check(ordinary.catalog.has("low_bookshelf"), "Low resource shelf is registered in the ordinary production catalogue")
	var file := FileAccess.open(OUTPUT.path_join("manifest.json" if rendered else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "walks": walks, "runtime_approved": false, "source_status": "One generated South open-bay insert; code-native shelf with unchanged axis oak tiles", "limitations": ["Only South exposes generated open-bay content; closed E/W ends are equivalent.", "No new gameplay action, seat, shadow, production family or saving.", "Recorded visual review is required separately from these geometry checks."]}, "\t"))
	print("Low bookshelf: %d checks, %d failures, %d captures" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
