class_name ArtifactRecord
extends RefCounted

var artifact_id: String = ""
var job_id: String = ""
var name: String = ""
var relative_path: String = ""
var media_type: String = ""

static func from_dictionary(data: Dictionary) -> ArtifactRecord:
	var artifact := ArtifactRecord.new()
	artifact.artifact_id = str(data.get("artifactId", ""))
	artifact.job_id = str(data.get("jobId", ""))
	artifact.name = str(data.get("name", ""))
	artifact.relative_path = str(data.get("relativePath", ""))
	artifact.media_type = str(data.get("mediaType", ""))
	return artifact
