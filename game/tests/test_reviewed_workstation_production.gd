extends SceneTree
## Provider-free production admission test for the reviewed four-facing assembly.

const CALIBRATED_FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const RUNTIME_HASHES := {
	"res://assets/runtime/office/workstations-v2/chair-east-front.png": "1c33dea821fb5a5cc8988919d6bd8477e8eb36a26c6a6b858afd7e02b3a19e14",
	"res://assets/runtime/office/workstations-v2/chair-east-rear.png": "d8d95f980d775a0106c6ce5d4372a6c6fb8e6ac39c7f97c3c80b9924ae5a6e67",
	"res://assets/runtime/office/workstations-v2/chair-north.png": "181533012b18d8c167b16d66712f1c098ca72038d8e4db0209549dda16eb25a7",
	"res://assets/runtime/office/workstations-v2/chair-south.png": "34a0e2894f089f256cef7c29ab826376e640a13fcce5e266599f19b3f4338a9c",
	"res://assets/runtime/office/workstations-v2/chair-west-front.png": "06f55fc22a9d8a304ad0821bf1abeaaee67bd1590c2711662d3c0e77b8cceea9",
	"res://assets/runtime/office/workstations-v2/chair-west-rear.png": "354a5cc29e1fd9c318eec3312fed3da20d9e6aa78c11819c7b44bf34b3cfd724",
	"res://assets/runtime/office/workstations-v2/desk-east-front.png": "84955f38693eba83e5891b77fbb7c30b6a62286cc69aa40436162fcccb3c2a11",
	"res://assets/runtime/office/workstations-v2/desk-east-rear.png": "a8f7bb9475f20ec83f7cf5d0896e90b5f646f7d15086f719bb89073a8aec9610",
	"res://assets/runtime/office/workstations-v2/desk-north-front.png": "ce1a47d7a86766c390aea38f1b89fa56540db5b80101cb5d0090a43cb975b276",
	"res://assets/runtime/office/workstations-v2/desk-north-rear.png": "bae1dc8b8e65c2a7768761c22655f37abc87a86272f2ee1d531f1758b8583fd0",
	"res://assets/runtime/office/workstations-v2/desk-south-front.png": "5e9e1eeeab65a39a73db6ffee6544d59514e43e62493859d796f5efe8183c183",
	"res://assets/runtime/office/workstations-v2/desk-south-rear.png": "54e7bfe7f3c6760700e0aa61cb3e9eeac4cb51833bbc3fc40028b1902f7bbcc4",
	"res://assets/runtime/office/workstations-v2/desk-west-front.png": "35ec784fd856582aa9da1a737be451c09b6ba4e7388f1f850b3828e514d5e6c5",
	"res://assets/runtime/office/workstations-v2/desk-west-rear.png": "a8f7bb9475f20ec83f7cf5d0896e90b5f646f7d15086f719bb89073a8aec9610",
	"res://assets/runtime/office/workstations-v2/keyboard-east.png": "0112b823fcdfe67092e35a33b8aa6a4e7d812101e6c85e12304462327d57ae91",
	"res://assets/runtime/office/workstations-v2/keyboard-north.png": "370b661c5d88cab4881f571f4c80a47b0d591cf7b4bc2abe8cc925934067c647",
	"res://assets/runtime/office/workstations-v2/keyboard-south.png": "8b57a8a83600547a3f077dca2daf5e4df01836ab251764657fc7e5a66456eb89",
	"res://assets/runtime/office/workstations-v2/keyboard-west.png": "1d56652c485e9785247d88192e12b77b6a0690036c5944210a54cb85035e89de",
	"res://assets/runtime/office/workstations-v2/monitor-east.png": "18856d719560ebbc634d1843f856bd20ca2264d908804436e188136482c56c34",
	"res://assets/runtime/office/workstations-v2/monitor-north.png": "237b9e27311a0fc11dc772c0fac9a477f904bb02b7336fc0298c4f6a529f1088",
	"res://assets/runtime/office/workstations-v2/monitor-south.png": "ade1a3685651e9babb2ad8d2342ed7d944cac45ce7f33caf7ca0b7b83a41524f",
	"res://assets/runtime/office/workstations-v2/monitor-west.png": "a70e5fc0465c2df58b9ecdb8a8309120c933a94ca348299ea29314e417d67f95",
	"res://assets/runtime/office/workstations-v2/mouse-east.png": "6b0f4a723f41d8e03ef389757560b97a5722fa0046db52549ae33abaa2709c68",
	"res://assets/runtime/office/workstations-v2/mouse-north.png": "4e730bbb85f1f13e794a256b75ff297223860bd2d8d439954176674e4d48a6ad",
	"res://assets/runtime/office/workstations-v2/mouse-south.png": "35fc55d02929dfbe6785f819c5b6c990c756aefa029551c8c38b5d88ccaf53b5",
	"res://assets/runtime/office/workstations-v2/mouse-west.png": "2c8f5ea5c4ba06d8bfc7a1d20193f0254b17a9789471c2ddd020e1bf30bd5ef4",
	"res://assets/runtime/characters/workstations-v2/mira-east.png": "1bcf88f00b52b635bd5cda51a29f7eb769f9b579eca47fcdb09b7e69080f0dd0",
	"res://assets/runtime/characters/workstations-v2/mira-north.png": "067b7b8781b589bbcdc89a46a69d7531363882faab34ba4cc80e7a2c9718458f",
	"res://assets/runtime/characters/workstations-v2/mira-west.png": "c71d136b7468df7dde0d5d9ef87d073471a8a1a4a975dcc9e25ca6cc4fc2c14f",
	"res://assets/runtime/characters/workstations-v2/theo-east.png": "bcf40180294d72954a8e038c456fdc0db7faec9b5e2b99ac6ce59202b6096db8",
	"res://assets/runtime/characters/workstations-v2/theo-north.png": "6f8a7427cb0823e2bedf5ae98a4c4f0c294b3be77430e4a96b3491fa92465ae1",
	"res://assets/runtime/characters/workstations-v2/theo-west.png": "36fcf36849f83ce0a11dbcb60626677fe83cdd05b6aa9b50c9c91174551ad5ad",
}

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func rejected(model: OfficeLayout, facing: String, message: String) -> void:
	check(not model.resolve_profile("desk", facing).errors.is_empty(), message)

func restore(model: OfficeLayout, facing: String, profile: Dictionary) -> void:
	model.catalog.desk.facing_profiles[facing] = profile.duplicate(true)

func run() -> void:
	for path: String in RUNTIME_HASHES:
		check(FileAccess.get_sha256(path) == RUNTIME_HASHES[path], "Reviewed runtime copy remains byte-exact: " + path)
	var model := OfficeLayout.new()
	check(model.load_files(), "Normal production catalogue loads without a calibration owner")
	check(model.available_facings("desk") == OfficeLayout.FACINGS, "Normal production exposes exactly the four accepted desk facings")
	for facing: String in OfficeLayout.FACINGS:
		var resolution := model.resolve_profile("desk", facing)
		check(resolution.errors.is_empty(), facing + " reviewed production profile resolves")
		var profile: Dictionary = resolution.profile
		check(not bool(profile.get("calibration_preview", false)), facing + " production admission does not borrow a calibration marker")
		var capability := CharacterArt.reviewed_workstation_capability(profile.pose_set, profile.work_facing, profile.workstation_capability_revision)
		check(not capability.is_empty() and capability.asset_revision == profile.asset_revision, facing + " resolves through the exact code-owned capability revision")
		for employee_id: String in ["mira", "theo"]:
			check(CharacterArt.supported_work_facings(employee_id, CharacterArt.REVIEWED_WORKSTATION_POSE_SET) == OfficeLayout.FACINGS, employee_id + " owns exactly four reviewed production pose directions")
			for pose: String in ["seated", "typing", "thinking"]:
				check(CharacterArt.supports_work_pose(employee_id, profile.pose_set, facing, pose), "%s has real %s %s pixels" % [employee_id, facing, pose])
			check(CharacterArt.workstation_thinking_reuses_seated(employee_id, profile.pose_set, facing, profile.workstation_capability_revision), "%s %s quiet thinking reuse is explicitly admitted" % [employee_id, facing])
			for pose: String in ["thinking", "typing"]:
				check(CharacterArt.workstation_work_vfx_anchor(employee_id, profile.pose_set, facing, pose, profile.workstation_capability_revision) is Vector2, "%s %s %s VFX attachment is explicit" % [employee_id, facing, pose])
		for layer: Dictionary in profile.render_layers:
			check(str(layer.art).begins_with("res://assets/runtime/"), facing + " production never reads test fixture art")
			check(not layer.has("rotation") and not layer.has("scale") and not layer.has("flip_h") and not layer.has("flip_v"), facing + " layers remain native and independently authored")
		var original: Dictionary = model.catalog.desk.facing_profiles[facing].duplicate(true)
		model.catalog.desk.facing_profiles[facing].pose_set = CharacterArt.LEGACY_WORK_POSE_SET
		rejected(model, facing, "Review flags plus a legacy pose name cannot forge reviewed presentation")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].erase("workstation_capability_revision")
		rejected(model, facing, "Missing capability revision fails closed")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].workstation_capability_revision = "workstations-v2:forged"
		rejected(model, facing, "Forged capability revision fails closed")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].asset_revision = "lookalike-v2"
		rejected(model, facing, "Capability cannot be attached to a different asset revision")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].seat_state_handoff.clearance_pixels = 31
		rejected(model, facing, "Altered handoff value cannot borrow the reviewed option")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].seat_anchor_by_employee.erase("theo")
		rejected(model, facing, "A profile missing one reviewed employee anchor is rejected")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].render_layers[0].art = "res://missing-reviewed-workstation.png"
		rejected(model, facing, "Review flags never conceal missing production art")
		restore(model, facing, original)
		model.catalog.desk.facing_profiles[facing].grounded_work_shadow_follow_seat_x = false
		rejected(model, facing, "A declared capability must match every reviewed presentation option")
		restore(model, facing, original)
	# Explicitly reconstruct the pre-promotion data shape. Its old South fallback
	# still works and gains none of the optional v2 presentation behavior.
	var legacy_catalog := model.catalog.duplicate(true)
	legacy_catalog.desk.erase("facing_profiles")
	legacy_catalog.desk.facings = ["south"]
	var legacy := OfficeLayout.new()
	legacy.configure(model.data, legacy_catalog)
	check(legacy.available_facings("desk") == ["south"], "A legacy catalogue retains its South-only fallback")
	var legacy_placement := legacy.placement_by_id("mira-workstation", 2)
	for field: String in ["workstation_capability_revision", "seat_pose_depth_lock", "seat_state_handoff", "grounded_work_shadow", "grounded_work_shadow_follow_seat_x"]:
		check(not legacy_placement.has(field), "Legacy fallback does not implicitly gain " + field)
	await check_game_main()
	await check_calibration_owner_scope()
	print("Reviewed workstation production: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_game_main() -> void:
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Normal integration test never starts the worker")
	check(main.room.layout_model.available_facings("desk") == OfficeLayout.FACINGS, "Normal GameMain sees all four reviewed facings without enabling calibration")
	for facing: String in OfficeLayout.FACINGS:
		check(main.room.set_placement_overrides({
			"mira-workstation": {"grid": [10, 8], "facing": facing},
			"theo-workstation": {"grid": [20, 8], "facing": facing},
		}), "Normal room accepts both reviewed %s workstations" % facing)
		main._on_room_placements_changed()
		for employee_id: String in ["mira", "theo"]:
			var actor := main.get_employee(employee_id)
			actor.set_physics_process(false)
			var accepted := actor._workstation_visual.duplicate(true)
			check(accepted.get("pose_set") == CharacterArt.REVIEWED_WORKSTATION_POSE_SET and str(accepted.get("workstation_capability_revision", "")) == "workstations-v2:" + facing, "%s receives reviewed %s metadata through TownRoom" % [employee_id, facing])
			check(bool(accepted.get("seat_pose_depth_lock")) and bool(accepted.get("grounded_work_shadow")) and bool(accepted.get("grounded_work_shadow_follow_seat_x")), "%s receives all admitted %s presentation options" % [employee_id, facing])
			check(actor._seat_transition_preview and is_equal_approx(actor._seat_transition_duration, 0.14), "%s production %s enables the bounded seat handoff" % [employee_id, facing])
			actor.position = actor.desk_position
			actor._has_target = false
			actor.has_live_job = true
			actor.work_state = EmployeeAvatar.WorkState.WORKING
			actor._activity = &"thinking"
			actor._update_character_frame()
			actor._physics_process(0.14)
			check(actor._uses_seated_thinking() and actor._uses_seated_visual(), "%s uses quiet seated thinking in normal %s gameplay" % [employee_id, facing])
			check(actor._work_vfx_anchor() is Vector2, "%s uses the reviewed %s assembly-relative VFX anchor" % [employee_id, facing])
			for mutation: Dictionary in [
				{"workstation_capability_revision": "workstations-v2:forged"},
				{"seat_state_handoff": {"clearance_pixels": 31}},
				{"grounded_work_shadow": false},
			]:
				var forged := accepted.duplicate(true)
				forged.merge(mutation, true)
				check(not actor.configure_workstation_visual(forged) and actor._workstation_visual == accepted, "%s actor rejects forged %s metadata without mutation" % [employee_id, facing])
	main.game_audio.shutdown()
	main.free()
	await process_frame

func check_calibration_owner_scope() -> void:
	var fixture := CALIBRATED_FIXTURE.new()
	fixture.employee_ids.assign(["mira"])
	fixture.initial_facing = "west"
	root.add_child(fixture)
	await process_frame
	check(fixture.ready_ok, "Owner-scoped calibration fixture remains admitted")
	if fixture.ready_ok:
		var actor: EmployeeAvatar = fixture.main.get_employee("mira")
		actor.set_physics_process(false)
		var accepted: Dictionary = actor._workstation_visual.duplicate(true)
		var owner_id := fixture.get_instance_id()
		check(int(accepted.get("calibration_owner_id", 0)) == owner_id, "TownRoom carries the live calibration owner into actor metadata")
		check(CharacterArt.workstation_thinking_reuses_seated("mira", fixture.pose_set_id, "west", "", owner_id), "Matching live owner admits calibration thinking reuse")
		check(not CharacterArt.workstation_thinking_reuses_seated("mira", fixture.pose_set_id, "west"), "Unscoped calibration cannot borrow thinking reuse")
		check(CharacterArt.workstation_work_vfx_anchor("mira", fixture.pose_set_id, "west", "typing", "", owner_id) is Vector2, "Matching live owner admits calibration VFX attachment")
		check(CharacterArt.workstation_work_vfx_anchor("mira", fixture.pose_set_id, "west", "typing") == null, "Unscoped calibration cannot borrow a VFX attachment")
		for forged_owner: Variant in [null, 0, owner_id + 1, "owner"]:
			var forged := accepted.duplicate(true)
			if forged_owner == null: forged.erase("calibration_owner_id")
			else: forged.calibration_owner_id = forged_owner
			check(not actor.configure_workstation_visual(forged) and actor._workstation_visual == accepted, "Direct calibration metadata requires the exact live owner scope")
		var original: Dictionary = fixture.model.catalog.desk.facing_profiles.west.duplicate(true)
		fixture.model.catalog.desk.facing_profiles.west.calibration_owner_id = owner_id
		check(not fixture.model.resolve_profile("desk", "west").errors.is_empty(), "Catalogue data cannot author or persist a calibration owner id")
		fixture.model.catalog.desk.facing_profiles.west = original
	fixture.free()
	await process_frame
