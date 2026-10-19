extends SceneTree
## Provider-free structural and owner-admission tests for passive lounge art.

const SEATING := preload("res://tools/lounge_seating_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const PRESERVE := ["res://data/furniture_catalog.json", "res://data/office_layout.json", "res://../dev/art-catalogue/furniture.json"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func mask_rect(profile: Dictionary) -> Rect2i:
	var result := Rect2i()
	for raw: Variant in profile.occupied:
		var cell := Vector2i(int(raw[0]), int(raw[1]))
		var rect := Rect2i(cell * 32 - Vector2i(16, 16), Vector2i(32, 32))
		result = result.merge(rect) if result.has_area() else rect
	return result

func opaque_component_count(image: Image) -> int:
	# Eight-neighbour connectivity admits the intentionally down-right one-pixel
	# contact mark, while still detecting a suspended foot or isolated shadow.
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var components := 0
	for y: int in range(height):
		for x: int in range(width):
			var index := y * width + x
			if seen[index] != 0 or image.get_pixel(x, y).a <= 0.0: continue
			components += 1
			var pending: Array[Vector2i] = [Vector2i(x, y)]
			seen[index] = 1
			var cursor := 0
			while cursor < pending.size():
				var point := pending[cursor]
				cursor += 1
				for offset_y: int in range(-1, 2):
					for offset_x: int in range(-1, 2):
						if offset_x == 0 and offset_y == 0: continue
						var next := point + Vector2i(offset_x, offset_y)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height: continue
						var next_index := next.y * width + next.x
						if seen[next_index] != 0 or image.get_pixelv(next).a <= 0.0: continue
						seen[next_index] = 1
						pending.append(next)
	return components

func run() -> void:
	var preserved := {}
	for path: String in PRESERVE: preserved[path] = FileAccess.get_sha256(path)
	check(SEATING.FAMILIES == ["two_seat_sofa", "lounge_armchair"], "Scope is exactly the requested sofa and lounge armchair")
	check(SEATING.profile("unknown", "north").is_empty() and SEATING.profile("two_seat_sofa", "diagonal").is_empty(), "Unknown family/facing rejected")
	var family_bounds := {}
	for family: String in SEATING.FAMILIES:
		var size := SEATING.canvas(family)
		var anchor := SEATING.pivot(family)
		var entry := SEATING.catalog_entry(family)
		check(entry.facings == SEATING.SIDES and entry.interaction_kind == "none", family + " exact NESW actionless entry")
		var hashes := {}
		var widest := 0
		for side: String in SEATING.SIDES:
			var profile := SEATING.profile(family, side)
			var parts := SEATING.layers(family, side)
			var whole := SEATING.whole(family, side)
			check(mask_rect(profile) == profile.floor, family + " " + side + " occupied mask equals physical envelope")
			check(parts.size() == 3 and whole.get_size() == size, family + " " + side + " exact three-layer canvas")
			check(opaque_component_count(whole) == 1, family + " " + side + " upholstery, supports and contact marks form one connected silhouette")
			var rebuilt := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			rebuilt.fill(Color(0, 0, 0, 0))
			for layer_name: String in SEATING.LAYERS:
				var layer: Image = parts[layer_name]
				var disk := Image.load_from_file(ProjectSettings.globalize_path(SEATING.output_root(family) + side + "-" + layer_name + ".png"))
				check(not disk.is_empty() and PIXELS.rgba(disk).get_data() == layer.get_data(), family + " " + side + " " + layer_name + " exact export")
				var facts := PIXELS.analyze(layer)
				check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + " " + side + " " + layer_name + " clean alpha")
				if layer_name == "floor_shadow": check(int(facts.opaque_pixels) > 0 and int(facts.opaque_pixels) <= 40, family + " " + side + " has bounded support contacts, not a broad under-seat mat")
				rebuilt.blend_rect(layer, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
			check(rebuilt.get_data() == whole.get_data(), family + " " + side + " exact ordered union")
			var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(SEATING.output_root(family) + side + "-whole.png"))
			check(not disk_whole.is_empty() and PIXELS.rgba(disk_whole).get_data() == whole.get_data(), family + " " + side + " exact whole export")
			var used := whole.get_used_rect()
			if side in ["east", "west"]:
				var local_top := used.position.y - anchor.y
				check(local_top == profile.floor.position.y - int(profile.rise), family + " " + side + " projects the declared rise above its far floor edge")
			widest = maxi(widest, used.size.x)
			check(used.position.x > 0 and used.position.y > 0 and used.end.x < size.x and used.end.y < size.y, family + " " + side + " protected padding")
			var candidate: Dictionary = entry.facing_profiles[side]
			check(candidate.profile_kind == "decorative" and candidate.status == "calibration_candidate" and not candidate.review.art and not candidate.review.geometry, family + " " + side + " honest dev state")
			for forbidden: String in ["interaction", "service_side", "approach_gaze", "work_cell", "work_facing", "seat_anchor", "pose_set", "standing_viewpoints", "collaboration_slots"]:
				check(not candidate.has(forbidden), family + " " + side + " has no invented " + forbidden)
			check(candidate.render_layers.size() == 3 and candidate.ambient_overlays.is_empty(), family + " " + side + " exact passive layers only")
			hashes[side] = PIXELS.digest(whole.get_data())
		check(hashes.north != hashes.south and hashes.east != hashes.west and hashes.north != hashes.east, family + " keeps distinct rear/front/side art")
		family_bounds[family] = widest
	check(int(family_bounds.two_seat_sofa) > int(family_bounds.lounge_armchair), "Sofa has a genuinely wider two-seat silhouette")
	check(SEATING.canvas("lounge_armchair") != Vector2i(96, 160), "Lounge armchair does not reuse the ergonomic task-chair envelope")

	var ordinary := OfficeLayout.new()
	check(ordinary.load_files(), "Loaded ordinary office model")
	for family: String in SEATING.FAMILIES:
		var data := ordinary.data.duplicate(true)
		var catalog := ordinary.catalog.duplicate(true)
		data.props = [{"id": "candidate", "kind": family, "grid": [18, 13], "facing": "north", "required_hires": 0}]
		catalog[family] = SEATING.catalog_entry(family)
		var model := OfficeLayout.new()
		model.configure(data, catalog)
		var owner := Node.new()
		root.add_child(owner)
		check(model.enable_calibration_preview(owner), family + " owner-scoped preview enabled")
		for side: String in SEATING.SIDES:
			check(model.authorize_calibration_decorative_profile(family, side, owner), family + " " + side + " exact definition admitted")
			var resolved := model.resolve_profile(family, side)
			check(resolved.errors.is_empty() and resolved.profile.profile_kind == "decorative", family + " " + side + " resolves after owner admission")
			for forbidden: String in ["interaction", "service_side", "work_cell", "seat_anchor", "pose_set", "standing_viewpoints"]: check(not resolved.profile.has(forbidden), family + " " + side + " remains passive")
			var safe := {"valid": false, "errors": ["no floor candidate"]}
			for y: int in range(4, model.height - 2):
				for x: int in range(2, model.width - 2):
					var attempt := model.validate_candidate("candidate", Vector2i(x, y), side, 0)
					if attempt.valid:
						safe = attempt
						break
				if safe.valid: break
			check(safe.valid, family + " " + side + " has a valid floor candidate: " + str(safe.errors))
			check(not model.validate_candidate("candidate", Vector2i(1, 3), side, 0).valid, family + " " + side + " wall/corner rejected")
		model.disable_calibration_preview(owner)
		check(not model.resolve_profile(family, "north").errors.is_empty(), family + " admission revoked")
		owner.queue_free()
		await process_frame
	check(ordinary.catalog.has("two_seat_sofa") and str(ordinary.catalog["two_seat_sofa"].get("interaction_kind", "")) == "none", "two_seat_sofa is registered as passive décor")
	check(not ordinary.catalog.has("lounge_armchair"), "lounge_armchair remains unregistered")
	for side: String in SEATING.SIDES:
		var production: Dictionary = ordinary.catalog["two_seat_sofa"]["facing_profiles"][side]
		check(str(production.get("profile_kind", "")) == "decorative" and str(production.get("status", "")) == "runtime_ready", "two_seat_sofa " + side + " is decorative runtime_ready")
		for forbidden: String in ["interaction", "service_side", "work_cell", "seat_anchor", "pose_set", "action"]:
			check(not production.has(forbidden), "two_seat_sofa " + side + " production profile has no " + forbidden)
	# Intentionally no assertion about the dev catalogue lifecycle state: this
	# structural suite remains valid if a later, explicit art-library review is applied.
	for path: String in preserved: check(FileAccess.get_sha256(path) == preserved[path], "Test leaves " + path + " byte-identical")
	print("Lounge seating: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
