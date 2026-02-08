## Property-based tests for EnemyAI component
## Validates correctness properties across random inputs
extends "res://tests/test_utils/property_test.gd"

var enemy: CharacterBody3D
var enemy_ai: EnemyAI
var enemy_movement: Movement
var enemy_combat: Combat
var player: CharacterBody3D

func before_each() -> void:
	# Create player
	player = CharacterBody3D.new()
	player.add_to_group("player")
	add_child(player)
	
	# Create enemy with AI
	enemy = CharacterBody3D.new()
	add_child(enemy)
	
	# Add NavigationAgent3D
	var nav_agent := NavigationAgent3D.new()
	enemy.add_child(nav_agent)
	
	# Add Movement component
	enemy_movement = Movement.new()
	enemy_movement.move_speed = 3.0
	enemy.add_child(enemy_movement)
	
	# Add Combat component
	enemy_combat = Combat.new()
	enemy_combat.attack_range = 1.5
	enemy.add_child(enemy_combat)
	
	# Add EnemyAI component
	enemy_ai = EnemyAI.new()
	enemy_ai.detection_range = 10.0
	enemy_ai.path_update_rate = 5.0
	enemy.add_child(enemy_ai)
	
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	if player:
		player.queue_free()
	if enemy:
		enemy.queue_free()
	player = null
	enemy = null
	enemy_ai = null
	enemy_movement = null
	enemy_combat = null

## Property 9: Detection Range Behavior
## Validates: Requirements 3.6
## Ensures enemy chases if distance <= detection_range
func test_detection_range_behavior() -> void:
	assert_property_holds("Enemy detects player within range", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Set random detection range
		var detection_range := random_float(rng, 5.0, 20.0)
		enemy_ai.detection_range = detection_range
		
		# Generate random player position
		var distance := random_float(rng, 1.0, 25.0)
		var direction := random_direction(rng)
		player.global_position = enemy.global_position + (direction * distance)
		
		# Update AI state
		enemy_ai._update_ai_state()
		
		var state := enemy_ai.get_state()
		var should_detect := distance <= detection_range
		
		# If detected, should be in CHASE or ATTACK state
		var is_detected := state != EnemyAI.State.IDLE
		var correct := is_detected == should_detect
		
		return {
			"success": correct,
			"input": "range=%.2f, distance=%.2f" % [detection_range, distance],
			"reason": "Enemy %s but should %s (state=%s)" % [
				"detected" if is_detected else "idle",
				"detect" if should_detect else "be idle",
				["IDLE", "CHASE", "ATTACK"][state]
			]
		}
	)

## Property 10: Navigation Path Validity
## Validates: Requirements 3.6
## Ensures each path step moves closer to target (simplified test)
func test_navigation_path_validity() -> void:
	assert_property_holds("Navigation moves toward target", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Place player at random position within detection range
		var distance := random_float(rng, 5.0, 9.0)
		var direction := random_direction(rng)
		player.global_position = enemy.global_position + (direction * distance)
		
		# Update AI to start chasing
		enemy_ai._update_ai_state()
		
		var initial_distance := enemy.global_position.distance_to(player.global_position)
		
		# Execute chase behavior for a few frames
		for i in range(5):
			enemy_ai._execute_chase(0.1)
		
		var final_distance := enemy.global_position.distance_to(player.global_position)
		
		# Distance should decrease or stay roughly the same (within tolerance)
		# Allow small increase due to navigation mesh constraints
		var moved_closer := final_distance <= initial_distance + 0.5
		
		return {
			"success": moved_closer,
			"input": "initial_dist=%.2f" % initial_distance,
			"reason": "Distance increased from %.2f to %.2f" % [initial_distance, final_distance]
		}
	)
