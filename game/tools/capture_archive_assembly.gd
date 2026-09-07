extends SceneTree
## DEV ONLY: four real camera faces on exact native cabinet geometry.
## This export/showroom does not bypass canonical placement approval or run AI.
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const FIX := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/archive-assembly"
const EXPORT := FIX + "modular-archive-v1"
const FACE_FILES := {"north": "archive-service-north-back-v1", "east": "archive-service-east-locker-end-v1", "south": "archive-service-south-insert-v1", "west": "archive-service-west-display-end-v1"}
const GAZES := {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var exports: Array[Dictionary] = []
var depth_observations: Array[Dictionary] = []
var source_hashes: Dictionary = {}
var textures: Dictionary = {}
var stations: Array[Dictionary] = []
var stage: Node2D
var canvas: CanvasLayer
var header: Label
var labels: Array[PanelContainer] = []
var model: OfficeLayout
var frames := 0
var painted_actor_pixels := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, copy: String) -> void:
	checks += 1
	if not ok:
		failures.append(copy)
		push_error(copy)

func texture(path: String) -> Texture2D:
	if not textures.has(path):
		var data := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(data != null and not data.is_empty(), "Existing source loads " + path)
		textures[path] = ImageTexture.create_from_image(data)
		source_hashes[path] = FileAccess.get_sha256(path)
	return textures[path]

func face_texture(side: String) -> Texture2D:
	return texture(FIX + "kits/" + FACE_FILES[side] + ".png")

func build_cabinet(side: String, finish: String, face: bool = true) -> Node2D:
	var node := CABINET.new()
	check(node.configure("archive", side, texture(FIX + "materials/oak-horizontal-v1-soft.png"), texture(FIX + "materials/oak-vertical-v1-soft.png")), "Build exact archive " + side)
	if face:
		check(node.set_camera_face_finish(CABINET.CAMERA_FACES[side], face_texture(side)), "Attach actual distinct camera face " + side)
	if finish == "powdercoat":
		check(node.set_top_finish(CABINET.TopFinish.POWDERCOAT, texture(FIX + "materials/charcoal-powdercoat-v1.png")), "Attach native isotropic powdercoat " + side)
	return node

func preflight() -> void:
	model = OfficeLayout.new()
	check(model.load_files(), "Read approved room grid, no user state")
	var material := texture(FIX + "materials/charcoal-powdercoat-v1.png").get_image()
	var finish_alpha := PIXELS.analyze(material)
	check(material.get_size() == Vector2i(32, 32) and finish_alpha.opaque_pixels == 1024 and finish_alpha.opaque_colors == 3, "Powdercoat is opaque native32 square with three colors")
	for side: String in CABINET.SIDES:
		var p: Dictionary = CABINET.profile("archive", side)
		var value := face_texture(side).get_image()
		var expected_size := Vector2i(88, 56) if side in ["north", "south"] else Vector2i(24, 56)
		check(value.get_size() == expected_size, side + " exact camera socket canvas")
		var expected_ink := Rect2i(0, 0, 88, 56) if side == "north" else Rect2i(0, 1, 88, 54) if side == "south" else Rect2i(0, 3, 24, 50)
		check(value.get_used_rect() == expected_ink, side + " preserves actual uniform native ink and honest padding")
		var alpha := PIXELS.analyze(value)
		check(alpha.partial_alpha_pixels == 0 and alpha.hidden_rgb_pixels == 0, side + " binary alpha, empty hidden RGB")
		var origin := Vector2i(52, 180) if side in ["north", "south"] else Vector2i(84, 212)
		check(p.camera_face_socket.position + p.pivot == origin and p.camera_face_socket.size == expected_size, side + " exact face socket registration")
		check(p.front.encloses(p.camera_face_socket) and not p.plinth.intersects(p.camera_face_socket), side + " face stays inside structural edges")
		var registered := Image.create(192, 288, false, Image.FORMAT_RGBA8)
		registered.blit_rect(value, Rect2i(Vector2i.ZERO, value.get_size()), origin)
		var authored := texture(FIX + "kits/" + FACE_FILES[side] + "-registered.png").get_image()
		authored.convert(Image.FORMAT_RGBA8)
		check(registered.get_data() == authored.get_data(), side + " full registered partner reconstructs exact source bytes")
		var node := build_cabinet(side, "oak")
		check(node.layers.Insert.texture == face_texture(side) and node.layers.Insert.texture_position == p.camera_face_socket.position, side + " real face resource and native origin retained")
		for wrong: String in CABINET.SIDES:
			if wrong == side:
				continue
			check(not node.set_camera_face_finish(CABINET.CAMERA_FACES[wrong], face_texture(wrong)), side + " rejects wrong camera face identity " + wrong)
		check(not node.set_camera_face_finish(CABINET.CAMERA_FACES[side], texture(FIX + "materials/charcoal-powdercoat-v1.png")), side + " wrong native face dimensions rejected without stretching")
		check(node.set_service_insert(face_texture("south")) == (side == "south"), side + " legacy service-front API stays South-only")
		check(node.set_camera_face_finish(CABINET.CAMERA_FACES[side], face_texture(side)), side + " restore own independently drawn face")
		var before: Array = node.layers.Top.rects.duplicate(true)
		var before_tile: Texture2D = node.layers.Top.tile
		check(not node.set_top_finish(CABINET.TopFinish.POWDERCOAT, face_texture(side)) and node.layers.Top.rects == before and node.layers.Top.tile == before_tile, side + " invalid top rejects without mutation")
		check(node.set_top_finish(CABINET.TopFinish.POWDERCOAT, texture(FIX + "materials/charcoal-powdercoat-v1.png")), side + " finish changes only top material")
		check(node.set_top_finish(CABINET.TopFinish.OAK) and node.layers.Top.rects == before and node.layers.Top.tile == before_tile, side + " original oak structure/material restored exactly")
		check(node.get_child_count() == 5 and node.scale == Vector2.ONE and node.rotation == 0, side + " native stable five-layer assembly")
		check(node.set_camera_face_finish(CABINET.CAMERA_FACES[side], null) and node.layers.Insert.texture == null, side + " optional face can clear to bare without leftover texture")
		node.free()
		var counter := CABINET.new()
		check(counter.configure("counter", side), "Counter remains supported " + side)
		check(not counter.set_camera_face_finish(CABINET.CAMERA_FACES[side], face_texture(side)), "Archive finish cannot leak into counter " + side)
		counter.free()
	var corners := {"north": Vector2i(80, 176), "east": Vector2i(1072, 208), "south": Vector2i(1072, 624), "west": Vector2i(80, 592)}
	var rejected := {"north": Vector2i(48, 176), "east": Vector2i(48, 176), "south": Vector2i(1104, 624), "west": Vector2i(48, 592)}
	for side: String in CABINET.SIDES:
		check(inside_room(CABINET.profile("archive", side), corners[side]), side + " actual near-corner art and service clearance fit")
		check(not inside_room(CABINET.profile("archive", side), rejected[side]), side + " wall crossing or inaccessible service corner is rejected")

func add_label(copy: String, point: Vector2, width: int) -> Label:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 4, 8, 4)))
	canvas.add_child(panel)
	labels.append(panel)
	var text := Label.new()
	text.text = copy
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(text, "meta")
	panel.add_child(text)
	return text

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Actual approved TownRoom renders")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	canvas = CanvasLayer.new()
	canvas.layer = 50
	root.add_child(canvas)
	header = add_label("ARCHIVE · four real camera faces · oak above / charcoal below · staged only", Vector2(136, 104), 992)
	for row: int in range(2):
		var finish := "oak" if row == 0 else "powdercoat"
		for column: int in range(4):
			var side: String = CABINET.SIDES[column]
			var p: Dictionary = CABINET.profile("archive", side)
			var host := Vector2i(208 + column * 256, 304 + row * 256)
			var cabinet := build_cabinet(side, finish)
			cabinet.position = host
			cabinet.z_as_relative = false
			cabinet.z_index = host.y
			stage.add_child(cabinet)
			var actor := Sprite2D.new()
			actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			actor.region_enabled = true
			actor.centered = false
			actor.z_as_relative = false
			actor.hide()
			stage.add_child(actor)
			stations.append({"id": side + "-" + finish, "side": side, "finish": finish, "p": p, "host": host, "cabinet": cabinet, "actor": actor, "whole": null, "foot": host})
			add_label("%s · %s" % [side.to_upper(), p.camera_face_name.replace("_", " ")], Vector2(host.x - 116, 384 + row * 256), 232)
			check(inside_room(p, host), side + " assembled ink and service cells stay in real floor")

func inside_room(p: Dictionary, host: Vector2i) -> bool:
	var visual: Rect2i = p.visual_bounds
	for y: int in range(visual.position.y, visual.end.y):
		for x: int in range(visual.position.x, visual.end.x):
			if not model.is_floor(model.cell_at(Vector2(host + Vector2i(x, y)))):
				return false
	for offset: Vector2i in p.clearance:
		if not model.is_floor(model.cell_at(Vector2(host)) + offset):
			return false
	return true

func settle(count: int = 3) -> void:
	for index: int in range(count):
		await process_frame
		frames += 1
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func view_for(side: String, finish: String, layer_name: String, face: bool = true) -> SubViewport:
	var view := SubViewport.new()
	view.size = Vector2i(192, 288)
	view.transparent_bg = true
	view.disable_3d = true
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var cabinet := build_cabinet(side, finish, face)
	cabinet.position = Vector2(96, 224)
	view.add_child(cabinet)
	if layer_name != "whole":
		for key: String in CABINET.LAYERS:
			cabinet.layers[key].visible = key == layer_name
	return view

func export_layers() -> void:
	for station: Dictionary in stations:
		var views: Dictionary = {}
		for key: String in ["Carcass", "Top", "Front", "Plinth", "Insert", "whole"]:
			views[key] = view_for(station.side, station.finish, key)
		var bare: SubViewport
		if station.finish == "oak":
			bare = view_for(station.side, "oak", "whole", false)
		await settle()
		var union := Image.create(192, 288, false, Image.FORMAT_RGBA8)
		var layer_metadata: Array[Dictionary] = []
		for key: String in ["Carcass", "Top", "Front", "Plinth", "Insert", "whole"]:
			var data := PIXELS.rgba(views[key].get_texture().get_image())
			var a := PIXELS.analyze(data)
			check(data.get_size() == Vector2i(192, 288) and a.partial_alpha_pixels == 0 and a.hidden_rgb_pixels == 0 and a.opaque_pixels > 0, station.id + " exact clean native layer " + key)
			if key == "Insert":
				var registered := PIXELS.rgba(texture(FIX + "kits/" + FACE_FILES[station.side] + "-registered.png").get_image())
				check(data.get_data() == registered.get_data(), station.id + " rendered face is byte-exact authored registered source, not a substitute")
			var name_value: String = station.id + "-" + key.to_lower() + ".png"
			check(data.save_png(OUTPUT.path_join(name_value)) == OK, "Write evidence layer " + name_value)
			captures.append(name_value)
			if key != "whole":
				union = PIXELS.binary_over(union, data)
			else:
				check(union.get_data() == data.get_data(), station.id + " complete ordered layer union exactly reconstructs assembly")
				check(data.get_used_rect() == Rect2i(station.p.visual_bounds.position + station.p.pivot, station.p.visual_bounds.size), station.id + " opaque bounds and floor contact remain exact")
				station.whole = data
			if station.finish == "powdercoat":
				var target: String = station.side + "-" + key.to_lower() + ".png"
				check(data.save_png(EXPORT.path_join(target)) == OK, "Write staged native export " + target)
				if key != "whole":
					layer_metadata.append({"name": "Archive" + key, "art": EXPORT.path_join(target), "region": [0, 0, 192, 288], "offset": [0, -80], "z_offset": 0, "ink": PIXELS.rect_values(data.get_used_rect())})
		if station.finish == "powdercoat":
			exports.append({"service_side": station.side, "approach_gaze": station.p.approach_gaze, "camera_face": station.p.camera_face_name, "source_face": FIX + "kits/" + FACE_FILES[station.side] + ".png", "canvas": [192, 288], "pivot": [96, 224], "floor": PIXELS.rect_values(station.p.floor), "top": PIXELS.rect_values(station.p.top), "visual_bounds": PIXELS.rect_values(station.p.visual_bounds), "face_socket": PIXELS.rect_values(station.p.camera_face_socket), "render_layers": layer_metadata, "runtime_approved": false})
		if bare != null:
			var old := Image.load_from_file(ProjectSettings.globalize_path("res://tests/output/modular-cabinet-calibration/archive-" + station.side + "-whole.png"))
			if old != null:
				check(PIXELS.rgba(old).get_data() == PIXELS.rgba(bare.get_texture().get_image()).get_data(), station.side + " previous bare output remains byte-identical")
			else:
				check(false, "Original bare evidence missing; cannot claim preserved raster " + station.side)
			bare.free()
		for view: SubViewport in views.values():
			view.free()

func set_actors(id: String, mode: String) -> void:
	for station: Dictionary in stations:
		var offset := Vector2i(-80, 16)
		var gaze := "south"
		match mode:
			"service":
				offset = station.p.service_cell * 32
				gaze = station.p.approach_gaze
			"rear": offset = Vector2i(0, -64)
			"front":
				offset = Vector2i(0, 64)
				gaze = "north"
			"left":
				offset = Vector2i(-80, 0)
				gaze = "east"
			"right":
				offset = Vector2i(80, 0)
				gaze = "west"
		var actor: Sprite2D = station.actor
		actor.texture = CharacterArt.locomotion_sheet(id)
		actor.region_rect = CharacterArt.locomotion_region(GAZES[gaze], 0)
		var foot: Vector2i = station.host + offset
		actor.position = foot - Vector2i(24, 72)
		actor.z_index = foot.y
		actor.show()
		station.foot = foot
		check(not (station.p.floor as Rect2i).has_point(offset), station.id + " actor feet outside physical body")
		check(model.is_floor(model.cell_at(Vector2(foot))), station.id + " actor reference stays on room floor")

func walkaround(id: String) -> void:
	header.text = "ARCHIVE · %s walkaround · scripted native sprite path, canonical navigation tested separately" % id
	var corners: Array[Vector2i] = [Vector2i(-80, -64), Vector2i(80, -64), Vector2i(80, 64), Vector2i(-80, 64), Vector2i(-80, -64)]
	var directions: Array[String] = ["east", "south", "west", "north"]
	var step := 0
	for edge: int in range(4):
		var from := corners[edge]
		var to := corners[edge + 1]
		var ticks := int(from.distance_to(to)) / 4
		for tick: int in range(ticks + 1):
			var offset := Vector2i(Vector2(from).lerp(Vector2(to), float(tick) / ticks))
			for station: Dictionary in stations:
				var actor: Sprite2D = station.actor
				actor.texture = CharacterArt.locomotion_sheet(id)
				actor.region_rect = CharacterArt.locomotion_region(GAZES[directions[edge]], 2 + int(step / 3) % 4)
				station.foot = station.host + offset
				actor.position = Vector2i(station.foot) - Vector2i(24, 72)
				actor.z_index = station.foot.y
				actor.show()
				check(not (station.p.floor as Rect2i).has_point(offset) and model.is_floor(model.cell_at(Vector2(station.foot))), station.id + " scripted walk feet do not cross furniture or walls")
			await settle(1)
			var shot := root.get_texture().get_image()
			for station: Dictionary in stations:
				verify_depth(shot, station, id + "-walk-" + str(step))
			step += 1
		await capture(id + "-walk-edge" + str(edge))

func corner_study() -> void:
	for panel: PanelContainer in labels:
		panel.hide()
	var panel := header.get_parent() as PanelContainer
	panel.show()
	panel.position = Vector2(200, 344)
	panel.custom_minimum_size.x = 896
	header.text = "ARCHIVE · near walls/corners · full opaque art and service cells remain on floor"
	var corners := {"north": Vector2i(80, 176), "east": Vector2i(1072, 208), "south": Vector2i(1072, 624), "west": Vector2i(80, 592)}
	for station: Dictionary in stations:
		station.actor.hide()
		station.cabinet.visible = station.finish == "powdercoat"
		if station.finish == "powdercoat":
			station.host = corners[station.side]
			station.cabinet.position = station.host
			station.cabinet.z_index = station.host.y
			check(inside_room(station.p, station.host), station.id + " near-wall assembly stays in actual room")
	await capture("wall-corners-empty")
	# Move the north service point one row inward for face/headroom. Collision
	# alone permits the nearer point, but its actor projects over the wainscot.
	for station: Dictionary in stations:
		if station.side == "north" and station.finish == "powdercoat":
			station.host.y += 32
			station.cabinet.position = station.host
			station.cabinet.z_index = station.host.y
	set_actors("mira", "service")
	for station: Dictionary in stations:
		if station.finish == "oak": station.actor.hide()
	header.text = "ARCHIVE · service-side approaches · north moved one row inward for character headroom"
	await capture("wall-corners-service")

func verify_depth(shot: Image, station: Dictionary, checkpoint: String) -> void:
	var actor: Sprite2D = station.actor
	if not actor.visible:
		return
	var pose := actor.texture.get_image().get_region(Rect2i(actor.region_rect))
	var hidden := 0
	var mismatches := 0
	var samples := 0
	for y: int in range(80):
		for x: int in range(48):
			var color := pose.get_pixel(x, y)
			if color.a < 0.99:
				continue
			var point := Vector2i(actor.position) + Vector2i(x, y)
			var local := point - Vector2i(station.host) + Vector2i(96, 224)
			if Rect2i(0, 0, 192, 288).has_point(local) and actor.z_index < int(station.host.y):
				var cover: Color = station.whole.get_pixelv(local)
				if cover.a > 0.99:
					color = cover
					hidden += 1
			var actual := shot.get_pixelv(point)
			if absf(actual.r - color.r) > 0.01 or absf(actual.g - color.g) > 0.01 or absf(actual.b - color.b) > 0.01:
				mismatches += 1
			samples += 1
	painted_actor_pixels += samples
	check(samples > 0 and mismatches == 0, station.id + " actual opaque actor/cabinet depth at " + checkpoint + "; mismatches=" + str(mismatches))
	depth_observations.append({"id": station.id, "checkpoint": checkpoint, "samples": samples, "hidden_by_cabinet": hidden, "mismatches": mismatches})

func capture(name_value: String, details: bool = false) -> void:
	await settle()
	var shot := root.get_texture().get_image()
	check(shot.get_size() == Vector2i(1280, 720), "Native room capture " + name_value)
	check(shot.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save native " + name_value)
	captures.append(name_value + ".png")
	for station: Dictionary in stations:
		verify_depth(shot, station, name_value)
		if details:
			var crop := shot.get_region(Rect2i(station.host + Vector2i(-96, -144), Vector2i(192, 216)))
			crop.resize(768, 864, Image.INTERPOLATE_NEAREST)
			var detail: String = name_value + "-" + station.id + "-4x.png"
			check(crop.save_png(OUTPUT.path_join(detail)) == OK, "Save nearest detail " + detail)
			captures.append(detail)
	for panel: PanelContainer in labels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Labels remain in native viewport")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT))
	preflight()
	var rendered := DisplayServer.get_name() != "headless"
	if rendered and failures.is_empty():
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		build()
		await export_layers()
		await capture("all-four-materials", true)
		for id: String in ["mira", "theo"]:
			for mode: String in ["scale", "service", "rear", "front", "left", "right"]:
				set_actors(id, mode)
				header.text = "ARCHIVE · %s / %s · real native depth references, not interaction proof" % [id, mode]
				await capture(id + "-" + mode, mode == "service")
			await walkaround(id)
		await corner_study()
		stage.free()
		canvas.free()
		await process_frame
	for path: String in source_hashes:
		check(FileAccess.get_sha256(path) == source_hashes[path], "Original face/material unchanged " + path)
	var data := {"checks": checks, "failures": failures, "captures": captures, "exports": exports, "depth_observations": depth_observations, "actor_pixels_checked": painted_actor_pixels, "scripted_frames": frames, "source_sha256": source_hashes, "runtime_approved": false, "worker_disabled": true, "save_access": false, "limitations": ["TownRoom native volume/face/depth showroom; canonical GameMain/nav/editor service integration is a separate explicit gate.", "Actor sprites are depth/scale references, not a new cabinet-use animation.", "Production furniture and default bare helper appearance remain unchanged."]}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	if rendered:
		var export_file := FileAccess.open(EXPORT.path_join("manifest.json"), FileAccess.WRITE)
		export_file.store_string(JSON.stringify({"exports": exports, "runtime_approved": false, "source_evidence": OUTPUT + "/manifest.json"}, "\t"))
	print("Archive assembly: %d checks, %d failures, %d captures; staged only." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
