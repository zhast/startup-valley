extends SceneTree
## Dev-only, provider-free checks of staged designer toolkit files.

const DIRECTORY := "res://tests/fixtures/furniture-calibration/roles"
const SOURCE := "res://assets/source/overnight-20260904/roles/creative-north-v1.png"
const PARTS := {
	"tablet": {"bounds": Rect2i(83, 127, 24, 15), "opaque": 338},
	"swatches": {"bounds": Rect2i(58, 128, 12, 12), "opaque": 95},
	"camera": {"bounds": Rect2i(124, 119, 12, 12), "opaque": 130},
}
const PALETTE: Array[String] = ["151515", "363631", "5a5a51", "b6b5b0", "f1f1f1", "ece3ca", "c7b999", "1f2a4b", "253667", "354b98", "6196c1", "c1fa81", "83ab56", "b98544", "fa4616", "bd3210"]
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

func run() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	check(source != null and source.get_size() == Vector2i(1672, 940), "Original generated master has recorded1672x940 dimensions")
	check(source.detect_alpha() != Image.ALPHA_NONE, "Generated source has real alpha; no opaque checkerboard export is accepted")
	var union := Image.load_from_file(ProjectSettings.globalize_path(DIRECTORY.path_join("creative-north-v1.png")))
	check(union.get_size() == Vector2i(192, 224), "Combined sprite keeps full registered192x224 canvas")
	var reconstructed := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	var owners := PackedByteArray()
	owners.resize(192 * 224)
	var observed: Dictionary = {}
	var total := 0
	for part: String in PARTS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(DIRECTORY.path_join("creative-north-v1-%s.png" % part)))
		check(image.get_size() == Vector2i(192, 224), "Every component keeps the same registered canvas: " + part)
		check(image.get_used_rect() == PARTS[part].bounds, "Actual alpha bounds match recorded component: " + part)
		check(Rect2i(48, 112, 96, 32).encloses(image.get_used_rect()), "Complete art bounds fit96x32 north tabletop: " + part)
		var count := 0
		var intermediate_alpha := 0
		var colors: Dictionary = {}
		var outside_palette := 0
		for y: int in range(224):
			for x: int in range(192):
				var color := image.get_pixel(x, y)
				if color.a != 0.0 and color.a != 1.0: intermediate_alpha += 1
				if color.a == 0.0: continue
				count += 1
				owners[y * 192 + x] += 1
				colors[color.to_html(false)] = true
				if not PALETTE.has(color.to_html(false)): outside_palette += 1
				reconstructed.set_pixel(x, y, color)
		check(intermediate_alpha == 0, "Native alpha is binary without matte halos: " + part)
		check(outside_palette == 0, "Every opaque pixel uses the shared role-material palette: " + part)
		check(count == PARTS[part].opaque, "Opaque pixel count is reproducible: " + part)
		total += count
		observed[part] = {"bounds": [image.get_used_rect().position.x, image.get_used_rect().position.y, image.get_used_rect().size.x, image.get_used_rect().size.y], "opaque_pixels": count, "colors": colors.size()}
	check(owners.count(0) == 42445 and owners.count(1) == 563, "Three disjoint native objects preserve transparent gutters")
	check(total == 563, "Union retains all563 native opaque pixels")
	check(reconstructed.get_data() == union.get_data(), "Exact component union reproduces every combined RGBA byte")
	check(PARTS.swatches.bounds.size == Vector2i(12, 12), "Square generated fan remains square rather than being forced to12x8")
	var output := "res://tests/output/creative-north-kit"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output.path_join("results.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "staged_native_export_not_runtime_approved", "checks": checks, "failures": failures, "workerDisabled": true, "source": SOURCE, "canvas": [192, 224], "pivot": [96, 160], "parts": observed, "opaque_pixels": total, "transparent_pixels": 42445, "source_or_production_mutated": false}, "\t"))
	print("creative_north_kit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
