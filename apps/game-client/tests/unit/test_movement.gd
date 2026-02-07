## Unit tests for Movement component
## Tests specific examples and edge cases
extends "res://addons/gut/test.gd"

var movement: Movement
var character_body: CharacterBody3D

func before_each() -> void:
	# Create CharacterBody3D parent
	character_body = CharacterBody3D.new()
	add_child(character_body)
	
	# Create Movement component as child
	movement = Movement.new()
	movement.move_speed = 5.0
	movement.rotation_speed = 10.0
	character_body.add_child(movement)
	
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	if character_body:
		character_body.queue_free()
	character_body = null
	movement = null

## Test: Movement initialized correctly
func test_movement_initialized() -> void:
	assert_eq(movement.move_speed, 5.0, "Move speed should be initialized")
	assert_eq(movement.rotation_speed, 10.0, "Rotation speed should be initialized")
	assert_not_null(movement._character_body, "CharacterBody3D should be found")

## Test: Zero direction results in zero velocity
func test_zero_direction_zero_velocity() -> void:
	movement.move(Vector3.ZERO, 0.016)
	
	assert_eq(movement.get_velocity_magnitude(), 0.0, "Zero direction should result in zero velocity")

## Test: Forward movement
func test_forward_movement() -> void:
	movement.move(Vector3.FORWARD, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Forward movement should have correct speed")

## Test: Backward movement
func test_backward_movement() -> void:
	movement.move(Vector3.BACK, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Backward movement should have correct speed")

## Test: Left movement
func test_left_movement() -> void:
	movement.move(Vector3.LEFT, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Left movement should have correct speed")

## Test: Right movement
func test_right_movement() -> void:
	movement.move(Vector3.RIGHT, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Right movement should have correct speed")

## Test: Diagonal movement (normalized)
func test_diagonal_movement() -> void:
	var diagonal := (Vector3.FORWARD + Vector3.RIGHT).normalized()
	movement.move(diagonal, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Diagonal movement should have correct speed")

## Test: Non-normalized direction gets normalized
func test_non_normalized_direction() -> void:
	var non_normalized := Vector3(2.0, 0.0, 2.0)  # Length > 1
	movement.move(non_normalized, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 5.0, 0.01, "Non-normalized direction should be normalized")

## Test: Character rotates to face movement direction
func test_character_rotation() -> void:
	# Move forward multiple times to allow rotation to settle
	for i in range(20):
		movement.move(Vector3.FORWARD, 0.1)
	
	var facing := movement.get_facing_direction()
	var dot_product := facing.dot(Vector3.FORWARD)
	
	assert_gt(dot_product, 0.99, "Character should face forward direction")

## Test: Get velocity direction
func test_get_velocity_direction() -> void:
	movement.move(Vector3.RIGHT, 0.016)
	
	var vel_dir := movement.get_velocity_direction()
	var dot_product := vel_dir.dot(Vector3.RIGHT)
	
	assert_almost_eq(dot_product, 1.0, 0.01, "Velocity direction should match movement direction")

## Test: Get facing direction
func test_get_facing_direction() -> void:
	# Move right multiple times to allow rotation
	for i in range(20):
		movement.move(Vector3.RIGHT, 0.1)
	
	var facing := movement.get_facing_direction()
	assert_almost_eq(facing.length(), 1.0, 0.01, "Facing direction should be normalized")

## Test: Data model serialization
func test_data_serialization() -> void:
	var data := movement.get_data()
	var dict := data.to_dict()
	
	assert_eq(dict["move_speed"], 5.0, "Serialized move_speed should be correct")
	assert_eq(dict["rotation_speed"], 10.0, "Serialized rotation_speed should be correct")
	
	# Test deserialization
	var new_data := MovementData.from_dict(dict)
	assert_eq(new_data.move_speed, 5.0, "Deserialized move_speed should be correct")
	assert_eq(new_data.rotation_speed, 10.0, "Deserialized rotation_speed should be correct")

## Test: Data model validation
func test_data_validation() -> void:
	var invalid_data := MovementData.new({"move_speed": -5.0, "rotation_speed": -10.0})
	var validation := invalid_data.validate()
	
	assert_false(validation["valid"], "Invalid data should fail validation")
	assert_gt(validation["errors"].size(), 0, "Validation should report errors")

## Test: Movement without CharacterBody3D parent
func test_movement_without_character_body() -> void:
	# Create standalone movement component
	var standalone_movement := Movement.new()
	add_child(standalone_movement)
	await get_tree().process_frame
	
	# Should not crash, but should log error
	standalone_movement.move(Vector3.FORWARD, 0.016)
	
	assert_eq(standalone_movement.get_velocity_magnitude(), 0.0, "Movement without CharacterBody3D should have zero velocity")
	
	standalone_movement.queue_free()

## Test: Custom move speed
func test_custom_move_speed() -> void:
	movement.move_speed = 10.0
	movement._data.move_speed = 10.0
	
	movement.move(Vector3.FORWARD, 0.016)
	
	var velocity_mag := movement.get_velocity_magnitude()
	assert_almost_eq(velocity_mag, 10.0, 0.01, "Custom move speed should be applied")

## Test: Custom rotation speed
func test_custom_rotation_speed() -> void:
	movement.rotation_speed = 50.0
	movement._data.rotation_speed = 50.0
	
	# Move with high rotation speed
	for i in range(5):
		movement.move(Vector3.RIGHT, 0.1)
	
	var facing := movement.get_facing_direction()
	var dot_product := facing.dot(Vector3.RIGHT)
	
	# Should rotate faster with higher rotation speed
	assert_gt(dot_product, 0.9, "Higher rotation speed should rotate faster")
