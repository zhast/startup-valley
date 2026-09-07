extends SceneTree
## Real authored archive art and standing-service contracts; no pose registry,
## provider, credential, personal bootstrap or persistence operation.
const FIXTURE := preload("res://tools/calibrated_service_fixture.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/calibrated-service"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var capture_hashes: Dictionary[String, String] = {}
var paths: Array[Dictionary] = []
var ticks := 0
var motion := false
var input_complete := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for index: int in range(count): await process_frame
	# A placement commit swaps StaticBody2D nodes immediately while the physics
	# server consumes that change on its next frame. Manual move_and_slide loops
	# below must see the same facing that the synchronous A* rebuild already sees.
	await physics_frame

func click(point: Vector2) -> void:
	var hover := InputEventMouseMotion.new()
	hover.position = point
	hover.global_position = point
	root.push_input(hover, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await frames()

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
	await frames()

func freeze_processes() -> void:
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for person: EmployeeAvatar in fixture.main._employees.values(): person.set_physics_process(false)

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), name_value + " actual native GameMain dimensions")
	check(fixture.editor._status.get_line_count() <= 2 and fixture.editor._status.get_global_rect().end.y <= 713, name_value + " diagnostic status fits entirely inside native paper/viewport")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	capture_hashes[name_value] = PIXELS.digest(PIXELS.rgba(image).get_data())
	if name_value.begins_with("view-"):
		var archive: Dictionary = fixture.main.room.placement_by_id("artifact-archive")
		var whole := Image.load_from_file(ProjectSettings.globalize_path(FIXTURE.EXPORTS + str(archive.facing) + "-whole.png"))
		var mismatches := 0
		var samples := 0
		for y: int in range(whole.get_height()):
			for x: int in range(whole.get_width()):
				var expected := whole.get_pixel(x, y)
				if expected.a < 0.99: continue
				var actual := image.get_pixelv(Vector2i(archive.anchor) - Vector2i(96, 224) + Vector2i(x, y))
				if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatches += 1
				samples += 1
		check(samples > 0 and mismatches == 0, name_value + " actual canonical render matches every opaque exported pixel; mismatches=" + str(mismatches))
		var detail := image.get_region(Rect2i(Vector2i(archive.anchor) + Vector2i(-112, -144), Vector2i(224, 224)))
		detail.resize(896, 896, Image.INTERPOLATE_NEAREST)
		check(detail.save_png(OUTPUT.path_join(name_value + "-4x.png")) == OK, "Save native-nearest detail " + name_value)
		captures.append(name_value + "-4x.png")

func walk_until_done(label_value: String) -> void:
	var player: PlayerAvatar = fixture.main.player
	var samples: Array[Dictionary] = []
	var start := player.position
	var distance := 0.0
	var cursor := start
	for next: Vector2 in player.route:
		distance += cursor.distance_to(next)
		cursor = next
	var mid := maxi(1, int(distance / player.speed * 15.0))
	for index: int in range(1800):
		if index == 0 or index == mid:
			await capture(label_value + ("-start" if index == 0 else "-middle"))
			samples.append({"tick": ticks, "foot": [player.position.x, player.position.y], "facing": str(player._facing), "image_sha256": capture_hashes.get(label_value + ("-start" if index == 0 else "-middle"), "")})
		player._physics_process(1.0 / 30.0)
		check(player.navigation.position_is_safe(player.position, "founder"), label_value + " actual founder physics never crosses furniture/wall")
		check(player._character_sprite.scale == Vector2.ONE and is_zero_approx(player._character_sprite.rotation), label_value + " native standing/walk source")
		ticks += 1
		if motion: await process_frame
		if player.route.is_empty(): break
	check(player.route.is_empty(), label_value + " route completed within bound; blocked=%s foot=%s next=%s" % [player.input_blocked, player.position, player.route[0] if not player.route.is_empty() else Vector2.ZERO])
	await capture(label_value + "-end")
	samples.append({"tick": ticks, "foot": [player.position.x, player.position.y], "facing": str(player._facing), "image_sha256": capture_hashes.get(label_value + "-end", "")})
	check(samples.size() == 3, label_value + " start/middle/end path markers were actually reached")
	if DisplayServer.get_name() != "headless":
		check(samples[0].image_sha256 != samples[-1].image_sha256 and samples[1].image_sha256 != samples[0].image_sha256, label_value + " actual sampled motion images are distinct")
	paths.append({"scenario": label_value, "samples": samples, "target": [player._route_target.x, player._route_target.y]})

func check_contracts(model: OfficeLayout, owner: Object) -> void:
	var clean: Dictionary = model.catalog.artifact_archive.duplicate(true)
	for side: String in OfficeLayout.FACINGS:
		var resolved := model.resolve_profile("artifact_archive", side)
		check(resolved.errors.is_empty(), side + " actual service candidate admitted with geometry validation")
		check(resolved.profile.service_side == side and resolved.profile.approach_gaze == OfficeLayout.OPPOSITE_GAZE[side], side + " service side and opposite gaze explicit")
		check(not resolved.profile.review.art and not resolved.profile.review.geometry, side + " admission does not mutate real review flags")
		var placement := model.resolve({"id": "artifact-archive", "kind": "artifact_archive", "grid": [10, 15], "facing": side})
		for field: String in OfficeLayout.SEATED_FIELDS:
			check(not resolved.profile.has(field) and not placement.has(field), side + " no invented seated metadata: " + field)
		check(not placement.has("work_position"), side + " no fake worker destination")
		var names: Array[String] = []
		for layer: Dictionary in placement.render_layers: names.append(layer.name)
		check(names == ["ArchiveCarcass", "ArchiveTop", "ArchiveFront", "ArchivePlinth", "ArchiveInsert"], side + " equal-depth source layer ownership/order preserved")
		for point: Vector2i in [Vector2i(1, 3), Vector2i(34, 3), Vector2i(1, 20), Vector2i(34, 20), Vector2i(16, 15), Vector2i(10, 10)]:
			check(not model.validate_candidate("artifact-archive", point, side, 2).valid, side + " wall/corner/aisle placement rejected " + str(point))
		check(model.validate_candidate("artifact-archive", Vector2i(10, 15), side, 2).valid, side + " real interior footprint, service and image bounds valid")
	var unsafe_north := model.validate_candidate("artifact-archive", Vector2i(2, 5), "north", 2)
	check(not unsafe_north.valid and unsafe_north.issues.any(func(issue: Dictionary) -> bool: return issue.code == "service_headroom"), "North source/body can fit while visitor headroom correctly rejects wall overlap")
	check(model.validate_candidate("artifact-archive", Vector2i(2, 6), "north", 2).valid, "One inward row gives actual standing-source headroom at pivot80,208")
	var other := Node.new()
	root.add_child(other)
	check(not model.authorize_calibration_service_profile("artifact_archive", "north", other), "Other live owner cannot authorize this model")
	model.disable_calibration_preview(other)
	check(model.resolve_profile("artifact_archive", "north").errors.is_empty(), "Other live owner cannot revoke existing service permits")
	var copied := OfficeLayout.new()
	copied.configure(model.data, model.catalog)
	check(copied.enable_calibration_preview(other), "Second independent model accepts own live owner")
	check(not copied.resolve_profile("artifact_archive", "north").errors.is_empty(), "Copying catalogue does not copy another model's candidate permit")
	check(not copied.authorize_calibration_service_profile("artifact_archive", "north", owner), "Cross-model owner cannot borrow authorization")
	check(copied.authorize_calibration_service_profile("artifact_archive", "north", other), "New owner must explicitly validate its own exact candidate")
	other.free()
	check(not copied.resolve_profile("artifact_archive", "north").errors.is_empty(), "Expired owner immediately closes standing candidate admission")
	for missing: String in OfficeLayout.SERVICE_FIELDS:
		model.catalog.artifact_archive = clean.duplicate(true)
		model.catalog.artifact_archive.facing_profiles.north.erase(missing)
		check(not model.authorize_calibration_service_profile("artifact_archive", "north", owner), "Missing explicit field rejected: " + missing)
		check(not model.resolve_profile("artifact_archive", "north").errors.is_empty(), "Missing field unavailable even after prior permit: " + missing)
	var mutations: Array[Dictionary] = [
		{"field": "approach_gaze", "value": "north"}, {"field": "service_side", "value": "west"},
		{"field": "profile_kind", "value": "poster"}, {"field": "interaction", "value": [0, 0]},
		{"field": "interaction", "value": [0, -2]}, {"field": "interaction", "value": [0.5, -1]},
		{"field": "clearance", "value": [[0, 0]]}, {"field": "anchor_offset", "value": [0.25, 0]},
		{"field": "review", "value": {"art": "yes", "geometry": true}},
		{"field": "review", "value": {"art": false, "geometry": false, "poses": true}},
		{"field": "render_layers", "value": []}, {"field": "occupied", "value": []},
		{"field": "visual_bounds", "value": [-96, -224, 192, 288]},
		{"field": "approach_visual_bounds", "value": [-16, -40, 32, 48]},
		{"field": "approach_visual_bounds", "value": [-24, -71, 48, 79]},
		{"field": "approach_visual_bounds", "value": [-24.25, -72, 48, 80]},
		{"field": "approach_visual_bounds", "value": "native"},
		{"field": "approach_visual_bounds", "value": Rect2(-24, -72, INF, 80)},
		{"field": "approach_visual_bounds", "value": [-24, -72, 48, NAN]},
	]
	for field: String in OfficeLayout.SEATED_FIELDS: mutations.append({"field": field, "value": [0, 0] if field.ends_with("anchor") else "fake"})
	for mutation: Dictionary in mutations:
		model.catalog.artifact_archive = clean.duplicate(true)
		model.catalog.artifact_archive.facing_profiles.north[mutation.field] = mutation.value
		check(not model.authorize_calibration_service_profile("artifact_archive", "north", owner), "Malformed/mixed profile cannot authorize: " + mutation.field)
		check(not model.resolve_profile("artifact_archive", "north").errors.is_empty(), "Malformed/mixed profile unavailable: " + mutation.field)
	model.catalog.artifact_archive = clean.duplicate(true)
	model.catalog.artifact_archive.facing_profiles.north.render_layers[0].z_offset = 1
	check(not model.resolve_profile("artifact_archive", "north").errors.is_empty(), "Even valid layer edits invalidate an exact-definition permit")
	check(model.authorize_calibration_service_profile("artifact_archive", "north", owner), "Owner may explicitly revalidate changed valid geometry")
	model.catalog.artifact_archive = clean.duplicate(true)
	for side: String in OfficeLayout.FACINGS:
		check(model.authorize_calibration_service_profile("artifact_archive", side, owner), "Restore exact original candidate " + side)
	var production := OfficeLayout.new()
	production.configure(model.data, model.catalog)
	check(production.available_facings("artifact_archive").is_empty(), "Unreviewed new views never leak into production model")
	# A separate synthetic readiness assertion proves standing profiles do not
	# need a pose gate; it is not written back to candidate metadata or exports.
	production.catalog.artifact_archive.facing_profiles.south.status = "runtime_ready"
	production.catalog.artifact_archive.facing_profiles.south.review = {"art": true, "geometry": true}
	check(production.available_facings("artifact_archive") == ["south"], "Standing runtime gate requires art+geometry without fictional pose approval")
	production.catalog.artifact_archive.facing_profiles.south.review.geometry = false
	check(production.available_facings("artifact_archive").is_empty(), "Missing geometry approval still prevents production availability")
	var legacy := OfficeLayout.new()
	check(legacy.load_files(), "Production catalogue loads")
	check(legacy.available_facings("artifact_archive") == OfficeLayout.FACINGS, "Separately reviewed archive views remain genuinely shipped")
	check(legacy.available_facings("coffee_station") == OfficeLayout.FACINGS and legacy.catalog.coffee_station.get("interaction_enabled", true) == false, "Reviewed coffee service geometry ships independently while its product interaction stays disabled")
	# The prior flat archive profile and source remain intact as an explicit
	# backward-compatibility fixture; never relax unrelated South-only gates.
	var legacy_catalog := legacy.catalog.duplicate(true)
	legacy_catalog.artifact_archive.erase("facing_profiles")
	legacy_catalog.artifact_archive.facings = ["south"]
	legacy.configure(legacy.data, legacy_catalog)
	check(legacy.available_facings("artifact_archive") == ["south"] and legacy.available_facings("desk") == OfficeLayout.FACINGS, "Legacy archive fallback remains South-only without changing reviewed desk availability")
	var south := legacy.placement_by_id("artifact-archive", 2)
	check(not south.has("profile_kind") and OfficeLayout.vector(south.render_layers[0].offset) == Vector2i(0, -43), "Legacy archive origin and profile representation unchanged")
	check(south.render_layers[0].art == "res://assets/runtime/office/artifact-archive.png", "Legacy archive source unchanged")
	var mixed: Dictionary = model.catalog.desk.duplicate(true)
	mixed.facings = ["north"]
	mixed.facing_profiles = {"north": clean.facing_profiles.north.duplicate(true)}
	production.catalog.desk = mixed
	check(not production.resolve_profile("desk", "north").errors.is_empty(), "A desk cannot evade seated capability checks with a service profile")

func input_scenarios() -> void:
	var game: GameMain = fixture.main
	var room: TownRoom = game.room
	var player: PlayerAvatar = game.player
	for side: String in ["south", "west", "north", "east"]:
		game.job_panel.close_drawer(false)
		player.input_blocked = false
		if str(room.placement_by_id("artifact-archive").facing) != side:
			await key(KEY_R)
			check(fixture.editor.placement_active and fixture.editor.preview_facing == side, side + " real R selects next authored service view")
			await click(room.layout_model.world(Vector2i(10, 15)))
			check(not fixture.editor.placement_active and str(room.placement_by_id("artifact-archive").facing) == side, side + " actual editor commit installs canonical layers")
			freeze_processes()
		var archive := room.placement_by_id("artifact-archive")
		var expected: Vector2 = room.interaction_world_position("artifact-archive")
		check(room.navigation.walkable(room.navigation.cell_at(expected)), side + " service target is actually walkable")
		check(room.employee_workstation_visual("artifact-archive").is_empty(), side + " service prop exposes no seated visual")
		await capture("view-" + side)
		await click(archive.world_hit_bounds.get_center())
		check(game._pending_interaction == "artifact-archive" and not player.route.is_empty(), side + " actual mouse hit begins real founder route")
		check(not game.job_panel.drawer_is_open(), side + " Studio does not open before arrival")
		freeze_processes()
		await walk_until_done("approach-" + side)
		check(player.position.distance_to(expected) < 0.01, side + " exact service cell reached")
		check(game.job_panel.drawer_is_open() and game.job_panel._tabs.current_tab == 3, side + " actual arrival opens existing Studio")
		var expected_pose: StringName = {"north": &"front", "east": &"left", "south": &"back", "west": &"right"}[side]
		check(player._facing == expected_pose, side + " founder faces service from the actual standing side")
		check(room.interaction_approach_direction("mira-workstation") == Vector2.ZERO, side + " legacy workstation has no forced arrival gaze")
		await capture("studio-" + side)
		await click(game.job_panel.drawer_global_rect().position + Vector2(60, 200))
		check(player.route.is_empty() and game._pending_interaction.is_empty(), side + " real Studio paper click does not leak into world navigation")
		game.job_panel.close_drawer(false)
		player.input_blocked = false
		# Return through a real click before rotating. A standing service user can
		# occupy a cell that another facing would block; never teleport it aside.
		await click(room.layout_model.world(Vector2i(17, 17)))
		freeze_processes()
		await walk_until_done("leave-" + side)
	# Current view E; next S blocks the right/left cells. Reject a real founder
	# obstruction without changing overrides/history or physical feet.
	var before := room.placement_overrides.duplicate(true)
	var history: int = fixture.editor._history.size()
	player.position = room.layout_model.world(Vector2i(11, 15))
	room.navigation.actors["founder"] = player.position
	var foot := player.position
	await key(KEY_R)
	await click(room.layout_model.world(Vector2i(10, 15)))
	check(fixture.editor.placement_active and not fixture.editor.preview_result.valid, "Real occupied service rotation rejected")
	check(room.placement_overrides == before and fixture.editor._history.size() == history and player.position == foot, "Rejected service rotation preserves candidate history and founder feet")
	await capture("occupied-rotation-rejected")
	await key(KEY_ESCAPE)
	check(not fixture.editor.placement_active, "Real Escape cancels rejected service preview")
	freeze_processes()
	# Safe route away (not a placement-induced teleport), then rotation succeeds.
	player.input_blocked = false
	await click(room.layout_model.world(Vector2i(17, 17)))
	freeze_processes()
	await walk_until_done("leave-before-rotation")
	await key(KEY_R)
	await click(room.layout_model.world(Vector2i(10, 15)))
	check(str(room.placement_by_id("artifact-archive").facing) == "south", "Leave then actual R commit accepted without actor pop")
	freeze_processes()
	# Explicitly stage another live body's foot in a newly blocked cell. This
	# is test setup, never an implementation-side evacuation/teleport.
	var mina := game.get_employee("mira")
	var old_mina := mina.position
	mina.position = room.layout_model.world(Vector2i(10, 14))
	room.navigation.actors["mira"] = mina.position
	mina._update_character_frame()
	before = room.placement_overrides.duplicate(true)
	history = fixture.editor._history.size()
	await key(KEY_R)
	await click(room.layout_model.world(Vector2i(10, 15)))
	check(fixture.editor.placement_active and not fixture.editor.preview_result.valid and "Mina" in fixture.editor._status.text, "Other employee blocks actual service rotation with actionable identity")
	check(room.placement_overrides == before and fixture.editor._history.size() == history and mina.position == room.layout_model.world(Vector2i(10, 14)), "Other actor rejection preserves feet, furniture and undo")
	await capture("employee-rotation-rejected")
	await key(KEY_ESCAPE)
	freeze_processes()
	mina.position = old_mina
	room.navigation.actors["mira"] = old_mina
	mina._update_character_frame()
	for bad: Vector2i in [Vector2i(1, 15), Vector2i(1, 3)]:
		await key(KEY_M)
		await click(room.layout_model.world(bad))
		check(fixture.editor.placement_active and not fixture.editor.preview_result.valid and room.placement_overrides == before, "Actual world click rejects wall/corner placement " + str(bad))
		await capture("rejected-wall-%d-%d" % [bad.x, bad.y])
		await key(KEY_ESCAPE)
		freeze_processes()
	# An already occupied service socket must not use nearest-free fallback to
	# open Studio from an adjacent location. No actor is displaced by the click.
	game.job_panel.close_drawer(false)
	player.input_blocked = false
	mina.position = room.interaction_world_position("artifact-archive")
	room.navigation.actors["mira"] = mina.position
	mina._update_character_frame()
	var occupied_socket := mina.position
	var founder_before := player.position
	# Click exposed archive art, not the occluding employee's hit rectangle;
	# selecting that person must legitimately retain employee-chat priority.
	await click(room.placement_by_id("artifact-archive").world_hit_bounds.position + Vector2(8, 20))
	check(player.route.is_empty() and game._pending_interaction.is_empty() and not game.job_panel.drawer_is_open(), "Occupied socket rejects real click rather than opening Studio from fallback cell")
	check(mina.position == occupied_socket and player.position == founder_before, "Rejected interaction never moves either actor")
	await capture("occupied-service-rejected")
	mina.position = old_mina
	room.navigation.actors["mira"] = old_mina
	mina._update_character_frame()
	# A real editor rotation during an incoming route changes the destination.
	# Existing placement-change behavior safely cancels founder intent; no stale
	# service action, automatic relocation or fabricated arrival is allowed.
	await click(room.placement_by_id("artifact-archive").world_hit_bounds.get_center())
	freeze_processes()
	for index: int in range(4): player._physics_process(1.0 / 30.0)
	check(not player.route.is_empty(), "Service route genuinely in flight before rotation")
	var travelling := player.position
	await key(KEY_R)
	await click(room.layout_model.world(Vector2i(10, 15)))
	freeze_processes()
	check(str(room.placement_by_id("artifact-archive").facing) == "west" and player.position == travelling, "Unobstructed rotation preserves travelling founder feet")
	check(player.route.is_empty() and game._pending_interaction.is_empty() and not game.job_panel.drawer_is_open(), "Changed service target cancels stale founder intent without false action")
	await capture("service-target-changed")
	await key(KEY_U)
	freeze_processes()
	check(str(room.placement_by_id("artifact-archive").facing) == "south", "Actual undo restores clear prior service view")
	# Deterministically inject a transient navigation obstruction AFTER the real
	# click, without replacing furniture, moving an actor, or calling an arrival
	# handler. The real PlayerAvatar replans to a nearby point; the arrival gate
	# must refuse to interpret that fallback as a successful service interaction.
	player.input_blocked = false
	await click(room.placement_by_id("artifact-archive").world_hit_bounds.get_center())
	freeze_processes()
	check(not player.route.is_empty(), "Real route exists before transient socket obstruction")
	var socket := room.interaction_world_position("artifact-archive")
	var socket_cell := room.navigation.cell_at(socket)
	room.navigation.grid.set_point_solid(socket_cell, true)
	room.navigation.revision += 1
	await walk_until_done("late-socket-blocked")
	check(player.position.distance_to(socket) > 2 and not game.job_panel.drawer_is_open() and game._pending_interaction.is_empty(), "Actual fallback arrival cannot open Studio after socket became blocked")
	room.navigation.grid.set_point_solid(socket_cell, false)
	room.navigation.revision += 1
	await capture("late-socket-rejected")
	# Real preview rejects the old nearest north placement solely for standing
	# source-cell headroom, then accepts the explicitly moved inward row.
	await key(KEY_R)
	await key(KEY_R)
	check(fixture.editor.preview_facing == "north", "Real two-key preview reaches north service side")
	await click(room.layout_model.world(Vector2i(2, 5)))
	check(fixture.editor.placement_active and fixture.editor.preview_result.errors.any(func(reason: String) -> bool: return reason.contains("Standing visitor would overlap a wall")), "Actual north preview rejects a clear foot cell whose visitor head reaches wall")
	await capture("headroom-wall-rejected")
	await click(room.layout_model.world(Vector2i(2, 6)))
	check(not fixture.editor.placement_active and room.placement_by_id("artifact-archive").grid == Vector2i(2, 6), "Actual inward north placement accepted with headroom, no actor reposition")
	freeze_processes()
	await capture("headroom-inward-accepted")
	player.input_blocked = false
	await click(room.placement_by_id("artifact-archive").world_hit_bounds.position + Vector2(8, 20))
	freeze_processes()
	await walk_until_done("headroom-north-approach")
	check(player.position == room.interaction_world_position("artifact-archive") and game.job_panel.drawer_is_open(), "Founder really reaches inward north service point and opens Studio")
	var standing := Rect2(player.position + OfficeLayout.STANDING_SOURCE_BOUNDS.position, OfficeLayout.STANDING_SOURCE_BOUNDS.size)
	for corner: Vector2 in [standing.position, Vector2(standing.end.x - 1, standing.position.y), standing.end - Vector2.ONE, Vector2(standing.position.x, standing.end.y - 1)]:
		check(room.layout_model.is_floor(room.layout_model.cell_at(corner)), "Actual source-cell corner lies over floor after inward placement")
	await capture("headroom-north-service")
	# Invalid wall click: no route, false arrival UI, or forced service gaze.
	game.job_panel.close_drawer(false)
	player.input_blocked = false
	var gaze := player._facing
	await click(Vector2(8, 320))
	check(player.route.is_empty() and game._pending_interaction.is_empty() and not game.job_panel.drawer_is_open(), "Unreachable wall input causes no false service action")
	check(player._facing == gaze, "Failed click never forces a service pose")
	check(game.get_node("WorkerClient") is FIXTURE.TRANSPORT.NullWorker and game.worker_client._process_id == -1 and game.worker_client._stdio == null, "Only null transport exists; no worker process or pipe was started")
	input_complete = true

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	motion = OS.get_cmdline_user_args().has("--motion")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(5)
	check(fixture.ready_ok, "Worker-free actual archive fixture ready: " + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.free()
		quit(1)
		return
	freeze_processes()
	check_contracts(fixture.model, fixture)
	await input_scenarios()
	check(input_complete, "All real input scenarios completed without an early runtime error")
	var retained: OfficeLayout = fixture.model
	fixture.free()
	await frames()
	check(retained.available_facings("artifact_archive").is_empty(), "Fixture teardown revokes every service candidate")
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(4)
	check(fixture.ready_ok, "Second independent actual fixture initializes without leaked permits/state")
	check(str(fixture.main.room.placement_by_id("artifact-archive").facing) == "south" and not fixture.main.job_panel.drawer_is_open(), "Second fixture has no old rotation or Studio attention; view=%s drawer=%s" % [fixture.main.room.placement_by_id("artifact-archive").facing, fixture.main.job_panel.drawer_is_open()])
	fixture.free()
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "capture_hashes": capture_hashes, "paths": paths, "physics_ticks": ticks,
		"input_complete": input_complete, "worker_started": false, "save_access": false, "runtime_approved": false,
		"limitations": ["Art remains unapproved calibration output.", "No new service backend, document persistence or seated/reaching pose.", "Tall rear archive intentionally occludes standing actors."]}, "\t"))
	print("Canonical service furniture: %d checks, %d failures, %d captures, %d actual physics ticks." % [checks, failures.size(), captures.size(), ticks])
	quit(0 if failures.is_empty() else 1)
