extends SceneTree

const Inventory = preload("res://tools/polish_inventory_layers.gd")
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

func run() -> void:
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	check(room.load_layout(), "Disposable room loads the actual production layout")
	room.set_hire_count(4)
	var baseline: Dictionary = Inventory.collect(room)
	check(baseline.errors.is_empty(), "Every actual canonical render layer has exact art/region/anchor/native transform")
	check(not baseline.expected.is_empty() and baseline.expected.size() == baseline.records.size(), "Every declaration has one live record")
	var archive_count := 0
	var target: Sprite2D
	for record: Dictionary in baseline.records:
		if record.placementId == "artifact-archive":
			archive_count += 1
			target = record.sprite
	check(archive_count == 5, "All five archive layers are inspected, not only a legacy sprite name")
	check(target != null, "Archive has a live target for failure injection")
	if target != null:
		var parent := target.get_parent()
		parent.remove_child(target)
		var missing: Dictionary = Inventory.collect(room)
		check(missing.records.size() == baseline.records.size() - 1 and missing.errors.size() == 1, "A missing live layer fails coverage rather than passing a total-count threshold")
		parent.add_child(target)
		target.scale = Vector2(0.5, 0.5)
		check(not Inventory.collect(room).errors.is_empty(), "Arbitrary runtime downscaling is detected")
		target.scale = Vector2.ONE
		target.flip_h = true
		check(not Inventory.collect(room).errors.is_empty(), "Mirroring a declared view is detected")
		target.flip_h = false
		var offset := target.position
		target.position += Vector2.ONE
		check(not Inventory.collect(room).errors.is_empty(), "Unregistered layer offset is detected")
		target.position = offset
		var region := target.region_rect
		target.region_rect.size.x -= 1
		check(not Inventory.collect(room).errors.is_empty(), "Wrong atlas crop is detected")
		target.region_rect = region
		check(Inventory.collect(room).errors.is_empty(), "Restoration returns the complete valid inventory")
	room.navigation.free()
	room.free()
	print("Polish inventory layers: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
