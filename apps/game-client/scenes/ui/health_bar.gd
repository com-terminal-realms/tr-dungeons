## Health bar UI component
## Displays health above a character
extends Control

@export var health_component: NodePath
@export var offset_y: float = 2.5

var _health: Node
var _camera: Camera3D
var _owner_node: Node3D

func _ready() -> void:
	# Find health component
	if health_component:
		_health = get_node(health_component)
	else:
		_health = _find_health_in_parent()
	
	if not _health:
		push_error("HealthBar: No health component found")
		return
	
	# Connect to health signals
	_health.health_changed.connect(_on_health_changed)
	
	# Find owner node for positioning
	_owner_node = _find_node3d(_health.get_parent())
	
	# Update initial health
	_on_health_changed(_health.get_current_health(), _health.get_max_health())

func _process(_delta: float) -> void:
	if not _owner_node:
		return
	
	# Get camera
	if not _camera:
		_camera = get_viewport().get_camera_3d()
		if not _camera:
			return
	
	# Position above character in screen space
	var world_pos := _owner_node.global_position + Vector3(0, offset_y, 0)
	var screen_pos := _camera.unproject_position(world_pos)
	
	# Center the health bar
	position = screen_pos - size / 2.0

func _on_health_changed(current: int, maximum: int) -> void:
	# Update progress bar
	var progress_bar := $ProgressBar as ProgressBar
	if progress_bar:
		progress_bar.max_value = maximum
		progress_bar.value = current

func _find_health_in_parent() -> Node:
	var parent := get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if child.get_class() == "Node" and child.name == "Health":
			return child
	return null

func _find_node3d(node: Node) -> Node3D:
	if node is Node3D:
		return node
	if node.get_parent():
		return _find_node3d(node.get_parent())
	return null
