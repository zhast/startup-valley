extends RefCounted
## DEV ONLY. Source-preserving coffee composition, not a furniture registry entry.
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const SOURCE := "res://assets/source/overnight-20260904/kits/coffee-service-south-v4.png"
const PREFIX := "res://tests/fixtures/furniture-calibration/kits/coffee-service-south-v4"
const CANVAS := Vector2i(192, 256)
const PIVOT := Vector2i(96, 192)
const PARTS: Array[String] = ["espresso", "grinder", "mug", "plant"]
const BOUNDS := {
	"espresso": Rect2i(56, 116, 29, 44), "grinder": Rect2i(94, 130, 12, 30),
	"mug": Rect2i(109, 161, 10, 10), "plant": Rect2i(121, 136, 16, 24),
}
const CROPS := {
	"espresso": Rect2i(235, 156, 367, 548), "grinder": Rect2i(745, 205, 184, 448),
	"mug": Rect2i(1055, 437, 193, 196), "plant": Rect2i(1321, 280, 248, 365),
}
# Conservative support hypotheses in host-floor coordinates, not alpha bounds,
# collision, or a claim to recover hidden geometry from a single front view.
const CONTACTS := {
	"espresso": Rect2i(-40, -45, 29, 13), "grinder": Rect2i(-2, -38, 12, 6),
	"mug": Rect2i(14, -25, 7, 4), "plant": Rect2i(26, -43, 14, 11),
}

static func path(part: String = "") -> String:
	return PREFIX + ("-" + part if not part.is_empty() else "") + ".png"

static func image(part: String = "") -> Image:
	return PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path(part))))

static func texture(part: String = "") -> Texture2D:
	return ImageTexture.create_from_image(image(part))

static func records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for part: String in PARTS:
		result.append({"part": part, "path": path(part), "sha256": FileAccess.get_sha256(path(part)),
			"alpha": PIXELS.analyze(image(part)), "contact_hypothesis": PIXELS.rect_values(CONTACTS[part]),
			"contact_measured_from_hidden_geometry": false, "runtime_approved": false})
	return result

static func build(parent: Node, anchor: Vector2, horizontal: Texture2D, vertical: Texture2D, with_kit: bool) -> Node2D:
	var host := Node2D.new()
	host.position = anchor
	host.z_as_relative = false
	host.z_index = int(anchor.y)
	parent.add_child(host)
	var cabinet := CABINET.new()
	host.add_child(cabinet)
	if not cabinet.configure("counter", "south", horizontal, vertical):
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
			# A solid service cabinet plus its appliances is one floor-sorted
			# assembly. A north actor is honestly hidden by the opaque assembly.
			sprite.z_index = 0
			host.add_child(sprite)
	return host
