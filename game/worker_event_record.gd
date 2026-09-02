class_name WorkerEventRecord
extends RefCounted

var type: StringName = &""
var summary: String = ""
var tool: String = ""
var label: String = ""
var ok: bool = false
var approval_id: String = ""
var action: String = ""
var artifact_id: String = ""
var name: String = ""
var input_tokens: int = 0
var output_tokens: int = 0
var cost: float = 0.0
var reason: String = ""
var error: String = ""

static func from_dictionary(data: Dictionary) -> WorkerEventRecord:
	var event := WorkerEventRecord.new()
	event.type = StringName(str(data.get("type", "")))
	event.summary = str(data.get("summary", ""))
	event.tool = str(data.get("tool", ""))
	event.label = str(data.get("label", ""))
	event.ok = bool(data.get("ok", false))
	event.approval_id = str(data.get("approvalId", ""))
	event.action = str(data.get("action", ""))
	event.artifact_id = str(data.get("artifactId", ""))
	event.name = str(data.get("name", ""))
	event.input_tokens = int(data.get("inputTokens", 0))
	event.output_tokens = int(data.get("outputTokens", 0))
	event.cost = float(data.get("cost", 0.0))
	event.reason = str(data.get("reason", ""))
	event.error = str(data.get("error", ""))
	return event
