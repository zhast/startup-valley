extends SceneTree

const FIXTURE := preload("res://tools/decision_console_fixture.gd")
const GEOMETRY := preload("res://tools/decision_console_geometry.gd")
const OUTPUT := "res://tests/output/decision-console-room"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var pivot := Vector2i(10, 13)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for _index: int in range(count): await process_frame

func select_side(side: String) -> void:
	var editor = fixture.editor
	editor.select_placement(FIXTURE.CONSOLE_ID)
	editor.begin_move()
	for _index: int in range(4):
		if editor.preview_facing == side: break
		editor.rotate_preview()
	check(editor.preview_facing == side, side + " selected through authored cycle")
	editor.preview_at(pivot)
	check(editor.preview_result.valid, side + " validates in actual room")
	check(editor.commit_preview(), side + " commits through transactional editor")
	await frames(3)

func choose_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(2, fixture.model.height - 2):
		for x: int in range(2, fixture.model.width - 2):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in OfficeLayout.FACINGS:
				if not fixture.model.validate_candidate(FIXTURE.CONSOLE_ID, point, side, 0).valid:
					valid = false
					break
			if valid: choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(Vector2i(10, 13)) < b.distance_squared_to(Vector2i(10, 13)))
	check(not choices.is_empty(), "Actual room has a common four-facing pivot")
	return choices[0] if not choices.is_empty() else Vector2i(10, 13)

func inspect_side(side: String) -> Image:
	var room: TownRoom = fixture.main.room
	var placement := room.placement_by_id(FIXTURE.CONSOLE_ID)
	check(placement.facing == side and placement.profile_kind == "service", side + " is a standing service prop")
	check(placement.interaction in placement.clearance and room.navigation.walkable(placement.interaction), side + " has a walkable service cell")
	check(room.interaction_at(room.global_position + placement.world_hit_bounds.get_center()).id == FIXTURE.CONSOLE_ID, side + " hit surface resolves")
	var route := room.navigation.path(fixture.main.player.position, room.layout_model.world(placement.interaction), "founder")
	check(not route.is_empty(), side + " is reachable by the founder")
	for layer: Dictionary in placement.render_layers:
		check(str(layer.art).contains("/" + side + "-"), side + " owns independent art")
		check(not layer.has("rotation") and not layer.has("scale") and not layer.has("flip_h"), side + " has no raster transform")
	if DisplayServer.get_name() == "headless": return Image.new()
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var frame_path := OUTPUT.path_join("room-" + side + ".png")
	check(frame.save_png(frame_path) == OK, "Saved room " + side)
	captures.append(frame_path)
	var origin := Vector2i(placement.anchor) - GEOMETRY.PIVOT
	var detail := frame.get_region(Rect2i(origin, GEOMETRY.CANVAS))
	var detail_path := OUTPUT.path_join("detail-" + side + "-native.png")
	check(detail.save_png(detail_path) == OK, "Saved detail " + side)
	captures.append(detail_path)
	return detail

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(5)
	check(fixture.ready_ok, "Decision-console actual-room fixture starts: " + str(fixture.errors))
	if not fixture.ready_ok:
		quit(1)
		return
	var ordinary := OfficeLayout.new()
	ordinary.configure(fixture.model.data.duplicate(true), fixture.model.catalog.duplicate(true))
	check(ordinary.available_facings("approval_console").is_empty(), "Unreviewed console remains unavailable without live calibration owner")
	pivot = choose_pivot()
	var details: Dictionary[String, Image] = {}
	for side: String in OfficeLayout.FACINGS:
		await select_side(side)
		var detail := await inspect_side(side)
		if not detail.is_empty(): details[side] = detail
	if not details.is_empty():
		var sheet := Image.create(GEOMETRY.CANVAS.x * 2, GEOMETRY.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("151515"))
		for index: int in range(OfficeLayout.FACINGS.size()): sheet.blit_rect(details[OfficeLayout.FACINGS[index]], Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), Vector2i(index % 2, index / 2) * GEOMETRY.CANVAS)
		check(sheet.save_png(OUTPUT.path_join("actual-room-contact-sheet-native.png")) == OK, "Saved actual-room contact sheet")
		captures.append(OUTPUT.path_join("actual-room-contact-sheet-native.png"))
	var file := FileAccess.open(OUTPUT.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "actual_room_review_required", "checks": checks, "failures": failures, "captures": captures, "worker_disabled": true, "save_access": false, "runtime_registered": false}, "\t") + "\n")
	print("Decision-console room: %d checks, %d failures" % [checks, failures.size()])
	fixture.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
