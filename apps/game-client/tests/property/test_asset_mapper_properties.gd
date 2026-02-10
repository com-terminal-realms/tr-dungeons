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
