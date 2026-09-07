extends "res://tools/calibrated_workstation_fixture.gd"
## DEV ONLY. Unapproved resting legal decor through real GameMain/TownRoom.
## The plain east workstation may still be inspected; no legal east kit exists.
const LEGAL_DIRECTIONS: Array[String] = ["north", "south", "west"]
const PARTS: Array[String] = ["binders", "folder", "pen_cup"]
const KIT := {
	"north": {"prefix": "lawyer-north-v3", "suffix": "-brand", "union": "lawyer-north-v3-brand.png", "contacts": {"binders": Rect2i(54, 116, 20, 12), "folder": Rect2i(114, 118, 26, 19), "pen_cup": Rect2i(60, 138, 7, 3)}},
	"south": {"prefix": "lawyer-south-v2", "suffix": "", "union": "lawyer-south-v2.png", "contacts": {"binders": Rect2i(122, 117, 20, 12), "folder": Rect2i(51, 117, 26, 18), "pen_cup": Rect2i(126, 140, 7, 3)}},
	"west": {"prefix": "lawyer-west-reclassified-v4", "suffix": "", "union": "lawyer-west-reclassified-v4.png", "contacts": {"binders": Rect2i(86, 82, 12, 20), "folder": Rect2i(83, 147, 19, 27), "pen_cup": Rect2i(103, 83, 6, 3)}},
}
var use_corrected_clearance := false

static func part_shift(direction: String, part: String, corrected: bool) -> Vector2i:
	if not corrected: return Vector2i.ZERO
	if direction == "north" and part == "folder": return Vector2i(0, -4)
	if direction == "south" and part == "pen_cup": return Vector2i(0, -1)
	return Vector2i.ZERO

static func kit_path(direction: String, part: String = "") -> String:
	if direction not in LEGAL_DIRECTIONS:
		return ""
	var description: Dictionary = KIT[direction]
	return FIX + "roles/" + (str(description.union) if part.is_empty() else "%s-%s%s.png" % [description.prefix, part, description.suffix])

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	if facing not in LEGAL_DIRECTIONS:
		result.calibration_limitations.append("Legal east artwork is unavailable. This is only the ordinary computer base.")
		return result
	var render_layers: Array = result.render_layers
	if facing == "south":
		for entry: Dictionary in render_layers:
			if entry.name == "Mouse":
				entry.offset[0] += 45 # Complete existing mouse moves69→114; no source change.
				if use_corrected_clearance: entry.offset[1] += 1
	for part: String in PARTS:
		var path := kit_path(facing, part).trim_prefix(FIX)
		render_layers.append(layer("Legal" + part.capitalize().replace("_", ""), path, Vector2i(192, 224), Vector2i(96, 160), part_shift(facing, part, use_corrected_clearance), 3))
	var bounds := Rect2()
	for entry: Dictionary in render_layers:
		var region := OfficeLayout.rectangle(entry.region)
		var origin := Vector2(OfficeLayout.vector(entry.offset)) - region.size * 0.5
		var ink := OfficeLayout.measured_layer_ink_bounds(entry)
		if ink.has_area():
			var placed := Rect2(origin + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
	result.visual_bounds = [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)]
	result.hit_bounds = result.visual_bounds.duplicate()
	result.calibration_limitations.append("Resting legal-themed decoration, no document-use animation or legal backend.")
	if facing == "west":
		result.calibration_limitations.append("Reclassified old east source: west-like leaves/spines, wrong outer tabs and unproven pen order/page markings; cleanup required.")
	return result
