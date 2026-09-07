extends SceneTree
## Focused structural/placement gate for three first-pass passive service/library props.

const ART := preload("res://tools/passive_service_library_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
const OUTPUTS := {
	"water_station": "res://tests/output/water-station-v2",
	"printer_scanner_station": "res://tests/output/printer-scanner-station-v1",
	"resource_cart": "res://tests/output/resource-cart-v1",
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

static func color_pixels(image: Image, color: Color) -> int:
	var result := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y) == color: result += 1
	return result

static func rect_is_transparent(image: Image, family: String, rect: Rect2i) -> bool:
	if not rect.has_area(): return false
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if image.get_pixelv(Vector2i(x, y) + ART.pivot(family)).a > 0.0: return false
	return true

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
		var admitted := model.authorize_calibration_decorative_profile(family, side, owner)
		if not admitted:
			var diagnostic := ART.catalog_entry(family).duplicate(true)
			var facing_profiles: Dictionary = diagnostic.facing_profiles
			diagnostic.erase("facing_profiles")
			diagnostic.merge(facing_profiles[side], true)
			var diagnostic_errors: Array[String] = []
			model._validate_direction_profile(diagnostic, diagnostic_errors)
			print("Passive service admission diagnostic ", family, "/", side, ": ", diagnostic_errors)
		check(admitted, family + "/" + side + " receives only passive calibration admission")
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
	check(recorded_elevation >= ART.base_elevation(family) and recorded_elevation <= maxi(ART.planned_vertical_envelope(family), ART.expected_feature_rise(family)), family + " records either the original planning envelope or the measured authored feature rise")
	check(ART.base_elevation(family) <= ART.planned_vertical_envelope(family), family + " measured base elevation stays within the planning envelope")
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
		check(p.top.size == p.floor.size and p.top.position == p.floor.position - Vector2i(0, ART.base_elevation(family)), family + "/" + side + " top plane is the exact physical floor rectangle translated by one family elevation")
		check(p.top_plane_depth == (32 if side in ["north", "south"] else 64), family + "/" + side + " records projected top-plane depth separately from vertical elevation")
		check(p.front == Rect2i(p.top.position.x, p.top.end.y, p.top.size.x, ART.base_elevation(family)) and p.front.end.y == p.contact_y, family + "/" + side + " camera-front elevation begins at the top near edge and reaches floor contact")
		check(p.base_solid_bounds == p.top.merge(p.front) and p.base_projected_rise == ART.base_elevation(family) + p.top_plane_depth, family + "/" + side + " whole solid bounds separately include elevation plus projected footprint depth")
		var parts := ART.layers(family, side)
		var whole := ART.whole(family, side)
		wholes[side] = whole
		check(parts.keys().size() == 3 and whole.get_size() == size, family + "/" + side + " exports three full-canvas layers and whole")
		check(ART.binary_over(ART.binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure).get_data() == whole.get_data(), family + "/" + side + " exact ordered layer reconstruction")
		check(rect_is_opaque(parts.rear_structure, family, p.top), family + "/" + side + " rear structure fully covers the explicit top plane")
		if family != "resource_cart":
			check(rect_is_opaque(parts.rear_structure, family, p.front), family + "/" + side + " rear structure fully covers the separate camera-front elevation")
		var top_detail_pixels := 0
		for x: int in range(p.top.position.x, p.top.end.x):
			for y: int in range(p.top.position.y, p.top.end.y):
				if (parts.front_structure as Image).get_pixelv(Vector2i(x, y) + ART.pivot(family)).a > 0.0: top_detail_pixels += 1
		check(top_detail_pixels > 0, family + "/" + side + " front detail explicitly occupies the real top plane")
		if family == "water_station":
			check(color_pixels(whole, ART.WATER_BLUE) > 0 and color_pixels(whole, ART.TEA_COPPER) > 0 and color_pixels(whole, ART.CUP) > 0, family + "/" + side + " visibly retains dispenser, kettle and cup cues")
		elif family == "printer_scanner_station":
			check(color_pixels(whole, ART.PAPER) > 0 and color_pixels(whole, ART.PRINTER_BODY) > 0, family + "/" + side + " visibly retains scanner/printer body and static paper cues")
		else:
			var lower := Rect2i(p.floor.position - Vector2i(0, 4), p.floor.size)
			# Measure the upper clear interval; the south handle intentionally crosses
			# the gap lower down without turning the cart into a closed cabinet.
			var gap_height := mini(12, lower.position.y - p.top.end.y)
			var gap := Rect2i(p.floor.position.x + p.floor.size.x / 2 - 2, p.top.end.y, 4, gap_height)
			check(rect_is_transparent(whole, family, gap), family + "/" + side + " keeps a measured open-air gap between its two trays")
			check(p.role_identity.open_trays == 2 and p.role_identity.casters == 4 and not p.role_identity.mobile_behavior_implemented, family + "/" + side + " records two trays/four casters without inventing movement")
		var facts := PIXELS.analyze(whole)
		var bounds := OfficeLayout.rectangle(facts.opaque_bounds)
		check(bounds.position.x >= 16 and bounds.position.y >= 16 and bounds.end.x <= size.x - 16 and bounds.end.y <= size.y - 16, family + "/" + side + " keeps at least 16px protected transparent padding")
		var local_bounds := Rect2i(Vector2i(bounds.position) - ART.pivot(family), Vector2i(bounds.size))
		check(local_bounds.position.y <= p.top.position.y and local_bounds.end.y == p.contact_y, family + "/" + side + " measured whole includes any raised role feature and reaches exact floor contact")
		check(p.contact_y - local_bounds.position.y <= ART.expected_feature_rise(family) + p.top_plane_depth, family + "/" + side + " measured projected rise stays inside the explicitly reviewed feature-plus-depth bound")
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
		"status": "native_review_candidate_without_runtime_binding",
		"family": family,
		"checks": checks - start_checks,
		"failures": family_failures,
		"canvas": [size.x, size.y],
		"pivot": [anchor.x, anchor.y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"measured_base_elevation_px": ART.base_elevation(family),
		"authored_vertical_feature_rise_px": ART.expected_feature_rise(family),
		"planned_vertical_feature_envelope_px": ART.planned_vertical_envelope(family),
		"north_south_top_plane_depth_px": 32,
		"east_west_top_plane_depth_px": 64,
		"maximum_expected_projected_rise_px": ART.expected_feature_rise(family) + 64,
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
	check(ART.FAMILIES == ["water_station", "printer_scanner_station", "resource_cart"], "Exactly the three assigned existing families are in scope")
	check(ART.SIDES == ["north", "east", "south", "west"], "Four facings use canonical catalogue order")
	check(ART.LAYERS == ["floor_shadow", "rear_structure", "front_structure"], "Every base exports the three required passive-library layers")
	var source := FileAccess.get_file_as_string("res://tools/passive_service_library_geometry.gd")
	for forbidden: String in ["rotate_", ".rotated(", "flip_x(", "flip_y(", "Image.load_from_buffer", "imagegen"]:
		check(source.find(forbidden) == -1, "Geometry contains no generated/finished-raster transform path: " + forbidden)
	for path: String in MATERIAL_HASHES:
		check(FileAccess.get_sha256(path) == str(MATERIAL_HASHES[path]), "Retained reviewed material stays byte-exact: " + path)
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEV_CATALOGUE))
	check(current.families.size() == 42, "Source catalogue still contains exactly 42 families")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("water_station") == -1, "Water station has no production registration")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("printer_scanner_station") == -1, "Printer/scanner station has no production registration")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("resource_cart") == -1, "Resource cart has no production registration")
	for family: String in ART.FAMILIES:
		var manifest_path := str(ART.ROOTS[family]).path_join("manifest.json")
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		check(manifest.id == ART.revision_id(family) and manifest.family == family and manifest.status == "native_review_candidate_without_runtime_binding", family + " manifest identifies the exact unregistered passive candidate revision")
		check((manifest.directions as Array).size() == 4 and (manifest.layers as Array) == ART.LAYERS, family + " manifest records four facings and exact required layers")
		var provenance: Dictionary = manifest.get("code_native_provenance", {})
		check(provenance.get("image_generation_calls", -1) == 0 and not provenance.get("generated_raster_sources_used", true) and provenance.get("source_attempts_created", -1) == 0, family + " transparently records zero raster generation/source attempts")
		check(not manifest.has("generation_budget") and not manifest.has("source_attempts"), family + " does not invent an image-generation retry budget or source-attempt history")
		check(not manifest.runtime_registered and not manifest.production_catalogue_registered and not manifest.default_layout_registered and not manifest.service_backend_or_interaction_created, family + " manifest claims no runtime/default/service implementation")
		check((manifest.failures as Array).is_empty(), family + " deterministic export manifest has no failures")
		if family == "water_station":
			check(manifest.supersedes_rejected_revision == "water-station-v1" and not str(manifest.rejected_revision_reason).is_empty(), "Water v2 explicitly preserves and diagnoses the rejected narrow-reservoir v1")
			check((manifest.preserved_v1_files as Array).size() == 37, "Water v2 pins the complete v1 fixture and evidence set")
			for history: Dictionary in manifest.preserved_v1_files:
				var history_path := "res://" + str(history.path).trim_prefix("game/")
				check(FileAccess.file_exists(history_path) and FileAccess.get_sha256(history_path) == str(history.sha256), "Water v1 history stays byte-exact: " + str(history.path))
		validate_family(family, current)
	check(ART.whole("water_station", "south").get_data() != ART.whole("printer_scanner_station", "south").get_data(), "Water and printer stations remain distinct")
	check(ART.whole("water_station", "south").get_data() != ART.whole("resource_cart", "south").get_data(), "Water station and resource cart remain distinct")
	check(ART.whole("printer_scanner_station", "south").get_data() != ART.whole("resource_cart", "south").get_data(), "Printer station and resource cart remain distinct")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/output/passive-service-library"))
	var file := FileAccess.open("res://tests/output/passive-service-library/structural-results.json", FileAccess.WRITE)
	check(file != null, "Opened combined structural result")
	if file != null:
		file.store_string(JSON.stringify({"status": "native_review_candidate_without_runtime_binding", "families": ART.FAMILIES, "checks": checks, "failures": failures, "runtime_registered": false, "service_backend_or_interaction_created": false}, "	") + "\n")
	print("Passive service library structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
