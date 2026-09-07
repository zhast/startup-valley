extends RefCounted
## DEV ONLY. Independent true rear appliances on the unchanged exact counter.
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const SOURCE := "res://assets/source/overnight-20260904/kits/coffee-service-north-v2.png"
const PREFIX := "res://tests/fixtures/furniture-calibration/kits/coffee-service-north-v2"
const CANVAS := Vector2i(192, 256)
const PIVOT := Vector2i(96, 192)
const PARTS: Array[String] = ["espresso", "grinder", "mug", "plant"]
const BOUNDS := {"espresso": Rect2i(107, 129, 28, 44), "grinder": Rect2i(86, 136, 12, 30), "mug": Rect2i(72, 143, 10, 10), "plant": Rect2i(55, 147, 15, 24)}
const CROPS := {"espresso": Rect2i(197, 155, 355, 555), "grinder": Rect2i(702, 202, 195, 474), "mug": Rect2i(1009, 440, 208, 206), "plant": Rect2i(1330, 253, 246, 403)}
# Parent's physical support hypotheses, not alpha/collision or recovered3D.
# Rotate the S floor-plane contact around the floor pivot, not the raised image.
const CONTACTS := {"espresso": Rect2i(11, -32, 28, 13), "grinder": Rect2i(-10, -32, 12, 6), "mug": Rect2i(-21, -43, 7, 4), "plant": Rect2i(-40, -32, 14, 11)}

static func path(part: String = "") -> String:
	return PREFIX + ("-" + part if not part.is_empty() else "") + ".png"

static func image(part: String = "") -> Image:
	return PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path(part))))

static func texture(part: String = "") -> Texture2D:
	return ImageTexture.create_from_image(image(part))

static func records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for part: String in PARTS:
		result.append({"part": part, "path": path(part), "sha256": FileAccess.get_sha256(path(part)), "alpha": PIXELS.analyze(image(part)), "contact_hypothesis": PIXELS.rect_values(CONTACTS[part]), "contact_measured_from_hidden_geometry": false, "runtime_approved": false})
	return result

static func build(parent: Node, anchor: Vector2, horizontal: Texture2D, vertical: Texture2D, with_kit: bool) -> Node2D:
	var host := Node2D.new()
	host.position = anchor
	host.z_as_relative = false
	host.z_index = int(anchor.y)
	parent.add_child(host)
	var cabinet := CABINET.new()
	host.add_child(cabinet)
	if not cabinet.configure("counter", "north", horizontal, vertical):
		host.free()
		return null
	if with_kit:
		for part: String in PARTS:
			var sprite := Sprite2D.new()
			sprite.name = part.capitalize()
			sprite.texture = texture(part)
			sprite.position = -Vector2(PIVOT)
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.z_index = 0
			host.add_child(sprite)
	return host
