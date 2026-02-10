class_name AssetMetadata
extends Resource

## Stores all measurements and properties for a single dungeon asset
## Asset-agnostic: works with any GLB/FBX format from any source

@export var asset_name: String = ""
@export var asset_path: String = ""
@export var asset_format: String = ""  # "GLB", "FBX", etc.
@export var asset_source: String = ""  # "Kenney", "Synty", "Custom", etc.
@export var measurement_timestamp: int = 0

# Dimensions
@export var bounding_box: AABB = AABB()
@export var origin_offset: Vector3 = Vector3.ZERO
@export var floor_height: float = 0.0
@export var wall_thickness: float = 0.0

# Connections
var connection_points: Array = []  # Array of ConnectionPoint objects
@export var doorway_dimensions: Vector2 = Vector2.ZERO

# Collision
var collision_shapes: Array = []  # Array of CollisionData objects
@export var walkable_area: AABB = AABB()

# Rotation
@export var default_rotation: Vector3 = Vector3.ZERO
@export var rotation_pivot: Vector3 = Vector3.ZERO

# Metadata
@export var measurement_accuracy: float = 0.1

func to_dict() -> Dictionary:
	var data = {
		"asset_name": asset_name,
		"asset_path": asset_path,
		"asset_format": asset_format,
		"asset_source": asset_source,
		"measurement_timestamp": measurement_timestamp,
		"bounding_box": {
			"position": {"x": bounding_box.position.x, "y": bounding_box.position.y, "z": bounding_box.position.z},
			"size": {"x": bounding_box.size.x, "y": bounding_box.size.y, "z": bounding_box.size.z}
		},
		"origin_offset": {"x": origin_offset.x, "y": origin_offset.y, "z": origin_offset.z},
		"floor_height": floor_height,
		"wall_thickness": wall_thickness,
		"doorway_dimensions": {"x": doorway_dimensions.x, "y": doorway_dimensions.y},
		"walkable_area": {
			"position": {"x": walkable_area.position.x, "y": walkable_area.position.y, "z": walkable_area.position.z},
			"size": {"x": walkable_area.size.x, "y": walkable_area.size.y, "z": walkable_area.size.z}
		},
		"default_rotation": {"x": default_rotation.x, "y": default_rotation.y, "z": default_rotation.z},
		"rotation_pivot": {"x": rotation_pivot.x, "y": rotation_pivot.y, "z": rotation_pivot.z},
		"measurement_accuracy": measurement_accuracy,
		"connection_points": [],
		"collision_shapes": []
	}
	
	for point in connection_points:
		data["connection_points"].append(point.to_dict())
	
	for shape in collision_shapes:
		data["collision_shapes"].append(shape.to_dict())
	
	return data

func from_dict(data: Dictionary) -> void:
	asset_name = data.get("asset_name", "")
	asset_path = data.get("asset_path", "")
	asset_format = data.get("asset_format", "")
	asset_source = data.get("asset_source", "")
	measurement_timestamp = data.get("measurement_timestamp", 0)
	
	var bbox = data.get("bounding_box", {})
	var bbox_pos = bbox.get("position", {"x": 0, "y": 0, "z": 0})
	var bbox_size = bbox.get("size", {"x": 0, "y": 0, "z": 0})
	bounding_box = AABB(
		Vector3(bbox_pos.x, bbox_pos.y, bbox_pos.z),
		Vector3(bbox_size.x, bbox_size.y, bbox_size.z)
	)
	
	var origin = data.get("origin_offset", {"x": 0, "y": 0, "z": 0})
	origin_offset = Vector3(origin.x, origin.y, origin.z)
	
	floor_height = data.get("floor_height", 0.0)
	wall_thickness = data.get("wall_thickness", 0.0)
	
	var doorway = data.get("doorway_dimensions", {"x": 0, "y": 0})
	doorway_dimensions = Vector2(doorway.x, doorway.y)
	
	var walkable = data.get("walkable_area", {})
	var walkable_pos = walkable.get("position", {"x": 0, "y": 0, "z": 0})
	var walkable_size = walkable.get("size", {"x": 0, "y": 0, "z": 0})
	walkable_area = AABB(
		Vector3(walkable_pos.x, walkable_pos.y, walkable_pos.z),
		Vector3(walkable_size.x, walkable_size.y, walkable_size.z)
	)
	
	var def_rot = data.get("default_rotation", {"x": 0, "y": 0, "z": 0})
	default_rotation = Vector3(def_rot.x, def_rot.y, def_rot.z)
	
	var rot_piv = data.get("rotation_pivot", {"x": 0, "y": 0, "z": 0})
	rotation_pivot = Vector3(rot_piv.x, rot_piv.y, rot_piv.z)
	
	measurement_accuracy = data.get("measurement_accuracy", 0.1)
	
	connection_points.clear()
	for point_data in data.get("connection_points", []):
		var point = ConnectionPoint.new()
		point.from_dict(point_data)
		connection_points.append(point)
	
	collision_shapes.clear()
	for shape_data in data.get("collision_shapes", []):
		var shape = CollisionData.new()
		shape.from_dict(shape_data)
		collision_shapes.append(shape)
