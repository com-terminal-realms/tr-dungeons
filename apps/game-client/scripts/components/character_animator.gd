extends Node
class_name CharacterAnimator

## Handles character animations based on movement state
## Simple version with basic idle animation

@export var movement_component_path: NodePath

var animation_player: AnimationPlayer
var movement_component: Node

func _ready() -> void:
	# Get AnimationPlayer from parent
	animation_player = get_parent().get_node_or_null("AnimationPlayer")
	
	if movement_component_path:
		movement_component = get_node(movement_component_path)
	
	if animation_player:
		print("CharacterAnimator: AnimationPlayer found")
		# Idle animation should auto-play
	else:
		print("CharacterAnimator: No AnimationPlayer found")

func _process(_delta: float) -> void:
	# For now, just keep idle animation playing
	# Future: Add walk/run animations based on movement
	pass
