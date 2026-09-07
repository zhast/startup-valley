extends SceneTree
const FIXTURE := preload("res://tools/prototype_bench_fixture.gd")
const G := preload("res://tools/prototype_bench_geometry.gd")
const OUTPUT := "res://tests/output/prototype-bench-room"
var fixture: Node; var checks := 0; var failures: Array[String] = []; var captures: Array[String] = []; var pivot := Vector2i(10, 13)
func _initialize() -> void: OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1"); call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count := 2) -> void:
	for _i: int in range(count): await process_frame
func choose_pivot() -> Vector2i:
	var choices: Array[Vector2i] = []
	for y: int in range(2, fixture.model.height - 2):
		for x: int in range(2, fixture.model.width - 2):
			var point := Vector2i(x, y); var valid := true
			for side: String in OfficeLayout.FACINGS:
				if not fixture.model.validate_candidate(FIXTURE.BENCH_ID, point, side, 0).valid: valid = false; break
			if valid: choices.append(point)
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(Vector2i(10, 13)) < b.distance_squared_to(Vector2i(10, 13)))
	check(not choices.is_empty(), "Common four-facing room pivot exists"); return choices[0] if not choices.is_empty() else Vector2i(10, 13)
func select_side(side: String) -> void:
	var editor = fixture.editor; editor.select_placement(FIXTURE.BENCH_ID); editor.begin_move()
	for _i: int in range(4):
		if editor.preview_facing == side: break
		editor.rotate_preview()
	editor.preview_at(pivot); check(editor.preview_facing == side and editor.preview_result.valid, side + " valid preview"); check(editor.commit_preview(), side + " transactional commit"); await frames(3)
func inspect(side: String) -> Image:
	var room: TownRoom = fixture.main.room; var placement := room.placement_by_id(FIXTURE.BENCH_ID)
	check(placement.facing == side and placement.profile_kind == "service", side + " standing station")
	check(placement.interaction in placement.clearance and room.navigation.walkable(placement.interaction), side + " clear service cell")
	check(not room.navigation.path(fixture.main.player.position, room.layout_model.world(placement.interaction), "founder").is_empty(), side + " founder route")
	for layer: Dictionary in placement.render_layers: check(str(layer.art).contains("/" + side + "-") and not layer.has("rotation") and not layer.has("scale"), side + " native layer")
	if DisplayServer.get_name() == "headless": return Image.new()
	await RenderingServer.frame_post_draw; var frame := root.get_texture().get_image(); var path := OUTPUT.path_join("room-" + side + ".png"); check(frame.save_png(path) == OK, "Save room " + side); captures.append(path)
	var detail := frame.get_region(Rect2i(Vector2i(placement.anchor) - G.PIVOT, G.CANVAS)); path = OUTPUT.path_join("detail-" + side + "-native.png"); check(detail.save_png(path) == OK, "Save detail " + side); captures.append(path); return detail
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)); fixture = FIXTURE.new(); root.add_child(fixture); await frames(5); check(fixture.ready_ok, "Prototype actual-room fixture starts: " + str(fixture.errors))
	if not fixture.ready_ok: quit(1); return
	var ordinary := OfficeLayout.new(); ordinary.configure(fixture.model.data.duplicate(true), fixture.model.catalog.duplicate(true)); check(ordinary.available_facings("prototype_bench").is_empty(), "Candidate unavailable without calibration owner")
	pivot = choose_pivot(); var details: Dictionary[String, Image] = {}
	for side: String in OfficeLayout.FACINGS:
		await select_side(side); var detail := await inspect(side); if not detail.is_empty(): details[side] = detail
	if not details.is_empty():
		var sheet := Image.create(G.CANVAS.x * 2, G.CANVAS.y * 2, false, Image.FORMAT_RGBA8); sheet.fill(Color("151515"))
		for i: int in range(4): sheet.blit_rect(details[OfficeLayout.FACINGS[i]], Rect2i(Vector2i.ZERO, G.CANVAS), Vector2i(i % 2, i / 2) * G.CANVAS)
		check(sheet.save_png(OUTPUT.path_join("actual-room-contact-sheet-native.png")) == OK, "Save contact sheet"); captures.append(OUTPUT.path_join("actual-room-contact-sheet-native.png"))
	var file := FileAccess.open(OUTPUT.path_join("results.json"), FileAccess.WRITE); file.store_string(JSON.stringify({"status": "actual_room_review_required", "checks": checks, "failures": failures, "captures": captures, "worker_disabled": true, "runtime_registered": false}, "\t") + "\n")
	print("Prototype bench room: %d checks, %d failures" % [checks, failures.size()]); fixture.queue_free(); await frames(); quit(0 if failures.is_empty() else 1)
