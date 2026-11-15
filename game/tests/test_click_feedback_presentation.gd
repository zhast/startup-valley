extends SceneTree
## Native click-marker geometry, contrast separation and pixel sampling.

const OUTPUT := "res://tests/output/click-feedback-current"
const POINT := Vector2(560, 400)

var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func color_near(actual: Color, expected: Color, tolerance: float = 0.04) -> bool:
	return absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b) + absf(actual.a - expected.a) <= tolerance

func merged(rects: Array[Rect2]) -> Rect2:
	var result := rects[0]
	for rect: Rect2 in rects.slice(1): result = result.merge(rect)
	return result

func capture(name_value: String) -> Image:
	if DisplayServer.get_name() == "headless": return null
	await frames()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var path := OUTPUT.path_join(name_value + ".png")
	check(image.save_png(path) == OK, "Saved native click-feedback capture: " + name_value)
	captures.append(path)
	return image

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	for pixels: PackedStringArray in [GameCursor.ARROW, GameCursor.HAND]:
		check(pixels.size() == 16, "Cursor has sixteen source rows")
		for row: String in pixels: check(row.length() == 16, "Cursor row fits its native grid")
	var arrow := GameCursor.texture(GameCursor.ARROW).get_image()
	var hand := GameCursor.texture(GameCursor.HAND).get_image()
	check(arrow.get_pixelv(GameCursor.ARROW_HOTSPOT).a == 1, "Arrow hotspot touches its visible tip")
	check(hand.get_pixelv(GameCursor.HAND_HOTSPOT).a == 1, "Hand hotspot touches its pointing fingertip")
	check(arrow.get_size() == Vector2i(32, 32) and hand.get_size() == Vector2i(32, 32), "Hardware cursors fit browser size limits")
	var cores := ClickFeedback.accepted_core_rects()
	var rims := ClickFeedback.accepted_rim_rects()
	check(cores.size() == 4 and rims.size() == 4, "Accepted marker keeps four cardinal sparks")
	for index: int in range(cores.size()):
		check(cores[index].position == cores[index].position.round() and rims[index].position == rims[index].position.round(), "Spark geometry stays on whole pixels")
		check(cores[index].get_center() == ClickFeedback.DOT_CENTERS[index] and rims[index].get_center() == ClickFeedback.DOT_CENTERS[index], "Core and rim share the authored destination-relative center")
	var core_bounds := merged(cores)
	var rim_bounds := merged(rims)
	check(is_equal_approx(core_bounds.position.x, -core_bounds.end.x) and is_equal_approx(core_bounds.position.y, -core_bounds.end.y), "Accepted core is centered exactly on the destination")
	check(is_equal_approx(rim_bounds.position.x, -rim_bounds.end.x) and is_equal_approx(rim_bounds.position.y, -rim_bounds.end.y), "Accepted rim is centered exactly on the destination")

	# Isolate the production marker on the production floor material. This keeps
	# the proof independent of mutable furniture/catalogue fixtures while still
	# exercising the actual CanvasItem renderer at the game's 1280x720 viewport.
	var floor_surface := TextureRect.new()
	floor_surface.texture = load("res://assets/runtime/office/architecture/floor.png") as Texture2D
	floor_surface.size = Vector2(1280, 720)
	floor_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_surface.stretch_mode = TextureRect.STRETCH_TILE
	floor_surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(floor_surface)
	var feedback := ClickFeedback.new()
	feedback.z_index = 1
	feedback.set_process(false)
	root.add_child(feedback)
	feedback.show_at(POINT + Vector2(0.49, 0.49), true)
	check(feedback.position == POINT, "Feedback origin snaps to the clicked world pixel")
	var accepted := await capture("accepted-marker")
	if accepted != null:
		for center: Vector2 in ClickFeedback.DOT_CENTERS:
			check(color_near(accepted.get_pixelv(Vector2i(POINT + center)), ClickFeedback.VALID), "Every accepted spark has a warm gold core")
		var rim_sample := POINT + rims[0].position
		check(color_near(accepted.get_pixelv(Vector2i(rim_sample)), ClickFeedback.INK), "Accepted marker has a crisp dark separation pixel on the pale floor")

	feedback.show_at(POINT, false)
	var rejected := await capture("rejected-marker")
	if rejected != null:
		check(color_near(rejected.get_pixelv(Vector2i(POINT)), ClickFeedback.INVALID), "Rejected marker retains its Vermilion center")
		check(color_near(rejected.get_pixelv(Vector2i(POINT + Vector2(-5, -8))), ClickFeedback.INK), "Rejected marker has a crisp dark separation pixel on the pale floor")
		check(feedback.position == POINT, "Accepted and rejected feedback share one exact hit origin")

	feedback.free()
	floor_surface.free()
	await process_frame
	var report := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "results.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "passed": failures.is_empty(), "renderer": DisplayServer.get_name(), "viewport": [1280, 720], "captures": captures, "workerDisabled": OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1"}, "\t"))
		report.close()
	print("Click feedback presentation: %d checks; %d failures" % [checks, failures.size()])
	quit(failures.size())
