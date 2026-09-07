extends "res://tools/capture_complete_south_workstation.gd"
## Thin direction specialization of the complete workstation lifecycle harness.
const NORTH_FIXTURE := preload("res://tools/complete_north_workstation_fixture.gd")

func fixture_resource() -> Variant:
	return NORTH_FIXTURE

func output_directory() -> String:
	return "res://tests/output/complete-north-workstation"

func review_facing() -> String:
	return "north"

func candidate_label() -> String:
	return "NORTH CANDIDATE"

func before_evidence_path() -> String:
	return "res://tests/output/supported-north-assembly"
