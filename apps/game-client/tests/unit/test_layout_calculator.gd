extends GutTest

## Unit tests for LayoutCalculator
## Tests corridor count calculation edge cases

var calculator: LayoutCalculator

func before_each():
	calculator = LayoutCalculator.new()

func after_each():
	calculator = null

## Test: distance = 0 (should return error)
func test_corridor_count_zero_distance():
	var metadata = _create_test_corridor_metadata(4.0)
	var result = calculator.calculate_corridor_count(0.0, metadata)
	assert_eq(result, -1, "Should return error code for zero distance")

## Test: negative distance (should return error)
func test_corridor_count_negative_distance():
	var metadata = _create_test_corridor_metadata(4.0)
	var result = calculator.calculate_corridor_count(-5.0, metadata)
	assert_eq(result, -1, "Should return error code for negative distance")

## Test: null metadata (should return error)
func test_corridor_count_null_metadata():
	var result = calculator.calculate_corridor_count(10.0, null)
	assert_eq(result, -1, "Should return error code for null metadata")

## Test: distance < corridor_length (should return 1)
func test_corridor_count_short_distance():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var distance = corridor_length * 0.5  # Half the corridor length
	
	var result = calculator.calculate_corridor_count(distance, metadata)
	assert_eq(result, 1, "Should return 1 corridor for distance less than corridor length")

## Test: distance = corridor_length (should return 1)
func test_corridor_count_exact_corridor_length():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	
	var result = calculator.calculate_corridor_count(corridor_length, metadata)
	assert_eq(result, 1, "Should return 1 corridor for distance equal to corridor length")

## Test: distance = 2 * corridor_length (should return 2)
func test_corridor_count_double_corridor_length():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var distance = corridor_length * 2.0
	
	var result = calculator.calculate_corridor_count(distance, metadata)
	assert_eq(result, 2, "Should return 2 corridors for distance equal to 2x corridor length")

## Test: distance slightly more than corridor_length (should return 2)
func test_corridor_count_just_over_one_corridor():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	
	# Distance just over one effective length
	var distance = effective_length + 0.1
	
	var result = calculator.calculate_corridor_count(distance, metadata)
	assert_eq(result, 2, "Should return 2 corridors for distance slightly more than one effective length")

## Test: corridor with no connection points (should handle gracefully)
func test_corridor_count_no_connection_points():
	var metadata = AssetMetadata.new()
	metadata.asset_name = "test_corridor"
	metadata.bounding_box = AABB(Vector3(-1, 0, -2), Vector3(2, 3, 4))
	metadata.connection_points = []  # No connection points
	
	var result = calculator.calculate_corridor_count(10.0, metadata)
	# Should still work, assuming zero overlap
	assert_gt(result, 0, "Should return positive corridor count even without connection points")

## Test: very long distance (should scale correctly)
func test_corridor_count_long_distance():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var distance = 50.0
	
	var result = calculator.calculate_corridor_count(distance, metadata)
	assert_gt(result, 10, "Should return many corridors for long distance")
	assert_lt(result, 20, "Should not return excessive corridors")

## Test: overlap calculation consistency
func test_overlap_calculation_consistency():
	var metadata = _create_test_corridor_metadata(4.0)
	
	var overlap1 = calculator._calculate_overlap(metadata)
	var overlap2 = calculator._calculate_overlap(metadata)
	var overlap3 = calculator._calculate_overlap(metadata)
	
	assert_almost_eq(overlap1, overlap2, 0.001, "Overlap calculation should be consistent")
	assert_almost_eq(overlap2, overlap3, 0.001, "Overlap calculation should be consistent")

## Test: overlap is non-negative
func test_overlap_non_negative():
	var metadata = _create_test_corridor_metadata(4.0)
	var overlap = calculator._calculate_overlap(metadata)
	
	assert_gte(overlap, 0.0, "Overlap should be non-negative")

## Test: overlap is less than corridor length
func test_overlap_less_than_length():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var overlap = calculator._calculate_overlap(metadata)
	
	assert_lt(overlap, corridor_length, "Overlap should be less than corridor length")

## Helper: Create test corridor metadata with connection points
func _create_test_corridor_metadata(corridor_length: float) -> AssetMetadata:
	var metadata = AssetMetadata.new()
	metadata.asset_name = "test_corridor"
	
	var corridor_width = 2.0
	var corridor_height = 3.0
	
	# Bounding box centered at origin
	metadata.bounding_box = AABB(
		Vector3(-corridor_width/2, 0, -corridor_length/2),
		Vector3(corridor_width, corridor_height, corridor_length)
	)
	
	# Add connection points at the ends (at the edges)
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
	
	return metadata

## ============================================================================
## Unit tests for calculate_position_from_corridor_count() - NEW FUNCTION
## ============================================================================

## Test: 1 corridor → correct distance
func test_position_from_count_one_corridor():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 1, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * effective_length
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: 2 corridors → 2× distance
func test_position_from_count_two_corridors():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 2, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * (2 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: 5 corridors → 5× distance
func test_position_from_count_five_corridors():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 5, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * (5 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: Different directions (north)
func test_position_from_count_direction_north():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3(10, 0, 20)
	var direction = Vector3(0, 0, -1)  # North (negative Z)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 3, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * (3 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: Different directions (east)
func test_position_from_count_direction_east():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3(10, 0, 20)
	var direction = Vector3(1, 0, 0)  # East (positive X)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 2, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * (2 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: Different directions (west)
func test_position_from_count_direction_west():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3(10, 0, 20)
	var direction = Vector3(-1, 0, 0)  # West (negative X)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 4, metadata, direction)
	
	# Calculate expected distance
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction * (4 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: Invalid inputs (count < 1)
func test_position_from_count_invalid_count_zero():
	var metadata = _create_test_corridor_metadata(4.0)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	
	# Expect error to be logged
	watch_signals(gut)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 0, metadata, direction)
	
	# Should return start position unchanged
	assert_eq(result, start_pos, "Should return start position for invalid count")

## Test: Invalid inputs (count < 1, negative)
func test_position_from_count_invalid_count_negative():
	var metadata = _create_test_corridor_metadata(4.0)
	var start_pos = Vector3(5, 0, 10)
	var direction = Vector3(0, 0, 1)
	
	# Expect error to be logged
	watch_signals(gut)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, -3, metadata, direction)
	
	# Should return start position unchanged
	assert_eq(result, start_pos, "Should return start position for negative count")

## Test: Invalid inputs (null metadata)
func test_position_from_count_null_metadata():
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	
	# Expect error to be logged
	watch_signals(gut)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 3, null, direction)
	
	# Should return start position unchanged
	assert_eq(result, start_pos, "Should return start position for null metadata")

## Test: Non-normalized direction vector (should normalize automatically)
func test_position_from_count_non_normalized_direction():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 5)  # Not normalized (length = 5)
	
	var result = calculator.calculate_position_from_corridor_count(start_pos, 2, metadata, direction)
	
	# Calculate expected distance (direction should be normalized internally)
	var overlap = calculator._calculate_overlap(metadata)
	var effective_length = corridor_length - (2 * overlap)
	var expected_pos = start_pos + direction.normalized() * (2 * effective_length)
	
	assert_almost_eq(result.x, expected_pos.x, 0.001, "X position should match")
	assert_almost_eq(result.y, expected_pos.y, 0.001, "Y position should match")
	assert_almost_eq(result.z, expected_pos.z, 0.001, "Z position should match")

## Test: Round-trip validation (count → position → count)
func test_position_from_count_round_trip():
	var corridor_length = 4.0
	var metadata = _create_test_corridor_metadata(corridor_length)
	var start_pos = Vector3.ZERO
	var direction = Vector3(0, 0, 1)
	var original_count = 7
	
	# Calculate position from count
	var calculated_pos = calculator.calculate_position_from_corridor_count(
		start_pos, original_count, metadata, direction
	)
	
	# Calculate distance
	var distance = start_pos.distance_to(calculated_pos)
	
	# Calculate count from distance
	var detected_count = calculator.calculate_corridor_count(distance, metadata)
	
	# Should match exactly (no tolerance needed)
	assert_eq(detected_count, original_count, "Round-trip should return original count")
