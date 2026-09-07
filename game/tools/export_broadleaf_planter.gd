extends SceneTree
## DEV ONLY. Provider-free deterministic broadleaf-planter export.

const PLANT := preload("res://tools/broadleaf_planter_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/broadleaf-planter-v1"
const EVIDENCE := "res://tests/output/broadleaf-planter"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func save(image: Image, path: String) -> Dictionary:
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and disk.get_data() == image.get_data(), "Exact PNG roundtrip " + path)
	var facts := PIXELS.analyze(image)
	return {
		"path": path.trim_prefix("res://../"),
		"canvas_size_px": [image.get_width(), image.get_height()],
		"floor_anchor_px": [PLANT.PIVOT.x, PLANT.PIVOT.y],
		"opaque_bounds_px": facts.opaque_bounds,
		"opaque_pixels": facts.opaque_pixels,
		"partial_alpha_pixels": facts.partial_alpha_pixels,
		"hidden_rgb_pixels": facts.hidden_rgb_pixels,
		"used_colors": facts.opaque_colors,
		"decoded_rgba_sha256": PIXELS.digest(image.get_data()),
		"sha256": FileAccess.get_sha256(path),
		"verify_decoded_facts": true,
	}

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var before := {
		"production": FileAccess.get_sha256(PRODUCTION_CATALOG),
		"layout": FileAccess.get_sha256(DEFAULT_LAYOUT),
		"catalogue": FileAccess.get_sha256(DEV_CATALOGUE),
	}
	var native := Image.create(PLANT.CANVAS.x * PLANT.SIDES.size(), PLANT.CANVAS.y, false, Image.FORMAT_RGBA8)
	native.fill(Color(0, 0, 0, 0))
	var layers_sheet := Image.create(PLANT.CANVAS.x * PLANT.SIDES.size(), PLANT.CANVAS.y * PLANT.LAYERS.size(), false, Image.FORMAT_RGBA8)
	layers_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(PLANT.SIDES.size()):
		var side: String = PLANT.SIDES[column]
		var parts := PLANT.layers(side)
		var whole := PLANT.whole(side)
		var exports: Array[Dictionary] = []
		for row: int in range(PLANT.LAYERS.size()):
			var layer_name: String = PLANT.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			var record := save(image, path)
			record.layer = layer_name
			record.source_layer = "BroadleafPlanter" + layer_name.to_pascal_case()
			record.z_offset = PLANT.layer_depth(layer_name)
			record.render_descriptor = PLANT.descriptor(side, layer_name)
			record.source_path = "game/tools/broadleaf_planter_geometry.gd"
			record.manifest_path = "game/tests/fixtures/furniture-calibration/broadleaf-planter-v1/manifest.json"
			record.review_path = "dev/BROADLEAF_PLANTER_NATIVE_REVIEW.md"
			record.method = "Exact deterministic code-native %s %s layer; no generated-source sampling or finished-raster transform." % [side, layer_name]
			exports.append(record)
			layers_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, PLANT.CANVAS), Vector2i(column * PLANT.CANVAS.x, row * PLANT.CANVAS.y))
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		var whole_record := save(whole, whole_path)
		whole_record.source_path = "game/tools/broadleaf_planter_geometry.gd"
		whole_record.manifest_path = "game/tests/fixtures/furniture-calibration/broadleaf-planter-v1/manifest.json"
		whole_record.review_path = "dev/BROADLEAF_PLANTER_NATIVE_REVIEW.md"
		whole_record.method = "Byte-exact ordered union of floor shadow, rear structure and front structure for native review only."
		native.blit_rect(whole, Rect2i(Vector2i.ZERO, PLANT.CANVAS), Vector2i(column * PLANT.CANVAS.x, 0))
		var p := PLANT.profile(side)
		directions.append({
			"facing": side,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"proposed_interaction_cell": p.interaction,
			"employee_look_vector": p.employee_look_vector,
			"leaf_count": p.leaves.size(),
			"pot_geometry": p.pot,
			"native_exports": exports,
			"composite_exports": [whole_record],
		})
	var native_record := save(native, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	var layer_record := save(layers_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	var enlarged := native.duplicate()
	enlarged.resize(native.get_width() * 4, native.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_record := save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == before.production, "Production catalogue unchanged")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == before.layout, "Default layout unchanged")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == before.catalogue, "Developer catalogue unchanged")
	var manifest := {
		"id": "broadleaf-planter-v1",
		"catalogue_family": "broadleaf_planter",
		"status": "native_review_candidate_not_runtime_registered",
		"asset_kind": "furniture_base",
		"canvas": [PLANT.CANVAS.x, PLANT.CANVAS.y],
		"pivot": [PLANT.PIVOT.x, PLANT.PIVOT.y],
		"sprite_offset": [PLANT.SPRITE_OFFSET.x, PLANT.SPRITE_OFFSET.y],
		"footprint_cells": [1, 1],
		"occupied_cell_offsets": [[0, 0]],
		"directions": directions,
		"failed_generated_references": [
			{
				"path": PLANT.SOURCE_V1.trim_prefix("res://"),
				"prompt_path": PLANT.PROMPT_V1.trim_prefix("res://../"),
				"sha256": FileAccess.get_sha256(PLANT.SOURCE_V1),
				"decoded_dimensions_px": [948, 1659],
				"decoded_format": "RGB8_without_alpha",
				"disposition": "Painted-checkerboard failure retained only as historical physical-identity reference; no pixels used in native export.",
			},
			{
				"path": PLANT.SOURCE_V2.trim_prefix("res://"),
				"prompt_path": PLANT.PROMPT_V2.trim_prefix("res://../"),
				"sha256": FileAccess.get_sha256(PLANT.SOURCE_V2),
				"decoded_dimensions_px": [949, 1658],
				"decoded_format": "RGB8_without_alpha",
				"disposition": "Painted-checkerboard retry failure retained only as historical physical-identity reference; no pixels used in native export.",
			},
		],
		"source_attempt_state": {
			"batch_one_attempts": 2,
			"batch_retry_limit_exhausted": false,
			"equivalent_alpha_only_method_closed": true,
			"reason": "Both built-in generations baked checkerboard cells into RGB pixels; repeating the same alpha request would not supply native transparency.",
		},
		"provenance": "Original editable code-native pixel construction: independently declared branch/leaf arrangements, ceramic pot geometry and fixed upper-left lighting for N/E/S/W. No source extraction, masking, keying, tracing, transform, provider call or ImageGen output.",
		"evidence": [native_record.path, enlarged_record.path, layer_record.path],
		"image_generation_used_for_native_candidate": false,
		"worker_disabled": true,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_files_changed": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Broadleaf planter export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
