extends SceneTree

## Automatically measure all character scenes and generate character_metadata.json
## This should be run whenever character models are added or updated

const CharacterMetadata = preload("res://scripts/utils/character_metadata.gd")
const CharacterMetadataDatabase = preload("res://scripts/utils/character_metadata_database.gd")

const OUTPUT_PATH = "res://data/character_metadata.json"

# Character scenes to measure
const CHARACTERS = [
	{
		"name": "player",
		"path": "res://scenes/player/player.tscn",
		"type": "player"
	},
	{
		"name": "enemy",
		"path": "res://scenes/enemies/enemy_base.tscn",
		"type": "enemy"
	}
]

var database: CharacterMetadataDatabase

func _init():
	print("\n=== Automated Character Measurement ===\n")
	
	database = CharacterMetadataDatabase.new()
	
	# Measure all characters
	for char_def in CHARACTERS:
		await _measure_and_store_character(char_def)
	
	# Save to JSON
	var result = database.save_to_json(OUTPUT_PATH)
	if result == OK:
		print("\n✅ Character metadata saved to: %s" % OUTPUT_PATH)
	else:
		push_error("Failed to save character metadata: %d" % result)
		quit(1)
		return
	
	# Print summary
	print("\n=== Measurement Summary ===\n")
	for metadata in database.get_all_characters():
		print("%s (%s):" % [metadata.character_name, metadata.character_type])
		print("  Floor offset: %.4f units" % metadata.floor_offset)
		print("  Height: %.4f units" % metadata.character_height)
		print("  Scene: %s" % metadata.scene_path)
	
	print("\n✅ All characters measured successfully!")
	print("\nNext steps:")
	print("1. Commit character_metadata.json to version control")
	print("2. Update validation scripts to use character metadata")
	print("3. Update scene positions using floor offsets")
	
	quit(0)

func _measure_and_store_character(char_def: Dictionary) -> void:
	print("Measuring %s..." % char_def.name)
	
	var scene_path = char_def.path
	var scene = load(scene_path)
	if scene == null:
		push_error("  Failed to load scene: %s" % scene_path)
		return
	
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	
	# Find all meshes
	var meshes = _find_all_meshes(instance)
	print("  Found %d mesh instances" % meshes.size())
	
	if meshes.is_empty():
		push_warning("  No meshes found!")
		instance.queue_free()
		return
	
	# Calculate bounding box
	var lowest_y = INF
	var highest_y = -INF
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for mesh_instance in meshes:
		var mesh = mesh_instance.mesh
		if mesh == null:
			continue
		
		var aabb = mesh.get_aabb()
		var global_transform = mesh_instance.global_transform
		
		# Transform AABB corners to world space
		var corners = [
			global_transform * aabb.position,
			global_transform * (aabb.position + Vector3(aabb.size.x, 0, 0)),
			global_transform * (aabb.position + Vector3(0, aabb.size.y, 0)),
			global_transform * (aabb.position + Vector3(0, 0, aabb.size.z)),
			global_transform * (aabb.position + Vector3(aabb.size.x, aabb.size.y, 0)),
			global_transform * (aabb.position + Vector3(aabb.size.x, 0, aabb.size.z)),
			global_transform * (aabb.position + Vector3(0, aabb.size.y, aabb.size.z)),
			global_transform * (aabb.position + aabb.size)
		]
		
		for corner in corners:
			lowest_y = min(lowest_y, corner.y)
			highest_y = max(highest_y, corner.y)
			min_x = min(min_x, corner.x)
			max_x = max(max_x, corner.x)
			min_z = min(min_z, corner.z)
			max_z = max(max_z, corner.z)
	
	# Create metadata
	var metadata = CharacterMetadata.new()
	metadata.character_name = char_def.name
	metadata.scene_path = scene_path
	metadata.character_type = char_def.type
	metadata.measurement_timestamp = Time.get_unix_time_from_system()
	
	# Floor offset is the absolute value of the lowest point
	# Positive = feet are below origin
	metadata.floor_offset = -lowest_y
	metadata.character_height = highest_y - lowest_y
	
	# Bounding box (relative to origin)
	metadata.bounding_box = AABB(
		Vector3(min_x, lowest_y, min_z),
		Vector3(max_x - min_x, highest_y - lowest_y, max_z - min_z)
	)
	
	# Collision approximation (cylinder)
	var radius = max(max_x - min_x, max_z - min_z) / 2.0
	metadata.collision_radius = radius
	metadata.collision_height = metadata.character_height
	
	print("  Floor offset: %.4f units" % metadata.floor_offset)
	print("  Height: %.4f units" % metadata.character_height)
	print("  Collision radius: %.4f units" % metadata.collision_radius)
	
	# Store in database
	database.add_character(metadata)
	
	# Cleanup
	instance.queue_free()

func _find_all_meshes(node: Node) -> Array:
	var meshes: Array = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_meshes(child))
	
	return meshes
