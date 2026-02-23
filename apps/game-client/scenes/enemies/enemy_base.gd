## Enemy base script
## Handles enemy death and removal from scene
extends CharacterBody3D

@export var is_boss: bool = false  # Mark this enemy as a boss

var _health: Health
var _combat_component: CombatComponent

func _ready() -> void:
	# Get component references
	_health = $Health
	_combat_component = $CombatComponent
	
	# Connect to death signal for removal
	# CRITICAL: Use NEW StatsComponent.died signal, not OLD Health.died
	# The OLD Health component can desync from the health bar (which shows NEW StatsComponent)
	if _combat_component and _combat_component.stats_component:
		_combat_component.stats_component.died.connect(_on_death)
		print("Enemy: Connected to NEW StatsComponent.died signal")
	elif _health:
		# Fallback to OLD system if NEW system not available
		_health.died.connect(_on_death)
		print("Enemy: WARNING - Using OLD Health.died signal (fallback)")
	
	# If this is a boss, add to boss group for easy identification
	if is_boss:
		add_to_group("boss")
		print("Enemy: This is a BOSS enemy")
	else:
		print("Enemy: This is a regular enemy")

## Handle death and remove from scene
func _on_death() -> void:
	print("Enemy: Died! Removing from scene...")
	
	# If this was a boss, stop boss music and resume background music
	if is_boss:
		print("Boss: Died! Stopping boss music...")
		var main_scene := get_tree().root.get_node_or_null("Main")
		if main_scene and main_scene.has_method("stop_boss_music"):
			main_scene.stop_boss_music()
	
	queue_free()
