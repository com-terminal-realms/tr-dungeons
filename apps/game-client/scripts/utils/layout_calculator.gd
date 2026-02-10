class_name LayoutCalculator
extends RefCounted

## Computes spacing requirements and validates dungeon layouts

var metadata_db: AssetMetadataDatabase

func _init(p_metadata_db: AssetMetadataDatabase = null):
	metadata_db = p_metadata_db

## PRIMARY FUNCTION: Calculate position from corridor count (for layout generation)
## This is the recommended function for generating new layouts
## Specify how many corridors you want, get exact position for next room
func calculate_position_from_corridor_count(
	start_position: Vector3,
	corridor_count: int,
	corridor_metadata: AssetMetadata,
	direction: Vector3 = Vector3(0, 0, 1)
) -> Vector3:
	if corridor_count < 1:
		push_error("LayoutCalculator: Corridor count must be at least 1")
		return start_position
	
	if corridor_metadata == null:
		push_error("LayoutCalculator: Corridor metadata is null")
		return start_position
	
	# Get corridor dimensions
	var corridor_length = corridor_metadata.bounding_box.size.z
	
	if corridor_length <= 0:
		push_error("LayoutCalculator: Invalid corridor length %.2f" % corridor_length)
		return start_position
	
	# Calculate overlap at connection points
	var overlap = _calculate_overlap(corridor_metadata)
	
	# Effective length is the corridor length minus overlap at BOTH ends
	var effective_length = corridor_length - (2 * overlap)
	
	if effective_length <= 0:
		push_error("LayoutCalculator: Effective length %.2f is not positive (length=%.2f, overlap=%.2f)" % [
			effective_length, corridor_length, overlap
		])
		return start_position
	
	# Calculate total distance
	var distance = corridor_count * effective_length
	
	# Return new position
	return start_position + (direction.normalized() * distance)

## VALIDATION FUNCTION: Calculate corridor count from distance (for validation only)
## This function is used to validate existing layouts, not generate new ones
## For layout generation, use calculate_position_from_corridor_count() instead
## Calculate number of corridor pieces needed for a given distance
## Formula: count = max(1, ceil(distance / effective_length))
## where effective_length = corridor_length - (2 * overlap)
func calculate_corridor_count(distance: float, corridor_metadata: AssetMetadata) -> int:
	if distance <= 0:
		push_warning("LayoutCalculator: Invalid distance %.2f (must be positive)" % distance)
		return -1
	
	if corridor_metadata == null:
		push_warning("LayoutCalculator: Corridor metadata is null")
		return -1
	
	# Get corridor length from bounding box (use Z axis for corridor length)
	var corridor_length = corridor_metadata.bounding_box.size.z
	
	if corridor_length <= 0:
		push_warning("LayoutCalculator: Invalid corridor length %.2f" % corridor_length)
		return -1
	
	# Calculate overlap at connection points
	# Overlap is the distance from the corridor edge to its connection point
	var overlap = _calculate_overlap(corridor_metadata)
	
	# Effective length is the corridor length minus overlap at BOTH ends
	var effective_length = corridor_length - (2 * overlap)
	
	if effective_length <= 0:
		push_warning("LayoutCalculator: Effective length %.2f is not positive (length=%.2f, overlap=%.2f)" % [
			effective_length, corridor_length, overlap
		])
		return -1
	
	# Calculate number of corridors needed
	# For very short distances, we need at least 1 corridor
	# Try both floor and ceil, pick whichever is closer to target
	# Prefer floor (fewer corridors) if errors are equal
	var exact_count = distance / effective_length
	var count_floor = maxi(1, floori(exact_count))
	var count_ceil = ceili(exact_count)
	
	# Calculate actual lengths for both options
	var length_floor = count_floor * effective_length
	var length_ceil = count_ceil * effective_length
	
	# Calculate errors
	var diff_floor = abs(length_floor - distance)
	var diff_ceil = abs(length_ceil - distance)
	
	# Pick the one with smaller error, preferring floor if equal
	var count = count_floor if diff_floor < diff_ceil else count_ceil
	
	# Verify the calculation
	var actual_length = count * effective_length
	var length_diff = abs(actual_length - distance)
	
	# If we're more than 0.5 units off, log a warning
	if length_diff > 0.5:
		push_warning("Corridor count %d gives length %.2f, target was %.2f (diff: %.2f)" % [
			count, actual_length, distance, length_diff
		])
	
	return count

## Calculate overlap at connection points
## For corridors, overlap is the distance from connection point to the end of the asset
func _calculate_overlap(metadata: AssetMetadata) -> float:
	if metadata == null or metadata.connection_points.is_empty():
		return 0.0
	
	# For a corridor, we expect 2 connection points (entry and exit)
	# The overlap is the distance from the corridor edge to the connection point
	
	# Get the bounding box
	var bbox = metadata.bounding_box
	var corridor_length = bbox.size.z
	
	# Find the connection points along the Z axis (corridor direction)
	var connection_z_positions: Array[float] = []
	for point in metadata.connection_points:
		# Check if this connection point is along the Z axis (corridor direction)
		if abs(point.normal.z) > 0.9:  # Normal points along Z
			connection_z_positions.append(point.position.z)
	
	if connection_z_positions.size() < 2:
		# Fallback: assume connection points are at the edges (no overlap)
		return 0.0
	
	# Sort the positions
	connection_z_positions.sort()
	
	# Calculate the distance between the two connection points
	# This is the "usable" length of the corridor
	var connection_distance = connection_z_positions[-1] - connection_z_positions[0]
	
	# The overlap at each end is the difference between the full corridor length
	# and the distance between connection points, divided by 2
	var total_overlap = corridor_length - connection_distance
	var overlap_per_end = total_overlap / 2.0
	
	# If connection points are at the edges (overlap_per_end ≈ 0),
	# use a small default overlap for smooth connections (0.025 units per end)
	if abs(overlap_per_end) < 0.01:
		overlap_per_end = 0.025
	
	# Ensure overlap is non-negative
	return max(0.0, overlap_per_end)

## Validate connection between two assets
## Checks for gaps, overlaps, and normal alignment
func validate_connection(
	asset_a: AssetMetadata,
	pos_a: Vector3,
	rot_a: Vector3,
	asset_b: AssetMetadata,
	pos_b: Vector3,
	rot_b: Vector3
) -> ValidationResult:
	
	var result = ValidationResult.new()
	
	if asset_a == null or asset_b == null:
		result.is_valid = false
		result.add_error("One or both assets are null")
		return result
	
	# Find closest connection points between the two assets
	var conn_a = _find_closest_connection(asset_a, pos_a, rot_a, pos_b)
	var conn_b = _find_closest_connection(asset_b, pos_b, rot_b, pos_a)
	
	if conn_a == null or conn_b == null:
		result.is_valid = false
		result.add_error("No connection points found")
		return result
	
	# Transform connection points to world space
	var world_pos_a = _transform_connection_to_world(conn_a, pos_a, rot_a)
	var world_pos_b = _transform_connection_to_world(conn_b, pos_b, rot_b)
	
	# Transform normals to world space
	var normal_a_world = _transform_normal_to_world(conn_a.normal, rot_a)
	var normal_b_world = _transform_normal_to_world(conn_b.normal, rot_b)
	
	# Check if normals are opposite (should be for a valid connection)
	var normal_dot = normal_a_world.dot(normal_b_world)
	result.normals_aligned = (normal_dot < -0.9)  # Should be close to -1
	
	# Calculate the signed distance between connection points
	# Positive = gap, Negative = overlap
	# We project the vector from A to B onto the normal of A
	var gap_vector = world_pos_b - world_pos_a
	var gap_distance = gap_vector.dot(normal_a_world)
	
	result.gap_distance = gap_distance
	
	# Gap detection: gaps larger than 0.2 units are errors
	if gap_distance > 0.2:
		result.has_gap = true
		result.is_valid = false
		result.add_error("Gap of %.2f units detected (max allowed: 0.2)" % gap_distance)
	
	# Overlap/close proximity detection: 
	# - Mark has_overlap=true for any overlap OR very close proximity (gap < 0.05)
	# - Only mark as invalid if overlap is > 0.1 units
	if gap_distance < 0.05:  # Overlap or very close
		result.has_overlap = true
		
		# Only mark as error if overlap is significant (> 0.1 units)
		if gap_distance < -0.1:
			result.is_valid = false
			result.add_error("Overlap of %.2f units detected (max allowed: 0.1)" % abs(gap_distance))
	
	# Check normal alignment
	if not result.normals_aligned:
		result.is_valid = false
		result.add_error("Normals not aligned (dot product: %.2f, expected: -1.0)" % normal_dot)
	
	return result

## Transform connection point to world space
func _transform_connection_to_world(conn: ConnectionPoint, pos: Vector3, rot: Vector3) -> Vector3:
	# Apply rotation then translation
	var rot_rad = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	var basis = Basis.from_euler(rot_rad)
	return pos + basis * conn.position

## Transform normal to world space
func _transform_normal_to_world(normal: Vector3, rot: Vector3) -> Vector3:
	# Apply rotation to normal
	var rot_rad = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	var basis = Basis.from_euler(rot_rad)
	return basis * normal

## Find the closest connection point on an asset to a target position
func _find_closest_connection(
	metadata: AssetMetadata,
	asset_pos: Vector3,
	asset_rot: Vector3,
	target_pos: Vector3
) -> ConnectionPoint:
	
	if metadata.connection_points.is_empty():
		return null
	
	var closest_point: ConnectionPoint = null
	var closest_distance = INF
	
	for point in metadata.connection_points:
		# Transform point by rotation
		var transformed = point.transform_by_rotation(asset_rot)
		var world_pos = asset_pos + transformed.position
		
		var distance = world_pos.distance_to(target_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = point
	
	return closest_point

## Validate entire layout
## Checks all connections and navigation continuity
func validate_layout(layout: Array[PlacedAsset]) -> LayoutValidationResult:
	var result = LayoutValidationResult.new()
	
	if layout.is_empty():
		result.add_error("Layout is empty")
		return result
	
	# Check each pair of adjacent assets
	for i in range(layout.size() - 1):
		var asset_a = layout[i]
		var asset_b = layout[i + 1]
		
		if asset_a.metadata == null or asset_b.metadata == null:
			result.add_error("Asset %d or %d has null metadata" % [i, i + 1])
			continue
		
		# Validate connection between adjacent assets
		var conn_result = validate_connection(
			asset_a.metadata, asset_a.position, asset_a.rotation,
			asset_b.metadata, asset_b.position, asset_b.rotation
		)
		
		if not conn_result.is_valid:
			var error_msg = conn_result.get_description() if conn_result.error_messages.size() > 0 else "Unknown error"
			result.add_error("Connection between asset %d and %d failed: %s" % [
				i, i + 1, error_msg
			])
			result.has_gap = result.has_gap or conn_result.has_gap
			result.has_overlap = result.has_overlap or conn_result.has_overlap
		
		if not conn_result.normals_aligned:
			result.normals_aligned = false
	
	# Check navigation continuity (walkable areas should connect)
	var nav_result = _validate_navigation_continuity(layout)
	if not nav_result.is_valid:
		for error in nav_result.error_messages:
			result.add_error("Navigation: %s" % error)
	
	return result

## Validate navigation path continuity
func _validate_navigation_continuity(layout: Array[PlacedAsset]) -> ValidationResult:
	var result = ValidationResult.new()
	result.is_valid = true
	
	# Check that all assets have walkable areas defined
	for i in range(layout.size()):
		var asset = layout[i]
		
		if asset.metadata.walkable_area.size == Vector3.ZERO:
			result.is_valid = false
			result.error_messages.append("Asset %d (%s) has no walkable area defined" % [
				i, asset.metadata.asset_name
			])
	
	# Check that walkable areas are continuous between connected assets
	for i in range(layout.size() - 1):
		var asset_a = layout[i]
		var asset_b = layout[i + 1]
		
		# Transform walkable areas to world space
		var walkable_a_world = _transform_aabb_to_world(
			asset_a.metadata.walkable_area,
			asset_a.position,
			asset_a.rotation
		)
		
		var walkable_b_world = _transform_aabb_to_world(
			asset_b.metadata.walkable_area,
			asset_b.position,
			asset_b.rotation
		)
		
		# Check if walkable areas overlap or are very close (within 0.2 units)
		var gap = _calculate_aabb_gap(walkable_a_world, walkable_b_world)
		
		if gap > 0.2:
			result.is_valid = false
			result.error_messages.append("Walkable area gap of %.2f units between assets %d and %d" % [
				gap, i, i+1
			])
	
	return result

## Transform AABB to world space
func _transform_aabb_to_world(aabb: AABB, pos: Vector3, rot: Vector3) -> AABB:
	# Transform AABB to world space
	var rot_rad = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	var basis = Basis.from_euler(rot_rad)
	
	var world_pos = pos + basis * aabb.position
	# Note: size doesn't change with rotation for axis-aligned boxes
	
	return AABB(world_pos, aabb.size)

## Calculate gap between two AABBs
func _calculate_aabb_gap(aabb_a: AABB, aabb_b: AABB) -> float:
	# Calculate the gap between two AABBs
	# Returns 0 if they overlap, positive if there's a gap
	
	var a_min = aabb_a.position
	var a_max = aabb_a.position + aabb_a.size
	var b_min = aabb_b.position
	var b_max = aabb_b.position + aabb_b.size
	
	# Calculate gap in each axis
	var gap_x = max(0, max(a_min.x - b_max.x, b_min.x - a_max.x))
	var gap_y = max(0, max(a_min.y - b_max.y, b_min.y - a_max.y))
	var gap_z = max(0, max(a_min.z - b_max.z, b_min.z - a_max.z))
	
	# Return the maximum gap (most restrictive axis)
	return max(gap_x, max(gap_y, gap_z))

## Data structure for character validation
## Represents a character/creature placed in the world
class PlacedCharacter:
	var name: String
	var position: Vector3
	var height_offset: float  # Distance from origin to feet (usually 1.0 for humanoids)
	
	func _init(n: String = "", p: Vector3 = Vector3.ZERO, h: float = 1.0):
		name = n
		position = p
		height_offset = h


## Find which asset contains a given position
func _find_containing_asset(pos: Vector3, layout: Array[PlacedAsset]) -> PlacedAsset:
	for asset in layout:
		# Transform asset bounding box to world space
		var world_bbox = _transform_aabb_to_world(
			asset.metadata.bounding_box,
			asset.position,
			asset.rotation
		)
		
		# Check if position is inside this bounding box
		if world_bbox.has_point(pos):
			return asset
	
	return null


## Validate character positioning
## Checks that characters are at the correct floor height
func validate_character_positioning(
	layout: Array[PlacedAsset],
	characters: Array[PlacedCharacter]
) -> ValidationResult:
	var result = ValidationResult.new()
	result.is_valid = true
	
	for character in characters:
		# Find which asset (room/corridor) the character is in
		var containing_asset = _find_containing_asset(character.position, layout)
		
		if containing_asset == null:
			result.is_valid = false
			result.add_error("Character '%s' at (%.2f, %.2f, %.2f) is not inside any asset" % [
				character.name, character.position.x, character.position.y, character.position.z
			])
			continue
		
		# Get the floor height of the containing asset
		var floor_height = containing_asset.metadata.floor_height
		
		# Calculate expected Y position
		# Character should be at floor_height + character_height_offset
		var expected_y = floor_height + character.height_offset
		
		# Check if character is at correct height (within 0.1 unit tolerance)
		var y_diff = abs(character.position.y - expected_y)
		
		if y_diff > 0.1:
			result.is_valid = false
			result.add_error(
				"Character '%s' at incorrect height: expected Y=%.2f, actual Y=%.2f (diff: %.2f)" % [
					character.name, expected_y, character.position.y, y_diff
				]
			)
	
	return result
