## Test helper utilities for dungeon asset mapping system
## Provides generators for random test data
class_name AssetTestHelpers
extends RefCounted

## Generate random AssetMetadata with valid dimensions
static func generate_random_asset_metadata(rng: RandomNumberGenerator) -> AssetMetadata:
	var metadata = AssetMetadata.new()
	
	# Basic info
	metadata.asset_name = "test_asset_%d" % rng.randi()
	metadata.asset_path = "res://test/asset_%d.glb" % rng.randi()
	metadata.asset_format = ["GLB", "FBX"].pick_random()
	metadata.asset_source = ["Kenney", "Synty", "Custom"].pick_random()
	metadata.measurement_timestamp = Time.get_unix_time_from_system()
	
	# Dimensions (reasonable ranges for dungeon assets)
	var size = Vector3(
		rng.randf_range(1.0, 10.0),
		rng.randf_range(2.0, 5.0),
		rng.randf_range(1.0, 10.0)
	)
	var position = Vector3(
		rng.randf_range(-5.0, 5.0),
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-5.0, 5.0)
	)
	metadata.bounding_box = AABB(position, size)
	
	metadata.origin_offset = Vector3(
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-2.0, 2.0)
	)
	
	metadata.floor_height = rng.randf_range(-0.5, 0.5)
	metadata.wall_thickness = rng.randf_range(0.1, 0.5)
	
	# Connection points (1-4 random connections)
	var num_connections = rng.randi_range(1, 4)
	for i in range(num_connections):
		metadata.connection_points.append(generate_random_connection_point(rng))
	
	# Doorway dimensions
	metadata.doorway_dimensions = Vector2(
		rng.randf_range(1.0, 3.0),
		rng.randf_range(2.0, 4.0)
	)
	
	# Collision shapes (1-3 random shapes)
	var num_shapes = rng.randi_range(1, 3)
	for i in range(num_shapes):
		metadata.collision_shapes.append(generate_random_collision_data(rng))
	
	# Walkable area (smaller than bounding box)
	var walkable_size = Vector3(
		size.x * rng.randf_range(0.5, 0.9),
		0.1,
		size.z * rng.randf_range(0.5, 0.9)
	)
	var walkable_pos = Vector3(
		position.x + (size.x - walkable_size.x) / 2.0,
		metadata.floor_height,
		position.z + (size.z - walkable_size.z) / 2.0
	)
	metadata.walkable_area = AABB(walkable_pos, walkable_size)
	
	# Rotation
	metadata.default_rotation = Vector3(0, rng.randf_range(0, TAU), 0)
	metadata.rotation_pivot = Vector3.ZERO
	
	metadata.measurement_accuracy = 0.1
	
	return metadata

## Generate random ConnectionPoint with valid position and normal
static func generate_random_connection_point(rng: RandomNumberGenerator) -> ConnectionPoint:
	var point = ConnectionPoint.new()
	
	point.position = Vector3(
		rng.randf_range(-5.0, 5.0),
		rng.randf_range(0.0, 3.0),
		rng.randf_range(-5.0, 5.0)
	)
	
	# Generate normalized normal vector (one of the cardinal directions)
	var normals = [
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3.LEFT,
		Vector3.RIGHT
	]
	point.normal = normals.pick_random()
	
	point.type = ["door", "corridor_end", "opening"].pick_random()
	
	point.dimensions = Vector2(
		rng.randf_range(1.0, 3.0),
		rng.randf_range(2.0, 4.0)
	)
	
	return point

## Generate random CollisionData
static func generate_random_collision_data(rng: RandomNumberGenerator) -> CollisionData:
	var collision = CollisionData.new()
	
	collision.shape_type = ["box", "sphere", "capsule"].pick_random()
	
	collision.position = Vector3(
		rng.randf_range(-5.0, 5.0),
		rng.randf_range(0.0, 3.0),
		rng.randf_range(-5.0, 5.0)
	)
	
	if collision.shape_type == "box":
		collision.size = Vector3(
			rng.randf_range(1.0, 5.0),
			rng.randf_range(1.0, 4.0),
			rng.randf_range(1.0, 5.0)
		)
	elif collision.shape_type == "sphere":
		collision.radius = rng.randf_range(0.5, 3.0)
	elif collision.shape_type == "capsule":
		collision.radius = rng.randf_range(0.3, 1.5)
		collision.height = rng.randf_range(1.0, 4.0)
	
	return collision

## Generate random rotation (cardinal directions only: 0°, 90°, 180°, 270°)
static func generate_random_cardinal_rotation(rng: RandomNumberGenerator) -> Vector3:
	var angles = [0.0, PI/2, PI, 3*PI/2]
	return Vector3(0, angles.pick_random(), 0)

## Generate random distance for corridor spacing tests
static func generate_random_distance(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(5.0, 50.0)

## Create a simple test asset scene with mesh and collision
static func create_test_asset_scene(size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "TestAsset"
	
	# Add mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	root.add_child(mesh_instance)
	
	# Add collision shape
	var static_body = StaticBody3D.new()
	static_body.name = "CollisionBody"
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	root.add_child(static_body)
	
	return root

## Assert two Vector3 values are approximately equal
static func assert_vector3_almost_eq(actual: Vector3, expected: Vector3, tolerance: float, message: String = "") -> bool:
	var diff = actual - expected
	var distance = diff.length()
	if distance > tolerance:
		push_error("Vector3 not equal: expected %s, got %s (distance: %.4f > %.4f) %s" % [
			expected, actual, distance, tolerance, message
		])
		return false
	return true

## Assert two float values are approximately equal
static func assert_float_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> bool:
	var diff = abs(actual - expected)
	if diff > tolerance:
		push_error("Float not equal: expected %.4f, got %.4f (diff: %.4f > %.4f) %s" % [
			expected, actual, diff, tolerance, message
		])
		return false
	return true

## Assert AABB values are approximately equal
static func assert_aabb_almost_eq(actual: AABB, expected: AABB, tolerance: float, message: String = "") -> bool:
	var pos_ok = assert_vector3_almost_eq(actual.position, expected.position, tolerance, message + " (position)")
	var size_ok = assert_vector3_almost_eq(actual.size, expected.size, tolerance, message + " (size)")
	return pos_ok and size_ok
