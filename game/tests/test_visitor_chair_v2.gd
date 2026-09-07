extends SceneTree
## Provider-free shadow-only visitor-chair-v2 regression gate.

const V2 := preload("res://tools/visitor_chair_review_v2.gd")
const CHAIR := preload("res://tools/visitor_chair_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/visitor-chair-v2"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func visible_shadow_pixels(shadow: Image, rear: Image, front: Image) -> int:
	var visible := 0
	for y: int in shadow.get_height():
		for x: int in shadow.get_width():
			if shadow.get_pixel(x, y).a <= 0.0:
				continue
			if rear.get_pixel(x, y).a <= 0.0 and front.get_pixel(x, y).a <= 0.0:
				visible += 1
	return visible

func run() -> void:
	check(V2.REVISION == "visitor-chair-v2", "Versioned correction does not overwrite v1")
	check(V2.OUTPUT_ROOT == OUTPUT, "Descriptors point only at the v2 fixture")
	for side: String in CHAIR.SIDES:
		var original := CHAIR.layers(side)
		var revised := V2.layers(side)
		check((original.seat_back as Image).get_data() == (revised.seat_back as Image).get_data(), side + " rear structure is exact v1")
		check((original.seat_front as Image).get_data() == (revised.seat_front as Image).get_data(), side + " front structure is exact v1")
		check((original.floor_shadow as Image).get_data() != (revised.floor_shadow as Image).get_data(), side + " replaces only the demonstrated shadow defect")
		var shadow: Image = revised.floor_shadow
		var facts := PIXELS.analyze(shadow)
		check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, side + " shadow has binary clean alpha")
		check(int(facts.opaque_pixels) > 8 and int(facts.opaque_pixels) <= 36, side + " contact marks stay small instead of filling a broad basket")
		var visible_contacts := visible_shadow_pixels(shadow, revised.seat_back, revised.seat_front)
		check(visible_contacts >= 4 and visible_contacts <= 24, side + " keeps restrained floor contacts visible after the chair structure is composed")
		var old_facts := PIXELS.analyze(original.floor_shadow)
		check(int(facts.opaque_pixels) * 4 < int(old_facts.opaque_pixels), side + " removes at least three quarters of old shadow mesh pixels")
		var floor := Rect2i(CHAIR.PIVOT - Vector2i(16, 16), Vector2i(32, 32))
		check(floor.encloses(shadow.get_used_rect()), side + " contact marks remain inside the one-cell floor")
		for point_value: Variant in CHAIR.profile(side).contact_points:
			var point := Vector2i(point_value) + CHAIR.PIVOT
			var nearby := Rect2i(point + Vector2i(1, -1), Vector2i(6, 2)).intersection(floor)
			var found := false
			for y: int in range(nearby.position.y, nearby.end.y):
				for x: int in range(nearby.position.x, nearby.end.x):
					if shadow.get_pixel(x, y).a > 0.0: found = true
			check(found, side + " each authored support owns a down-right contact mark")
		var disk_back := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-seat_back.png")))
		var disk_front := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-seat_front.png")))
		var disk_shadow := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-floor_shadow.png")))
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_back.is_empty() and disk_back.get_data() == (original.seat_back as Image).get_data(), side + " exported back preserves v1 bytes")
		check(not disk_front.is_empty() and disk_front.get_data() == (original.seat_front as Image).get_data(), side + " exported front preserves v1 bytes")
		check(not disk_shadow.is_empty() and disk_shadow.get_data() == shadow.get_data(), side + " exported shadow rebuilds exactly")
		check(not disk_whole.is_empty() and disk_whole.get_data() == V2.whole(side).get_data(), side + " exported whole rebuilds exactly")
		var rebuilt := CHAIR.binary_over(CHAIR.binary_over(shadow, revised.seat_back), revised.seat_front)
		check(rebuilt.get_data() == V2.whole(side).get_data(), side + " three v2 layers reconstruct byte-exact")
		for layer_name: String in CHAIR.LAYERS:
			var descriptor := V2.descriptor(side, layer_name)
			check(str(descriptor.art).begins_with(OUTPUT), side + " descriptor stays v2 fixture-scoped")
			check(descriptor.region == [0, 0, 96, 144] and descriptor.offset == [0, -24], side + " canvas/pivot registration unchanged")
	var entry := V2.catalog_entry()
	check(entry.facings == CHAIR.SIDES and entry.facing_profiles.size() == 4, "V2 exposes the same four dev-only facings")
	for side: String in CHAIR.SIDES:
		var profile: Dictionary = entry.facing_profiles[side]
		check(profile.occupied == [[0, 0]] and profile.optional_contact_socket.runtime_capability == false, side + " geometry/contact semantics unchanged and non-capable")
		check(profile.render_layers.size() == 3 and str(profile.render_layers[0].art).contains("visitor-chair-v2"), side + " exact v2 layers are referenced")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("visitor-chair-v2") == -1, "No production registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("visitor-chair-v2") == -1, "No default-layout binding")
	print("Visitor chair v2: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
