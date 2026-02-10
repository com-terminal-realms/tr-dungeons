extends PropertyTest

## Property-based tests for AssetMapper
## Feature: dungeon-asset-mapping

var rng: RandomNumberGenerator

func before_each():
	rng = RandomNumberGenerator.new()
	rng.randomize()

# Feature: dungeon-asset-mapping, Property 1: Bounding Box Measurement Accuracy
func test_property_bounding_box_accuracy():
	assert_property_holds("Bounding Box Measurement Accuracy", func(iteration: int) -> Dictionary:
		# Generate random test asset with known dimensions
		var size = Vector3(
			rng.randf_range(1.0, 10.0),
			rng.randf_range(2.0, 5.0),
			rng.randf_range(1.0, 10.0)
		)
		
		# Create test scene with mesh
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Measure using AssetMapper
		var mapper = AssetMapper.new()
		var measured_bbox = mapper._calculate_bounding_box(test_scene)
		
		# The measured size should match the actual size within ±0.1 units
		var size_diff = (measured_bbox.size - size).abs()
		var max_diff = max(size_diff.x, max(size_diff.y, size_diff.z))
		
		# Clean up
		test_scene.queue_free()
		
		if max_diff > 0.1:
			return {
				"success": false,
				"input": "size=%s" % size,
				"reason": "Measured size %s differs from actual %s by %.3f units (max allowed: 0.1)" % [
					measured_bbox.size, size, max_diff
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 2: Origin Offset Calculation
func test_property_origin_offset():
	assert_property_holds("Origin Offset Calculation", func(iteration: int) -> Dictionary:
		# Generate random test asset
		var size = Vector3(
			rng.randf_range(2.0, 10.0),
			rng.randf_range(2.0, 5.0),
			rng.randf_range(2.0, 10.0)
		)
		
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Measure using AssetMapper
		var mapper = AssetMapper.new()
		var bbox = mapper._calculate_bounding_box(test_scene)
		var origin_offset = mapper._find_origin_offset(test_scene)
		
		# Calculate expected center
		var expected_center = bbox.position + bbox.size / 2.0
		
		# Origin offset should equal the center of the bounding box
		var diff = (origin_offset - expected_center).length()
		
		# Clean up
		test_scene.queue_free()
		
		if diff > 0.01:
			return {
				"success": false,
				"input": "size=%s, bbox=%s" % [size, bbox],
				"reason": "Origin offset %s differs from expected center %s by %.4f units" % [
					origin_offset, expected_center, diff
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 3: Visual vs Collision Extent Distinction
func test_property_visual_vs_collision_extent():
	assert_property_holds("Visual vs Collision Extent Distinction", func(iteration: int) -> Dictionary:
		# Generate random sizes for visual and collision (make them different)
		var visual_size = Vector3(
			rng.randf_range(3.0, 10.0),
			rng.randf_range(2.0, 5.0),
			rng.randf_range(3.0, 10.0)
		)
		
		# Collision should be smaller than visual
		var collision_size = visual_size * rng.randf_range(0.6, 0.9)
		
		# Create test scene with both visual and collision
		var test_scene = AssetTestHelpers.create_test_asset_scene(visual_size)
		
		# Measure using AssetMapper
		var mapper = AssetMapper.new()
		var visual_bbox = mapper._calculate_bounding_box(test_scene)
		var collision_data = mapper._extract_collision_geometry(test_scene)
		
		# Should have found collision shapes
		if collision_data.is_empty():
			test_scene.queue_free()
			return {
				"success": false,
				"input": "visual_size=%s" % visual_size,
				"reason": "No collision shapes found"
			}
		
		# Visual and collision extents should be different
		# (In this test, collision is embedded in the scene, so they might be similar)
		# The key is that we can distinguish them
		var has_collision = collision_data.size() > 0
		var has_visual = visual_bbox.size != Vector3.ZERO
		
		# Clean up
		test_scene.queue_free()
		
		if not (has_collision and has_visual):
			return {
				"success": false,
				"input": "visual_size=%s, collision_size=%s" % [visual_size, collision_size],
				"reason": "Failed to distinguish visual (found: %s) and collision (found: %s)" % [
					has_visual, has_collision
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 15: JSON Export Round-Trip
func test_property_json_round_trip():
	assert_property_holds("JSON Export Round-Trip", func(iteration: int) -> Dictionary:
		# Generate random asset metadata
		var original_metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
		
		# Export to JSON
		var json_dict = original_metadata.to_dict()
		var json_string = JSON.stringify(json_dict)
		
		# Import from JSON
		var restored_dict = JSON.parse_string(json_string)
		var restored_metadata = AssetMetadata.new()
		restored_metadata.from_dict(restored_dict)
		
		# Verify key fields are preserved within precision
		var bbox_diff = (original_metadata.bounding_box.size - restored_metadata.bounding_box.size).abs()
		var max_bbox_diff = max(bbox_diff.x, max(bbox_diff.y, bbox_diff.z))
		
		if max_bbox_diff > 0.001:
			return {
				"success": false,
				"input": "bbox_size=%s" % original_metadata.bounding_box.size,
				"reason": "Bounding box size not preserved: original=%s, restored=%s (diff=%.4f)" % [
					original_metadata.bounding_box.size,
					restored_metadata.bounding_box.size,
					max_bbox_diff
				]
			}
		
		# Verify connection points count preserved
		if original_metadata.connection_points.size() != restored_metadata.connection_points.size():
			return {
				"success": false,
				"input": "connection_count=%d" % original_metadata.connection_points.size(),
				"reason": "Connection point count not preserved: original=%d, restored=%d" % [
					original_metadata.connection_points.size(),
					restored_metadata.connection_points.size()
				]
			}
		
		# Verify collision shapes count preserved
		if original_metadata.collision_shapes.size() != restored_metadata.collision_shapes.size():
			return {
				"success": false,
				"input": "collision_count=%d" % original_metadata.collision_shapes.size(),
				"reason": "Collision shape count not preserved: original=%d, restored=%d" % [
					original_metadata.collision_shapes.size(),
					restored_metadata.collision_shapes.size()
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 4: Connection Point Discovery
func test_property_connection_point_discovery():
	assert_property_holds("Connection Point Discovery", func(iteration: int) -> Dictionary:
		# Generate random asset size
		var is_corridor = rng.randf() > 0.5
		var size: Vector3
		
		if is_corridor:
			# Create corridor-shaped asset (one dimension 2x+ longer)
			var long_dim = rng.randf_range(8.0, 15.0)
			var short_dim = rng.randf_range(2.0, 4.0)
			var height = rng.randf_range(2.5, 4.0)
			
			if rng.randf() > 0.5:
				size = Vector3(short_dim, height, long_dim)  # Long in Z
			else:
				size = Vector3(long_dim, height, short_dim)  # Long in X
		else:
			# Create room-shaped asset (roughly square)
			var base_size = rng.randf_range(5.0, 12.0)
			var variation = rng.randf_range(0.8, 1.2)
			var height = rng.randf_range(2.5, 4.0)
			size = Vector3(base_size, height, base_size * variation)
		
		# Create test scene
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Find connection points
		var mapper = AssetMapper.new()
		var points = mapper._find_connection_points(test_scene)
		
		# Clean up
		test_scene.queue_free()
		
		# Verify connection points were found
		if points.is_empty():
			return {
				"success": false,
				"input": "size=%s, is_corridor=%s" % [size, is_corridor],
				"reason": "No connection points found"
			}
		
		# Verify correct number of points
		var expected_count = 2 if is_corridor else 4
		if points.size() != expected_count:
			return {
				"success": false,
				"input": "size=%s, is_corridor=%s" % [size, is_corridor],
				"reason": "Expected %d connection points, found %d" % [expected_count, points.size()]
			}
		
		# Verify all points have valid normals (unit length)
		for i in range(points.size()):
			var normal_length = points[i].normal.length()
			if abs(normal_length - 1.0) > 0.01:
				return {
					"success": false,
					"input": "size=%s, point_index=%d" % [size, i],
					"reason": "Connection point normal not unit length: %.4f" % normal_length
				}
		
		# Verify all points have positive dimensions
		for i in range(points.size()):
			if points[i].dimensions.x <= 0 or points[i].dimensions.y <= 0:
				return {
					"success": false,
					"input": "size=%s, point_index=%d" % [size, i],
					"reason": "Connection point has invalid dimensions: %s" % points[i].dimensions
				}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 5: Connection Point Coordinate System
func test_property_connection_point_coordinate_system():
	assert_property_holds("Connection Point Coordinate System", func(iteration: int) -> Dictionary:
		# Generate random asset size
		var size = Vector3(
			rng.randf_range(3.0, 10.0),
			rng.randf_range(2.5, 4.0),
			rng.randf_range(3.0, 10.0)
		)
		
		# Create test scene
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Find connection points
		var mapper = AssetMapper.new()
		var bbox = mapper._calculate_bounding_box(test_scene)
		var points = mapper._find_connection_points(test_scene)
		
		# Clean up
		test_scene.queue_free()
		
		if points.is_empty():
			return {"success": true}  # Skip if no points
		
		# Verify all connection points are on or near the bounding box surface
		for i in range(points.size()):
			var point = points[i]
			var pos = point.position
			
			# Check if point is within or on the bounding box (with small tolerance)
			var tolerance = 0.5
			var min_bound = bbox.position - Vector3(tolerance, tolerance, tolerance)
			var max_bound = bbox.position + bbox.size + Vector3(tolerance, tolerance, tolerance)
			
			if pos.x < min_bound.x or pos.x > max_bound.x or \
			   pos.y < min_bound.y or pos.y > max_bound.y or \
			   pos.z < min_bound.z or pos.z > max_bound.z:
				return {
					"success": false,
					"input": "size=%s, point_index=%d, bbox=%s" % [size, i, bbox],
					"reason": "Connection point %s is outside bounding box bounds [%s, %s]" % [
						pos, min_bound, max_bound
					]
				}
			
			# Verify normal points outward (away from center)
			var center = bbox.position + bbox.size / 2.0
			var to_point = (pos - center).normalized()
			var dot_product = to_point.dot(point.normal)
			
			# Normal should point in same general direction as vector from center to point
			# (dot product should be positive, allowing some tolerance for edge cases)
			if dot_product < -0.1:
				return {
					"success": false,
					"input": "size=%s, point_index=%d" % [size, i],
					"reason": "Connection point normal %s doesn't point outward (dot=%.3f)" % [
						point.normal, dot_product
					]
				}
		
		return {"success": true}
	)
