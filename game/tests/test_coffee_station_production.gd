extends SceneTree
## Production promotion proof for the reviewed four-facing coffee art/geometry.
## Service sockets remain geometry only: no coffee click, UI, worker or save action.

const RUNTIME := "res://assets/runtime/office/coffee-station-v1/"
const SOURCE := "res://tests/fixtures/furniture-calibration/coffee-station-code-v1/"
const FRONT_CORRECTION := "res://assets/source/coffee-front-polish/"
const MANIFEST_PATH := RUNTIME + "manifest.json"
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const PARTS: Array[String] = [
	"floor_shadow", "counter_carcass", "counter_top", "counter_front",
	"counter_plinth", "service_panel", "espresso", "grinder",
	"serviceware", "plant",
]
const ORDER := {
	"north": ["floor_shadow", "counter_carcass", "counter_top", "counter_front", "counter_plinth", "service_panel", "serviceware", "plant", "grinder", "espresso"],
	"east": ["floor_shadow", "counter_carcass", "counter_top", "counter_front", "counter_plinth", "service_panel", "grinder", "serviceware", "espresso", "plant"],
	"south": ["floor_shadow", "counter_carcass", "counter_top", "counter_front", "counter_plinth", "service_panel", "grinder", "espresso", "plant", "serviceware"],
	"west": ["floor_shadow", "counter_carcass", "counter_top", "counter_front", "counter_plinth", "service_panel", "plant", "espresso", "serviceware", "grinder"],
}
const EXPECTED_VISUAL := {
	"north": [-48, -68, 96, 88], "east": [-16, -90, 32, 142],
	"south": [-48, -73, 96, 93], "west": [-16, -84, 32, 136],
}
const EXPECTED_HIT := {
	"north": [-48, -68, 96, 84], "east": [-16, -90, 32, 138],
	"south": [-48, -73, 96, 89], "west": [-16, -84, 32, 132],
}

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func source_image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))

func reviewed_source(file_name: String) -> String:
	# Preserve the historical code fixture. The south front panel now has its
	# own retained, reproducible ImageGen treatment with identical geometry.
	if file_name in ["south-espresso.png", "south-whole.png"]:
		return FRONT_CORRECTION + file_name
	return SOURCE + file_name

func first_painted_point(prop: Node2D, placement: Dictionary) -> Vector2:
	for layer: Dictionary in placement.render_layers:
		var sprite := prop.get_node_or_null(NodePath(str(layer.name))) as Sprite2D
		if sprite == null or sprite.texture == null: continue
		var image := sprite.texture.get_image()
		var content := OfficeLayout.layer_content_bounds(layer)
		for y: int in range(int(content.position.y), int(content.end.y)):
			for x: int in range(int(content.position.x), int(content.end.x)):
				if image.get_pixel(x, y).a >= 0.99:
					return sprite.global_position + Vector2(x + 0.5, y + 0.5) - sprite.region_rect.size * 0.5
	return Vector2(INF, INF)

func run() -> void:
	var manifest := load_json(MANIFEST_PATH)
	check(manifest.revision == "coffee-station-v1" and manifest.status == "runtime_ready", "Runtime manifest records the reviewed revision")
	check(OfficeLayout.vector(manifest.canvas) == Vector2i(192, 256) and OfficeLayout.vector(manifest.pivot) == Vector2i(96, 192) and is_equal_approx(float(manifest.native_scale), 1.0), "Runtime manifest preserves canvas, floor pivot and native scale")
	check(manifest.interaction == "noninteractive", "Runtime manifest explicitly keeps coffee noninteractive")
	check(manifest.files.size() == 44, "Runtime manifest freezes 40 layers plus four whole references")

	var model := OfficeLayout.new()
	check(model.load_files(), "Normal production layout and catalogue load")
	check(model.available_facings("coffee_station") == OfficeLayout.FACINGS, "Coffee exposes exactly four reviewed production views")
	check(model.catalog.coffee_station.get("interaction_enabled", true) == false, "Coffee family explicitly opts out of runtime interaction")
	var default_coffee := model.placement_by_id("coffee-station", 1)
	check(default_coffee.grid == Vector2i(4, 6) and default_coffee.facing == "south", "Promotion preserves the authored South bay")

	for side: String in OfficeLayout.FACINGS:
		var result := model.resolve_profile("coffee_station", side)
		check(result.errors.is_empty(), side + " production profile resolves without a calibration permit: " + str(result.errors))
		var profile: Dictionary = result.profile
		check(profile.profile_kind == "service" and profile.service_side == side and profile.approach_gaze == OfficeLayout.OPPOSITE_GAZE[side], side + " preserves service-side geometry and opposite standing gaze")
		check(profile.status == "runtime_ready" and profile.review == {"art": true, "geometry": true} and profile.asset_revision == "coffee-station-v1", side + " has exact art/geometry production admission")
		check(profile.get("interaction_enabled", true) == false, side + " remains noninteractive after directional profile resolution")
		check(OfficeLayout.rectangle(profile.visual_bounds) == OfficeLayout.rectangle(EXPECTED_VISUAL[side]) and OfficeLayout.rectangle(profile.hit_bounds) == OfficeLayout.rectangle(EXPECTED_HIT[side]), side + " retains measured visual and non-shadow hit bounds")
		check(profile.render_layers.size() == PARTS.size(), side + " declares all ten semantic layers")
		for field: String in OfficeLayout.SEATED_FIELDS:
			check(not profile.has(field), side + " does not invent seated/reaching metadata: " + field)
		var ordered: Array[String] = []
		var composite := Image.create(192, 256, false, Image.FORMAT_RGBA8)
		composite.fill(Color(0, 0, 0, 0))
		for layer: Dictionary in profile.render_layers:
			var file_name := str(layer.art).get_file()
			var part := file_name.trim_prefix(side + "-").trim_suffix(".png")
			ordered.append(part)
			check(part in PARTS and str(layer.art) == RUNTIME + file_name, side + " catalogue points only at its production layer: " + file_name)
			check(OfficeLayout.rectangle(layer.region) == Rect2(0, 0, 192, 256) and OfficeLayout.vector(layer.offset) == Vector2i(0, -64), side + " keeps exact layer registration: " + file_name)
			check(not layer.has("scale") and not layer.has("rotation") and not layer.has("flip_h") and not layer.has("flip_v"), side + " never transforms the reviewed raster: " + file_name)
			var runtime_path := RUNTIME + file_name
			var source_path := reviewed_source(file_name)
			check(FileAccess.file_exists(runtime_path) and FileAccess.file_exists(source_path), side + " source/runtime layer exists: " + file_name)
			check(FileAccess.get_sha256(runtime_path) == FileAccess.get_sha256(source_path), side + " runtime layer is byte-identical to reviewed candidate: " + file_name)
			check(str(manifest.files.get(file_name, "")) == FileAccess.get_sha256(runtime_path), side + " manifest hash matches installed layer: " + file_name)
			var texture := load(runtime_path) as Texture2D
			check(texture != null and texture.get_size() == Vector2(192, 256), side + " imports full registered canvas: " + file_name)
			composite = PIXELS.binary_over(composite, source_image(source_path))
		check(ordered == ORDER[side], side + " keeps the reviewed far-to-near layer declaration")
		var whole_name := side + "-whole.png"
		var source_whole := source_image(reviewed_source(whole_name))
		check(composite.get_data() == source_whole.get_data(), side + " production declaration reconstructs the reviewed whole exactly")
		check(FileAccess.get_sha256(RUNTIME + whole_name) == FileAccess.get_sha256(reviewed_source(whole_name)), side + " runtime whole reference is byte-identical")
		check(str(manifest.files.get(whole_name, "")) == FileAccess.get_sha256(RUNTIME + whole_name), side + " manifest hash matches installed whole reference")
		var original: Dictionary = model.catalog.coffee_station.facing_profiles[side].duplicate(true)
		model.catalog.coffee_station.facing_profiles[side].status = "calibration_candidate"
		check(not model.resolve_profile("coffee_station", side).errors.is_empty(), side + " candidate status cannot forge production admission")
		model.catalog.coffee_station.facing_profiles[side] = original

	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.room.set_hire_count(1)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Production proof starts no worker process")
	for side: String in OfficeLayout.FACINGS:
		main.player.cancel_route()
		main._pending_interaction = ""
		check(main.room.set_placement_overrides({"coffee-station": {"grid": [4, 6], "facing": side}}), "Normal room accepts reviewed coffee " + side)
		var placement := main.room.placement_by_id("coffee-station")
		var prop := main.room.prop_node("coffee-station")
		check(placement.facing == side and placement.profile_kind == "service" and prop != null, side + " ordinary TownRoom builds the production layers")
		check(main.room.navigation.walkable(placement.interaction), side + " declared standing socket remains reachable geometry")
		var point := first_painted_point(prop, placement)
		check(point.is_finite(), side + " exposes a painted production pixel")
		check(main.room.interaction_at(point).is_empty() and main._interaction_at(point).is_empty(), side + " painted coffee remains a noninteractive occluder")
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		main._unhandled_input(event)
		check(main._pending_interaction.is_empty() and main.player.route.is_empty() and not main.job_panel.drawer_is_open() and not main.company_panel.visible, side + " click starts no route, action, drawer or work UI")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("Coffee station production: %d checks, %d failures; interaction intentionally disabled." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
