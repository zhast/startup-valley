class_name WindowPresentation
extends RefCounted
## Pure startup sizing policy. The authored viewport always remains 1280 × 720.
## macOS window and screen coordinates use the greatest connected display scale.

const LOGICAL_SIZE := Vector2i(1280, 720)
const MARGIN_POINTS := 24

static func should_adapt(platform: String, display_server: String, mode: int, arguments: PackedStringArray) -> bool:
	if platform != "macOS" or display_server == "headless" or mode != Window.MODE_WINDOWED:
		return false
	# A developer play script can opt in by setting SceneTree.current_scene.
	# Explicit geometry, movie capture, and embedded/editor windows are never resized.
	var overrides := ["--resolution", "--position", "--write-movie", "--embedded", "--editor", "-e", "--project-manager", "-p", "--fullscreen", "-f", "--maximized", "-m"]
	for argument: String in arguments:
		if argument == "--": break
		for flag: String in overrides:
			if argument == flag or argument.begins_with(flag + "="):
				return false
	return true

static func initial_rect(usable: Rect2i, display_scale: float, decorations: Vector2i = Vector2i.ZERO) -> Rect2i:
	if not usable.has_area(): return Rect2i()
	var scale := display_scale
	if is_nan(scale) or is_inf(scale) or scale < 1.0 or scale > 4.0:
		scale = 1.0
	var chrome := Vector2i(maxi(0, decorations.x), maxi(0, decorations.y))
	var margin := Vector2i.ONE * roundi(MARGIN_POINTS * scale)
	var available := usable.size - margin * 2 - chrome
	if available.x < 16 or available.y < 9: return Rect2i()
	var desired := Vector2(LOGICAL_SIZE) * scale
	# Whole 16:9 units avoid rounding one axis into an accidental letterbox.
	var units := floori(minf(minf(desired.x / 16.0, desired.y / 9.0), minf(available.x / 16.0, available.y / 9.0)))
	var size := Vector2i(16 * units, 9 * units)
	var position := usable.position + (usable.size - size - chrome) / 2
	return Rect2i(position, size)
