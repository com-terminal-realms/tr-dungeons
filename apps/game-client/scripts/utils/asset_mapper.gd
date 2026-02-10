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
	metadata.floor_height = _measure_floor_height(scene)
	metadata.connection_points = _find_connection_points(scene)
	metadata.collision_shapes = _extract_collision_geometry(scene)
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
func _measure_floor_height(node: Node3D) -> float:
	var bbox = _calculate_bounding_box(node)
	if bbox.size == Vector3.ZERO:
		return 0.0
	
	# Floor height is the lowest point of the bounding box
	return bbox.position.y

## Identify connection points (doors, corridor ends)
## TODO: Implement geometry analysis to find openings
func _find_connection_points(node: Node3D) -> Array[ConnectionPoint]:
	var points: Array[ConnectionPoint] = []
	
	# Placeholder implementation
	# In a full implementation, this would analyze mesh boundaries
	# to find openings, doorways, and corridor ends
	
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
