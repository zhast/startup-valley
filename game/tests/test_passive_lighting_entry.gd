extends SceneTree
## Provider-free structural, alpha, host-fit and direction gate for three
## passive candidates. It deliberately does not assume their shared catalogue
## status remains planned, so the test survives a later library review.

const ART := preload("res://tools/passive_lighting_entry_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const EVIDENCE_ROOTS := {
	"task_floor_lamp": "res://tests/output/task-floor-lamp-v2",
	"desk_lamp_kit": "res://tests/output/desk-lamp-kit-v2",
	"coat_bag_stand": "res://tests/output/coat-bag-stand-v3",
}
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func opaque_overlap(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x, y).a > 0.0 and b.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func contains_color(image: Image, color: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y) == color:
				return true
	return false

func all_points_opaque(image: Image, points: Array[Vector2i]) -> bool:
	for point: Vector2i in points:
		if image.get_pixelv(point).a == 0.0:
			return false
	return not points.is_empty()

func bag_shelf_contact_pixels(image: Image, bag: Rect2i, shelf: Rect2i) -> int:
	var result := 0
	for x: int in range(maxi(bag.position.x, shelf.position.x), mini(bag.end.x, shelf.end.x)):
		if image.get_pixel(x, bag.end.y - 1).a > 0.0 and image.get_pixel(x, shelf.position.y).a > 0.0:
			result += 1
	return result

func color_count_in(image: Image, rect: Rect2i, color: Color) -> int:
	var result := 0
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y) == color:
				result += 1
	return result

func projected_span(from: Vector2i, to: Vector2i) -> int:
	return absi(to.x - from.x) + 1

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

func shifted(path: String, delta: Vector2i) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	var result := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	result.blit_rect(source, Rect2i(Vector2i.ZERO, Vector2i(192, 224)), delta)
	return result

func run() -> void:
	check(ART.FAMILIES == ["task_floor_lamp", "desk_lamp_kit", "coat_bag_stand"], "Batch scope contains exactly the three assigned passive families")
	var source := FileAccess.get_file_as_string("res://tools/passive_lighting_entry_geometry.gd")
	check(source.find("Image.load_from_file") == -1 and source.find("get_pixel") == -1, "Editable geometry loads and samples no raster source")
	check(source.find("flip_x") == -1 and source.find("flip_y") == -1 and source.find("draw_string") == -1, "Geometry has no finished-bitmap transform or text path")
	var expected_contacts := {
		"task_floor_lamp": {"north": [[0, 1], [0, -1]], "east": [[-1, 0], [1, 0]], "south": [[0, -1], [0, 1]], "west": [[1, 0], [-1, 0]]},
		"coat_bag_stand": {"north": [[0, -1], [0, 1]], "east": [[1, 0], [-1, 0]], "south": [[0, 1], [0, -1]], "west": [[-1, 0], [1, 0]]},
	}
	var wholes := {}
	for family: String in ART.FAMILIES:
		var expected_revision := family.replace("_", "-") + ("-v3" if family == "coat_bag_stand" else "-v2")
		check(ART.revision(family) == expected_revision, family + " exports into its distinct corrected revision")
		check(FileAccess.file_exists("res://tests/fixtures/furniture-calibration/" + family.replace("_", "-") + "-v1/manifest.json"), family + " preserves rejected/superseded v1 evidence")
		if family == "coat_bag_stand":
			check(FileAccess.file_exists("res://tests/fixtures/furniture-calibration/coat-bag-stand-v2/manifest.json"), "Coat stand preserves the physically supported but directionally rejected v2 evidence")
		var size := ART.canvas(family)
		var pivot := ART.pivot(family)
		if family == "desk_lamp_kit":
			check(size == Vector2i(192, 224) and pivot == Vector2i(96, 160), "Desk lamp shares the accepted workstation canvas/pivot")
			check(ART.layer_names(family) == ["surface_decor_rear", "surface_decor_front"], "Desk lamp exports only reusable rear/front host overlays")
		else:
			check(size == Vector2i(128, 256) and pivot == Vector2i(64, 208), family + " keeps planned base-furniture canvas/pivot")
			check(ART.layer_names(family) == ["floor_shadow", "rear_structure", "front_structure"], family + " exports exact shadow/rear/front structure layers")
		if family == "coat_bag_stand":
			var north: Dictionary = ART.profile(family, "north")
			var east: Dictionary = ART.profile(family, "east")
			var south: Dictionary = ART.profile(family, "south")
			var west: Dictionary = ART.profile(family, "west")
			var front_coat_width := mini((north.coat as Rect2i).size.x, (south.coat as Rect2i).size.x)
			var front_bag_width := mini((north.bag as Rect2i).size.x, (south.bag as Rect2i).size.x)
			var front_shelf_width := mini((north.shelf as Rect2i).size.x, (south.shelf as Rect2i).size.x)
			var front_bar_span := mini(projected_span(north.crossbar_from, north.crossbar_to), projected_span(south.crossbar_from, south.crossbar_to))
			check(north.projection == "front" and north.coat_face == "front" and south.projection == "rear" and south.coat_face == "rear", "North exposes the coat front while South exposes its button-free rear")
			check(east.projection == "side" and east.coat_face == "side_left" and west.projection == "side" and west.coat_face == "side_right", "East/West declare opposing narrow garment sides")
			for side_profile: Dictionary in [east, west]:
				check((side_profile.coat as Rect2i).size.x * 100 <= front_coat_width * 60 and (side_profile.coat as Rect2i).size.y >= 69, "Side coat is physically foreshortened in width without shrinking garment height")
				check((side_profile.bag as Rect2i).size.x * 100 <= front_bag_width * 60 and (side_profile.bag as Rect2i).size.y >= 29, "Side bag is physically foreshortened in width without shrinking bag height")
				check((side_profile.shelf as Rect2i).size.x * 100 <= front_shelf_width * 65, "Side shelf is a narrow rotated projection rather than the full frontal board")
				check(projected_span(side_profile.crossbar_from, side_profile.crossbar_to) * 100 <= front_bar_span * 60, "Side crossbar span is foreshortened relative to the front/rear rack")
		check(ART.sprite_offset(family) + size / 2 == size - pivot, family + " centered sprite offset preserves the common floor pivot")
		wholes[family] = {}
		for side: String in ART.SIDES:
			var p := ART.profile(family, side)
			check(p.family == family and p.facing == side, family + "/" + side + " is a direct authored profile")
			if family == "desk_lamp_kit":
				check(p.footprint == [0, 0] and p.occupied.is_empty(), side + " desk lamp adds zero floor collision")
				check(p.employee_look_vector == {"north": [0, -1], "east": [1, 0], "south": [0, 1], "west": [-1, 0]}[side], side + " desk lamp follows host gaze")
			else:
				check(p.footprint == [1, 1] and p.occupied == [[0, 0]], family + "/" + side + " blocks exactly one floor cell")
				check(p.interaction == expected_contacts[family][side][0] and p.employee_look_vector == expected_contacts[family][side][1], family + "/" + side + " preserves authored passive contact/gaze")
			if family == "coat_bag_stand":
				check(p.service_side == side and p.approach_gaze == {"north": "south", "east": "west", "south": "north", "west": "east"}[side], side + " coat stand retains service-side semantics without implementing service")
			var parts := ART.layers(family, side)
			var whole := ART.whole(family, side)
			wholes[family][side] = whole
			var rebuilt := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			rebuilt.fill(Color(0, 0, 0, 0))
			for layer_name: String in ART.layer_names(family):
				var image: Image = parts[layer_name]
				var facts := PIXELS.analyze(image)
				check(image.get_size() == size and int(facts.opaque_pixels) > 0, family + "/" + side + "/" + layer_name + " is nonempty on the common canvas")
				check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, family + "/" + side + "/" + layer_name + " has binary alpha and zero hidden RGB")
				var descriptor := ART.descriptor(family, side, layer_name)
				check(descriptor.region == [0, 0, size.x, size.y] and descriptor.offset == [ART.sprite_offset(family).x, ART.sprite_offset(family).y], family + "/" + side + "/" + layer_name + " keeps exact integer registration")
				check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), family + "/" + side + "/" + layer_name + " declares no raster transform")
				var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
				check(not disk.is_empty() and disk.get_data() == image.get_data(), family + "/" + side + "/" + layer_name + " fixture rebuilds byte-exact")
				rebuilt = ART.binary_over(rebuilt, image)
			check(rebuilt.get_data() == whole.get_data(), family + "/" + side + " layers reconstruct whole byte-exact")
			var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(str(ART.OUTPUT_ROOTS[family]).path_join(side + "-whole.png")))
			check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), family + "/" + side + " whole fixture rebuilds byte-exact")
			var facts := PIXELS.analyze(whole)
			var bounds := whole.get_used_rect()
			if family == "task_floor_lamp":
				check(int(facts.opaque_pixels) >= 1750 and int(facts.opaque_pixels) <= 2100 and int(facts.opaque_colors) >= 8, side + " floor lamp has articulated multi-material detail")
				check(bounds.position.x >= 16 and bounds.position.y >= 48 and size.x - bounds.end.x >= 16 and size.y - bounds.end.y >= 32, side + " floor lamp retains planned transparent padding")
				check(pivot.y - bounds.position.y <= 160, side + " floor lamp stays inside planned 160px rise")
				check(contains_color(whole, ART.METAL_LIGHT) and contains_color(whole, ART.SHADE_LIGHT) and contains_color(whole, ART.WARM_LIGHT), side + " floor lamp keeps fixed highlight, shade and warm face materials")
			elif family == "coat_bag_stand":
				var side_projection := str(p.projection) == "side"
				var minimum_pixels := 2300 if side_projection else 3900
				var maximum_pixels := 3600 if side_projection else 5100
				check(int(facts.opaque_pixels) >= minimum_pixels and int(facts.opaque_pixels) <= maximum_pixels and int(facts.opaque_colors) >= 13, side + " coat stand has projection-appropriate hooks, garment, shelf and bag detail")
				check(bounds.position.x >= 16 and bounds.position.y >= 48 and size.x - bounds.end.x >= 16 and size.y - bounds.end.y >= 32, side + " coat stand retains planned transparent padding")
				check(pivot.y - bounds.position.y <= 160, side + " coat stand stays inside planned 160px rise")
				check(contains_color(whole, ART.WOOD_LIGHT) and contains_color(whole, ART.COAT_LIGHT) and contains_color(whole, ART.BAG_LIGHT), side + " coat stand keeps fixed wood, coat and bag highlights")
				check(all_points_opaque(whole, ART.coat_hanger_path(side)), side + " coat hanger visibly connects upper hook through the coat collar")
				check(p.bag.end.y == p.shelf.position.y and bag_shelf_contact_pixels(whole, p.bag, p.shelf) >= mini(p.bag.size.x, p.shelf.size.x) / 2, side + " bag body has substantial visible shelf contact instead of floating")
				var front_markers := color_count_in(parts.front_structure, p.coat, ART.METAL_LIGHT)
				check((front_markers >= 3) if side == "north" else (front_markers == 0), side + " coat face uses buttons only on the physical front projection")
				if side == "south":
					check(color_count_in(parts.front_structure, p.bag, ART.WARM_LIGHT) == 0, "South bag shows its rear panel rather than the frontal buckle")
			else:
				check(int(facts.opaque_pixels) >= 180 and int(facts.opaque_pixels) <= 380 and int(facts.opaque_colors) >= 7, side + " desk lamp stays small but materially detailed, including foreshortened side views")
				var desk_top: Rect2i = DESK.profile(side).top
				desk_top.position += pivot
				check(desk_top.grow(-1).encloses(bounds), side + " complete desk lamp stays inside the accepted tabletop inset")
				check(contains_color(whole, ART.METAL_LIGHT) and contains_color(whole, ART.WARM_LIGHT), side + " desk lamp retains fixed metal highlight and warm face")
				check(all_points_opaque(whole, ART.desk_support_path(side)), side + " desk lamp has a continuous base-to-shade support centerline")
				check(all_points_opaque(parts.surface_decor_rear, ART.desk_support_path(side)), side + " desk support and shade remain one reusable rear assembly")
				check(ART.layer_depth(family, "surface_decor_rear") == 2 and ART.layer_depth(family, "surface_decor_front") == 4, side + " desk overlays sit above host top z+1 in strict rear/front order")
			check(ART.layer_depth(family, ART.layer_names(family)[0]) < ART.layer_depth(family, ART.layer_names(family)[-1]), family + "/" + side + " preserves strict rear/front order")
		var family_wholes: Dictionary = wholes[family]
		for side: String in ART.SIDES:
			for other: String in ART.SIDES:
				if side >= other: continue
				check((family_wholes[side] as Image).get_data() != (family_wholes[other] as Image).get_data(), family + " " + side + "/" + other + " wholes are direction-identifiable")
		check((family_wholes.north as Image).get_data() != reflected(family_wholes.south, true).get_data(), family + " North is not a horizontal mirror of South")
		check((family_wholes.east as Image).get_data() != reflected(family_wholes.west, true).get_data(), family + " East is not a horizontal mirror of West")
		var entry := ART.catalog_entry(family)
		check(entry.facings == ART.SIDES and entry.interaction_kind == "none", family + " disposable admission remains passive and four-facing")
		for side: String in ART.SIDES:
			var candidate: Dictionary = entry.facing_profiles[side]
			check(candidate.profile_kind == "decorative" and candidate.status == "calibration_candidate", family + "/" + side + " entry is owner-scoped calibration only")
			check(candidate.render_layers.size() == ART.layer_names(family).size() and candidate.ambient_overlays.is_empty(), family + "/" + side + " claims only exact native structure layers and no powered glow")
			if family == "desk_lamp_kit":
				check(candidate.occupied.is_empty() and candidate.clearance.is_empty() and candidate.standing_viewpoints.is_empty(), side + " desk host overlay invents no floor geometry/contact")
			else:
				check(candidate.occupied == [[0, 0]] and candidate.clearance == [expected_contacts[family][side][0]], family + "/" + side + " admission matches one-cell collision and passive contact")
	# Desk-device clearance uses exactly the accepted production component files
	# and the same measured registration corrections as the accepted host review.
	for side: String in ART.SIDES:
		var lamp := ART.whole("desk_lamp_kit", side)
		var device_paths := {
			"monitor": "res://assets/runtime/office/workstations-v2/monitor-%s.png" % side,
			"keyboard": "res://assets/runtime/office/workstations-v2/keyboard-%s.png" % side,
			"mouse": "res://assets/runtime/office/workstations-v2/mouse-%s.png" % side,
		}
		var deltas := {"monitor": Vector2i.ZERO, "keyboard": Vector2i.ZERO, "mouse": Vector2i.ZERO}
		if side == "north": deltas = {"monitor": Vector2i(0, -10), "keyboard": Vector2i(0, 4), "mouse": Vector2i(0, 4)}
		elif side == "east": deltas = {"monitor": Vector2i.ZERO, "keyboard": Vector2i(6, 0), "mouse": Vector2i(6, 0)}
		elif side == "south": deltas.monitor = Vector2i(0, 3)
		for device: String in device_paths:
			check(opaque_overlap(lamp, shifted(device_paths[device], deltas[device])) == 0, side + " desk lamp clears accepted " + device)
	for family: String in ART.FAMILIES:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(EVIDENCE_ROOTS[family])))
		var result := {
			"status": "native_review_candidate_not_runtime_registered",
			"family": family,
			"checks_at_batch_write": checks,
			"failures_at_batch_write": failures.duplicate(),
			"canvas": [ART.canvas(family).x, ART.canvas(family).y],
			"pivot": [ART.pivot(family).x, ART.pivot(family).y],
			"layers": ART.layer_names(family),
			"image_generation_used": false,
			"runtime_status_not_assumed": true,
			"service_created": false,
		}
		var file := FileAccess.open(str(EVIDENCE_ROOTS[family]).path_join("structural-results.json"), FileAccess.WRITE)
		check(file != null, "Opened " + family + " structural result")
		result.checks_at_batch_write = checks
		result.failures_at_batch_write = failures.duplicate()
		if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Passive lighting/entry structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
