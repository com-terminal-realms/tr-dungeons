class_name CharacterMetadataDatabase
extends RefCounted

## Database of character measurements
## Stores floor offsets and dimensions for all character types

var characters: Dictionary = {}  # character_name -> CharacterMetadata

func add_character(metadata: CharacterMetadata) -> void:
	characters[metadata.character_name] = metadata

func get_character(character_name: String) -> CharacterMetadata:
	return characters.get(character_name, null)

func has_character(character_name: String) -> bool:
	return characters.has(character_name)

func get_all_characters() -> Array:
	var result: Array = []
	for metadata in characters.values():
		result.append(metadata)
	return result

func to_dict() -> Dictionary:
	var data = {
		"version": "1.0",
		"characters": {}
	}
	
	for char_name in characters:
		data["characters"][char_name] = characters[char_name].to_dict()
	
	return data

func from_dict(data: Dictionary) -> void:
	characters.clear()
	
	var chars = data.get("characters", {})
	for char_name in chars:
		var metadata = CharacterMetadata.new()
		metadata.from_dict(chars[char_name])
		characters[char_name] = metadata

func save_to_json(file_path: String) -> Error:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: %s" % file_path)
		return FileAccess.get_open_error()
	
	var json_string = JSON.stringify(to_dict(), "\t")
	file.store_string(json_string)
	file.close()
	
	return OK

func load_from_json(file_path: String) -> Error:
	if not FileAccess.file_exists(file_path):
		push_warning("Character metadata file does not exist: %s" % file_path)
		return ERR_FILE_NOT_FOUND
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: %s" % file_path)
		return FileAccess.get_open_error()
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse JSON from %s: %s" % [file_path, json.get_error_message()])
		return parse_result
	
	from_dict(json.data)
	return OK
