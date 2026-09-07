extends SceneTree
## Deterministic actual-room review of the collaboration-table candidate. The
## source remains a calibration fixture until this evidence is scored.

const FIXTURE := preload("res://tools/collaboration_table_fixture.gd")
const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/collaboration-table-room"
const EXPORTS := "res://tests/fixtures/furniture-calibration/collaboration-table-v1/"
const PREFERRED_PIVOT := Vector2i(10, 13)

var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var pivot_cell := PREFERRED_PIVOT

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
	editor.select_placement(FIXTURE.TABLE_ID)
	editor.begin_move()
	for _index: int in range(4):
		if editor.preview_facing == side: break
		editor.rotate_preview()
	check(editor.preview_facing == side, side + " selected through authored rotation cycle")
	editor.preview_at(pivot_cell)
	check(editor.preview_result.valid, side + " candidate validates in the actual room: " + str(editor.preview_result.get("errors", [])))
	check(editor.commit_preview(), side + " commits through the real transactional editor")
	await frames(3)

func capture_side(side: String) -> Image:
	if DisplayServer.get_name() == "headless": return Image.new()
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	check(frame.get_size() == Vector2i(1280, 720), side + " capture is the actual native viewport")
	var path := OUTPUT.path_join("room-" + side + ".png")
	check(frame.save_png(path) == OK, "Save actual-room " + side)
	captures.append(path)
	var placement: Dictionary = fixture.main.room.placement_by_id(FIXTURE.TABLE_ID)
	var origin := Vector2i(placement.anchor) - GEOMETRY.PIVOT
	var detail := frame.get_region(Rect2i(origin, GEOMETRY.CANVAS))
	check(detail.get_size() == GEOMETRY.CANVAS, side + " registered native detail fits viewport")
	var detail_path := OUTPUT.path_join("detail-" + side + "-native.png")
	check(detail.save_png(detail_path) == OK, "Save native detail " + side)
	captures.append(detail_path)
	var enlarged := detail.duplicate()
	enlarged.resize(GEOMETRY.CANVAS.x * 4, GEOMETRY.CANVAS.y * 4, Image.INTERPOLATE_NEAREST)
	check(enlarged.save_png(OUTPUT.path_join("detail-" + side + "-4x.png")) == OK, "Save nearest detail " + side)
	captures.append(OUTPUT.path_join("detail-" + side + "-4x.png"))
	var expected := Image.load_from_file(ProjectSettings.globalize_path(EXPORTS + side + "-whole.png"))
	var mismatch := 0
	var opaque := 0
	for y: int in range(expected.get_height()):
		for x: int in range(expected.get_width()):
			var source := expected.get_pixel(x, y)
			if source.a < 0.99: continue
			opaque += 1
			var actual := detail.get_pixel(x, y)
			if absf(source.r - actual.r) > 0.01 or absf(source.g - actual.g) > 0.01 or absf(source.b - actual.b) > 0.01: mismatch += 1
	check(opaque > 0 and mismatch == 0, side + " actual-room composite preserves every opaque candidate pixel; mismatches=" + str(mismatch))
	observations.append({"facing": side, "anchor": [placement.anchor.x, placement.anchor.y], "service": [placement.interaction.x, placement.interaction.y], "visual_bounds": PIXELS.rect_values(placement.visual_bounds), "opaque_samples": opaque, "mismatches": mismatch})
	return detail

func check_profile(side: String) -> void:
	var room: TownRoom = fixture.main.room
	var placement: Dictionary = room.placement_by_id(FIXTURE.TABLE_ID)
	var service_world := room.layout_model.world(placement.interaction)
	check(placement.facing == side and placement.profile_kind == "service", side + " resolves as a standing shared prop")
	check(placement.service_side == side and placement.approach_gaze == OfficeLayout.OPPOSITE_GAZE[side], side + " service side and visitor gaze agree")
	check(room.interaction_world_position(FIXTURE.TABLE_ID) == service_world, side + " lunch destination uses the explicit service cell")
	check(room.lunch_position() == service_world, side + " production schedule lookup follows the rotated table")
	check(room.navigation.walkable(placement.interaction), side + " lunch/service cell is walkable")
	for occupied: Vector2i in placement.occupied:
		check(not room.navigation.walkable(occupied), side + " table footprint blocks navigation " + str(occupied))
	var path := room.navigation.path(fixture.main.player.position, service_world, "founder")
	check(not path.is_empty(), side + " actual founder can route to the service side")
	for point: Vector2 in path:
		check(room.navigation.position_is_safe(point, "founder"), side + " route remains outside table and walls")
	var layer_names: Array[String] = []
	for layer: Dictionary in placement.render_layers:
		layer_names.append(str(layer.name))
		check(str(layer.art).contains("/" + side + "-"), side + " owns direction-specific source " + str(layer.name))
		check(not layer.has("rotation") and not layer.has("scale") and not layer.has("flip_h") and not layer.has("flip_v"), side + " does not rotate/mirror/scale raster " + str(layer.name))
	check(layer_names == ["FloorShadow", "RearStructure", "FrontStructure"], side + " stable registered layer order")

func save_contact_sheet(details: Dictionary[String, Image]) -> void:
	if details.is_empty(): return
	var sheet := Image.create(GEOMETRY.CANVAS.x * 2, GEOMETRY.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	var order: Array[String] = ["north", "east", "south", "west"]
	for index: int in range(order.size()):
		var side := order[index]
		sheet.blit_rect(details[side], Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), Vector2i(index % 2, index / 2) * GEOMETRY.CANVAS)
	check(sheet.save_png(OUTPUT.path_join("actual-room-contact-sheet-native.png")) == OK, "Save four-view actual-room native contact sheet")
	captures.append(OUTPUT.path_join("actual-room-contact-sheet-native.png"))
	var enlarged := sheet.duplicate()
	enlarged.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	check(enlarged.save_png(OUTPUT.path_join("actual-room-contact-sheet-2x.png")) == OK, "Save four-view nearest contact sheet")
	captures.append(OUTPUT.path_join("actual-room-contact-sheet-2x.png"))

func check_fail_closed() -> void:
	var ordinary := OfficeLayout.new()
	var data: Dictionary = fixture.model.data.duplicate(true)
	var catalog: Dictionary = fixture.model.catalog.duplicate(true)
	ordinary.configure(data, catalog)
	check(ordinary.available_facings("collaboration_cluster").is_empty(), "Calibration permits never expose any unreviewed direction in an ordinary model")
	for side: String in OfficeLayout.FACINGS:
		var result := ordinary.resolve_profile("collaboration_cluster", side)
		check(not result.errors.is_empty(), side + " ordinary availability remains truthful")

func choose_common_pivot() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y: int in range(2, fixture.model.height - 2):
		for x: int in range(2, fixture.model.width - 2):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in OfficeLayout.FACINGS:
				if not fixture.model.validate_candidate(FIXTURE.TABLE_ID, point, side, 0).valid:
					valid = false
					break
			if valid: candidates.append(point)
	candidates.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		var left_distance: int = absi(left.x - PREFERRED_PIVOT.x) + absi(left.y - PREFERRED_PIVOT.y)
		var right_distance: int = absi(right.x - PREFERRED_PIVOT.x) + absi(right.y - PREFERRED_PIVOT.y)
		return left_distance < right_distance if left_distance != right_distance else left.y < right.y if left.y != right.y else left.x < right.x
	)
	check(not candidates.is_empty(), "At least one actual-room pivot supports all four honest views")
	return candidates[0] if not candidates.is_empty() else PREFERRED_PIVOT

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(5)
	check(fixture.ready_ok, "Collaboration-table actual-room fixture starts: " + str(fixture.errors))
	if not fixture.ready_ok:
		quit(1)
		return
	check_fail_closed()
	pivot_cell = choose_common_pivot()
	check(pivot_cell != Vector2i.ZERO, "Deterministic four-facing pivot selected: " + str(pivot_cell))
	var details: Dictionary[String, Image] = {}
	for side: String in ["north", "east", "south", "west"]:
		await select_side(side)
		check_profile(side)
		if DisplayServer.get_name() != "headless": details[side] = await capture_side(side)
	save_contact_sheet(details)
	var report := {
		"status": "actual_room_review_required",
		"checks": checks,
		"failures": failures,
		"captures": captures,
		"observations": observations,
		"worker_disabled": true,
		"save_access": false,
		"runtime_registered": false,
		"limitations": ["One standing lunch/service point per view.", "Visual scoring is required before production registration.", "No multi-seat character poses are claimed."],
	}
	var report_file := FileAccess.open(OUTPUT.path_join("results.json"), FileAccess.WRITE)
	check(report_file != null, "Open deterministic evidence manifest")
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "\t") + "\n")
		report_file.close()
	print("Collaboration-table room audit: %d checks, %d failures" % [checks, failures.size()])
	fixture.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
