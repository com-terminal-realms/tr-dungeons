extends SceneTree

## Measure character models to determine correct floor offset
## This script loads character scenes and measures their geometry to find
## where their feet are relative to their origin point

const PLAYER_SCENE = "res://scenes/player/player.tscn"
const ENEMY_SCENE = "res://scenes/enemies/enemy_base.tscn"

func _init():
	print("\n=== Character Floor Offset Measurement ===\n")
	
	# Measure player
	print("Measuring Player...")
	var player_offset = await _measure_character(PLAYER_SCENE, "Player")
	
	# Measure enemy
	print("\nMeasuring Enemy...")
	var enemy_offset = await _measure_character(ENEMY_SCENE, "Enemy")
	
	# Report results
	print("\n=== Measurement Results ===\n")
	print("Player floor offset: %.4f units" % player_offset)
	print("Enemy floor offset: %.4f units" % enemy_offset)
	
	print("\n=== Recommended Fix ===\n")
	print("Update PlacedCharacter height_offset in validate_character_positions.gd:")
	print("  Player: height_offset = %.4f" % player_offset)
	print("  Enemies: height_offset = %.4f" % enemy_offset)
	
	print("\nUpdate character Y positions in main.tscn:")
	print("  Player: y = %.4f" % player_offset)
	print("  Enemies: y = %.4f" % enemy_offset)
	
	quit(0)

func _measure_character(scene_path: String, character_name: String) -> float:
	# Load the scene
	var scene = load(scene_path)
	if scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		return 0.0
	
	# Instantiate the scene
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	
	# Find all MeshInstance3D nodes
	var meshes = _find_all_meshes(instance)
	print("  Found %d mesh instances" % meshes.size())
	
	if meshes.is_empty():
		print("  WARNING: No meshes found!")
		instance.queue_free()
		return 0.0
	
	# Calculate the lowest point of all meshes
	var lowest_y = INF
	var highest_y = -INF
	
	for mesh_instance in meshes:
		var mesh = mesh_instance.mesh
		if mesh == null:
			continue
		
		# Get the AABB of the mesh in local space
		var aabb = mesh.get_aabb()
		
		# Transform to world space
		var global_transform = mesh_instance.global_transform
		var world_aabb_min = global_transform * aabb.position
		var world_aabb_max = global_transform * (aabb.position + aabb.size)
		
		# Track lowest and highest points
		lowest_y = min(lowest_y, world_aabb_min.y)
		lowest_y = min(lowest_y, world_aabb_max.y)
		highest_y = max(highest_y, world_aabb_min.y)
		highest_y = max(highest_y, world_aabb_max.y)
	
	print("  Lowest point: Y = %.4f" % lowest_y)
	print("  Highest point: Y = %.4f" % highest_y)
	print("  Character height: %.4f units" % (highest_y - lowest_y))
	
	# The floor offset is the absolute value of the lowest point
	# If lowest_y is negative, the character's feet are below the origin
	# If lowest_y is positive, the character's feet are above the origin
	var floor_offset = -lowest_y
	
	print("  Floor offset (distance from origin to feet): %.4f units" % floor_offset)
	
	# Cleanup
	instance.queue_free()
	
	return floor_offset

func _find_all_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_meshes(child))
	
	return meshes
