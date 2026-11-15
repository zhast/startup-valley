extends SceneTree
## Retained ImageGen chair normalization. Candidate-only unless --apply is set.
const SOURCE := "res://assets/source/task-chair-v3/"
const RUNTIME := "res://assets/runtime/office/workstations-v2/"
const MODULES := ["chair-north", "chair-south", "chair-east-rear", "chair-east-front", "chair-west-rear", "chair-west-front"]
const VIEWS := {
	"south": Rect2i(106, 178, 273, 480),
	"north": Rect2i(591, 178, 277, 480),
	"east": Rect2i(1059, 178, 302, 480),
	"west": Rect2i(1553, 178, 299, 480),
}

func _initialize() -> void:
	var raw := Image.load_from_file(SOURCE + "generated-four-views.png")
	raw.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE + "candidate"))
	for facing: String in VIEWS:
		var ink := raw.get_region(VIEWS[facing])
		ink.resize(32, 58, Image.INTERPOLATE_NEAREST)
		for y: int in range(58):
			for x: int in range(32):
				var color := ink.get_pixel(x, y)
				color.a = 1.0 if color.a >= 0.5 else 0.0
				if color.a == 0: color = Color.TRANSPARENT
				ink.set_pixel(x, y, color)
		var whole := Image.create(96, 160, false, Image.FORMAT_RGBA8)
		# The generated back was too tall (58px above its visible feet). Keep
		# the already aligned cushion/legs pixel-exact and shorten only the
		# upper back to a 42px rise, preserving all actor hip/hand anchors.
		var back := ink.get_region(Rect2i(0, 0, 32, 29))
		back.resize(32, 14, Image.INTERPOLATE_NEAREST)
		whole.blit_rect(back, Rect2i(0, 0, 32, 14), Vector2i(32, 85))
		whole.blit_rect(ink, Rect2i(0, 29, 32, 29), Vector2i(32, 99))
		whole.save_png(SOURCE + "candidate/chair-" + facing + ".png")
		if facing in ["east", "west"]:
			# Near seat rail/legs replace the former near-arm layer. Keeping the
			# registered layer lets the actual body pass behind the near frame.
			var near := Image.create(96, 160, false, Image.FORMAT_RGBA8)
			near.blit_rect(whole, Rect2i(0, 109, 96, 51), Vector2i(0, 109))
			whole.save_png(SOURCE + "candidate/chair-" + facing + "-rear.png")
			near.save_png(SOURCE + "candidate/chair-" + facing + "-front.png")
	if "--apply" in OS.get_cmdline_user_args():
		for name: String in MODULES:
			var error := DirAccess.copy_absolute(ProjectSettings.globalize_path(SOURCE + "candidate/" + name + ".png"), ProjectSettings.globalize_path(RUNTIME + name + ".png"))
			if error != OK:
				push_error("Cannot install chair: " + name)
				quit(1)
				return
	if "--verify" in OS.get_cmdline_user_args():
		for name: String in MODULES:
			if FileAccess.get_sha256(SOURCE + "candidate/" + name + ".png") != FileAccess.get_sha256(RUNTIME + name + ".png"):
				push_error("Runtime chair differs from reproducible source: " + name)
				quit(1)
				return
		print("Six runtime chair modules reproduce byte-for-byte")
	print("Task chair: four views, six registered layers; applied=" + str("--apply" in OS.get_cmdline_user_args()))
	quit()
