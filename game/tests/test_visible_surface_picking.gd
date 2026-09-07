extends SceneTree
## Provider-free real input reproductions and native sprite-picking regressions.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/visible-surface-picking"
var main: GameMain
var owner_fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var baseline := false
var completed_facings: Array[String] = []
var sampled_pixels := 0
var source_hashes := {}
var render_tie_verified := false

func state() -> Array:
	var actors: Array = []
	for actor: EmployeeAvatar in main._employees.values():
		actors.append([actor.position, actor.work_state, actor._route.duplicate(), actor._animation_elapsed, actor.seated_render_offset(), actor.z_index])
	return [actors, main.room.resolved_placements.duplicate(true), main.day_clock.day, main.day_clock.minute_of_day]

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 3) -> void:
	for tick: int in range(count): await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await frames(1)

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Native1280×720 capture")
	var path := OUTPUT.path_join(("before-" if baseline else "after-") + name_value + ".png")
	check(image.save_png(path) == OK, "Save " + name_value)
	captures.append(path)

func cleanup() -> void:
	if owner_fixture != null:
		owner_fixture.free()
		owner_fixture = null
	elif main != null:
		main.game_audio.shutdown()
		main.free()
	main = null

func settle() -> void:
	await frames()
	main.set_process(false)
	main.player.set_physics_process(false)
	main.day_clock.set_speed(0)
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.founder_hud.dismiss_movement_hint()
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "No worker transport")
	await frames()
	main._process(0)

func legacy() -> void:
	cleanup()
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(FIXTURE.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	await settle()
	main.room.set_hire_count(4)
	var actor := main.get_employee("mira")
	actor.position = actor.desk_position
	actor._has_target = false
	actor._route.clear()
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._animation_elapsed = 0
	actor._update_character_frame()
	main.player.position = Vector2(272, 496)
	await frames()
	await capture("legacy-seated")
	for point: Vector2 in [Vector2(336, 234), Vector2(210, 466)]:
		await click(point)
		var target := main._pending_interaction
		observations.append({"point": str(point), "target": target, "kind": main._pending_kind, "route": str(main.player.route)})
		var expected := ("mira" if baseline else "mira-workstation") if point.x == 336 else ("founder-workstation" if baseline else "")
		check(target == expected, "Real click %s selects '%s', got '%s'" % [point, expected, target])
		if point.x == 210 and not baseline: check(not main.player.route.is_empty(), "Transparent desk padding remains ground navigation")
		main.player.cancel_route()
	await capture("legacy-clicks")
	if baseline: return
	var face := Vector2(336, 194)
	var before := state()
	check(main._interaction_at(face).get("id") == "mira", "Visible Mina face remains selectable")
	check(state() == before, "Picking does not mutate actors, clock or placements")
	var original := [actor._character_sprite.visible, actor._effect_sprite.visible, actor._shadow_sprite.visible]
	actor._character_sprite.hide()
	actor._effect_sprite.show()
	actor._shadow_sprite.show()
	check(actor.body_surface_at(actor._effect_sprite.global_position) == null, "Work cues cannot impersonate body clicks")
	check(actor.body_surface_at(actor._shadow_sprite.global_position) == null, "Floor shadows cannot impersonate body clicks")
	actor._character_sprite.visible = original[0]
	actor._effect_sprite.visible = original[1]
	actor._shadow_sprite.visible = original[2]
	await click(face)
	check(main._pending_interaction == "mira", "Real visible-face click targets employee")
	main.player.cancel_route()
	# One genuine arrival proves the existing action routing rather than calling
	# destination handlers directly. Actor state and workstation remain frozen.
	await click(Vector2(336, 234))
	for tick: int in range(900):
		main.player._physics_process(1.0 / 30.0)
		if main.player.route.is_empty(): break
	check(main.job_panel._tabs.current_tab == 1, "Monitor arrival opens the existing Assign action")
	main.job_panel.close_drawer(false)
	await frames()
	main.player.position = Vector2(272, 496)
	# UI owns its click/focus; it must not call the newly refined world picker.
	main.job_panel.open_chat_for_employee("mira")
	await create_timer(0.22).timeout
	var input: Control = main.job_panel._chat_input
	main.player.cancel_route()
	await click(input.get_global_rect().get_center())
	check(main.player.route.is_empty(), "Chat text focus click cannot leak to world movement")
	check(root.gui_get_focus_owner() == input, "Real chat click retains keyboard focus")
	await capture("ui-focus-isolated")
	var rail_button: Button = main.job_panel._team_buttons["theo"]
	await click(rail_button.get_global_rect().get_center())
	check(main.job_panel._selected_employee_id == "theo" and main.player.route.is_empty(), "Rail selection stays accessible without world movement")
	main.job_panel.close_drawer(false)
	await frames()

func engine_contract() -> void:
	var branch := Node2D.new()
	root.add_child(branch)
	branch.position = Vector2(40, 80)
	branch.z_index = 10
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.set_pixel(5, 2, Color.RED)
	var texture := ImageTexture.create_from_image(image)
	var first := Sprite2D.new()
	first.texture = texture
	first.region_enabled = true
	first.region_rect = Rect2(4, 0, 4, 4)
	first.z_index = 2
	branch.add_child(first)
	check(VisibleSurface.depth(first) == 12, "Relative child depth includes real parent depth")
	check(VisibleSurface.painted(first, Vector2(39, 80)), "Native opaque-hit accounts for centered source region")
	check(not VisibleSurface.painted(first, Vector2(40, 80)), "Native opaque-hit rejects transparent region pixel")
	first.centered = false
	first.position = Vector2(7, 9)
	check(VisibleSurface.painted(first, Vector2(48, 91)), "Uncentered split source and local transform are respected")
	first.hide()
	check(not VisibleSurface.painted(first, Vector2(48, 91)), "Hidden body never wins")
	first.show()
	branch.modulate.a = 0
	check(not VisibleSurface.painted(first, Vector2(48, 91)), "Invisible parent modulation never wins")
	branch.modulate.a = 1
	var second := Sprite2D.new()
	second.texture = texture
	branch.add_child(second)
	second.z_as_relative = false
	second.z_index = 12
	check(VisibleSurface.depth(second) == 12, "Absolute depth does not double-count prop parent")
	check(VisibleSurface.in_front(second, first) and not VisibleSurface.in_front(first, second), "Same-depth actual later scene sibling wins")
	second.z_index = 11
	check(VisibleSurface.in_front(first, second), "Higher effective depth beats scene order")
	# Native tie proof uses two solid test pixels only, outside actual game art.
	first.position = Vector2(0, 0)
	first.centered = false
	first.region_enabled = false
	first.texture = ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	var red := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	red.fill(Color.RED)
	first.texture = ImageTexture.create_from_image(red)
	var blue := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	blue.fill(Color.BLUE)
	second.texture = ImageTexture.create_from_image(blue)
	second.centered = false
	second.z_index = 12
	if DisplayServer.get_name() != "headless":
		await frames()
		RenderingServer.force_draw(false)
		check(root.get_texture().get_image().get_pixel(43, 83) == Color.BLUE, "Actual renderer agrees with equal-depth later-sibling picking")
		render_tie_verified = true
	branch.free()

func body_sprites(actor: EmployeeAvatar) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = [actor._character_sprite]
	for sprite: Sprite2D in actor._work_pose_layer_sprites.values(): result.append(sprite)
	return result

func source_pixel(sprite: Sprite2D, point: Vector2) -> Color:
	# Independent DEV oracle: cached CPU source images, not a production input
	# path. Read source registration directly rather than calling the picker.
	var local := sprite.to_local(point) - sprite.get_rect().position
	if not Rect2(Vector2.ZERO, sprite.get_rect().size).has_point(local): return Color.TRANSPARENT
	var region := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, sprite.texture.get_size())
	var pixel := Vector2i((region.position + local).floor())
	var image := sprite.texture.get_image()
	if not Rect2i(Vector2i.ZERO, image.get_size()).has_point(pixel): return Color.TRANSPARENT
	return image.get_pixelv(pixel)

func layered() -> void:
	for facing: String in OfficeLayout.FACINGS:
		cleanup()
		owner_fixture = FIXTURE.new()
		owner_fixture.employee_ids.assign(["mira", "theo"])
		owner_fixture.initial_facing = facing
		root.add_child(owner_fixture)
		check(owner_fixture.ready_ok, "Actual admitted %s fixture ready: %s" % [facing, owner_fixture.errors])
		if not owner_fixture.ready_ok: return
		main = owner_fixture.main
		await settle()
		owner_fixture.editor.hide()
		owner_fixture.editor.set_process_input(false)
		owner_fixture.editor.set_process_unhandled_input(false)
		await frames()
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			owner_fixture.send_to_desk(id)
			for tick: int in range(1200):
				actor._physics_process(1.0 / 30.0)
				if not actor._has_target and not actor._seat_transition_active: break
			check(not actor._has_target and not actor._seat_transition_active, "Actual %s %s route/seat transition finished" % [id, facing])
		for frame: int in range(6):
			for id: String in ["mira", "theo"]:
				var actor := main.get_employee(id)
				actor.work_state = EmployeeAvatar.WorkState.SITTING if frame < 2 else EmployeeAvatar.WorkState.TYPING
				actor._animation_elapsed = (float(frame if frame < 2 else frame - 2) + 0.01) / (1.5 if frame < 2 else 8.0)
				actor._update_character_frame()
				var before := state()
				var all_sprites: Array[Sprite2D] = body_sprites(actor)
				var prop := main.room.prop_node(id + "-workstation")
				for layer: Dictionary in main.room.placement_by_id(id + "-workstation").render_layers:
					all_sprites.append(prop.get_node(NodePath(str(layer.name))) as Sprite2D)
				all_sprites.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return VisibleSurface.in_front(b, a))
				var found_body := Vector2.INF
				var found_foreground := Vector2.INF
				var hidden_count := 0
				var bounds := Rect2i(actor.render_position() + Vector2(-24, -72), Vector2(48, 80))
				for y: int in range(bounds.position.y, bounds.end.y, 2):
					for x: int in range(bounds.position.x, bounds.end.x, 2):
						var point := Vector2(x, y) + Vector2(0.5, 0.5)
						var painted: Sprite2D
						var body_ink := false
						for sprite: Sprite2D in all_sprites:
							if not sprite.visible or source_pixel(sprite, point).a < 0.5: continue
							painted = sprite
							if sprite.get_parent() == actor: body_ink = true
						var actual := main._interaction_at(point)
						if painted == null: continue
						sampled_pixels += 1
						var is_body := painted.get_parent() == actor
						check(actual.get("id") == (id if is_body else id + "-workstation"), "%s/%s/%d pixel%s selects the top registered source body" % [facing, id, frame, point])
						if is_body and found_body == Vector2.INF: found_body = point
						if not is_body and body_ink:
							hidden_count += 1
							found_foreground = point
				check(found_body != Vector2.INF, "%s/%s/%d has genuinely visible employee pixels" % [facing, id, frame])
				check(state() == before, "Dense surface probes do not alter actor/geometry state")
				if frame == 0:
					await click(found_body)
					check(main._pending_interaction == id, "Actual %s/%s visible body click reaches employee route got %s" % [facing, id, main._pending_interaction])
					main.player.cancel_route()
					if found_foreground != Vector2.INF:
						await click(found_foreground)
						check(main._pending_interaction == id + "-workstation", "Actual layered foreground click cannot select a hidden seated body")
						main.player.cancel_route()
					observations.append({"facing": facing, "employee": id, "visibleBody": str(found_body), "opaqueOverlap": str(found_foreground), "hiddenSamples": hidden_count})
			if frame in [0, 2, 5]: await capture(facing + "-frame" + str(frame))
		var actor := main.get_employee("mira")
		var before_leave := actor.render_position()
		owner_fixture.leave_desk("mira")
		for tick: int in range(1200):
			actor._physics_process(1.0 / 30.0)
			if not actor._has_target and not actor._seat_transition_active: break
		check(actor.render_position() != before_leave and actor._active_work_pose_layers.is_empty(), "Leave restores locomotion and discards stale split-layer targets")
		check(actor.body_surface_at(before_leave + Vector2(0, -48)) == null, "Old seated silhouette is not clickable after departure")
		await capture(facing + "-left-desk")
		completed_facings.append(facing)

func run() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.notify_mouse_entered()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for path: String in [OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH, "res://assets/runtime/characters/mira-locomotion.png", "res://assets/runtime/characters/theo-locomotion.png"]:
		source_hashes[path] = FileAccess.get_sha256(path)
	await legacy()
	check(observations.size() == 2, "Both real-input reproductions completed")
	if not baseline:
		cleanup()
		await engine_contract()
		await layered()
		check(completed_facings == OfficeLayout.FACINGS and sampled_pixels > 10000, "All four directions/both actors/all six frames completed")
		check(DisplayServer.get_name() == "headless" or render_tie_verified, "Native engine tie-order proof completed when rendered")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Source data and art unchanged: " + path)
	cleanup()
	var result := {"checks": checks, "failures": failures, "baseline": baseline, "observations": observations, "captures": captures, "facings": completed_facings, "sampledPixels": sampled_pixels, "sourceHashes": source_hashes, "nativeTieOrder": render_tie_verified}
	var file := FileAccess.open(OUTPUT.path_join("baseline.json" if baseline else "headless.json" if DisplayServer.get_name() == "headless" else "results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
