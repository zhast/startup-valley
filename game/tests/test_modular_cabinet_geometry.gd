extends SceneTree
## Provider-free dev geometry checks; passing is not production art approval.
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const OUTPUT := "res://tests/output/modular-cabinet-calibration"
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

func texture(size_value: Vector2i) -> ImageTexture:
	var image := Image.create(size_value.x, size_value.y, false, Image.FORMAT_RGBA8)
	image.fill(Color("f1f1f1"))
	return ImageTexture.create_from_image(image)

func run() -> void:
	check(CABINET.profile("desk", "south").is_empty(), "Unknown family fails closed")
	check(CABINET.profile("counter", "diagonal").is_empty(), "Unknown service side fails closed")
	for family: String in CABINET.FAMILIES:
		for side: String in CABINET.SIDES:
			var p: Dictionary = CABINET.profile(family, side)
			var key := family + " " + side
			var horizontal := side in ["north", "south"]
			var expected_floor := Rect2i(-48, -16, 96, 32) if horizontal else Rect2i(-16, -48, 32, 96)
			var expected_rise := 32 if family == "counter" else 64
			check(p.floor == expected_floor, key + " exact independent floor axes")
			check(p.rise == expected_rise, key + " physical height preserved")
			check(p.top == Rect2i(expected_floor.position - Vector2i(0, expected_rise), expected_floor.size), key + " raised roof keeps floor depth")
			check(p.top_interior == p.top.grow(-2), key + " support excludes actual raised rim")
			check(p.contact_y == expected_floor.end.y and p.plinth.end.y == p.contact_y, key + " exact near floor contact")
			check(p.visual_bounds.end.y == p.contact_y, key + " artwork reaches floor without padded collision")
			check(p.visual_bounds.position == p.top.position and p.visual_bounds.size.y == expected_floor.size.y + expected_rise, key + " ink silhouette distinguishes rise and depth")
			var registered: Rect2i = p.visual_bounds
			registered.position += p.pivot
			check(Rect2i(Vector2i.ZERO, p.canvas).grow(-1).encloses(registered), key + " full padded canvas contains all ink")
			check(p.canvas == (Vector2i(192, 256) if family == "counter" else Vector2i(192, 288)), key + " family canvas")
			check(p.pivot == (Vector2i(96, 192) if family == "counter" else Vector2i(96, 224)), key + " common family pivot")
			check(not p.occupied.has(p.service_cell), key + " service cell outside collision")
			check(p.clearance.has(p.service_cell), key + " service row includes approach destination")
			for cell: Vector2i in p.clearance:
				check(not p.occupied.has(cell), key + " clearance does not intersect body")
			check({"north": "south", "east": "west", "south": "north", "west": "east"}[side] == p.approach_gaze, key + " gaze points toward service side")
			for forbidden: String in ["facing", "work_gaze", "seat_anchor", "seat_reference", "pose_set", "work_cell"]:
				check(not p.has(forbidden), key + " no chair or ambiguous gaze metadata " + forbidden)
			check(not p.runtime_approved, key + " calibration never enables production")
			var cabinet := CABINET.new()
			root.add_child(cabinet)
			check(cabinet.configure(family, side, texture(Vector2i(32, 32)), texture(Vector2i(32, 32))), key + " builds native materials")
			check(cabinet.material_ready and cabinet.scale == Vector2.ONE and is_zero_approx(cabinet.rotation), key + " material stays native without rotation")
			check(cabinet.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, key + " nearest material sampling")
			check(cabinet.get_child_count() == 5 and cabinet.layers.keys() == CABINET.LAYERS, key + " separate registered layers")
			for layer_name: String in CABINET.LAYERS:
				var layer: Node2D = cabinet.layers[layer_name]
				check(layer.position == Vector2.ZERO and layer.scale == Vector2.ONE and is_zero_approx(layer.rotation), key + " shared layer registration " + layer_name)
				check(layer.z_index == 0, key + " solid cabinet keeps common floor depth " + layer_name)
			check(cabinet.set_service_insert(null), key + " can clear optional insert")
			if side == "south":
				check(p.insert_socket == Rect2i(-44, -12 if family == "counter" else -44, 88, expected_rise - 8), key + " exact flat front insert")
				check(p.front.encloses(p.insert_socket) and not p.plinth.intersects(p.insert_socket), key + " insert avoids structural edges/plinth")
				check(cabinet.set_service_insert(texture(p.insert_socket.size)), key + " native insert accepted")
				check(cabinet.layers.Insert.texture_position == p.insert_socket.position, key + " insert draws at true native position")
				check(not cabinet.set_service_insert(texture(p.insert_socket.size + Vector2i.ONE)), key + " insert cannot stretch to fit")
			else:
				check(not p.insert_socket.has_area() and not p.insert_visible, key + " hidden/edge-on service details honest")
				check(not cabinet.set_service_insert(texture(Vector2i(88, expected_rise - 8))), key + " front cannot be reused sideways/rearward")
			var before := cabinet.resolved.duplicate(true)
			check(not cabinet.configure(family, "bad") and cabinet.resolved == before, key + " invalid side preserves current view")
			check(not cabinet.configure(family, side, texture(Vector2i(64, 32)), null) and cabinet.resolved == before, key + " non-native tile rejected without mutation")
			cabinet.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "runtime_approved": false, "worker_disabled": true}, "\t"))
	await process_frame
	print("Modular cabinet geometry: %d checks, %d failures; staged only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
