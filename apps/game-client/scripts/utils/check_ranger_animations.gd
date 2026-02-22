extends SceneTree

func _init():
	print("=== CHECKING MALE_RANGER ANIMATIONS ===")
	
	var ranger_scene = load("res://assets/characters/outfits/Male_Ranger.gltf")
	var ranger = ranger_scene.instantiate()
	
	var anim_player = _find_animation_player(ranger)
	if anim_player:
		print("Found AnimationPlayer in Male_Ranger.gltf")
		print("Animations: ", anim_player.get_animation_list())
	else:
		print("No AnimationPlayer in Male_Ranger.gltf")
	
	ranger.queue_free()
	quit()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
