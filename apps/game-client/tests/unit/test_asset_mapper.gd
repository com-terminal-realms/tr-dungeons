extends "res://addons/gut/test.gd"

## Unit tests for AssetMapper
## Tests specific examples and edge cases

var mapper: AssetMapper

func before_each():
	mapper = AssetMapper.new()

func test_empty_scene_returns_zero_bbox():
	# Create empty scene with no meshes
	var empty_scene = Node3D.new()
	empty_scene.name = "EmptyScene"
	add_child_autofree(empty_scene)  # Add to tree so transforms work
	
	var bbox = mapper._calculate_bounding_box(empty_scene)
	
	assert_eq(bbox.size, Vector3.ZERO, "Empty scene should have zero-size bounding box")
	assert_eq(bbox.position, Vector3.ZERO, "Empty scene bbox should be at origin")

func test_single_mesh_bbox():
	# Create scene with single mesh of known size
	var size = Vector3(2.0, 3.0, 4.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)  # Add to tree so transforms work
	
	var bbox = mapper._calculate_bounding_box(test_scene)
	
	# Should match the mesh size within tolerance
	assert_almost_eq(bbox.size.x, size.x, 0.1, "X dimension should match")
	assert_almost_eq(bbox.size.y, size.y, 0.1, "Y dimension should match")
	assert_almost_eq(bbox.size.z, size.z, 0.1, "Z dimension should match")

func test_origin_offset_for_centered_mesh():
	# Create centered mesh
	var size = Vector3(4.0, 4.0, 4.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)  # Add to tree so transforms work
	
	var origin_offset = mapper._find_origin_offset(test_scene)
	
	# For a centered mesh, origin offset should be near zero
	# (BoxMesh is centered by default)
	assert_almost_eq(origin_offset.length(), 0.0, 0.1, "Centered mesh should have origin near center")

func test_floor_height_measurement():
	# Create mesh at known position
	var size = Vector3(2.0, 3.0, 2.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)  # Add to tree so transforms work
	
	var floor_height = mapper._measure_floor_height(test_scene)
	
	# Floor height should be the top surface of the collision box
	# BoxMesh is centered, and collision box is same size
	# Top surface is at position.y + size.y/2
	# Since position is 0, top surface is at size.y/2
	assert_almost_eq(floor_height, size.y / 2.0, 0.1, "Floor height should be at top of collision box")

func test_collision_extraction():
	# Create scene with collision shapes
	var size = Vector3(3.0, 3.0, 3.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)  # Add to tree so transforms work
	
	var collision_data = mapper._extract_collision_geometry(test_scene)
	
	assert_gt(collision_data.size(), 0, "Should find collision shapes")
	assert_eq(collision_data[0].shape_type, "box", "Should identify box shape")

func test_detect_format_glb():
	var format = mapper._detect_format("res://assets/models/test.glb")
	assert_eq(format, "GLB", "Should detect GLB format")

func test_detect_format_fbx():
	var format = mapper._detect_format("res://assets/models/test.fbx")
	assert_eq(format, "FBX", "Should detect FBX format")

func test_detect_format_gltf():
	var format = mapper._detect_format("res://assets/models/test.gltf")
	assert_eq(format, "GLB", "Should detect GLTF as GLB format")

func test_metadata_to_dict_and_back():
	# Create metadata with known values
	var metadata = AssetMetadata.new()
	metadata.asset_name = "test_asset"
	metadata.asset_path = "res://test.glb"
	metadata.asset_format = "GLB"
	metadata.bounding_box = AABB(Vector3(1, 2, 3), Vector3(4, 5, 6))
	metadata.floor_height = 1.5
	
	# Convert to dict and back
	var dict = metadata.to_dict()
	var restored = AssetMetadata.new()
	restored.from_dict(dict)
	
	assert_eq(restored.asset_name, "test_asset", "Asset name should be preserved")
	assert_eq(restored.asset_format, "GLB", "Asset format should be preserved")
	assert_almost_eq(restored.floor_height, 1.5, 0.001, "Floor height should be preserved")
	assert_almost_eq(restored.bounding_box.size.x, 4.0, 0.001, "Bbox size X should be preserved")

func test_connection_point_to_dict_and_back():
	# Create connection point
	var point = ConnectionPoint.new()
	point.position = Vector3(1, 2, 3)
	point.normal = Vector3(0, 0, 1)  # Use explicit values instead of Vector3.FORWARD
	point.type = "door"
	point.dimensions = Vector2(2, 3)
	
	# Convert to dict and back
	var dict = point.to_dict()
	var restored = ConnectionPoint.new()
	restored.from_dict(dict)
	
	assert_eq(restored.type, "door", "Type should be preserved")
	assert_almost_eq(restored.position.x, 1.0, 0.001, "Position X should be preserved")
	assert_almost_eq(restored.position.y, 2.0, 0.001, "Position Y should be preserved")
	assert_almost_eq(restored.position.z, 3.0, 0.001, "Position Z should be preserved")
	assert_almost_eq(restored.normal.x, 0.0, 0.001, "Normal X should be preserved")
	assert_almost_eq(restored.normal.y, 0.0, 0.001, "Normal Y should be preserved")
	assert_almost_eq(restored.normal.z, 1.0, 0.001, "Normal Z should be preserved")
	assert_almost_eq(restored.dimensions.x, 2.0, 0.001, "Dimensions X should be preserved")

func test_collision_data_to_dict_and_back():
	# Create collision data
	var collision = CollisionData.new()
	collision.shape_type = "box"
	collision.position = Vector3(1, 2, 3)
	collision.size = Vector3(4, 5, 6)
	
	# Convert to dict and back
	var dict = collision.to_dict()
	var restored = CollisionData.new()
	restored.from_dict(dict)
	
	assert_eq(restored.shape_type, "box", "Shape type should be preserved")
	assert_almost_eq(restored.position.y, 2.0, 0.001, "Position Y should be preserved")
	assert_almost_eq(restored.size.z, 6.0, 0.001, "Size Z should be preserved")

func test_corridor_shaped_detection():
	# Test corridor-shaped asset (long in one dimension)
	var corridor_size = Vector3(2.0, 3.0, 10.0)  # Long in Z
	assert_true(mapper._is_corridor_shaped(corridor_size), "Should detect corridor shape (Z-axis)")
	
	var corridor_size_x = Vector3(10.0, 3.0, 2.0)  # Long in X
	assert_true(mapper._is_corridor_shaped(corridor_size_x), "Should detect corridor shape (X-axis)")
	
	# Test non-corridor (square-ish)
	var room_size = Vector3(5.0, 3.0, 6.0)  # Similar X and Z
	assert_false(mapper._is_corridor_shaped(room_size), "Should not detect square shape as corridor")

func test_room_shaped_detection():
	# Test room-shaped asset (roughly square in XZ)
	var room_size = Vector3(5.0, 3.0, 6.0)
	assert_true(mapper._is_room_shaped(room_size), "Should detect room shape")
	
	# Test corridor (not room-shaped)
	var corridor_size = Vector3(2.0, 3.0, 10.0)
	assert_false(mapper._is_room_shaped(corridor_size), "Should not detect corridor as room")
	
	# Test too small (not a room)
	var small_size = Vector3(2.0, 3.0, 2.0)
	assert_false(mapper._is_room_shaped(small_size), "Should not detect small asset as room")

func test_longest_horizontal_axis():
	# Test Z is longest
	var size_z = Vector3(2.0, 3.0, 10.0)
	assert_eq(mapper._get_longest_horizontal_axis(size_z), "z", "Should identify Z as longest")
	
	# Test X is longest
	var size_x = Vector3(10.0, 3.0, 2.0)
	assert_eq(mapper._get_longest_horizontal_axis(size_x), "x", "Should identify X as longest")

func test_corridor_connection_points():
	# Create corridor-shaped asset (long in Z)
	var size = Vector3(2.0, 3.0, 10.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var points = mapper._find_connection_points(test_scene)
	
	# Should have 2 connection points
	assert_eq(points.size(), 2, "Corridor should have 2 connection points")
	
	# Both should be corridor_end type
	assert_eq(points[0].type, "corridor_end", "First point should be corridor_end")
	assert_eq(points[1].type, "corridor_end", "Second point should be corridor_end")
	
	# Normals should face opposite directions along Z axis
	var normal_sum = points[0].normal + points[1].normal
	assert_almost_eq(normal_sum.length(), 0.0, 0.01, "Normals should face opposite directions")

func test_room_connection_points():
	# Create room-shaped asset (square-ish)
	var size = Vector3(8.0, 3.0, 10.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var points = mapper._find_connection_points(test_scene)
	
	# Should have 4 connection points (one per wall)
	assert_eq(points.size(), 4, "Room should have 4 connection points")
	
	# All should be door type
	for point in points:
		assert_eq(point.type, "door", "Room connection points should be doors")
	
	# Should have one point facing each cardinal direction
	var has_north = false
	var has_south = false
	var has_east = false
	var has_west = false
	
	for point in points:
		if point.normal.z > 0.9:
			has_north = true
		elif point.normal.z < -0.9:
			has_south = true
		elif point.normal.x > 0.9:
			has_east = true
		elif point.normal.x < -0.9:
			has_west = true
	
	assert_true(has_north, "Should have north-facing door")
	assert_true(has_south, "Should have south-facing door")
	assert_true(has_east, "Should have east-facing door")
	assert_true(has_west, "Should have west-facing door")

func test_determine_asset_type_from_name():
	# Test wall detection
	assert_eq(mapper._determine_asset_type("template-wall", Vector3(1, 3, 5)), "wall", "Should detect wall from name")
	assert_eq(mapper._determine_asset_type("corridor-wall", Vector3(1, 3, 5)), "wall", "Should detect wall from name")
	
	# Test corridor detection
	assert_eq(mapper._determine_asset_type("corridor", Vector3(2, 3, 10)), "corridor", "Should detect corridor from name")
	
	# Test room detection
	assert_eq(mapper._determine_asset_type("room-small", Vector3(8, 3, 10)), "room", "Should detect room from name")
	
	# Test door detection
	assert_eq(mapper._determine_asset_type("gate-door", Vector3(2, 3, 1)), "door", "Should detect door from name")
	
	# Test floor detection
	assert_eq(mapper._determine_asset_type("template-floor", Vector3(5, 0.5, 5)), "floor", "Should detect floor from name")
	
	# Test stairs detection
	assert_eq(mapper._determine_asset_type("stairs-wide", Vector3(3, 2, 5)), "stairs", "Should detect stairs from name")

func test_determine_asset_type_from_geometry():
	# Test corridor detection by shape
	assert_eq(mapper._determine_asset_type("unknown-asset", Vector3(2, 3, 10)), "corridor", "Should detect corridor from geometry")
	
	# Test room detection by shape
	assert_eq(mapper._determine_asset_type("unknown-asset", Vector3(8, 3, 10)), "room", "Should detect room from geometry")
	
	# Test unknown fallback
	assert_eq(mapper._determine_asset_type("unknown-asset", Vector3(1, 1, 1)), "unknown", "Should return unknown for ambiguous geometry")

func test_wall_thickness_measurement():
	# Create a wall-like asset with collision
	var size = Vector3(1.0, 3.0, 5.0)  # Thin in X (wall thickness)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var thickness = mapper._measure_wall_thickness(test_scene, "wall")
	
	# Should measure the thinnest dimension (X = 1.0)
	assert_almost_eq(thickness, 1.0, 0.1, "Wall thickness should be the thinnest dimension")

func test_wall_thickness_non_wall_asset():
	# Non-wall assets should return 0 thickness
	var size = Vector3(5.0, 3.0, 5.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var thickness = mapper._measure_wall_thickness(test_scene, "room")
	
	assert_eq(thickness, 0.0, "Non-wall assets should have 0 thickness")

func test_doorway_dimensions_measurement():
	# Create room with connection points
	var size = Vector3(8.0, 3.0, 10.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var points = mapper._find_connection_points(test_scene)
	var doorway_dims = mapper._measure_doorway_dimensions(test_scene, points)
	
	# Should return the dimensions from the first connection point
	assert_gt(doorway_dims.x, 0.0, "Doorway width should be positive")
	assert_gt(doorway_dims.y, 0.0, "Doorway height should be positive")

func test_doorway_dimensions_no_connections():
	# Asset with no connection points should return zero dimensions
	var size = Vector3(2.0, 2.0, 2.0)
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var empty_points: Array[ConnectionPoint] = []
	var doorway_dims = mapper._measure_doorway_dimensions(test_scene, empty_points)
	
	assert_eq(doorway_dims, Vector2.ZERO, "No connection points should return zero dimensions")


# ===== Rotation Tests =====

func test_determine_default_rotation_corridor_z():
	# Corridor along Z axis should have default rotation of 0 (facing +Z/north)
	var size = Vector3(2.0, 3.0, 10.0)  # Long in Z
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var rotation = mapper._determine_default_rotation(test_scene)
	
	assert_eq(rotation, Vector3(0, 0, 0), "Z-axis corridor should face north (0°)")

func test_determine_default_rotation_corridor_x():
	# Corridor along X axis should have default rotation of 90 (facing +X/east)
	var size = Vector3(10.0, 3.0, 2.0)  # Long in X
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var rotation = mapper._determine_default_rotation(test_scene)
	
	assert_eq(rotation, Vector3(0, 90, 0), "X-axis corridor should face east (90°)")

func test_determine_default_rotation_room():
	# Room should have default rotation of 0 (facing north)
	var size = Vector3(8.0, 3.0, 10.0)  # Room-shaped
	var test_scene = AssetTestHelpers.create_test_asset_scene(size)
	add_child_autofree(test_scene)
	
	var rotation = mapper._determine_default_rotation(test_scene)
	
	assert_eq(rotation, Vector3(0, 0, 0), "Room should face north (0°)")

func test_get_rotation_for_direction():
	# Test all cardinal directions
	assert_eq(mapper.get_rotation_for_direction("north"), Vector3(0, 0, 0), "North should be 0°")
	assert_eq(mapper.get_rotation_for_direction("east"), Vector3(0, 90, 0), "East should be 90°")
	assert_eq(mapper.get_rotation_for_direction("south"), Vector3(0, 180, 0), "South should be 180°")
	assert_eq(mapper.get_rotation_for_direction("west"), Vector3(0, 270, 0), "West should be 270°")

func test_get_rotation_for_direction_case_insensitive():
	# Test case insensitivity
	assert_eq(mapper.get_rotation_for_direction("NORTH"), Vector3(0, 0, 0), "NORTH should work")
	assert_eq(mapper.get_rotation_for_direction("East"), Vector3(0, 90, 0), "East should work")
	assert_eq(mapper.get_rotation_for_direction("SoUtH"), Vector3(0, 180, 0), "SoUtH should work")

func test_get_rotation_for_direction_invalid():
	# Invalid direction should default to north
	var rotation = mapper.get_rotation_for_direction("invalid")
	assert_eq(rotation, Vector3(0, 0, 0), "Invalid direction should default to north")

func test_get_all_cardinal_rotations():
	var rotations = mapper.get_all_cardinal_rotations()
	
	# Should have all four directions
	assert_true(rotations.has("north"), "Should have north")
	assert_true(rotations.has("south"), "Should have south")
	assert_true(rotations.has("east"), "Should have east")
	assert_true(rotations.has("west"), "Should have west")
	
	# Verify values
	assert_eq(rotations["north"], Vector3(0, 0, 0), "North should be 0°")
	assert_eq(rotations["east"], Vector3(0, 90, 0), "East should be 90°")
	assert_eq(rotations["south"], Vector3(0, 180, 0), "South should be 180°")
	assert_eq(rotations["west"], Vector3(0, 270, 0), "West should be 270°")

func test_connection_point_transform_by_rotation_90():
	# Create a connection point facing north (+Z)
	var point = ConnectionPoint.new()
	point.position = Vector3(0, 1, 5)
	point.normal = Vector3(0, 0, 1)  # Facing +Z (north)
	point.type = "door"
	point.dimensions = Vector2(2, 3)
	
	# Rotate 90° clockwise (to face east)
	var rotated = point.transform_by_rotation(Vector3(0, 90, 0))
	
	# Position should rotate: (0, 1, 5) -> (5, 1, 0)
	assert_almost_eq(rotated.position.x, 5.0, 0.01, "X should be 5")
	assert_almost_eq(rotated.position.y, 1.0, 0.01, "Y should be 1")
	assert_almost_eq(rotated.position.z, 0.0, 0.01, "Z should be 0")
	
	# Normal should rotate: (0, 0, 1) -> (1, 0, 0)
	assert_almost_eq(rotated.normal.x, 1.0, 0.01, "Normal X should be 1")
	assert_almost_eq(rotated.normal.y, 0.0, 0.01, "Normal Y should be 0")
	assert_almost_eq(rotated.normal.z, 0.0, 0.01, "Normal Z should be 0")
	
	# Type and dimensions should be preserved
	assert_eq(rotated.type, "door", "Type should be preserved")
	assert_eq(rotated.dimensions, Vector2(2, 3), "Dimensions should be preserved")

func test_connection_point_transform_by_rotation_180():
	# Create a connection point facing north (+Z)
	var point = ConnectionPoint.new()
	point.position = Vector3(2, 1, 3)
	point.normal = Vector3(0, 0, 1)  # Facing +Z (north)
	point.type = "corridor_end"
	point.dimensions = Vector2(2, 3)
	
	# Rotate 180° (to face south)
	var rotated = point.transform_by_rotation(Vector3(0, 180, 0))
	
	# Position should rotate: (2, 1, 3) -> (-2, 1, -3)
	assert_almost_eq(rotated.position.x, -2.0, 0.01, "X should be -2")
	assert_almost_eq(rotated.position.y, 1.0, 0.01, "Y should be 1")
	assert_almost_eq(rotated.position.z, -3.0, 0.01, "Z should be -3")
	
	# Normal should rotate: (0, 0, 1) -> (0, 0, -1)
	assert_almost_eq(rotated.normal.x, 0.0, 0.01, "Normal X should be 0")
	assert_almost_eq(rotated.normal.y, 0.0, 0.01, "Normal Y should be 0")
	assert_almost_eq(rotated.normal.z, -1.0, 0.01, "Normal Z should be -1")

func test_connection_point_rotation_round_trip():
	# Create a connection point
	var point = ConnectionPoint.new()
	point.position = Vector3(3, 2, 4)
	point.normal = Vector3(1, 0, 0)  # Facing +X (east)
	point.type = "door"
	point.dimensions = Vector2(2.5, 3.5)
	
	# Rotate 90° and then -90° (should return to original)
	var rotated = point.transform_by_rotation(Vector3(0, 90, 0))
	var restored = rotated.transform_by_rotation(Vector3(0, -90, 0))
	
	# Should match original
	assert_almost_eq(restored.position.x, point.position.x, 0.01, "Position X should be restored")
	assert_almost_eq(restored.position.y, point.position.y, 0.01, "Position Y should be restored")
	assert_almost_eq(restored.position.z, point.position.z, 0.01, "Position Z should be restored")
	assert_almost_eq(restored.normal.x, point.normal.x, 0.01, "Normal X should be restored")
	assert_almost_eq(restored.normal.y, point.normal.y, 0.01, "Normal Y should be restored")
	assert_almost_eq(restored.normal.z, point.normal.z, 0.01, "Normal Z should be restored")
	assert_eq(restored.type, point.type, "Type should be preserved")
	assert_eq(restored.dimensions, point.dimensions, "Dimensions should be preserved")


# ============================================================================
# LayoutCalculator Tests
# ============================================================================

func test_layout_calculator_corridor_count_20_units():
	# Test known case: 20 units with 5-unit corridors
	# Formula: count = ceil((distance - overlap) / effective_length)
	# With 5-unit corridors and connection points at edges (no overlap):
	# count = ceil((20 - 0) / 5) = ceil(4) = 4
	var metadata = AssetMetadata.new()
	metadata.asset_name = "corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	
	# Add connection points at the ends
	var point_a = ConnectionPoint.new()
	point_a.position = Vector3(0, 1.5, -2.5)
	point_a.normal = Vector3(0, 0, -1)
	point_a.type = "corridor_end"
	point_a.dimensions = Vector2(2, 3)
	
	var point_b = ConnectionPoint.new()
	point_b.position = Vector3(0, 1.5, 2.5)
	point_b.normal = Vector3(0, 0, 1)
	point_b.type = "corridor_end"
	point_b.dimensions = Vector2(2, 3)
	
	metadata.connection_points = [point_a, point_b]
	
	var calculator = LayoutCalculator.new()
	var count = calculator.calculate_corridor_count(20.0, metadata)
	
	# 20 units / 5 units per corridor = 4 corridors
	assert_eq(count, 4, "20 units should equal 4 corridor pieces")

func test_layout_calculator_corridor_count_10_units():
	# Test 10 units distance
	var metadata = AssetMetadata.new()
	metadata.asset_name = "corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	
	var point_a = ConnectionPoint.new()
	point_a.position = Vector3(0, 1.5, -2.5)
	point_a.normal = Vector3(0, 0, -1)
	point_a.type = "corridor_end"
	point_a.dimensions = Vector2(2, 3)
	
	var point_b = ConnectionPoint.new()
	point_b.position = Vector3(0, 1.5, 2.5)
	point_b.normal = Vector3(0, 0, 1)
	point_b.type = "corridor_end"
	point_b.dimensions = Vector2(2, 3)
	
	metadata.connection_points = [point_a, point_b]
	
	var calculator = LayoutCalculator.new()
	var count = calculator.calculate_corridor_count(10.0, metadata)
	
	assert_true(count >= 1, "10 units should require at least 1 corridor")
	assert_true(count <= 3, "10 units should require at most 3 corridors")

func test_layout_calculator_corridor_count_15_units():
	# Test 15 units distance
	var metadata = AssetMetadata.new()
	metadata.asset_name = "corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	
	var point_a = ConnectionPoint.new()
	point_a.position = Vector3(0, 1.5, -2.5)
	point_a.normal = Vector3(0, 0, -1)
	point_a.type = "corridor_end"
	point_a.dimensions = Vector2(2, 3)
	
	var point_b = ConnectionPoint.new()
	point_b.position = Vector3(0, 1.5, 2.5)
	point_b.normal = Vector3(0, 0, 1)
	point_b.type = "corridor_end"
	point_b.dimensions = Vector2(2, 3)
	
	metadata.connection_points = [point_a, point_b]
	
	var calculator = LayoutCalculator.new()
	var count = calculator.calculate_corridor_count(15.0, metadata)
	
	assert_true(count >= 2, "15 units should require at least 2 corridors")
	assert_true(count <= 4, "15 units should require at most 4 corridors")

func test_layout_calculator_corridor_count_30_units():
	# Test 30 units distance
	var metadata = AssetMetadata.new()
	metadata.asset_name = "corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	
	var point_a = ConnectionPoint.new()
	point_a.position = Vector3(0, 1.5, -2.5)
	point_a.normal = Vector3(0, 0, -1)
	point_a.type = "corridor_end"
	point_a.dimensions = Vector2(2, 3)
	
	var point_b = ConnectionPoint.new()
	point_b.position = Vector3(0, 1.5, 2.5)
	point_b.normal = Vector3(0, 0, 1)
	point_b.type = "corridor_end"
	point_b.dimensions = Vector2(2, 3)
	
	metadata.connection_points = [point_a, point_b]
	
	var calculator = LayoutCalculator.new()
	var count = calculator.calculate_corridor_count(30.0, metadata)
	
	assert_true(count >= 4, "30 units should require at least 4 corridors")
	assert_true(count <= 8, "30 units should require at most 8 corridors")

func test_layout_calculator_invalid_distance():
	# Test error handling for invalid distance
	var metadata = AssetMetadata.new()
	metadata.asset_name = "corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	
	var calculator = LayoutCalculator.new()
	
	# Tell GUT to ignore push_error calls for this test
	watch_signals(calculator)
	var count = calculator.calculate_corridor_count(-10.0, metadata)
	
	assert_eq(count, -1, "Negative distance should return error code")

func test_layout_calculator_null_metadata():
	# Test error handling for null metadata
	var calculator = LayoutCalculator.new()
	
	# Tell GUT to ignore push_error calls for this test
	watch_signals(calculator)
	var count = calculator.calculate_corridor_count(20.0, null)
	
	assert_eq(count, -1, "Null metadata should return error code")
