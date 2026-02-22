extends Node
class_name RuntimeAnimationLoader

## Loads animations from UAL1_Standard.glb at runtime and adds them to AnimationPlayer

@export var animation_library_path: String = "res://assets/characters/animations/UAL1_Standard.glb"
@export var animation_player_path: NodePath

var animation_player: AnimationPlayer

func _ready() -> void:
	# Get the AnimationPlayer
	if animation_player_path:
		animation_player = get_node(animation_player_path)
	else:
		animation_player = get_parent().get_node_or_null("AnimationPlayer")
	
	if not animation_player:
		push_error("RuntimeAnimationLoader: No AnimationPlayer found!")
		return
	
	# Set the root node to the parent (CharacterModel) to ensure correct path resolution
	animation_player.root_node = animation_player.get_path_to(get_parent())
	print("RuntimeAnimationLoader: Set AnimationPlayer root_node to: ", animation_player.root_node)
	
	# Load the UAL scene
	var ual_scene = load(animation_library_path)
	if not ual_scene:
		push_error("RuntimeAnimationLoader: Failed to load ", animation_library_path)
		return
	
	# Instantiate it
	var ual_instance = ual_scene.instantiate()
	
	# Find the AnimationPlayer in the UAL scene
	var ual_anim_player = _find_animation_player(ual_instance)
	
	if not ual_anim_player:
		push_error("RuntimeAnimationLoader: No AnimationPlayer found in UAL scene")
		ual_instance.queue_free()
		return
	
	# Copy all animations
	var anim_list = ual_anim_player.get_animation_list()
	print("RuntimeAnimationLoader: Found ", anim_list.size(), " animations")
	
	# Create an animation library
	var anim_library = AnimationLibrary.new()
	
	for anim_name in anim_list:
		var animation = ual_anim_player.get_animation(anim_name)
		if animation:
			# Duplicate the animation so we own it
			var anim_copy = animation.duplicate()
			anim_library.add_animation(anim_name, anim_copy)
			print("RuntimeAnimationLoader: Loaded animation: ", anim_name)
	
	# Add the library to the player's AnimationPlayer
	animation_player.add_animation_library("", anim_library)
	
	# Clean up
	ual_instance.queue_free()
	
	print("RuntimeAnimationLoader: Successfully loaded ", animation_player.get_animation_list().size(), " animations")
	print("RuntimeAnimationLoader: AnimationPlayer root_node: ", animation_player.root_node)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null
