## Property-based tests for Movement component
## Validates correctness properties across random inputs
extends "res://tests/test_utils/property_test.gd"

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

## Property 4: Movement Velocity Magnitude
## Validates: Requirements 3.4
## Ensures velocity magnitude equals move_speed when moving (±0.01 tolerance)
func test_movement_velocity_magnitude() -> void:
	assert_property_holds("Velocity magnitude equals move_speed", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random direction
		var direction := random_direction(rng)
		
		# Apply movement
		movement.move(direction, 0.016)  # Fixed delta for consistency
		
		var velocity_mag := movement.get_velocity_magnitude()
		var expected_speed := movement.move_speed
		var tolerance := 0.01
		
		var within_tolerance: bool = abs(velocity_mag - expected_speed) <= tolerance
		
		return {
			"success": within_tolerance,
			"input": "direction=%s" % str(direction),
			"reason": "Velocity magnitude %.3f not equal to move_speed %.3f (tolerance ±%.3f)" % [
				velocity_mag, expected_speed, tolerance
			]
		}
	)

## Property 5: Movement Direction Alignment
## Validates: Requirements 3.4
## Ensures character faces movement direction (±5° tolerance)
func test_movement_direction_alignment() -> void:
	assert_property_holds("Character faces movement direction", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random direction (horizontal only - Y=0)
		var direction := Vector3(
			random_float(rng, -1.0, 1.0),
			0.0,  # No vertical component
			random_float(rng, -1.0, 1.0)
		).normalized()
		
		# Apply movement multiple times to allow rotation to settle
		for i in range(10):
			movement.move(direction, 0.1)  # Larger delta for faster rotation
		
		var facing := movement.get_facing_direction()
		
		# Calculate angle between facing and movement direction
		var dot_product := facing.dot(direction)
		dot_product = clamp(dot_product, -1.0, 1.0)  # Clamp for acos safety
		var angle_rad := acos(dot_product)
		var angle_deg := rad_to_deg(angle_rad)
		
		var tolerance_deg := 5.0
		var aligned := angle_deg <= tolerance_deg
		
		return {
			"success": aligned,
			"input": "direction=%s" % str(direction),
			"reason": "Facing angle %.1f° exceeds tolerance %.1f°" % [angle_deg, tolerance_deg]
		}
	)
