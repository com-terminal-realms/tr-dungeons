## Property-based tests for Door placement and dimensions
## Validates correctness properties for door geometry and collision
# Feature: interactive-doors
extends "res://tests/test_utils/property_test.gd"

var door_scene: PackedScene

func before_all() -> void:
	door_scene = load("res://scenes/door.tscn")
	if not door_scene:
		push_error("Failed to load door scene from res://scenes/door.tscn")

## Property 8: Interaction Zone Dimensions
## Validates: Requirements 2.5
## For any door instance, the interaction zone Area3D collision shape should extend 3 units from the door center in all directions
func test_interaction_zone_dimensions() -> void:
	assert_property_holds("Interaction zone extends 3 units in all directions", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Instantiate a fresh door for this iteration
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Failed to instantiate door from scene"
			}
		
		# Set random position for door
		var random_pos := random_vector3(rng, -50.0, 50.0)
		test_door.position = random_pos
		
		# Get interaction area and its collision shape
		var interaction_area: Area3D = test_door.get_node("InteractionArea")
		if not interaction_area:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s" % str(random_pos),
				"reason": "InteractionArea node not found"
			}
		
		var collision_shape: CollisionShape3D = interaction_area.get_node("CollisionShape3D")
		if not collision_shape:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s" % str(random_pos),
				"reason": "CollisionShape3D not found in InteractionArea"
			}
		
		var shape := collision_shape.shape
		if not shape is SphereShape3D:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s" % str(random_pos),
				"reason": "Interaction zone shape is not SphereShape3D, got %s" % str(shape.get_class())
			}
		
		var sphere_shape := shape as SphereShape3D
		var radius: float = sphere_shape.radius
		var expected_radius: float = 3.0
		var tolerance: float = 0.01
		
		var radius_correct: bool = abs(radius - expected_radius) < tolerance
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": radius_correct,
			"input": "position=%s" % str(random_pos),
			"reason": "Interaction zone radius is %f, expected %f" % [radius, expected_radius]
		}
	)

## Property 14: Collision Shape Dimensions
## Validates: Requirements 4.4
## For any door instance, the collision shape dimensions should match the door geometry (5.2×4.4×1.4 units)
func test_collision_shape_dimensions() -> void:
	assert_property_holds("Collision shape matches door geometry dimensions", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Instantiate a fresh door for this iteration
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Failed to instantiate door from scene"
			}
		
		# Set random position and rotation for door
		var random_pos := random_vector3(rng, -50.0, 50.0)
		var random_rot := Vector3(0, rng.randf_range(0, 360), 0)
		test_door.position = random_pos
		test_door.rotation_degrees = random_rot
		
		# Get collision body and its collision shape
		var collision_body: StaticBody3D = test_door.get_node("CollisionBody")
		if not collision_body:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s, rotation=%s" % [str(random_pos), str(random_rot)],
				"reason": "CollisionBody node not found"
			}
		
		var collision_shape: CollisionShape3D = collision_body.get_node("CollisionShape3D")
		if not collision_shape:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s, rotation=%s" % [str(random_pos), str(random_rot)],
				"reason": "CollisionShape3D not found in CollisionBody"
			}
		
		var shape := collision_shape.shape
		if not shape is BoxShape3D:
			test_door.queue_free()
			return {
				"success": false,
				"input": "position=%s, rotation=%s" % [str(random_pos), str(random_rot)],
				"reason": "Collision shape is not BoxShape3D, got %s" % str(shape.get_class())
			}
		
		var box_shape := shape as BoxShape3D
		var size: Vector3 = box_shape.size
		
		# Expected dimensions from requirements (gate-door.glb bounding box)
		var expected_size: Vector3 = Vector3(5.2, 4.4, 1.4)
		var tolerance: float = 0.1
		
		var size_correct: bool = (
			abs(size.x - expected_size.x) < tolerance and
			abs(size.y - expected_size.y) < tolerance and
			abs(size.z - expected_size.z) < tolerance
		)
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": size_correct,
			"input": "position=%s, rotation=%s" % [str(random_pos), str(random_rot)],
			"reason": "Collision shape size is %s, expected %s" % [str(size), str(expected_size)]
		}
	)
