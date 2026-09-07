extends SceneTree
const SCOPE := preload("res://tools/audit_output_scope.gd")

func _initialize() -> void:
	var checks := 0
	var failures := 0
	for value: String in ["", "res://tests/output/new-checkpoint", "res://tests/output/new/nested"]:
		checks += 1
		if not SCOPE.valid(value): failures += 1; push_error("Valid output scope rejected: " + value)
	for value: String in ["/", "/tmp/audit", "res://", "res://tests/output", "res://tests/output/", "res://tests/output/../data", "res://tests/output/x/../../data", "res://tests/output/x//y", "res://tests/output/./x", "res://tests/output/x\\y", "res://tests/output/x:y", "res://tests/output/x\n"]:
		checks += 1
		if SCOPE.valid(value): failures += 1; push_error("Invalid output scope accepted")
	print("Audit output scope: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
