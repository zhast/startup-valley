extends SceneTree
## Production archive promotion proof. Actual catalogue/room/actors/UI;
## no candidate permits, substituted art, provider, credentials or save access.
const FIXTURE := preload("res://tools/archive_production_fixture.gd")
const SOURCE := "res://tests/fixtures/furniture-calibration/modular-archive-v1/"
const RUNTIME := "res://assets/runtime/office/archive-v1/"
const OUTPUT := "res://tests/output/archive-production"
const SOURCE_FILES: Array[String] = [
	"res://world/main.gd", "res://actors/employee_avatar.gd", "res://actors/player_avatar.gd",
	"res://world/office_layout.gd", "res://world/town_room.gd", "res://data/furniture_catalog.json",
	"res://tools/archive_production_fixture.gd", "res://tests/test_archive_production.gd",
]
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var paths: Array[Dictionary] = []
var ticks := 0
var motion := false
var completed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for index: int in range(count): await process_frame
	# Placement commits replace the archive's StaticBody2D while navigation is
	# rebuilt synchronously. Manual route stepping below must not run until the
	# physics server has observed that same committed orientation.
	await physics_frame

func settle_drawer() -> void:
	var tween: Tween = fixture.main.job_panel._drawer_tween
	if tween != null and tween.is_valid() and tween.is_running(): await tween.finished
	await frames(2)

func freeze() -> void:
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values():
		actor.set_physics_process(false)
		actor._has_target = false
		actor._route.clear()
	fixture.place_editor_labels()

func fresh(hires: int) -> void:
	if is_instance_valid(fixture):
		fixture.free()
		await frames()
	fixture = FIXTURE.new()
	fixture.hires = hires
	root.add_child(fixture)
	await frames(4)
	freeze()
	check(fixture.ready_ok, "Production stage %d loads normally: %s" % [hires, fixture.errors])
	check(not fixture.main.room.layout_model.calibration_preview_enabled(), "Production fixture has no calibration owner or admission")
	check(fixture.main.worker_client is FIXTURE.TRANSPORT.NullWorker and fixture.main.worker_client._process_id == -1 and fixture.main.worker_client._stdio == null, "Transport isolated before scene ready; no worker started")
	check(not fixture.main._state_loaded and not fixture.main._worker_ready, "No personal bootstrap or saved state is loaded")

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

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
	await frames()
	freeze()

func capture(name_value: String, compare_archive := false) -> String:
	if DisplayServer.get_name() == "headless": return ""
	await frames(3)
	# Container geometry settles asynchronously when the optional dev editor is
	# first added. Resolve its real bounds immediately before the recorded draw.
	freeze()
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), name_value + " native composition")
	if is_instance_valid(fixture.editor):
		var toolbar: Rect2 = fixture.editor._inspector.get_parent().get_global_rect()
		for actor: EmployeeAvatar in fixture.main._employees.values():
			check(actor.labels_suppressed or not actor._labels_visible() or not toolbar.intersects(actor.world_label_rect()), name_value + " dev toolbar does not clip visible native callout")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if compare_archive:
		var archive: Dictionary = fixture.main.room.placement_by_id("artifact-archive")
		var expected := Image.load_from_file(ProjectSettings.globalize_path(RUNTIME + str(archive.facing) + "-whole.png"))
		var mismatches := 0
		var samples := 0
		for y: int in range(expected.get_height()):
			for x: int in range(expected.get_width()):
				var wanted := expected.get_pixel(x, y)
				if wanted.a < 0.99: continue
				var actual := image.get_pixelv(Vector2i(archive.anchor) - Vector2i(96, 224) + Vector2i(x, y))
				if absf(wanted.r - actual.r) > 0.01 or absf(wanted.g - actual.g) > 0.01 or absf(wanted.b - actual.b) > 0.01: mismatches += 1
				samples += 1
		check(samples > 0 and mismatches == 0, name_value + " every actual runtime archive pixel matches reviewed export")
		var detail := image.get_region(Rect2i(Vector2i(archive.anchor) + Vector2i(-96, -128), Vector2i(192, 208)))
		detail.resize(768, 832, Image.INTERPOLATE_NEAREST)
		check(detail.save_png(OUTPUT.path_join(name_value + "-4x.png")) == OK, "Save source-preserving nearest detail")
		captures.append(name_value + "-4x.png")
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(image.get_data())
	return digest.finish().hex_encode()

func walk(label_value: String) -> void:
	var player: PlayerAvatar = fixture.main.player
	var samples: Array[Dictionary] = []
	var distance := 0.0
	var cursor := player.position
	for waypoint: Vector2 in player.route:
		distance += cursor.distance_to(waypoint)
		cursor = waypoint
	var middle := maxi(1, int(distance / player.speed * 15))
	for index: int in range(1600):
		if index == 0 or index == middle:
			var suffix := "-start" if index == 0 else "-middle"
			samples.append({"foot": [player.position.x, player.position.y], "hash": await capture(label_value + suffix)})
		player._physics_process(1.0 / 30.0)
		fixture.place_editor_labels()
		check(player.navigation.position_is_safe(player.position, "founder"), label_value + " real route never crosses wall/furniture/live actor")
		ticks += 1
		if motion: await process_frame
		if player.route.is_empty(): break
	check(player.route.is_empty(), label_value + " actual route finishes")
	samples.append({"foot": [player.position.x, player.position.y], "hash": await capture(label_value + "-end")})
	check(samples.size() == 3, label_value + " actual start/middle/end positions sampled")
	if DisplayServer.get_name() != "headless" and samples.size() == 3:
		check(samples[0].hash != samples[1].hash and samples[1].hash != samples[2].hash, label_value + " real sampled movement frames differ")
	paths.append({"scenario": label_value, "samples": samples})

func validate_assets_and_stages() -> void:
	var model := OfficeLayout.new()
	check(model.load_files(), "Normal production files load")
	check(model.available_facings("artifact_archive") == OfficeLayout.FACINGS, "The reviewed archive retains all four production views")
	for kind: String in model.catalog:
		if kind == "artifact_archive": continue
		var expected: Array[String] = []
		expected.assign(OfficeLayout.FACINGS if kind in ["desk", "approval_console", "coffee_station", "collaboration_cluster", "prototype_bench", "research_table", "broadleaf_planter", "task_floor_lamp", "coat_bag_stand", "water_station", "resource_cart", "printer_scanner_station", "recycling_sorter", "tall_storage_cabinet", "server_cabinet", "low_coffee_table", "round_meeting_table", "low_bookshelf", "acoustic_divider", "mobile_whiteboard", "visitor_chair", "rolling_storage_pedestal"] else ["south"])
		check(model.available_facings(kind) == expected, kind + " exposes only its separately reviewed production views")
	for side: String in OfficeLayout.FACINGS:
		for part: String in ["carcass", "top", "front", "plinth", "insert", "whole"]:
			var file := side + "-" + part + ".png"
			check(FileAccess.file_exists(RUNTIME + file), "Runtime export exists: " + file)
			check(FileAccess.get_sha256(RUNTIME + file) == FileAccess.get_sha256(SOURCE + file), "Runtime file is byte-identical to reviewed native export: " + file)
			var texture := load(RUNTIME + file) as Texture2D
			check(texture != null and texture.get_size() == Vector2(192, 288), "Runtime registered canvas preserved: " + file)
			if texture != null:
				var imported := texture.get_image()
				var original := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + file))
				imported.convert(Image.FORMAT_RGBA8)
				original.convert(Image.FORMAT_RGBA8)
				check(imported.get_data() == original.get_data(), "Imported RGBA including transparent padding is exact: " + file)
		var profile: Dictionary = model.resolve_profile("artifact_archive", side).profile
		check(profile.status == "runtime_ready" and profile.review.art and profile.review.geometry and not profile.has("calibration_preview"), "Honest production art/geometry approval only: " + side)
		for field: String in OfficeLayout.SEATED_FIELDS: check(not profile.has(field), "No invented archive pose field: " + field)
		for stage: int in range(1, 5):
			check(model.validate_candidate("artifact-archive", Vector2i(4, 13), side, stage).valid, side + " preserves every actual office composition stage " + str(stage))
	for stage: int in range(5): check(model.validate_placements(model.resolve_placements(stage)).valid, "Default production stage " + str(stage) + " valid")
	var archive := model.placement_by_id("artifact-archive", 1)
	check(archive.grid == Vector2i(4, 13) and archive.facing == "south", "Default archive stays in original South bay")
	check(archive.occupied == OfficeLayout._offset_cells(model.catalog.artifact_archive.occupied, archive.grid), "South physical footprint unchanged")
	check(archive.clearance == OfficeLayout._offset_cells(model.catalog.artifact_archive.clearance, archive.grid), "South clearance unchanged")
	check(archive.interaction == archive.grid + Vector2i.DOWN, "South existing service point unchanged")
	check(FileAccess.file_exists("res://assets/runtime/office/artifact-archive.png"), "Previous runtime master is retained recoverably")

func scene_scenarios() -> void:
	for stage: int in range(5):
		await fresh(stage)
		await capture("office-stage-" + str(stage), stage > 0)
		check(fixture.main.room.placement_by_id("artifact-archive").is_empty() == (stage == 0), "Archive still follows original first-hire unlock")
	# Actual normal office, not the isolated service showroom. Move through the
	# real room from its unchanged initial spawn before exposing the dev toolbar.
	for stage: int in [1, 4]:
		await fresh(stage)
		var game: GameMain = fixture.main
		var room: TownRoom = game.room
		var home := room.layout_model.world(Vector2i(17, 16))
		await click(home)
		await walk("stage%d-initial-walk" % stage)
		fixture.editor = FIXTURE.ProductionEditor.new()
		fixture.editor.game = game
		fixture.add_child(fixture.editor)
		fixture.editor.select_placement("artifact-archive")
		await frames()
		for side: String in ["south", "west", "north", "east"]:
			if str(room.placement_by_id("artifact-archive").facing) != side:
				await key(KEY_R)
				check(fixture.editor.placement_active and fixture.editor.preview_facing == side, "Real R chooses production archive " + side)
				await click(room.layout_model.world(Vector2i(4, 13)))
				check(not fixture.editor.placement_active and room.placement_by_id("artifact-archive").facing == side, "Real commit installs approved view in normal room")
			await capture("stage%d-view-%s" % [stage, side], true)
			var socket := room.interaction_world_position("artifact-archive")
			await click(room.placement_by_id("artifact-archive").world_hit_bounds.get_center())
			check(not game.job_panel.drawer_is_open() and not game.player.route.is_empty(), "Archive click walks before Studio opens")
			await walk("stage%d-approach-%s" % [stage, side])
			await settle_drawer() # Hit-test only after the real transition, independent of headless wall-clock speed.
			var expected_pose: String = {"north": "front", "east": "left", "south": "back", "west": "right"}[side]
			check(game.player.position == socket and game.player._facing == expected_pose, "Exact normal-room service socket and gaze reached")
			check(game.job_panel.drawer_is_open() and game.job_panel._tabs.current_tab == 3, "Existing Studio opens from actual production archive")
			await capture("stage%d-studio-%s" % [stage, side])
			var feet := game.player.position
			await click(Vector2(900, 240))
			check(game.player.position == feet and game.player.route.is_empty(), "Studio click cannot leak into normal world")
			# Use the real close target, then walk away before a shape-changing turn.
			await click(game.job_panel._drawer_close_button.get_global_rect().get_center())
			await settle_drawer()
			game.player.input_blocked = false
			check(not game.job_panel.drawer_is_open(), "Actual close target dismisses Studio")
			await click(home)
			await walk("stage%d-leave-%s" % [stage, side])
			# Roster reconciliation must preserve the explicit shared-prop facing;
			# it must not restore South or borrow employee work sockets.
			var before := game.player.position
			var records := room.placeholder_records()
			records.resize(mini(stage, records.size()))
			game._spawn_employees(records)
			room.set_hire_count(stage)
			freeze()
			check(room.placement_by_id("artifact-archive").facing == side and game.player.position == before, "Roster/growth reconciliation preserves archive direction without actor pop")
			check(room.layout_model.validate_placements(room.resolved_placements).valid, "Reconciled real office remains valid")
			var export_path := "res://tests/output/office-layout/archive-production-stage%d-%s.json" % [stage, side]
			check(fixture.editor.export_layout(export_path), "Existing guarded developer export stores actual approved facing")
			var reloaded := OfficeLayout.new()
			check(reloaded.load_files(export_path), "Fresh normal model reloads developer export without calibration permits")
			check(reloaded.placement_by_id("artifact-archive", stage).facing == side and not reloaded.calibration_preview_enabled(), "Export/reload keeps real approved view and does not borrow preview admission")
			for later: int in range(5): check(reloaded.validate_placements(reloaded.resolve_placements(later)).valid, "Export/reload preserves all future office stages")
	completed = true

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	motion = OS.get_cmdline_user_args().has("--motion")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var room_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH)
	var catalog_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH)
	var source_hashes: Dictionary = {}
	for path: String in SOURCE_FILES: source_hashes[path] = FileAccess.get_sha256(path)
	validate_assets_and_stages()
	if failures.is_empty(): await scene_scenarios()
	check(completed, "Every production scene/input scenario completed")
	if is_instance_valid(fixture): fixture.free()
	check(FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH) == room_hash and FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH) == catalog_hash, "Production tests never write runtime room/catalogue")
	for path: String in SOURCE_FILES:
		check(source_hashes[path] == FileAccess.get_sha256(path), "Evidence source remained frozen: " + path)
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "paths": paths, "physics_ticks": ticks, "completed": completed, "calibration_permits": false, "worker_started": false, "personal_state_loaded": false, "source_hashes": source_hashes}, "\t"))
	print("Production archive: %d checks, %d failures, %d captures, %d actual physics ticks." % [checks, failures.size(), captures.size(), ticks])
	quit(0 if failures.is_empty() else 1)
