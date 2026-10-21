extends SceneTree
## Provider-free focused gate for the base-only contact-shadow revisions.

const REVIEW := preload("res://tools/base_furniture_review_v2.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
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

func count_alpha(image: Image) -> int:
	var result := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func occupied_rows(image: Image) -> Array[int]:
	var result: Array[int] = []
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				result.append(y)
				break
	return result

func run() -> void:
	var furnishing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furnishing_catalog.json"))
	var compact_entry: Dictionary = furnishing["furniture"]["compact_desk"]
	var compact_passive := str(compact_entry.get("interaction_kind", "")) == "none"
	for side_name: String in ["north", "east", "south", "west"]:
		var shipped: Dictionary = compact_entry["facing_profiles"][side_name]
		compact_passive = compact_passive and str(shipped.get("profile_kind", "")) == "decorative" and str(shipped.get("status", "")) == "runtime_ready" and bool(shipped["review"]["art"]) and bool(shipped["review"]["geometry"])
	check(compact_passive, "compact_desk is passive décor in the furnishing catalogue")
	var bench_entry: Dictionary = furnishing["furniture"]["shared_workbench"]
	var bench_passive := str(bench_entry.get("interaction_kind", "")) == "none"
	for side_name: String in ["north", "east", "south", "west"]:
		var shipped_bench: Dictionary = bench_entry["facing_profiles"][side_name]
		bench_passive = bench_passive and str(shipped_bench.get("profile_kind", "")) == "decorative" and str(shipped_bench.get("status", "")) == "runtime_ready" and bool(shipped_bench["review"]["art"]) and bool(shipped_bench["review"]["geometry"])
	check(bench_passive, "shared_workbench is passive décor in the furnishing catalogue")
	check(FileAccess.get_file_as_string(DEFAULT_LAYOUT).find("compact_desk") == -1 and FileAccess.get_file_as_string(DEFAULT_LAYOUT).find("shared_workbench") == -1, "Neither base review enters the default layout")
	for family: String in REVIEW.FAMILIES:
		var base: Variant = REVIEW.source(family)
		var entry := REVIEW.catalog_entry(family)
		check(entry.interaction_kind == "none" and entry.facing_profiles.keys().size() == 4, family + " remains an explicit four-view passive base")
		for side: String in base.SIDES:
			var old_parts: Dictionary[String, Image] = base.layers(side)
			var parts := REVIEW.layers(family, side)
			var shadow: Image = parts.floor_shadow
			check((parts.rear_structure as Image).get_data() == (old_parts.rear_structure as Image).get_data(), family + " " + side + " rear structure is byte-identical to v1")
			check((parts.front_structure as Image).get_data() == (old_parts.front_structure as Image).get_data(), family + " " + side + " front structure is byte-identical to v1")
			var old_count := count_alpha(old_parts.floor_shadow)
			var new_count := count_alpha(shadow)
			check(new_count > 0 and new_count * 3 < old_count, family + " " + side + " replaces the broad lattice with bounded contact marks")
			var rows := occupied_rows(shadow)
			check(rows.size() <= 12, family + " " + side + " shadow occupies at most twelve sparse contact rows")
			var profile: Dictionary = base.profile(side)
			var bounds := shadow.get_used_rect()
			var local := Rect2i(bounds.position - base.PIVOT, bounds.size)
			check(profile.floor.encloses(local), family + " " + side + " shadow remains inside the physical floor footprint")
			var facts := PIXELS.analyze(shadow)
			check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + " " + side + " shadow has binary true transparency")
			var rebuilt: Image = base.binary_over(base.binary_over(shadow, parts.rear_structure), parts.front_structure)
			check(rebuilt.get_data() == REVIEW.whole(family, side).get_data(), family + " " + side + " three layers reconstruct v2 byte-exact")
			for layer_name: String in base.LAYERS:
				var descriptor := REVIEW.descriptor(family, side, layer_name)
				check(str(descriptor.art).begins_with(REVIEW.output_root(family) + "/"), family + " " + side + " " + layer_name + " stays in the versioned dev fixture")
				var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
				check(not disk.is_empty() and disk.get_data() == (parts[layer_name] as Image).get_data(), family + " " + side + " " + layer_name + " fixture rebuilds byte-exact")
			var profile_entry: Dictionary = entry.facing_profiles[side]
			check(profile_entry.profile_kind == "decorative" and profile_entry.status == "calibration_candidate", family + " " + side + " remains owner-scoped dev calibration")
			check(profile_entry.review == {"art": false, "geometry": false}, family + " " + side + " does not self-approve")
			check(not profile_entry.has("interaction") and not profile_entry.has("work_cell") and not profile_entry.has("pose_set"), family + " " + side + " invents no action, seat or pose")
		var room_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_LAYOUT))
		var production: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRODUCTION_CATALOG))
		room_data.props = [{"id": family + "-review", "kind": family, "grid": [12, 13], "facing": "north", "required_hires": 0}]
		room_data.employees = []
		var catalogue: Dictionary = production.furniture.duplicate(true)
		catalogue[family] = entry
		var model := OfficeLayout.new()
		model.configure(room_data, catalogue)
		var owner := Node.new()
		root.add_child(owner)
		check(model.enable_calibration_preview(owner), family + " isolated model accepts a live owner")
		for side: String in base.SIDES:
			check(model.authorize_calibration_decorative_profile(family, side, owner), family + " " + side + " accepts its exact dev definition")
			var resolution := model.resolve_profile(family, side)
			check(resolution.errors.is_empty() and resolution.profile.calibration_preview, family + " " + side + " resolves only inside that owner scope")
			check(not resolution.profile.has("interaction") and not resolution.profile.has("service_side"), family + " " + side + " remains passive rather than a fake workstation/service")
		model.disable_calibration_preview(owner)
		check(model.available_facings(family).is_empty(), family + " review disappears after owner scope closes")
		owner.free()
	print("Base furniture v2 focused: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
