## Player controller script
## Handles WASD input, mouse targeting, and respawn on death
extends CharacterBody3D

@export var spawn_point: Vector3 = Vector3.ZERO

var _health: Health
var _movement: Movement
var _combat: Combat

func _ready() -> void:
	# Get component references
	_health = $Health
	_movement = $Movement
	_combat = $Combat
	
	# Connect to death signal for respawn
	if _health:
		_health.died.connect(_on_death)
	
	# Set initial spawn point
	spawn_point = global_position

func _process(delta: float) -> void:
	# Handle WASD input
	var input_dir := _get_input_direction()
	
	# Transform input to world space (accounting for isometric camera)
	var world_dir := _transform_to_world_space(input_dir)
	
	# Apply movement
	if _movement:
		_movement.move(world_dir, delta)
	
	# Handle mouse click for attack
	if Input.is_action_just_pressed("attack"):
		_handle_attack()

## Get input direction from WASD keys
func _get_input_direction() -> Vector3:
	var input := Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input.z += 1.0
	if Input.is_action_pressed("move_left"):
		input.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input.x += 1.0
	
	return input.normalized()

## Transform input direction to world space for isometric camera
## For now, this is a simple pass-through. Will be updated when camera is implemented.
func _transform_to_world_space(input_dir: Vector3) -> Vector3:
	# TODO: Transform based on camera rotation (45° for isometric)
	# For now, assume standard orientation
	return input_dir

## Handle attack targeting
func _handle_attack() -> void:
	if not _combat:
		return
	
	# Find nearest enemy in range
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy:
		_combat.attack(nearest_enemy)

## Find nearest enemy in attack range
func _find_nearest_enemy() -> Node3D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_distance := INF
	
	for enemy in enemies:
		if enemy is Node3D:
			var distance := global_position.distance_to(enemy.global_position)
			if distance < nearest_distance and _combat.is_in_range(enemy):
				nearest = enemy
				nearest_distance = distance
	
	return nearest

## Handle death and respawn
func _on_death() -> void:
	# Respawn at spawn point
	global_position = spawn_point
	
	# Reset health
	if _health:
		_health._data.current_health = _health._data.max_health
		_health._is_alive = true
		_health.health_changed.emit(_health._data.current_health, _health._data.max_health)
