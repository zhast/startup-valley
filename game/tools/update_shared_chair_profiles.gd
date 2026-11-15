extends SceneTree
## Refresh only collaboration visual bindings after the shared chair rebuild.
## No cell, seat socket, actor anchor, depth, or table source is changed.
const CATALOG := "res://data/furniture_catalog.json"
const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")

func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	for side: String in GEOMETRY.SIDES:
		var profile: Dictionary = catalog.furniture.collaboration_cluster.facing_profiles[side]
		profile.render_layers = GEOMETRY.cluster_specs(side, "res://assets/runtime/office/collaboration-cluster-v2")
		profile.visual_bounds = GEOMETRY.cluster_visual_bounds(side)
		profile.hit_bounds = profile.visual_bounds.duplicate()
	var output := "res://assets/source/task-chair-v3/collaboration-profiles.json"
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(catalog.furniture.collaboration_cluster.facing_profiles, "  ") + "\n")
	print("Shared chair profile candidate: " + output)
	quit()
