extends SceneTree
## Exact dev source partition and canonical texture import checks.
const EXPORT := preload("res://tools/export_chair_layers.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
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

func rectangle(values: Array) -> Rect2i:
	return Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))

func image(path: String) -> Image:
	check(FileAccess.file_exists(path), "PNG exists " + path)
	return PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))

func run() -> void:
	check(EXPORT.profile("north").is_empty() and EXPORT.profile("south").is_empty() and EXPORT.profile("diagonal").is_empty(), "Only reviewed E/W partitions exported; N/S untouched")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EXPORT.OUTPUT.path_join("manifest.json")))
	check(manifest.status == "dev_source_partition_not_runtime_ready" and not manifest.runtime_registered and not manifest.north_south_changed, "No new art/facing approval")
	check(manifest.worker_disabled and manifest.failures.is_empty(), "CPU exporter passed without worker")
	check(manifest.directions.size() == 2, "Exactly two independently authored source views")
	for source: Dictionary in manifest.source_files:
		check(str(source.sha256) == FileAccess.get_sha256(str(source.path)), "Source/helper hash unchanged " + str(source.path))
	var sheet := image(EXPORT.EVIDENCE.path_join("source-rear-arm-reunion-native.png"))
	var large := image(EXPORT.EVIDENCE.path_join("source-rear-arm-reunion-4x.png"))
	check(sheet.get_size() == Vector2i(384, 320), "Native proof uses unchanged96×160 cells")
	var enlarged := sheet.duplicate() as Image
	enlarged.resize(1536, 1280, Image.INTERPOLATE_NEAREST)
	check(large.get_size() == Vector2i(1536, 1280) and enlarged.get_data() == large.get_data(), "4× proof preserves exact pixel replication")
	for row: int in range(EXPORT.DIRECTIONS.size()):
		var direction: String = EXPORT.DIRECTIONS[row]
		var p: Dictionary = EXPORT.profile(direction)
		var record: Dictionary = manifest.directions[row]
		check(record.facing == direction, "Explicit E/W manifest order")
		check(p.canvas == EXPORT.CANVAS and p.pivot == EXPORT.PIVOT, direction + " stable source canvas/pivot")
		var expected: Array[Rect2i] = []
		expected.assign([Rect2i(44, 88, 14, 4), Rect2i(48, 92, 4, 1), Rect2i(48, 93, 3, 9)] if direction == "east" else [Rect2i(39, 89, 13, 4), Rect2i(44, 93, 4, 10)])
		check(p.front == expected, direction + " actual calibrated near-arm regions, not a mirrored substitute")
		var owners := EXPORT.ownership(p)
		var exact := owners.size() == 15360
		for count: int in owners: exact = exact and count == 1
		check(exact, direction + " all15360source pixels belong exactly once")
		var duplicate := p.duplicate(true)
		duplicate.front.append(expected[0])
		var bad := EXPORT.ownership(duplicate)
		check(2 in bad, direction + " duplicate ownership negative control fails")
		var hole := p.duplicate(true)
		hole.front.remove_at(0)
		check(0 in EXPORT.ownership(hole), direction + " missing source region negative control fails")
		var outside := p.duplicate(true)
		outside.front.append(Rect2i(-1, 0, 2, 2))
		check(EXPORT.ownership(outside).is_empty(), direction + " out-of-canvas source cut refuses")
		var source := image(str(p.source))
		var rear := image(EXPORT.OUTPUT.path_join(direction + "-rear.png"))
		var front := image(EXPORT.OUTPUT.path_join(direction + "-front.png"))
		var reunion := PIXELS.binary_over(rear, front)
		check(reunion.get_data() == source.get_data(), direction + " exactsource RGBA reunion")
		check(PIXELS.digest(reunion.get_data()) == record.source_rgba_sha256, direction + " standarddecodedRGBAhash matches")
		var source_ink := PIXELS.analyze(source)
		check(source_ink.opaque_pixels == (740 if direction == "east" else 660), direction + " originalsource ink count")
		for index: int in range(2):
			var layer := "rear" if index == 0 else "front"
			var art := rear if index == 0 else front
			var measured := PIXELS.analyze(art)
			var d: Dictionary = record.render_layers[index]
			check(art.get_size() == EXPORT.CANVAS and rectangle(d.region) == Rect2i(Vector2i.ZERO, EXPORT.CANVAS), direction + layer + " unchanged full padded region")
			check(measured.partial_alpha_pixels == 0 and measured.hidden_rgb_pixels == 0 and measured.transparent_pixels > 0, direction + layer + " exact true alpha, no newmask or halo")
			check(art.get_data() == EXPORT.copy_regions(source, p[layer]).get_data(), direction + layer + " every source byte preserved in original rectangle")
			check(measured.opaque_pixels == (659 if index == 0 else 81) if direction == "east" else measured.opaque_pixels == (574 if index == 0 else 86), direction + layer + " measured owned ink count")
			check(rectangle(d.content_bounds) == rectangle(measured.opaque_bounds), direction + layer + " protected bounds match ink, not canvas")
			check(Vector2i(d.offset[0], d.offset[1]) - EXPORT.CANVAS / 2 == -EXPORT.PIVOT, direction + layer + " canonical centered offset preserves48,112pivot")
			check(d.name == ("ChairRear" if index == 0 else "ChairNearArm") and int(d.z_offset) == (-5 if index == 0 else -3), direction + layer + " near-arm semantic and depth")
			check(not d.has("rotation") and not d.has("scale") and not d.has("flip_h"), direction + layer + " no runtime reshape")
			var tex := load(str(d.art)) as Texture2D
			check(tex != null and tex.get_size() == Vector2(EXPORT.CANVAS), direction + layer + " import native size")
			check(tex != null and PIXELS.rgba(tex.get_image()).get_data() == art.get_data(), direction + layer + " importedRGBA staysbyteexact")
			var config := ConfigFile.new()
			check(config.load(str(d.art) + ".import") == OK and config.get_value("params", "compress/mode", -1) == 0 and not config.get_value("params", "process/fix_alpha_border", true) and not config.get_value("params", "mipmaps/generate", true), direction + layer + " lossless no-border-fill import metadata")
		var canonical := OfficeLayout.render_layers({"render_layers": record.render_layers}, "ergonomic_chair")
		check(canonical.size() == 2 and canonical[0].name == "ChairRear" and canonical[1].name == "ChairNearArm", direction + " existing canonical reader accepts descriptors")
		var crops: Array[Image] = [source, rear, front, reunion]
		for column: int in range(4):
			check(crops[column].get_data() == sheet.get_region(Rect2i(column * 96, row * 160, 96, 160)).get_data(), direction + " contact sheet crop sourceidentity")
	var file := FileAccess.open(EXPORT.EVIDENCE.path_join("results-headless.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"checks": checks, "failures": failures, "worker_disabled": true, "rendered": false, "runtime_approved": false}, "\t") + "\n")
	print("Chair layer export tests: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
