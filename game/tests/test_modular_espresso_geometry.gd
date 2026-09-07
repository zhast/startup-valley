extends SceneTree
## DEV-only geometry/material reuse. A green test is not appliance art approval.
const ESPRESSO := preload("res://tools/modular_espresso_geometry.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/modular-espresso"
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
	check(ESPRESSO.profile("bad").is_empty(), "Unknown side fails closed")
	check(ESPRESSO.face_source("bad").is_empty(), "Unknown material view fails closed")
	var records: Array[Dictionary] = []
	for side: String in ESPRESSO.SIDES:
		var p: Dictionary = ESPRESSO.profile(side)
		var ns := side in ["north", "south"]
		check(p.floor == (Rect2i(-14, -6, 29, 13) if ns else Rect2i(-6, -14, 13, 29)), side + " exact odd-pixel floor")
		check(p.rise == 31, side + " same31px physical rise")
		check(p.top == Rect2i(p.floor.position - Vector2i(0, 31), p.floor.size), side + " roof is physical plane raised31")
		check(p.visual_bounds.size == (Vector2i(29, 44) if ns else Vector2i(13, 60)), side + " screen height includes depth and rise")
		check(p.visual_bounds.end.y == p.floor.end.y and p.contact_y == p.floor.end.y, side + " ink reaches true floor boundary")
		check(p.floor.get_center() == Vector2i.ZERO, side + " integer anchor convention")
		check(Vector2(p.floor.position) + Vector2(p.floor.size) / 2.0 == p.odd_dimension_center, side + " geometric center offset is disclosed")
		check(Rect2i(Vector2i.ZERO, ESPRESSO.CANVAS).grow(-1).encloses(Rect2i(p.visual_bounds.position + ESPRESSO.PIVOT, p.visual_bounds.size)), side + " registered canvas contains full source with gutter")
		check(p.front.encloses(p.face_socket), side + " socket remains inside exact front")
		var counter: Dictionary = CABINET.profile("counter", side)
		check(counter.top_interior.encloses(Rect2i(p.floor.position - Vector2i(0, 32), p.floor.size)), side + " exact appliance contact fits actual counter wood")
		var record: Dictionary = ESPRESSO.face_source(side)
		check(not record.is_empty(), side + " rectangle is entirely near-opaque solid interior")
		if record.is_empty(): continue
		var data: Image = record.image
		check(data.get_size() == record.native_size, side + " native normalized dimensions")
		check(p.face_socket.encloses(Rect2i(record.position, record.native_size)), side + " uniformly normalized detail fits without aspect stretch")
		var crop: Rect2i = record.crop
		var factor: float = record.uniform_scale
		check(record.native_size == Vector2i(roundi(crop.size.x * factor), roundi(crop.size.y * factor)), side + " one shared scalar with nearest pixel rounding")
		var original := Image.load_from_file(ProjectSettings.globalize_path(record.source))
		original.convert(Image.FORMAT_RGBA8)
		var expected := original.get_region(crop)
		var expected_bytes := expected.get_data()
		for at: int in range(3, expected_bytes.size(), 4): expected_bytes[at] = 255
		expected = Image.create_from_data(crop.size.x, crop.size.y, false, Image.FORMAT_RGBA8, expected_bytes)
		expected.resize(record.native_size.x, record.native_size.y, Image.INTERPOLATE_NEAREST)
		check(expected.get_data() == data.get_data(), side + " output is exact cropped+point-normalized RGB and verified opacity normalization")
		var alpha := PIXELS.analyze(data)
		check(alpha.partial_alpha_pixels == 0 and alpha.transparent_pixels == 0, side + " opaque material has no silhouette mask / matte extraction")
		check(record.whole_source_alpha_accepted == ns, side + " failed E/W whole source remains unaccepted")
		var source_colors: Dictionary = {}
		var source_bytes := original.get_region(crop).get_data()
		for at: int in range(0, source_bytes.size(), 4): source_colors[source_bytes.slice(at, at + 3).hex_encode()] = true
		var unchanged_colors := true
		var output_bytes := data.get_data()
		for at: int in range(0, output_bytes.size(), 4):
			if not source_colors.has(output_bytes.slice(at, at + 3).hex_encode()): unchanged_colors = false
		check(unchanged_colors, side + " every material RGB pixel is from the original face crop")
		check(record.minimum_original_alpha >= 250, side + " near-opaque interior threshold excludes transparent silhouette edges")
		var node := ESPRESSO.new()
		root.add_child(node)
		check(node.configure(side), side + " builds volume and native face")
		check(node.scale == Vector2.ONE and is_zero_approx(node.rotation), side + " no finished-prop image transform")
		check(node.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, side + " native nearest sampling")
		check(node.layers.keys() == ESPRESSO.LAYERS, side + " separated registered top/housing/face")
		for name_value: String in ESPRESSO.LAYERS:
			var layer: Node2D = node.layers[name_value]
			check(layer.z_index == 0 and layer.position == Vector2.ZERO and layer.scale == Vector2.ONE and is_zero_approx(layer.rotation), side + " common registration and solid depth " + name_value)
		var before: Dictionary = node.resolved.duplicate(true)
		check(not node.configure("bad") and node.resolved == before, side + " rejected side leaves valid view intact")
		node.free()
		records.append({"side": side, "source": record.source, "sha256": record.source_sha256, "crop": PIXELS.rect_values(crop), "factor": factor,
			"native_size": [record.native_size.x, record.native_size.y], "padding": [record.padding.x, record.padding.y], "native_alpha": alpha,
			"minimum_original_alpha": record.minimum_original_alpha, "interior_opacity_normalized": record.interior_opacity_normalized,
			"source_is_not_silhouette": true, "whole_source_alpha_accepted": ns, "runtime_approved": false})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var out := FileAccess.open(OUTPUT.path_join("results-headless.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks": checks, "failures": failures, "views": records, "runtime_approved": false, "no_worker_save": true}, "\t") + "\n")
	await process_frame
	print("Modular espresso: %d checks, %d failures; opaque interior reuse only, no full kit approval." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
