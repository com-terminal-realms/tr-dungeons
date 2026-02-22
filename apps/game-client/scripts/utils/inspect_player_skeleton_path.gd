extends SceneTree

## Find the actual skeleton path in the player scene

func _init():
	print("=== INSPECTING PLAYER SCENE STRUCTURE ===")
	
	# Load player scene
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	
	print("Player node: ", player.name)
	_print_tree(player, 0)
	
	# Find skeleton and print its path
	var skeleton = _find_skeleton(player)
	if skeleton:
		print("\nFound Skeleton3D!")
		print("Skeleton node name: ", skeleton.name)
		print("Skeleton path from player root: ", player.get_path_to(skeleton))
		
		# Check if AnimationPlayer can find it
		var anim_player = player.get_node_or_null("CharacterModel/AnimationPlayer")
		if anim_player:
			print("\nAnimationPlayer found at: CharacterModel/AnimationPlayer")
			print("AnimationPlayer root node: ", anim_player.get_node(anim_player.root_node) if anim_player.root_node else "None")
	else:
		print("ERROR: No Skeleton3D found!")
	
	player.queue_free()
	quit()

func _print_tree(node: Node, indent: int):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	print(prefix, "- ", node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_tree(child, indent + 1)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null
