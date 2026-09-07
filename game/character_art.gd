class_name CharacterArt
extends RefCounted

const CHARACTER_SHEET: Texture2D = preload("res://assets/concepts/office-town-characters-sheet.png")
const FOUNDER_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/founder-locomotion.png")
const MIRA_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/mira-locomotion.png")
const THEO_LOCOMOTION: Texture2D = preload("res://assets/runtime/characters/theo-locomotion.png")
const MIRA_WORK: Texture2D = preload("res://assets/runtime/characters/mira-work.png")
const THEO_WORK: Texture2D = preload("res://assets/runtime/characters/theo-work.png")
const MIRA_SEATED: Texture2D = preload("res://assets/runtime/characters/mira-seated.png")
const THEO_SEATED: Texture2D = preload("res://assets/runtime/characters/theo-seated.png")
const MIRA_WORKSTATIONS_V2_NORTH: Texture2D = preload("res://assets/runtime/characters/workstations-v2/mira-north.png")
const THEO_WORKSTATIONS_V2_NORTH: Texture2D = preload("res://assets/runtime/characters/workstations-v2/theo-north.png")
const MIRA_WORKSTATIONS_V2_EAST: Texture2D = preload("res://assets/runtime/characters/workstations-v2/mira-east.png")
const THEO_WORKSTATIONS_V2_EAST: Texture2D = preload("res://assets/runtime/characters/workstations-v2/theo-east.png")
const MIRA_WORKSTATIONS_V2_WEST: Texture2D = preload("res://assets/runtime/characters/workstations-v2/mira-west.png")
const THEO_WORKSTATIONS_V2_WEST: Texture2D = preload("res://assets/runtime/characters/workstations-v2/theo-west.png")
const MIRA_RESEARCH_NORTH: Texture2D = preload("res://assets/runtime/characters/research-v1/mira-north.png")
const MIRA_RESEARCH_EAST: Texture2D = preload("res://assets/runtime/characters/research-v1/mira-east.png")
const MIRA_RESEARCH_SOUTH: Texture2D = preload("res://assets/runtime/characters/research-v1/mira-south.png")
const MIRA_RESEARCH_WEST: Texture2D = preload("res://assets/runtime/characters/research-v1/mira-west.png")
const THEO_RESEARCH_NORTH: Texture2D = preload("res://assets/runtime/characters/research-v1/theo-north.png")
const THEO_RESEARCH_EAST: Texture2D = preload("res://assets/runtime/characters/research-v1/theo-east.png")
const THEO_RESEARCH_SOUTH: Texture2D = preload("res://assets/runtime/characters/research-v1/theo-south.png")
const THEO_RESEARCH_WEST: Texture2D = preload("res://assets/runtime/characters/research-v1/theo-west.png")
const FRAME_SIZE := Vector2(48.0, 80.0)
const CHAT_FACE_REGION := Rect2(8.0, 4.0, 32.0, 32.0)
const LEGACY_WORK_POSE_SET := "legacy-office-v1"
const REVIEWED_WORKSTATION_POSE_SET := "reviewed-workstations-v2"
const REVIEWED_COLLABORATION_REVISION := "collaboration-cluster-v2"
const WORK_FACINGS: Array[String] = ["north", "east", "south", "west"]
const REVIEWED_CAPABILITY_FIELDS: Array[String] = [
	"revision", "asset_revision", "employees", "seat_pose_depth_lock",
	"seat_state_handoff", "grounded_work_shadow",
	"grounded_work_shadow_follow_seat_x", "thinking_reuses_seated",
	"work_vfx_poses",
]

# Only reviewed, actually authored sheets belong here. Locomotion having four
# directions does not grant those directions seated/typing/research support.
# Future sets add explicit per-facing regions and character sheets; no raster
# rotation, mirroring, or fallback to another person's poses is permitted.
const WORK_POSE_SETS: Dictionary = {
	LEGACY_WORK_POSE_SET: {
		"characters": {
			"mira": {"seated": MIRA_SEATED, "work": MIRA_WORK},
			"theo": {"seated": THEO_SEATED, "work": THEO_WORK},
		},
		"facings": {
			"south": {
				"seated": {"sheet": "seated", "row": 0, "column": 0, "frames": 2},
				"typing": {"sheet": "seated", "row": 0, "column": 2, "frames": 4},
				"research": {"sheet": "work", "row": 1, "column": 0, "frames": 4},
				"thinking": {"sheet": "work", "row": 1, "column": 4, "frames": 4},
				"approval": {"sheet": "work", "row": 0, "column": 6, "frames": 2},
			},
		},
	},
	# This registry is deliberately code-owned rather than data-authored. The
	# furniture catalogue may request these capabilities, but review booleans or
	# a copied pose-set name cannot manufacture them. Every referenced bitmap is
	# a byte-exact runtime copy of its accepted directional evidence source.
	REVIEWED_WORKSTATION_POSE_SET: {
		"status": "runtime_ready",
		"asset_revision": "workstations-v2",
		"review": {"art": true, "geometry": true, "poses": true},
		"characters": {
			"mira": {"north": MIRA_WORKSTATIONS_V2_NORTH, "east": MIRA_WORKSTATIONS_V2_EAST, "south": MIRA_SEATED, "west": MIRA_WORKSTATIONS_V2_WEST, "research_north": MIRA_RESEARCH_NORTH, "research_east": MIRA_RESEARCH_EAST, "research_south": MIRA_RESEARCH_SOUTH, "research_west": MIRA_RESEARCH_WEST},
			"theo": {"north": THEO_WORKSTATIONS_V2_NORTH, "east": THEO_WORKSTATIONS_V2_EAST, "south": THEO_SEATED, "west": THEO_WORKSTATIONS_V2_WEST, "research_north": THEO_RESEARCH_NORTH, "research_east": THEO_RESEARCH_EAST, "research_south": THEO_RESEARCH_SOUTH, "research_west": THEO_RESEARCH_WEST},
		},
		"facings": {
			"north": {
				"seated": {
					"sheet": "north", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [48, 48], "theo": [48, 48]},
				},
				"typing": {
					"sheet": "north", "row": 0, "column": 2, "frames": 4,
					"cuts_by_character": {"mira": [48, 48, 48, 48], "theo": [48, 48, 48, 48]},
					"work_vfx_anchor_by_character": {"mira": [0, -89], "theo": [0, -89]},
				},
				"thinking": {
					"sheet": "north", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [48, 48], "theo": [48, 48]},
					"reuse_pose": "seated", "presentation": "quiet_seated_thinking",
					"work_vfx_anchor_by_character": {"mira": [0, -89], "theo": [0, -89]},
				},
				"research": {"sheet": "research_north", "row": 0, "column": 0, "frames": 4},
			},
			"east": {
				"seated": {
					"sheet": "east", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [52, 52], "theo": [52, 52]},
				},
				"typing": {
					"sheet": "east", "row": 0, "column": 2, "frames": 4,
					"cuts_by_character": {"mira": [52, 52, 52, 52], "theo": [52, 52, 52, 52]},
					"work_vfx_anchor_by_character": {"mira": [-20, -96], "theo": [-20, -96]},
				},
				"thinking": {
					"sheet": "east", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [52, 52], "theo": [52, 52]},
					"reuse_pose": "seated", "presentation": "quiet_seated_thinking",
					"work_vfx_anchor_by_character": {"mira": [-20, -96], "theo": [-20, -96]},
				},
				"research": {"sheet": "research_east", "row": 0, "column": 0, "frames": 4},
			},
			"south": {
				"seated": {
					"sheet": "south", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [50, 50], "theo": [50, 50]},
				},
				"typing": {
					"sheet": "south", "row": 0, "column": 2, "frames": 4,
					"cuts_by_character": {"mira": [50, 50, 50, 50], "theo": [50, 50, 50, 50]},
					"work_vfx_anchor_by_character": {"mira": [0, -120], "theo": [0, -120]},
				},
				"thinking": {
					"sheet": "south", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [50, 50], "theo": [50, 50]},
					"reuse_pose": "seated", "presentation": "quiet_seated_thinking",
					"work_vfx_anchor_by_character": {"mira": [0, -120], "theo": [0, -120]},
				},
				"research": {"sheet": "research_south", "row": 0, "column": 0, "frames": 4},
			},
			"west": {
				"seated": {
					"sheet": "west", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [50, 50], "theo": [48, 48]},
				},
				"typing": {
					"sheet": "west", "row": 0, "column": 2, "frames": 4,
					"cuts_by_character": {"mira": [50, 50, 50, 50], "theo": [47, 47, 47, 48]},
					"work_vfx_anchor_by_character": {"mira": [20, -96], "theo": [20, -96]},
				},
				"thinking": {
					"sheet": "west", "row": 0, "column": 0, "frames": 2,
					"cuts_by_character": {"mira": [50, 50], "theo": [48, 48]},
					"reuse_pose": "seated", "presentation": "quiet_seated_thinking",
					"work_vfx_anchor_by_character": {"mira": [20, -96], "theo": [20, -96]},
				},
				"research": {"sheet": "research_west", "row": 0, "column": 0, "frames": 4},
			},
		},
		"workstation_capabilities": {
			"north": {
				"revision": "workstations-v2:north",
				"asset_revision": "workstations-v2",
				"employees": ["mira", "theo"],
				"seat_pose_depth_lock": true,
				"seat_state_handoff": {"clearance_pixels": 32},
				"grounded_work_shadow": true,
				"grounded_work_shadow_follow_seat_x": true,
				"thinking_reuses_seated": true,
				"work_vfx_poses": ["thinking", "typing"],
			},
			"east": {
				"revision": "workstations-v2:east",
				"asset_revision": "workstations-v2",
				"employees": ["mira", "theo"],
				"seat_pose_depth_lock": true,
				"seat_state_handoff": {"clearance_pixels": 32},
				"grounded_work_shadow": true,
				"grounded_work_shadow_follow_seat_x": true,
				"thinking_reuses_seated": true,
				"work_vfx_poses": ["thinking", "typing"],
			},
			"south": {
				"revision": "workstations-v2:south",
				"asset_revision": "workstations-v2",
				"employees": ["mira", "theo"],
				"seat_pose_depth_lock": true,
				"seat_state_handoff": {"clearance_pixels": 32},
				"grounded_work_shadow": true,
				"grounded_work_shadow_follow_seat_x": true,
				"thinking_reuses_seated": true,
				"work_vfx_poses": ["thinking", "typing"],
			},
			"west": {
				"revision": "workstations-v2:west",
				"asset_revision": "workstations-v2",
				"employees": ["mira", "theo"],
				"seat_pose_depth_lock": true,
				"seat_state_handoff": {"clearance_pixels": 32},
				"grounded_work_shadow": true,
				"grounded_work_shadow_follow_seat_x": true,
				"thinking_reuses_seated": true,
				"work_vfx_poses": ["thinking", "typing"],
			},
		},
	},
}

# Collaboration seating reuses only the neutral seated frames from the already
# reviewed directional workstation atlases. This separate immutable capability
# prevents a furniture JSON flag from turning typing/research art into a meeting
# pose or admitting a cluster whose table/chair revision was never reviewed.
const REVIEWED_COLLABORATION_CAPABILITIES: Dictionary = {
	"north": {"revision": "collaboration-cluster-v2:north", "furniture_asset_revision": REVIEWED_COLLABORATION_REVISION, "pose_asset_revision": "workstations-v2", "pose_set": REVIEWED_WORKSTATION_POSE_SET, "employees": ["mira", "theo"], "poses": ["seated"]},
	"east": {"revision": "collaboration-cluster-v2:east", "furniture_asset_revision": REVIEWED_COLLABORATION_REVISION, "pose_asset_revision": "workstations-v2", "pose_set": REVIEWED_WORKSTATION_POSE_SET, "employees": ["mira", "theo"], "poses": ["seated"]},
	"south": {"revision": "collaboration-cluster-v2:south", "furniture_asset_revision": REVIEWED_COLLABORATION_REVISION, "pose_asset_revision": "workstations-v2", "pose_set": REVIEWED_WORKSTATION_POSE_SET, "employees": ["mira", "theo"], "poses": ["seated"]},
	"west": {"revision": "collaboration-cluster-v2:west", "furniture_asset_revision": REVIEWED_COLLABORATION_REVISION, "pose_asset_revision": "workstations-v2", "pose_set": REVIEWED_WORKSTATION_POSE_SET, "employees": ["mira", "theo"], "poses": ["seated"]},
}

# Actual-texture calibration sets are scoped to one editor-only fixture owner.
# No production resource references staged art and legacy names cannot be replaced.
static var _calibration_pose_sets: Dictionary[String, Dictionary] = {}
static var _calibration_pose_owners: Dictionary[String, int] = {}

static func register_calibration_pose_set(id: String, definition: Dictionary, owner: Object) -> bool:
	if not OS.has_feature("editor") or owner == null or not is_instance_valid(owner): return false
	if not id.begins_with("dev-calibration-") or WORK_POSE_SETS.has(id) or _calibration_pose_sets.has(id): return false
	var characters: Variant = definition.get("characters")
	var facings: Variant = definition.get("facings")
	if not characters is Dictionary or not facings is Dictionary or characters.is_empty() or facings.is_empty(): return false
	for character_key: Variant in characters:
		if not character_key is String: return false
		var character_id := str(character_key)
		if character_id not in ["mira", "theo"] or not characters[character_id] is Dictionary: return false
		for facing_key: Variant in facings:
			if not facing_key is String: return false
			var facing := str(facing_key)
			if facing not in WORK_FACINGS or not facings[facing] is Dictionary: return false
			if facings[facing].is_empty(): return false
			for pose_key: Variant in facings[facing]:
				if not pose_key is String or str(pose_key) not in ["seated", "typing", "research", "thinking", "approval"]: return false
				var pose := str(pose_key)
				var action: Variant = facings[facing][pose]
				if not action is Dictionary: return false
				for field: String in ["frames", "row", "column"]:
					if not _native_integer(action.get(field)): return false
				if int(action.row) < 0 or int(action.column) < 0: return false
				var count := int(action.get("frames", 0))
				if count < 1 or count > 8: return false
				for frame: int in range(count):
					if _resolve_work_pose_frame(definition, character_id, facing, pose, frame).is_empty(): return false
	_calibration_pose_sets[id] = definition.duplicate(true)
	_calibration_pose_owners[id] = owner.get_instance_id()
	return true

static func unregister_calibration_pose_set(id: String, owner: Object) -> bool:
	if owner == null or not is_instance_valid(owner) or _calibration_pose_owners.get(id, -1) != owner.get_instance_id(): return false
	_calibration_pose_sets.erase(id)
	_calibration_pose_owners.erase(id)
	return true

static func _native_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

static func calibration_pose_belongs_to(id: String, owner_id: int) -> bool:
	return is_calibration_pose_set(id) and owner_id != 0 and _calibration_pose_owners.get(id, 0) == owner_id

static func is_calibration_pose_set(id: String) -> bool:
	if not OS.has_feature("editor") or not _calibration_pose_sets.has(id): return false
	if not is_instance_id_valid(_calibration_pose_owners.get(id, 0)):
		_calibration_pose_sets.erase(id)
		_calibration_pose_owners.erase(id)
		return false
	return true

# The source artwork is intentionally kept as one lossless sheet. Atlas regions let
# the office and UI share the exact same character art without derivative PNGs.
const PORTRAIT_REGIONS: Dictionary = {
	"founder": Rect2(13.0, 76.0, 112.0, 224.0),
	"mira": Rect2(14.0, 372.0, 112.0, 244.0),
	"theo": Rect2(13.0, 676.0, 112.0, 252.0),
}

const WORLD_HEIGHTS: Dictionary = {
	"founder": 68.0,
	"mira": 70.0,
	"theo": 70.0,
}

static func portrait(character_id: String) -> AtlasTexture:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	var texture := AtlasTexture.new()
	texture.atlas = CHARACTER_SHEET
	texture.region = region
	texture.filter_clip = true
	return texture

static func bust_portrait(character_id: String) -> AtlasTexture:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	var texture := AtlasTexture.new()
	texture.atlas = CHARACTER_SHEET
	texture.region = Rect2(region.position, Vector2(region.size.x, region.size.y * 0.68))
	texture.filter_clip = true
	return texture

static func chat_face(character_id: String) -> AtlasTexture:
	# Reuse the front-idle art at its authored pixel size. A native head crop
	# keeps facial features legible without shrinking a large framed bust.
	var texture := AtlasTexture.new()
	texture.atlas = locomotion_sheet(character_id)
	texture.region = CHAT_FACE_REGION
	texture.filter_clip = true
	return texture

static func world_scale(character_id: String) -> float:
	var region: Rect2 = PORTRAIT_REGIONS.get(character_id, PORTRAIT_REGIONS["founder"])
	return float(WORLD_HEIGHTS.get(character_id, 64.0)) / region.size.y

static func locomotion_sheet(character_id: String) -> Texture2D:
	match character_id:
		"mira":
			return MIRA_LOCOMOTION
		"theo":
			return THEO_LOCOMOTION
	return FOUNDER_LOCOMOTION

static func work_sheet(character_id: String) -> Texture2D:
	return THEO_WORK if character_id == "theo" else MIRA_WORK

static func seated_sheet(character_id: String) -> Texture2D:
	return THEO_SEATED if character_id == "theo" else MIRA_SEATED

static func supports_work_pose(character_id: String, pose_set: String, facing: String, pose: String = "seated") -> bool:
	return not work_pose_frame(character_id, pose_set, facing, pose, 0).is_empty()

static func reviewed_workstation_capability(pose_set: String, facing: String, revision: String = "") -> Dictionary:
	# Production admission comes from this immutable registry, not catalogue
	# review flags. Validate the complete declaration every time so a partial
	# registry edit fails closed instead of silently widening a capability.
	var registry_value: Variant = WORK_POSE_SETS.get(pose_set)
	if not registry_value is Dictionary: return {}
	var registry := registry_value as Dictionary
	if str(registry.get("status", "")) != "runtime_ready": return {}
	var review: Variant = registry.get("review")
	if not review is Dictionary: return {}
	for gate: String in ["art", "geometry", "poses"]:
		if not review.get(gate) is bool or not bool(review.get(gate)): return {}
	var capabilities: Variant = registry.get("workstation_capabilities")
	if not capabilities is Dictionary or not capabilities.get(facing) is Dictionary: return {}
	var capability: Dictionary = capabilities[facing]
	if capability.size() != REVIEWED_CAPABILITY_FIELDS.size(): return {}
	for field: String in REVIEWED_CAPABILITY_FIELDS:
		if not capability.has(field): return {}
	var capability_revision: Variant = capability.get("revision")
	var asset_revision: Variant = capability.get("asset_revision")
	if not capability_revision is String or str(capability_revision).is_empty(): return {}
	if not revision.is_empty() and revision != str(capability_revision): return {}
	if not asset_revision is String or str(asset_revision).is_empty() or str(registry.get("asset_revision", "")) != str(asset_revision): return {}
	var employees: Variant = capability.get("employees")
	if not employees is Array or employees != ["mira", "theo"]: return {}
	for option: String in ["seat_pose_depth_lock", "grounded_work_shadow", "grounded_work_shadow_follow_seat_x", "thinking_reuses_seated"]:
		if not capability.get(option) is bool or not bool(capability.get(option)): return {}
	var handoff: Variant = capability.get("seat_state_handoff")
	if not handoff is Dictionary or handoff.size() != 1 or not _native_integer(handoff.get("clearance_pixels")) or int(handoff.clearance_pixels) < 1 or int(handoff.clearance_pixels) > 128: return {}
	var vfx_poses: Variant = capability.get("work_vfx_poses")
	if not vfx_poses is Array or vfx_poses != ["thinking", "typing"]: return {}
	var characters: Variant = registry.get("characters")
	if not characters is Dictionary or characters.size() != employees.size(): return {}
	for employee_id: String in employees:
		if not characters.get(employee_id) is Dictionary: return {}
		for pose: String in ["seated", "typing", "thinking"]:
			var frame := _resolve_work_pose_frame(registry, employee_id, facing, pose, 0)
			if frame.is_empty(): return {}
			if pose == "thinking" and (frame.get("reuse_pose") != "seated" or frame.get("presentation") != "quiet_seated_thinking"): return {}
			if pose in vfx_poses and not frame.get("work_vfx_anchor") is Vector2: return {}
	return capability.duplicate(true)

static func reviewed_workstation_option_admitted(pose_set: String, facing: String, revision: String, option: String, value: Variant) -> bool:
	if revision.is_empty(): return false
	var capability := reviewed_workstation_capability(pose_set, facing, revision)
	return capability.has(option) and _exact_variant_equal(capability[option], value)

static func reviewed_collaboration_capability(pose_set: String, facing: String, revision: String = "") -> Dictionary:
	var value: Variant = REVIEWED_COLLABORATION_CAPABILITIES.get(facing)
	if not value is Dictionary: return {}
	var capability := value as Dictionary
	var expected_fields: Array[String] = ["revision", "furniture_asset_revision", "pose_asset_revision", "pose_set", "employees", "poses"]
	if capability.size() != expected_fields.size(): return {}
	for field: String in expected_fields:
		if not capability.has(field): return {}
	if pose_set != REVIEWED_WORKSTATION_POSE_SET or str(capability.pose_set) != pose_set: return {}
	if str(capability.furniture_asset_revision) != REVIEWED_COLLABORATION_REVISION: return {}
	if str(capability.pose_asset_revision) != "workstations-v2": return {}
	if not revision.is_empty() and str(capability.revision) != revision: return {}
	if capability.employees != ["mira", "theo"] or capability.poses != ["seated"]: return {}
	var registry: Variant = WORK_POSE_SETS.get(pose_set)
	if not registry is Dictionary or str(registry.get("status", "")) != "runtime_ready" or str(registry.get("asset_revision", "")) != str(capability.pose_asset_revision): return {}
	var review: Variant = registry.get("review")
	if not review is Dictionary:
		return {}
	for gate: String in ["art", "geometry", "poses"]:
		if not review.get(gate) is bool or not bool(review.get(gate)): return {}
	for employee_id: String in capability.employees:
		if not supports_work_pose(employee_id, pose_set, facing, "seated"): return {}
	return capability.duplicate(true)

static func _exact_variant_equal(left: Variant, right: Variant) -> bool:
	# JSON numbers decode as floats while code-owned constants retain integers.
	# Treat equal finite numeric values as the same exact authored pixel value.
	if (left is int or left is float) and (right is int or right is float):
		return is_finite(float(left)) and is_finite(float(right)) and float(left) == float(right)
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _exact_variant_equal(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _exact_variant_equal(left[index], right[index]): return false
		return true
	return left == right

static func calibration_thinking_reuses_seated(character_id: String, pose_set: String, facing: String) -> bool:
	# An owner-scoped admission of quiet seated-idle reuse, not a newly drawn
	# thinking, research, approval, or delivery pose in the production registry.
	if not is_calibration_pose_set(pose_set): return false
	var frame := work_pose_frame(character_id, pose_set, facing, "thinking", 0)
	return frame.get("reuse_pose") == "seated" and frame.get("presentation") == "quiet_seated_thinking"

static func calibration_work_vfx_anchor(character_id: String, pose_set: String, facing: String, pose: String) -> Variant:
	if not is_calibration_pose_set(pose_set) or pose not in ["thinking", "typing"]: return null
	return work_pose_frame(character_id, pose_set, facing, pose, 0).get("work_vfx_anchor")

static func workstation_thinking_reuses_seated(character_id: String, pose_set: String, facing: String, revision: String = "", calibration_owner_id: int = 0) -> bool:
	if calibration_pose_belongs_to(pose_set, calibration_owner_id):
		return calibration_thinking_reuses_seated(character_id, pose_set, facing)
	if is_calibration_pose_set(pose_set): return false
	if revision.is_empty(): return false
	var capability := reviewed_workstation_capability(pose_set, facing, revision)
	if capability.get("thinking_reuses_seated") != true: return false
	var frame := work_pose_frame(character_id, pose_set, facing, "thinking", 0)
	return frame.get("reuse_pose") == "seated" and frame.get("presentation") == "quiet_seated_thinking"

static func workstation_work_vfx_anchor(character_id: String, pose_set: String, facing: String, pose: String, revision: String = "", calibration_owner_id: int = 0) -> Variant:
	if calibration_pose_belongs_to(pose_set, calibration_owner_id):
		return calibration_work_vfx_anchor(character_id, pose_set, facing, pose)
	if is_calibration_pose_set(pose_set): return null
	if revision.is_empty(): return null
	var capability := reviewed_workstation_capability(pose_set, facing, revision)
	var poses: Variant = capability.get("work_vfx_poses", [])
	if not poses is Array or pose not in poses: return null
	return work_pose_frame(character_id, pose_set, facing, pose, 0).get("work_vfx_anchor")

static func supported_work_facings(character_id: String, pose_set: String = LEGACY_WORK_POSE_SET, required_poses: Array[String] = ["seated", "typing"]) -> Array[String]:
	var supported: Array[String] = []
	if required_poses.is_empty(): return supported
	for facing: String in WORK_FACINGS:
		var complete := true
		for pose: String in required_poses:
			if not supports_work_pose(character_id, pose_set, facing, pose): complete = false
		if complete: supported.append(facing)
	return supported

static func work_pose_frame(character_id: String, pose_set: String, facing: String, pose: String, frame: int) -> Dictionary:
	var registry: Dictionary = WORK_POSE_SETS.get(pose_set, {})
	if registry.is_empty() and is_calibration_pose_set(pose_set): registry = _calibration_pose_sets[pose_set]
	return _resolve_work_pose_frame(registry, character_id, facing, pose, frame)

static func _resolve_work_pose_frame(registry: Dictionary, character_id: String, facing: String, pose: String, frame: int) -> Dictionary:
	var characters: Dictionary = registry.get("characters", {})
	var sheets: Dictionary = characters.get(character_id, {})
	var facings: Dictionary = registry.get("facings", {})
	var poses: Dictionary = facings.get(facing, {})
	var definition: Dictionary = poses.get(pose, {})
	if definition.is_empty() or sheets.is_empty(): return {}
	var texture := sheets.get(str(definition.get("sheet", ""))) as Texture2D
	for field: String in ["frames", "row", "column"]:
		if not _native_integer(definition.get(field)): return {}
	var frame_count := int(definition.get("frames", 0))
	if texture == null or frame_count < 1: return {}
	var strip := Rect2(Vector2(int(definition.column), int(definition.row)) * FRAME_SIZE, Vector2(frame_count, 1) * FRAME_SIZE)
	if not Rect2(Vector2.ZERO, texture.get_size()).encloses(strip): return {}
	var region := Rect2(Vector2(int(definition.column) + posmod(frame, frame_count), int(definition.row)) * FRAME_SIZE, FRAME_SIZE)
	if not Rect2(Vector2.ZERO, texture.get_size()).encloses(region): return {}
	var result := {"texture": texture, "region": region}
	if definition.has("cuts_by_character"):
		var cuts_map: Variant = definition.cuts_by_character
		if not cuts_map is Dictionary: return {}
		var cuts: Variant = cuts_map.get(character_id)
		if not cuts is Array or cuts.size() != frame_count: return {}
		var value: Variant = cuts[posmod(frame, frame_count)]
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floorf(float(value)): return {}
		var cut := int(value)
		if cut < 1 or cut >= int(FRAME_SIZE.y): return {}
		var layers: Array[Dictionary] = [
			{"name": "upper", "region": Rect2(region.position, Vector2(48, cut)), "offset": Vector2.ZERO},
			{"name": "lower", "region": Rect2(region.position + Vector2(0, cut), Vector2(48, 80 - cut)), "offset": Vector2(0, cut)},
		]
		result["layers"] = layers
	if definition.has("reuse_pose") or definition.has("presentation"):
		# Reuse is deliberately narrow and source-exact. A typing strip or altered
		# cut cannot be relabeled as idle thinking to unlock a seated capability.
		if pose != "thinking" or definition.get("reuse_pose") != "seated" or definition.get("presentation") != "quiet_seated_thinking": return {}
		var idle: Dictionary = poses.get("seated", {})
		if idle.has("reuse_pose") or idle.has("presentation") or int(idle.get("frames", 0)) != frame_count: return {}
		var source := _resolve_work_pose_frame(registry, character_id, facing, "seated", frame)
		if source.is_empty() or source.texture != texture or source.region != region or source.get("layers", []) != result.get("layers", []): return {}
		result["reuse_pose"] = "seated"
		result["presentation"] = "quiet_seated_thinking"
	if definition.has("work_vfx_anchor_by_character"):
		if pose not in ["thinking", "typing"]: return {}
		var anchors: Variant = definition.work_vfx_anchor_by_character
		if not anchors is Dictionary or anchors.size() != characters.size(): return {}
		for id: Variant in anchors:
			if not characters.has(id): return {}
		var anchor: Variant = anchors.get(character_id)
		if not anchor is Array or anchor.size() != 2: return {}
		for coordinate: Variant in anchor:
			if not _native_integer(coordinate) or absf(float(coordinate)) > 256.0: return {}
		result["work_vfx_anchor"] = Vector2(float(anchor[0]), float(anchor[1]))
	return result

static func locomotion_region(direction: StringName, column: int) -> Rect2:
	var row := 0
	match direction:
		&"back":
			row = 1
		&"left":
			row = 2
		&"right":
			row = 3
	return Rect2(Vector2(float(clampi(column, 0, 5)) * FRAME_SIZE.x, float(row) * FRAME_SIZE.y), FRAME_SIZE)

static func work_region(row: int, column: int) -> Rect2:
	return Rect2(
		Vector2(float(clampi(column, 0, 7)) * FRAME_SIZE.x, float(clampi(row, 0, 3)) * FRAME_SIZE.y),
		FRAME_SIZE
	)
