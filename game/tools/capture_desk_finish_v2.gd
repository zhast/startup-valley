extends SceneTree
## Provider-free finish study; --export creates only new v2 outputs, --room
## compares disposable real GameMain instances. Default is headless preflight.
const BASE := preload("res://tools/modular_desk_geometry.gd")
const FINISH := preload("res://tools/desk_finish_v2_geometry.gd")
const UTIL := preload("res://tools/export_modular_desk_layers.gd")
const FIXTURE := preload("res://tools/desk_finish_v2_fixture.gd")
const OUTPUT := "res://tests/output/desk-finish-v2"
const EXPORTS := "res://tests/fixtures/furniture-calibration/modular-desk-finish-v2"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var pixel_checks := 0
var changed_pixels := 0
var physical_ticks := 0
var source_before: Array[Dictionary] = []
var baseline_shots: Dictionary = {}
var active_fixture: Node
var active_direction := ""
var active_finish := false
var assembly_compared_pixels := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for i: int in range(count): await process_frame

func source_records() -> Array[Dictionary]:
	var result := UTIL.source_records()
	for direction: String in BASE.DIRECTIONS:
		for layer_name: String in ["rear", "front"]:
			var path := UTIL.OUTPUT.path_join(direction + "-" + layer_name + ".png")
			result.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	return result

func preflight() -> void:
	for direction: String in BASE.DIRECTIONS:
		var baseline: Dictionary = BASE.profile(direction)
		check(FINISH.profile(direction) == baseline, direction + " retains exact geometry profile")
		for layer_name: String in ["rear", "front"]:
			var added := FINISH.finish_parts(direction, layer_name)
			var ink := UTIL.rgba(Image.load_from_file(ProjectSettings.globalize_path(UTIL.OUTPUT.path_join(direction + "-" + layer_name + ".png"))))
			for part: Dictionary in added:
				var r: Rect2i = part.rect
				check(r.size.x > 0 and r.size.y > 0, "Nonempty finish rectangle")
				for y: int in range(r.position.y, r.end.y):
					for x: int in range(r.position.x, r.end.x):
						var point := Vector2i(x, y) + UTIL.PIVOT
						# Far legs may be overdrawn by the unchanged top, but every
						# final finish pixel still lies within existing layer ink.
						check(ink.get_pixelv(point).a == 1.0, direction + " finish stays in old opaque layer")
		var plain := BASE.new()
		var candidate := FINISH.new()
		check(plain.configure(direction) and candidate.configure(direction), "Both native helpers configure")
		for key: String in ["top", "floor", "contact_y", "top_layer", "material_axis"]:
			check(plain.resolved[key] == candidate.resolved[key], direction + " exact " + key)
		check(candidate.rear.z_index == -1 and candidate.front.z_index == 1, "Original rear/front depth")
		plain.free()
		candidate.free()
		var old_fixture := FIXTURE.new()
		var new_fixture := FIXTURE.new()
		new_fixture.finish_v2 = true
		var old_profile: Dictionary = old_fixture.profile(direction)
		var new_profile: Dictionary = new_fixture.profile(direction)
		for entry: Dictionary in new_profile.render_layers:
			entry.art = str(entry.art).replace("modular-desk-finish-v2/", "modular-desk-v1/")
		check(new_profile == old_profile, direction + " disposable profile changes only two desk art paths; all physical, actor and cue metadata unchanged")
		old_fixture.free()
		new_fixture.free()
	check(FINISH.finish_parts("diagonal", "front").is_empty(), "No invented facing")

func make_view(direction: String, selected_layer: String) -> SubViewport:
	var view := SubViewport.new()
	view.size = UTIL.CANVAS
	view.transparent_bg = true
	view.disable_3d = true
	view.msaa_2d = Viewport.MSAA_DISABLED
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var desk := FINISH.new()
	desk.position = Vector2(UTIL.PIVOT)
	view.add_child(desk)
	var horizontal := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(UTIL.HORIZONTAL)))
	var vertical := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(UTIL.VERTICAL)))
	check(desk.configure(direction, horizontal, vertical), "Existing soft grain at native size")
	if selected_layer == "rear": desk.front.hide()
	if selected_layer == "front": desk.rear.hide()
	return view

func compare_layer(old: Image, next: Image, direction: String, layer_name: String) -> void:
	var a := UTIL.rgba(old).get_data()
	var b := UTIL.rgba(next).get_data()
	var top: Rect2i = BASE.profile(direction).top
	var permitted := FINISH.finish_parts(direction, layer_name)
	var alpha_errors := 0
	var illegal_changes := 0
	var changed := 0
	for y: int in range(UTIL.CANVAS.y):
		for x: int in range(UTIL.CANVAS.x):
			var at := (y * UTIL.CANVAS.x + x) * 4
			pixel_checks += 1
			if a[at + 3] != b[at + 3]: alpha_errors += 1
			if a.slice(at, at + 4) == b.slice(at, at + 4): continue
			changed += 1
			var point := Vector2i(x, y) - UTIL.PIVOT
			var allowed := false
			for part: Dictionary in permitted:
				if (part.rect as Rect2i).has_point(point): allowed = true
			if not allowed or (layer_name == BASE.profile(direction).top_layer and top.has_point(point)): illegal_changes += 1
	changed_pixels += changed
	check(alpha_errors == 0, direction + layer_name + " exact old alpha mask")
	check(illegal_changes == 0, direction + layer_name + " RGB changes only inside finish masks; all top/material pixels unchanged")
	var facts := UTIL.analyze(next)
	check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, "Binary alpha and empty padding")
	check(facts.opaque_colors <= 12, "Bounded native palette")

func save(image: Image, target: String) -> void:
	check(image.save_png(target) == OK, "Save " + target)
	check(UTIL.rgba(Image.load_from_file(ProjectSettings.globalize_path(target))).get_data() == UTIL.rgba(image).get_data(), "Exact PNG roundtrip")

func export_views() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORTS))
	var views := {}
	for direction: String in BASE.DIRECTIONS:
		views[direction] = {}
		for layer_name: String in ["whole", "rear", "front"]: views[direction][layer_name] = make_view(direction, layer_name)
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var plate := Image.create(768, 448, false, Image.FORMAT_RGBA8)
	plate.fill(Color.TRANSPARENT)
	for index: int in range(4):
		var direction: String = BASE.DIRECTIONS[index]
		var images := {}
		for layer_name: String in ["whole", "rear", "front"]:
			images[layer_name] = UTIL.rgba((views[direction][layer_name] as SubViewport).get_texture().get_image())
			var path := (OUTPUT if layer_name == "whole" else EXPORTS).path_join(direction + "-" + layer_name + ".png")
			save(images[layer_name], path)
			if layer_name != "whole":
				compare_layer(Image.load_from_file(ProjectSettings.globalize_path(UTIL.OUTPUT.path_join(direction + "-" + layer_name + ".png"))), images[layer_name], direction, layer_name)
		check(UTIL.binary_over(images.rear, images.front).get_data() == (images.whole as Image).get_data(), "Exact rear/front reconstruction")
		var before := Image.load_from_file(ProjectSettings.globalize_path(UTIL.EVIDENCE.path_join(direction + "-whole.png")))
		plate.blit_rect(before, Rect2i(Vector2i.ZERO, UTIL.CANVAS), Vector2i(index * 192, 0))
		plate.blit_rect(images.whole, Rect2i(Vector2i.ZERO, UTIL.CANVAS), Vector2i(index * 192, 224))
		var detail: Image = images.whole.duplicate()
		detail.resize(768, 896, Image.INTERPOLATE_NEAREST)
		save(detail, OUTPUT.path_join(direction + "-whole-4x.png"))
		for layer_name: String in ["whole", "rear", "front"]: (views[direction][layer_name] as SubViewport).free()
	save(plate, OUTPUT.path_join("finish-before-after-native.png"))
	check(changed_pixels > 0, "Finish study changes real RGB, not just filenames")

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(2)
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Native actual GameMain evidence")
	if active_fixture != null:
		var key := name_value.replace("-v1-", "-").replace("-v2-", "-")
		if not active_finish:
			baseline_shots[key] = image.duplicate()
		else:
			var old: Image = baseline_shots[key]
			var illegal := 0
			var permitted: Array[Rect2i] = []
			for id: String in ["mira", "theo"]:
				var anchor := Vector2i(active_fixture.main.get_employee(id)._workstation_visual.prop_anchor)
				for layer_name: String in ["rear", "front"]:
					for part: Dictionary in FINISH.finish_parts(active_direction, layer_name):
						permitted.append(Rect2i(anchor + (part.rect as Rect2i).position, (part.rect as Rect2i).size))
			for id: String in ["mira", "theo"]:
				var anchor := Vector2i(active_fixture.main.get_employee(id)._workstation_visual.prop_anchor)
				var crop := Rect2i(anchor - UTIL.PIVOT, UTIL.CANVAS)
				for y: int in range(crop.position.y, crop.end.y):
					for x: int in range(crop.position.x, crop.end.x):
						assembly_compared_pixels += 1
						if old.get_pixel(x, y) == image.get_pixel(x, y): continue
						var allowed := false
						for rect: Rect2i in permitted:
							if rect.has_point(Vector2i(x, y)): allowed = true
						if not allowed: illegal += 1
			check(illegal == 0, "Native assembly changes only permitted desk finish pixels: " + name_value)
	save(image, OUTPUT.path_join(name_value + ".png"))
	captures.append(name_value + ".png")

func advance(actor: EmployeeAvatar) -> void:
	for tick: int in range(700):
		actor._physics_process(1.0 / 30.0)
		physical_ticks += 1
		check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Physical feet stay walkable")
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active: break
	check(not actor._has_target, "Real path reaches target")

func room_study() -> void:
	for direction: String in BASE.DIRECTIONS:
		for finished: bool in [false, true]:
			var fixture := FIXTURE.new()
			fixture.employee_ids.assign(["mira", "theo"])
			fixture.initial_facing = direction
			fixture.finish_v2 = finished
			root.add_child(fixture)
			await frames()
			check(fixture.ready_ok, "Real calibration fixture ready: " + str(fixture.errors))
			if not fixture.ready_ok:
				fixture.free()
				return
			var main: GameMain = fixture.main
			active_fixture = fixture
			active_direction = direction
			active_finish = finished
			main.set_process(false)
			main.player.set_physics_process(false)
			for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
			if finished:
				for id: String in ["mira", "theo"]:
					for layer_name: String in ["rear", "front"]:
						var sprite: Sprite2D = main.room.prop_node(id + "-workstation").get_node("Desk" + layer_name.capitalize())
						var raw := Image.load_from_file(ProjectSettings.globalize_path(EXPORTS.path_join(direction + "-" + layer_name + ".png")))
						check(UTIL.rgba(sprite.texture.get_image()).get_data() == UTIL.rgba(raw).get_data(), "Imported native layer retains complete RGBA buffer")
						check(sprite.scale == Vector2.ONE and sprite.rotation == 0 and not sprite.flip_h and not sprite.flip_v, "Native unrotated, unscaled layer")
			var prefix := direction + ("-v2" if finished else "-v1")
			await capture(prefix + "-standing")
			for id: String in ["mira", "theo"]:
				fixture.send_to_desk(id)
				await advance(main.get_employee(id))
				check(main.get_employee(id).position == main.get_employee(id).desk_position, "Unchanged logical seat")
			for frame: int in range(6):
				for actor: EmployeeAvatar in main._employees.values():
					actor.work_state = EmployeeAvatar.WorkState.SITTING if frame < 2 else EmployeeAvatar.WorkState.TYPING
					actor.has_live_job = frame >= 2
					var phase := frame if frame < 2 else frame - 2
					actor._animation_elapsed = (float(phase) + 0.01) / (1.5 if frame < 2 else 8.0)
					actor._update_character_frame()
					actor._sync_render_transform()
					var authored := CharacterArt.work_pose_frame(actor.employee_id, fixture.pose_set_id, direction, "seated" if frame < 2 else "typing", phase)
					check(actor._character_sprite.region_rect == authored.region, "Exact intended source frame")
				main._update_label_visibility("")
				await capture(prefix + "-pose-%d" % frame)
			for id: String in ["mira", "theo"]:
				fixture.leave_desk(id)
				await advance(main.get_employee(id))
				check(main.get_employee(id)._active_work_pose_layers.is_empty(), "Leaving restores standing body ownership")
			main._update_label_visibility("")
			await capture(prefix + "-left")
			check(main.worker_client._stdio == null and not main._state_loaded, "No real worker or saved company")
			active_fixture = null
			fixture.free()
			await frames()

func build_contacts() -> void:
	for direction: String in BASE.DIRECTIONS:
		var sheet := Image.create(960, 704, false, Image.FORMAT_RGBA8)
		for version: int in range(2):
			for frame: int in range(6):
				var path := OUTPUT.path_join("%s-v%d-pose-%d.png" % [direction, version + 1, frame])
				check(FileAccess.file_exists(path), "Recorded actual-room pose exists")
				var shot := Image.load_from_file(ProjectSettings.globalize_path(path))
				for person: int in range(2):
					var source := Rect2i(256 + person * 448, 160, 160, 176)
					var destination := Vector2i(((frame % 3) * 2 + person) * 160, (version * 2 + frame / 3) * 176)
					sheet.blit_rect(shot, source, destination)
		save(sheet, OUTPUT.path_join(direction + "-assembly-before-after-native.png"))

func write_export_index() -> void:
	var profiles: Array[Dictionary] = []
	for direction: String in BASE.DIRECTIONS:
		var record := UTIL.explicit_profile(direction)
		var layers: Array[Dictionary] = []
		for layer_name: String in ["rear", "front"]:
			var path := EXPORTS.path_join(direction + "-" + layer_name + ".png")
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			var measured := UTIL.analyze(image)
			var descriptor := UTIL.layer_descriptor(direction, layer_name, measured)
			descriptor.art = path
			descriptor["sha256"] = FileAccess.get_sha256(path)
			descriptor["decoded_rgba_sha256"] = UTIL.digest(UTIL.rgba(image).get_data())
			descriptor["measurements"] = measured
			layers.append(descriptor)
		record["render_layers"] = layers
		profiles.append(record)
	var sources := source_records()
	for path: String in ["res://tools/desk_finish_v2_geometry.gd", "res://tools/desk_finish_v2_fixture.gd", "res://tools/capture_desk_finish_v2.gd", "res://tests/test_desk_finish_v2.gd"]:
		sources.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	var manifest := {"id": "modular-desk-finish-v2", "status": "dev_finish_candidate_not_runtime_ready", "runtime_approved": false, "generated_originals": 0, "source_files": sources, "directions": profiles, "method": "Code-native finish inside unchanged v1 masks; original soft oak pixels preserved.", "evidence": [OUTPUT.path_join("results-export.json"), OUTPUT.path_join("results-room-headless.json"), OUTPUT.path_join("results-room.json"), OUTPUT.path_join("finish-before-after-native.png")], "limitations": ["Unchanged repeated wood grain.", "No new shadow, mount gesture or hand-contact approval.", "New contact-sheet/index-only helpers were added after the native room capture; geometry and profile logic remain unchanged."]}
	var file := FileAccess.open(EXPORTS.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open separate v2 dev export manifest")
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	source_before = source_records()
	preflight()
	var mode := "preflight"
	if "--export" in OS.get_cmdline_user_args():
		mode = "export"
		check(DisplayServer.get_name() != "headless", "Export requires actual renderer")
		if failures.is_empty(): await export_views()
	elif "--room" in OS.get_cmdline_user_args():
		mode = "room"
		if failures.is_empty(): await room_study()
	elif "--contacts" in OS.get_cmdline_user_args():
		mode = "contacts"
		if failures.is_empty():
			build_contacts()
			write_export_index()
	check(source_records() == source_before, "Original helper, generated material and v1 PNGs unchanged")
	var result := {"id": "desk-finish-v2", "mode": mode, "worker_disabled": true, "renderer": DisplayServer.get_name(), "checks": checks, "failures": failures, "captures": captures, "compared_layer_pixels": pixel_checks, "changed_layer_pixels": changed_pixels, "assembly_compared_pixels": assembly_compared_pixels, "physical_ticks": physical_ticks, "source_files": source_before, "runtime_approved": false}
	var file := FileAccess.open(OUTPUT.path_join("results-" + mode + ("-headless" if DisplayServer.get_name() == "headless" else "") + ".json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Desk finish v2 %s: %d checks / %d failures" % [mode, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
