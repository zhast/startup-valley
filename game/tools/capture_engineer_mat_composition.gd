extends SceneTree
## DEV ONLY. Same real GameMain path in both headless and native evidence.
const FIXTURE := preload("res://tools/engineer_mat_fixture.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/engineer-mat-composition"
const DIRECTIONS: Array[String] = ["north", "east", "south", "west"]
const IDS: Array[String] = ["mira", "theo"]
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var captures: Array[String] = []
var measurements: Dictionary = {}
var source_hashes: Dictionary = {}
var images: Dictionary = {}
var rendered := false
var frames := 0
var depth_pixels := 0
var shadow_blend_pixels := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func image_at(path: String) -> Image:
	if not images.has(path):
		var value := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(value != null and not value.is_empty(), "Read source " + path)
		value.convert(Image.FORMAT_RGBA8)
		images[path] = value
		source_hashes[path] = FileAccess.get_sha256(path)
	return images[path]

func preflight(owner: Node, facing: String) -> void:
	var mat := image_at(FIXTURE.mat_path(facing))
	var box := FIXTURE.mat_bounds(facing)
	var top: Rect2i = DESK.profile(facing).top
	var wood := top.grow(-2)
	var info := PIXELS.analyze(mat)
	check(mat.get_size() == box.size, facing + " native mat source is its actual physical size")
	check(info.opaque_pixels == 640 and info.transparent_pixels == 0 and info.partial_alpha_pixels == 0, facing + " intentionally opaque plate, not a recovered cutout")
	check(info.opaque_colors <= 24, facing + " frozen native palette limit")
	check(wood.grow(-2).encloses(box), facing + " at least two clear wood pixels inside actual rim")
	var profile: Dictionary = owner.profile(facing)
	var names: Array[String] = []
	for entry: Dictionary in profile.render_layers: names.append(str(entry.name))
	check("EngineerMat" in names and "Keyboard" not in names and "Mouse" not in names and "Monitor" not in names, facing + " no stacked electronics/computer props")
	check(not profile.review.art and not profile.review.geometry and not profile.review.poses, facing + " calibration never grants art approval")
	var source_path := "res://assets/source/overnight-20260904/roles/engineer-mat-" + str(FIXTURE.MATS[facing]) + ".png"
	var master := image_at(source_path)
	measurements[facing] = {"native": [mat.get_width(), mat.get_height()], "source_size": [master.get_width(), master.get_height()],
		"source_sha256": source_hashes[source_path], "native_sha256": source_hashes[FIXTURE.mat_path(facing)],
		"mat_bounds": PIXELS.rect_values(box), "top_bounds": PIXELS.rect_values(top), "wood_bounds": PIXELS.rect_values(wood),
		"wood_edge_gaps": [box.position.x - wood.position.x, box.position.y - wood.position.y, wood.end.x - box.end.x, wood.end.y - box.end.y],
		"palette": info.opaque_colors, "opaque_pixels": info.opaque_pixels, "geometry_only": true}
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var prop: Node2D = owner.main.room.prop_node(id + "-workstation")
		var live: Sprite2D = prop.get_node("EngineerMat")
		check(live.scale == Vector2.ONE and live.rotation == 0 and not live.flip_h and not live.flip_v, facing + " live plate has no rescale, rotation or mirror")
		check(live.region_rect == Rect2(Vector2.ZERO, Vector2(box.size)) and live.position == Vector2(box.position) + Vector2(box.size) * 0.5, facing + " actual renderer exact native mat registration")
		check(live.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, facing + " nearest pixel sampling")
		check(actor.desk_position == owner.main.room.employee_workstation_visual(id).work_position, facing + " role decor does not move physical work cell")
		check(actor.navigation.position_is_safe(actor.desk_position, actor.employee_id), facing + " physical work cell stays reachable")

func walk(actor: EmployeeAvatar, desk: bool) -> void:
	var arrived := false
	for tick: int in range(600):
		actor._physics_process(1.0 / 30.0)
		check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Real actor path stays on walkable ground")
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active:
			arrived = true
			break
	check(arrived, "Real path and source seat transition finish")
	check(actor.position == (actor.desk_position if desk else actor.home_position), "Logical feet end at requested unmodified destination")

func set_frame(actor: EmployeeAvatar, facing: String, frame: int) -> void:
	var pose := "seated" if frame < 2 else "typing"
	var phase := frame if frame < 2 else frame - 2
	actor.work_state = EmployeeAvatar.WorkState.SITTING if frame < 2 else EmployeeAvatar.WorkState.TYPING
	actor._animation_elapsed = (phase + 0.01) / (1.5 if frame < 2 else 8.0)
	actor._update_character_frame()
	actor._effect_sprite.hide()
	var authored := CharacterArt.work_pose_frame(actor.employee_id, actor._workstation_visual.pose_set, facing, pose, phase)
	check(not authored.is_empty() and actor._character_sprite.region_rect == authored.region, "Exact original authored pose frame")
	var atlas := PIXELS.rgba(authored.texture.get_image())
	var original := atlas.get_region(Rect2i(authored.region))
	if authored.has("layers"):
		var combined := Image.create(48, 80, false, Image.FORMAT_RGBA8)
		for part: Dictionary in authored.layers:
			var live: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
			check(live.visible and live.region_rect == part.region and live.texture == authored.texture, "Original layer region retained")
			check(live.scale == Vector2.ONE and live.rotation == 0 and live.global_position == live.global_position.round(), "Body layers use native integer pixels")
			combined.blit_rect(atlas, Rect2i(part.region), Vector2i(part.offset))
		check(combined.get_data() == original.get_data(), "Source union reconstructs unmodified body")
	else:
		check(actor._character_sprite.visible and actor._active_work_pose_layers.is_empty(), "North retains original whole seated body")
	check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Canonical pose depth lock unchanged")
	var mat_box := FIXTURE.mat_bounds(facing)
	var origin := Vector2i(actor.render_position() - Vector2(actor._workstation_visual.prop_anchor)) - Vector2i(24, 72)
	var body_overlap := 0
	var head_overlap := 0
	for y: int in range(80):
		for x: int in range(48):
			if original.get_pixel(x, y).a > 0.5 and mat_box.has_point(origin + Vector2i(x, y)):
				body_overlap += 1
				if y < 36: head_overlap += 1
	observations.append({"facing": facing, "employee": actor.employee_id, "frame": frame,
		"pose_semantics": "resting seated reference" if frame < 2 else "incompatible existing typing stress test; not probe use",
		"body_origin_from_desk": [origin.x, origin.y], "projected_body_mat_pixels": body_overlap,
		"projected_upper_36rows_mat_pixels": head_overlap, "head_region_is_conservative_inference": true})

func sprite_depth(sprite: Sprite2D) -> int:
	return sprite.z_index + (sprite.get_parent().z_index if sprite.z_as_relative and sprite.get_parent() is Node2D else 0)

func sprite_data(sprite: Sprite2D) -> Dictionary:
	var region := Rect2i(sprite.region_rect) if sprite.region_enabled else Rect2i(Vector2i.ZERO, Vector2i(sprite.texture.get_size()))
	var image := PIXELS.rgba(sprite.texture.get_image()).get_region(region)
	var origin := sprite.global_position + sprite.offset
	if sprite.centered: origin -= Vector2(region.size) * 0.5
	check(origin == origin.round(), "Actual layer origin stays pixel integral")
	return {"image": image, "origin": Vector2i(origin), "depth": sprite_depth(sprite)}

func verify_depth(owner: Node, screen: Image, facing: String, checkpoint: String) -> void:
	for id: String in IDS:
		var prop: Node2D = owner.main.room.prop_node(id + "-workstation")
		var mat_sprite: Sprite2D = prop.get_node("EngineerMat")
		var mat := sprite_data(mat_sprite)
		var occluders: Array[Dictionary] = []
		# Renderer uses explicit absolute depth. The mat is appended last among
		# equal-depth furniture layers; body follows room at equal depth.
		for child: Node in prop.get_children():
			if child is Sprite2D and child.visible and child != mat_sprite and child.z_index > mat.depth:
				occluders.append(sprite_data(child))
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var candidates: Array[Sprite2D] = [actor._shadow_sprite, actor._character_sprite]
		for part: Sprite2D in actor._work_pose_layer_sprites.values(): candidates.append(part)
		if actor.visible:
			for part: Sprite2D in candidates:
				if part.visible and sprite_depth(part) >= mat.depth:
					# Main body inherits the actor's absolute depth, unlike split
					# sprites which themselves have z_as_relative=false.
					var fragment := sprite_data(part)
					fragment.shadow = part == actor._shadow_sprite
					occluders.append(fragment)
		occluders.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.depth) < int(right.depth))
		var mismatch := 0
		var visible_mat := 0
		var visible_shadow := 0
		for y: int in range(mat.image.get_height()):
			for x: int in range(mat.image.get_width()):
				var at: Vector2i = mat.origin + Vector2i(x, y)
				var expected: Color = mat.image.get_pixel(x, y)
				var covered := false
				var partial := false
				var final_shadow := false
				for fragment: Dictionary in occluders:
					var local: Vector2i = at - fragment.origin
					if Rect2i(Vector2i.ZERO, fragment.image.get_size()).has_point(local):
						var color: Color = fragment.image.get_pixelv(local)
						if color.a > 0.0:
							expected = expected.blend(color)
							covered = true
							partial = color.a < 1.0
							final_shadow = bool(fragment.get("shadow", false))
				if not covered: visible_mat += 1
				if final_shadow: visible_shadow += 1
				depth_pixels += 1
				var actual := screen.get_pixelv(at)
				if partial:
					shadow_blend_pixels += 1
					# GL's normalized-byte blend can round once differently from
					# CPU Color.blend. Only these known existing translucent
					# shadow pixels allow one 8-bit channel step; opaque pixels
					# and the source reconstruction remain exactly equal.
					if absf(actual.r - expected.r) > 1.01 / 255.0 or absf(actual.g - expected.g) > 1.01 / 255.0 or absf(actual.b - expected.b) > 1.01 / 255.0: mismatch += 1
				elif actual != expected: mismatch += 1
		check(mismatch == 0, "%s %s %s actual mat/actor/furniture depth pixels (%d mismatches)" % [facing, id, checkpoint, mismatch])
		observations.append({"facing": facing, "employee": id, "checkpoint": checkpoint, "actual_depth_pixels": 640, "depth_mismatches": mismatch, "visible_mat_pixels": visible_mat, "visible_floor_shadow_on_mat_pixels": visible_shadow, "shadow_on_mat_is_visual_defect": visible_shadow > 0})

func capture(owner: Node, facing: String, checkpoint: String) -> void:
	if not rendered: return
	for tick: int in range(3):
		await process_frame
		frames += 1
	RenderingServer.force_draw(false)
	var shot := PIXELS.rgba(root.get_texture().get_image())
	check(shot.get_size() == Vector2i(1280, 720), "Native actual GameMain1280x720")
	check(not owner.main.job_panel._connection_panel.visible and not owner.main.job_panel.drawer_is_open(), "No stale onboarding/drawer in captured room")
	verify_depth(owner, shot, facing, checkpoint)
	var name_value := facing + "-" + checkpoint + ".png"
	check(shot.save_png(OUTPUT.path_join(name_value)) == OK, "Save native " + name_value)
	captures.append(name_value)
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var pivot := Vector2i(actor._workstation_visual.prop_anchor)
		var crop := shot.get_region(Rect2i(pivot + Vector2i(-80, -112), Vector2i(160, 176)))
		crop.resize(640, 704, Image.INTERPOLATE_NEAREST)
		name_value = "%s-%s-%s-4x.png" % [facing, id, checkpoint]
		check(crop.save_png(OUTPUT.path_join(name_value)) == OK, "Save nearest detail " + name_value)
		captures.append(name_value)

func run_direction(facing: String) -> bool:
	var owner := FIXTURE.new()
	owner.employee_ids.assign(IDS)
	owner.initial_facing = facing
	root.add_child(owner)
	await process_frame
	check(owner.ready_ok, "Real GameMain profile admission " + facing + ": " + str(owner.errors))
	if not owner.ready_ok:
		owner.free()
		return false
	for tick: int in range(3): await process_frame
	var main: GameMain = owner.main
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.player.set_physics_process(false)
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
		actor._label_layer.hide()
		actor._effect_sprite.hide()
	main.set_process(false)
	for child: Node in owner.editor.get_children():
		if child is CanvasLayer: (child as CanvasLayer).hide()
	var ui := CanvasLayer.new()
	ui.layer = 100
	owner.add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(176, 112)
	panel.custom_minimum_size = Vector2(800, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 4, 10, 4)))
	ui.add_child(panel)
	var caption := Label.new()
	CozyUI.label(caption, "meta")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(caption)
	preflight(owner, facing)
	caption.text = "ENGINEER MAT · %s · resting tools · no computer or engineer backend" % facing.to_upper()
	await capture(owner, facing, "resting-tools")
	for id: String in IDS:
		owner.send_to_desk(id)
		walk(main.get_employee(id), true)
	for frame: int in range(6):
		caption.text = "ENGINEER MAT · %s · frame%d · %s" % [facing.to_upper(), frame, "seated scale reference" if frame < 2 else "typing stress test — NOT probe-use animation"]
		for id: String in IDS: set_frame(main.get_employee(id), facing, frame)
		await capture(owner, facing, "frame%d" % frame)
	if facing == "south":
		caption.text = "DIAGNOSTIC ONLY · South floor shadows hidden · not a production fix"
		for id: String in IDS:
			set_frame(main.get_employee(id), facing, 0)
			main.get_employee(id)._shadow_sprite.hide()
		await capture(owner, facing, "shadow-hidden-diagnostic")
		for id: String in IDS: main.get_employee(id)._shadow_sprite.show()
	for id: String in IDS:
		owner.leave_desk(id)
		walk(main.get_employee(id), false)
		check(main.get_employee(id)._active_work_pose_layers.is_empty(), "Standing restores original unsplit locomotion")
	caption.text = "ENGINEER MAT · %s · actors returned to idle · resting tools unchanged" % facing.to_upper()
	await capture(owner, facing, "returned-idle")
	var worker := main.worker_client as FIXTURE.NullWorker
	check(worker != null and not main._state_loaded and not main._worker_ready, "Only blocked NullWorker, no state read")
	check(main.day_clock.speed == 0, "Business clock fixed")
	observations.append({"facing": facing, "blocked_transport_requests": worker.blocked_requests.duplicate()})
	check(not worker.blocked_requests.has("job.start") and not worker.blocked_requests.has("chat.send"), "No paid work or chat requested; all fixture transport is blocked")
	var scope: String = owner.pose_set_id
	owner.free()
	await process_frame
	check(not CharacterArt.is_calibration_pose_set(scope), "Temporary pose authorization revoked")
	return true

func contacts() -> void:
	for facing: String in DIRECTIONS:
		var sheet := Image.create(960, 352, false, Image.FORMAT_RGBA8)
		for frame: int in range(6):
			var full := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join("%s-frame%d.png" % [facing, frame])))
			for person: int in range(2):
				sheet.blit_rect(full, Rect2i(256 + person * 448, 160, 160, 176), Vector2i((frame % 3) * 320 + person * 160, int(frame / 3) * 176))
		var path := facing + "-all-six-native.png"
		check(sheet.save_png(OUTPUT.path_join(path)) == OK, "All-six native pair " + facing)
		captures.append(path)
	var all_four := Image.create(640, 352, false, Image.FORMAT_RGBA8)
	for index: int in range(4):
		var full := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(DIRECTIONS[index] + "-frame0.png")))
		for person: int in range(2):
			all_four.blit_rect(full, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(index * 160, person * 176))
	check(all_four.save_png(OUTPUT.path_join("all-four-native.png")) == OK, "All-four facing native contact")
	captures.append("all-four-native.png")
	all_four.resize(2560, 1408, Image.INTERPOLATE_NEAREST)
	check(all_four.save_png(OUTPUT.path_join("all-four-4x.png")) == OK, "All-four nearest contact")
	captures.append("all-four-4x.png")

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var all_ready := true
	for facing: String in DIRECTIONS: all_ready = await run_direction(facing) and all_ready
	if rendered and all_ready: contacts()
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Original source/export unchanged " + path)
	var file := FileAccess.open(OUTPUT.path_join("manifest.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "frames": frames,
		"depth_pixels": depth_pixels, "shadow_blend_pixels_with_one_byte_tolerance": shadow_blend_pixels,
		"observations": observations, "measurements": measurements, "source_sha256": source_hashes,
		"scene": "Actual GameMain through scoped calibrated_workstation_fixture", "runtime_approved": false,
		"worker_transport_started": false, "save_access": false, "mat_material": "intentionally opaque plates; no cutout claim",
		"pose_limit": "Existing seated/typing as scale and occlusion references only; no probe-use animation or engineer work."}, "\t"))
	print("Engineer mat composition: %d checks, %d failures; %d captures, %d actual depth pixels." % [checks, failures.size(), captures.size(), depth_pixels])
	quit(0 if failures.is_empty() else 1)
