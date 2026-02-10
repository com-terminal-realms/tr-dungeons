class_name PlacedAsset
extends RefCounted

## Represents an asset placed in a dungeon layout with position and rotation

var metadata: AssetMetadata
var position: Vector3
var rotation: Vector3  # Euler angles (degrees)

func _init(p_metadata: AssetMetadata = null, p_position: Vector3 = Vector3.ZERO, p_rotation: Vector3 = Vector3.ZERO):
	metadata = p_metadata
	position = p_position
	rotation = p_rotation
