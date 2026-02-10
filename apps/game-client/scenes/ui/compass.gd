## Compass UI
## Shows orientation relative to world north
## Updates based on camera rotation
extends Control

@onready var compass_rose: Control = $CompassRose
@onready var needle: ColorRect = $CompassRose/Needle
@onready var label: Label = $Label

var camera: Camera3D = null

func _ready() -> void:
	# Find the camera in the scene
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	
	if not camera:
		push_warning("Compass: No camera found in scene")

func _process(_delta: float) -> void:
	if not camera or not camera.has_method("get_camera_rotation_y"):
		return
	
	# Get camera rotation (0° = North, 90° = East, 180° = South, 270° = West)
	var camera_angle: float = camera.get_camera_rotation_y()
	
	# Rotate the compass rose to show orientation
	# Negative because we want the compass to rotate opposite to camera
	compass_rose.rotation = deg_to_rad(-camera_angle)
	
	# Update label with cardinal direction and angle
	var direction := get_cardinal_direction(camera_angle)
	label.text = "%s %d°" % [direction, int(camera_angle)]

## Get cardinal direction from angle
func get_cardinal_direction(angle: float) -> String:
	# Normalize angle to 0-360
	while angle < 0:
		angle += 360
	while angle >= 360:
		angle -= 360
	
	# Determine cardinal direction (with 45° tolerance)
	if angle < 22.5 or angle >= 337.5:
		return "N"
	elif angle < 67.5:
		return "NE"
	elif angle < 112.5:
		return "E"
	elif angle < 157.5:
		return "SE"
	elif angle < 202.5:
		return "S"
	elif angle < 247.5:
		return "SW"
	elif angle < 292.5:
		return "W"
	else:
		return "NW"
