extends SceneTree
## DEV ONLY. Combines three fresh-process native GameMain utility-v2 captures.
## A single process spanning multiple GameMain lifecycles stalled twice in separate
## harnesses on 2026-09-06, so acceptance uses isolated family processes and keeps
## the interrupted attempts as explicit, non-acceptance history.

const FAMILIES: Array[String] = ["tall_storage_cabinet", "server_cabinet", "recycling_sorter"]
const OUTPUTS := {
	"tall_storage_cabinet": "res://tests/output/tall-storage-cabinet-v2",
	"server_cabinet": "res://tests/output/server-cabinet-v2",
	"recycling_sorter": "res://tests/output/recycling-sorter-v2",
}
const AGGREGATE := "res://tests/output/passive-utility-library-v2/actual-room-isolated-aggregate-results.json"

var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func load_json(path: String) -> Dictionary:
	check(FileAccess.file_exists(path), "Exists: " + path)
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(parsed is Dictionary, "Valid JSON object: " + path)
	return parsed as Dictionary if parsed is Dictionary else {}

func pair_as_vector2i(value: Variant) -> Vector2i:
	if not value is Array or (value as Array).size() != 2: return Vector2i(-1, -1)
	var pair := value as Array
	return Vector2i(int(pair[0]), int(pair[1]))

func run() -> void:
	var families := {}
	var invocation_checks := 0
	var family_evidence_checks := 0
	for family: String in FAMILIES:
		var slug := family.replace("_", "-")
		var invocation_path := "res://tests/output/passive-utility-library-v2/native-invocation-%s.json" % slug
		var invocation := load_json(invocation_path)
		var actual_path := str(OUTPUTS[family]).path_join("actual-room-results.json")
		var actual := load_json(actual_path)
		check(str(invocation.get("status", "")) == "passed", family + " isolated invocation passed")
		check(str(invocation.get("selected_family", "")) == family, family + " isolated invocation names only its own family")
		check(str(invocation.get("renderer", "")) != "headless", family + " used a native renderer")
		check(pair_as_vector2i(invocation.get("viewport", [])) == Vector2i(1280, 720), family + " stayed at native 1280x720")
		check((invocation.get("failures", []) as Array).is_empty(), family + " isolated invocation has zero failures")
		check(int(invocation.get("checks", 0)) == 196, family + " isolated invocation records the full 196 checks")
		check(str(actual.get("family", "")) == family, family + " actual-room result identifies its family")
		check((actual.get("failures", []) as Array).is_empty(), family + " actual-room family evidence has zero failures")
		check(int(actual.get("checks", 0)) == 190, family + " actual-room family evidence records 190 checks before result-file close")
		check(str(actual.get("renderer", "")) != "headless", family + " family evidence records native renderer")
		check(pair_as_vector2i(actual.get("viewport", [])) == Vector2i(1280, 720), family + " family evidence records native viewport")
		check(bool(actual.get("worker_disabled", false)) and not bool(actual.get("save_access", true)), family + " starts no worker and touches no save")
		check(not bool(actual.get("runtime_registered", true)) and not bool(actual.get("service_backend_or_interaction_created", true)), family + " adds no runtime or service capability")
		for hash_key: String in ["production_catalogue", "default_layout", "shared_art_catalogue"]:
			check(str(invocation.get(hash_key + "_sha256_before", "")) == str(invocation.get(hash_key + "_sha256_after", "changed")), family + " leaves " + hash_key + " byte-exact during its isolated run")
		for capture_path: Variant in actual.get("captures", []):
			check(FileAccess.file_exists(str(capture_path)), family + " retains native evidence: " + str(capture_path))
		invocation_checks += int(invocation.get("checks", 0))
		family_evidence_checks += int(actual.get("checks", 0))
		families[family] = {
			"invocation_path": invocation_path.trim_prefix("res://"),
			"actual_room_results_path": actual_path.trim_prefix("res://"),
			"invocation_checks": invocation.get("checks", 0),
			"family_evidence_checks": actual.get("checks", 0),
			"renderer": actual.get("renderer", ""),
			"viewport": actual.get("viewport", []),
			"common_safe_pivot": actual.get("common_safe_pivot", []),
			"observations": actual.get("observations", {}),
			"captures": actual.get("captures", []),
		}
	var interrupted_attempts := [
		{
			"attempt": "utility_v2_multi_family_initial",
			"disposition": "interrupted_non_acceptance_history",
			"observed": "Tall storage and server family result files completed, then the process made no observable progress before sorter for more than three minutes and was manually interrupted.",
			"cause": "unknown",
			"inference_limit": "The later focused sorter success and catalogue-hash failure do not establish the cause of this earlier stall.",
		},
		{
			"attempt": "utility_v2_focused_sorter_diagnostic",
			"disposition": "superseded_non_acceptance_diagnostic",
			"observed": "Sorter completed its 190 family checks; the invocation ended at 195 checks / 1 failure because furniture.json changed between the run-local before/after hashes.",
			"cause": "concurrent shared-catalogue mutation for this diagnostic guard failure only",
			"inference_limit": "This result says nothing about the cause of the earlier multi-family stall and is superseded by the clean isolated final run.",
		},
	]
	var aggregate_file := FileAccess.open(AGGREGATE, FileAccess.WRITE)
	check(aggregate_file != null, "Opened isolated native aggregate result")
	if aggregate_file != null:
		aggregate_file.store_string(JSON.stringify({
			"status": "passed" if failures.is_empty() else "failed",
			"strategy": "three fresh native GameMain processes, one family per process",
			"families": families,
			"isolated_invocation_checks": invocation_checks,
			"family_evidence_checks": family_evidence_checks,
			"aggregate_verification_checks": checks,
			"failures": failures,
			"interrupted_attempts": interrupted_attempts,
			"runtime_registered": false,
			"service_backend_or_interaction_created": false,
		}, "\t") + "\n")
	print("Passive utility library v2 isolated native aggregate: %d checks, %d failures; source invocations %d/0" % [checks, failures.size(), invocation_checks])
	quit(0 if failures.is_empty() else 1)

func _initialize() -> void:
	call_deferred("run")
