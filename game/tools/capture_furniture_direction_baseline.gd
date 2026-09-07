extends SceneTree
## Provider-free native regression evidence. This does not approve any N/E/W art.
## South comparisons reconstruct the PRE-DIRECTION texture/region/origin/depth
## math independently inside the same frozen room, rather than comparing stale
## historical screenshots with different clocks, UI states or idle frames.

const OUTPUT := "res://tests/output/furniture-direction-baseline"
const EDITOR: Script = preload("res://tools/office_layout_editor.gd")
const LEGACY_DESK: Texture2D = preload("res://assets/runtime/office/south-workstation.png")
const LEGACY_MIRA: Texture2D = preload("res://assets/runtime/characters/mira-seated.png")
const LEGACY_THEO: Texture2D = preload("res://assets/runtime/characters/theo-seated.png")
const LEGACY_SHADOW: Texture2D = preload("res://assets/runtime/effects/character-shadows.png")
var main: GameMain
var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var comparisons: Array[Dictionary] = []
var rendered := false

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	await _south_pixel_baseline()
	await _shifted_actor_input()
	await _reset_events()
	await _dispose_main()
	await _editor_input()
	var file := FileAccess.open(OUTPUT.path_join("results-rendered.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "rendered": rendered, "workerDisabled": true, "productionFacings": ["south"], "comparisonMethod": "independent legacy south sprite-math reconstruction in identical frozen GameMain", "captures": captures, "pixelComparisons": comparisons, "limitations": ["No new facing artwork is approved", "Shifted seated socket is an isolated geometry test, not accepted art placement", "Editor captures use its native 1600x800 development canvas", "Unknown work identities reject registry lookups; generic old locomotion/delivery helpers still have legacy placeholder behavior"]}, "\t"))
	print("Furniture direction baseline: %d checks, %d failures, %d native captures, %d pixel comparisons." % [checks, failures.size(), captures.size(), comparisons.size()])
	quit(0 if failures.is_empty() else 1)

func _frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func _fixture() -> void:
	await _dispose_main()
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	main.game_audio.set_volumes(0, 0)
	main.game_audio.shutdown()
	main.company_panel.hide()
	main.founder_hud.dismiss_movement_hint()
	main.founder_hud.hide_delivery()
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	main.job_panel.close_drawer(false)
	if main.worker_client.request_failed.is_connected(main.job_panel.set_error): main.worker_client.request_failed.disconnect(main.job_panel.set_error)
	# Visible interactions are exercised; any worker-facing signal stays local.
	for entry: Dictionary in main.job_panel.get_signal_list():
		for connection: Dictionary in main.job_panel.get_signal_connection_list(entry.name):
			var callback: Callable = connection.callable
			if callback.get_object() == main.worker_client: main.job_panel.disconnect(entry.name, callback)
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
		actor.world_paused = true
	main.player.set_physics_process(false)
	main.room.navigation.reservations.clear()
	main._process(0)
	await create_timer(0.24).timeout
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1 and not main._state_loaded, "Fresh fixture has no worker process or loaded personal save")
	_stop_ambient(main.room)
	await _frames()

func _stop_ambient(node: Node) -> void:
	if node is OfficeAmbientOverlay: node.set_process(false)
	for child: Node in node.get_children(): _stop_ambient(child)

func _dispose_main() -> void:
	if main != null:
		main.game_audio.shutdown()
		main.free()
		main = null
		await _frames()

func _snapshot(name_value: String = "", note: String = "") -> Image:
	await _frames()
	if not rendered: return null
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if not name_value.is_empty():
		var path := OUTPUT.path_join(name_value + ".png")
		check(image.save_png(path) == OK, "Saved native capture " + name_value)
		captures.append({"name": name_value, "path": path, "size": [image.get_width(), image.get_height()], "note": note})
	return image

func _south_pixel_baseline() -> void:
	await _fixture()
	for actor: EmployeeAvatar in main._employees.values():
		actor.position = actor.desk_position
		actor._has_target = false
		actor._activity = &""
		actor._effect_sprite.hide()
		actor._label_layer.hide()
	for column: int in range(6):
		for actor: EmployeeAvatar in main._employees.values():
			actor.work_state = EmployeeAvatar.WorkState.SITTING if column < 2 else EmployeeAvatar.WorkState.TYPING
			actor._animation_elapsed = float(column) / 1.5 if column < 2 else float(column - 2) / 8.0
			actor._update_character_frame()
			var prop := main.room.prop_node(actor.employee_id + "-workstation")
			check(actor.z_index == int(actor.position.y), "Actual legacy south seated depth equals pre-direction foot Y")
			check(prop.get_node("WorkstationRear").z_index < actor.z_index and actor.z_index < prop.get_node("WorkstationFront").z_index, "Actual south actor sorts between desk layers")
		var name_value := "south-seated-current" if column == 0 else "south-typing-current" if column == 2 else ""
		var current := await _snapshot(name_value, "Actual production south rendering")
		# Explicit historical values, intentionally not derived from the new
		# resolver, new pose registry or seat-depth metadata being verified.
		for actor: EmployeeAvatar in main._employees.values():
			actor._character_sprite.texture = LEGACY_MIRA if actor.employee_id == "mira" else LEGACY_THEO
			actor._character_sprite.region_rect = Rect2(column * 48, 0, 48, 80)
			actor._character_sprite.position = Vector2(0, -32) + actor.position.round() - actor.position
			actor.z_index = int(actor.position.y)
			actor._shadow_sprite.texture = LEGACY_SHADOW
			actor._shadow_sprite.region_rect = Rect2(64, 0, 32, 16)
			actor._shadow_sprite.position = Vector2(0, -2) + actor.position.round() - actor.position
			var prop := main.room.prop_node(actor.employee_id + "-workstation")
			for index: int in range(2):
				var sprite := prop.get_node("WorkstationRear" if index == 0 else "WorkstationFront") as Sprite2D
				sprite.texture = LEGACY_DESK
				sprite.region_rect = Rect2(index * 128, 0, 128, 112)
				sprite.position = Vector2(0, -40)
				sprite.scale = Vector2.ONE
				sprite.z_as_relative = false
				sprite.z_index = prop.z_index + (-40 if index == 0 else 1)
		var reference := await _snapshot("south-seated-legacy-reference" if column == 0 else "south-typing-legacy-reference" if column == 2 else "", "Independent reconstruction, not a historical whole-screen screenshot")
		if current != null:
			for actor: EmployeeAvatar in main._employees.values():
				var prop := main.room.prop_node(actor.employee_id + "-workstation")
				var bounds := Rect2i(Vector2i(prop.global_position) - Vector2i(80, 112), Vector2i(160, 144))
				var pixels := _different_pixels(current.get_region(bounds), reference.get_region(bounds))
				check(pixels == 0, "%s south frame%d matches every baseline pixel (%d changed)" % [actor.employee_id, column, pixels])
				comparisons.append({"employee": actor.employee_id, "frame": column, "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "changedPixels": pixels, "comparedPixels": bounds.size.x * bounds.size.y})
	check(CharacterArt.work_pose_frame("future-lawyer", CharacterArt.LEGACY_WORK_POSE_SET, "south", "seated", 0).is_empty(), "Unknown specialist cannot silently borrow Mina work poses")
	check(CharacterArt.work_pose_frame("", CharacterArt.LEGACY_WORK_POSE_SET, "south", "typing", 0).is_empty(), "Missing identity has no registered typing art")

func _different_pixels(left: Image, right: Image) -> int:
	var count := 0
	for y: int in range(left.get_height()):
		for x: int in range(left.get_width()):
			if left.get_pixel(x, y) != right.get_pixel(x, y): count += 1
	return count

func _seat(actor: EmployeeAvatar, offset: Vector2 = Vector2.ZERO) -> void:
	actor.position = actor.desk_position
	actor._has_target = false
	actor._route.clear()
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	var metadata := main.room.employee_workstation_visual(actor.employee_id)
	metadata.seat_anchor = offset
	check(actor.configure_workstation_visual(metadata), "Supported south socket configures without enabling another facing")
	actor._animation_elapsed = 0
	actor._update_character_frame()
	main.room.navigation.actors[actor.employee_id] = actor.position
	main.room.navigation.reservations[actor.employee_id] = main.room.navigation.cell_at(actor.position)

func _shifted_actor_input() -> void:
	await _fixture()
	var actor := main.get_employee("mira")
	_seat(actor, Vector2(16, -8))
	var feet := actor.position
	main.player.position = main.room.grid_to_world_position(Vector2i(12, 8))
	main.room.navigation.actors["founder"] = main.player.position
	main._process(0)
	var point := actor.render_position() + Vector2(11, -52)
	check(not Rect2(feet + Vector2(-24, -72), Vector2(48, 84)).has_point(point), "Mouse proof targets the shifted body outside the old hit rectangle")
	await _mouse(point)
	main._process(0)
	check(main._interaction_at(point).get("id", "") == "mira", "Shifted visual point resolves to the employee")
	if rendered: check(actor._ui_highlighted, "Real mouse motion highlights the visually shifted employee")
	check(actor._label_layer.global_position == actor.render_position(), "Callout canvas uses the same shifted native origin as character art")
	check(main.founder_hud.interaction_visible(), "Nearby seated employee has a visible interaction prompt")
	var prompt := main.founder_hud._interaction_prompt
	var action := prompt.get_node("ChatAction") as FounderHud.InteractionButton
	check(prompt.global_position + action.callout_target == WorldCalloutSkin.actor_rect(actor.render_position()).get_center(), "Interaction prompt pointer targets the rendered employee, not stale physical feet")
	await _snapshot("shifted-socket-hover", "Geometry-only +16,-8px render socket; physical feet stay unchanged")
	await _click(point)
	check(main._pending_interaction == "mira" and main._pending_kind == "employee", "Real click selects the shifted employee rather than the furniture behind")
	check(not main.player.route.is_empty(), "Employee click starts a valid physical approach path")
	main.player.set_physics_process(true)
	for frame: int in range(240):
		main._process(0)
		await _frames(1)
		if main.job_panel.drawer_is_open(): break
	main.player.set_physics_process(false)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Chat opens after real path arrival")
	check(actor.position == feet and main.room.navigation.cell_at(actor.position) == main.room.navigation.cell_at(feet), "Hover/click/render socket leave employee navigation feet unchanged")
	await create_timer(0.24).timeout
	main._process(0)
	check(actor._drawer_selected and not actor._labels_visible(), "Opened drawer suppresses the shifted actor's redundant world name")
	await _snapshot("shifted-socket-chat-open", "Actual world click → physical approach → Mina chat")

func _reset_events() -> void:
	for terminal: StringName in [&"job.failed", &"job.completed"]:
		await _fixture()
		var actor := main.get_employee("mira")
		_seat(actor, Vector2(8, -6))
		main._job_employees["baseline-job"] = "mira"
		main.job_panel.begin_job("baseline-job", "mira")
		main.job_panel.accept_submission("baseline-job")
		actor.has_live_job = true
		var write := WorkerEventRecord.new()
		write.type = &"tool.started"
		write.tool = "write_file"
		main._on_job_event("baseline-job", write)
		check(actor.work_state == EmployeeAvatar.WorkState.TYPING and actor.seated_render_offset() == Vector2(8, -6), "Actual write event uses the configured seated socket")
		var event := WorkerEventRecord.new()
		event.type = terminal
		main._on_job_event("baseline-job", event)
		main._process(0)
		check(actor.seated_render_offset() == Vector2.ZERO and actor._character_sprite.position == Vector2(0, -32), "Terminal event immediately clears the seated render offset")
		check(actor._shadow_sprite.position == Vector2(0, -2) and actor.z_index == int(actor.position.y), "Terminal event restores physical-foot shadow and depth")
		check(actor._label_layer.global_position == actor.render_position(), "Terminal event removes stale offset from callout drawing")
		await create_timer(0.24).timeout
		await _snapshot("failure-seat-reset" if terminal == &"job.failed" else "delivery-seat-reset", "Actual simulated terminal worker event; no provider")

func _editor_input() -> void:
	root.size = Vector2i(1600, 800)
	root.content_scale_size = root.size
	var editor := EDITOR.new() as DevOfficeLayoutEditor
	root.add_child(editor)
	await _frames(8)
	editor.select_placement("mira-workstation")
	var before := editor.room.placement_by_id("mira-workstation").duplicate(true)
	check(editor._facing_picker.item_count == 1, "Production editor exposes south only")
	await _key(KEY_R)
	check(not editor.placement_active and editor.room.placement_by_id("mira-workstation") == before, "Real R cannot substitute or commit missing direction art")
	await _snapshot("editor-missing-direction-rejected", "Native1600x800 developer editor; no missing facing is offered")
	await _key(KEY_M)
	var target: Vector2i = before.grid + Vector2i(2, -1)
	var point := editor.ROOM_ORIGIN + editor.model.world(target)
	await _mouse(point)
	check(editor.preview_result.valid, "Actual mouse preview chooses a valid existing south bay")
	var ghost := editor._preview_layers(editor._candidate)
	await _snapshot("editor-south-move-preview", "Existing authored south layers remain registered in preview")
	await _click(point)
	check(not editor.placement_active, "Actual click commits the valid south preview")
	var placed := editor.room.prop_node("mira-workstation")
	for index: int in range(2):
		var sprite := placed.get_node("WorkstationRear" if index == 0 else "WorkstationFront") as Sprite2D
		check(sprite.texture == ghost[index].texture and sprite.region_rect == ghost[index].source, "Committed native layer matches preview art region")
		check(Rect2(sprite.global_position - sprite.region_rect.size * 0.5, sprite.region_rect.size) == ghost[index].destination, "Committed native layer origin matches the preview exactly")
	await _snapshot("editor-south-move-placed", "Actual input committed the same preview geometry")
	await _key(KEY_Z, true)
	check(editor.room.placement_by_id("mira-workstation").grid == before.grid, "Actual undo restores the original authored station")
	editor.free()
	await _frames()

func _mouse(point: Vector2) -> void:
	if rendered: root.warp_mouse(point)
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	await _frames()

func _click(point: Vector2) -> void:
	await _mouse(point)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await _frames(1)
	await _frames()

func _key(code: Key, control: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.ctrl_pressed = control
		event.pressed = down
		root.push_input(event, true)
		await _frames(1)
	await _frames()
