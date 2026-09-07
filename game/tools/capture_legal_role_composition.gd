extends SceneTree
## Actual GameMain render and provider-free structural tests. Findings about
## placement/art are separate from invariant failures; no auto art approval.
const FIXTURE := preload("res://tools/legal_role_fixture.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/legal-role-composition"
var checks := 0
var failures: Array[String] = []
var findings: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var captures: Array[String] = []
var source_hashes: Dictionary = {}
var images: Dictionary = {}
var placement_advice: Dictionary = {}
var rendered := false
var motion_frames := 0
var corrected := false
var output_dir := OUTPUT

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func finding(id: String, detail: String, data: Dictionary = {}) -> void:
	for previous: Dictionary in findings:
		if previous.id == id:
			return
	findings.append({"id": id, "detail": detail, "measurements": data, "runtime_approval": false})

func source(path: String) -> Image:
	if not images.has(path):
		var value := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(value != null and not value.is_empty(), "Read existing native source " + path)
		value.convert(Image.FORMAT_RGBA8)
		images[path] = value
		source_hashes[path] = FileAccess.get_sha256(path)
	return images[path]

func overlap(left: Image, left_origin: Vector2i, right: Image, right_origin: Vector2i) -> int:
	var count := 0
	var intersection := Rect2i(left_origin, left.get_size()).intersection(Rect2i(right_origin, right.get_size()))
	for y: int in range(intersection.position.y, intersection.end.y):
		for x: int in range(intersection.position.x, intersection.end.x):
			var point := Vector2i(x, y)
			if left.get_pixelv(point - left_origin).a > 0.5 and right.get_pixelv(point - right_origin).a > 0.5:
				count += 1
	return count

func image_part(value: Image, displacement: Vector2i = Vector2i.ZERO) -> Dictionary:
	var bounds := value.get_used_rect()
	return {"image": value.get_region(bounds), "position": bounds.position + displacement}

func separated(left: Dictionary, right: Dictionary) -> bool:
	# One empty native pixel between unrelated flat objects, not just zero overlap.
	for y: int in range(-1, 2):
		for x: int in range(-1, 2):
			if overlap(left.image, left.position + Vector2i(x, y), right.image, right.position) > 0:
				return false
	return true

func advise_north(owner: Node, safe: Rect2i) -> void:
	var parts: Dictionary = {}
	for part: String in FIXTURE.PARTS:
		parts[part] = image_part(source(FIXTURE.kit_path("north", part)))
	for entry: Dictionary in owner.profile("north").render_layers:
		if str(entry.name) in ["Mouse", "Keyboard", "Monitor"]:
			parts[str(entry.name)] = image_part(source(str(entry.art)), OfficeLayout.vector(entry.offset) + Vector2i(0, 48))
	var best: Dictionary = {}
	var best_cost := 999
	for folder_x: int in range(-2, 3):
		for folder_y: int in range(-4, 5):
			var folder: Dictionary = parts.folder.duplicate()
			folder.position += Vector2i(folder_x, folder_y)
			if not safe.encloses(Rect2i(folder.position, folder.image.get_size())):
				continue
			if not separated(folder, parts.Keyboard) or not separated(folder, parts.Monitor):
				continue
			for mouse_x: int in range(-6, 7):
				for mouse_y: int in range(-5, 6):
					var cost := absi(folder_x) + absi(folder_y) + absi(mouse_x) + absi(mouse_y)
					if cost >= best_cost:
						continue
					var mouse: Dictionary = parts.Mouse.duplicate()
					mouse.position += Vector2i(mouse_x, mouse_y)
					if not safe.encloses(Rect2i(mouse.position, mouse.image.get_size())):
						continue
					var clear := separated(mouse, folder)
					for fixed: String in ["binders", "pen_cup", "Keyboard", "Monitor"]:
						clear = clear and separated(mouse, parts[fixed]) and separated(folder, parts[fixed])
					if clear:
						best_cost = cost
						best = {"folder_translation": [folder_x, folder_y], "mouse_translation": [mouse_x, mouse_y], "manhattan_displacement": cost, "folder_bounds": PIXELS.rect_values(Rect2i(folder.position, folder.image.get_size())), "mouse_bounds": PIXELS.rect_values(Rect2i(mouse.position, mouse.image.get_size())), "scope": "Minimum within the stated local search box, not an ergonomic or native visual approval. One empty opaque pixel checked against other static objects. Actors not moved or re-rendered."}
	placement_advice.north = best

func preflight(direction: String, owner: Node) -> void:
	var whole := source(FIXTURE.kit_path(direction))
	var reconstructed := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	reconstructed.fill(Color(0, 0, 0, 0))
	var p: Dictionary = owner.profile(direction)
	var safe: Rect2i = DESK.profile(direction).top.grow(-2)
	safe.position += Vector2i(96, 160)
	var previous_parts: Array[String] = []
	for part: String in FIXTURE.PARTS:
		var value := source(FIXTURE.kit_path(direction, part))
		check(value.get_size() == Vector2i(192, 224), direction + " " + part + " remains full registered192x224")
		var alpha := PIXELS.analyze(value)
		check(alpha.partial_alpha_pixels == 0, direction + " " + part + " clean binary alpha")
		if alpha.hidden_rgb_pixels > 0:
			finding(direction + "-" + part + "-hidden-rgb", "Transparent source padding retains invisible RGB. Alpha is binary, so this is normalization bookkeeping, not an opaque background or observed matte.", {"hidden_rgb_pixels": alpha.hidden_rgb_pixels})
		var contact: Rect2i = FIXTURE.KIT[direction].contacts[part]
		var shift := FIXTURE.part_shift(direction, part, corrected)
		contact.position += shift
		if corrected: check(safe.encloses(contact), direction + " corrected role contact stays inside real wood: " + part)
		if not safe.encloses(contact):
			finding(direction + "-" + part + "-rim", "Proposed contact extends outside the actual two-pixel-inset wood; padding/outer tabletop is not valid support.", {"contact": PIXELS.rect_values(contact), "wood": PIXELS.rect_values(safe)})
		for previous: String in previous_parts:
			check(overlap(value, Vector2i.ZERO, source(FIXTURE.kit_path(direction, previous)), Vector2i.ZERO) == 0, direction + " original role component silhouettes do not overlap")
		previous_parts.append(part)
		reconstructed = PIXELS.binary_over(reconstructed, value)
		for entry: Dictionary in p.render_layers:
			if str(entry.name) not in ["Keyboard", "Mouse", "Monitor"]:
				continue
			var device := source(str(entry.art))
			var displacement := OfficeLayout.vector(entry.offset) + Vector2i(0, 48)
			var count := overlap(value, shift, device, displacement)
			if corrected: check(count == 0, direction + " corrected role/device opaque clearance: " + part + "/" + str(entry.name))
			if count > 0:
				finding(direction + "-" + part + "-" + str(entry.name).to_lower(), "Actual opaque role/device pixels overlap before any actor is added.", {"pixels": count, "part": part, "device": entry.name})
			if str(entry.name) == "Mouse":
				var mouse_bound := device.get_used_rect()
				mouse_bound.position += displacement
				if corrected: check(safe.encloses(mouse_bound), direction + " corrected flat mouse is fully on real wood")
				if not safe.encloses(mouse_bound):
					finding(direction + "-mouse-rim", "Flat mouse silhouette touches or exceeds the actual wood interior.", {"bounds": PIXELS.rect_values(mouse_bound), "wood": PIXELS.rect_values(safe)})
	check(reconstructed.get_data() == whole.get_data(), direction + " complete role union reconstructs every RGBA byte")
	check(p.status == "calibration_candidate" and not p.review.art and not p.review.geometry and not p.review.poses, direction + " real profile stays explicitly unapproved")
	if direction == "south":
		check(source(FIXTURE.kit_path(direction, "binders")).get_used_rect().position.y == 106, "South retains final binderY106")
	if direction == "west":
		finding("west-identity", "Reclassified source has W-like checklist-top leaves and near binder spines, but outer tabs still point right, page marks stay screen-upright, pen order remains unproven, and binder is12x32 not12x30.")
	if direction == "north" and not corrected:
		advise_north(owner, safe)

func advance_actor(actor: EmployeeAvatar) -> void:
	for tick: int in range(600):
		actor._physics_process(1.0 / 30.0)
		check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Actual employee route stays on traversable ground")
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active:
			break
	check(not actor._has_target and not actor._seat_transition_active and actor.position == actor.desk_position, "Actual path and seat transition settle at the physical workstation")

func set_frame(actor: EmployeeAvatar, direction: String, frame: int) -> Dictionary:
	var pose := "seated" if frame < 2 else "typing"
	var phase := frame if frame < 2 else frame - 2
	actor.work_state = EmployeeAvatar.WorkState.SITTING if frame < 2 else EmployeeAvatar.WorkState.TYPING
	actor._animation_elapsed = (phase + 0.01) / (1.5 if frame < 2 else 8.0)
	actor._update_character_frame()
	var authored := CharacterArt.work_pose_frame(actor.employee_id, actor._workstation_visual.pose_set, direction, pose, phase)
	check(not authored.is_empty(), "Actual scoped pose registry resolves " + direction + " " + str(frame))
	check(actor._character_sprite.region_rect == authored.region, "Actor uses exact requested authored frame")
	var atlas: Image = authored.texture.get_image()
	var original := atlas.get_region(Rect2i(authored.region))
	if authored.has("layers"):
		var reconstruction := Image.create(48, 80, false, Image.FORMAT_RGBA8)
		for part: Dictionary in authored.layers:
			var live: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
			check(live.visible and live.region_rect == part.region and live.texture == authored.texture, "Live split uses exact owned source region")
			check(live.position == live.position.round() and live.scale == Vector2.ONE and live.rotation == 0.0, "Live body layer stays native")
			reconstruction.blit_rect(atlas, Rect2i(part.region), Vector2i(part.offset))
		check(reconstruction.get_data() == original.get_data(), "Body upper/lower union reconstructs source bytes")
	else:
		check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "North uses original whole body")
	check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Canonical seated depth lock remains intact")
	return authored

func measure_actor(actor: EmployeeAvatar, direction: String, frame: int, authored: Dictionary) -> void:
	var atlas: Image = authored.texture.get_image()
	var body := atlas.get_region(Rect2i(authored.region))
	var origin := Vector2i(actor.render_position() - Vector2(actor._workstation_visual.prop_anchor)) - Vector2i(24, 72) + Vector2i(96, 160)
	var counts: Dictionary = {}
	var layer_counts: Dictionary = {}
	for part: String in FIXTURE.PARTS:
		var shift := FIXTURE.part_shift(direction, part, corrected)
		var count := overlap(source(FIXTURE.kit_path(direction, part)), shift, body, origin)
		counts[part] = count
		var by_layer: Dictionary = {}
		for body_layer: Dictionary in authored.get("layers", []):
			var fragment := atlas.get_region(Rect2i(body_layer.region))
			by_layer[str(body_layer.name)] = overlap(source(FIXTURE.kit_path(direction, part)), shift, fragment, origin + Vector2i(body_layer.offset))
		if corrected:
			check(int(by_layer.get("upper", count if direction == "north" else 0)) == 0, direction + " corrected decoration clears essential actor source")
		layer_counts[part] = by_layer
		if count > 0:
			finding(direction + "-" + actor.employee_id + "-" + part + "-actor-projection", "Role decoration projects onto actor source pixels; actual layered capture must distinguish intended occlusion from hand/face collision.", {"first_frame": frame, "pixels": count})
	observations.append({"direction": direction, "employee": actor.employee_id, "frame": frame, "render_origin_on_192x224": [origin.x, origin.y], "actor_role_opaque_overlaps": counts, "actor_role_overlap_by_source_layer": layer_counts, "physical_position": [actor.position.x, actor.position.y], "render_offset": [actor.seated_render_offset().x, actor.seated_render_offset().y], "depth": actor.z_index})

func save_capture(owner: Node, direction: String, frame: int) -> void:
	if not rendered:
		return
	for tick: int in range(3):
		await process_frame
		motion_frames += 1
	RenderingServer.force_draw(false)
	var shot := root.get_texture().get_image()
	check(shot.get_size() == Vector2i(1280, 720), "Actual GameMain stays native1280x720")
	var name_value := "%s-frame%d.png" % [direction, frame]
	check(not owner.main.job_panel._connection_panel.visible and not owner.main.job_panel.drawer_is_open(), "No onboarding/drawer overlay contaminates role evidence")
	check(shot.save_png(output_dir.path_join(name_value)) == OK, "Save " + name_value)
	captures.append(name_value)
	for id: String in ["mira", "theo"]:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var pivot := Vector2i(actor._workstation_visual.prop_anchor)
		var crop := shot.get_region(Rect2i(pivot + Vector2i(-80, -112), Vector2i(160, 176)))
		crop.resize(640, 704, Image.INTERPOLATE_NEAREST)
		var detail := "%s-%s-frame%d-4x.png" % [direction, id, frame]
		check(crop.save_png(output_dir.path_join(detail)) == OK, "Save " + detail)
		captures.append(detail)

func run_direction(direction: String) -> bool:
	var owner := FIXTURE.new()
	owner.use_corrected_clearance = corrected
	owner.employee_ids.assign(["mira", "theo"])
	owner.initial_facing = direction
	root.add_child(owner)
	await process_frame
	check(owner.ready_ok, "Actual legal GameMain fixture validates " + direction + ": " + str(owner.errors))
	if not owner.ready_ok:
		owner.free()
		return false
	preflight(direction, owner)
	var main: GameMain = owner.main
	for tick: int in range(3): await process_frame
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.player.set_physics_process(false)
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
	for id: String in ["mira", "theo"]:
		owner.send_to_desk(id)
		advance_actor(main.get_employee(id))
	main.set_process(false)
	for actor: EmployeeAvatar in main._employees.values():
		actor._label_layer.hide()
		actor._effect_sprite.hide()
	# Keep normal team rail/HUD visible, but remove the dev placement toolbar.
	# This is a room composition screenshot, not an editor screenshot or paid job.
	for child: Node in owner.editor.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).hide()
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	owner.add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(136, 112)
	panel.custom_minimum_size = Vector2(880, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 4, 10, 4)))
	canvas.add_child(panel)
	var caption := Label.new()
	CozyUI.label(caption, "meta")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(caption)
	for frame: int in range(6):
		caption.text = "LEGAL DECOR · %s · frame%d · %s%s" % [direction.to_upper(), frame, "corrected resting clearance" if corrected else "original placement", " · W IDENTITY CLEANUP" if direction == "west" else " · no legal backend"]
		for actor: EmployeeAvatar in main._employees.values():
			var authored := set_frame(actor, direction, frame)
			measure_actor(actor, direction, frame, authored)
		await save_capture(owner, direction, frame)
	var worker := main.worker_client as FIXTURE.NullWorker
	check(worker != null, "Only NullWorker exists in actual GameMain fixture")
	check(not main._state_loaded and not main._worker_ready, "No real bootstrap or persistent state loaded")
	check(main.day_clock.speed == 0.0, "Clock remains deterministic")
	var registry_id: String = owner.pose_set_id
	owner.free()
	await process_frame
	check(not CharacterArt.is_calibration_pose_set(registry_id), "Fixture unregisters actual pose capability on teardown")
	return true

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	corrected = OS.get_cmdline_user_args().has("--clearance-corrected")
	if corrected: output_dir = OUTPUT.path_join("clearance-corrected")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	check(FIXTURE.kit_path("east").is_empty(), "No invented or mislabeled legal east toolkit")
	for direction: String in FIXTURE.LEGAL_DIRECTIONS:
		var captured_direction := await run_direction(direction)
		if rendered and captured_direction:
			var contact := Image.create(960, 352, false, Image.FORMAT_RGBA8)
			for frame: int in range(6):
				var full := Image.load_from_file(ProjectSettings.globalize_path(output_dir.path_join("%s-frame%d.png" % [direction, frame])))
				for employee: int in range(2):
					contact.blit_rect(full, Rect2i(256 + employee * 448, 160, 160, 176), Vector2i((frame % 3) * 320 + employee * 160, int(frame / 3) * 176))
			var sheet_name := direction + "-all-six-native.png"
			check(contact.save_png(output_dir.path_join(sheet_name)) == OK, "Save paired native all-six-frame contact " + direction)
			captures.append(sheet_name)
	for path: String in source_hashes:
		check(FileAccess.get_sha256(path) == source_hashes[path], "Source/export remains untouched: " + path)
	if corrected:
		for issue: Dictionary in findings:
			check(not str(issue.id).ends_with("-rim") and issue.id != "north-folder-mouse", "Corrected clearance finding is genuinely absent")
	var file := FileAccess.open(output_dir.path_join("manifest.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "findings": findings, "observations": observations, "placement_advice": placement_advice, "clearance_corrected": corrected, "corrections": {"north_folder": [0, -4], "south_mouse_additional": [0, 1], "south_cup": [0, -1]} if corrected else {}, "captures": captures, "scripted_frames": motion_frames, "source_sha256": source_hashes, "scene": "actual GameMain via scoped calibrated_workstation_fixture", "directions": FIXTURE.LEGAL_DIRECTIONS, "east_available": false, "worker_disabled": true, "save_access": false, "runtime_approved": false, "typing_frames": "Existing computer typing as scale/occlusion references only; no document or legal work happened."}, "\t"))
	print("Legal role composition: %d invariant checks, %d failures, %d art/placement findings, %d captures; not runtime approved." % [checks, failures.size(), findings.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
