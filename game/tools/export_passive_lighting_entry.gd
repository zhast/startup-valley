extends SceneTree
## DEV ONLY. Provider-free deterministic export for three passive candidates.

const ART := preload("res://tools/passive_lighting_entry_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const EVIDENCE_ROOTS := {
	"task_floor_lamp": "res://tests/output/task-floor-lamp-v2",
	"desk_lamp_kit": "res://tests/output/desk-lamp-kit-v2",
	"coat_bag_stand": "res://tests/output/coat-bag-stand-v3",
}
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

func save(family: String, image: Image, path: String) -> Dictionary:
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and disk.get_data() == image.get_data(), "Exact PNG roundtrip " + path)
	var facts := PIXELS.analyze(image)
	return {
		"path": path.trim_prefix("res://../"),
		"canvas_size_px": [image.get_width(), image.get_height()],
		"floor_anchor_px": [ART.pivot(family).x, ART.pivot(family).y],
		"opaque_bounds_px": facts.opaque_bounds,
		"opaque_pixels": facts.opaque_pixels,
		"partial_alpha_pixels": facts.partial_alpha_pixels,
		"hidden_rgb_pixels": facts.hidden_rgb_pixels,
		"used_colors": facts.opaque_colors,
		"decoded_rgba_sha256": PIXELS.digest(image.get_data()),
		"sha256": FileAccess.get_sha256(path),
		"verify_decoded_facts": true,
	}

func export_family(family: String) -> void:
	var output := str(ART.OUTPUT_ROOTS[family])
	var evidence := str(EVIDENCE_ROOTS[family])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	var size := ART.canvas(family)
	var layer_names := ART.layer_names(family)
	var native := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	var layers_sheet := Image.create(size.x * 4, size.y * layer_names.size(), false, Image.FORMAT_RGBA8)
	native.fill(Color(0, 0, 0, 0))
	layers_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[column]
		var parts := ART.layers(family, side)
		var whole := ART.whole(family, side)
		var exports: Array[Dictionary] = []
		for row: int in range(layer_names.size()):
			var layer_name: String = layer_names[row]
			var image: Image = parts[layer_name]
			var path := output.path_join("%s-%s.png" % [side, layer_name])
			var record := save(family, image, path)
			record.layer = layer_name
			record.source_layer = family.to_pascal_case() + layer_name.to_pascal_case()
			record.z_offset = ART.layer_depth(family, layer_name)
			record.render_descriptor = ART.descriptor(family, side, layer_name)
			record.source_path = "game/tools/passive_lighting_entry_geometry.gd"
			record.manifest_path = output.trim_prefix("res://").path_join("manifest.json").insert(0, "game/")
			record.review_path = "dev/PASSIVE_LIGHTING_ENTRY_NATIVE_REVIEW.md"
			record.method = "Exact deterministic code-native %s/%s layer; fixed screen light and no finished-raster transform." % [side, layer_name]
			exports.append(record)
			layers_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, row * size.y))
		var whole_path := output.path_join(side + "-whole.png")
		var whole_record := save(family, whole, whole_path)
		whole_record.source_path = "game/tools/passive_lighting_entry_geometry.gd"
		whole_record.manifest_path = output.trim_prefix("res://").path_join("manifest.json").insert(0, "game/")
		whole_record.review_path = "dev/PASSIVE_LIGHTING_ENTRY_NATIVE_REVIEW.md"
		whole_record.method = "Byte-exact ordered native-layer union for review only; no approval or runtime installation."
		native.blit_rect(whole, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, 0))
		var p := ART.profile(family, side)
		directions.append({
			"facing": side,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"proposed_interaction_cell": p.get("interaction"),
			"employee_look_vector": p.employee_look_vector,
			"authored_geometry": p,
			"native_exports": exports,
			"composite_exports": [whole_record],
		})
	var native_record := save(family, native, evidence.path_join("candidate-contact-sheet-native.png"))
	var layer_record := save(family, layers_sheet, evidence.path_join("candidate-layers-native.png"))
	var enlarged := native.duplicate()
	enlarged.resize(native.get_width() * 4, native.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_record := save(family, enlarged, evidence.path_join("candidate-contact-sheet-4x.png"))
	var manifest := {
		"id": ART.revision(family),
		"catalogue_family": family,
		"status": "native_review_candidate_not_runtime_registered",
		"canvas": [size.x, size.y],
		"pivot": [ART.pivot(family).x, ART.pivot(family).y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"directions": directions,
		"optional_ambient_overlay_exported": false,
		"optional_ambient_overlay_status": "planned_unclaimed" if family in ["task_floor_lamp", "desk_lamp_kit"] else "not_applicable",
		"provenance": "Original editable code-native pixel geometry with independent screen-axis projections and fixed upper-left material light. No provider, generated raster, source extraction, text, baked actor, interaction, service or runtime binding.",
		"evidence": [native_record.path, enlarged_record.path, layer_record.path],
		"image_generation_used": false,
		"worker_disabled": true,
		"runtime_registered": false,
		"dev_catalogue_mutated": false,
		"production_files_changed": false,
		"checks_at_write": checks,
		"failures_at_write": failures.duplicate(),
	}
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " fixture manifest")
	manifest.checks_at_write = checks
	manifest.failures_at_write = failures.duplicate()
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	var before := {
		"production": FileAccess.get_sha256(PRODUCTION_CATALOG),
		"layout": FileAccess.get_sha256(DEFAULT_LAYOUT),
		"catalogue": FileAccess.get_sha256(DEV_CATALOGUE),
	}
	for family: String in ART.FAMILIES:
		export_family(family)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == before.production, "Production catalogue unchanged")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == before.layout, "Default layout unchanged")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == before.catalogue, "Shared developer catalogue unchanged")
	print("Passive lighting/entry export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
