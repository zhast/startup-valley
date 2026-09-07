extends SceneTree
## Provider-free alpha, registration, support-hypothesis and composition checks.
const KIT := preload("res://tools/coffee_south_kit_calibration.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const OUTPUT := "res://tests/output/coffee-south-kit"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(KIT.SOURCE))
	check(source.get_size() == Vector2i(1774, 887), "Retained genuine-alpha source dimensions")
	check(source.has_mipmaps() == false and source.detect_alpha() != Image.ALPHA_NONE, "Source has real alpha, not a painted background")
	var source_data := PIXELS.rgba(source).get_data()
	var uncropped_opaque := 0
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			if source_data[(y * source.get_width() + x) * 4 + 3] < 128:
				continue
			var included := false
			for crop: Rect2i in KIT.CROPS.values():
				if crop.has_point(Vector2i(x, y)):
					included = true
					break
			if not included: uncropped_opaque += 1
	check(uncropped_opaque == 0, "Declared source crops retain every thresholded opaque pixel; outside=" + str(uncropped_opaque))
	var merged := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	merged.fill(Color(0, 0, 0, 0))
	var occupied: Dictionary = {}
	var profile: Dictionary = CABINET.profile("counter", "south")
	var alpha_total := 0
	for part: String in KIT.PARTS:
		var native := KIT.image(part)
		var measurement := PIXELS.analyze(native)
		check(native.get_size() == KIT.CANVAS, part + " full registered canvas")
		check(native.get_used_rect() == KIT.BOUNDS[part], part + " measured actual alpha bounds")
		check(measurement.partial_alpha_pixels == 0 and measurement.hidden_rgb_pixels == 0, part + " binary alpha with clean transparent padding")
		check(measurement.opaque_colors <= 47 and measurement.opaque_pixels > 0, part + " bounded shared palette, nonempty")
		check(Rect2i(Vector2i.ZERO, KIT.CANVAS).grow(-1).encloses(native.get_used_rect()), part + " no clipped silhouette at canvas edge")
		var contact: Rect2i = KIT.CONTACTS[part]
		check(profile.top_interior.encloses(contact), part + " conservative base contact stays inside actual wood rim")
		check(Rect2i(KIT.BOUNDS[part].position - KIT.PIVOT, KIT.BOUNDS[part].size).encloses(contact), part + " contact belongs to its own object, not distant empty canvas")
		var native_data := native.get_data()
		var duplicate_pixels := 0
		for at: int in range(0, native_data.size(), 4):
			if native_data[at + 3] == 0: continue
			if occupied.has(at): duplicate_pixels += 1
			occupied[at] = part
		check(duplicate_pixels == 0, part + " separately placed source objects do not overlap")
		alpha_total += int(measurement.opaque_pixels)
		merged = PIXELS.binary_over(merged, native)
	var union := KIT.image()
	check(merged.get_data() == union.get_data(), "All four registered parts reunite byte-identically with exported union")
	check(PIXELS.analyze(union).opaque_pixels == alpha_total, "Union retains every opaque source-native pixel exactly once")
	check(PIXELS.analyze(union).opaque_colors <= 47, "Combined native kit uses shared palette, not four unrelated quantizers")
	check(profile.service_cell == Vector2i(0, 1) and profile.approach_gaze == "north", "Service south is not seated gaze south")
	check(not profile.runtime_approved, "Passing mechanical checks is not production approval")
	var material := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	material.fill(Color("b6b5b0"))
	var tex := ImageTexture.create_from_image(material)
	var host := KIT.build(root, Vector2(336, 304), tex, tex, true)
	check(host != null and host.get_child_count() == 5, "One exact counter plus four independent pieces")
	for item: Node in host.get_children():
		var node := item as Node2D
		check(node.scale == Vector2.ONE and is_zero_approx(node.rotation), node.name + " native transform, no fake facing")
		if node is Sprite2D:
			var sprite := node as Sprite2D
			check(sprite.position == -Vector2(KIT.PIVOT) and not sprite.centered, sprite.name + " common explicit pivot")
			check(sprite.z_index == 0 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, sprite.name + " honest floor-depth and nearest sampling")
	host.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "source_sha256": FileAccess.get_sha256(KIT.SOURCE),
		"source_opaque_outside_crops": uncropped_opaque, "records": KIT.records(), "union": PIXELS.analyze(union),
		"runtime_approved": false, "new_interaction_implemented": false, "worker_started": false, "save_access": false}, "\t"))
	print("Coffee south kit: %d checks, %d failures; geometry hypotheses, not art approval." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
