## Enemy base script
## Handles enemy death and removal from scene
extends CharacterBody3D

var _health: Health

func _ready() -> void:
	# Get component references
	_health = $Health
	
	# Connect to death signal for removal
	if _health:
		_health.died.connect(_on_death)

## Handle death and remove from scene
func _on_death() -> void:
	# Remove enemy from scene
	queue_free()
