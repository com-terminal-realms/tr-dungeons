extends CharacterBody3D

## Combat-enabled enemy character
## Controlled by EnemyAI component

@export var gravity: float = 9.8

@onready var combat_component: CombatComponent = $CombatComponent
@onready var stats_component: StatsComponent = $StatsComponent
@onready var enemy_ai: EnemyAI = $EnemyAI

func _ready() -> void:
	# Connect death signal
	if stats_component:
		stats_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	# AI handles movement via velocity
	# Just apply it here
	move_and_slide()

func _on_died() -> void:
	# Notify respawn manager
	var respawn_manager := get_tree().get_first_node_in_group("respawn_manager")
	if respawn_manager and respawn_manager.has_method("add_enemy_killed"):
		respawn_manager.add_enemy_killed()
