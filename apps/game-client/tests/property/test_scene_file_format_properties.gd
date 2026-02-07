## Property tests for scene file format validation
## **Property 16: Scene File Format Consistency**
## **Validates: Requirements 7.1**
extends GutTest

## Property 16: Scene File Format Consistency
## Verify all .tscn files are in text format (not binary)
func test_property_16_scene_file_format_consistency() -> void:
	var scene_files := _find_all_scene_files("res://")
	
	assert_gt(scene_files.size(), 0, "Should find at least one scene file")
	
	for scene_path in scene_files:
		# Read first line of file
		var file := FileAccess.open(scene_path, FileAccess.READ)
		assert_not_null(file, "Should be able to open scene file: %s" % scene_path)
		
		if file:
			var first_line := file.get_line()
			file.close()
			
			# Text format scenes start with [gd_scene
			# Binary format scenes start with RSRC or GDSC
			assert_true(
				first_line.begins_with("[gd_scene"),
				"Scene file must be in text format (not binary): %s\nFirst line: %s" % [scene_path, first_line]
			)
			
			# Verify it's a valid GDScript resource format
			assert_true(
				first_line.contains("format=3") or first_line.contains("format=2"),
				"Scene file must have valid format version: %s" % scene_path
			)

## Recursively find all .tscn files in directory
func _find_all_scene_files(dir_path: String) -> Array[String]:
	var scene_files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	
	if not dir:
		return scene_files
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		var full_path := dir_path.path_join(file_name)
		
		if dir.current_is_dir():
			# Skip hidden directories and addons
			if not file_name.begins_with(".") and file_name != "addons":
				scene_files.append_array(_find_all_scene_files(full_path))
		elif file_name.ends_with(".tscn"):
			scene_files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return scene_files
