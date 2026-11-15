extends SceneTree
## Deterministic source import only: crop generated alpha, nearest-neighbor
## registration, binary alpha. No semantic repainting and no runtime writes.

const BASE := "res://assets/source/furniture-scale-v1/"
const SPEC := {
	"cafe_chair": {"source": "cafe-chair-generated.png", "crop": [521, 738, 212, 367], "native_size": [32, 52], "canvas": [96, 160], "pivot": [48, 128], "top_left": [32, 92], "layer": "CafeChairBody", "occupied": [[0, 0]], "clearance": [[0, 1]]},
	"cafe_table": {"source": "cafe-table-generated.png", "crop": [412, 598, 430, 461], "native_size": [56, 48], "canvas": [96, 160], "pivot": [48, 128], "top_left": [20, 96], "layer": "CafeTableBody", "occupied": [[0, 0]], "clearance": [[0, 1]]},
	"phone_booth": {"source": "phone-booth-generated.png", "crop": [324, 151, 606, 1049], "native_size": [56, 112], "canvas": [128, 192], "pivot": [80, 160], "top_left": [36, 64], "layer": "PhoneBoothBody", "occupied": [[-1, 0], [0, 0]], "clearance": [[-1, 1], [0, 1]]},
}

func _initialize() -> void:
	var records: Dictionary = {}
	var profiles: Dictionary = {}
	for kind: String in SPEC:
		var spec: Dictionary = SPEC[kind]
		var source := Image.load_from_file(BASE.path_join(spec.source))
		var crop := Rect2i(spec.crop[0], spec.crop[1], spec.crop[2], spec.crop[3])
		var sampled := source.get_region(crop)
		sampled.resize(spec.native_size[0], spec.native_size[1], Image.INTERPOLATE_NEAREST)
		for y: int in range(sampled.get_height()):
			for x: int in range(sampled.get_width()):
				var color := sampled.get_pixel(x, y)
				color = Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else Color.TRANSPARENT
				sampled.set_pixel(x, y, color)
		var canvas := Image.create(spec.canvas[0], spec.canvas[1], false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(sampled, Rect2i(Vector2i.ZERO, sampled.get_size()), Vector2i(spec.top_left[0], spec.top_left[1]))
		var destination := BASE.path_join(kind.replace("_", "-") + "-native.png")
		if canvas.save_png(destination) != OK:
			push_error("Could not save " + destination)
			quit(1)
			return
		var ink := canvas.get_used_rect()
		var offset := [spec.canvas[0] / 2 - spec.pivot[0], spec.canvas[1] / 2 - spec.pivot[1]]
		var bounds := [ink.position.x - spec.pivot[0], ink.position.y - spec.pivot[1], ink.size.x, ink.size.y]
		profiles[kind] = {"status": "calibration_candidate", "review": {"art": false, "geometry": false}, "source_review": "furniture-scale-v1 candidate; not admitted", "preview_art": destination, "profile_kind": "decorative", "occupied": spec.occupied, "clearance": spec.clearance, "anchor_offset": [0, 0], "visual_bounds": bounds, "hit_bounds": bounds, "ambient_overlays": [], "standing_viewpoints": [{"cell": [0, 1], "visual_bounds": [-24, -76, 48, 84]}], "render_layers": [{"art": destination, "name": spec.layer, "offset": offset, "region": [0, 0, spec.canvas[0], spec.canvas[1]], "z_offset": 0, "content_bounds": [ink.position.x, ink.position.y, ink.size.x, ink.size.y]}]}
		records[kind] = {"source": BASE.path_join(spec.source), "source_sha256": FileAccess.get_sha256(BASE.path_join(spec.source)), "output": destination, "output_sha256": FileAccess.get_sha256(destination), "transform": spec, "sampling": "Godot Image.INTERPOLATE_NEAREST; alpha>=0.5 opaque; RGB unchanged", "painted_bounds": bounds, "status": "candidate_not_admitted"}
	for name: String in ["import-record.json", "candidate-profiles.json"]:
		var file := FileAccess.open(BASE.path_join(name), FileAccess.WRITE)
		file.store_string(JSON.stringify(records if name == "import-record.json" else profiles, "\t") + "\n")
	print("Imported 3 generated furniture candidates without changing runtime art or catalogs")
	quit()
