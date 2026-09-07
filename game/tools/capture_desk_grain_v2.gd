extends "res://tools/capture_desk_finish_v2.gd"
## Isolated material A/B. Reuses frozen mechanical helpers, not their outputs.
const GRAIN_FIXTURE := preload("res://tools/desk_grain_v2_fixture.gd")
const GRAIN_OUTPUT := "res://tests/output/desk-grain-v2"
const GRAIN_EXPORTS := "res://tests/fixtures/furniture-calibration/modular-desk-grain-v2"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials-v2"
var material_facts: Array[Dictionary] = []
var new_layers: Array[Dictionary] = []
var old_shots: Dictionary = {}

func source_records() -> Array[Dictionary]:
	var records := super.source_records()
	for path: String in ["res://tools/desk_finish_v2_geometry.gd", "res://tools/desk_finish_v2_fixture.gd", "res://tools/desk_grain_v2_fixture.gd", "res://tools/capture_desk_grain_v2.gd"]:
		records.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	for direction: String in BASE.DIRECTIONS:
		for layer: String in ["rear", "front"]:
			var path := EXPORTS.path_join(direction + "-" + layer + ".png")
			records.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	for axis: String in ["horizontal", "vertical"]:
		for path: String in ["res://assets/source/overnight-20260904/materials/oak-" + axis + "-v2.png", MATERIALS.path_join("oak-" + axis + "-v2.png")]:
			records.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	return records

func preflight() -> void:
	for axis: String in ["horizontal", "vertical"]:
		var path := MATERIALS.path_join("oak-" + axis + "-v2.png")
		var image := UTIL.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))
		check(image.get_size() == Vector2i(32, 32), "Exact native tile")
		var palette := [Color("a75927"), Color("b7672c"), Color("c47734")]
		var counts := [0, 0, 0]
		for y: int in range(32):
			for x: int in range(32):
				var index := palette.find(image.get_pixel(x, y))
				check(index >= 0, "Opaque pixel belongs to original three-color palette")
				if index >= 0: counts[index] += 1
		material_facts.append({"path": path, "sha256": FileAccess.get_sha256(path), "decoded_sha256": UTIL.digest(image.get_data()), "counts_dark_base_light": counts, "measurements": UTIL.analyze(image)})
	for direction: String in BASE.DIRECTIONS:
		var a := GRAIN_FIXTURE.new()
		var b := GRAIN_FIXTURE.new()
		b.quiet_grain = true
		var before: Dictionary = a.profile(direction)
		var after: Dictionary = b.profile(direction)
		for layer: Dictionary in after.render_layers:
			layer.art = str(layer.art).replace("modular-desk-grain-v2/", "modular-desk-finish-v2/")
		check(before == after, "Only material raster paths change; all sockets/pose/cue/physics exact")
		a.free()
		b.free()

func make_view(direction: String, selected_layer: String) -> SubViewport:
	var view := super.make_view(direction, selected_layer)
	var desk = view.get_child(0)
	var h := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(MATERIALS.path_join("oak-horizontal-v2.png"))))
	var v := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(MATERIALS.path_join("oak-vertical-v2.png"))))
	check(desk.configure(direction, h, v), "Frozen finish geometry accepts new native materials")
	# configure replaces layer nodes; apply isolation to the newly created pair.
	if selected_layer == "rear": desk.front.hide()
	if selected_layer == "front": desk.rear.hide()
	return view

func export_views() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GRAIN_EXPORTS))
	var views := {}
	for direction: String in BASE.DIRECTIONS:
		views[direction] = {}
		for layer: String in ["rear", "front", "whole"]: views[direction][layer] = make_view(direction, layer)
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var plate := Image.create(768, 448, false, Image.FORMAT_RGBA8)
	plate.fill(Color.TRANSPARENT)
	for index: int in range(4):
		var direction: String = BASE.DIRECTIONS[index]
		var pictures := {}
		var profile: Dictionary = BASE.profile(direction)
		for layer: String in ["rear", "front", "whole"]:
			var next := UTIL.rgba((views[direction][layer] as SubViewport).get_texture().get_image())
			pictures[layer] = next
			var path := (GRAIN_OUTPUT if layer == "whole" else GRAIN_EXPORTS).path_join(direction + "-" + layer + ".png")
			save(next, path)
			if layer != "whole":
				var old := UTIL.rgba(Image.load_from_file(ProjectSettings.globalize_path(EXPORTS.path_join(direction + "-" + layer + ".png"))))
				var illegal := 0
				var alpha_errors := 0
				for y: int in range(224):
					for x: int in range(192):
						pixel_checks += 1
						var a := old.get_pixel(x, y)
						var b := next.get_pixel(x, y)
						if a.a != b.a: alpha_errors += 1
						if a == b: continue
						changed_pixels += 1
						if layer != profile.top_layer or not (profile.top as Rect2i).grow(-2).has_point(Vector2i(x, y) - UTIL.PIVOT): illegal += 1
				check(alpha_errors == 0 and illegal == 0, "Exact alpha/finish/border; only inset material changes: " + direction + layer)
				var facts := UTIL.analyze(next)
				check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, "Binary clean alpha")
				new_layers.append({"path": path, "sha256": FileAccess.get_sha256(path), "decoded_sha256": UTIL.digest(next.get_data()), "measurements": facts, "pivot": [96, 160], "scale": 1})
		check(UTIL.binary_over(pictures.rear, pictures.front).get_data() == (pictures.whole as Image).get_data(), "Exact source layer reunion")
		plate.blit_rect(Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(direction + "-whole.png"))), Rect2i(Vector2i.ZERO, UTIL.CANVAS), Vector2i(index * 192, 0))
		plate.blit_rect(pictures.whole, Rect2i(Vector2i.ZERO, UTIL.CANVAS), Vector2i(index * 192, 224))
		for layer: String in ["rear", "front", "whole"]: (views[direction][layer] as SubViewport).free()
	save(plate, GRAIN_OUTPUT.path_join("grain-before-after-native.png"))
	var detail := plate.duplicate()
	detail.resize(3072, 1792, Image.INTERPOLATE_NEAREST)
	save(detail, GRAIN_OUTPUT.path_join("grain-before-after-4x.png"))

func room_study() -> void:
	var contacts := Image.create(1280, 704, false, Image.FORMAT_RGBA8)
	for direction_index: int in range(4):
		var direction: String = BASE.DIRECTIONS[direction_index]
		for quiet: bool in [false, true]:
			var fixture := GRAIN_FIXTURE.new()
			fixture.employee_ids.assign(["mira", "theo"])
			fixture.initial_facing = direction
			fixture.quiet_grain = quiet
			root.add_child(fixture)
			await frames()
			check(fixture.ready_ok, "Actual GameMain material fixture ready")
			if not fixture.ready_ok: return
			var main: GameMain = fixture.main
			main.set_process(false)
			main.player.set_physics_process(false)
			for id: String in ["mira", "theo"]:
				var actor := main.get_employee(id)
				actor.set_physics_process(false)
				fixture.send_to_desk(id)
				await advance(actor)
				check(actor.position == actor.desk_position, "Original logical work foot")
				for layer: String in ["rear", "front"]:
					var sprite: Sprite2D = main.room.prop_node(id + "-workstation").get_node("Desk" + layer.capitalize())
					var expected := UTIL.rgba(Image.load_from_file(ProjectSettings.globalize_path((GRAIN_EXPORTS if quiet else EXPORTS).path_join(direction + "-" + layer + ".png"))))
					check(UTIL.rgba(sprite.texture.get_image()).get_data() == expected.get_data(), "Imported full RGBA buffer exact")
					check(sprite.scale == Vector2.ONE and sprite.rotation == 0 and not sprite.flip_h and not sprite.flip_v, "Native unrotated scale1 desk")
			for frame: int in [0, 3]:
				for actor: EmployeeAvatar in main._employees.values():
					actor.work_state = EmployeeAvatar.WorkState.SITTING if frame == 0 else EmployeeAvatar.WorkState.TYPING
					actor.has_live_job = frame != 0
					actor._animation_elapsed = 0.01 if frame == 0 else 1.01 / 8.0
					actor._update_character_frame()
					actor._sync_render_transform()
				main._update_label_visibility("")
				if DisplayServer.get_name() != "headless":
					await frames(2)
					RenderingServer.force_draw(false)
					var shot := root.get_texture().get_image()
					check(shot.get_size() == Vector2i(1280, 720), "Native room screenshot")
					var key := direction + "-pose-%d" % frame
					var name_value := direction + ("-quiet" if quiet else "-old") + "-pose-%d.png" % frame
					if not quiet: old_shots[key] = shot.duplicate()
					else:
						var illegal := 0
						for id: String in ["mira", "theo"]:
							var anchor := Vector2i(main.get_employee(id)._workstation_visual.prop_anchor)
							var allowed: Rect2i = BASE.profile(direction).top
							allowed.position += anchor
							allowed = allowed.grow(-2)
							for y: int in range(anchor.y - 160, anchor.y + 64):
								for x: int in range(anchor.x - 96, anchor.x + 96):
									assembly_compared_pixels += 1
									if (old_shots[key] as Image).get_pixel(x, y) != shot.get_pixel(x, y) and not allowed.has_point(Vector2i(x, y)): illegal += 1
						check(illegal == 0, "All body/finish/computer/chair pixels outside inset top exact")
					if frame == 3:
						for person: int in range(2): contacts.blit_rect(shot, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(direction_index * 320 + person * 160, 352 if quiet else 0))
					else:
						for person: int in range(2): contacts.blit_rect(shot, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(direction_index * 320 + person * 160, 528 if quiet else 176))
					save(shot, GRAIN_OUTPUT.path_join(name_value))
					captures.append(name_value)
			check(main.worker_client._stdio == null and not main._state_loaded, "No real worker or personal save")
			fixture.free()
			await frames()
	if DisplayServer.get_name() != "headless": save(contacts, GRAIN_OUTPUT.path_join("all-four-assembly-before-after-native.png"))

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GRAIN_OUTPUT))
	source_before = source_records()
	preflight()
	var mode := "preflight"
	if "--export" in OS.get_cmdline_user_args():
		mode = "export"
		check(DisplayServer.get_name() != "headless", "Export needs renderer")
		if failures.is_empty(): await export_views()
	elif "--room" in OS.get_cmdline_user_args():
		mode = "room"
		if failures.is_empty(): await room_study()
	check(source_records() == source_before, "Originals, finish and old exports unchanged")
	var result := {"id": "desk-grain-v2", "mode": mode, "checks": checks, "failures": failures, "renderer": DisplayServer.get_name(), "worker_disabled": true, "runtime_approved": false, "materials": material_facts, "layers": new_layers, "source_files": source_before, "captures": captures, "compared_layer_pixels": pixel_checks, "changed_layer_pixels": changed_pixels, "assembly_compared_pixels": assembly_compared_pixels, "physical_ticks": physical_ticks}
	var file := FileAccess.open(GRAIN_OUTPUT.path_join("results-" + mode + ("-headless" if DisplayServer.get_name() == "headless" else "") + ".json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Desk grain v2 %s: %d checks / %d failures" % [mode, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
