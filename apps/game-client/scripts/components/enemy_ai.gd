## EnemyAI component
## Handles enemy behavior: detection, pathfinding, and state management
class_name EnemyAI
extends Node

enum State {
	IDLE,
	CHASE,
	ATTACK
}

@export var detection_range: float = 10.0
@export var path_update_rate: float = 5.0  # Hz

var _state: State = State.IDLE
var _target: Node3D = null
var _owner_node: Node3D
var _navigation_agent: NavigationAgent3D
var _movement: Movement
var _combat: Combat
var _path_update_timer: float = 0.0
var _detection_indicator: Node3D = null

func _ready() -> void:
	# Find owner node
	_owner_node = _find_node3d(get_parent())
	if not _owner_node:
		push_error("EnemyAI requires Node3D parent or ancestor")
		return
	
	# Find NavigationAgent3D
	_navigation_agent = _find_navigation_agent(_owner_node)
	if not _navigation_agent:
		push_error("EnemyAI requires NavigationAgent3D sibling")
	
	# Find Movement component
	_movement = _find_component(Movement)
	if not _movement:
		push_error("EnemyAI requires Movement component")
	
	# Find Combat component
	_combat = _find_component(Combat)
	if not _combat:
		push_error("EnemyAI requires Combat component")
	
	# Find DetectionIndicator
	_detection_indicator = _find_detection_indicator(_owner_node)
	if _detection_indicator and _detection_indicator.has_method("hide_indicator"):
		_detection_indicator.hide_indicator()

func _physics_process(delta: float) -> void:
	if not _owner_node or not _movement or not _combat:
		return
	
	# Update path at specified rate (5Hz)
	_path_update_timer += delta
	var update_interval := 1.0 / path_update_rate
	if _path_update_timer >= update_interval:
		_path_update_timer = 0.0
		_update_ai_state()
		_update_navigation()
	
	# Execute current state behavior
	_execute_state(delta)

## Update AI state based on player detection
func _update_ai_state() -> void:
	# Find player
	var player := _find_player()
	if not player:
		_state = State.IDLE
		_target = null
		return
	
	# Check detection range
	var distance := _owner_node.global_position.distance_to(player.global_position)
	
	if distance <= detection_range:
		_target = player
		
		# Show detection indicator
		if _detection_indicator and _detection_indicator.has_method("show_indicator"):
			_detection_indicator.show_indicator()
		
		# Check if in attack range
		if _combat.is_in_range(player):
			_state = State.ATTACK
		else:
			_state = State.CHASE
	else:
		_state = State.IDLE
		_target = null
		
		# Hide detection indicator
		if _detection_indicator and _detection_indicator.has_method("hide_indicator"):
			_detection_indicator.hide_indicator()

## Update navigation path to target
func _update_navigation() -> void:
	if not _navigation_agent or not _target:
		return
	
	_navigation_agent.target_position = _target.global_position

## Execute behavior for current state
func _execute_state(delta: float) -> void:
	match _state:
		State.IDLE:
			_execute_idle(delta)
		State.CHASE:
			_execute_chase(delta)
		State.ATTACK:
			_execute_attack(delta)

## Idle state: no movement
func _execute_idle(_delta: float) -> void:
	_movement.move(Vector3.ZERO)

## Chase state: follow navigation path
func _execute_chase(delta: float) -> void:
	if not _navigation_agent or not _navigation_agent.is_navigation_finished():
		var next_position := _navigation_agent.get_next_path_position()
		var direction := (_owner_node.global_position.direction_to(next_position))
		_movement.move(direction, delta)
	else:
		_movement.move(Vector3.ZERO)

## Attack state: attack target
func _execute_attack(_delta: float) -> void:
	if _target and _combat:
		_combat.attack(_target)
	
	# Stop moving while attacking
	_movement.move(Vector3.ZERO)

## Get current AI state
func get_state() -> State:
	return _state

## Get current target
func get_target() -> Node3D:
	return _target

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

## Find NavigationAgent3D in siblings
func _find_navigation_agent(parent: Node) -> NavigationAgent3D:
	for child in parent.get_children():
		if child is NavigationAgent3D:
			return child
	return null

## Find component of specific type in siblings
func _find_component(component_type) -> Node:
	var parent := get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if is_instance_of(child, component_type):
			return child
	return null

## Find DetectionIndicator in siblings
func _find_detection_indicator(parent: Node) -> Node3D:
	for child in parent.get_children():
		if child.name == "DetectionIndicator":
			return child
	return null
