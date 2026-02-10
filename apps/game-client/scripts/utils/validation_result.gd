class_name ValidationResult
extends RefCounted

## Result of validating a connection or layout

var is_valid: bool = true
var has_gap: bool = false
var has_overlap: bool = false
var gap_distance: float = 0.0
var normals_aligned: bool = true
var error_messages: Array[String] = []

func add_error(message: String) -> void:
	error_messages.append(message)
	is_valid = false

func get_description() -> String:
	if is_valid:
		return "Validation passed"
	
	var result = "Validation failed:\n"
	for msg in error_messages:
		result += "  - " + msg + "\n"
	
	if has_gap:
		result += "  - Gap detected: %.3f units\n" % gap_distance
	if has_overlap:
		result += "  - Overlap detected: %.3f units\n" % abs(gap_distance)
	if not normals_aligned:
		result += "  - Connection normals not aligned\n"
	
	return result
