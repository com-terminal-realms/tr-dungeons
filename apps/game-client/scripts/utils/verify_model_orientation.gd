extends SceneTree

## Verify that character models are facing forward (negative Z direction)

func _init():
	print("=== VERIFYING MODEL ORIENTATION ===")
	
	# Load Male_Ranger
	var ranger_scene = load("res://assets/characters/outfits/Male_Ranger.gltf")
	var ranger = ranger_scene.instantiate()
	
	print("\nMale_Ranger.gltf:")
	print("  Root node: ", ranger.name)
	
	# Find the Armature node
	var armature = _find_node_by_name(ranger, "Armature")
	if armature:
		print("  Armature transform: ", armature.transform)
		print("  Armature rotation (degrees): ", armature.rotation_degrees)
		print("  Armature forward direction (-Z): ", -armature.global_transform.basis.z)
	else:
		print("  No Armature found")
	
	# Check if there's a root rotation
	print("  Root transform: ", ranger.transform)
	print("  Root rotation (degrees): ", ranger.rotation_degrees)
	
	ranger.queue_free()
	
	print("\n=== EXPECTED ===")
	print("  If model is facing forward correctly:")
	print("  - Armature rotation Y should be 180 degrees (or -180)")
	print("  - OR Root rotation Y should be 180 degrees")
	print("  - Forward direction should point in negative Z (0, 0, -1)")
	
	quit()

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	return null
