extends ProgressBar
class_name HealthBar

## Health bar UI component
## Can be used for both player (screen space) and enemies (world space)

@export var stats_component: StatsComponent

func _ready() -> void:
	# Auto-find stats component if not set
	if not stats_component:
		stats_component = _find_stats_component()
	
	# Connect to health changed signal
	if stats_component:
		stats_component.health_changed.connect(_on_health_changed)
		_on_health_changed(stats_component.current_health, stats_component.stats.max_health if stats_component.stats else 100.0)

## Update health bar display
func _on_health_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
	
	# Update color based on health percentage
	var health_percent := current / maximum
	if health_percent > 0.5:
		modulate = Color(0.0, 1.0, 0.0)  # Green
	elif health_percent > 0.25:
		modulate = Color(1.0, 1.0, 0.0)  # Yellow
	else:
		modulate = Color(1.0, 0.0, 0.0)  # Red

## Find StatsComponent in parent hierarchy
func _find_stats_component() -> StatsComponent:
	var node := get_parent()
	while node:
		for child in node.get_children():
			if child is StatsComponent:
				return child
		node = node.get_parent()
	return null
