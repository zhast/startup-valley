extends SceneTree
## DEV ONLY. Provider-free export for three unregistered passive service/storage bases.

const ART := preload("res://tools/passive_service_library_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUTS := {
	"water_station": "res://tests/output/water-station-v2",
	"printer_scanner_station": "res://tests/output/printer-scanner-station-v1",
	"resource_cart": "res://tests/output/resource-cart-v1",
}
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
const MATERIALS := {
	"charcoal_powdercoat": ART.POWDERCOAT,
	"oak_horizontal": ART.OAK_HORIZONTAL,
	"oak_vertical": ART.OAK_VERTICAL,
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

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Saved " + path)
	var decoded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(decoded != null and decoded.get_data() == image.get_data(), "PNG roundtrip is exact: " + path)

static func rect_values(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func export_family(family: String) -> void:
	var fixture_root := str(ART.ROOTS[family])
	var evidence_root := str(OUTPUTS[family])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_root))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_root))
	var size := ART.canvas(family)
	var native_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	var layer_sheet := Image.create(size.x * 4, size.y * ART.LAYERS.size(), false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	layer_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[column]
		var p := ART.profile(family, side)
		var parts := ART.layers(family, side)
		var whole := ART.whole(family, side)
		var whole_analysis := PIXELS.analyze(whole)
		var local_opaque_top := int(whole_analysis.opaque_bounds[1]) - ART.pivot(family).y
		var layer_records: Array[Dictionary] = []
		for row: int in range(ART.LAYERS.size()):
			var layer_name: String = ART.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := fixture_root.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, row * size.y))
			var descriptor := ART.descriptor(family, side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			layer_records.append(descriptor)
		var whole_path := fixture_root.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, 0))
		directions.append({
			"facing": side,
			"service_side": p.service_side,
			"approach_gaze": p.approach_gaze,
			"employee_look_vector": p.employee_look_vector,
			"proposed_interaction_cell": p.interaction,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"clearance_cell_offsets": p.clearance,
			"floor_plane_px": rect_values(p.floor),
			"top_plane_px": rect_values(p.top),
			"camera_front_elevation_px": rect_values(p.front),
			"base_solid_bounds_px": rect_values(p.base_solid_bounds),
			"contact_boundary_y": p.contact_y,
			"base_elevation_px": p.base_elevation,
			"top_plane_depth_px": p.top_plane_depth,
			"base_projected_rise_px": p.base_projected_rise,
			"measured_whole_projected_rise_px": p.contact_y - local_opaque_top,
			"camera_face_identity": p.camera_face_identity,
			"role_identity": p.role_identity,
			"dimension_review": p.dimension_review,
			"layers": layer_records,
			"whole_measurements": whole_analysis,
			"whole_sha256": FileAccess.get_sha256(whole_path),
		})
	save(native_sheet, evidence_root.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, evidence_root.path_join("candidate-layers-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, evidence_root.path_join("candidate-contact-sheet-4x.png"))
	var material_records := {}
	for material_name: String in MATERIALS:
		var path := str(MATERIALS[material_name])
		material_records[material_name] = {"path": path, "sha256": FileAccess.get_sha256(path), "retained_unchanged": true}
	var manifest := {
		"id": ART.revision_id(family),
		"family": family,
		"status": "native_review_candidate_without_runtime_binding",
		"canvas": [size.x, size.y],
		"pivot": [ART.pivot(family).x, ART.pivot(family).y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"layers": ART.LAYERS,
		"directions": directions,
		"dimension_review": ART.dimension_review(family),
		"material_sources": material_records,
		"provenance": "Editable typed-GDScript screen-axis construction with a physical-footprint top plane and separate elevation/contact geometry. Reviewed native oak/powdercoat tiles are retained materials only. No generated raster, transformed finished bitmap, provider call, text, logo, fake metric, baked actor, service, printing, dispensing or cart movement is implemented.",
		"code_native_provenance": {"image_generation_calls": 0, "generated_raster_sources_used": false, "source_attempts_created": 0},
		"runtime_registered": false,
		"dev_catalogue_registration": "Not asserted. This exporter only verifies byte-exact shared-catalogue immutability during its own run.",
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"service_backend_or_interaction_created": false,
		"checks": checks,
		"failures": failures,
	}
	if family == "water_station":
		manifest["supersedes_rejected_revision"] = "water-station-v1"
		manifest["rejected_revision_reason"] = "The complete v1 fixture/evidence is preserved, but direct native review rejected its narrow featureless rectangular reservoir because it read as a blue chimney rather than an office water bottle. V2 changes only the reservoir silhouette."
		manifest["preserved_v1_files"] = [
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/east-floor_shadow.png", "sha256": "84fa086f790b16c746e59af3a46d53f1b1d3e936d3cbf2f98a0042d07cedfeb2"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/east-front_structure.png", "sha256": "23a491d59f6c095189a072e89933b10a3f608943be013d9f752a4e1c249afdc9"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/east-rear_structure.png", "sha256": "f68850e0b9e2fed7b3d781d5421b0ab9fa61c9f30091c0697446e8dee578119d"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/east-whole.png", "sha256": "d82ca25d01188f64d2f0419b3d4c71a545a7981cd4726054fed775f3917728a1"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/manifest.json", "sha256": "e43ec199c41cbfbe39e118a357afc4a7be21fd4822c809a933cc45858c11978e"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/north-floor_shadow.png", "sha256": "3dd018cb9af50be2d8ae36843cfd02f1a65ac70f3ee1f40c89f0a8f519994698"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/north-front_structure.png", "sha256": "905f78435c878ec7a2bc8e8833b4573f56d42a1eea3c0fc07f561040e4e65136"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/north-rear_structure.png", "sha256": "09f3f7a541dc6ec684d9021c0b0d07581c4c7d705efa060ce7537c62088f1876"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/north-whole.png", "sha256": "2b7a857754fc09bf5ed7ac53c92d5859930242c80c32c14b569013ae65aafb75"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/south-floor_shadow.png", "sha256": "0796117769a6c6b7b330b3a470f0b5f8ee4a1b5af9451c8af7db3e0e22996331"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/south-front_structure.png", "sha256": "b99e5466cfa4ac2b931f977ed3b5f14ebf5a5624b2ec3dbdb0b0f358d4136c47"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/south-rear_structure.png", "sha256": "f44331103af34756b94f5261754b8bec0bebe8f971af162fbbc293a1144a2a39"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/south-whole.png", "sha256": "09a426412fbd743da45f0e61126bc5fd8f0e1e973b2ac557ca55545b0827f62d"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/west-floor_shadow.png", "sha256": "629ee770e6384296dd682b51d408cc491051fe983113d199c35fc7630f3e298c"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/west-front_structure.png", "sha256": "01cb55e416e1df90aacf201483cf35e70d4c561ab3451edd081cd7b8ec61336f"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/west-rear_structure.png", "sha256": "5142a16b1410d58096f24bec2fe520a008ffaf6b8b8739392a7d62f8ba8b6890"},
			{"path": "game/tests/fixtures/furniture-calibration/water-station-v1/west-whole.png", "sha256": "9d2e21f30da68ce29a0b1d8de7991264c6afd8bbda3af78428865753eeb09777"},
			{"path": "game/tests/output/water-station-v1/actual-room-approach-contact-sheet-4x.png", "sha256": "996077056f5bedae568b50e6cafd6058e46890322b499d8e951f1e55cb9ac3d7"},
			{"path": "game/tests/output/water-station-v1/actual-room-approach-contact-sheet-native.png", "sha256": "3502cb7faba081e373807a822aa036a1e64426ad3f0353130f2b523f225522d8"},
			{"path": "game/tests/output/water-station-v1/actual-room-base-contact-sheet-native.png", "sha256": "dda94904a03b656f8a2ad5d220f53b5ac946760b836fb2d057029b790ea43804"},
			{"path": "game/tests/output/water-station-v1/actual-room-results.json", "sha256": "8450d25ce7a029a62ca728b34c4b75cf791f5d75732b6c388489bdc8fd5901ba"},
			{"path": "game/tests/output/water-station-v1/candidate-contact-sheet-4x.png", "sha256": "b452ada77b4bb00ef9afe1e9bb02c944505ca8629acc851a071b315f39f19165"},
			{"path": "game/tests/output/water-station-v1/candidate-contact-sheet-native.png", "sha256": "09b46be88ac03e4d06a3a5df9f66fa00f836e08f01fab96f58b970ad1dad4a7f"},
			{"path": "game/tests/output/water-station-v1/candidate-layers-native.png", "sha256": "3a8b13c44bc70f36272291ba68c67ec72e62e4afb835561d5ce0056a01cde8af"},
			{"path": "game/tests/output/water-station-v1/detail-east-approach-native.png", "sha256": "8513078a9531d327cc61237f3bcbc464db11c1c32a1c69909ff0fc8992e71f68"},
			{"path": "game/tests/output/water-station-v1/detail-east-base-native.png", "sha256": "c82202db95db8275be37ee6e53c0c25eca9573133702b68eadf2582dcf41e19c"},
			{"path": "game/tests/output/water-station-v1/detail-north-approach-native.png", "sha256": "8417e8f99bb2af4bacdbe2bb4f40a05a8ded0a2863d5d0e242734d73581cf74d"},
			{"path": "game/tests/output/water-station-v1/detail-north-base-native.png", "sha256": "bc5c2b191c0c285ebb0830477674d49770f276598c77285d457aba990d2d5884"},
			{"path": "game/tests/output/water-station-v1/detail-south-approach-native.png", "sha256": "e61cca4a5c3de77a924a76b30d8c3f990286940411b389a0fcfadc638c98a2b4"},
			{"path": "game/tests/output/water-station-v1/detail-south-base-native.png", "sha256": "303e323d5f6baacb1b939c95258adcf4a8fbcd7f0789d48fdebe99838cf32641"},
			{"path": "game/tests/output/water-station-v1/detail-west-approach-native.png", "sha256": "39b1298be2d5e503d3465de19bf931363e5018a89108df361db72f6fd8d33400"},
			{"path": "game/tests/output/water-station-v1/detail-west-base-native.png", "sha256": "536820bbced151b4cf7d2779bec70c7fffb5688c21dc0ce58e3c1d674e32be1a"},
			{"path": "game/tests/output/water-station-v1/room-east.png", "sha256": "cf740f850f7513bd1d9f5c75bb7fc0f523893833ab9c03351de621bb76bf34d3"},
			{"path": "game/tests/output/water-station-v1/room-north.png", "sha256": "b2bbd002a627a60df7967da1068a441565a04315facc7eb7deeba2e9fd698b12"},
			{"path": "game/tests/output/water-station-v1/room-south.png", "sha256": "8f24d5555cbeacaf656fdeb3b007af3a797ef2aac1a6f7e017159cc5b6feebbc"},
			{"path": "game/tests/output/water-station-v1/room-west.png", "sha256": "ab0a32d4d88305b83c54bbbe1a242fe09b5b755e8dafa7eaf163a10e34dc252e"},
			{"path": "game/tests/output/water-station-v1/structural-results.json", "sha256": "425810c0b276ed519070844c1013c252229ad1ff568f257255ddb3cbf3a18452"},
		]
	var file := FileAccess.open(fixture_root.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")

func run() -> void:
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_before := FileAccess.get_sha256(DEV_CATALOGUE)
	for family: String in ART.FAMILIES: export_family(family)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "Exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Exporter leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == dev_before, "Exporter leaves shared dev catalogue byte-exact")
	print("Passive service library export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
