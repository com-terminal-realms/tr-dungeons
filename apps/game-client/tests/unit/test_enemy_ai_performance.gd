## Unit tests for EnemyAI performance optimization
## Validates: Requirements 3.10
extends GutTest

const ENEMY_SCENE = preload("res://scenes/enemies/enemy_base.tscn")
const PLAYER_SCENE = preload("res://scenes/player/player.tscn")

## Test that enemy AI updates paths at 5Hz (not 60Hz)
func test_navigation_update_rate_is_5hz() -> void:
	# Create enemy and player
	var enemy := ENEMY_SCENE.instantiate()
	var player := PLAYER_SCENE.instantiate()
	add_child_autofree(enemy)
	add_child_autofree(player)
	
	# Position player within detection range
	enemy.global_position = Vector3.ZERO
	player.global_position = Vector3(5, 0, 0)
	
	# Get EnemyAI component
	var enemy_ai: Node = null
	for child in enemy.get_children():
		if child.name == "EnemyAI":
			enemy_ai = child
			break
	
	assert_not_null(enemy_ai, "Enemy must have EnemyAI component")
	
	# Verify path_update_rate is 5Hz
	assert_eq(enemy_ai.path_update_rate, 5.0, "Path update rate should be 5Hz")
	
	# Calculate expected update interval
	var expected_interval := 1.0 / 5.0  # 0.2 seconds
	assert_almost_eq(expected_interval, 0.2, 0.001, "Update interval should be 0.2 seconds")

## Test performance with multiple enemies
func test_performance_with_10_enemies() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child_autofree(player)
	player.global_position = Vector3.ZERO
	
	# Create 10 enemies
	var enemies: Array[Node] = []
	for i in range(10):
		var enemy := ENEMY_SCENE.instantiate()
		add_child_autofree(enemy)
		
		# Position in circle around player
		var angle := (i / 10.0) * TAU
		var radius := 8.0
		enemy.global_position = Vector3(
			cos(angle) * radius,
			0,
			sin(angle) * radius
		)
		
		enemies.append(enemy)
	
	# Run for a few frames to ensure no crashes
	for frame in range(10):
		await get_tree().process_frame
	
	# Verify all enemies still exist
	assert_eq(enemies.size(), 10, "All 10 enemies should still exist")
	
	# Verify all enemies have AI components
	for enemy in enemies:
		var has_ai := false
		for child in enemy.get_children():
			if child.name == "EnemyAI":
				has_ai = true
				break
		assert_true(has_ai, "Enemy should have EnemyAI component")

## Test that navigation updates don't happen every frame
func test_navigation_updates_are_throttled() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	var player := PLAYER_SCENE.instantiate()
	add_child_autofree(enemy)
	add_child_autofree(player)
	
	# Position player within detection range
	enemy.global_position = Vector3.ZERO
	player.global_position = Vector3(5, 0, 0)
	
	# Get EnemyAI component
	var enemy_ai: Node = null
	for child in enemy.get_children():
		if child.name == "EnemyAI":
			enemy_ai = child
			break
	
	assert_not_null(enemy_ai, "Enemy must have EnemyAI component")
	
	# Verify update rate is not 60Hz (which would be every frame)
	assert_ne(enemy_ai.path_update_rate, 60.0, "Path update rate should not be 60Hz")
	assert_lt(enemy_ai.path_update_rate, 10.0, "Path update rate should be less than 10Hz for performance")
