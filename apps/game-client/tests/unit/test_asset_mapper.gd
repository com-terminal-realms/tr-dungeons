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
	
	# Floor height should be the bottom of the bounding box
	# BoxMesh is centered, so bottom is at -size.y/2
	assert_almost_eq(floor_height, -size.y / 2.0, 0.1, "Floor height should be at bottom of bbox")

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
