extends SceneTree
const KIT := preload("res://tools/coffee_north_kit_calibration.gd")
const SOUTH := preload("res://tools/coffee_south_kit_calibration.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const OUTPUT := "res://tests/output/coffee-north-kit"
var checks := 0
var failures: Array[String] = []
var comparisons: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, copy: String) -> void:
	checks += 1
	if not ok:
		failures.append(copy)
		push_error(copy)

func run() -> void:
	var original := Image.load_from_file(ProjectSettings.globalize_path(KIT.SOURCE))
	check(original != null and original.get_size() == Vector2i(1774, 887), "Retained alpha-extraction source is1774x887")
	check(original.detect_alpha() != Image.ALPHA_NONE, "Source really has transparency")
	var bytes := PIXELS.rgba(original).get_data()
	var lost := 0
	for y: int in range(original.get_height()):
		for x: int in range(original.get_width()):
			if bytes[(y * original.get_width() + x) * 4 + 3] < 128: continue
			var covered := false
			for rect: Rect2i in KIT.CROPS.values():
				if rect.has_point(Vector2i(x, y)):
					covered = true
					break
			if not covered: lost += 1
	check(lost == 0, "Declared source crops contain all thresholded opaque pixels; lost=" + str(lost))
	var p: Dictionary = CABINET.profile("counter", "north")
	var union := Image.create(192, 256, false, Image.FORMAT_RGBA8)
	var occupied: Dictionary = {}
	var opaque := 0
	for part: String in KIT.PARTS:
		var value := KIT.image(part)
		var a := PIXELS.analyze(value)
		check(value.get_size() == KIT.CANVAS and value.get_used_rect() == KIT.BOUNDS[part], part + " full canvas and actual native bounds")
		check(a.partial_alpha_pixels == 0 and a.hidden_rgb_pixels == 0 and a.opaque_pixels > 0, part + " clean nonempty binary alpha")
		check(a.opaque_colors <= 47, part + " bounded shared palette")
		var contact: Rect2i = KIT.CONTACTS[part]
		check(p.top_interior.encloses(contact), part + " inferred base lies inside actual raised-rim wood")
		check(Rect2i(KIT.BOUNDS[part].position - KIT.PIVOT, KIT.BOUNDS[part].size).encloses(contact), part + " contact belongs to its own visible object")
		var south_contact: Rect2i = SOUTH.CONTACTS[part]
		# Undo32px elevation, turn physical ground-plane rectangle180 degrees,
		# then restore elevation. Never rotate any source image.
		var floor_contact := Rect2i(south_contact.position + Vector2i(0, 32), south_contact.size)
		var turned := Rect2i(-floor_contact.end - Vector2i(0, 32), floor_contact.size)
		check(contact.position == turned.position, part + " registered north contact follows physical S→N turn")
		check((contact.size - turned.size).abs().x <= 1 and contact.size.y == turned.size.y, part + " only independently normalized one-pixel width variation")
		comparisons.append({"part": part, "south_contact": PIXELS.rect_values(south_contact), "north_contact": PIXELS.rect_values(contact), "physical_turned_hypothesis": PIXELS.rect_values(turned), "south_native_bounds": PIXELS.rect_values(SOUTH.BOUNDS[part]), "north_native_bounds": PIXELS.rect_values(KIT.BOUNDS[part]), "source_view_identity_is_not_proven_by_geometry": true})
		var data := value.get_data()
		var duplicate := 0
		for at: int in range(0, data.size(), 4):
			if data[at + 3] == 0: continue
			if occupied.has(at): duplicate += 1
			occupied[at] = part
		check(duplicate == 0, part + " source object pixels remain independently owned")
		opaque += int(a.opaque_pixels)
		union = PIXELS.binary_over(union, value)
	check(union.get_data() == KIT.image().get_data(), "Four full registered layers reconstruct exact native union")
	check(PIXELS.analyze(union).opaque_pixels == opaque and PIXELS.analyze(union).opaque_colors <= 47, "Union preserves all opaque pixels in one palette")
	check(p.service_cell == Vector2i(0, -1) and p.approach_gaze == "south", "Service North means actor above looking South, not seated gaze")
	var tile := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	tile.fill(Color("a87742"))
	var tex := ImageTexture.create_from_image(tile)
	var host := KIT.build(root, Vector2(336, 304), tex, tex, true)
	check(host != null and host.get_child_count() == 5, "Exact counter and four independent native components")
	for child: Node2D in host.get_children():
		check(child.position == (-Vector2(KIT.PIVOT) if child is Sprite2D else Vector2.ZERO) and child.scale == Vector2.ONE and child.rotation == 0, "Native registered transform " + str(child.name))
		check(child.z_index == 0, "Whole assembly shares floor depth " + str(child.name))
	host.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "source_sha256": FileAccess.get_sha256(KIT.SOURCE), "source_opaque_outside_crops": lost, "records": KIT.records(), "union": PIXELS.analyze(union), "physical_comparisons": comparisons, "contacts_are_hypotheses": true, "runtime_approved": false, "new_interaction": false, "worker_disabled": true, "save_access": false}, "\t"))
	print("Coffee North: %d checks, %d failures; staged contact hypotheses only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
