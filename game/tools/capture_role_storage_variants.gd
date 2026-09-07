extends SceneTree
## Read-only role decor through actual GameMain. Only South insert changes.
const FIXTURE := preload("res://tools/role_storage_fixture.gd")
const BASELINE := preload("res://tools/archive_production_fixture.gd")
const OUTPUT := "res://tests/output/role-storage-variants"
const COMMON := "res://assets/runtime/office/archive-v1/"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var parameters: Dictionary[String, String] = {}
var comparisons: Dictionary[String, Image] = {}
var source_hashes: Dictionary[String, String] = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for index: int in range(count): await process_frame

func freeze() -> void:
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values():
		actor.set_physics_process(false)
		actor._has_target = false
		actor._route.clear()
	fixture.place_editor_labels()

func input_event(event: InputEvent) -> void:
	root.push_input(event, true)
	await frames()
	freeze()

func click(point: Vector2) -> void:
	var hover := InputEventMouseMotion.new()
	hover.position = point
	hover.global_position = point
	root.push_input(hover, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await frames()
	freeze()

func rotate() -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_R
		event.physical_keycode = KEY_R
		event.pressed = down
		root.push_input(event, true)
	await frames()
	freeze()
	await click(fixture.model.world(Vector2i(4, 13)))

func composite(profile: Dictionary) -> Image:
	var result := Image.create(192, 288, false, Image.FORMAT_RGBA8)
	for layer: Dictionary in profile.render_layers:
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(layer.art)))
		image.convert(Image.FORMAT_RGBA8)
		result.blend_rect(image, Rect2i(0, 0, 192, 288), Vector2i.ZERO)
	return result

func validate_source(role: String, path: String) -> void:
	check(ResourceLoader.exists(path), role + " real native export is imported")
	if not ResourceLoader.exists(path): return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	check(image.get_size() == Vector2i(192, 288), "Registered role canvas is192×288")
	if image.get_size() != Vector2i(192, 288): return
	var region := Rect2i(52, 180, 88, 56)
	var bad_alpha := 0
	for y: int in range(288):
		for x: int in range(192):
			var expected := 1.0 if region.has_point(Vector2i(x, y)) else 0.0
			if image.get_pixel(x, y).a != expected: bad_alpha += 1
	check(bad_alpha == 0, role + " opaque88×56 material occupies exactfront and transparent exterior; no full-image matte")
	var texture := load(path) as Texture2D
	var imported := texture.get_image()
	imported.convert(Image.FORMAT_RGBA8)
	check(imported.get_data() == image.get_data(), "Registered runtime import keeps every source byte including padding")
	source_hashes[path] = FileAccess.get_sha256(path)
	var master := "res://assets/source/overnight-20260904/kits/" + role + "-storage-front-v1.png"
	check(FileAccess.file_exists(master), role + " preserved source master exists")
	source_hashes[master] = FileAccess.get_sha256(master)

func capture(role: String, side: String) -> void:
	var placement: Dictionary = fixture.main.room.placement_by_id("artifact-archive")
	var expected := composite(placement.profile)
	if side != "south" or role == "common":
		var common := Image.load_from_file(ProjectSettings.globalize_path(COMMON + side + "-whole.png"))
		common.convert(Image.FORMAT_RGBA8)
		check(expected.get_data() == common.get_data(), role + side + " wholeview is EXACT common reuse, not new role art")
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	freeze()
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Role study actualroom stays native1280×720")
	var count := 0
	var mismatches := 0
	for y: int in range(288):
		for x: int in range(192):
			var original := expected.get_pixel(x, y)
			if original.a < 0.99: continue
			var actual := image.get_pixelv(Vector2i(placement.anchor) - Vector2i(96, 224) + Vector2i(x, y))
			if absf(original.r - actual.r) > 0.01 or absf(original.g - actual.g) > 0.01 or absf(original.b - actual.b) > 0.01: mismatches += 1
			count += 1
	check(count > 0 and mismatches == 0, "Every actual native cabinet pixel matches ordered registered layers: " + role + side)
	var name_value := role + "-" + side
	check(image.save_png(OUTPUT.path_join(name_value + "-room.png")) == OK, "Save actual role room")
	var crop := image.get_region(Rect2i(Vector2i(placement.anchor) - Vector2i(80, 128), Vector2i(160, 192)))
	comparisons[name_value] = crop
	check(crop.save_png(OUTPUT.path_join(name_value + "-native.png")) == OK, "Save unchanged native crop")
	var detail := crop.duplicate()
	detail.resize(640, 768, Image.INTERPOLATE_NEAREST)
	check(detail.save_png(OUTPUT.path_join(name_value + "-4x.png")) == OK, "Save exact nearest4x crop")
	captures.append({"role": role, "side": side, "room": name_value + "-room.png", "native_crop": name_value + "-native.png", "new_front_visible": side == "south" and role != "common", "view_source": "new unapproved role South insert + reused common shell" if side == "south" and role != "common" else "unchanged approved common archive components; no new visible rolefront", "native_pixels_compared": count})

func role_scenario(role: String) -> void:
	fixture = FIXTURE.new()
	fixture.role = role
	fixture.south_insert_path = parameters[role]
	fixture.hires = 2
	root.add_child(fixture)
	await frames(4)
	check(fixture.ready_ok, role + " actualroom candidate validates: " + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.free()
		return
	freeze()
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1 and not fixture.main._state_loaded, "No worker or personal bootstrap")
	var model: OfficeLayout = fixture.model
	for side: String in ["south", "west", "north", "east"]:
		if fixture.main.room.placement_by_id("artifact-archive").facing != side: await rotate()
		var placement: Dictionary = fixture.main.room.placement_by_id("artifact-archive")
		check(placement.facing == side and not fixture.editor.placement_active, "RealR andmousecommit use canonical " + side + " servicegeometry")
		check(placement.profile.status == "calibration_candidate" and not placement.profile.review.art, "Role study does not promote new insert")
		check(not placement.has("work_cell") and not placement.has("pose_set"), "Storage role never borrows a seatedworker capability")
		for stage: int in range(1, 5): check(model.validate_candidate("artifact-archive", Vector2i(4, 13), side, stage).valid, "Rolefront preserves proven placement across stages")
		for layer: Dictionary in placement.render_layers:
			check(OfficeLayout.rectangle(layer.region) == Rect2(0, 0, 192, 288) and OfficeLayout.vector(layer.offset) == Vector2i(0, -80) and int(layer.z_offset) == 0, "All parts retain exact common registration and stable depth")
			if side != "south" or layer.name != "ArchiveInsert": check(str(layer.art).begins_with(COMMON), "Unchangedparts reuse actual approvedcommonfiles")
		await capture(role, side)
	fixture.free()
	check(not model.calibration_preview_enabled(), "Scoped roleadmission removed when scene ends")
	var ordinary := OfficeLayout.new()
	ordinary.load_files()
	check(ordinary.resolve_profile("artifact_archive", "south").profile.render_layers[-1].art == COMMON + "south-insert.png", "Independent normalroom stilluses original approved archivefront")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	for arg: String in OS.get_cmdline_user_args():
		for role: String in ["legal", "creative"]:
			if arg.begins_with("--" + role + "="): parameters[role] = arg.split("=", true, 1)[1]
	for role: String in ["legal", "creative"]:
		check(parameters.has(role), "Provide explicit actual registered --" + role + "=res://... path; missing art is not substituted")
	if not failures.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for role: String in ["legal", "creative"]: validate_source(role, parameters[role])
	for path: String in [OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH]: source_hashes[path] = FileAccess.get_sha256(path)
	if failures.is_empty():
		fixture = BASELINE.new()
		fixture.hires = 2
		fixture.show_editor = true
		root.add_child(fixture)
		await frames(4)
		check(fixture.ready_ok, "Unchanged approved common South control loads")
		freeze()
		await capture("common", "south")
		fixture.free()
		for role: String in ["legal", "creative"]: await role_scenario(role)
	if comparisons.size() == 9:
		var sheet := Image.create(640, 384, false, Image.FORMAT_RGBA8)
		for row: int in range(2):
			var role := "legal" if row == 0 else "creative"
			for column: int in range(4): sheet.blit_rect(comparisons[role + "-" + OfficeLayout.FACINGS[column]], Rect2i(0, 0, 160, 192), Vector2i(column * 160, row * 192))
		check(sheet.save_png(OUTPUT.path_join("all-roles-views-native.png")) == OK, "Save unscaled actualroomcompare: legalrow,creativerow; N/E/S/W columns")
		var fronts := Image.create(320, 192, false, Image.FORMAT_RGBA8)
		fronts.blit_rect(comparisons["legal-south"], Rect2i(0, 0, 160, 192), Vector2i.ZERO)
		fronts.blit_rect(comparisons["creative-south"], Rect2i(0, 0, 160, 192), Vector2i(160, 0))
		check(fronts.save_png(OUTPUT.path_join("legal-creative-fronts-native.png")) == OK, "Side-by-sideSouthfronts are exactnativeactualroomcrops,not syntheticapproval")
		var control := Image.create(480, 192, false, Image.FORMAT_RGBA8)
		for index: int in range(3): control.blit_rect(comparisons[["common-south", "legal-south", "creative-south"][index]], Rect2i(0, 0, 160, 192), Vector2i(index * 160, 0))
		check(control.save_png(OUTPUT.path_join("common-legal-creative-fronts-native.png")) == OK, "Compare approvedcommon control against bothunapprovedrolefronts atidenticalnative scale")
	for path: String in source_hashes: check(source_hashes[path] == FileAccess.get_sha256(path), "Study preserves sourcehash: " + path)
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "source_hashes": source_hashes, "runtime_approved": false, "new_drawings": 2, "reused_views_per_role": ["north", "east", "west"], "comparison_note": "Fresh independent actualGameMain scenes, shown sidebyside at unchanged nativepixels; no new productionvariant schema or specialist backend."}, "\t"))
	print("Role storage study: %dchecks, %dfailures, %drole/view captures." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
