extends SceneTree
## Provider-free checks of reclassified W calibration art, not visual approval.

const DIRECTORY := "res://tests/fixtures/furniture-calibration/roles"
const PREFIX := "lawyer-west-reclassified-v4"
const SOURCE := "res://assets/source/overnight-20260904/roles/lawyer-kit-east-v4.png"
const SOURCE_SHA256 := "2433507ee40add344a53bcb931cc12b2fc5cc66d711dd46e589ef4512a8c0335"
const PARTS := {
	"binders": {"bounds": Rect2i(86, 70, 12, 32), "opaque": 382, "contact": Rect2i(86, 82, 12, 20)},
	"folder": {"bounds": Rect2i(83, 147, 19, 27), "opaque": 493, "contact": Rect2i(83, 147, 19, 27)},
	"pen_cup": {"bounds": Rect2i(103, 74, 6, 12), "opaque": 67, "contact": Rect2i(103, 83, 6, 3)},
}
const PALETTE: Array[String] = ["151515", "363631", "5a5a51", "b6b5b0", "f1f1f1", "ece3ca", "c7b999", "1f2a4b", "253667", "354b98", "6196c1", "c1fa81", "83ab56", "b98544", "fa4616", "bd3210"]
const LIMITATIONS: Array[String] = [
	"Source was requested as east with incorrect identity instructions; source batch remains exhausted after one initial call and three retries.",
	"West leaf order and near binder spines fit north identity, but source folder tabs remain screen-right rather than on the outer top edge.",
	"Checkbox rows remain screen-upright rather than physically rotating with the page.",
	"Cup keeps north-like pen order; an actual west cup view is not proven.",
	"Uniform binder export is 12x32, not the desired 12x30; folder is 19x27 rather than 19x26.",
	"Contacts are proposed 2D geometry only; no actor interaction or four-view runtime acceptance is asserted.",
]
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

func rgba(image: Image) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	return image

func run() -> void:
	var source := rgba(Image.load_from_file(ProjectSettings.globalize_path(SOURCE)))
	check(source.get_size() == Vector2i(1672, 941), "Retained misdirected source dimensions stay unchanged")
	check(source.detect_alpha() != Image.ALPHA_NONE, "Existing source supplies genuine alpha")
	check(FileAccess.get_sha256(SOURCE) == SOURCE_SHA256, "Original source is preserved byte-for-byte")
	var union := rgba(Image.load_from_file(ProjectSettings.globalize_path(DIRECTORY.path_join(PREFIX + ".png"))))
	check(union.get_size() == Vector2i(192, 224), "Shared registered canvas remains192x224 with pivot96,160")
	var reconstructed := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	var owners := PackedByteArray()
	owners.resize(192 * 224)
	var observed: Dictionary = {}
	var total := 0
	var safe_wood := Rect2i(82, 82, 28, 92)
	var desktop_contacts: Array[Rect2i] = []
	for part: String in PARTS:
		var file_name := DIRECTORY.path_join(PREFIX + "-" + part + ".png")
		var image := rgba(Image.load_from_file(ProjectSettings.globalize_path(file_name)))
		var old := rgba(Image.load_from_file(ProjectSettings.globalize_path(DIRECTORY.path_join("lawyer-east-v4-" + part + ".png"))))
		var bounds: Rect2i = PARTS[part].bounds
		var contact: Rect2i = PARTS[part].contact
		check(image.get_size() == Vector2i(192, 224), "Full registered canvas: " + part)
		check(image.get_used_rect() == bounds, "Measured whole-object bounds, no target-size squeezing: " + part)
		check(image.get_region(bounds).get_data() == old.get_region(old.get_used_rect()).get_data(), "Old E export's complete object pixels are reused without mirroring or repainting: " + part)
		check(safe_wood.encloses(contact), "Proposed contact fits actual inset wood, not just outer tabletop rim: " + part)
		for previous: Rect2i in desktop_contacts:
			check(not previous.intersects(contact), "Proposed toolkit contacts are disjoint: " + part)
		desktop_contacts.append(contact)
		var opaque := 0
		var partial := 0
		var hidden := 0
		var outside_palette := 0
		for y: int in range(224):
			for x: int in range(192):
				var color := image.get_pixel(x, y)
				if color.a != 0.0 and color.a != 1.0: partial += 1
				if color.a == 0.0:
					if color.r != 0.0 or color.g != 0.0 or color.b != 0.0: hidden += 1
					continue
				opaque += 1
				if not PALETTE.has(color.to_html(false)): outside_palette += 1
				owners[y * 192 + x] += 1
				reconstructed.set_pixel(x, y, color)
		check(partial == 0, "Native silhouette alpha is binary: " + part)
		check(hidden == 0, "Transparent padding has zero RGB: " + part)
		check(outside_palette == 0, "Shared role-material palette is preserved: " + part)
		check(opaque == PARTS[part].opaque, "Measured opaque pixel count: " + part)
		total += opaque
		observed[part] = {"file": file_name, "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "proposed_contact": [contact.position.x, contact.position.y, contact.size.x, contact.size.y], "opaque_pixels": opaque}
	check(total == 942 and owners.count(1) == 942 and owners.count(0) == 42066, "No overlapping object pixels;942 opaque and42066 transparent")
	check(union.get_data() == reconstructed.get_data(), "Three objects reconstruct every combined RGBA byte")
	for computer_name: String in ["monitor", "keyboard", "mouse"]:
		var art := Image.load_from_file(ProjectSettings.globalize_path("res://tests/fixtures/furniture-calibration/kits/computer-west-v2-" + computer_name + ".png"))
		var art_bounds := art.get_used_rect()
		for part: String in PARTS:
			check(not art_bounds.intersects(PARTS[part].bounds), "Draft W toolkit avoids the current computer silhouette: " + part + "/" + computer_name)
	check(PARTS.binders.bounds.size == Vector2i(12, 32), "The2px binder-height discrepancy is recorded, not hidden by stretching")
	var output := "res://tests/output/lawyer-direction-identity"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var result := {"status": "reclassified_west_cleanup_required_not_approved", "source_request_direction": "east", "candidate_direction": "west", "source": SOURCE, "source_sha256": SOURCE_SHA256, "new_generation_requests": 0, "original_batch_calls": 4, "original_batch_exhausted": true, "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "canvas": [192, 224], "pivot": [96, 160], "parts": observed, "opaque_pixels": total, "transparent_pixels": 42066, "limitations": LIMITATIONS}
	var file := FileAccess.open(output.path_join("results.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t"))
	print("lawyer_direction_identity: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
