class_name AssetMetadataDatabase
extends Resource

## Stores and retrieves asset metadata with version history

# Current metadata storage: asset_name -> AssetMetadata
var _metadata: Dictionary = {}

# Version history: asset_name -> Array[AssetMetadata]
var _version_history: Dictionary = {}

## Store metadata for an asset
## If metadata already exists, previous version is saved to history
func store(metadata: AssetMetadata) -> void:
	if metadata == null or metadata.asset_name.is_empty():
		push_error("AssetMetadataDatabase: Cannot store null or unnamed metadata")
		return
	
	var asset_name = metadata.asset_name
	
	# If metadata already exists, save it to version history
	if _metadata.has(asset_name):
		if not _version_history.has(asset_name):
			_version_history[asset_name] = []
		_version_history[asset_name].append(_metadata[asset_name])
	
	# Store new metadata
	_metadata[asset_name] = metadata

## Get metadata for an asset
## Returns null if asset not found
func get_metadata(asset_name: String) -> AssetMetadata:
	return _metadata.get(asset_name)

## Check if metadata exists for an asset
func has_metadata(asset_name: String) -> bool:
	return _metadata.has(asset_name)

## Get version history for an asset
## Returns empty array if no history exists
func get_version_history(asset_name: String) -> Array:
	if _version_history.has(asset_name):
		return _version_history[asset_name]
	return []

## Get all asset names in the database
func get_all_asset_names() -> Array:
	var names: Array = []
	for key in _metadata.keys():
		names.append(key)
	return names

## Clear all metadata and history
func clear() -> void:
	_metadata.clear()
	_version_history.clear()

## Save database to JSON file
func save_to_json(path: String) -> void:
	var data = {
		"metadata": {},
		"version_history": {}
	}
	
	# Convert metadata to dictionaries
	for key in _metadata:
		data["metadata"][key] = _metadata[key].to_dict()
	
	# Convert version history to dictionaries
	for key in _version_history:
		var history_array = []
		for metadata in _version_history[key]:
			history_array.append(metadata.to_dict())
		data["version_history"][key] = history_array
	
	# Write to file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("AssetMetadataDatabase: Failed to open file for writing: %s" % path)
		return
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Load database from JSON file
func load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("AssetMetadataDatabase: File not found: %s" % path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("AssetMetadataDatabase: Failed to open file for reading: %s" % path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null:
		push_error("AssetMetadataDatabase: Failed to parse JSON from file: %s" % path)
		return
	
	# Clear existing data
	clear()
	
	# Load metadata
	if data.has("metadata"):
		for key in data["metadata"]:
			var metadata = AssetMetadata.new()
			metadata.from_dict(data["metadata"][key])
			_metadata[key] = metadata
	
	# Load version history
	if data.has("version_history"):
		for key in data["version_history"]:
			var history_array: Array[AssetMetadata] = []
			for metadata_dict in data["version_history"][key]:
				var metadata = AssetMetadata.new()
				metadata.from_dict(metadata_dict)
				history_array.append(metadata)
			_version_history[key] = history_array
