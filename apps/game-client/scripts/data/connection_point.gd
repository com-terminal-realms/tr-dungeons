class_name DoorConnectionPoint
extends RefCounted

## Represents a location where a door should be placed
## Used by DoorManager to track connection points between rooms and corridors

var position: Vector3 = Vector3.ZERO
var door_rotation: Vector3 = Vector3.ZERO
var room_a: Node3D = null
var room_b: Node3D = null
var wall_normal: Vector3 = Vector3.ZERO
