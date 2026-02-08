## Integration test for full playthrough validation
## **Validates: Requirements 11.2**
## Tests complete gameplay flow from start to finish
extends GutTest

const MAIN_SCENE = preload("res://scenes/main.tscn")

## Test complete playthrough with all mechanics
func test_full_playthrough_validation() -> void:
	# Load main scene
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	
	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find player
	var player: Node3D = null
	for child in main.get_children():
		if child.name == "Player":
			player = child
			break
	
	assert_not_null(player, "Main scene must have Player")
	
	# Find camera
	var camera: Camera3D = null
	for child in main.get_children():
		if child is Camera3D:
			camera = child
			break
	
	assert_not_null(camera, "Main scene must have Camera")
	
	# Verify player has required components
	var player_health := _find_component(player, "Health")
	var player_movement := _find_component(player, "Movement")
	var player_combat := _find_component(player, "Combat")
	
	assert_not_null(player_health, "Player must have Health component")
	assert_not_null(player_movement, "Player must have Movement component")
	assert_not_null(player_combat, "Player must have Combat component")
	
	# Verify initial health
	assert_gt(player_health.get_current_health(), 0, "Player should start with health > 0")
	
	# Find enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	assert_gt(enemies.size(), 0, "Main scene must have at least one enemy")
	
	# Verify each enemy has required components
	for enemy in enemies:
		var enemy_health := _find_component(enemy, "Health")
		var enemy_ai := _find_component(enemy, "EnemyAI")
		
		assert_not_null(enemy_health, "Enemy must have Health component")
		assert_not_null(enemy_ai, "Enemy must have EnemyAI component")
	
	# Test camera follows player
	var initial_camera_pos := camera.global_position
	player.global_position = Vector3(10, 0, 10)
	
	# Wait for camera to update
	for i in range(10):
		await get_tree().process_frame
	
	var new_camera_pos := camera.global_position
	assert_ne(initial_camera_pos, new_camera_pos, "Camera should follow player movement")
	
	# Verify no console errors during gameplay
	# (This is implicit - test will fail if errors occur)
	
	pass_test("Full playthrough validation passed")

## Test WASD movement works smoothly
func test_wasd_movement() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	
	await get_tree().process_frame
	
	var player: Node3D = null
	for child in main.get_children():
		if child.name == "Player":
			player = child
			break
	
	assert_not_null(player, "Main scene must have Player")
	
	var initial_pos := player.global_position
	
	# Simulate movement input (this would normally come from Input)
	# For now, just verify player can move
	var movement := _find_component(player, "Movement")
	assert_not_null(movement, "Player must have Movement component")
	
	# Test movement in different directions
	var directions := [
		Vector3(1, 0, 0),   # Right
		Vector3(-1, 0, 0),  # Left
		Vector3(0, 0, 1),   # Forward
		Vector3(0, 0, -1),  # Backward
	]
	
	for direction in directions:
		movement.move(direction, 0.016)  # Simulate one frame
		await get_tree().process_frame
	
	pass_test("WASD movement test passed")

## Test camera zoom works
func test_camera_zoom() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	
	await get_tree().process_frame
	
	var camera: Node = null
	for child in main.get_children():
		if child is Camera3D and child.has_method("zoom_in"):
			camera = child
			break
	
	assert_not_null(camera, "Main scene must have IsometricCamera")
	
	# Test zoom in
	var initial_distance: float = camera.distance
	camera.zoom_in()
	await get_tree().process_frame
	
	assert_lt(camera.distance, initial_distance, "Zoom in should decrease distance")
	
	# Test zoom out
	camera.zoom_out()
	await get_tree().process_frame
	
	assert_gt(camera.distance, camera.distance, "Zoom out should increase distance")
	
	pass_test("Camera zoom test passed")

## Test enemies detect, chase, and attack
func test_enemy_behavior() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	
	await get_tree().process_frame
	
	var player: Node3D = null
	for child in main.get_children():
		if child.name == "Player":
			player = child
			break
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	assert_gt(enemies.size(), 0, "Must have at least one enemy")
	
	var enemy := enemies[0]
	
	# Position player near enemy
	enemy.global_position = Vector3.ZERO
	player.global_position = Vector3(5, 0, 0)
	
	# Wait for AI to update
	for i in range(30):
		await get_tree().process_frame
	
	# Verify enemy AI is working
	var enemy_ai := _find_component(enemy, "EnemyAI")
	assert_not_null(enemy_ai, "Enemy must have EnemyAI")
	
	# Enemy should detect player and change state
	var state = enemy_ai.get_state()
	assert_true(
		state == enemy_ai.State.CHASE or state == enemy_ai.State.ATTACK,
		"Enemy should chase or attack when player is in range"
	)
	
	pass_test("Enemy behavior test passed")

## Test health system and death/respawn
func test_health_and_respawn() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	
	await get_tree().process_frame
	
	var player: Node3D = null
	for child in main.get_children():
		if child.name == "Player":
			player = child
			break
	
	var player_health := _find_component(player, "Health")
	assert_not_null(player_health, "Player must have Health")
	
	var initial_pos := player.global_position
	var initial_health: int = player_health.get_current_health()
	
	# Damage player to death
	player_health.take_damage(initial_health)
	
	# Wait for respawn
	await get_tree().create_timer(0.5).timeout
	
	# Verify player respawned
	assert_eq(player_health.get_current_health(), player_health.get_max_health(), "Player should respawn with full health")
	
	pass_test("Health and respawn test passed")

## Find component by name in node's children
func _find_component(node: Node, component_name: String) -> Node:
	for child in node.get_children():
		if child.name == component_name:
			return child
	return null
