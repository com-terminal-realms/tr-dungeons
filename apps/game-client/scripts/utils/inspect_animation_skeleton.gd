extends SceneTree

## Inspect animation tracks and skeleton bones to diagnose retargeting issues

func _init():
	print("=== INSPECTING CHARACTER SKELETON ===")
	
	# Load character model
	var character_scene = load("res://assets/characters/outfits/Male_Ranger.gltf")
	var character = character_scene.instantiate()
	
	# Find skeleton
	var skeleton = _find_skeleton(character)
	if skeleton:
		print("Found Skeleton3D with ", skeleton.get_bone_count(), " bones")
		print("\nBone names:")
		for i in range(skeleton.get_bone_count()):
			print("  [", i, "] ", skeleton.get_bone_name(i))
	else:
		print("ERROR: No Skeleton3D found in character!")
	
	character.queue_free()
	
	print("\n=== INSPECTING ANIMATION TRACKS ===")
	
	# Load animation library
	var anim_scene = load("res://assets/characters/animations/UAL1_Standard.glb")
	var anim_instance = anim_scene.instantiate()
	
	# Find AnimationPlayer
	var anim_player = _find_animation_player(anim_instance)
	if anim_player:
		print("Found AnimationPlayer with ", anim_player.get_animation_list().size(), " animations")
		
		# Inspect Sword_Attack animation
		if anim_player.has_animation("Sword_Attack"):
			var anim = anim_player.get_animation("Sword_Attack")
			print("\nSword_Attack animation:")
			print("  Length: ", anim.length, " seconds")
			print("  Track count: ", anim.get_track_count())
			print("\nFirst 10 track paths:")
			for i in range(min(10, anim.get_track_count())):
				var track_path = anim.track_get_path(i)
				var track_type = anim.track_get_type(i)
				print("  [", i, "] ", track_path, " (type: ", track_type, ")")
	else:
		print("ERROR: No AnimationPlayer found in animation library!")
	
	anim_instance.queue_free()
	
	quit()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
