## Property-based tests for IsometricCamera
## Validates correctness properties across random inputs
extends "res://tests/test_utils/property_test.gd"

var camera: IsometricCamera
var target: Node3D

func before_each() -> void:
	# Create target
	target = Node3D.new()
	add_child(target)
	
	# Create camera
	camera = IsometricCamera.new()
	camera.target = target
	camera.distance = 15.0
	camera.zoom_min = 8.0
	camera.zoom_max = 25.0
	add_child(camera)
	
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	if camera:
		camera.queue_free()
	if target:
		target.queue_free()
	camera = null
	target = null

## Property 1: Isometric Camera Angle Invariant
## Validates: Requirements 3.3
## Ensures camera maintains 45° angle from horizontal (±1° tolerance)
func test_camera_angle_invariant() -> void:
	assert_property("Camera maintains 45° angle", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random player position
		var player_pos := random_vector3(rng, -50.0, 50.0)
		target.global_position = player_pos
		
		# Update camera position
		camera.update_camera_position()
		
		# Get camera angle
		var angle := camera.get_camera_angle()
		var expected_angle := 45.0
		var tolerance := 1.0
		
		var within_tolerance := abs(angle - expected_angle) <= tolerance
		
		return {
			"success": within_tolerance,
			"input": "player_pos=%s" % str(player_pos),
			"reason": "Camera angle %.2f° not within %.2f° ± %.2f°" % [
				angle, expected_angle, tolerance
			]
		}
	)

## Property 2: Camera Distance Bounds
## Validates: Requirements 3.3
## Ensures camera distance stays in [zoom_min, zoom_max]
func test_camera_distance_bounds() -> void:
	assert_property("Camera distance within bounds", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random zoom sequence
		var zoom_operations: Array[String] = []
		for i in range(10):
			if random_bool(rng):
				camera.distance -= 2.0  # Zoom in
				zoom_operations.append("in")
			else:
				camera.distance += 2.0  # Zoom out
				zoom_operations.append("out")
		
		var distance := camera.distance
		var within_bounds := distance >= camera.zoom_min and distance <= camera.zoom_max
		
		return {
			"success": within_bounds,
			"input": "ops=%s" % str(zoom_operations),
			"reason": "Distance %.2f not in [%.2f, %.2f]" % [
				distance, camera.zoom_min, camera.zoom_max
			]
		}
	)

## Property 3: Camera Rotation Invariant
## Validates: Requirements 3.3
## Ensures camera Y rotation remains constant at 45°
func test_camera_rotation_invariant() -> void:
	assert_property("Camera Y rotation constant at 45°", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random player movements
		var movements: Array[Vector3] = []
		for i in range(5):
			var movement := random_vector3(rng, -10.0, 10.0)
			target.global_position += movement
			movements.append(movement)
			camera.update_camera_position()
		
		# Get camera rotation around Y axis
		var rotation_y := camera.get_camera_rotation_y()
		var expected_rotation := 45.0
		var tolerance := 5.0  # Slightly larger tolerance due to atan2 precision
		
		# Normalize angle to [-180, 180]
		while rotation_y > 180.0:
			rotation_y -= 360.0
		while rotation_y < -180.0:
			rotation_y += 360.0
		
		var within_tolerance := abs(rotation_y - expected_rotation) <= tolerance
		
		return {
			"success": within_tolerance,
			"input": "movements=%d" % movements.size(),
			"reason": "Camera Y rotation %.2f° not within %.2f° ± %.2f°" % [
				rotation_y, expected_rotation, tolerance
			]
		}
	)
