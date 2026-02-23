## Health bar UI component
## Displays health above a character
extends Control

@export var health_component: NodePath
@export var offset_y: float = 2.5

var _stats_component: StatsComponent
var _camera: Camera3D
var _owner_node: Node3D

func _ready() -> void:
	print("HealthBar: _ready() called")
	
	# Find StatsComponent (NEW system)
	_stats_component = _find_stats_component()
	
	if not _stats_component:
		push_error("HealthBar: No StatsComponent found!")
		return
	
	print("HealthBar: Found StatsComponent, connecting to health_changed signal")
	print("HealthBar: Initial health: ", _stats_component.current_health, "/", _stats_component.stats.max_health if _stats_component.stats else 0.0)
	
	# Connect to health signals
	_stats_component.health_changed.connect(_on_health_changed)
	
	# Find owner node for positioning
	_owner_node = _find_node3d(_stats_component.get_parent())
	
	# Update initial health
	if _stats_component.stats:
		_on_health_changed(_stats_component.current_health, _stats_component.stats.max_health)

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

func _on_health_changed(current: float, maximum: float) -> void:
	print("HealthBar: _on_health_changed - current: ", current, " max: ", maximum)
	
	# Update progress bar
	var progress_bar := $ProgressBar as ProgressBar
	if progress_bar:
		progress_bar.max_value = maximum
		progress_bar.value = current

func _find_stats_component() -> StatsComponent:
	# First check if health_component path is set (legacy)
	if health_component:
		var node := get_node_or_null(health_component)
		if node:
			print("HealthBar: health_component path points to: ", node.get_class())
	
	# Search parent hierarchy for StatsComponent
	var parent := get_parent()
	while parent:
		for child in parent.get_children():
			if child is StatsComponent:
				print("HealthBar: Found StatsComponent in ", parent.name)
				return child
		parent = parent.get_parent()
	
	print("HealthBar: No StatsComponent found in hierarchy")
	return null

func _find_node3d(node: Node) -> Node3D:
	if node is Node3D:
		return node
	if node.get_parent():
		return _find_node3d(node.get_parent())
	return null
