extends SceneTree
## Focused structural/placement gate for three perspective-correct v2 passive bases.

const ART := preload("res://tools/passive_utility_library_v2_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
const OUTPUTS := {
	"tall_storage_cabinet": "res://tests/output/tall-storage-cabinet-v2",
	"server_cabinet": "res://tests/output/server-cabinet-v2",
	"recycling_sorter": "res://tests/output/recycling-sorter-v2",
}
const MATERIAL_HASHES := {
	ART.POWDERCOAT: "807152a50c8a1771cd451d0984fe1fd4ba3fb6328089e5fa9dd1fb2c858ad42d",
	ART.OAK_HORIZONTAL: "bcd3ccf8c6411b4ce24997a88b3fabf78f7fa2132b240f66ee1d59ab3e0dded6",
	ART.OAK_VERTICAL: "28a84e93bcdd6e026fbd3a56ae598f14a6c74acd07d1c5950a1a2347a1a24fae",
}

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

static func family_record(catalogue: Dictionary, family: String) -> Dictionary:
	for raw: Variant in catalogue.families:
		var item := raw as Dictionary
		if str(item.id) == family: return item
	return {}

static func variant_record(family: Dictionary, side: String) -> Dictionary:
	for raw: Variant in family.variants:
		var item := raw as Dictionary
		if str(item.facing) == side: return item
	return {}

static func floor_from_cells(values: Array) -> Rect2i:
	var low := Vector2i(999, 999)
	var high := Vector2i(-999, -999)
	for raw: Variant in values:
		var cell := OfficeLayout.vector(raw)
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	return Rect2i(low * 32 - Vector2i(16, 16), (high - low + Vector2i.ONE) * 32)

static func same_pair(raw: Variant, expected: Variant) -> bool:
	return raw is Array and expected is Array and OfficeLayout.vector(raw) == OfficeLayout.vector(expected)

static func same_cells(raw: Array, expected: Array) -> bool:
	if raw.size() != expected.size(): return false
	for index: int in range(raw.size()):
		if OfficeLayout.vector(raw[index]) != OfficeLayout.vector(expected[index]): return false
	return true

static func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

static func visible_pixels(layer_name: String, parts: Dictionary) -> int:
	var index := ART.LAYERS.find(layer_name)
	var result := 0
	var image := parts[layer_name] as Image
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0: continue
			var hidden := false
			for later: int in range(index + 1, ART.LAYERS.size()):
				if (parts[ART.LAYERS[later]] as Image).get_pixel(x, y).a > 0.0:
					hidden = true
					break
			if not hidden: result += 1
	return result

static func rect_is_opaque(image: Image, family: String, rect: Rect2i) -> bool:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if image.get_pixelv(Vector2i(x, y) + ART.pivot(family)).a == 0.0: return false
	return true

static func color_pixels_in_rect(image: Image, family: String, rect: Rect2i, color: Color) -> int:
	var result := 0
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if image.get_pixelv(Vector2i(x, y) + ART.pivot(family)) == color: result += 1
	return result

static func issue_codes(result: Dictionary) -> Array[String]:
	var codes: Array[String] = []
	for issue: Dictionary in result.issues:
		var code := str(issue.code)
		if not codes.has(code): codes.append(code)
	return codes

func validate_owner_scoped_model(family: String) -> void:
	var room_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/office_layout.json"))
	var production: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furniture_catalog.json"))
	var candidate_id := family + "-candidate"
	room_data.props = [{"id": candidate_id, "kind": family, "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	var catalogue: Dictionary = production.furniture.duplicate(true)
	catalogue[family] = ART.catalog_entry(family)
	var model := OfficeLayout.new()
	model.configure(room_data, catalogue)
	var owner := Node.new()
	root.add_child(owner)
	check(model.enable_calibration_preview(owner), family + " opens only an owner-scoped copied model")
	for side: String in ART.SIDES:
		check(model.authorize_calibration_decorative_profile(family, side, owner), family + "/" + side + " receives only passive calibration admission")
		var resolution := model.resolve_profile(family, side)
		check(resolution.errors.is_empty() and resolution.profile.calibration_preview, family + "/" + side + " copied profile resolves")
		var profile: Dictionary = resolution.profile
		check(not profile.has("interaction") and not profile.has("service_side") and not profile.has("work_cell"), family + "/" + side + " creates no service or workstation action")
		check(profile.occupied == ART.profile(family, side).occupied and profile.clearance == ART.profile(family, side).clearance, family + "/" + side + " preserves exact collision and planning clearance")
		check(profile.standing_viewpoints.size() == 1, family + "/" + side + " retains one geometry-only actor viewpoint")
		var safe_found := false
		var wall_found := false
		for y: int in range(model.height):
			for x: int in range(model.width):
				var point := Vector2i(x, y)
				if not model.is_floor(point): continue
				var validation := model.validate_candidate(candidate_id, point, side, 0)
				if validation.valid: safe_found = true
				else:
					var codes := issue_codes(validation)
					for code: String in ["wall_intersection", "visual_wall_intersection", "wall_clearance", "decorative_headroom"]:
						if code in codes: wall_found = true
		check(safe_found, family + "/" + side + " has a real safe production-room cell")
		check(wall_found, family + "/" + side + " detects an actual wall/headroom conflict")
	var ordinary := OfficeLayout.new()
	ordinary.configure(room_data, catalogue)
	check(ordinary.available_facings(family).is_empty(), family + " copied definition is unavailable without the live owner permit")
	model.disable_calibration_preview(owner)
	check(model.available_facings(family).is_empty(), family + " becomes unavailable when the owner scope closes")
	owner.free()

func validate_family(family: String, current: Dictionary) -> void:
	var start_checks := checks
	var start_failures := failures.size()
	var record := family_record(current, family)
	var size := ART.canvas(family)
	var anchor := ART.pivot(family)
	check(not record.is_empty(), family + " exists in the 42-family source catalogue")
	check(record.current_availability.runtime_family_id == null and (record.current_availability.runtime_registered_facings as Array).is_empty(), family + " remains absent from the runtime catalogue while allowing passive-library approval")
	check(OfficeLayout.vector(record.native_geometry.canvas_size_px) == size and OfficeLayout.vector(record.native_geometry.floor_anchor_px) == anchor, family + " retains its exact native canvas/pivot")
	var recorded_elevation := int(record.native_geometry.estimated_max_rise_above_occupied_floor_px)
	check(recorded_elevation >= ART.elevation(family) and recorded_elevation <= ART.planned_elevation_envelope(family), family + " records either the original elevation envelope or its measured in-envelope revision")
	check(ART.elevation(family) <= ART.planned_elevation_envelope(family), family + " measured vertical elevation stays within the planning envelope")
	var wholes := {}
	for side: String in ART.SIDES:
		var p := ART.profile(family, side)
		var original := variant_record(record, side)
		check(not p.is_empty() and p.facing == side and p.service_side == side, family + "/" + side + " owns an independent native declaration")
		check(same_pair(p.footprint, original.footprint_cells) and same_cells(p.occupied, original.proposed_occupied_cell_offsets), family + "/" + side + " retains the original two-cell footprint and ordered mask")
		check(same_pair(p.interaction, original.proposed_interaction_cell) and same_pair(p.employee_look_vector, original.employee_look_vector), family + "/" + side + " retains original approach/gaze planning metadata")
		check(p.approach_gaze == original.approach_gaze and p.service_side == original.service_side, family + "/" + side + " retains the corrected service-side semantics")
		check(original.get("runtime_art_path") == null and original.get("runtime_evidence") == null, family + "/" + side + " passive-library state has no runtime art or runtime evidence")
		check(p.floor == floor_from_cells(p.occupied), family + "/" + side + " physical floor plane equals the exact occupied-cell union")
		check(p.top.size == p.floor.size and p.top.position == p.floor.position - Vector2i(0, ART.elevation(family)), family + "/" + side + " top plane is the exact physical floor rectangle translated by one family elevation")
		check(p.top_plane_depth == (32 if side in ["north", "south"] else 64), family + "/" + side + " records projected top-plane depth separately from vertical elevation")
		check(p.front == Rect2i(p.top.position.x, p.top.end.y, p.top.size.x, ART.elevation(family)) and p.front.end.y == p.contact_y, family + "/" + side + " camera-front elevation begins at the top near edge and reaches floor contact")
		check(p.solid_bounds == p.top.merge(p.front) and p.projected_opaque_rise == ART.elevation(family) + p.top_plane_depth, family + "/" + side + " whole solid bounds separately include elevation plus projected footprint depth")
		var parts := ART.layers(family, side)
		var whole := ART.whole(family, side)
		wholes[side] = whole
		check(parts.keys().size() == 3 and whole.get_size() == size, family + "/" + side + " exports three full-canvas layers and whole")
		check(ART.binary_over(ART.binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure).get_data() == whole.get_data(), family + "/" + side + " exact ordered layer reconstruction")
		check(rect_is_opaque(parts.rear_structure, family, p.top), family + "/" + side + " rear structure fully covers the explicit top plane")
		check(rect_is_opaque(parts.rear_structure, family, p.front), family + "/" + side + " rear structure fully covers the separate camera-front elevation")
		var top_detail_pixels := 0
		for x: int in range(p.top.position.x, p.top.end.x):
			for y: int in range(p.top.position.y, p.top.end.y):
				if (parts.front_structure as Image).get_pixelv(Vector2i(x, y) + ART.pivot(family)).a > 0.0: top_detail_pixels += 1
		check(top_detail_pixels > 0, family + "/" + side + " front detail explicitly occupies the real top plane")
		if family == "recycling_sorter":
			check(color_pixels_in_rect(parts.front_structure, family, p.top, ART.STREAM_BLUE) > 0 and color_pixels_in_rect(parts.front_structure, family, p.top, ART.STREAM_GREEN) > 0 and color_pixels_in_rect(parts.front_structure, family, p.top, ART.STREAM_GREY) > 0, family + "/" + side + " places all three color/shape apertures on the top plane")
		var facts := PIXELS.analyze(whole)
		var bounds := OfficeLayout.rectangle(facts.opaque_bounds)
		check(bounds.position.x >= 16 and bounds.position.y >= 16 and bounds.end.x <= size.x - 16 and bounds.end.y <= size.y - 16, family + "/" + side + " keeps at least 16px protected transparent padding")
		var local_bounds := Rect2i(Vector2i(bounds.position) - ART.pivot(family), Vector2i(bounds.size))
		check(local_bounds.position.y == p.top.position.y and local_bounds.end.y == p.contact_y, family + "/" + side + " measured whole vertical bounds exactly span top-plane origin to floor contact")
		check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + "/" + side + " whole has binary alpha and zero hidden RGB")
		for layer_name: String in ART.LAYERS:
			var image := parts[layer_name] as Image
			var layer_facts := PIXELS.analyze(image)
			check(image.get_size() == size and int(layer_facts.opaque_pixels) > 0, family + "/" + side + "/" + layer_name + " is a nonempty full native canvas")
			check(int(layer_facts.partial_alpha_pixels) == 0 and int(layer_facts.hidden_rgb_pixels) == 0, family + "/" + side + "/" + layer_name + " has clean transparency")
			check(visible_pixels(layer_name, parts) > 0, family + "/" + side + "/" + layer_name + " contributes visible final pixels")
			var descriptor := ART.descriptor(family, side, layer_name)
			check(descriptor.region == [0, 0, size.x, size.y] and descriptor.offset == [ART.sprite_offset(family).x, ART.sprite_offset(family).y], family + "/" + side + "/" + layer_name + " has exact integer registration")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), family + "/" + side + "/" + layer_name + " declares no finished-raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(disk != null and disk.get_data() == image.get_data(), family + "/" + side + "/" + layer_name + " deterministic export rebuilds byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(str(ART.ROOTS[family]).path_join(side + "-whole.png")))
		check(disk_whole != null and disk_whole.get_data() == whole.get_data(), family + "/" + side + " whole rebuilds byte-exact")
	for side: String in ART.SIDES:
		for other: String in ART.SIDES:
			if side >= other: continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), family + " " + side + "/" + other + " are materially distinct authored views")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data() and (wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), family + " N/S are not mirror-derived")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data() and (wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), family + " E/W are not mirror-derived")
	var entry := ART.catalog_entry(family)
	check(entry.facings == ART.SIDES and entry.interaction_kind == "none", family + " dev-only entry exposes four passive facings")
	for side: String in ART.SIDES:
		var profile: Dictionary = entry.facing_profiles[side]
		check(profile.profile_kind == "decorative" and profile.status == "calibration_candidate" and profile.review == {"art": false, "geometry": false}, family + "/" + side + " is owner-scoped calibration only")
		check(not profile.has("interaction") and not profile.has("service_side"), family + "/" + side + " runtime profile has no service action")
		check(profile.proposed_service_side == side and profile.proposed_interaction_cell == ART.profile(family, side).interaction, family + "/" + side + " keeps planning semantics explicitly non-runtime")
	validate_owner_scoped_model(family)
	var family_failures: Array[String] = []
	for index: int in range(start_failures, failures.size()): family_failures.append(failures[index])
	var result := {
		"status": "perspective_corrected_v2_candidate_without_runtime_binding",
		"family": family,
		"checks": checks - start_checks,
		"failures": family_failures,
		"canvas": [size.x, size.y],
		"pivot": [anchor.x, anchor.y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"measured_vertical_elevation_px": ART.elevation(family),
		"planned_vertical_elevation_envelope_px": ART.planned_elevation_envelope(family),
		"north_south_top_plane_depth_px": 32,
		"east_west_top_plane_depth_px": 64,
		"maximum_projected_opaque_rise_px": ART.elevation(family) + 64,
		"layers": ART.LAYERS,
		"runtime_registered": false,
		"dev_catalogue_status_observed": str(record.production_status),
		"production_catalogue_registered": false,
		"service_backend_or_interaction_created": false,
	}
	var file := FileAccess.open(str(OUTPUTS[family]).path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " structural result")
	if file != null: file.store_string(JSON.stringify(result, "	") + "\n")

func run() -> void:
	check(ART.FAMILIES == ["tall_storage_cabinet", "server_cabinet", "recycling_sorter"], "Exactly the three assigned existing families are in scope")
	check(ART.SIDES == ["north", "east", "south", "west"], "Four facings use canonical catalogue order")
	check(ART.LAYERS == ["floor_shadow", "rear_structure", "front_structure"], "Every v2 base exports the three required passive-library layers")
	var source := FileAccess.get_file_as_string("res://tools/passive_utility_library_v2_geometry.gd")
	for forbidden: String in ["rotate_", ".rotated(", "flip_x(", "flip_y(", "Image.load_from_buffer", "imagegen"]:
		check(source.find(forbidden) == -1, "Geometry contains no generated/finished-raster transform path: " + forbidden)
	for path: String in MATERIAL_HASHES:
		check(FileAccess.get_sha256(path) == str(MATERIAL_HASHES[path]), "Retained reviewed material stays byte-exact: " + path)
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEV_CATALOGUE))
	check(current.families.size() == 42, "Source catalogue still contains exactly 42 families")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("tall_storage_cabinet") == -1, "Tall storage has no production registration")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("server_cabinet") == -1, "Server cabinet has no production registration")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("recycling_sorter") == -1, "Recycling sorter has no production registration")
	for family: String in ART.FAMILIES:
		var manifest_path := str(ART.ROOTS[family]).path_join("manifest.json")
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		check(str(manifest.supersedes_rejected_revision).ends_with("-v1"), family + " v2 manifest preserves the rejected v1 revision identity")
		check(str(manifest.v1_rejection_review_path) == "dev/PASSIVE_UTILITY_LIBRARY_NATIVE_REVIEW.md", family + " v2 manifest names the exact rejected v1 review")
		check(str(manifest.v1_rejection_review_sha256) == FileAccess.get_sha256("res://../dev/PASSIVE_UTILITY_LIBRARY_NATIVE_REVIEW.md"), family + " v2 manifest pins the rejected v1 review byte-exact")
		check(not (manifest.preserved_v1_files as Array).is_empty(), family + " v2 manifest records non-destructive v1 history")
		for history: Dictionary in manifest.preserved_v1_files:
			var history_path := "res://" + str(history.path).trim_prefix("game/")
			check(FileAccess.file_exists(history_path) and FileAccess.get_sha256(history_path) == str(history.sha256), family + " preserves rejected v1 byte-exact: " + str(history.path))
		validate_family(family, current)
	check(ART.whole("tall_storage_cabinet", "south").get_data() != ART.whole("server_cabinet", "south").get_data(), "Tall supply and server silhouettes/details remain distinct")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/output/passive-utility-library-v2"))
	var file := FileAccess.open("res://tests/output/passive-utility-library-v2/structural-results.json", FileAccess.WRITE)
	check(file != null, "Opened combined structural result")
	if file != null:
		file.store_string(JSON.stringify({"status": "perspective_corrected_v2_candidate_without_runtime_binding", "families": ART.FAMILIES, "checks": checks, "failures": failures, "runtime_registered": false, "service_backend_or_interaction_created": false}, "	") + "\n")
	print("Passive utility library v2 structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
