class_name LayoutCalculator
extends RefCounted

## Computes spacing requirements and validates dungeon layouts

var metadata_db: AssetMetadataDatabase

func _init(p_metadata_db: AssetMetadataDatabase = null):
	metadata_db = p_metadata_db

## Calculate number of corridor pieces needed for a given distance
## Formula: count = ceil((distance - overlap) / effective_length)
## where effective_length = corridor_length - overlap
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
	var overlap = _calculate_overlap(corridor_metadata)
	
	# Calculate effective length (length minus overlap)
	var effective_length = corridor_length - overlap
	
	if effective_length <= 0:
		push_warning("LayoutCalculator: Effective length %.2f is not positive (length=%.2f, overlap=%.2f)" % [
			effective_length, corridor_length, overlap
		])
		return -1
	
	# Formula: count = ceil((distance - overlap) / effective_length)
	var count = ceili((distance - overlap) / effective_length)
	
	# Ensure at least 1 corridor piece
	return maxi(1, count)

## Calculate overlap at connection points
## For corridors, overlap is the distance from connection point to the end of the asset
func _calculate_overlap(metadata: AssetMetadata) -> float:
	if metadata == null or metadata.connection_points.is_empty():
		return 0.0
	
	# For corridors, find the connection points at the ends
	# Overlap is the distance from the connection point to the edge of the bounding box
	var bbox = metadata.bounding_box
	var corridor_length = bbox.size.z
	
	# Find connection points at the ends (Z axis)
	var end_points: Array[ConnectionPoint] = []
	for point in metadata.connection_points:
		# Check if point is near the ends (Z axis)
		var dist_to_min_z = abs(point.position.z - bbox.position.z)
		var dist_to_max_z = abs(point.position.z - (bbox.position.z + bbox.size.z))
		
		if dist_to_min_z < 0.5 or dist_to_max_z < 0.5:
			end_points.append(point)
	
	if end_points.is_empty():
		# No end connection points found, assume no overlap
		return 0.0
	
	# Calculate overlap as the distance from connection point to the edge
	# For a typical corridor, this is half the wall thickness or connection depth
	# We'll use a heuristic: overlap = distance from connection point to bbox edge
	var total_overlap = 0.0
	for point in end_points:
		var dist_to_min_z = abs(point.position.z - bbox.position.z)
		var dist_to_max_z = abs(point.position.z - (bbox.position.z + bbox.size.z))
		var overlap_at_point = min(dist_to_min_z, dist_to_max_z)
		total_overlap += overlap_at_point
	
	# Average overlap across connection points
	var avg_overlap = total_overlap / end_points.size()
	
	return avg_overlap

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
	
	# Transform connection points by rotation and position
	var transformed_a = conn_a.transform_by_rotation(rot_a)
	var transformed_b = conn_b.transform_by_rotation(rot_b)
	
	var world_pos_a = pos_a + transformed_a.position
	var world_pos_b = pos_b + transformed_b.position
	
	# Calculate gap/overlap distance
	var gap = world_pos_a.distance_to(world_pos_b)
	
	# Check for gaps (> 0.2 units)
	result.has_gap = gap > 0.2
	
	# Check for overlaps (< -0.5 units would mean significant overlap)
	# For now, we'll consider any distance < 0.1 as potential overlap
	result.has_overlap = gap < 0.1
	
	result.gap_distance = gap
	
	# Check normal alignment (should face opposite directions)
	var normal_a = transformed_a.normal
	var normal_b = transformed_b.normal
	var normal_alignment = normal_a.dot(normal_b)
	
	# Normals should be opposite (dot product close to -1)
	result.normals_aligned = abs(normal_alignment + 1.0) < 0.1
	
	# Determine if connection is valid
	result.is_valid = not result.has_gap and result.normals_aligned
	
	if not result.is_valid:
		var errors: Array[String] = []
		if result.has_gap:
			errors.append("Gap of %.2f units detected (max allowed: 0.2)" % gap)
		if not result.normals_aligned:
			errors.append("Normals not aligned (dot product: %.2f, expected: -1.0)" % normal_alignment)
		for error in errors:
			result.add_error(error)
	
	return result

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
	for i in range(layout.size() - 1):
		var asset_a = layout[i]
		var asset_b = layout[i + 1]
		
		if asset_a.metadata == null or asset_b.metadata == null:
			continue
		
		# Check if walkable areas are continuous
		# For now, we'll just verify that both assets have walkable areas defined
		if asset_a.metadata.walkable_area.size == Vector3.ZERO:
			result.add_error("Asset %d has no walkable area defined" % i)
		
		if asset_b.metadata.walkable_area.size == Vector3.ZERO:
			result.add_error("Asset %d has no walkable area defined" % (i + 1))
	
	return result
