class_name StudioFileRecord
extends RefCounted

var name: String = ""
var relative_path: String = ""
var media_type: String = ""
var source_job_id: String = ""
var promoted_at: String = ""

static func from_dictionary(data: Dictionary) -> StudioFileRecord:
	var file := StudioFileRecord.new()
	file.name = str(data.get("name", ""))
	file.relative_path = str(data.get("relativePath", ""))
	file.media_type = str(data.get("mediaType", ""))
	file.source_job_id = str(data.get("sourceJobId", ""))
	file.promoted_at = str(data.get("promotedAt", ""))
	return file
