extends SceneTree
## Provider-free deterministic geometry checks. Passing does not register art.
const COFFEE := preload("res://tools/coffee_station_geometry.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const OUTPUT := "res://tests/output/coffee-station-candidate"
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

func texture(size_value: Vector2i, color: Color) -> ImageTexture:
	var image := Image.create(size_value.x, size_value.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func overlaps(left: Rect2i, right: Rect2i) -> bool:
	return left.intersects(right)

func run() -> void:
	check(COFFEE.profile("bad").is_empty(), "Unknown service side fails closed")
	check(COFFEE.supports("bad").is_empty(), "Unknown support layout fails closed")
	var summaries: Array[Dictionary] = []
	for side: String in COFFEE.SIDES:
		var p: Dictionary = COFFEE.profile(side)
		var base: Dictionary = CABINET.profile("counter", side)
		var horizontal := side in ["north", "south"]
		check(p.canvas == COFFEE.CANVAS and p.pivot == COFFEE.PIVOT, side + " shared family canvas and floor pivot")
		check(p.floor == base.floor and p.top == base.top and p.top_interior == base.top_interior, side + " reuses exact counter planes")
		check(p.service_cell == base.service_cell and p.approach_gaze == base.approach_gaze, side + " retains explicit service semantics")
		check(p.occupied == base.occupied and p.clearance == base.clearance, side + " retains exact collision and approach strip")
		check(p.runtime_approved == false and p.derivation == "deterministic_code_geometry_plus_reviewed_native_tiles", side + " candidate status and derivation are explicit")
		check(p.service_controls_visibility == ("front" if side == "south" else ("rear_hidden" if side == "north" else "edge_on")), side + " service-face visibility is honest")
		var expected_face: String = {"north": "rear", "east": "reservoir_end", "south": "service_controls", "west": "vent_end"}[side]
		check(p.machine_camera_face == expected_face, side + " machine has a distinct camera face")
		var registered := Rect2i(p.visual_bounds.position + COFFEE.PIVOT, p.visual_bounds.size)
		check(Rect2i(Vector2i.ZERO, COFFEE.CANVAS).grow(-1).encloses(registered), side + " all declared ink has transparent canvas gutter")
		var support_names: Array[String] = []
		for component: String in COFFEE.COMPONENTS:
			var support: Rect2i = p.supports[component]
			check(p.top_interior.encloses(support), side + " " + component + " support stays inside actual raised rim")
			check((p.component_bounds[component] as Rect2i).has_area(), side + " " + component + " has explicit native pixels")
			check(p.visual_bounds.encloses(p.component_bounds[component]), side + " " + component + " pixels belong to family bounds")
			for earlier: String in support_names:
				check(not overlaps(support, p.supports[earlier]), side + " " + component + " support does not overlap " + earlier)
			support_names.append(component)
		check(p.component_order.size() == 4, side + " all components have same-depth rear-to-front order")
		for component: String in COFFEE.COMPONENTS:
			check(p.component_order.has(component), side + " depth order contains " + component)
		var machine: Rect2i = p.supports.Espresso
		check(machine.size == (Vector2i(31, 15) if horizontal else Vector2i(15, 31)), side + " exact machine footprint exchanges axes")
		check((p.component_bounds.Espresso as Rect2i).size.y >= 46, side + " machine remains a tall readable silhouette")
		var mug_bounds: Rect2i = p.component_bounds.Serviceware
		check(mug_bounds.size.x >= 5 and mug_bounds.size.y >= 6, side + " two-mug cluster remains native-readable")
		var plant_bounds: Rect2i = p.component_bounds.Plant
		check(plant_bounds.size.x >= 12 and plant_bounds.size.y >= 20, side + " plant has readable pot and foliage")
		var node := COFFEE.new()
		root.add_child(node)
		var oak_h := texture(Vector2i(32, 32), Color("a87742"))
		var oak_v := texture(Vector2i(32, 32), Color("93633a"))
		var powder := texture(Vector2i(32, 32), Color("35434d"))
		check(node.configure(side, oak_h, oak_v, powder), side + " builds exact deterministic station")
		check(node.resolved == p and node.scale == Vector2.ONE and is_zero_approx(node.rotation), side + " native geometry and transform")
		check(node.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, side + " nearest sampling")
		check(node.layers.size() == COFFEE.LAYERS.size(), side + " every semantic layer is registered")
		check(node.render_order.size() == COFFEE.LAYERS.size(), side + " render order covers every layer once")
		for layer_name: String in COFFEE.LAYERS:
			check(node.layers.has(layer_name) and node.render_order.has(layer_name), side + " registered layer " + layer_name)
			var layer := node.layers[layer_name] as Node2D
			check(layer.position == Vector2.ZERO and layer.scale == Vector2.ONE and is_zero_approx(layer.rotation), side + " common origin " + layer_name)
			check(layer.z_index == (-1 if layer_name == "FloorShadow" else 0), side + " reviewed layer depth " + layer_name)
		check(node.render_order[0] == "FloorShadow" and node.render_order[5] == "ServicePanel", side + " structure order precedes loose objects")
		var previous := -2147483648
		for component: String in p.component_order:
			var contact: Rect2i = p.supports[component]
			check(contact.end.y >= previous, side + " loose objects are ordered by camera depth")
			previous = contact.end.y
		var before := node.resolved.duplicate(true)
		check(not node.configure("bad", oak_h, oak_v, powder) and node.resolved == before, side + " invalid side preserves valid configuration")
		check(not node.configure(side, texture(Vector2i(31, 32), Color.WHITE), oak_v, powder) and node.resolved == before, side + " wrong material dimensions reject without mutation")
		node.free()
		summaries.append({"side": side, "service_side": p.service_side, "approach_gaze": p.approach_gaze,
			"floor": [p.floor.position.x, p.floor.position.y, p.floor.size.x, p.floor.size.y],
			"visual_bounds": [p.visual_bounds.position.x, p.visual_bounds.position.y, p.visual_bounds.size.x, p.visual_bounds.size.y],
			"machine_camera_face": p.machine_camera_face, "service_controls_visibility": p.service_controls_visibility,
			"component_order": p.component_order, "runtime_approved": false})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("geometry-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "views": summaries,
		"canvas": [COFFEE.CANVAS.x, COFFEE.CANVAS.y], "pivot": [COFFEE.PIVOT.x, COFFEE.PIVOT.y],
		"image_generation": false, "semantic_raster_edit": false, "runtime_registered": false,
		"worker_disabled": true, "save_access": false}, "\t") + "\n")
	print("Coffee station deterministic geometry: %d checks, %d failures; candidate only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
