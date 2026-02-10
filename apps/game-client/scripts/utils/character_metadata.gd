class_name CharacterMetadata
extends Resource

## Stores all measurements and properties for a character/creature
## Used for proper floor positioning and collision detection

@export var character_name: String = ""
@export var scene_path: String = ""
@export var character_type: String = ""  # "player", "enemy", "boss", "npc"
@export var measurement_timestamp: int = 0

# Dimensions
@export var bounding_box: AABB = AABB()
@export var floor_offset: float = 0.0  # Distance from origin to feet (positive = feet below origin)
@export var character_height: float = 0.0  # Total height from feet to top

# Collision
@export var collision_radius: float = 0.5  # For cylindrical collision
@export var collision_height: float = 2.0

# Metadata
@export var measurement_accuracy: float = 0.01

func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"scene_path": scene_path,
		"character_type": character_type,
		"measurement_timestamp": measurement_timestamp,
		"bounding_box": {
			"position": {"x": bounding_box.position.x, "y": bounding_box.position.y, "z": bounding_box.position.z},
			"size": {"x": bounding_box.size.x, "y": bounding_box.size.y, "z": bounding_box.size.z}
		},
		"floor_offset": floor_offset,
		"character_height": character_height,
		"collision_radius": collision_radius,
		"collision_height": collision_height,
		"measurement_accuracy": measurement_accuracy
	}

func from_dict(data: Dictionary) -> void:
	character_name = data.get("character_name", "")
	scene_path = data.get("scene_path", "")
	character_type = data.get("character_type", "")
	measurement_timestamp = data.get("measurement_timestamp", 0)
	
	var bbox = data.get("bounding_box", {})
	var bbox_pos = bbox.get("position", {"x": 0, "y": 0, "z": 0})
	var bbox_size = bbox.get("size", {"x": 0, "y": 0, "z": 0})
	bounding_box = AABB(
		Vector3(bbox_pos.x, bbox_pos.y, bbox_pos.z),
		Vector3(bbox_size.x, bbox_size.y, bbox_size.z)
	)
	
	floor_offset = data.get("floor_offset", 0.0)
	character_height = data.get("character_height", 0.0)
	collision_radius = data.get("collision_radius", 0.5)
	collision_height = data.get("collision_height", 2.0)
	measurement_accuracy = data.get("measurement_accuracy", 0.01)
