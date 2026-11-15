class_name OfficeDaylight
extends Node2D
## Static window light: only floor pixels, below furniture and characters.
## This is presentation. It never adds floor, collision, or an outside exit.

var architecture: OfficeArchitecture
var patches: Array[Dictionary] = []

func configure(model: OfficeLayout, source: OfficeArchitecture) -> void:
	architecture = source
	patches.clear()
	if model == null: return
	for window: Dictionary in model.data.get("windows", []):
		if str(window.get("facing", "north")) != "north": continue
		var cell := OfficeLayout.vector(window.get("grid", [0, 0]))
		var start := Vector2(cell.x, cell.y + int(window.get("height", 3))) * model.tile_size
		var width := float(int(window.get("width", 5)) * model.tile_size)
		# Three panes match the existing native window modules. Soft falloff is
		# stepped rather than blurred, keeping the room's pixel-art treatment.
		for pane: int in range(3):
			var left := 12.0 + pane * (width - 20.0) / 3.0
			var right := left + (width - 20.0) / 3.0 - 8.0
			for band: int in range(4):
				var near_y := float(band * 40)
				var far_y := near_y + 40.0
				var shape := PackedVector2Array([
					(start + Vector2(left + near_y * 0.3, near_y)).round(),
					(start + Vector2(right + near_y * 0.3, near_y)).round(),
					(start + Vector2(right + far_y * 0.3, far_y)).round(),
					(start + Vector2(left + far_y * 0.3, far_y)).round(),
				])
				_clip_to_floor(model, shape, 0.17 - band * 0.035)
	queue_redraw()

func _clip_to_floor(model: OfficeLayout, shape: PackedVector2Array, opacity: float) -> void:
	var bounds := Rect2(shape[0], Vector2.ZERO)
	for point: Vector2 in shape: bounds = bounds.expand(point)
	for cell: Vector2i in model.floor_cells():
		var area := Rect2(Vector2(cell * model.tile_size), Vector2.ONE * model.tile_size)
		if not area.intersects(bounds): continue
		var tile := PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])
		for polygon: PackedVector2Array in Geometry2D.intersect_polygons(shape, tile):
			if polygon.size() < 3: continue
			patches.append({"polygon": polygon, "opacity": opacity, "floor_cell": cell})

func _draw() -> void:
	if architecture == null or architecture.blockout: return
	var evening := architecture.theme_id == "evening"
	for patch: Dictionary in patches:
		var tint := Color("d4e0ed") if evening else Color("ffe9ac")
		tint.a = float(patch.opacity) * (0.32 if evening else 1.0)
		draw_colored_polygon(patch.polygon, tint)
