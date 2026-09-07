extends SceneTree
## One deterministic exporter/structural gate plus optional actual native room.
## Use --headless -- --export-only first; native mode loads no personal save.
const ART := preload("res://tools/phone_booth_v1_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const TRANSPORT := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/phone-booth"
const ID := "phone-booth-candidate"
var checks := 0
var failures: Array[String] = []
var main: GameMain
var model: OfficeLayout
var directions: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 3) -> void:
	for _tick: int in range(count): await process_frame

func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "Open " + path)
	if file != null: file.store_string(JSON.stringify(data, "\t") + "\n")

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)

func export_art() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART.ROOT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var sheet := Image.create(ART.CANVAS.x * 4, ART.CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../dev/art-catalogue/furniture.json"))
	var record := {}
	for item: Dictionary in current.families:
		if item.id == "phone_booth": record = item
	check(not record.is_empty() and record.current_availability.runtime_family_id == null, "Booth is an existing non-runtime library family")
	check(OfficeLayout.vector(record.native_geometry.canvas_size_px) == ART.CANVAS and OfficeLayout.vector(record.native_geometry.floor_anchor_px) == ART.PIVOT, "Original canvas and floor pivot retained")
	var previous: Array[Image] = []
	for side: String in ART.SIDES:
		var layers := ART.layers(side)
		var whole := ART.whole(side)
		var descriptors: Array[Dictionary] = []
		var rebuilt := Image.create(ART.CANVAS.x, ART.CANVAS.y, false, Image.FORMAT_RGBA8)
		rebuilt.fill(Color(0, 0, 0, 0))
		for part: String in ART.LAYERS:
			var descriptor := ART.descriptor(side, part)
			var image := layers[part] as Image
			var facts := PIXELS.analyze(image)
			check(image.get_size() == ART.CANVAS and int(facts.opaque_pixels) > 0, side + "/" + part + " exact nonempty native canvas")
			check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, side + "/" + part + " true binary alpha / clean hidden RGB")
			save(image, str(descriptor.art))
			descriptor["measurements"] = facts
			descriptor["sha256"] = FileAccess.get_sha256(str(descriptor.art))
			descriptors.append(descriptor)
			rebuilt = ART.over(rebuilt, image)
		check(rebuilt.get_data() == whole.get_data(), side + " exact five-layer reconstruction")
		var bounds := whole.get_used_rect()
		check(Rect2i(16, 16, ART.CANVAS.x - 32, ART.CANVAS.y - 32).encloses(bounds), side + " protects native transparent margins")
		for old: Image in previous:
			check(old.get_data() != whole.get_data(), side + " distinct authored view")
			var mirror := old.duplicate()
			mirror.flip_x()
			check(mirror.get_data() != whole.get_data(), side + " is not a mirrored completed view")
		previous.append(whole)
		var original := {}
		for item: Dictionary in record.variants:
			if item.facing == side: original = item
		var expected: Array[String] = []
		var actual: Array[String] = []
		for value: Variant in original.proposed_occupied_cell_offsets: expected.append(str(OfficeLayout.vector(value)))
		for value: Variant in ART.occupied(side): actual.append(str(OfficeLayout.vector(value)))
		expected.sort()
		actual.sort()
		check(actual == expected and actual.size() == 9, side + " retains all nine original collision cells")
		check(OfficeLayout.vector(original.proposed_interaction_cell) == ART.approach(side), side + " preserves proposed doorway approach")
		save(whole, ART.ROOT.path_join(side + "-whole.png"))
		sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, ART.CANVAS), Vector2i(ART.SIDES.find(side) * ART.CANVAS.x, 0))
		directions.append({"facing": side, "layers": descriptors, "whole_measurements": PIXELS.analyze(whole), "whole_sha256": FileAccess.get_sha256(ART.ROOT.path_join(side + "-whole.png")), "occupied": ART.occupied(side), "approach": [ART.approach(side).x, ART.approach(side).y]})
	save(sheet, OUTPUT.path_join("candidate-contact-sheet-native.png"))
	var enlarged := sheet.duplicate()
	enlarged.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, OUTPUT.path_join("candidate-contact-sheet-4x.png"))
	write_json(ART.ROOT.path_join("manifest.json"), {"id": "phone-booth-v1", "status": "native_review_candidate_not_runtime", "canvas": [ART.CANVAS.x, ART.CANVAS.y], "pivot": [ART.PIVOT.x, ART.PIVOT.y], "rise_px": ART.RISE, "directions": directions, "provenance": "Original editable code-native geometry; no generated bitmap input, mirroring, rotation, runtime downscaling or fake transparency. Five independently occludable shell/interior/glass layers. Closed passive footprint, not an enterable phone action.", "checks": checks, "failures": failures})

func configure_room() -> void:
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(TRANSPORT.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	main._state_loaded = false
	main._worker_ready = false
	main.company_panel.hide()
	main.job_panel.close_drawer(false)
	main.founder_hud.dismiss_movement_hint()
	main._spawn_employees([])
	var data := main.room.layout_model.data.duplicate(true)
	var catalog := main.room.layout_model.catalog.duplicate(true)
	data.props = [{"id": ID, "kind": "phone_booth", "grid": [16, 13], "facing": "south", "required_hires": 0}]
	data.employees = []
	catalog.phone_booth = ART.catalog_entry()
	model = OfficeLayout.new()
	model.configure(data, catalog)
	check(model.enable_calibration_preview(self), "Live dev owner enabled")
	for side: String in ART.SIDES: check(model.authorize_calibration_decorative_profile("phone_booth", side, self), side + " passive admission only")
	var initial := safe_pivot()
	check(initial.x >= 0, "Choose a valid all-facing pivot before building room props")
	if initial.x < 0: return
	model.data.props[0].grid = [initial.x, initial.y]
	check(model.validate_placements(model.resolve_placements(0)).valid, "Initial fixture is valid before TownRoom rebuild")
	main.room.layout_model = model
	main.room.placement_overrides.clear()
	main.room.architecture.configure(model)
	main.room.set_hire_count(0)
	main.player.set_physics_process(false)
	main.player.cancel_route()
	main.player.position = model.world(Vector2i(24, 18))
	main.room.navigation.actors["founder"] = main.player.position
	await frames()

func safe_pivot() -> Vector2i:
	for y: int in range(10, 17):
		for x: int in range(11, 24):
			var point := Vector2i(x, y)
			var valid := true
			for side: String in ART.SIDES:
				if not model.validate_candidate(ID, point, side, 0).valid: valid = false
			if valid: return point
	return Vector2i(-1, -1)

func capture_room() -> void:
	await configure_room()
	var pivot := safe_pivot()
	check(pivot.x >= 0, "Actual architecture has a common safe four-facing pivot")
	if pivot.x < 0: return
	var room_sheet := Image.create(ART.CANVAS.x * 4, ART.CANVAS.y, false, Image.FORMAT_RGBA8)
	room_sheet.fill(Color("151515"))
	var results: Array[Dictionary] = []
	for side: String in ART.SIDES:
		check(main.room.set_placement_overrides({ID: {"grid": [pivot.x, pivot.y], "facing": side}}), side + " commits through actual TownRoom")
		await frames()
		var placement := main.room.placement_by_id(ID)
		var prop := main.room.prop_node(ID)
		check(placement.profile_kind == "decorative" and not main.room.interaction_world_position(ID).is_finite(), side + " no service or phone action")
		check(placement.occupied.size() == 9, side + " nine actual room occupied cells")
		for cell: Vector2i in placement.occupied: check(not main.room.navigation.walkable(cell), side + " physical cell blocks navigation")
		for part: String in ART.LAYERS:
			var descriptor := ART.descriptor(side, part)
			var sprite := prop.get_node(str(descriptor.name)) as Sprite2D
			check(sprite != null and sprite.position == Vector2(ART.OFFSET) and sprite.scale == Vector2.ONE and sprite.rotation == 0 and not sprite.flip_h and not sprite.flip_v, side + "/" + part + " native registration and no transform")
			check(sprite.z_index == prop.z_index + int(descriptor.z_offset), side + "/" + part + " exact authored depth")
		var previous := main.room.placement_overrides.duplicate(true)
		check(not main.room.set_placement_overrides({ID: {"grid": [1, 3], "facing": side}}), side + " rejects wall/corner transaction")
		check(main.room.placement_overrides == previous, side + " invalid wall leaves layout exact")
		var destination := model.world(pivot + ART.approach(side))
		main.player.position = model.world(Vector2i(24, 18))
		main.room.navigation.actors["founder"] = main.player.position
		check(main.player.move_to(destination), side + " actual founder path to proposed doorway")
		var safe := true
		for _tick: int in range(900):
			main.player._physics_process(1.0 / 30.0)
			if not main.room.navigation.position_is_safe(main.player.position, "founder"): safe = false
			if main.player.route.is_empty(): break
		check(safe and main.player.position.distance_to(destination) < 0.1, side + " path remains outside physical shell")
		main.player.face_direction(-Vector2(ART.approach(side)))
		main.player.z_index = int(main.player.position.y)
		await frames()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_size() == Vector2i(1280, 720), "Native frame dimensions")
		save(image, OUTPUT.path_join("actual-room-" + side + ".png"))
		var crop := Rect2i(Vector2i(main.room.global_position + placement.anchor) - ART.PIVOT, ART.CANVAS)
		check(Rect2i(Vector2i.ZERO, image.get_size()).encloses(crop), side + " full registered crop in frame")
		var detail := image.get_region(crop)
		save(detail, OUTPUT.path_join(side + "-detail-native.png"))
		room_sheet.blit_rect(detail, Rect2i(Vector2i.ZERO, ART.CANVAS), Vector2i(ART.SIDES.find(side) * ART.CANVAS.x, 0))
		results.append({"facing": side, "grid": [pivot.x, pivot.y], "actor_destination": [destination.x, destination.y], "actor_z": main.player.z_index, "prop_z": prop.z_index, "collision_cells": placement.occupied.size(), "route_safe": safe})
	save(room_sheet, OUTPUT.path_join("actual-room-contact-sheet-native.png"))
	room_sheet.resize(room_sheet.get_width() * 4, room_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(room_sheet, OUTPUT.path_join("actual-room-contact-sheet-4x.png"))
	write_json(OUTPUT.path_join("actual-room-results.json"), {"checks": checks, "failures": failures, "observations": results, "worker_started": false, "save_access": false, "runtime_registered": false, "scope": "Closed passive library: proposed approach and exterior founder depth, no booth entry, interior pose or calling behavior"})
	model.disable_calibration_preview(self)
	check(model.available_facings("phone_booth").is_empty(), "Closing owner revokes all candidate directions")
	main.game_audio.shutdown()
	main.queue_free()
	await frames()

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var catalog_hash := FileAccess.get_sha256("res://data/furniture_catalog.json")
	var layout_hash := FileAccess.get_sha256("res://data/office_layout.json")
	export_art()
	if DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().has("--export-only"): await capture_room()
	check(FileAccess.get_sha256("res://data/furniture_catalog.json") == catalog_hash and FileAccess.get_sha256("res://data/office_layout.json") == layout_hash, "Production catalogue and layout remain byte-exact")
	write_json(OUTPUT.path_join("headless-results.json" if DisplayServer.get_name() == "headless" else "results.json"), {"checks": checks, "failures": failures})
	print("Phone booth: %d checks / %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
