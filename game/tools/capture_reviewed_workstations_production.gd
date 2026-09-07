extends SceneTree
## Native evidence for the exact production catalogue -> TownRoom -> actor path.

const OUTPUT := "res://tests/output/reviewed-workstations-production"
const FACINGS: Array[String] = ["north", "east", "south", "west"]

var main: GameMain
var captures: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 2) -> void:
	for _index: int in range(count): await process_frame

func capture(label: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var path := OUTPUT.path_join(label + ".png")
	check(image.get_size() == Vector2i(1280, 720), label + " is native 1280x720")
	check(image.save_png(path) == OK, "Saved " + label)
	captures.append({"label": label, "path": path, "sha256": FileAccess.get_sha256(path)})
	return image

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames(3)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "No worker started")
	var images: Array[Image] = []
	for facing: String in FACINGS:
		check(main.room.set_placement_overrides({
			"mira-workstation": {"grid": [10, 8], "facing": facing},
			"theo-workstation": {"grid": [20, 8], "facing": facing},
		}), "Production room accepted " + facing)
		main._on_room_placements_changed()
		for employee_id: String in ["mira", "theo"]:
			var actor := main.get_employee(employee_id)
			actor.set_physics_process(false)
			actor.position = actor.desk_position
			actor.navigation.actors[employee_id] = actor.position
			actor._has_target = false
			actor.has_live_job = true
			actor.work_state = EmployeeAvatar.WorkState.TYPING
			actor._activity = &"typing"
			actor._update_character_frame()
			actor._physics_process(0.14)
			check(str(actor._workstation_visual.get("workstation_capability_revision", "")) == "workstations-v2:" + facing, "%s uses exact %s capability" % [employee_id, facing])
			check(actor._seat_transition_preview and not actor._seat_transition_active, "%s completed reviewed %s seat handoff" % [employee_id, facing])
		await frames()
		images.append(await capture("production-" + facing))
	var contact := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for index: int in range(images.size()):
		var tile := images[index].duplicate()
		tile.resize(640, 360, Image.INTERPOLATE_NEAREST)
		contact.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i((index % 2) * 640, (index / 2) * 360))
	check(contact.save_png(OUTPUT.path_join("production-four-facing-contact-sheet.png")) == OK, "Saved production contact sheet")
	var manifest := {
		"status": "reviewed production runtime evidence",
		"renderer": DisplayServer.get_name(),
		"worker_disabled": true,
		"personal_save_access": false,
		"facings": FACINGS,
		"captures": captures,
		"contact_sheet": OUTPUT.path_join("production-four-facing-contact-sheet.png"),
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	main.game_audio.shutdown()
	main.free()
	print("Reviewed workstation production capture: %d images, %d failures" % [captures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
