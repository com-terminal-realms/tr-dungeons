## Movement component for entities
## Handles velocity application and character rotation
## Uses MovementData model for data storage (future orb-schema-generator output)
class_name Movement
extends Node

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0

var _data: MovementData
var _character_body: CharacterBody3D

func _ready() -> void:
	_data = MovementData.new({"move_speed": move_speed, "rotation_speed": rotation_speed})
	var validation: Dictionary = _data.validate()
	if not validation["valid"]:
		push_error("Movement component invalid: %s" % validation["errors"])
		move_speed = 5.0
		rotation_speed = 10.0
		_data = MovementData.new({"move_speed": 5.0, "rotation_speed": 10.0})
	
	# Find CharacterBody3D parent
	_character_body = _find_character_body(get_parent())
	if not _character_body:
		push_error("Movement component requires CharacterBody3D parent or ancestor")

## Move the character in the given direction
## direction: Normalized direction vector (will be normalized if not already)
## delta: Frame delta time
## Handles both velocity application and character rotation to face movement direction
func move(direction: Vector3, delta: float = 0.0) -> void:
	if not _character_body:
		push_error("Cannot move: CharacterBody3D not found")
		return
	
	# Use physics delta if not provided
	if delta <= 0.0:
		delta = get_physics_process_delta_time()
	
	# Normalize direction if not already
	if direction.length() > 0.001:
		direction = direction.normalized()
	else:
		# No movement
		_character_body.velocity = Vector3.ZERO
		_character_body.move_and_slide()
		return
	
	# Apply velocity
	var velocity := direction * _data.move_speed
	_character_body.velocity = velocity
	
	# Rotate character to face movement direction
	# Uses standard atan2(x, z) for forward-facing rotation
	if direction.length() > 0.001:
		var target_rotation := atan2(direction.x, direction.z)
		var current_rotation := _character_body.rotation.y
		
		# Smooth rotation using lerp
		var new_rotation := lerp_angle(current_rotation, target_rotation, _data.rotation_speed * delta)
		_character_body.rotation.y = new_rotation
	
	# Apply movement
	_character_body.move_and_slide()

## Get current velocity magnitude
func get_velocity_magnitude() -> float:
	if not _character_body:
		return 0.0
	return _character_body.velocity.length()

## Get current velocity direction (normalized)
func get_velocity_direction() -> Vector3:
	if not _character_body:
		return Vector3.ZERO
	var vel := _character_body.velocity
	if vel.length() > 0.001:
		return vel.normalized()
	return Vector3.ZERO

## Get current facing direction
func get_facing_direction() -> Vector3:
	if not _character_body:
		return Vector3.FORWARD
	var rotation_y := _character_body.rotation.y
	return Vector3(sin(rotation_y), 0, cos(rotation_y)).normalized()

## Get movement data model (for serialization)
func get_data() -> MovementData:
	return _data

## Set movement from data model (for deserialization)
func set_data(data: MovementData) -> void:
	_data = data
	move_speed = _data.move_speed
	rotation_speed = _data.rotation_speed

## Find CharacterBody3D in parent hierarchy
func _find_character_body(node: Node) -> CharacterBody3D:
	if node is CharacterBody3D:
		return node
	if node.get_parent():
		return _find_character_body(node.get_parent())
	return null
