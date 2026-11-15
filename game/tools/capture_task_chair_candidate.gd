extends "res://tests/test_seated_chair_composition.gd"
## Uses actual production assembly and the existing48-pose pixel regression,
## substituting only candidate chair textures after each real layout change.

func capture(facing: String, state_name: String) -> void:
	if state_name == "empty":
		for id: String in ["mira", "theo"]:
			var prop := main.room.prop_node(id + "-workstation")
			for child: Node in prop.get_children():
				if child is not Sprite2D or not str(child.name).begins_with("Chair"): continue
				var suffix := "-rear" if str(child.name) == "ChairRear" else "-front" if str(child.name) == "ChairNearArm" else ""
				var path := "res://assets/source/task-chair-v3/candidate/chair-" + facing + suffix + ".png"
				var bitmap := Image.load_from_file(ProjectSettings.globalize_path(path))
				child.texture = ImageTexture.create_from_image(bitmap)
	await super.capture(facing, state_name)
