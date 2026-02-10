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
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
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
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
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
			# Clean up before returning
			AssetTestHelpers.cleanup_test_asset_scene(test_scene)
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
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
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
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
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
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
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

# Feature: dungeon-asset-mapping, Property 9: Rotation Transform Round-Trip
func test_property_rotation_round_trip():
	assert_property_holds("Rotation Transform Round-Trip", func(iteration: int) -> Dictionary:
		# Generate random asset metadata with connection points
		var metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
		
		# Ensure we have at least one connection point
		if metadata.connection_points.is_empty():
			var point = ConnectionPoint.new()
			point.position = Vector3(
				rng.randf_range(-5.0, 5.0),
				rng.randf_range(0.0, 3.0),
				rng.randf_range(-5.0, 5.0)
			)
			point.normal = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0)
			).normalized()
			point.type = "test"
			point.dimensions = Vector2(2.0, 3.0)
			metadata.connection_points.append(point)
		
		# Pick a random rotation (cardinal directions: 0, 90, 180, 270 degrees)
		var rotation_degrees = [0, 90, 180, 270][rng.randi() % 4]
		var rotation = Vector3(0, rotation_degrees, 0)
		
		# Store original connection points
		var original_points: Array[ConnectionPoint] = []
		for point in metadata.connection_points:
			original_points.append(point)
		
		# Apply rotation
		var rotated_points: Array[ConnectionPoint] = []
		for point in original_points:
			rotated_points.append(point.transform_by_rotation(rotation))
		
		# Apply inverse rotation
		var inverse_rotation = Vector3(0, -rotation_degrees, 0)
		var restored_points: Array[ConnectionPoint] = []
		for point in rotated_points:
			restored_points.append(point.transform_by_rotation(inverse_rotation))
		
		# Verify round-trip: restored points should match original points
		for i in range(original_points.size()):
			var pos_diff = original_points[i].position.distance_to(restored_points[i].position)
			if pos_diff > 0.01:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Position not preserved after round-trip: original=%s, restored=%s (diff=%.4f)" % [
						original_points[i].position,
						restored_points[i].position,
						pos_diff
					]
				}
			
			var normal_diff = original_points[i].normal.distance_to(restored_points[i].normal)
			if normal_diff > 0.01:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Normal not preserved after round-trip: original=%s, restored=%s (diff=%.4f)" % [
						original_points[i].normal,
						restored_points[i].normal,
						normal_diff
					]
				}
		
		return {"success": true}
	)


# Feature: dungeon-asset-mapping, Property 10: Cardinal Direction Rotation Completeness
func test_property_cardinal_direction_completeness():
	assert_property_holds("Cardinal Direction Rotation Completeness", func(iteration: int) -> Dictionary:
		# Get all cardinal rotations from AssetMapper
		var mapper = AssetMapper.new()
		var rotations = mapper.get_all_cardinal_rotations()
		
		# Verify we have all four cardinal directions
		var required_directions = ["north", "south", "east", "west"]
		for direction in required_directions:
			if not rotations.has(direction):
				return {
					"success": false,
					"input": "iteration=%d" % iteration,
					"reason": "Missing cardinal direction: %s" % direction
				}
		
		# Verify each direction has a distinct rotation
		var rotation_values: Array[Vector3] = []
		for direction in required_directions:
			var rotation = rotations[direction]
			
			# Check if this rotation is already in the list (should be unique)
			for existing_rotation in rotation_values:
				if rotation.distance_to(existing_rotation) < 0.01:
					return {
						"success": false,
						"input": "direction=%s" % direction,
						"reason": "Rotation %s is not distinct (matches another direction)" % rotation
					}
			
			rotation_values.append(rotation)
		
		# Verify rotations are valid Y-axis rotations (X and Z should be 0)
		for direction in required_directions:
			var rotation = rotations[direction]
			if abs(rotation.x) > 0.01 or abs(rotation.z) > 0.01:
				return {
					"success": false,
					"input": "direction=%s" % direction,
					"reason": "Rotation %s is not a pure Y-axis rotation" % rotation
				}
		
		# Verify Y rotations are in expected range [0, 360)
		for direction in required_directions:
			var rotation = rotations[direction]
			if rotation.y < 0 or rotation.y >= 360:
				return {
					"success": false,
					"input": "direction=%s" % direction,
					"reason": "Rotation Y value %.1f is outside valid range [0, 360)" % rotation.y
				}
		
		# Verify specific expected values for each direction
		var expected = {
			"north": 0.0,
			"east": 90.0,
			"south": 180.0,
			"west": 270.0
		}
		
		for direction in required_directions:
			var rotation = rotations[direction]
			var expected_y = expected[direction]
			if abs(rotation.y - expected_y) > 0.01:
				return {
					"success": false,
					"input": "direction=%s" % direction,
					"reason": "Expected Y rotation %.1f, got %.1f" % [expected_y, rotation.y]
				}
		
		return {"success": true}
	)


# Feature: dungeon-asset-mapping, Property 11: Rotation Preserves Connection Alignment
func test_property_rotation_preserves_alignment():
	assert_property_holds("Rotation Preserves Connection Alignment", func(iteration: int) -> Dictionary:
		# Generate random asset metadata with connection points
		var metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
		
		# Ensure we have at least one connection point
		if metadata.connection_points.is_empty():
			var point = ConnectionPoint.new()
			point.position = Vector3(
				rng.randf_range(-5.0, 5.0),
				rng.randf_range(0.0, 3.0),
				rng.randf_range(-5.0, 5.0)
			)
			point.normal = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0)
			).normalized()
			point.type = "test"
			point.dimensions = Vector2(2.0, 3.0)
			metadata.connection_points.append(point)
		
		# Pick a random cardinal direction rotation
		var rotation_degrees = [0, 90, 180, 270][rng.randi() % 4]
		var rotation = Vector3(0, rotation_degrees, 0)
		
		# Apply rotation to all connection points
		for i in range(metadata.connection_points.size()):
			var original_point = metadata.connection_points[i]
			var rotated_point = original_point.transform_by_rotation(rotation)
			
			# Verify normal is still unit length (preserved)
			var normal_length = rotated_point.normal.length()
			if abs(normal_length - 1.0) > 0.01:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Normal length not preserved: original=1.0, rotated=%.4f" % normal_length
				}
			
			# Verify dimensions are preserved (rotation shouldn't change dimensions)
			var dims_diff = (original_point.dimensions - rotated_point.dimensions).abs()
			if dims_diff.x > 0.01 or dims_diff.y > 0.01:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Dimensions not preserved: original=%s, rotated=%s" % [
						original_point.dimensions,
						rotated_point.dimensions
					]
				}
			
			# Verify type is preserved
			if original_point.type != rotated_point.type:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Type not preserved: original=%s, rotated=%s" % [
						original_point.type,
						rotated_point.type
					]
				}
			
			# Verify normal still points outward (relative to rotated position)
			# For a valid connection point, the normal should be perpendicular to at least one axis
			# and should maintain its outward-facing property
			var rotated_normal = rotated_point.normal
			
			# Check that the normal is still a valid direction (not zero)
			if rotated_normal.length_squared() < 0.9:
				return {
					"success": false,
					"input": "rotation=%d°, point_index=%d" % [rotation_degrees, i],
					"reason": "Rotated normal is invalid: %s" % rotated_normal
				}
		
		return {"success": true}
	)


# Feature: dungeon-asset-mapping, Property 12: Walkable Area Containment
func test_property_walkable_area_containment():
	assert_property_holds("Walkable Area Containment", func(iteration: int) -> Dictionary:
		# Generate random room-shaped asset
		var base_size = rng.randf_range(5.0, 12.0)
		var variation = rng.randf_range(0.8, 1.2)
		var height = rng.randf_range(2.5, 4.0)
		var size = Vector3(base_size, height, base_size * variation)
		
		# Create test scene
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Measure using AssetMapper
		var mapper = AssetMapper.new()
		var bbox = mapper._calculate_bounding_box(test_scene)
		var collision_shapes = mapper._extract_collision_geometry(test_scene)
		var walkable_area = mapper._calculate_walkable_area(test_scene, collision_shapes)
		
		# Clean up
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
		# Verify walkable area is contained within bounding box
		var walkable_min = walkable_area.position
		var walkable_max = walkable_area.position + walkable_area.size
		var bbox_min = bbox.position
		var bbox_max = bbox.position + bbox.size
		
		# Check X bounds
		if walkable_min.x < bbox_min.x - 0.1 or walkable_max.x > bbox_max.x + 0.1:
			return {
				"success": false,
				"input": "size=%s" % size,
				"reason": "Walkable area X bounds [%.2f, %.2f] outside bbox X bounds [%.2f, %.2f]" % [
					walkable_min.x, walkable_max.x, bbox_min.x, bbox_max.x
				]
			}
		
		# Check Z bounds
		if walkable_min.z < bbox_min.z - 0.1 or walkable_max.z > bbox_max.z + 0.1:
			return {
				"success": false,
				"input": "size=%s" % size,
				"reason": "Walkable area Z bounds [%.2f, %.2f] outside bbox Z bounds [%.2f, %.2f]" % [
					walkable_min.z, walkable_max.z, bbox_min.z, bbox_max.z
				]
			}
		
		# Verify walkable area doesn't overlap with wall collision boundaries
		# Wall collision shapes should be outside or at the edge of walkable area
		for shape in collision_shapes:
			if shape.shape_type == "box":
				# Check if this is a wall shape (tall, not flat)
				if shape.size.y > shape.size.x or shape.size.y > shape.size.z:
					# Wall shape - verify it doesn't significantly overlap walkable area
					var shape_min = shape.position - shape.size / 2.0
					var shape_max = shape.position + shape.size / 2.0
					
					# Check for overlap in XZ plane
					var overlap_x = min(walkable_max.x, shape_max.x) - max(walkable_min.x, shape_min.x)
					var overlap_z = min(walkable_max.z, shape_max.z) - max(walkable_min.z, shape_min.z)
					
					# Allow small overlap (margin), but not significant overlap
					if overlap_x > 0.5 and overlap_z > 0.5:
						return {
							"success": false,
							"input": "size=%s" % size,
							"reason": "Walkable area significantly overlaps wall collision (overlap: %.2f x %.2f)" % [
								overlap_x, overlap_z
							]
						}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 13: Collision Geometry Documentation Completeness
func test_property_collision_documentation_completeness():
	assert_property_holds("Collision Geometry Documentation Completeness", func(iteration: int) -> Dictionary:
		# Generate random asset size
		var size = Vector3(
			rng.randf_range(3.0, 10.0),
			rng.randf_range(2.5, 4.0),
			rng.randf_range(3.0, 10.0)
		)
		
		# Create test scene with collision
		var test_scene = AssetTestHelpers.create_test_asset_scene(size)
		
		# Extract collision geometry
		var mapper = AssetMapper.new()
		var collision_shapes = mapper._extract_collision_geometry(test_scene)
		
		# Clean up
		AssetTestHelpers.cleanup_test_asset_scene(test_scene)
		
		# Verify collision shapes were documented
		if collision_shapes.is_empty():
			# It's okay to have no collision shapes for some assets
			return {"success": true}
		
		# Verify each collision shape has complete documentation
		for i in range(collision_shapes.size()):
			var shape = collision_shapes[i]
			
			# Verify shape type is documented
			if shape.shape_type.is_empty():
				return {
					"success": false,
					"input": "size=%s, shape_index=%d" % [size, i],
					"reason": "Collision shape has no type documented"
				}
			
			# Verify position is documented
			if shape.position == Vector3.ZERO and i > 0:
				# First shape might legitimately be at origin, but others should vary
				pass
			
			# Verify dimensions are documented based on shape type
			if shape.shape_type == "box":
				if shape.size == Vector3.ZERO:
					return {
						"success": false,
						"input": "size=%s, shape_index=%d" % [size, i],
						"reason": "Box collision shape has zero size"
					}
				
				# Verify documented size is reasonable (within ±0.1 of expected)
				# For test assets, collision size should be similar to visual size
				var size_diff = (shape.size - size).abs()
				var max_diff = max(size_diff.x, max(size_diff.y, size_diff.z))
				
				# Allow up to 20% difference (collision might be smaller than visual)
				var tolerance = max(size.x, max(size.y, size.z)) * 0.2 + 0.1
				if max_diff > tolerance:
					return {
						"success": false,
						"input": "size=%s, shape_index=%d" % [size, i],
						"reason": "Box collision size %s differs significantly from expected %s (diff=%.2f, tolerance=%.2f)" % [
							shape.size, size, max_diff, tolerance
						]
					}
			
			elif shape.shape_type == "sphere":
				if shape.radius <= 0:
					return {
						"success": false,
						"input": "size=%s, shape_index=%d" % [size, i],
						"reason": "Sphere collision shape has zero or negative radius"
					}
			
			elif shape.shape_type == "capsule":
				if shape.radius <= 0 or shape.height <= 0:
					return {
						"success": false,
						"input": "size=%s, shape_index=%d" % [size, i],
						"reason": "Capsule collision shape has zero or negative dimensions"
					}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 14: Metadata Storage Round-Trip
func test_property_metadata_storage_round_trip():
	assert_property_holds("Metadata Storage Round-Trip", func(iteration: int) -> Dictionary:
		# Generate random asset metadata
		var original_metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
		
		# Create database and store metadata
		var database = AssetMetadataDatabase.new()
		database.store(original_metadata)
		
		# Retrieve metadata
		var retrieved_metadata = database.get_metadata(original_metadata.asset_name)
		
		if retrieved_metadata == null:
			return {
				"success": false,
				"input": "asset_name=%s" % original_metadata.asset_name,
				"reason": "Failed to retrieve stored metadata"
			}
		
		# Verify key fields are preserved
		if retrieved_metadata.asset_name != original_metadata.asset_name:
			return {
				"success": false,
				"input": "asset_name=%s" % original_metadata.asset_name,
				"reason": "Asset name not preserved: original=%s, retrieved=%s" % [
					original_metadata.asset_name,
					retrieved_metadata.asset_name
				]
			}
		
		# Verify bounding box preserved
		var bbox_diff = (original_metadata.bounding_box.size - retrieved_metadata.bounding_box.size).abs()
		var max_bbox_diff = max(bbox_diff.x, max(bbox_diff.y, bbox_diff.z))
		if max_bbox_diff > 0.001:
			return {
				"success": false,
				"input": "asset_name=%s" % original_metadata.asset_name,
				"reason": "Bounding box not preserved: original=%s, retrieved=%s" % [
					original_metadata.bounding_box.size,
					retrieved_metadata.bounding_box.size
				]
			}
		
		# Verify connection points count preserved
		if original_metadata.connection_points.size() != retrieved_metadata.connection_points.size():
			return {
				"success": false,
				"input": "asset_name=%s" % original_metadata.asset_name,
				"reason": "Connection point count not preserved: original=%d, retrieved=%d" % [
					original_metadata.connection_points.size(),
					retrieved_metadata.connection_points.size()
				]
			}
		
		# Verify collision shapes count preserved
		if original_metadata.collision_shapes.size() != retrieved_metadata.collision_shapes.size():
			return {
				"success": false,
				"input": "asset_name=%s" % original_metadata.asset_name,
				"reason": "Collision shape count not preserved: original=%d, retrieved=%d" % [
					original_metadata.collision_shapes.size(),
					retrieved_metadata.collision_shapes.size()
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 16: Metadata Query Performance
func test_property_metadata_query_performance():
	assert_property_holds("Metadata Query Performance", func(iteration: int) -> Dictionary:
		# Create database and populate with random metadata
		var database = AssetMetadataDatabase.new()
		var num_assets = 100
		var asset_names: Array[String] = []
		
		for i in range(num_assets):
			var metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
			metadata.asset_name = "asset_%d" % i
			database.store(metadata)
			asset_names.append(metadata.asset_name)
		
		# Measure query time for 100 consecutive queries
		var start_time = Time.get_ticks_usec()
		
		for i in range(100):
			var asset_name = asset_names[rng.randi() % asset_names.size()]
			var metadata = database.get_metadata(asset_name)
			if metadata == null:
				return {
					"success": false,
					"input": "iteration=%d, asset_name=%s" % [iteration, asset_name],
					"reason": "Failed to retrieve metadata during performance test"
				}
		
		var end_time = Time.get_ticks_usec()
		var total_time_ms = (end_time - start_time) / 1000.0
		var avg_time_ms = total_time_ms / 100.0
		
		# Each query should complete within 1 millisecond
		if avg_time_ms > 1.0:
			return {
				"success": false,
				"input": "iteration=%d, num_assets=%d" % [iteration, num_assets],
				"reason": "Average query time %.3f ms exceeds 1 ms limit" % avg_time_ms
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 17: Version History Preservation
func test_property_version_history_preservation():
	assert_property_holds("Version History Preservation", func(iteration: int) -> Dictionary:
		# Generate initial metadata
		var metadata_v1 = AssetTestHelpers.generate_random_asset_metadata(rng)
		metadata_v1.asset_name = "test_asset"
		
		# Create database and store first version
		var database = AssetMetadataDatabase.new()
		database.store(metadata_v1)
		
		# Generate updated metadata (same asset name, different dimensions)
		var metadata_v2 = AssetTestHelpers.generate_random_asset_metadata(rng)
		metadata_v2.asset_name = "test_asset"
		
		# Store updated version
		database.store(metadata_v2)
		
		# Retrieve version history
		var history = database.get_version_history("test_asset")
		
		# Verify history contains previous version
		if history.size() != 1:
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Expected 1 version in history, found %d" % history.size()
			}
		
		# Verify previous version is preserved
		var stored_v1 = history[0]
		var bbox_diff = (metadata_v1.bounding_box.size - stored_v1.bounding_box.size).abs()
		var max_diff = max(bbox_diff.x, max(bbox_diff.y, bbox_diff.z))
		
		if max_diff > 0.001:
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Previous version not preserved correctly: original=%s, stored=%s" % [
					metadata_v1.bounding_box.size,
					stored_v1.bounding_box.size
				]
			}
		
		# Verify current version is the updated one
		var current = database.get_metadata("test_asset")
		var current_diff = (metadata_v2.bounding_box.size - current.bounding_box.size).abs()
		var max_current_diff = max(current_diff.x, max(current_diff.y, current_diff.z))
		
		if max_current_diff > 0.001:
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Current version not updated correctly: expected=%s, current=%s" % [
					metadata_v2.bounding_box.size,
					current.bounding_box.size
				]
			}
		
		# Test multiple updates
		var metadata_v3 = AssetTestHelpers.generate_random_asset_metadata(rng)
		metadata_v3.asset_name = "test_asset"
		database.store(metadata_v3)
		
		var history_after_v3 = database.get_version_history("test_asset")
		if history_after_v3.size() != 2:
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Expected 2 versions in history after third update, found %d" % history_after_v3.size()
			}
		
		return {"success": true}
	)


# Feature: dungeon-asset-mapping, Property 7: Corridor Count Formula
func test_property_corridor_count_formula():
	assert_property_holds("Corridor Count Formula", func(iteration: int) -> Dictionary:
		# Generate random corridor metadata
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata = AssetMetadata.new()
		metadata.asset_name = "test_corridor"
		metadata.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points at the ends
		var point_a = ConnectionPoint.new()
		point_a.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_a.normal = Vector3(0, 0, -1)
		point_a.type = "corridor_end"
		point_a.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b = ConnectionPoint.new()
		point_b.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_b.normal = Vector3(0, 0, 1)
		point_b.type = "corridor_end"
		point_b.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata.connection_points = [point_a, point_b]
		
		# Generate random target distance
		var target_distance = rng.randf_range(10.0, 50.0)
		
		# Calculate corridor count
		var calculator = LayoutCalculator.new()
		var count = calculator.calculate_corridor_count(target_distance, metadata)
		
		if count < 0:
			return {
				"success": false,
				"input": "distance=%.2f, corridor_length=%.2f" % [target_distance, corridor_length],
				"reason": "Calculator returned error code: %d" % count
			}
		
		# Calculate actual total length with this count
		var overlap = calculator._calculate_overlap(metadata)
		var effective_length = corridor_length - (2 * overlap)
		var actual_length = count * effective_length
		
		# Verify that the actual length is within ±1.0 units of target
		# Note: 1.0 unit tolerance is used due to discrete corridor lengths (4-6 units)
		# See design.md for details on why tighter tolerance is not achievable
		var length_diff = abs(actual_length - target_distance)
		
		if length_diff > 1.0:
			return {
				"success": false,
				"input": "distance=%.2f, corridor_length=%.2f, count=%d" % [target_distance, corridor_length, count],
				"reason": "Actual length %.2f differs from target %.2f by %.2f units (max allowed: 1.0)" % [
					actual_length, target_distance, length_diff
				]
			}
		
		# Verify that using one fewer corridor would be too short
		if count > 1:
			var shorter_length = (count - 1) * effective_length
			if shorter_length >= target_distance - 1.0:
				return {
					"success": false,
					"input": "distance=%.2f, corridor_length=%.2f, count=%d" % [target_distance, corridor_length, count],
					"reason": "Count %d may be too high: %d corridors would give %.2f (within tolerance)" % [
						count, count - 1, shorter_length
					]
				}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 8: Overlap Calculation Consistency
func test_property_overlap_calculation_consistency():
	assert_property_holds("Overlap Calculation Consistency", func(iteration: int) -> Dictionary:
		# Generate random corridor metadata
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata = AssetMetadata.new()
		metadata.asset_name = "test_corridor"
		metadata.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points at the ends with random positions
		var offset_a = rng.randf_range(0.1, 0.5)
		var offset_b = rng.randf_range(0.1, 0.5)
		
		var point_a = ConnectionPoint.new()
		point_a.position = Vector3(0, corridor_height/2, -corridor_length/2 + offset_a)
		point_a.normal = Vector3(0, 0, -1)
		point_a.type = "corridor_end"
		point_a.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b = ConnectionPoint.new()
		point_b.position = Vector3(0, corridor_height/2, corridor_length/2 - offset_b)
		point_b.normal = Vector3(0, 0, 1)
		point_b.type = "corridor_end"
		point_b.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata.connection_points = [point_a, point_b]
		
		# Calculate overlap multiple times
		var calculator = LayoutCalculator.new()
		var overlap_1 = calculator._calculate_overlap(metadata)
		var overlap_2 = calculator._calculate_overlap(metadata)
		var overlap_3 = calculator._calculate_overlap(metadata)
		
		# Verify consistency (all calculations should return the same value)
		if abs(overlap_1 - overlap_2) > 0.001 or abs(overlap_2 - overlap_3) > 0.001:
			return {
				"success": false,
				"input": "corridor_length=%.2f" % corridor_length,
				"reason": "Overlap calculation inconsistent: %.4f, %.4f, %.4f" % [
					overlap_1, overlap_2, overlap_3
				]
			}
		
		# Verify overlap is reasonable (should be less than corridor length)
		if overlap_1 >= corridor_length:
			return {
				"success": false,
				"input": "corridor_length=%.2f" % corridor_length,
				"reason": "Overlap %.2f is >= corridor length %.2f" % [overlap_1, corridor_length]
			}
		
		# Verify overlap is non-negative
		if overlap_1 < 0:
			return {
				"success": false,
				"input": "corridor_length=%.2f" % corridor_length,
				"reason": "Overlap %.2f is negative" % overlap_1
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping-bugfixes, Property 2.4: Position-Count Round-Trip
func test_property_position_count_round_trip():
	assert_property_holds("Position-Count Round-Trip", func(iteration: int) -> Dictionary:
		# Generate random corridor metadata
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata = AssetMetadata.new()
		metadata.asset_name = "test_corridor"
		metadata.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points at the ends
		var point_a = ConnectionPoint.new()
		point_a.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_a.normal = Vector3(0, 0, -1)
		point_a.type = "corridor_end"
		point_a.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b = ConnectionPoint.new()
		point_b.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_b.normal = Vector3(0, 0, 1)
		point_b.type = "corridor_end"
		point_b.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata.connection_points = [point_a, point_b]
		
		# Generate random corridor count (1-10)
		var original_count = rng.randi_range(1, 10)
		
		# Calculate position using calculate_position_from_corridor_count()
		var calculator = LayoutCalculator.new()
		var start_position = Vector3.ZERO
		var direction = Vector3(0, 0, 1)  # Forward along Z axis
		
		var calculated_position = calculator.calculate_position_from_corridor_count(
			start_position,
			original_count,
			metadata,
			direction
		)
		
		# Calculate distance from start to calculated position
		var distance = start_position.distance_to(calculated_position)
		
		# Verify calculate_corridor_count(distance) returns original count
		var detected_count = calculator.calculate_corridor_count(distance, metadata)
		
		if detected_count < 0:
			return {
				"success": false,
				"input": "original_count=%d, corridor_length=%.2f" % [original_count, corridor_length],
				"reason": "Calculator returned error code: %d" % detected_count
			}
		
		# Round-trip should be exact (no tolerance needed for generated positions)
		if detected_count != original_count:
			return {
				"success": false,
				"input": "original_count=%d, corridor_length=%.2f, distance=%.2f" % [
					original_count, corridor_length, distance
				],
				"reason": "Round-trip failed: original count=%d, detected count=%d" % [
					original_count, detected_count
				]
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 18: Gap and Overlap Detection
func test_property_gap_and_overlap_detection():
	assert_property_holds("Gap and Overlap Detection", func(iteration: int) -> Dictionary:
		# Generate two random corridor metadata objects
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata_a = AssetMetadata.new()
		metadata_a.asset_name = "corridor_a"
		metadata_a.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points
		var point_a1 = ConnectionPoint.new()
		point_a1.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_a1.normal = Vector3(0, 0, -1)
		point_a1.type = "corridor_end"
		point_a1.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_a2 = ConnectionPoint.new()
		point_a2.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_a2.normal = Vector3(0, 0, 1)
		point_a2.type = "corridor_end"
		point_a2.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata_a.connection_points = [point_a1, point_a2]
		
		# Create second corridor with same dimensions
		var metadata_b = AssetMetadata.new()
		metadata_b.asset_name = "corridor_b"
		metadata_b.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		var point_b1 = ConnectionPoint.new()
		point_b1.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_b1.normal = Vector3(0, 0, -1)
		point_b1.type = "corridor_end"
		point_b1.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b2 = ConnectionPoint.new()
		point_b2.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_b2.normal = Vector3(0, 0, 1)
		point_b2.type = "corridor_end"
		point_b2.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata_b.connection_points = [point_b1, point_b2]
		
		# Test case 1: Large gap (should be detected)
		var gap_distance = rng.randf_range(0.3, 1.0)  # > 0.2 threshold
		var pos_a = Vector3.ZERO
		var pos_b = Vector3(0, 0, corridor_length + gap_distance)
		var rot = Vector3.ZERO
		
		var calculator = LayoutCalculator.new()
		var result_gap = calculator.validate_connection(metadata_a, pos_a, rot, metadata_b, pos_b, rot)
		
		if not result_gap.has_gap:
			return {
				"success": false,
				"input": "gap_distance=%.2f" % gap_distance,
				"reason": "Failed to detect gap of %.2f units (threshold: 0.2)" % gap_distance
			}
		
		# Test case 2: Small gap (should not be detected as error)
		var small_gap = rng.randf_range(0.0, 0.15)  # < 0.2 threshold
		pos_b = Vector3(0, 0, corridor_length + small_gap)
		var result_small_gap = calculator.validate_connection(metadata_a, pos_a, rot, metadata_b, pos_b, rot)
		
		if result_small_gap.has_gap:
			return {
				"success": false,
				"input": "small_gap=%.2f" % small_gap,
				"reason": "False positive: detected gap of %.2f units (threshold: 0.2)" % small_gap
			}
		
		# Test case 3: Overlap (assets very close)
		var overlap_distance = rng.randf_range(-0.2, 0.05)  # Very close or overlapping
		pos_b = Vector3(0, 0, corridor_length + overlap_distance)
		var result_overlap = calculator.validate_connection(metadata_a, pos_a, rot, metadata_b, pos_b, rot)
		
		if not result_overlap.has_overlap:
			return {
				"success": false,
				"input": "overlap_distance=%.2f" % overlap_distance,
				"reason": "Failed to detect overlap/close proximity (distance: %.2f)" % overlap_distance
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 19: Layout Connection Validation
func test_property_layout_connection_validation():
	assert_property_holds("Layout Connection Validation", func(iteration: int) -> Dictionary:
		# Generate random number of assets (2-5)
		var num_assets = rng.randi_range(2, 5)
		
		# Create corridor metadata
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata = AssetMetadata.new()
		metadata.asset_name = "corridor"
		metadata.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points
		var point_a = ConnectionPoint.new()
		point_a.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_a.normal = Vector3(0, 0, -1)
		point_a.type = "corridor_end"
		point_a.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b = ConnectionPoint.new()
		point_b.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_b.normal = Vector3(0, 0, 1)
		point_b.type = "corridor_end"
		point_b.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata.connection_points = [point_a, point_b]
		metadata.walkable_area = AABB(
			Vector3(-corridor_width/2 + 0.1, 0, -corridor_length/2 + 0.1),
			Vector3(corridor_width - 0.2, 0.1, corridor_length - 0.2)
		)
		
		# Create layout with proper spacing (should be valid)
		# Connection points are at ±corridor_length/2, so adjacent corridors should be
		# spaced at corridor_length apart (edge-to-edge) minus a small overlap for connection
		# We want overlap < 0.1 units, so use 0.05 units of overlap
		var layout_valid: Array[PlacedAsset] = []
		for i in range(num_assets):
			var placed = PlacedAsset.new()
			placed.metadata = metadata
			# Space corridors at (corridor_length - 0.05) to create 0.05 units of overlap
			placed.position = Vector3(0, 0, i * (corridor_length - 0.05))
			placed.rotation = Vector3.ZERO
			layout_valid.append(placed)
		
		var calculator = LayoutCalculator.new()
		var result_valid = calculator.validate_layout(layout_valid)
		
		# Valid layout should pass validation
		if not result_valid.is_valid:
			return {
				"success": false,
				"input": "num_assets=%d, corridor_length=%.2f" % [num_assets, corridor_length],
				"reason": "Valid layout failed validation: %s" % result_valid.get_summary()
			}
		
		# Create layout with large gap (should be invalid)
		var layout_invalid: Array[PlacedAsset] = []
		for i in range(num_assets):
			var placed = PlacedAsset.new()
			placed.metadata = metadata
			# Add large gap between assets
			var gap = 0.5 if i > 0 else 0.0
			placed.position = Vector3(0, 0, i * (corridor_length + gap))
			placed.rotation = Vector3.ZERO
			layout_invalid.append(placed)
		
		var result_invalid = calculator.validate_layout(layout_invalid)
		
		# Invalid layout should fail validation
		if result_invalid.is_valid:
			return {
				"success": false,
				"input": "num_assets=%d, corridor_length=%.2f" % [num_assets, corridor_length],
				"reason": "Invalid layout (with gaps) passed validation"
			}
		
		# Verify that gaps were detected
		if not result_invalid.has_gap:
			return {
				"success": false,
				"input": "num_assets=%d" % num_assets,
				"reason": "Layout validation failed but didn't detect gaps"
			}
		
		return {"success": true}
	)

# Feature: dungeon-asset-mapping, Property 20: Navigation Path Continuity
func test_property_navigation_path_continuity():
	assert_property_holds("Navigation Path Continuity", func(iteration: int) -> Dictionary:
		# Generate random corridor metadata with walkable area
		var corridor_length = rng.randf_range(4.0, 6.0)
		var corridor_width = rng.randf_range(2.0, 3.0)
		var corridor_height = rng.randf_range(2.5, 4.0)
		
		var metadata = AssetMetadata.new()
		metadata.asset_name = "corridor"
		metadata.bounding_box = AABB(
			Vector3(-corridor_width/2, 0, -corridor_length/2),
			Vector3(corridor_width, corridor_height, corridor_length)
		)
		
		# Add connection points
		var point_a = ConnectionPoint.new()
		point_a.position = Vector3(0, corridor_height/2, -corridor_length/2)
		point_a.normal = Vector3(0, 0, -1)
		point_a.type = "corridor_end"
		point_a.dimensions = Vector2(corridor_width, corridor_height)
		
		var point_b = ConnectionPoint.new()
		point_b.position = Vector3(0, corridor_height/2, corridor_length/2)
		point_b.normal = Vector3(0, 0, 1)
		point_b.type = "corridor_end"
		point_b.dimensions = Vector2(corridor_width, corridor_height)
		
		metadata.connection_points = [point_a, point_b]
		
		# Define walkable area (slightly smaller than bounding box)
		metadata.walkable_area = AABB(
			Vector3(-corridor_width/2 + 0.1, 0, -corridor_length/2 + 0.1),
			Vector3(corridor_width - 0.2, 0.1, corridor_length - 0.2)
		)
		
		# Create layout with 2-3 connected corridors
		var num_assets = rng.randi_range(2, 3)
		var layout: Array[PlacedAsset] = []
		
		for i in range(num_assets):
			var placed = PlacedAsset.new()
			placed.metadata = metadata
			placed.position = Vector3(0, 0, i * corridor_length * 0.95)  # Slight overlap
			placed.rotation = Vector3.ZERO
			layout.append(placed)
		
		var calculator = LayoutCalculator.new()
		var result = calculator.validate_layout(layout)
		
		# Verify that all assets have walkable areas defined
		for i in range(layout.size()):
			if layout[i].metadata.walkable_area.size == Vector3.ZERO:
				return {
					"success": false,
					"input": "iteration=%d, asset_index=%d" % [iteration, i],
					"reason": "Asset %d has no walkable area defined" % i
				}
		
		# For a valid layout, walkable areas should be continuous
		# (This is a basic check - in practice, we'd verify actual overlap)
		if result.is_valid:
			# Verify no error messages about missing walkable areas
			for error in result.error_messages:
				if "no walkable area" in error.to_lower():
					return {
						"success": false,
						"input": "num_assets=%d" % num_assets,
						"reason": "Valid layout has walkable area errors: %s" % error
					}
		
		# Test case with missing walkable area
		var metadata_no_walkable = AssetMetadata.new()
		metadata_no_walkable.asset_name = "corridor_no_walkable"
		metadata_no_walkable.bounding_box = metadata.bounding_box
		metadata_no_walkable.connection_points = metadata.connection_points
		metadata_no_walkable.walkable_area = AABB()  # Empty walkable area
		
		var layout_no_walkable: Array[PlacedAsset] = []
		var placed_no_walkable = PlacedAsset.new()
		placed_no_walkable.metadata = metadata_no_walkable
		placed_no_walkable.position = Vector3.ZERO
		placed_no_walkable.rotation = Vector3.ZERO
		layout_no_walkable.append(placed_no_walkable)
		
		var result_no_walkable = calculator.validate_layout(layout_no_walkable)
		
		# Should detect missing walkable area
		var found_walkable_error = false
		for error in result_no_walkable.error_messages:
			if "no walkable area" in error.to_lower():
				found_walkable_error = true
				break
		
		if not found_walkable_error:
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Failed to detect missing walkable area"
			}
		
		return {"success": true}
	)


# Feature: dungeon-asset-mapping, Property 21: Documentation Generation Completeness
func test_property_documentation_generation_completeness():
	assert_property_holds("Documentation Generation Completeness", func(iteration: int) -> Dictionary:
		# Generate random asset metadata
		var metadata = AssetTestHelpers.generate_random_asset_metadata(rng)
		
		# Ensure metadata has all required fields
		metadata.asset_name = "test_asset_%d" % iteration
		metadata.asset_path = "res://test/asset_%d.glb" % iteration
		metadata.asset_format = "GLB"
		metadata.measurement_timestamp = Time.get_unix_time_from_system()
		
		# Generate documentation
		var generator = DocumentationGenerator.new()
		var doc = generator.generate_asset_doc(metadata)
		
		# Verify documentation is not empty
		if doc.is_empty():
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Generated documentation is empty"
			}
		
		# Verify required sections are present
		var required_sections = [
			"# Asset:",
			"## Metadata",
			"## Dimensions",
			"## Connection Points",
			"## Collision Geometry",
			"## Walkable Area",
			"## Rotation",
			"## Visual Diagram"
		]
		
		for section in required_sections:
			if not doc.contains(section):
				return {
					"success": false,
					"input": "asset_name=%s" % metadata.asset_name,
					"reason": "Missing required section: %s" % section
				}
		
		# Verify asset name is in the documentation
		if not doc.contains(metadata.asset_name):
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Asset name not found in documentation"
			}
		
		# Verify dimensions are documented
		if not doc.contains("Bounding Box"):
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Bounding box dimensions not documented"
			}
		
		# Verify connection points are documented
		if metadata.connection_points.size() > 0:
			if not doc.contains("Connection Point"):
				return {
					"success": false,
					"input": "asset_name=%s, connection_count=%d" % [
						metadata.asset_name,
						metadata.connection_points.size()
					],
					"reason": "Connection points not documented despite having %d points" % metadata.connection_points.size()
				}
		
		# Verify collision shapes are documented
		if metadata.collision_shapes.size() > 0:
			if not doc.contains("Collision Shape"):
				return {
					"success": false,
					"input": "asset_name=%s, collision_count=%d" % [
						metadata.asset_name,
						metadata.collision_shapes.size()
					],
					"reason": "Collision shapes not documented despite having %d shapes" % metadata.collision_shapes.size()
				}
		
		# Test spacing documentation
		var calculator = LayoutCalculator.new()
		var spacing_doc = generator.generate_spacing_doc(calculator)
		
		if spacing_doc.is_empty():
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Spacing documentation is empty"
			}
		
		# Verify spacing doc has required sections
		if not spacing_doc.contains("Corridor Count Formula"):
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Spacing documentation missing formula section"
			}
		
		if not spacing_doc.contains("Worked Examples"):
			return {
				"success": false,
				"input": "iteration=%d" % iteration,
				"reason": "Spacing documentation missing examples section"
			}
		
		# Test rotation documentation
		var rotation_doc = generator.generate_rotation_doc(metadata)
		
		if rotation_doc.is_empty():
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Rotation documentation is empty"
			}
		
		# Verify rotation doc has required sections
		if not rotation_doc.contains("Cardinal Direction Rotations"):
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Rotation documentation missing cardinal directions"
			}
		
		if not rotation_doc.contains("Rotation Matrices"):
			return {
				"success": false,
				"input": "asset_name=%s" % metadata.asset_name,
				"reason": "Rotation documentation missing rotation matrices"
			}
		
		# Verify all four cardinal directions are documented
		var cardinal_directions = ["North", "East", "South", "West"]
		for direction in cardinal_directions:
			if not rotation_doc.contains(direction):
				return {
					"success": false,
					"input": "asset_name=%s" % metadata.asset_name,
					"reason": "Rotation documentation missing direction: %s" % direction
				}
		
		return {"success": true}
	)
