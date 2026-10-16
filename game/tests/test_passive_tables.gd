extends SceneTree
## Provider-free structural and owner-scoped admission checks for three bare tables.

const TABLES := preload("res://tools/passive_table_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
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

func run() -> void:
	var preserved := {
		PRODUCTION_CATALOG: FileAccess.get_sha256(PRODUCTION_CATALOG),
		DEFAULT_LAYOUT: FileAccess.get_sha256(DEFAULT_LAYOUT),
		DEV_CATALOGUE: FileAccess.get_sha256(DEV_CATALOGUE),
	}
	check(TABLES.FAMILIES == ["low_coffee_table", "cafe_table", "round_meeting_table"], "Scope is exactly the three requested table families")
	check(TABLES.profile("unknown", "north").is_empty() and TABLES.profile("cafe_table", "diagonal").is_empty(), "Unknown family/facing rejected")
	var rises := {}
	var opaque_counts := {}
	for family: String in TABLES.FAMILIES:
		var size := TABLES.canvas(family)
		var anchor := TABLES.pivot(family)
		check(size.x > 0 and size.y > 0 and anchor.x > 0 and anchor.y > 0 and anchor.x < size.x and anchor.y < size.y, family + " valid padded canvas/pivot")
		var entry := TABLES.catalog_entry(family)
		check(entry.facings == TABLES.SIDES and entry.facing_profiles.size() == 4, family + " exact NESW profiles")
		var hashes := {}
		for side: String in TABLES.SIDES:
			var profile := TABLES.profile(family, side)
			var parts := TABLES.layers(family, side)
			var whole := TABLES.whole(family, side)
			check(mask_rect(profile) == profile.floor, family + " " + side + " occupied cells equal physical floor envelope")
			check(parts.size() == 3 and whole.get_size() == size, family + " " + side + " exact three-layer canvas")
			var rebuilt := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			rebuilt.fill(Color(0, 0, 0, 0))
			for layer_name: String in TABLES.LAYERS:
				var layer: Image = parts[layer_name]
				var path := TABLES.output_root(family) + side + "-" + layer_name + ".png"
				var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
				check(not disk.is_empty() and PIXELS.rgba(disk).get_data() == layer.get_data(), family + " " + side + " " + layer_name + " exact disk export")
				var facts := PIXELS.analyze(layer)
				check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + " " + side + " " + layer_name + " clean alpha")
				rebuilt.blend_rect(layer, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
			check(rebuilt.get_data() == whole.get_data(), family + " " + side + " exact layer reunion")
			if family == "cafe_table":
				var center: Vector2i = profile.center
				for local_y: int in range(center.y - 42, center.y + 19):
					check(whole.get_pixelv(anchor + Vector2i(center.x, local_y)).a > 0.99, family + " " + side + " support is continuously opaque at y=" + str(local_y))
			var whole_disk := Image.load_from_file(ProjectSettings.globalize_path(TABLES.output_root(family) + side + "-whole.png"))
			check(not whole_disk.is_empty() and PIXELS.rgba(whole_disk).get_data() == whole.get_data(), family + " " + side + " exact whole export")
			var used := whole.get_used_rect()
			check(used.position.x > 0 and used.position.y > 0 and used.end.x < size.x and used.end.y < size.y, family + " " + side + " protected transparent padding")
			var candidate: Dictionary = entry.facing_profiles[side]
			check(candidate.profile_kind == "decorative" and candidate.status == "calibration_candidate" and not candidate.review.art and not candidate.review.geometry, family + " " + side + " honest dev-only review state")
			for forbidden: String in ["interaction", "service_side", "approach_gaze", "work_cell", "work_facing", "seat_anchor", "pose_set", "collaboration_slots"]:
				check(not candidate.has(forbidden), family + " " + side + " has no invented " + forbidden)
			check(candidate.render_layers.size() == 3 and candidate.ambient_overlays.is_empty(), family + " " + side + " only exact native structure layers")
			hashes[side] = PIXELS.digest(whole.get_data())
			rises[family] = profile.rise
			opaque_counts[family] = int(PIXELS.analyze(whole).opaque_pixels)
		if family == "round_meeting_table":
			check(hashes.values().all(func(value: Variant) -> bool: return value == hashes.north), "Round table declares honest full rotational symmetry")
		elif family == "low_coffee_table":
			check(hashes.north != hashes.south and hashes.east != hashes.west and hashes.north != hashes.east, "Low table declares shifted horizontal and vertical views")
		else:
			check(hashes.north != hashes.east and hashes.east != hashes.south and hashes.south != hashes.west, "Cafe square has four explicit even-footprint registrations")
	check(int(rises.low_coffee_table) < int(rises.cafe_table) and int(rises.cafe_table) < int(rises.round_meeting_table), "Low, cafe and meeting surfaces have distinct increasing rises")
	check(int(opaque_counts.low_coffee_table) < int(opaque_counts.cafe_table) and int(opaque_counts.cafe_table) < int(opaque_counts.round_meeting_table), "Three silhouettes have distinct increasing native mass")

	var ordinary := OfficeLayout.new()
	check(ordinary.load_files(), "Loaded ordinary office model")
	for family: String in TABLES.FAMILIES:
		var data := ordinary.data.duplicate(true)
		var catalog := ordinary.catalog.duplicate(true)
		data.props = [{"id": "candidate", "kind": family, "grid": [18, 13], "facing": "north", "required_hires": 0}]
		catalog[family] = TABLES.catalog_entry(family)
		var model := OfficeLayout.new()
		model.configure(data, catalog)
		var owner := Node.new()
		root.add_child(owner)
		check(model.enable_calibration_preview(owner), family + " owner-scoped preview enabled")
		for side: String in TABLES.SIDES:
			check(model.authorize_calibration_decorative_profile(family, side, owner), family + " " + side + " exact definition admitted")
			var resolved := model.resolve_profile(family, side)
			check(resolved.errors.is_empty() and resolved.profile.profile_kind == "decorative", family + " " + side + " resolves only after admission")
			for forbidden: String in ["interaction", "service_side", "work_cell", "seat_anchor", "pose_set"]:
				check(not resolved.profile.has(forbidden), family + " " + side + " resolved profile stays passive")
			var safe := {"valid": false, "errors": ["no valid reviewed floor candidate"]}
			for y: int in range(4, model.height - 2):
				for x: int in range(2, model.width - 2):
					var attempt := model.validate_candidate("candidate", Vector2i(x, y), side, 0)
					if attempt.valid:
						safe = attempt
						break
				if safe.valid: break
			check(safe.valid, family + " " + side + " has a valid reviewed floor candidate: " + str(safe.errors))
			var wall := model.validate_candidate("candidate", Vector2i(1, 3), side, 0)
			check(not wall.valid, family + " " + side + " wall/corner candidate rejected")
		model.disable_calibration_preview(owner)
		check(not model.resolve_profile(family, "north").errors.is_empty(), family + " admission revoked with owner")
		owner.queue_free()
		await process_frame
	check(ordinary.catalog.has("low_coffee_table") and ordinary.catalog.has("round_meeting_table") and str(ordinary.catalog["cafe_table"]["facing_profiles"]["south"]["preview_art"]) == "res://assets/runtime/office/cafe-table-south.png", "Low lounge table and round meeting table are registered; the older one-cell cafe prop is unchanged")
	for path: String in preserved:
		check(FileAccess.get_sha256(path) == preserved[path], "Test leaves " + path + " byte-identical")
	print("Passive tables: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
