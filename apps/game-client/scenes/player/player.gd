## Player controller script
## Handles WASD input, mouse targeting, and respawn on death
extends CharacterBody3D

@export var spawn_point: Vector3 = Vector3.ZERO

var _health: Health
var _movement: Movement
var _combat: Combat
var _move_target: Vector3 = Vector3.ZERO
var _is_moving_to_target: bool = false
var _camera: Camera3D
var _animation_player: AnimationPlayer
var _is_attacking: bool = false
var _movement_indicator: Node3D = null
var _movement_indicator_scene: PackedScene = null

# New combat system components
var _stats_component: StatsComponent
var _combat_component: CombatComponent
var _inventory: Inventory

func _ready() -> void:
	print("Player: Initializing at ", global_position)
	
	# Load movement indicator scene
	_movement_indicator_scene = load("res://scenes/ui/movement_indicator.tscn")
	
	# Get component references
	_health = $Health as Health
	_movement = $Movement as Movement
	_combat = $Combat as Combat
	_animation_player = $CharacterModel/AnimationPlayer if has_node("CharacterModel/AnimationPlayer") else $AnimationPlayer
	
	# Get new combat system components
	_stats_component = $StatsComponent as StatsComponent
	_combat_component = $CombatComponent as CombatComponent
	_inventory = $Inventory as Inventory
	
	print("Player: New combat components - Stats:", _stats_component != null, " Combat:", _combat_component != null, " Inventory:", _inventory != null)
	
	if not _health:
		push_error("Player: Health component not found!")
	if not _movement:
		push_error("Player: Movement component not found!")
	if not _combat:
		push_error("Player: Combat component not found!")
	if not _animation_player:
		push_warning("Player: AnimationPlayer not found!")
	else:
		print("Player: AnimationPlayer found with animations: ", _animation_player.get_animation_list())
	
	# Connect to death signal for respawn (both old and new systems)
	if _health:
		_health.died.connect(_on_death)
	if _stats_component:
		_stats_component.died.connect(_on_death)
	
	# Set initial spawn point
	spawn_point = global_position
	
	# Find camera
	_camera = get_viewport().get_camera_3d()
	if not _camera:
		push_warning("Player: Camera not found!")
	
	print("Player: Ready! Components - Health:", _health != null, " Movement:", _movement != null, " Combat:", _combat != null)

func _physics_process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	
	# Check for RMB movement
	if _is_moving_to_target:
		# Calculate direction to target
		var direction := global_position.direction_to(_move_target)
		direction.y = 0  # Keep movement horizontal
		
		# Check if we've reached the target
		var distance := global_position.distance_to(_move_target)
		if distance < 0.5:  # Within 0.5 units
			_is_moving_to_target = false
			input_dir = Vector3.ZERO
			# Remove movement indicator when arrived
			_remove_movement_indicator()
		else:
			input_dir = direction
	else:
		# Handle WASD input (overrides RMB movement)
		input_dir = _get_input_direction()
		
		# If WASD is pressed, cancel RMB movement
		if input_dir.length() > 0:
			_is_moving_to_target = false
			# Remove movement indicator when WASD is used
			_remove_movement_indicator()
	
	# Transform input to world space (accounting for isometric camera)
	var world_dir := _transform_to_world_space(input_dir)
	
	# Apply movement
	if _movement:
		_movement.move(world_dir, delta)
	
	# Update animations based on movement
	_update_animation(world_dir)

func _process(_delta: float) -> void:
	# Handle left mouse click for attack
	if Input.is_action_just_pressed("attack"):
		print("Player: === LMB ATTACK TRIGGERED ===")
		print("Player: Player position: ", global_position)
		print("Player: Player rotation: ", rotation)
		
		# Stop movement when attacking
		_is_moving_to_target = false
		_remove_movement_indicator()
		print("Player: Movement stopped")
		
		# Get mouse position in world via raycast
		if _camera:
			var mouse_pos := get_viewport().get_mouse_position()
			print("Player: Mouse screen position: ", mouse_pos)
			var from := _camera.project_ray_origin(mouse_pos)
			var to := from + _camera.project_ray_normal(mouse_pos) * 1000.0
			
			var space_state := get_world_3d().direct_space_state
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			
			var result := space_state.intersect_ray(query)
			
			if result:
				print("Player: Raycast hit at: ", result.position)
				# Rotate player to face the clicked position
				# This sets the Player node's rotation, which determines attack direction
				var direction_to_click := global_position.direction_to(result.position)
				direction_to_click.y = 0  # Keep rotation horizontal
				if direction_to_click.length() > 0:
					var target_rotation := atan2(direction_to_click.x, direction_to_click.z)
					print("Player: Setting rotation from ", rotation.y, " to ", target_rotation)
					rotation.y = target_rotation
					print("Player: Rotation set to: ", rotation.y)
			else:
				print("Player: Raycast missed")
		else:
			print("Player: No camera found")
		
		# Trigger attack via new combat system
		if _combat_component:
			print("Player: Calling _combat_component.attack()")
			var attack_result = _combat_component.attack()
			print("Player: attack() returned: ", attack_result)
		else:
			print("Player: No _combat_component, using old system")
			_handle_attack()
		
		print("Player: === LMB ATTACK COMPLETE ===")
	
	# Handle H key for heal
	if Input.is_action_just_pressed("heal"):
		_handle_heal()

func _input(event: InputEvent) -> void:
	# Handle right mouse click for movement
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_handle_move_to_click()
	
	# New combat system input handling
	if not _combat_component:
		return
	
	# Dodge (spacebar)
	if event.is_action_pressed("dodge"):
		var dodge_direction := Vector3.ZERO
		
		# Get movement direction for dodge
		var input_dir := _get_input_direction()
		if input_dir.length() > 0.1:
			dodge_direction = _transform_to_world_space(input_dir)
		else:
			# Dodge forward if not moving
			dodge_direction = -global_transform.basis.z
		
		_combat_component.dodge(dodge_direction)
	
	# Cast fireball (right mouse button - but only if not moving)
	if event.is_action_pressed("cast_fireball"):
		if _combat_component.ability_controller:
			_combat_component.ability_controller.activate_ability("fireball")

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
		print("Player: No combat component!")
		return
	
	if _is_attacking:
		return  # Already attacking
	
	# Find nearest enemy in range
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy:
		print("Player: Attacking enemy at ", nearest_enemy.global_position)
		_is_attacking = true
		
		# Rotate to face the enemy
		var direction_to_enemy := global_position.direction_to(nearest_enemy.global_position)
		direction_to_enemy.y = 0  # Keep rotation horizontal
		if direction_to_enemy.length() > 0:
			var target_rotation := atan2(direction_to_enemy.x, direction_to_enemy.z)
			rotation.y = target_rotation
		
		# Play attack animation
		if _animation_player:
			_animation_player.play("Sword_Attack")
			# Wait for animation to finish
			await _animation_player.animation_finished
		
		# Do damage
		var success := _combat.attack(nearest_enemy)
		print("Player: Attack success = ", success)
		_is_attacking = false
	else:
		print("Player: No enemy in range to attack")

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

## Handle RMB click for movement
func _handle_move_to_click() -> void:
	if not _camera:
		return
	
	# Get mouse position
	var mouse_pos := get_viewport().get_mouse_position()
	
	# Raycast from camera to world
	var from := _camera.project_ray_origin(mouse_pos)
	var to := from + _camera.project_ray_normal(mouse_pos) * 1000.0
	
	# Perform raycast
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result := space_state.intersect_ray(query)
	
	if result:
		# Set move target to clicked position
		_move_target = result.position
		_move_target.y = global_position.y  # Keep same height
		_is_moving_to_target = true
		print("Player: Moving to ", _move_target)
		
		# Spawn movement indicator at clicked position
		_spawn_movement_indicator(result.position)

## Spawn movement indicator at target position
func _spawn_movement_indicator(position: Vector3) -> void:
	# Remove previous indicator if it exists
	_remove_movement_indicator()
	
	if not _movement_indicator_scene:
		push_warning("Player: Movement indicator scene not loaded!")
		return
	
	# Instantiate indicator
	_movement_indicator = _movement_indicator_scene.instantiate()
	
	# Add to scene (as child of NavigationRegion3D or root)
	var nav_region := get_node("/root/Main/NavigationRegion3D")
	if nav_region:
		nav_region.add_child(_movement_indicator)
	else:
		get_tree().root.add_child(_movement_indicator)
	
	# Set position at floor level (y=0)
	_movement_indicator.global_position = Vector3(position.x, 0.0, position.z)
	print("Player: Movement indicator spawned at ", _movement_indicator.global_position)

## Remove movement indicator
func _remove_movement_indicator() -> void:
	if _movement_indicator:
		_movement_indicator.remove_immediately()
		_movement_indicator = null

## Update character animation based on movement
## This runs every frame to keep Walk/Idle animations playing
## CRITICAL: Must not override attack animations from combat system
func _update_animation(direction: Vector3) -> void:
	if not _animation_player:
		return
	
	# Don't interrupt attack animation from old combat system
	if _is_attacking:
		return
	
	# Don't interrupt attack animation from new combat system
	# The combat system state machine controls when attack animations play
	if _combat_component and _combat_component.state_machine:
		if _combat_component.state_machine.current_state == StateMachine.State.ATTACKING:
			return
	
	var is_moving := direction.length() > 0.1
	
	if is_moving:
		# Play walk animation if not already playing
		if _animation_player.current_animation != "Walk":
			_animation_player.play("Walk")
	else:
		# Play idle animation if not already playing
		if _animation_player.current_animation != "Idle":
			_animation_player.play("Idle")

## Handle heal action (H key)
func _handle_heal() -> void:
	if not _health:
		return
	
	# Heal for 20 HP
	var heal_amount := 20
	_health.heal(heal_amount)
	print("Player: Healed for ", heal_amount, " HP. Current health: ", _health._data.current_health)
	
	# Track stats
	if DungeonStatsTracker.instance:
		DungeonStatsTracker.instance.record_player_heal(heal_amount)

## Add gold to inventory (new combat system)
func add_gold(amount: int) -> void:
	if _inventory:
		_inventory.add_gold(amount)

## Add item to inventory (new combat system)
func add_item(item_data: Dictionary) -> void:
	if _inventory:
		_inventory.add_item(item_data)
