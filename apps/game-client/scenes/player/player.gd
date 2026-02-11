## Player controller script
## Handles WASD input, mouse targeting, and respawn on death
extends CharacterBody3D

@export var spawn_point: Vector3 = Vector3.ZERO

var _health: Health
var _movement: Movement
var _combat: Combat
var _move_target: Vector3 = Vector3.ZERO
var _is_moving_to_target: bool = false
var _rmb_target: Node3D = null  # Target selected by RMB
var _camera: Camera3D
var _animation_player: AnimationPlayer
var _is_attacking: bool = false

func _ready() -> void:
	print("Player: Initializing at ", global_position)
	
	# Get component references
	_health = $Health
	_movement = $Movement
	_combat = $Combat
	_animation_player = $CharacterModel/AnimationPlayer if has_node("CharacterModel/AnimationPlayer") else $AnimationPlayer
	
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
	
	# Connect to death signal for respawn
	if _health:
		_health.died.connect(_on_death)
	
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
		# Check if we have an RMB target (enemy) or just a ground position
		if _rmb_target and is_instance_valid(_rmb_target):
			# Moving to an enemy - stop when within cone range
			var distance := global_position.distance_to(_rmb_target.global_position)
			
			if distance <= _combat.cone_range:
				# Within range, stop moving
				_is_moving_to_target = false
				_rmb_target = null
				input_dir = Vector3.ZERO
			else:
				# Calculate direction to target
				var direction := global_position.direction_to(_rmb_target.global_position)
				direction.y = 0  # Keep movement horizontal
				input_dir = direction
		else:
			# Moving to a ground position
			var direction := global_position.direction_to(_move_target)
			direction.y = 0  # Keep movement horizontal
			
			# Check if we've reached the target
			var distance := global_position.distance_to(_move_target)
			if distance < 0.5:  # Within 0.5 units
				_is_moving_to_target = false
				input_dir = Vector3.ZERO
			else:
				input_dir = direction
	else:
		# Handle WASD input (overrides RMB movement)
		input_dir = _get_input_direction()
		
		# If WASD is pressed, cancel RMB movement
		if input_dir.length() > 0:
			_is_moving_to_target = false
			_rmb_target = null
	
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
		_handle_attack()
	
	# Handle H key for heal
	if Input.is_action_just_pressed("heal"):
		_handle_heal()

func _input(event: InputEvent) -> void:
	# Handle right mouse click for movement
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_handle_move_to_click()

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

## Transform input direction to world space based on camera rotation
## Makes WASD relative to camera view for intuitive controls
func _transform_to_world_space(input_dir: Vector3) -> Vector3:
	if input_dir.length() == 0:
		return Vector3.ZERO
	
	# Get camera rotation around Y axis
	if _camera and _camera is IsometricCamera:
		var camera_rotation_y: float = _camera.current_rotation_y
		# Rotate input by camera's Y rotation
		var rotated := input_dir.rotated(Vector3.UP, deg_to_rad(camera_rotation_y))
		return rotated
	
	# Fallback to world space if no camera
	return input_dir

## Handle attack targeting
func _handle_attack() -> void:
	if not _combat:
		print("Player: No combat component!")
		return
	
	if _is_attacking:
		return  # Already attacking
	
	_is_attacking = true
	
	# Find nearest enemy in cone to face toward
	var nearest_enemy := _find_nearest_enemy_in_cone()
	if nearest_enemy:
		# Rotate to face AWAY from the enemy (because character model is backwards)
		var direction_to_enemy := global_position.direction_to(nearest_enemy.global_position)
		direction_to_enemy.y = 0  # Keep rotation horizontal
		# Face opposite direction so the visual model faces the enemy
		look_at(global_position - direction_to_enemy, Vector3.UP)
	
	# Play attack animation
	if _animation_player:
		_animation_player.play("Sword_Attack")
		# Wait for animation to finish
		await _animation_player.animation_finished
	
	# Perform cone attack
	var hit_targets := _combat.attack_cone()
	print("Player: Hit ", hit_targets.size(), " targets")
	
	_is_attacking = false

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

## Find nearest enemy in cone to face toward
func _find_nearest_enemy_in_cone() -> Node3D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_distance := INF
	
	for enemy in enemies:
		if enemy is Node3D:
			var distance := global_position.distance_to(enemy.global_position)
			if distance < nearest_distance and distance <= _combat.cone_range:
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
		var clicked_object = result.get("collider")
		
		# Check if clicked on an enemy
		if clicked_object and clicked_object is Node3D and clicked_object.is_in_group("enemies"):
			# Check if already within range
			var distance := global_position.distance_to(clicked_object.global_position)
			if distance <= _combat.cone_range:
				print("Player: Already in range of enemy, ignoring RMB")
				return
			
			# Set RMB target to the enemy
			_rmb_target = clicked_object
			_is_moving_to_target = true
			print("Player: Moving to enemy ", clicked_object.name)
		else:
			# Fallback to ground movement
			_rmb_target = null
			_move_target = result.position
			_move_target.y = global_position.y  # Keep same height
			_is_moving_to_target = true
			print("Player: Moving to ", _move_target)

## Update character animation based on movement
func _update_animation(direction: Vector3) -> void:
	if not _animation_player:
		return
	
	# Don't interrupt attack animation
	if _is_attacking:
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
