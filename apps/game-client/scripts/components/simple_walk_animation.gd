extends Node
class_name SimpleWalkAnimation

## Simple procedural walk animation without requiring animation library
## Makes the character bob up and down when moving

@export var bob_height: float = 0.1
@export var bob_speed: float = 10.0
@export var movement_component_path: NodePath

var movement_component: Node
var character_model: Node3D
var time: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	if movement_component_path:
		movement_component = get_node(movement_component_path)
	
	# Find the CharacterModel node
	character_model = get_parent().get_node_or_null("CharacterModel")
	if character_model:
		base_y = character_model.position.y

func _process(delta: float) -> void:
	if not character_model or not movement_component:
		return
	
	# Check if character is moving
	var is_moving = false
	if movement_component.has_method("get_velocity"):
		var velocity = movement_component.get_velocity()
		is_moving = velocity.length() > 0.1
	elif "velocity" in movement_component:
		is_moving = movement_component.velocity.length() > 0.1
	
	if is_moving:
		# Bob up and down when moving
		time += delta * bob_speed
		var bob_offset = sin(time) * bob_height
		character_model.position.y = base_y + bob_offset
	else:
		# Return to base position when stopped
		time = 0.0
		character_model.position.y = lerp(character_model.position.y, base_y, delta * 5.0)
