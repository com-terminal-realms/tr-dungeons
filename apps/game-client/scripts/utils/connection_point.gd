class_name ConnectionPoint
extends Resource

## Represents a point where assets connect (doors, corridor ends, openings)

@export var position: Vector3 = Vector3.ZERO  # Local space coordinates
@export var normal: Vector3 = Vector3.ZERO    # Direction facing outward
@export var type: String = ""                 # "door", "corridor_end", "opening"
@export var dimensions: Vector2 = Vector2.ZERO # Width x Height

func transform_by_rotation(rotation: Vector3) -> ConnectionPoint:
	"""Return new ConnectionPoint with rotated position and normal"""
	var new_point = ConnectionPoint.new()
	new_point.type = type
	new_point.dimensions = dimensions
	
	# Convert rotation from degrees to radians
	var rotation_radians = Vector3(
		deg_to_rad(rotation.x),
		deg_to_rad(rotation.y),
		deg_to_rad(rotation.z)
	)
	
	# Create rotation basis from Euler angles (in radians)
	var basis = Basis.from_euler(rotation_radians)
	
	# Transform position and normal
	new_point.position = basis * position
	new_point.normal = basis * normal
	
	return new_point

func to_dict() -> Dictionary:
	return {
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"normal": {"x": normal.x, "y": normal.y, "z": normal.z},
		"type": type,
		"dimensions": {"x": dimensions.x, "y": dimensions.y}
	}

func from_dict(data: Dictionary) -> void:
	var pos = data.get("position", {"x": 0, "y": 0, "z": 0})
	position = Vector3(pos.x, pos.y, pos.z)
	
	var norm = data.get("normal", {"x": 0, "y": 0, "z": 0})
	normal = Vector3(norm.x, norm.y, norm.z)
	
	type = data.get("type", "")
	
	var dims = data.get("dimensions", {"x": 0, "y": 0})
	dimensions = Vector2(dims.x, dims.y)
