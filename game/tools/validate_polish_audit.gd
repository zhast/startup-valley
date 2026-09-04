extends SceneTree

const OUTPUT_ROOT := "res://tests/output/polish-audit"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const CONTACT_SIZE := Vector2i(1920, 360)
const EXPECTED_SCENARIOS: Dictionary = {
	"world": [
		"founder-locomotion",
		"employee-idle-cycle",
		"job-state-cycle",
		"schedule-cycle",
		"depth-and-occlusion",
		"office-growth",
	],
	"ui": [
		"team-drawer-controls",
		"chat-and-work-order",
		"work-controls",
		"journal-and-approval",
		"delivery-studio-reader",
		"queued-errors-and-overflow",
	],
}
const REQUIRED_UI_CHECKS := {
	"team-drawer-controls": ["mina-rail-selection", "theo-rail-selection"],
	"chat-and-work-order": ["visible-editable-text-focus", "real-keyboard-text-entry", "chat-only-dispatch", "chat-waiting-disabled", "chat-to-editable-work-draft"],
	"work-controls": ["dropdown-selection-changed", "visible-editable-text-focus", "real-keyboard-text-entry", "confirmed-assignment-dispatch", "assignment-pending-disabled", "disabled-assignment-no-double-dispatch"],
	"journal-and-approval": ["activity-only-steering-dispatch", "steering-pending-disabled", "approval-ledger-keeps-footer-footprint", "ledger-back-restores-approval", "combined-disclosures-restore-work-context", "combined-disclosures-no-partial-action-controls", "approval-click-dispatch", "answered-approval-clears-stale-world-cue", "answered-approval-reveals-result"],
	"delivery-studio-reader": ["delivery-preview-in-first-view", "preview-opens-reader-before-decision", "reader-wheel-scroll", "reader-close-button-pressed", "reader-click-close", "reader-reopen-reset", "reader-reopen-retains-document", "reader-escape-close", "preview-before-promotion-dispatch-order", "studio-file-selection", "studio-reader-retains-document"],
	"queued-errors-and-overflow": ["worker-error-retry-visible", "worker-recovery-distinct"],
}
const REQUIRED_DISPATCH_ORDER := {
	"chat-and-work-order": ["chat.send"],
	"work-controls": ["job.start"],
	"journal-and-approval": ["job.steer", "approval"],
	"delivery-studio-reader": ["artifact.read", "artifact.read", "promotion", "studio.read"],
}

var _failures: PackedStringArray = []

func _initialize() -> void:
	_validate_inventory()
	for suite: String in EXPECTED_SCENARIOS:
		_validate_suite(suite)
	if _failures.is_empty():
		print("validate_polish_audit: world and UI evidence are complete")
		quit()
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)

func _validate_inventory() -> void:
	var inventory := _read_json("%s/asset-inventory.json" % OUTPUT_ROOT)
	if inventory.is_empty():
		return
	var textures_value: Variant = inventory.get("textures", [])
	var live_value: Variant = inventory.get("liveSprites", [])
	var regions_value: Variant = inventory.get("characterAtlases", [])
	var fonts_value: Variant = inventory.get("fonts", [])
	var flags_value: Variant = inventory.get("knownFlags", [])
	if not textures_value is Array or (textures_value as Array).is_empty():
		_failures.append("Asset inventory did not contain texture metadata")
	if not live_value is Array or (live_value as Array).size() < 12:
		_failures.append("Asset inventory did not inspect the live characters and office props")
	if not regions_value is Array or (regions_value as Array).size() != 3:
		_failures.append("Asset inventory did not record all three native character atlases")
	if not fonts_value is Array or (fonts_value as Array).size() < 5:
		_failures.append("Asset inventory did not record display/body/bold/italic/code fonts and licenses")
	if not flags_value is Array:
		_failures.append("Asset inventory flags are malformed")
	elif not (flags_value as Array).is_empty():
		_failures.append("Runtime asset inventory still contains polish flags: %s" % str(flags_value))
	if live_value is Array:
		for live_value_item: Variant in live_value as Array:
			if not live_value_item is Dictionary:
				continue
			var live := live_value_item as Dictionary
			if not is_equal_approx(float(live.get("scaleX", 0.0)), 1.0) or not is_equal_approx(float(live.get("scaleY", 0.0)), 1.0):
				_failures.append("%s does not render at native scale" % str(live.get("id", "sprite")))
			if str(live.get("kind", "")) == "character" and (int(live.get("sourceWidth", 0)) != 48 or int(live.get("sourceHeight", 0)) != 80):
				_failures.append("%s does not use a 48x80 runtime cell" % str(live.get("id", "character")))
	if fonts_value is Array:
		for font_value: Variant in fonts_value as Array:
			if not font_value is Dictionary:
				continue
			var font := font_value as Dictionary
			for path_key: String in ["path", "license"]:
				if not FileAccess.file_exists(str(font.get(path_key, ""))):
					_failures.append("Missing bundled font %s: %s" % [path_key, str(font.get(path_key, ""))])

func _validate_suite(suite: String) -> void:
	var movie_path := "%s/%s.avi" % [OUTPUT_ROOT, suite]
	if not FileAccess.file_exists(movie_path):
		_failures.append("Missing %s audit movie: %s" % [suite, movie_path])
	else:
		var movie := FileAccess.open(movie_path, FileAccess.READ)
		if movie == null or movie.get_length() < 1024:
			_failures.append("The %s audit movie is empty" % suite)
	var manifest := _read_json("%s/%s/manifest.json" % [OUTPUT_ROOT, suite])
	if manifest.is_empty():
		return
	if not (manifest.get("failures", []) as Array).is_empty():
		_failures.append("%s capture reported failures: %s" % [suite, manifest.get("failures", [])])
	if int(manifest.get("fps", 0)) != 30:
		_failures.append("%s manifest did not use fixed 30 FPS" % suite)
	var viewport_value: Variant = manifest.get("viewport", {})
	var viewport := viewport_value as Dictionary if viewport_value is Dictionary else {}
	if int(viewport.get("width", 0)) != VIEWPORT_SIZE.x or int(viewport.get("height", 0)) != VIEWPORT_SIZE.y:
		_failures.append("%s manifest did not use the 1280x720 audit viewport" % suite)
	var scenarios_value: Variant = manifest.get("scenarios", [])
	if not scenarios_value is Array:
		_failures.append("%s manifest scenarios are malformed" % suite)
		return
	var scenarios := scenarios_value as Array
	var expected := EXPECTED_SCENARIOS[suite] as Array
	if scenarios.size() != expected.size():
		_failures.append("%s manifest expected %d scenarios, found %d" % [suite, expected.size(), scenarios.size()])
	for expected_name: Variant in expected:
		var scenario := _scenario_named(scenarios, str(expected_name))
		if scenario.is_empty():
			_failures.append("%s manifest is missing %s" % [suite, expected_name])
			continue
		if int(scenario.get("endFrame", 0)) <= int(scenario.get("startFrame", 0)):
			_failures.append("%s has an invalid frame range" % expected_name)
		if str(scenario.get("expectedState", "")).is_empty():
			_failures.append("%s is missing its expected state" % expected_name)
		if not bool(scenario.get("sampledFramesDistinct", false)):
			_failures.append("%s did not contain distinct sampled frames" % expected_name)
		var keyframes_value: Variant = scenario.get("keyframes", {})
		var keyframes := keyframes_value as Dictionary if keyframes_value is Dictionary else {}
		for phase: String in ["start", "middle", "end"]:
			_validate_image(str(keyframes.get(phase, "")), VIEWPORT_SIZE, "%s %s" % [expected_name, phase])
		_validate_image(str(scenario.get("contactSheet", "")), CONTACT_SIZE, "%s contact sheet" % expected_name)
		if suite == "ui": _validate_ui_actions(scenario)

func _validate_ui_actions(scenario: Dictionary) -> void:
	var passed: Array[String] = []
	for check: Dictionary in scenario.get("checks", []):
		if bool(check.get("passed", false)): passed.append(str(check.get("label", "")))
		else: _failures.append("%s failed input check: %s" % [scenario.name, check.get("label", "")])
	for required: String in REQUIRED_UI_CHECKS.get(str(scenario.name), []):
		if not passed.has(required): _failures.append("%s lacks exercised input evidence: %s" % [scenario.name, required])
	if REQUIRED_DISPATCH_ORDER.has(str(scenario.name)):
		var methods: Array[String] = []
		for dispatch: Dictionary in scenario.get("dispatches", []): methods.append(str(dispatch.get("method", "")))
		if methods != REQUIRED_DISPATCH_ORDER[str(scenario.name)]: _failures.append("%s has incorrect actual dispatch order: %s" % [scenario.name, methods])
	var checkpoints: Dictionary = scenario.get("checkpoints", {})
	for label: String in checkpoints:
		_validate_image(str(checkpoints[label].get("path", "")), VIEWPORT_SIZE, str(scenario.name) + " " + label)
	if str(scenario.name) == "queued-errors-and-overflow":
		for required: String in ["worker-error", "worker-recovered"]:
			if not checkpoints.has(required): _failures.append("Separate %s checkpoint missing" % required)
		if checkpoints.has("worker-error") and checkpoints.has("worker-recovered"):
			if int(checkpoints["worker-error"].frame) >= int(checkpoints["worker-recovered"].frame): _failures.append("Error/recovery checkpoints are not temporally distinct")
			var error_state: Dictionary = checkpoints["worker-error"].get("uiState", {})
			var recovered_state: Dictionary = checkpoints["worker-recovered"].get("uiState", {})
			if not bool(error_state.get("connectionVisible", false)) or bool(error_state.get("workerConnected", true)): _failures.append("Error checkpoint does not prove visible offline state")
			if bool(recovered_state.get("connectionVisible", true)) or not bool(recovered_state.get("workerConnected", false)): _failures.append("Recovery checkpoint does not prove connected state")

func _scenario_named(scenarios: Array, wanted_name: String) -> Dictionary:
	for scenario_value: Variant in scenarios:
		if scenario_value is Dictionary:
			var scenario := scenario_value as Dictionary
			if str(scenario.get("name", "")) == wanted_name:
				return scenario
	return {}

func _validate_image(path: String, expected_size: Vector2i, label: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		_failures.append("Missing image for %s" % label)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_size() != expected_size:
		_failures.append("%s did not have size %dx%d" % [label, expected_size.x, expected_size.y])

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Could not read audit output: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_failures.append("Audit output is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary
