class_name LayoutValidationResult
extends RefCounted

## Result of validating a dungeon layout

var is_valid: bool = true
var has_gap: bool = false
var has_overlap: bool = false
var gap_distance: float = 0.0
var normals_aligned: bool = true
var error_messages: Array[String] = []

func _init():
	is_valid = true
	has_gap = false
	has_overlap = false
	gap_distance = 0.0
	normals_aligned = true
	error_messages = []

## Add an error message and mark as invalid
func add_error(message: String) -> void:
	error_messages.append(message)
	is_valid = false

## Get a summary of validation results
func get_summary() -> String:
	if is_valid:
		return "Layout is valid"
	
	var summary = "Layout validation failed:\n"
	for msg in error_messages:
		summary += "  - %s\n" % msg
	return summary
