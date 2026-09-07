extends SceneTree
## Mechanical registration only; the frozen blank whiteboard exports stay intact.
func _initialize() -> void:
	var source := Image.load_from_file("res://tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png")
	if source == null or source.get_size() != Vector2i(80, 48): quit(1); return
	source.convert(Image.FORMAT_RGBA8)
	var registered := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	registered.fill(Color.TRANSPARENT)
	registered.blit_rect(source, Rect2i(0, 0, 80, 48), Vector2i(56, 86))
	var path := "res://tests/fixtures/furniture-calibration/passive-furniture-v1/whiteboard-south-planning.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if registered.get_region(Rect2i(56, 86, 80, 48)).get_data() != source.get_data(): quit(1); return
	var result := registered.save_png(path)
	print("Passive planning insert: exact80×48 source registered at56,86; no scaling/repainting; result=", result)
	quit(0 if result == OK else 1)
