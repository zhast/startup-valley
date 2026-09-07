extends "res://tools/capture_complete_south_workstation.gd"
## Thin direction specialization of the complete workstation lifecycle harness.
const EAST_FIXTURE := preload("res://tools/complete_east_workstation_fixture.gd")

func fixture_resource() -> Variant:
	return EAST_FIXTURE

func output_directory() -> String:
	return "res://tests/output/complete-east-workstation"

func review_facing() -> String:
	return "east"

func candidate_label() -> String:
	return "EAST CANDIDATE"

func before_evidence_path() -> String:
	return "res://tests/output/supported-east-assembly"
