extends SceneTree
## Real decorative family admission/factory/editor/input. No worker or saves.
const FIXTURE := preload("res://tools/passive_furniture_fixture.gd")
const PROFILES := preload("res://tools/passive_furniture_profiles.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/passive-furniture"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var hashes: Dictionary[String, String] = {}
var route_samples: Array[Dictionary] = []
var ticks := 0
var motion := false

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count := 2) -> void:
	for index: int in range(count): await process_frame

func freeze() -> void:
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor.set_physics_process(false)

func click(point: Vector2) -> void:
	var hover := InputEventMouseMotion.new()
	hover.position = point
	hover.global_position = point
	root.push_input(hover, true)
	await frames(2)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func key(code: Key, target: Viewport = null) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		(root if target == null else target).push_input(event, true)
		await process_frame
	await frames()

func capture(name_value: String, prop_id := "") -> void:
	if DisplayServer.get_name() == "headless": return
	fixture.place_editor_labels()
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), name_value + " native viewport")
	# Containers may retain extra blank Label allocation after popup relayout.
	# Bound actual text lines against the paper instead of that empty rectangle.
	var status: Label = fixture.editor._status
	var paper := fixture.editor._inspector.get_parent() as Control
	var text_bottom := status.get_global_rect().position.y + status.get_line_height() * status.get_line_count()
	check(status.get_line_count() <= 2 and text_bottom <= minf(paper.get_global_rect().end.y - 4, 716), name_value + " actual dev status lines fit paper")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	hashes[name_value] = PIXELS.digest(PIXELS.rgba(image).get_data())
	if not prop_id.is_empty():
		var placement: Dictionary = fixture.main.room.placement_by_id(prop_id)
		var bounds: Rect2 = placement.world_visual_bounds
		if name_value.begins_with("dev-"):
			var first: Dictionary = placement.render_layers[0]
			var size := Vector2i(OfficeLayout.rectangle(first.region).size)
			var whole := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			for layer: Dictionary in placement.render_layers:
				var source := PIXELS.rgba((load(layer.art) as Texture2D).get_image())
				whole.blend_rect(source, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
			var origin := Vector2i(placement.anchor) + OfficeLayout.vector(first.offset) - size / 2
			var mismatches := 0
			var opaque := 0
			for y: int in range(size.y):
				for x: int in range(size.x):
					var expected := whole.get_pixel(x, y)
					if expected.a < 0.99: continue
					var actual := image.get_pixelv(origin + Vector2i(x, y))
					if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatches += 1
					opaque += 1
			check(opaque > 0 and mismatches == 0, name_value + " actual room matches source layer union; opaque%d mismatches%d" % [opaque, mismatches])
		var crop := image.get_region(Rect2i(Vector2i(bounds.position) - Vector2i(24, 24), Vector2i(bounds.size) + Vector2i(48, 48)))
		crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
		check(crop.save_png(OUTPUT.path_join(name_value + "-4x.png")) == OK, "Save native4× " + name_value)
		captures.append(name_value + "-4x.png")

func contracts() -> void:
	var model: OfficeLayout = fixture.model
	check(TownRoom.PROP_SCENES.size() == 7, "Original seven PackedScene families preserved")
	for kind: String in PROFILES.FAMILIES:
		var clean: Dictionary = model.catalog[kind].duplicate(true)
		check(not TownRoom.PROP_SCENES.has(kind), "Passive family uses only validated generic factory: " + kind)
		for side: String in OfficeLayout.FACINGS:
			var resolution := model.resolve_profile(kind, side)
			check(resolution.errors.is_empty(), kind + "/" + side + " admitted exact native profile")
			check(not resolution.profile.review.art and not resolution.profile.review.geometry, "Admission never invents approval")
			var p := model.resolve({"id": "probe", "kind": kind, "grid": [22, 15], "facing": side})
			for field: String in OfficeLayout.SEATED_FIELDS + ["interaction", "work_position", "service_side", "approach_gaze", "action"]:
				check(not p.has(field) and not p.profile.has(field), kind + "/" + side + " absent " + field)
			for layer: Dictionary in p.render_layers:
				var source := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(layer.art)))
				var imported := PIXELS.rgba((load(layer.art) as Texture2D).get_image())
				check(source.get_data() == imported.get_data(), layer.art + " decoded import exact including transparent RGB")
				check(layer.offset == [0, -48] if kind == "mobile_whiteboard" else layer.offset == [0, -24], "Fixed padded origin")
		for required: String in OfficeLayout.DECORATIVE_FIELDS:
			model.catalog[kind] = clean.duplicate(true)
			model.catalog[kind].facing_profiles.north.erase(required)
			check(not model.authorize_calibration_decorative_profile(kind, "north", fixture), "Missing explicit passive field rejected: " + required)
			check(not model.resolve_profile(kind, "north").errors.is_empty(), "Prior permit invalid after missing field")
		var mutations: Array[Dictionary] = [
			{"key": "profile_kind", "value": "unknown"}, {"key": "occupied", "value": []},
			{"key": "occupied", "value": [[0, 0], [0, 0]]}, {"key": "clearance", "value": [[0, 0]]},
			{"key": "clearance", "value": [[0, -1], [0, -1]]}, {"key": "anchor_offset", "value": [0.5, 0]},
			{"key": "review", "value": {"art": "yes", "geometry": false}},
			{"key": "review", "value": {"art": false, "geometry": false, "poses": true}},
			{"key": "render_layers", "value": []}, {"key": "standing_viewpoints", "value": "none"},
			{"key": "standing_viewpoints", "value": [{"cell": [0, -1]}]},
			{"key": "standing_viewpoints", "value": [{"cell": [0, -1], "visual_bounds": [-24, -71, 48, 79]}]},
			{"key": "standing_viewpoints", "value": [{"cell": [0, -1], "visual_bounds": [-24, -72, 48, 80], "gaze": "south"}]},
			{"key": "standing_viewpoints", "value": [{"cell": [0, -2], "visual_bounds": [-24, -72, 48, 80]}]},
		]
		for forbidden: String in OfficeLayout.SEATED_FIELDS + ["interaction", "work_position", "service_side", "approach_gaze", "approach_visual_bounds", "action", "actions", "interaction_action"]:
			mutations.append({"key": forbidden, "value": [0, 0]})
		for mutation: Dictionary in mutations:
			model.catalog[kind] = clean.duplicate(true)
			model.catalog[kind].facing_profiles.north[mutation.key] = mutation.value
			check(not model.authorize_calibration_decorative_profile(kind, "north", fixture), "Malformed passive contract rejected " + str(mutation.key))
			check(not model.resolve_profile(kind, "north").errors.is_empty(), "Exact candidate mutation invalidates former permit " + str(mutation.key))
		for field: String in ["art", "offset", "region", "scale", "flip_h"]:
			model.catalog[kind] = clean.duplicate(true)
			model.catalog[kind].facing_profiles.north.render_layers[0][field] = {"art": "res://missing.png", "offset": [0.5, 0], "region": [0, 0, 9999, 9999], "scale": [2, 2], "flip_h": true}[field]
			check(not model.authorize_calibration_decorative_profile(kind, "north", fixture), "Malformed raster transform rejected: " + field)
		model.catalog[kind] = clean.duplicate(true)
		model.catalog[kind].facing_profiles.north.standing_viewpoints = []
		check(model.authorize_calibration_decorative_profile(kind, "north", fixture), "Optional viewing geometry may be absent with no target synthesized")
		model.catalog[kind] = clean.duplicate(true)
		for side: String in OfficeLayout.FACINGS: check(model.authorize_calibration_decorative_profile(kind, side, fixture), "Restore exact reviewed-source candidate")
	var other := Node.new()
	root.add_child(other)
	check(not model.authorize_calibration_decorative_profile("mobile_whiteboard", "north", other), "Other live owner cannot borrow local permit")
	model.disable_calibration_preview(other)
	check(model.resolve_profile("mobile_whiteboard", "north").errors.is_empty(), "Wrong owner cannot revoke local permit")
	var copied := OfficeLayout.new()
	copied.configure(model.data, model.catalog)
	check(copied.enable_calibration_preview(other), "Independent model live owner accepted")
	check(not copied.resolve_profile("mobile_whiteboard", "north").errors.is_empty(), "Copying definitions never copies permit")
	check(not copied.authorize_calibration_decorative_profile("mobile_whiteboard", "north", fixture), "Cross-model owner rejected")
	check(copied.authorize_calibration_decorative_profile("mobile_whiteboard", "north", other), "Own explicit permit works")
	other.free()
	check(not copied.resolve_profile("mobile_whiteboard", "north").errors.is_empty(), "Owner death closes admission")
	var registered := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(PROFILES.PLANNING)))
	var original := PIXELS.rgba(Image.load_from_file("res://tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png"))
	check(registered.get_region(Rect2i(56, 86, 80, 48)).get_data() == original.get_data(), "Planning registration preserves every source pixel")
	check(registered.get_used_rect() == Rect2i(56, 86, 80, 48), "Planning export adds only transparent padding")
	var isolated := model.data.duplicate(true)
	isolated.props = [{"id": "probe", "kind": "rolling_storage_pedestal", "grid": [2, 5], "facing": "north", "required_hires": 0}]
	var geometry := OfficeLayout.new()
	geometry.configure(isolated, model.catalog)
	geometry.enable_calibration_preview(fixture)
	geometry.authorize_calibration_decorative_profile("rolling_storage_pedestal", "north", fixture)
	var headroom := geometry.validate_placements(geometry.resolve_placements(0))
	check(not headroom.valid and headroom.issues.any(func(issue: Dictionary) -> bool: return issue.code == "decorative_headroom"), "Pedestal body fits but native standing viewpoint rejects architecture")
	check(not headroom.issues.any(func(issue: Dictionary) -> bool: return issue.code == "visual_wall_intersection"), "Viewpoint protection is separate from art bounds")
	check(geometry.validate_candidate("probe", Vector2i(2, 6), "north", 0).valid, "One inward row supplies genuine standing headroom")
	var flat: Dictionary = model.catalog.rolling_storage_pedestal.facing_profiles.south.duplicate(true)
	flat.facings = ["south"]
	geometry.catalog.rolling_storage_pedestal = flat
	check(not geometry.resolve_profile("rolling_storage_pedestal", "south").errors.is_empty(), "Flat decorative legacy shape cannot bypass explicit-profile gates")
	check(not model.resolve_profile("invented_family", "south").errors.is_empty(), "Unknown family cannot acquire generic render fallback")
	geometry.configure(isolated, model.catalog)
	check(not geometry.resolve_profile("rolling_storage_pedestal", "north").errors.is_empty(), "Reconfigure clears exact local candidate permit")

func check_render_contract(id: String) -> void:
	var room: TownRoom = fixture.main.room
	var p := room.placement_by_id(id)
	var prop := room.prop_node(id)
	check(prop != null and prop.get_script() == null, id + " neutral native-layer factory, not an aliased service scene")
	if prop == null: return
	check(not room.interaction_world_position(id).is_finite(), id + " no callable fake interaction coordinate")
	check(room._workstation_visual(id).is_empty(), id + " no workstation pose attachment")
	check(prop.position == p.anchor and prop.z_index == int(p.anchor.y), id + " physical floor sort pivot")
	for layer: Dictionary in p.render_layers:
		var sprite := prop.get_node(str(layer.name)) as Sprite2D
		check(sprite != null and sprite.position == Vector2(OfficeLayout.vector(layer.offset)), id + " native registered layer offset")
		check(sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, id + " never rotates/scales raster")
		check(sprite.region_rect == OfficeLayout.rectangle(layer.region), id + " canonical atlas region")
	for cell: Vector2i in p.occupied: check(not room.navigation.walkable(cell), id + " native occupied cell blocks AStar")
	var collision := prop.get_node("PlacementCollision") as StaticBody2D
	check(collision != null and collision.get_child_count() == p.occupied.size(), id + " real per-cell body collision")
	var picked := false
	for layer: Dictionary in p.render_layers:
		var sprite := prop.get_node(str(layer.name)) as Sprite2D
		var bounds := OfficeLayout.measured_layer_ink_bounds(layer)
		if not bounds.has_area(): continue
		var texture := PIXELS.rgba((sprite.texture as Texture2D).get_image())
		for y: int in range(int(bounds.position.y), int(bounds.end.y)):
			for x: int in range(int(bounds.position.x), int(bounds.end.x)):
				if texture.get_pixel(x, y).a < 0.99: continue
				var point := sprite.global_position - sprite.region_rect.size / 2 + Vector2(x + 0.5, y + 0.5)
				var hit := room.surface_at(point)
				if hit.sprite == null: continue
				if (hit.sprite as Node).get_parent() != prop: continue
				check(hit.interaction.is_empty(), id + " actual painted foreground hit exposes no action")
				picked = true
				break
			if picked: break
		if picked: break
	check(picked, id + " real alpha-aware surface picking finds passive art")

func walk(label_value: String) -> void:
	var player: PlayerAvatar = fixture.main.player
	var start := player.position
	var positions: Array[Vector2] = [start]
	var cursor := start
	var length := 0.0
	for point: Vector2 in player.route:
		length += cursor.distance_to(point)
		cursor = point
	var traveled := 0.0
	var middle_captured := false
	await capture(label_value + "-start")
	for index: int in range(900):
		var before := player.position
		player._physics_process(1.0 / 30.0)
		check(player.navigation.position_is_safe(player.position, "founder"), label_value + " safe physical feet")
		ticks += 1
		traveled += before.distance_to(player.position)
		if not middle_captured and traveled >= length * 0.5:
			await capture(label_value + "-middle")
			positions.append(player.position)
			middle_captured = true
		if motion: await process_frame
		if player.route.is_empty(): break
	check(player.route.is_empty() and start.distance_to(player.position) > 32, label_value + " actual input route completes with movement")
	await capture(label_value + "-end")
	positions.append(player.position)
	check(positions.size() == 3 and positions[0].distance_to(positions[1]) > 10 and positions[1].distance_to(positions[2]) > 10, label_value + " start/middle/end are distinct actual physical positions")
	route_samples.append({"name": label_value, "positions": positions.map(func(p: Vector2) -> Array: return [p.x, p.y]), "ticks": ticks})
	if DisplayServer.get_name() != "headless": check(hashes.get(label_value + "-start") != hashes.get(label_value + "-end") and hashes.get(label_value + "-middle") != hashes.get(label_value + "-start") and hashes.get(label_value + "-middle") != hashes.get(label_value + "-end"), label_value + " distinct rendered motion samples")

func occlusion() -> void:
	var main: GameMain = fixture.main
	var room: TownRoom = main.room
	var p := room.placement_by_id("dev-whiteboard")
	var actor: EmployeeAvatar = main.get_employee("mira")
	var before := actor.position
	actor.position = fixture.model.world(p.grid + Vector2i(0, -1))
	actor.z_index = int(actor.position.y)
	actor.labels_suppressed = true
	room.navigation.actors.mira = actor.position
	var overlap := Vector2(INF, INF)
	var bounds: Rect2 = p.world_visual_bounds
	for y: int in range(int(bounds.position.y), int(bounds.end.y)):
		for x: int in range(int(bounds.position.x), int(bounds.end.x)):
			var point := Vector2(x + 0.5, y + 0.5)
			var body := actor.body_surface_at(point)
			var surface := room.surface_at(point)
			if body == null or surface.sprite == null: continue
			if (surface.sprite as Node).get_parent() != room.prop_node("dev-whiteboard"): continue
			if not VisibleSurface.in_front(surface.sprite, body): continue
			overlap = point
			break
		if overlap.is_finite(): break
	check(overlap.is_finite(), "Actual Mina opaque body pixel lies behind actual whiteboard art")
	if overlap.is_finite():
		check(main._interaction_at(overlap).is_empty(), "Passive foreground never selects an employee through paint")
		await click(overlap)
		check(main._pending_interaction.is_empty() and not main.job_panel.drawer_is_open(), "Real occluded click creates no employee/chat action")
		main.player.cancel_route()
		await capture("passive-occludes-employee", "dev-whiteboard")
	actor.position = before
	actor.z_index = int(before.y)
	actor.labels_suppressed = false
	room.navigation.actors.mira = before
	var archive := room.prop_node("artifact-archive")
	var service_hit := false
	var archive_bounds: Rect2 = room.placement_by_id("artifact-archive").world_visual_bounds
	for y: int in range(int(archive_bounds.position.y), int(archive_bounds.end.y)):
		for x: int in range(int(archive_bounds.position.x), int(archive_bounds.end.x)):
			var surface := room.surface_at(Vector2(x + 0.5, y + 0.5))
			if surface.sprite != null and (surface.sprite as Node).get_parent() == archive and not surface.interaction.is_empty(): service_hit = true; break
		if service_hit: break
	check(service_hit, "Existing approved archive still exposes its real service hit")

func actual_input() -> void:
	var editor: Node2D = fixture.editor
	var room: TownRoom = fixture.main.room
	for id: String in ["dev-whiteboard", "dev-pedestal"]:
		var before_picker: Vector2 = fixture.main.player.position
		var index_to_select := -1
		for item: int in range(editor._prop_picker.item_count):
			if str(editor._prop_picker.get_item_metadata(item)) == id: index_to_select = item
		check(index_to_select >= 0, "Real editor picker contains " + id)
		await click(editor._prop_picker.get_global_rect().get_center())
		var popup: PopupMenu = editor._prop_picker.get_popup()
		if not popup.visible: await key(KEY_SPACE)
		check(popup.visible, "Actual pointer focus and keyboard opens native picker popup")
		for item: int in range(editor._prop_picker.item_count + 1):
			if popup.get_focused_item() == index_to_select: break
			await key(KEY_DOWN)
		check(popup.get_focused_item() == index_to_select, "Real arrow keys focus desired native popup item")
		await key(KEY_ENTER)
		check(not popup.visible, "Native popup selection closes after Enter")
		check(editor.selected_id == id, "Real mouse/keyboard dropdown selection chooses " + id)
		check(fixture.main.player.position == before_picker and fixture.main.player.route.is_empty(), "Editor dropdown input does not leak into world movement")
		if root.gui_get_focus_owner() != null: root.gui_get_focus_owner().release_focus()
		check(editor._facing_picker.item_count == 4, id + " actual facing picker lists all admitted directions")
		for index: int in range(4):
			await key(KEY_R)
			check(editor.placement_active and editor.preview_result.valid, id + " R creates validated ghost")
			var ghost: Dictionary = editor._candidate
			check(ghost.render_layers == room.layout_model.resolve_profile(str(ghost.kind), str(ghost.facing)).profile.render_layers, "Ghost uses same native source recipes")
			await click(room.global_position + fixture.model.world(editor.preview_grid))
			freeze()
			check(not editor.placement_active and str(room.placement_by_id(id).facing) == str(ghost.facing), id + " actual mouse commits R-facing")
			check_render_contract(id)
			await capture(id + "-" + str(ghost.facing), id)
	var saved := room.placement_overrides.duplicate(true)
	var founder_position: Vector2 = fixture.main.player.position
	editor.select_placement("dev-whiteboard")
	await key(KEY_M)
	await click(fixture.model.world(Vector2i(1, 3)))
	check(editor.placement_active and not editor.preview_result.valid and room.placement_overrides == saved, "Real wall click rejects transaction unchanged")
	await capture("invalid-wall")
	await key(KEY_ESCAPE)
	freeze()
	check(not editor.placement_active and room.prop_node("dev-whiteboard").visible, "Escape restores committed art, no ghost or rollback loss")
	# Founder physically occupies only a newly introduced vertical cell on rotation.
	var board: Dictionary = room.placement_by_id("dev-whiteboard")
	fixture.main.player.position = fixture.model.world(board.grid + Vector2i(0, 1))
	room.navigation.actors.founder = fixture.main.player.position
	var occupied_foot: Vector2 = fixture.main.player.position
	await key(KEY_R)
	check(not editor.preview_result.valid and not room.placement_actor_conflicts(editor._with_candidate()).is_empty(), "R rejects live founder foot in newly blocked cell")
	await click(fixture.model.world(board.grid))
	check(room.placement_overrides == saved and fixture.main.player.position == occupied_foot, "Rejected occupied rotation never teleports actor or changes committed layout")
	await capture("occupied-rotation-rejected")
	await key(KEY_ESCAPE)
	fixture.main.player.position = founder_position
	room.navigation.actors.founder = founder_position
	freeze()
	var employee: EmployeeAvatar = fixture.main.get_employee("theo")
	var employee_before := employee.position
	employee.position = fixture.model.world(board.grid + Vector2i(0, 1))
	room.navigation.actors.theo = employee.position
	await key(KEY_R)
	await click(fixture.model.world(board.grid))
	check(editor.placement_active and room.placement_overrides == saved and employee.position == fixture.model.world(board.grid + Vector2i(0, 1)), "Other employee blocks rotation without teleport or partial commit")
	await key(KEY_ESCAPE)
	employee.position = employee_before
	room.navigation.actors.theo = employee_before
	freeze()
	await key(KEY_R)
	await click(fixture.model.world(board.grid))
	freeze()
	check(not editor.placement_active, "Same rotation accepted after actor leaves")
	await key(KEY_U)
	freeze()
	check(room.placement_overrides == saved, "Real Undo restores exact layout after safe rotation")
	check(not editor.export_layout("res://tests/output/should-not-exist.json"), "Calibration editor refuses export")
	await occlusion()
	# Click actual ground on far side of board; AStar must route around its footprint.
	fixture.main.player.input_blocked = false
	await click(fixture.model.world(Vector2i(24, 14)))
	check(not fixture.main.player.route.is_empty() and fixture.main._pending_interaction.is_empty(), "Actual ground click creates route, not a passive action")
	await walk("walk-around-whiteboard")
	check(not fixture.main.job_panel.drawer_is_open() and not fixture.main.company_panel.visible, "Passive vicinity does not open an interface")
	# A future route cell is not an occupied actor. The existing GameMain policy
	# safely cancels routes on layout rebuild; a new real click replans around it.
	await click(fixture.model.world(Vector2i(25, 18)))
	var route_before: PackedVector2Array = fixture.main.player.route.duplicate()
	var current_foot: Vector2 = fixture.main.player.position
	editor.select_placement("dev-pedestal")
	var intercept := Vector2i(-1, -1)
	for point: Vector2 in route_before:
		var cell: Vector2i = fixture.model.cell_at(point)
		if point.distance_to(current_foot) < 48: continue
		var proposed := room.placement_overrides.duplicate(true)
		proposed["dev-pedestal"] = {"grid": [cell.x, cell.y], "facing": "south"}
		if editor.validate_all_stages(proposed).valid and room.placement_actor_conflicts(proposed).is_empty(): intercept = cell; break
	check(intercept.x >= 0, "Actual future route has a legal furniture interception cell")
	await key(KEY_M)
	await click(fixture.model.world(intercept))
	freeze()
	check(not editor.placement_active and fixture.main.player.position == current_foot, "Route-only destination furniture change commits without actor relocation: " + str(editor.preview_result))
	check(not route_before.is_empty(), "Route-only replan started from actual click path")
	check(fixture.main.player.route.is_empty(), "Existing GameMain layout-change policy safely cancels stale founder route")
	fixture.main.player.input_blocked = false
	await click(fixture.model.world(Vector2i(25, 18)))
	check(not fixture.main.player.route.is_empty(), "New ground click plans around newly blocked pedestal cell")
	await walk("replanned-around-pedestal")

func run() -> void:
	root.gui_embed_subwindows = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	motion = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames(3)
	check(fixture.ready_ok, "Disposable passive fixture ready: " + str(fixture.errors))
	if not fixture.ready_ok: fixture.queue_free(); await frames(); quit(1); return
	freeze()
	check(not fixture.main._state_loaded and not fixture.main._worker_ready, "No personal bootstrap or live worker state")
	contracts()
	for stage: int in range(5):
		check(fixture.model.validate_placements(fixture.model.resolve_placements(stage)).valid, "Stage%d passive additions keep ordinary geometry valid" % stage)
		var records: Array[EmployeeRecord] = fixture.main.room.placeholder_records()
		records.resize(mini(stage, 2))
		fixture.main._spawn_employees(records)
		fixture.main.room.set_hire_count(stage)
		freeze()
		await capture("office-stage-" + str(stage))
	fixture.main._spawn_employees(fixture.main.room.placeholder_records())
	fixture.main.room.set_hire_count(2)
	freeze()
	fixture.editor._refresh_placements()
	await actual_input()
	check(not fixture.main.worker_client.blocked_requests.has("game.save") and not fixture.main.worker_client.blocked_requests.has("job.start"), "No save or work request attempted")
	var previous: OfficeLayout = fixture.model
	fixture.queue_free()
	await frames(3)
	check(not previous.calibration_preview_enabled() and not previous.resolve_profile("mobile_whiteboard", "north").errors.is_empty(), "Teardown removes exact model permits")
	var ordinary := preload("res://tools/archive_production_fixture.gd").new()
	root.add_child(ordinary)
	await frames(3)
	check(ordinary.ready_ok and ordinary.main.room.layout_model.catalog.has("mobile_whiteboard"), "Mobile whiteboard is registered in the ordinary production catalogue")
	check(ordinary.main.room.prop_node("dev-whiteboard") == null and ordinary.main.room.prop_node("dev-pedestal") == null, "No generic prop/node leakage")
	ordinary.queue_free()
	await frames(3)
	var report := {"checks": checks, "failures": failures, "captures": captures, "hashes": hashes, "routes": route_samples,
		"ticks": ticks, "runtime_approved": false, "limitations": ["Dev candidates only; no gameplay use action.", "Native visual review remains separate from geometry assertions."]}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json" if motion else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("Passive furniture: %d checks / %d failures / %d captures" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
