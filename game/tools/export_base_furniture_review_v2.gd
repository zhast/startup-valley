extends SceneTree
## DEV ONLY. Exports the contact-shadow-only v2 review without overwriting v1.

const REVIEW := preload("res://tools/base_furniture_review_v2.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const EVIDENCE := "res://tests/output/base-furniture-review-2026-09-06"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
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

func save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and disk.get_data() == image.get_data(), "PNG roundtrip is exact: " + path)

func alpha_count(image: Image) -> int:
	var result := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var hashes := {
		PRODUCTION_CATALOG: FileAccess.get_sha256(PRODUCTION_CATALOG),
		DEFAULT_LAYOUT: FileAccess.get_sha256(DEFAULT_LAYOUT),
		DEV_CATALOGUE: FileAccess.get_sha256(DEV_CATALOGUE),
	}
	var records := {}
	for family: String in REVIEW.FAMILIES:
		var base: Variant = REVIEW.source(family)
		var output := REVIEW.output_root(family)
		var before_sheet := Image.create(base.CANVAS.x * 4, base.CANVAS.y, false, Image.FORMAT_RGBA8)
		var after_sheet := Image.create(base.CANVAS.x * 4, base.CANVAS.y, false, Image.FORMAT_RGBA8)
		before_sheet.fill(Color(0, 0, 0, 0))
		after_sheet.fill(Color(0, 0, 0, 0))
		var directions := {}
		for index: int in range(base.SIDES.size()):
			var side: String = base.SIDES[index]
			var old_parts: Dictionary[String, Image] = base.layers(side)
			var parts := REVIEW.layers(family, side)
			var old_whole: Image = base.whole(side)
			var whole := REVIEW.whole(family, side)
			var layer_records: Array[Dictionary] = []
			check((parts.rear_structure as Image).get_data() == (old_parts.rear_structure as Image).get_data(), family + " " + side + " rear structure remains byte-identical to v1")
			check((parts.front_structure as Image).get_data() == (old_parts.front_structure as Image).get_data(), family + " " + side + " front structure remains byte-identical to v1")
			check(whole.get_size() == base.CANVAS and whole.get_data() != old_whole.get_data(), family + " " + side + " changes only the assembled shadow result")
			for layer_name: String in base.LAYERS:
				var layer: Image = parts[layer_name]
				var path := output.path_join("%s-%s.png" % [side, layer_name])
				save(layer, path)
				var facts := PIXELS.analyze(layer)
				check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + " " + side + " " + layer_name + " keeps clean binary alpha")
				var descriptor := REVIEW.descriptor(family, side, layer_name)
				descriptor.measurements = facts
				descriptor.sha256 = FileAccess.get_sha256(path)
				descriptor.decoded_rgba_sha256 = PIXELS.digest(layer.get_data())
				layer_records.append(descriptor)
			var whole_path := output.path_join(side + "-whole.png")
			save(whole, whole_path)
			before_sheet.blit_rect(old_whole, Rect2i(Vector2i.ZERO, base.CANVAS), Vector2i(index * base.CANVAS.x, 0))
			after_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, base.CANVAS), Vector2i(index * base.CANVAS.x, 0))
			var old_shadow_pixels := alpha_count(old_parts.floor_shadow)
			var new_shadow_pixels := alpha_count(parts.floor_shadow)
			check(new_shadow_pixels > 0 and new_shadow_pixels * 3 < old_shadow_pixels, family + " " + side + " contact marks materially reduce the old lattice area")
			directions[side] = {
				"old_shadow_opaque_pixels": old_shadow_pixels,
				"new_shadow_opaque_pixels": new_shadow_pixels,
				"layers": layer_records,
				"rear_structure_sha256": FileAccess.get_sha256(output.path_join(side + "-rear_structure.png")),
				"front_structure_sha256": FileAccess.get_sha256(output.path_join(side + "-front_structure.png")),
				"whole_sha256": FileAccess.get_sha256(whole_path),
				"whole_rgba_sha256": PIXELS.digest(whole.get_data()),
				"whole_measurements": PIXELS.analyze(whole),
			}
		save(before_sheet, EVIDENCE.path_join(family + "-before-v1-native.png"))
		save(after_sheet, EVIDENCE.path_join(family + "-after-v2-native.png"))
		var comparison := Image.create(base.CANVAS.x * 4, base.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
		comparison.fill(Color(0, 0, 0, 0))
		comparison.blit_rect(before_sheet, Rect2i(Vector2i.ZERO, before_sheet.get_size()), Vector2i.ZERO)
		comparison.blit_rect(after_sheet, Rect2i(Vector2i.ZERO, after_sheet.get_size()), Vector2i(0, base.CANVAS.y))
		var comparison_4x := comparison.duplicate()
		comparison_4x.resize(comparison.get_width() * 4, comparison.get_height() * 4, Image.INTERPOLATE_NEAREST)
		save(comparison_4x, EVIDENCE.path_join(family + "-before-after-4x.png"))
		records[family] = {"revision": REVIEW.revision(family), "directions": directions}
		var fixture_manifest := {
			"id": REVIEW.revision(family),
			"catalogue_family": family,
			"status": "base_only_native_review_candidate_not_runtime_registered",
			"change_scope": "floor shadow only",
			"unchanged_from_v1": ["rear_structure", "front_structure", "canvas", "pivot", "sprite_offset", "footprint", "clearance", "overlay ownership"],
			"directions": directions,
			"runtime_registered": false,
			"production_catalogue_registered": false,
			"default_layout_registered": false,
		}
		var fixture_file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
		check(fixture_file != null, "Opened " + REVIEW.revision(family) + " manifest")
		if fixture_file != null:
			fixture_file.store_string(JSON.stringify(fixture_manifest, "\t") + "\n")
	for path: String in hashes:
		check(FileAccess.get_sha256(path) == hashes[path], "Exporter leaves " + path + " byte-identical")
	var manifest := {
		"status": "base_only_shadow_revision_not_runtime_registered",
		"date": "2026-09-06",
		"worker_disabled": true,
		"records": records,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(EVIDENCE.path_join("export-results.json"), FileAccess.WRITE)
	check(file != null, "Opened combined export results")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Base furniture v2 export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
