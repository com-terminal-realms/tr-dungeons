extends Node
class_name EnemyAI

## Enemy AI component for combat system
## Manages enemy behavior: detection, patrol, chase, attack, and return to spawn

signal state_changed(old_state: AIState, new_state: AIState)
signal target_detected(target: Node3D)
signal target_lost()

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN
}

@export var detection_radius: float = 10.0
@export var attack_range: float = 2.0
@export var patrol_radius: float = 5.0
@export var return_distance: float = 15.0  # Distance from spawn before returning
@export var path_update_rate: float = 5.0  # Hz

@export var combat_component: CombatComponent
@export var state_machine: StateMachine
@export var navigation_agent: NavigationAgent3D

var current_ai_state: AIState = AIState.IDLE
var target: Node3D = null
var spawn_position: Vector3
var patrol_target: Vector3

var _path_update_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _owner_node: Node3D

func _ready() -> void:
	# Find owner node
	_owner_node = _find_node3d(get_parent())
	if not _owner_node:
		push_error("EnemyAI requires Node3D parent or ancestor")
		return
	
	# Store spawn position
	spawn_position = _owner_node.global_position
	patrol_target = spawn_position
	
	# Auto-find components if not set
	if not combat_component:
		combat_component = _find_component(CombatComponent)
	if not state_machine:
		state_machine = _find_component(StateMachine)
	if not navigation_agent:
		navigation_agent = _find_component(NavigationAgent3D)
	
	# Validate required components
	if not combat_component:
		push_error("EnemyAI requires CombatComponent")
	if not state_machine:
		push_error("EnemyAI requires StateMachine")
	if not navigation_agent:
		push_error("EnemyAI requires NavigationAgent3D")

func _physics_process(delta: float) -> void:
	if not _owner_node or not combat_component or not state_machine:
		return
	
	# Don't process AI if dead
	if state_machine.is_dead():
		return
	
	# Update attack cooldown
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	
	# Update path at specified rate
	_path_update_timer += delta
	var update_interval := 1.0 / path_update_rate
	if _path_update_timer >= update_interval:
		_path_update_timer = 0.0
		_update_ai_state()
		_update_navigation()
	
	# Execute current state behavior
	_execute_state(delta)

## Update AI state based on player detection and distance
func _update_ai_state() -> void:
	var player := _find_player()
	
	# Check if we're too far from spawn
	var distance_from_spawn := _owner_node.global_position.distance_to(spawn_position)
	if distance_from_spawn > return_distance and current_ai_state != AIState.RETURN:
		_transition_to(AIState.RETURN)
		target = null
		target_lost.emit()
		return
	
	# If returning and close to spawn, go back to idle
	if current_ai_state == AIState.RETURN and distance_from_spawn < 1.0:
		_transition_to(AIState.IDLE)
		return
	
	# If no player found, idle or patrol
	if not player:
		if current_ai_state in [AIState.CHASE, AIState.ATTACK]:
			target = null
			target_lost.emit()
		_transition_to(AIState.IDLE)
		return
	
	# Check detection range
	var distance_to_player := _owner_node.global_position.distance_to(player.global_position)
	
	# Player detected within range
	if distance_to_player <= detection_radius:
		# First detection
		if target == null:
			target = player
			target_detected.emit(player)
		
		# Check if in attack range
		if distance_to_player <= attack_range:
			_transition_to(AIState.ATTACK)
		else:
			_transition_to(AIState.CHASE)
	
	# Player out of range (with hysteresis)
	elif distance_to_player > detection_radius * 1.5:
		if current_ai_state in [AIState.CHASE, AIState.ATTACK]:
			target = null
			target_lost.emit()
			_transition_to(AIState.IDLE)

## Update navigation path based on current state
func _update_navigation() -> void:
	if not navigation_agent:
		return
	
	match current_ai_state:
		AIState.CHASE:
			if target:
				navigation_agent.target_position = target.global_position
		AIState.RETURN:
			navigation_agent.target_position = spawn_position
		AIState.PATROL:
			navigation_agent.target_position = patrol_target

## Execute behavior for current AI state
func _execute_state(delta: float) -> void:
	match current_ai_state:
		AIState.IDLE:
			_execute_idle(delta)
		AIState.PATROL:
			_execute_patrol(delta)
		AIState.CHASE:
			_execute_chase(delta)
		AIState.ATTACK:
			_execute_attack(delta)
		AIState.RETURN:
			_execute_return(delta)

## Idle state: stand still, occasionally patrol
func _execute_idle(_delta: float) -> void:
	# Randomly decide to patrol
	if randf() < 0.01:  # 1% chance per frame
		_generate_patrol_target()
		_transition_to(AIState.PATROL)

## Patrol state: move to patrol target
func _execute_patrol(_delta: float) -> void:
	if not navigation_agent:
		return
	
	# Check if reached patrol target
	if navigation_agent.is_navigation_finished():
		_transition_to(AIState.IDLE)
		return
	
	# Move toward patrol target
	_move_along_path()

## Chase state: pursue target
func _execute_chase(_delta: float) -> void:
	if not navigation_agent or not target:
		return
	
	# Face target
	_face_target(target)
	
	# Move toward target
	_move_along_path()

## Attack state: attack target
func _execute_attack(_delta: float) -> void:
	if not target or not combat_component:
		return
	
	# Face target
	_face_target(target)
	
	# Attack on cooldown (1.5 seconds)
	if _attack_cooldown <= 0.0:
		combat_component.attack()
		_attack_cooldown = 1.5

## Return state: return to spawn position
func _execute_return(_delta: float) -> void:
	if not navigation_agent:
		return
	
	# Move toward spawn
	_move_along_path()

## Move along navigation path
func _move_along_path() -> void:
	if not navigation_agent or navigation_agent.is_navigation_finished():
		return
	
	var next_position := navigation_agent.get_next_path_position()
	var direction := (_owner_node.global_position.direction_to(next_position))
	
	# Apply movement to parent CharacterBody3D
	var parent := get_parent()
	if parent is CharacterBody3D:
		var stats := combat_component.get_stats_component()
		var move_speed := stats.stats.move_speed if stats and stats.stats else 5.0
		parent.velocity = direction * move_speed
		parent.move_and_slide()

## Face target
func _face_target(target_node: Node3D) -> void:
	if not target_node:
		return
	
	var direction := _owner_node.global_position.direction_to(target_node.global_position)
	if direction.length() > 0.01:
		var target_rotation := atan2(direction.x, direction.z)
		_owner_node.rotation.y = lerp_angle(_owner_node.rotation.y, target_rotation, 0.1)

## Generate random patrol target within patrol radius
func _generate_patrol_target() -> void:
	var random_offset := Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0.0,
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = spawn_position + random_offset

## Transition to new AI state
func _transition_to(new_state: AIState) -> void:
	if new_state == current_ai_state:
		return
	
	var old_state := current_ai_state
	current_ai_state = new_state
	state_changed.emit(old_state, new_state)

## Find player in scene
func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node3D:
		return players[0]
	return null

## Find Node3D in parent hierarchy
func _find_node3d(node: Node) -> Node3D:
	if node is Node3D:
		return node
	if node.get_parent():
		return _find_node3d(node.get_parent())
	return null

## Find component of specific type
func _find_component(component_type) -> Node:
	var parent := get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if is_instance_of(child, component_type):
			return child
	
	return null

## Get current AI state
func get_ai_state() -> AIState:
	return current_ai_state

## Get current target
func get_target() -> Node3D:
	return target
