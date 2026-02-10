class_name CollisionData
extends Resource

## Stores collision shape information for an asset

@export var shape_type: String = ""  # "box", "sphere", "capsule", "mesh"
@export var position: Vector3 = Vector3.ZERO
@export var size: Vector3 = Vector3.ZERO  # For box shapes
@export var radius: float = 0.0  # For sphere/capsule shapes
@export var height: float = 0.0  # For capsule shapes

func to_dict() -> Dictionary:
	return {
		"shape_type": shape_type,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"size": {"x": size.x, "y": size.y, "z": size.z},
		"radius": radius,
		"height": height
	}

func from_dict(data: Dictionary) -> void:
	shape_type = data.get("shape_type", "")
	
	var pos = data.get("position", {"x": 0, "y": 0, "z": 0})
	position = Vector3(pos.x, pos.y, pos.z)
	
	var sz = data.get("size", {"x": 0, "y": 0, "z": 0})
	size = Vector3(sz.x, sz.y, sz.z)
	
	radius = data.get("radius", 0.0)
	height = data.get("height", 0.0)
