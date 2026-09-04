extends SceneTree

const EDITOR_SCRIPT: Script = preload("res://tools/office_layout_editor.gd")

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	root.title = "Startup Valley — Developer Office Layout"
	root.size = Vector2i(1600, 800)
	root.content_scale_size = Vector2i(1600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	var editor := Node2D.new()
	editor.set_script(EDITOR_SCRIPT)
	root.add_child(editor)
