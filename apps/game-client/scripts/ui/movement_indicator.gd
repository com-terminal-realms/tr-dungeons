## Movement Indicator
## Visual indicator showing where player will move when RMB clicking
extends Node3D

@export var fade_duration: float = 2.0
@export var initial_alpha: float = 0.5

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _tween: Tween
var _elapsed_time: float = 0.0

func _ready() -> void:
	# Get mesh instance
	_mesh_instance = $MeshInstance3D
	if not _mesh_instance:
		push_error("MovementIndicator: MeshInstance3D not found!")
		return
	
	# Get material
	_material = _mesh_instance.get_active_material(0) as StandardMaterial3D
	if not _material:
		push_error("MovementIndicator: Material not found!")
		return
	
	# Set initial alpha
	var color := _material.albedo_color
	color.a = initial_alpha
	_material.albedo_color = color
	
	# Start fade animation
	start_fade()

func start_fade() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(_material, "albedo_color:a", 0.0, fade_duration)
	_tween.tween_callback(_on_fade_complete)

func _on_fade_complete() -> void:
	queue_free()

## Called by player when destination is reached
func remove_immediately() -> void:
	if _tween:
		_tween.kill()
	queue_free()
