class_name AssetMapper
extends RefCounted

## Measures and analyzes dungeon assets to extract dimensional data
## Asset-agnostic: works with any GLB or FBX format from any source

## Measure an asset and return complete metadata
## Works with GLB, FBX, or any Godot-compatible 3D format
func measure_asset(asset_path: String) -> AssetMetadata:
	# Validate path
	if not FileAccess.file_exists(asset_path):
		push_error("AssetMapper: Asset file not found: %s" % asset_path)
		return null
	
	# Load and instantiate the asset
	var resource = load(asset_path)
	if resource == null:
		push_error("AssetMapper: Failed to load asset: %s" % asset_path)
		return null
	
	var scene = resource.instantiate()
	if scene == null:
		push_error("AssetMapper: Failed to instantiate asset: %s" % asset_path)
		return null
	
	# Create metadata object
	var metadata = AssetMetadata.new()
	metadata.asset_path = asset_path
	metadata.asset_name = asset_path.get_file().get_basename()
	metadata.asset_format = _detect_format(asset_path)
	metadata.measurement_timestamp = Time.get_unix_time_from_system()
	
	# Perform measurements
	metadata.bounding_box = _calculate_bounding_box(scene)
	metadata.origin_offset = _find_origin_offset(scene)
	metadata.collision_shapes = _extract_collision_geometry(scene)
	metadata.floor_height = _measure_floor_height(scene)
	metadata.connection_points = _find_connection_points(scene)
	
	# Determine asset type from name or geometry
	var asset_type = _determine_asset_type(metadata.asset_name, metadata.bounding_box.size)
	
	# Measure type-specific properties
	metadata.wall_thickness = _measure_wall_thickness(scene, asset_type)
	metadata.doorway_dimensions = _measure_doorway_dimensions(scene, metadata.connection_points)
	metadata.default_rotation = _determine_default_rotation(scene)
	
	# Calculate walkable area (for room assets)
	metadata.walkable_area = _calculate_walkable_area(scene, metadata.collision_shapes)
	
	# Clean up
	scene.queue_free()
	
	return metadata

## Detect asset format from file extension
func _detect_format(asset_path: String) -> String:
	var extension = asset_path.get_extension().to_upper()
	if extension in ["GLB", "GLTF"]:
		return "GLB"
	elif extension == "FBX":
		return "FBX"
	else:
		return extension

## Determine asset type from name and geometry
func _determine_asset_type(asset_name: String, size: Vector3) -> String:
	var name_lower = asset_name.to_lower()
	
	# Check name for type hints
	if "wall" in name_lower:
		return "wall"
	elif "corridor" in name_lower:
		return "corridor"
	elif "room" in name_lower:
		return "room"
	elif "door" in name_lower or "gate" in name_lower:
		return "door"
	elif "floor" in name_lower:
		return "floor"
	elif "stairs" in name_lower or "stair" in name_lower:
		return "stairs"
	
	# Fallback to geometry analysis
	if _is_corridor_shaped(size):
		return "corridor"
	elif _is_room_shaped(size):
		return "room"
	
	return "unknown"

## Calculate AABB for the asset with ±0.1 unit accuracy
## Recursively finds all MeshInstance3D nodes and combines their AABBs
func _calculate_bounding_box(node: Node3D) -> AABB:
	var mesh_aabbs: Array[AABB] = []
	
	_collect_mesh_aabbs(node, node.global_transform, mesh_aabbs)
	
	# If no meshes found, return zero-size AABB at origin
	if mesh_aabbs.is_empty():
		push_warning("AssetMapper: No mesh geometry found in asset")
		return AABB(Vector3.ZERO, Vector3.ZERO)
	
	# Combine all AABBs
	var combined_aabb = mesh_aabbs[0]
	for i in range(1, mesh_aabbs.size()):
		combined_aabb = combined_aabb.merge(mesh_aabbs[i])
	
	return combined_aabb

## Recursively collect AABBs from all MeshInstance3D nodes
func _collect_mesh_aabbs(node: Node, root_transform: Transform3D, mesh_aabbs: Array[AABB]) -> void:
	# Check if this node is a MeshInstance3D
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			# Get the mesh AABB in local space
			var mesh_aabb = mesh_instance.mesh.get_aabb()
			
			# Transform to world space relative to root
			var world_transform = root_transform.inverse() * mesh_instance.global_transform
			var transformed_aabb = world_transform * mesh_aabb
			
			mesh_aabbs.append(transformed_aabb)
	
	# Recursively process children
	for child in node.get_children():
		_collect_mesh_aabbs(child, root_transform, mesh_aabbs)

## Find where origin is relative to geometry center
func _find_origin_offset(node: Node3D) -> Vector3:
	var bbox = _calculate_bounding_box(node)
	if bbox.size == Vector3.ZERO:
		return Vector3.ZERO
	
	# Calculate center of bounding box
	var center = bbox.position + bbox.size / 2.0
	
	# Return offset from origin to center
	return center

## Measure floor height (Y coordinate where characters walk)
## Analyzes collision shapes to find the actual walkable surface
func _measure_floor_height(node: Node3D) -> float:
	# First, try to find floor collision shapes
	var collision_data = _extract_collision_geometry(node)
	
	if not collision_data.is_empty():
		# Find the lowest collision shape that could be a floor
		var lowest_floor = INF
		for shape in collision_data:
			# Floor shapes are typically box shapes near the bottom
			if shape.shape_type == "box":
				# Calculate the bottom surface of this collision box
				var bottom_surface = shape.position.y - (shape.size.y / 2.0)
				if bottom_surface < lowest_floor:
					lowest_floor = bottom_surface
		
		if lowest_floor != INF:
			return lowest_floor
	
	# Fallback: use bounding box
	var bbox = _calculate_bounding_box(node)
	if bbox.size == Vector3.ZERO:
		return 0.0
	
	# Floor height is the lowest point of the bounding box
	return bbox.position.y

## Calculate wall thickness for wall assets
## Analyzes collision geometry to determine wall depth
func _measure_wall_thickness(node: Node3D, asset_type: String) -> float:
	# Only measure wall thickness for wall-type assets
	if asset_type != "wall":
		return 0.0
	
	var collision_data = _extract_collision_geometry(node)
	if collision_data.is_empty():
		return 0.0
	
	# Find the thinnest dimension of collision boxes (likely the wall thickness)
	var min_thickness = INF
	for shape in collision_data:
		if shape.shape_type == "box":
			# Wall thickness is typically the smallest horizontal dimension
			var thickness = min(shape.size.x, shape.size.z)
			if thickness < min_thickness:
				min_thickness = thickness
	
	return min_thickness if min_thickness != INF else 0.0

## Measure doorway dimensions for room assets
## Returns Vector2(width, height) of the doorway opening
func _measure_doorway_dimensions(node: Node3D, connection_points: Array[ConnectionPoint]) -> Vector2:
	if connection_points.is_empty():
		return Vector2.ZERO
	
	# Use the first connection point's dimensions as representative doorway size
	# (All doors in a room typically have the same dimensions)
	var first_point = connection_points[0]
	return first_point.dimensions

## Identify connection points (doors, corridor ends)
## Uses heuristic approach: analyze bounding box edges for openings
func _find_connection_points(node: Node3D) -> Array[ConnectionPoint]:
	var points: Array[ConnectionPoint] = []
	
	var bbox = _calculate_bounding_box(node)
	if bbox.size == Vector3.ZERO:
		return points
	
	# Heuristic: For corridor-like assets (longer in one dimension),
	# create connection points at the ends
	var size = bbox.size
	var center = bbox.position + size / 2.0
	
	# Determine asset type by aspect ratio
	var is_corridor = _is_corridor_shaped(size)
	var is_room = _is_room_shaped(size)
	
	if is_corridor:
		# Corridor: 2 connection points at ends (along longest axis)
		var longest_axis = _get_longest_horizontal_axis(size)
		points = _create_corridor_connections(bbox, center, longest_axis)
	elif is_room:
		# Room: 4 connection points (one on each wall)
		points = _create_room_connections(bbox, center)
	
	return points

## Check if asset is corridor-shaped (one dimension much longer than others)
func _is_corridor_shaped(size: Vector3) -> bool:
	var xz_size = Vector2(size.x, size.z)
	var max_dim = max(xz_size.x, xz_size.y)
	var min_dim = min(xz_size.x, xz_size.y)
	
	# Corridor if one horizontal dimension is 2x+ the other
	return max_dim >= min_dim * 2.0

## Check if asset is room-shaped (roughly square in XZ plane)
func _is_room_shaped(size: Vector3) -> bool:
	var xz_size = Vector2(size.x, size.z)
	var max_dim = max(xz_size.x, xz_size.y)
	var min_dim = min(xz_size.x, xz_size.y)
	
	# Room if horizontal dimensions are similar (within 2x ratio)
	return max_dim < min_dim * 2.0 and min_dim > 3.0  # Minimum 3 units

## Get the longest horizontal axis (X or Z)
func _get_longest_horizontal_axis(size: Vector3) -> String:
	return "z" if size.z > size.x else "x"

## Create connection points for corridor assets
func _create_corridor_connections(bbox: AABB, center: Vector3, longest_axis: String) -> Array[ConnectionPoint]:
	var points: Array[ConnectionPoint] = []
	
	var opening_height = bbox.size.y * 0.8  # 80% of height
	var opening_width = min(bbox.size.x, bbox.size.z)  # Width is the shorter dimension
	
	if longest_axis == "z":
		# Corridor runs along Z axis
		# Connection at -Z end
		var point1 = ConnectionPoint.new()
		point1.position = Vector3(center.x, center.y, bbox.position.z)
		point1.normal = Vector3(0, 0, -1)  # Facing -Z
		point1.type = "corridor_end"
		point1.dimensions = Vector2(opening_width, opening_height)
		points.append(point1)
		
		# Connection at +Z end
		var point2 = ConnectionPoint.new()
		point2.position = Vector3(center.x, center.y, bbox.position.z + bbox.size.z)
		point2.normal = Vector3(0, 0, 1)  # Facing +Z
		point2.type = "corridor_end"
		point2.dimensions = Vector2(opening_width, opening_height)
		points.append(point2)
	else:
		# Corridor runs along X axis
		# Connection at -X end
		var point1 = ConnectionPoint.new()
		point1.position = Vector3(bbox.position.x, center.y, center.z)
		point1.normal = Vector3(-1, 0, 0)  # Facing -X
		point1.type = "corridor_end"
		point1.dimensions = Vector2(opening_width, opening_height)
		points.append(point1)
		
		# Connection at +X end
		var point2 = ConnectionPoint.new()
		point2.position = Vector3(bbox.position.x + bbox.size.x, center.y, center.z)
		point2.normal = Vector3(1, 0, 0)  # Facing +X
		point2.type = "corridor_end"
		point2.dimensions = Vector2(opening_width, opening_height)
		points.append(point2)
	
	return points

## Create connection points for room assets
func _create_room_connections(bbox: AABB, center: Vector3) -> Array[ConnectionPoint]:
	var points: Array[ConnectionPoint] = []
	
	var door_height = bbox.size.y * 0.6  # 60% of height for doors
	var door_width = 2.0  # Standard door width
	
	# North wall (+Z)
	var north = ConnectionPoint.new()
	north.position = Vector3(center.x, center.y, bbox.position.z + bbox.size.z)
	north.normal = Vector3(0, 0, 1)
	north.type = "door"
	north.dimensions = Vector2(door_width, door_height)
	points.append(north)
	
	# South wall (-Z)
	var south = ConnectionPoint.new()
	south.position = Vector3(center.x, center.y, bbox.position.z)
	south.normal = Vector3(0, 0, -1)
	south.type = "door"
	south.dimensions = Vector2(door_width, door_height)
	points.append(south)
	
	# East wall (+X)
	var east = ConnectionPoint.new()
	east.position = Vector3(bbox.position.x + bbox.size.x, center.y, center.z)
	east.normal = Vector3(1, 0, 0)
	east.type = "door"
	east.dimensions = Vector2(door_width, door_height)
	points.append(east)
	
	# West wall (-X)
	var west = ConnectionPoint.new()
	west.position = Vector3(bbox.position.x, center.y, center.z)
	west.normal = Vector3(-1, 0, 0)
	west.type = "door"
	west.dimensions = Vector2(door_width, door_height)
	points.append(west)
	
	return points

## Extract collision shape data from all CollisionShape3D nodes
func _extract_collision_geometry(node: Node3D) -> Array[CollisionData]:
	var collision_data: Array[CollisionData] = []
	
	_collect_collision_shapes(node, collision_data)
	
	return collision_data

## Recursively collect collision shapes
func _collect_collision_shapes(node: Node, collision_data: Array[CollisionData]) -> void:
	if node is CollisionShape3D:
		var collision_shape = node as CollisionShape3D
		if collision_shape.shape != null:
			var data = CollisionData.new()
			data.position = collision_shape.global_position
			
			# Extract shape-specific data
			if collision_shape.shape is BoxShape3D:
				var box = collision_shape.shape as BoxShape3D
				data.shape_type = "box"
				data.size = box.size
			elif collision_shape.shape is SphereShape3D:
				var sphere = collision_shape.shape as SphereShape3D
				data.shape_type = "sphere"
				data.radius = sphere.radius
			elif collision_shape.shape is CapsuleShape3D:
				var capsule = collision_shape.shape as CapsuleShape3D
				data.shape_type = "capsule"
				data.radius = capsule.radius
				data.height = capsule.height
			else:
				data.shape_type = "unknown"
			
			collision_data.append(data)
	
	# Recursively process children
	for child in node.get_children():
		_collect_collision_shapes(child, collision_data)

## Determine default facing direction
## TODO: Implement geometry orientation analysis
func _determine_default_rotation(node: Node3D) -> Vector3:
	# Placeholder: assume default is facing forward (no rotation)
	return Vector3.ZERO

## Calculate walkable area boundaries
func _calculate_walkable_area(node: Node3D, collision_shapes: Array[CollisionData]) -> AABB:
	# Placeholder implementation
	# In a full implementation, this would analyze floor collision shapes
	# and subtract wall collision areas
	
	var bbox = _calculate_bounding_box(node)
	if bbox.size == Vector3.ZERO:
		return AABB()
	
	# For now, assume walkable area is slightly smaller than bounding box
	# and at floor height
	var walkable_size = Vector3(
		bbox.size.x * 0.8,
		0.1,
		bbox.size.z * 0.8
	)
	var walkable_pos = Vector3(
		bbox.position.x + (bbox.size.x - walkable_size.x) / 2.0,
		bbox.position.y,
		bbox.position.z + (bbox.size.z - walkable_size.z) / 2.0
	)
	
	return AABB(walkable_pos, walkable_size)
