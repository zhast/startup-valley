extends SceneTree
## Deterministic collaboration-cluster-v2 export. The accepted directional
## task-chair components are registered into this table's unchanged native
## canvas; no source bitmap is rotated, mirrored, scaled, or repainted.

const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const FIXTURE := "res://tests/fixtures/furniture-calibration/collaboration-cluster-v2"
const RUNTIME := "res://assets/runtime/office/collaboration-cluster-v2"
const EVIDENCE := "res://tests/output/collaboration-cluster-v2"

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

func analyze(image: Image) -> Dictionary:
	var bounds := image.get_used_rect()
	var partial := 0
	var hidden := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.a < 1.0: partial += 1
			if pixel.a == 0.0 and (pixel.r != 0.0 or pixel.g != 0.0 or pixel.b != 0.0): hidden += 1
	return {"bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "partial_alpha": partial, "hidden_rgb": hidden}

func save_exact(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)
	var loaded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(loaded != null and loaded.get_size() == image.get_size() and loaded.get_data() == image.get_data(), "Exact PNG roundtrip " + path)

func run() -> void:
	for directory: String in [FIXTURE, RUNTIME, EVIDENCE]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var sheet := Image.create(GEOMETRY.CANVAS.x * 2, GEOMETRY.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	var records: Array[Dictionary] = []
	for index: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[index]
		var profile: Dictionary = GEOMETRY.profile(side)
		var layers: Dictionary[String, Image] = GEOMETRY.cluster_layers(side)
		var specs := GEOMETRY.cluster_specs(side, RUNTIME)
		check(layers.size() == specs.size() and layers.size() >= 7, side + " complete table-plus-four-chair layer set")
		check(profile.slots.size() == 4 and profile.clearance.size() == 4, side + " four explicit reusable seat sockets")
		var layer_records: Array[Dictionary] = []
		for spec: Dictionary in specs:
			var name := str(spec.name)
			check(layers.has(name), side + " generated layer " + name)
			if not layers.has(name): continue
			var image := layers[name] as Image
			var slug := side + "-" + name.to_snake_case() + ".png"
			var measured := analyze(image)
			check(measured.partial_alpha == 0 and measured.hidden_rgb == 0, side + " clean binary alpha " + name)
			check((image.get_used_rect() as Rect2i).has_area(), side + " nonempty layer " + name)
			save_exact(image, FIXTURE.path_join(slug))
			save_exact(image, RUNTIME.path_join(slug))
			check(FileAccess.get_sha256(FIXTURE.path_join(slug)) == FileAccess.get_sha256(RUNTIME.path_join(slug)), side + " runtime byte-match " + name)
			layer_records.append({"name": name, "fixture": FIXTURE.path_join(slug), "runtime": RUNTIME.path_join(slug), "sha256": FileAccess.get_sha256(RUNTIME.path_join(slug)), "z_offset": int(spec.z_offset), "measurements": measured})
		var whole := GEOMETRY.cluster_whole(side)
		var whole_name := side + "-whole.png"
		save_exact(whole, FIXTURE.path_join(whole_name))
		var whole_measure := analyze(whole)
		check(whole_measure.partial_alpha == 0 and whole_measure.hidden_rgb == 0, side + " composite clean binary alpha")
		check(whole.get_used_rect().position.x > 0 and whole.get_used_rect().position.y > 0 and whole.get_used_rect().end.x < GEOMETRY.CANVAS.x and whole.get_used_rect().end.y < GEOMETRY.CANVAS.y, side + " cluster is unclipped inside registered canvas")
		sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), Vector2i(index % 2, index / 2) * GEOMETRY.CANVAS)
		records.append({"facing": side, "profile": profile, "production_profile": GEOMETRY.production_profile(side), "whole": {"path": FIXTURE.path_join(whole_name), "sha256": FileAccess.get_sha256(FIXTURE.path_join(whole_name)), "measurements": whole_measure}, "layers": layer_records})
	save_exact(sheet, EVIDENCE.path_join("component-contact-sheet-native.png"))
	var enlarged := sheet.duplicate()
	enlarged.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	save_exact(enlarged, EVIDENCE.path_join("component-contact-sheet-2x.png"))
	var manifest := {
		"id": "collaboration-cluster-v2", "status": "native_review_candidate_not_runtime_registered",
		"checks": checks, "failures": failures, "canvas": [GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y],
		"pivot": [GEOMETRY.PIVOT.x, GEOMETRY.PIVOT.y], "directions": records,
		"chair_source_revision": "workstations-v2", "chair_sources": GEOMETRY.CHAIR_PATHS,
		"method": "Code-native table layers plus byte-preserving registration of already reviewed directional task-chair components. South/West table pivots are corrected as complete-layer translations; no finished bitmap rotation, mirror, scale, crop, or repaint.",
	}
	var file := FileAccess.open(FIXTURE.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open collaboration-cluster-v2 manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	print("Collaboration cluster export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
