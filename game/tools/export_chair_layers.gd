extends SceneTree
## CPU-only exact region extraction from already reviewed E/W chair sources.
## No ImageGen, color/alpha alteration, source resize, rotation or runtime flags.
const EAST := preload("res://tools/calibration_chair_layers.gd")
const WEST := preload("res://tools/calibration_west_chair_layers.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/chair-layers-v1"
const EVIDENCE := "res://tests/output/chair-layer-export"
const CANVAS := Vector2i(96, 160)
const PIVOT := Vector2i(48, 112)
const DIRECTIONS: Array[String] = ["east", "west"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

static func profile(direction: String) -> Dictionary:
	if direction == "east": return EAST.partition("east")
	if direction == "west":
		var result: Dictionary = WEST.partition()
		result["front"] = result.near_arm
		return result
	return {}

static func ownership(p: Dictionary) -> PackedInt32Array:
	var owners := PackedInt32Array()
	owners.resize(CANVAS.x * CANVAS.y)
	for layer: String in ["rear", "front"]:
		for rectangle: Rect2i in p[layer]:
			if not Rect2i(Vector2i.ZERO, CANVAS).encloses(rectangle): return PackedInt32Array()
			for y: int in range(rectangle.position.y, rectangle.end.y):
				for x: int in range(rectangle.position.x, rectangle.end.x):
					owners[y * CANVAS.x + x] += 1
	return owners

static func copy_regions(source: Image, regions: Array) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	for rectangle: Rect2i in regions: result.blit_rect(source, rectangle, rectangle.position)
	return result

static func descriptor(direction: String, layer: String, measured: Dictionary) -> Dictionary:
	return {"name": "ChairRear" if layer == "rear" else "ChairNearArm",
		"art": OUTPUT.path_join(direction + "-" + layer + ".png"),
		"region": [0, 0, CANVAS.x, CANVAS.y], "offset": [0, -32],
		"z_offset": -5 if layer == "rear" else -3,
		"content_bounds": measured.opaque_bounds}

static func source_records() -> Array[Dictionary]:
	var paths: Array[String] = ["res://tools/calibration_chair_layers.gd", "res://tools/calibration_west_chair_layers.gd", "res://tools/export_chair_layers.gd", "res://tools/export_modular_desk_layers.gd"]
	for direction: String in DIRECTIONS: paths.append(str(profile(direction).source))
	var result: Array[Dictionary] = []
	for path: String in paths: result.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	return result

func save_png(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)
	var loaded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not loaded.is_empty() and PIXELS.rgba(loaded).get_data() == image.get_data(), "Exact PNG roundtrip " + path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var sources := source_records()
	for entry: Dictionary in sources: check(not str(entry.sha256).is_empty(), "Read existing source " + str(entry.path))
	var sheet := Image.create(4 * CANVAS.x, 2 * CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var records: Array[Dictionary] = []
	for row: int in range(DIRECTIONS.size()):
		var direction: String = DIRECTIONS[row]
		var p := profile(direction)
		var source := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(str(p.source))))
		check(source.get_size() == CANVAS and p.canvas == CANVAS and p.pivot == PIVOT, direction + " unchanged full canvas and pivot")
		var owners := ownership(p)
		var unique_ownership := owners.size() == CANVAS.x * CANVAS.y
		for count: int in owners: unique_ownership = unique_ownership and count == 1
		check(unique_ownership, direction + " every source pixel including padding has exactly one owner")
		var original := PIXELS.analyze(source)
		check(original.partial_alpha_pixels == 0 and original.hidden_rgb_pixels == 0, direction + " source already has clean binary alpha; no cleanup applied")
		var rear := copy_regions(source, p.rear)
		var front := copy_regions(source, p.front)
		var reunion := PIXELS.binary_over(rear, front)
		check(reunion.get_data() == source.get_data(), direction + " extracted layers reunite to exact source RGBA")
		var record := {"facing": direction, "canvas_size_px": [CANVAS.x, CANVAS.y], "floor_anchor_px": [PIVOT.x, PIVOT.y],
			"source": p.source, "source_rgba_sha256": PIXELS.digest(source.get_data()),
			"status": "exact_source_partition_not_runtime_approved", "source_measurements": original,
			"suggested_visual_socket_offset_from_work_foot": [12 if direction == "east" else -12, 0],
			"socket_status": "Static calibration reference only; not a physical work-cell relocation or gameplay approval.",
			"depth_reference": "Relative to desk anchor; E/W chair socket Y is unchanged. Rear -5 / lower actor -4 / near arm -3 / desk top -1. Final actor/desk assembly must be reviewed.",
			"render_layers": [], "partitions": {}, "measurements": {}}
		for layer: String in ["rear", "front"]:
			var image := rear if layer == "rear" else front
			var measured := PIXELS.analyze(image)
			check(measured.partial_alpha_pixels == 0 and measured.hidden_rgb_pixels == 0 and measured.opaque_pixels > 0, direction + layer + " genuine source pixels and transparent padding")
			var regions: Array = []
			for rect: Rect2i in p[layer]: regions.append(PIXELS.rect_values(rect))
			record.partitions[layer] = regions
			record.measurements[layer] = measured
			record.render_layers.append(descriptor(direction, layer, measured))
			save_png(image, OUTPUT.path_join(direction + "-" + layer + ".png"))
		check(int(record.measurements.rear.opaque_pixels) + int(record.measurements.front.opaque_pixels) == int(original.opaque_pixels), direction + " no duplicate or discarded opaque source pixels")
		sheet.blit_rect(source, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(0, row * CANVAS.y))
		sheet.blit_rect(rear, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(CANVAS.x, row * CANVAS.y))
		sheet.blit_rect(front, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(2 * CANVAS.x, row * CANVAS.y))
		sheet.blit_rect(reunion, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(3 * CANVAS.x, row * CANVAS.y))
		records.append(record)
	save_png(sheet, EVIDENCE.path_join("source-rear-arm-reunion-native.png"))
	var enlarged := sheet.duplicate() as Image
	enlarged.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save_png(enlarged, EVIDENCE.path_join("source-rear-arm-reunion-4x.png"))
	check(source_records() == sources, "Source PNGs and measured helpers remain unchanged")
	var manifest := {"id": "chair-layers-v1", "status": "dev_source_partition_not_runtime_ready", "worker_disabled": true,
		"export_method": "CPU Image.blit_rect of existing calibrated source regions; no new pixels, resize, alpha threshold or renderer.",
		"canvas_size_px": [CANVAS.x, CANVAS.y], "floor_anchor_px": [PIVOT.x, PIVOT.y], "source_files": sources,
		"directions": records, "runtime_registered": false, "north_south_changed": false,
		"semantic_front": "Near arm only, not a whole foreground chair.", "checks": checks, "failures": failures}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open dev-only layer manifest")
	manifest["checks"] = checks
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Chair native layer export: %d checks, %d failures; exact source extraction only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
