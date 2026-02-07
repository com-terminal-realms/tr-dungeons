## Isometric Camera
## Maintains 45° overhead view with smooth following and zoom
class_name IsometricCamera
extends Camera3D

@export var target: Node3D = null
@export var distance: float = 15.0
@export var zoom_min: float = 8.0
@export var zoom_max: float = 25.0
@export var zoom_speed: float = 2.0
@export var follow_speed: float = 5.0

const ISOMETRIC_ANGLE_DEG: float = 45.0
const ISOMETRIC_ROTATION_DEG: float = 45.0

func _ready() -> void:
	if target:
		update_camera_position()

func _process(delta: float) -> void:
	# Handle zoom input
	if Input.is_action_pressed("zoom_in"):
		distance = max(zoom_min, distance - zoom_speed * delta * 10.0)
	if Input.is_action_pressed("zoom_out"):
		distance = min(zoom_max, distance + zoom_speed * delta * 10.0)
	
	# Update camera position
	if target:
		var target_position := calculate_camera_position(target.global_position)
		global_position = global_position.lerp(target_position, follow_speed * delta)
		
		# Always look at target
		look_at(target.global_position, Vector3.UP)

## Calculate camera position for isometric view
## target_pos: The position to center the camera on
## Returns: The calculated camera position
func calculate_camera_position(target_pos: Vector3) -> Vector3:
	# Isometric angle: 45° from horizontal
	var angle_rad := deg_to_rad(ISOMETRIC_ANGLE_DEG)
	
	# Rotation around Y axis: 45° for isometric view
	var rotation_rad := deg_to_rad(ISOMETRIC_ROTATION_DEG)
	
	# Calculate offset from target
	# Using 45° angle creates the isometric look
	var horizontal_distance := distance * cos(angle_rad)
	var vertical_distance := distance * sin(angle_rad)
	
	# Apply rotation around Y axis
	var offset := Vector3(
		horizontal_distance * cos(rotation_rad),
		vertical_distance,
		horizontal_distance * sin(rotation_rad)
	)
	
	return target_pos + offset

## Set camera position immediately (no lerp)
func update_camera_position() -> void:
	if target:
		global_position = calculate_camera_position(target.global_position)
		look_at(target.global_position, Vector3.UP)

## Get current camera angle from horizontal (should be ~45°)
func get_camera_angle() -> float:
	if not target:
		return 0.0
	
	var to_target := target.global_position - global_position
	var horizontal_distance := Vector2(to_target.x, to_target.z).length()
	var vertical_distance := to_target.y
	
	return rad_to_deg(atan2(abs(vertical_distance), horizontal_distance))

## Get current camera rotation around Y axis (should be ~45°)
func get_camera_rotation_y() -> float:
	if not target:
		return 0.0
	
	var to_target := target.global_position - global_position
	return rad_to_deg(atan2(to_target.x, to_target.z))

## Get current distance to target
func get_distance_to_target() -> float:
	if not target:
		return 0.0
	return global_position.distance_to(target.global_position)
