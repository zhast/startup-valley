extends RefCounted
## Audit overrides may select only a strict descendant of developer output.
static func valid(value: String) -> bool:
	if value.is_empty(): return true
	const PREFIX := "res://tests/output/"
	if not value.begins_with(PREFIX) or value.contains("\\"): return false
	for index: int in range(value.length()):
		if value.unicode_at(index) < 32: return false
	for segment: String in value.trim_prefix(PREFIX).split("/", true):
		if segment in ["", ".", ".."] or segment.contains(":"): return false
	return true
