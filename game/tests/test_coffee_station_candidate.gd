extends SceneTree
## Headless admission and actual TownRoom native-layer proof for the dev candidate.
const COFFEE := preload("res://tools/coffee_station_geometry.gd")
const FIXTURE := preload("res://tools/coffee_station_candidate_fixture.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/coffee-station-candidate"
var checks := 0
var failures: Array[String] = []
var physics_ticks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func rect_array(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func walk_until_done(player: PlayerAvatar, label: String) -> void:
	for tick: int in range(1200):
		player._physics_process(1.0 / 30.0)
		physics_ticks += 1
		check(player.navigation.position_is_safe(player.position, "founder"), label + " founder stays outside furniture/walls")
		if player.route.is_empty(): break
	check(player.route.is_empty(), label + " actual route completes within bound")

func run() -> void:
	var profiles: Array[Dictionary] = []
	for side: String in COFFEE.SIDES:
		var profile := FIXTURE.service_profile(side)
		var geometry := COFFEE.profile(side)
		check(not profile.is_empty(), side + " candidate profile resolves from native exports")
		check(profile.profile_kind == "service" and profile.status == "calibration_candidate", side + " explicit standing-service candidate status")
		check(profile.review == {"art": false, "geometry": false}, side + " no hidden production approval")
		check(profile.service_side == side and profile.approach_gaze == geometry.approach_gaze, side + " service side and opposite gaze")
		check(profile.interaction == [geometry.service_cell.x, geometry.service_cell.y], side + " exact authored service cell")
		check(profile.approach_visual_bounds == [-24, -72, 48, 80], side + " full native standing headroom")
		check(profile.render_layers.size() == COFFEE.LAYERS.size(), side + " all registered semantic layers exported")
		var seen: Array[String] = []
		var union := Rect2()
		var decoded := Image.create(COFFEE.CANVAS.x, COFFEE.CANVAS.y, false, Image.FORMAT_RGBA8)
		decoded.fill(Color(0, 0, 0, 0))
		for layer: Dictionary in profile.render_layers:
			check(not seen.has(str(layer.name)), side + " unique runtime layer " + str(layer.name))
			seen.append(str(layer.name))
			check(ResourceLoader.exists(str(layer.art), "Texture2D"), side + " imported runtime candidate layer " + str(layer.art))
			check(layer.region == [0, 0, 192, 256] and layer.offset == [0, -64], side + " exact common registration " + str(layer.name))
			check(not layer.has("scale") and not layer.has("rotation") and not layer.has("flip_h") and not layer.has("flip_v"), side + " no runtime image transform " + str(layer.name))
			var ink := OfficeLayout.measured_layer_ink_bounds(layer)
			check(ink.has_area(), side + " nonempty native layer " + str(layer.name))
			var placed := Rect2(Vector2(-96, -192) + ink.position, ink.size)
			union = union.merge(placed) if union.has_area() else placed
			# Source PNG bytes are the export contract. Godot's lossless importer
			# may synthesize RGB under alpha=0 for sampling, which is not artwork.
			var image := Image.load_from_file(ProjectSettings.globalize_path(str(layer.art)))
			var alpha := PIXELS.analyze(image)
			check(image.get_size() == COFFEE.CANVAS and alpha.partial_alpha_pixels == 0 and alpha.hidden_rgb_pixels == 0, side + " clean full-canvas layer " + str(layer.name))
			decoded = PIXELS.binary_over(decoded, image)
		check(profile.visual_bounds == [int(union.position.x), int(union.position.y), int(union.size.x), int(union.size.y)], side + " runtime visual bounds equal measured layer union")
		check(profile.visual_bounds == rect_array(geometry.visual_bounds), side + " runtime image union equals explicit geometry")
		var whole_path := FIXTURE.EXPORT + side + "-whole.png"
		check(ResourceLoader.exists(whole_path, "Texture2D"), side + " registered whole evidence imports")
		var whole := Image.load_from_file(ProjectSettings.globalize_path(whole_path))
		check(decoded.get_data() == whole.get_data(), side + " runtime layer declaration reconstructs exact whole")
		check(whole.get_used_rect() == Rect2i(geometry.visual_bounds.position + COFFEE.PIVOT, geometry.visual_bounds.size), side + " whole preserves exact local floor registration")
		profiles.append({"side": side, "profile": profile, "whole_sha256": FileAccess.get_sha256(whole_path)})
	var fixture := FIXTURE.new()
	root.add_child(fixture)
	await process_frame
	await process_frame
	check(fixture.ready_ok and fixture.errors.is_empty(), "Actual GameMain/TownRoom candidate fixture starts: " + str(fixture.errors))
	if fixture.ready_ok:
		check(fixture.main.get_node_or_null("WorkerClient") != null and OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1", "Fixture uses the null worker boundary")
		fixture.main.set_process(false)
		fixture.main.player.set_physics_process(false)
		for side: String in COFFEE.SIDES:
			fixture.main.player.cancel_route()
			fixture.main.player.input_blocked = false
			fixture.main.player.position = fixture.model.world(Vector2i(17, 17))
			fixture.main.player.z_index = int(fixture.main.player.position.y)
			fixture.main.room.navigation.actors["founder"] = fixture.main.player.position
			check(fixture.set_facing(side), side + " actual room accepts candidate facing")
			await process_frame
			await physics_frame
			var placement := fixture.main.room.placement_by_id("coffee-station")
			check(not placement.is_empty() and placement.facing == side, side + " actual room resolves selected facing")
			check(placement.profile_kind == "service" and placement.service_side == side, side + " actual room keeps standing-service semantics")
			check(placement.approach_gaze == COFFEE.profile(side).approach_gaze, side + " actual arrival gaze")
			check(placement.interaction == fixture.initial_grid + COFFEE.profile(side).service_cell, side + " actual interaction cell is one face beyond footprint")
			check((placement.direction_errors as Array).is_empty(), side + " owner-scoped candidate has no direction validation error")
			var prop := fixture.main.room.prop_node("coffee-station")
			check(prop != null and prop.position == fixture.model.world(fixture.initial_grid), side + " actual TownRoom anchor")
			if prop != null:
				var collisions := prop.get_node_or_null("PlacementCollision") as StaticBody2D
				check(collisions != null and collisions.get_child_count() == 3, side + " exact three-cell runtime collision")
				for layer: Dictionary in placement.render_layers:
					var sprite := prop.get_node_or_null(NodePath(str(layer.name))) as Sprite2D
					check(sprite != null, side + " TownRoom built native sprite " + str(layer.name))
					if sprite != null:
						check(sprite.position == Vector2(0, -64) and sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation), side + " actual native transform " + str(layer.name))
						check(not sprite.flip_h and not sprite.flip_v and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, side + " actual nearest/unmirrored sprite " + str(layer.name))
						check(sprite.z_index == prop.z_index + int(layer.z_offset), side + " actual reviewed depth " + str(layer.name))
			check(fixture.model.is_floor(placement.interaction), side + " actual service cell lies on approved room floor")
			for occupied: Vector2i in placement.occupied: check(fixture.model.is_floor(occupied), side + " occupied cell stays on floor")
			# Coffee is still product-scoped as decorative in TownRoom/Main, so the
			# candidate must not silently invent a click action. Independently prove
			# that its declared service socket is reachable through real navigation.
			var machine_bounds: Rect2i = COFFEE.profile(side).component_bounds.Espresso
			var click_point := Vector2(placement.anchor) + Vector2(machine_bounds.get_center())
			check(fixture.main.room.interaction_at(click_point).is_empty(), side + " current product does not acquire a fabricated coffee click action")
			var target := fixture.main.room.interaction_world_position("coffee-station")
			check(fixture.main.player.move_to(target) and not fixture.main.player.route.is_empty(), side + " declared service socket begins a real AStar route")
			await walk_until_done(fixture.main.player, side + " service")
			check(fixture.main.player.position.distance_to(target) < 0.01, side + " exact authored service socket reached")
			fixture.main.player.face_direction(fixture.main.room.interaction_approach_direction("coffee-station"))
			var expected_pose: StringName = {"north": &"front", "east": &"left", "south": &"back", "west": &"right"}[side]
			check(fixture.main.player._facing == expected_pose, side + " explicit approach direction maps to existing standing art")
			check(fixture.main._pending_interaction.is_empty() and not fixture.main.job_panel.drawer_is_open() and not fixture.main.company_panel.visible, side + " coffee click invents no work or drawer action")
		var before := fixture.main.room.placement_by_id("coffee-station").duplicate(true)
		check(not fixture.main.room.set_placement_overrides({"coffee-station": {"grid": [1, 1], "facing": "north"}}), "Actual room rejects wall-crossing candidate")
		check(fixture.main.room.placement_by_id("coffee-station") == before, "Rejected move preserves valid room candidate")
	fixture.free()
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("candidate-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "profiles": profiles, "actual_founder_physics_ticks": physics_ticks,
		"runtime_registered": false, "catalogue_changed": false, "worker_disabled": true, "save_access": false}, "\t") + "\n")
	print("Coffee station runtime candidate: %d checks, %d failures; owner-scoped only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
