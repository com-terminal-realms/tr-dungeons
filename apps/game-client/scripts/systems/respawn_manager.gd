extends Node
class_name RespawnManager

## Manages player death and respawn
## Handles checkpoint tracking, resource restoration, and enemy reset

signal player_died
signal player_respawned

var last_checkpoint: Vector3 = Vector3.ZERO
var death_screen: DeathScreen
var player: Node3D

var combat_stats: Dictionary = {
	"damage_dealt": 0.0,
	"damage_taken": 0.0,
	"enemies_killed": 0
}

func _ready() -> void:
	# Find death screen
	death_screen = _find_death_screen()
	if death_screen:
		death_screen.respawn_requested.connect(_on_respawn_requested)

## Set checkpoint position
func set_checkpoint(position: Vector3) -> void:
	last_checkpoint = position

## Handle player death
func on_player_died(player_node: Node3D) -> void:
	player = player_node
	player_died.emit()
	
	# Show death screen
	if death_screen:
		death_screen.show_death_screen(combat_stats)
	
	# Disable player input
	if player:
		player.set_physics_process(false)

## Handle respawn request
func _on_respawn_requested() -> void:
	if not player:
		return
	
	# Respawn player at checkpoint
	player.global_position = last_checkpoint
	
	# Restore health and mana
	var combat_component := _find_combat_component(player)
	if combat_component and combat_component.stats_component:
		combat_component.stats_component.restore_full()
	
	# Reset state machine
	if combat_component and combat_component.state_machine:
		combat_component.state_machine.transition_to(StateMachine.State.IDLE)
	
	# Reset enemies in current room
	_reset_enemies()
	
	# Re-enable player input
	player.set_physics_process(true)
	
	# Reset combat stats
	combat_stats = {
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"enemies_killed": 0
	}
	
	player_respawned.emit()

## Reset all enemies in current room
func _reset_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is Node3D:
			# Reset enemy health
			var combat_component := _find_combat_component(enemy)
			if combat_component and combat_component.stats_component:
				combat_component.stats_component.restore_full()
			
			# Reset enemy state
			if combat_component and combat_component.state_machine:
				combat_component.state_machine.transition_to(StateMachine.State.IDLE)
			
			# Reset enemy AI
			var enemy_ai := _find_enemy_ai(enemy)
			if enemy_ai:
				enemy_ai.target = null

## Track damage dealt
func add_damage_dealt(amount: float) -> void:
	combat_stats.damage_dealt += amount

## Track damage taken
func add_damage_taken(amount: float) -> void:
	combat_stats.damage_taken += amount

## Track enemy killed
func add_enemy_killed() -> void:
	combat_stats.enemies_killed += 1

## Find death screen in scene
func _find_death_screen() -> DeathScreen:
	var ui_nodes := get_tree().get_nodes_in_group("ui")
	for node in ui_nodes:
		if node is DeathScreen:
			return node
	return null

## Find CombatComponent in node
func _find_combat_component(node: Node) -> CombatComponent:
	for child in node.get_children():
		if child is CombatComponent:
			return child
	return null

## Find EnemyAI in node
func _find_enemy_ai(node: Node) -> EnemyAI:
	for child in node.get_children():
		if child is EnemyAI:
			return child
	return null
