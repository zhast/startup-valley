class_name EmployeeRecord
extends RefCounted

var id: String = ""
var display_name: String = ""
var desk_grid: Vector2i = Vector2i.ZERO
var morale: int = 50
var assignment: String = ""
var memory_line: String = ""

static func from_dictionary(data: Dictionary) -> EmployeeRecord:
	var employee := EmployeeRecord.new()
	employee.id = str(data.get("id", ""))
	employee.display_name = str(data.get("name", employee.id))
	employee.desk_grid = Vector2i(int(data.get("deskX", 0)), int(data.get("deskY", 0)))
	employee.morale = int(data.get("morale", 50))
	employee.assignment = str(data.get("assignment", ""))
	return employee
