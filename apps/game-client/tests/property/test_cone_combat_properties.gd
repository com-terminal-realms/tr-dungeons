## Property-based tests for Cone Combat system
## Validates correctness properties for cone-based area attacks
## Feature: cone-melee-combat
extends "res://tests/test_utils/property_test.gd"

var attacker: Node3D
var attacker_combat: Combat

func before_each() -> void:
	# Create attacker with Combat component
	attacker = Node3D.new()
	attacker.add_to_group("player")  # Mark as player for target detection
	add_child(attacker)
	
	attacker_combat = Combat.new()
	attacker_combat.attack_damage = 10
	attacker_combat.attack_cooldown = 1.0
	attacker_combat.cone_angle = 90.0
	attacker_combat.cone_range = 3.0
	attacker.add_child(attacker_combat)
	
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	# Clean up all enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	if attacker:
		attacker.queue_free()
	attacker = null
	attacker_combat = null

## Helper: Create enemy at position
func _create_enemy(pos: Vector3) -> Node3D:
	var enemy := Node3D.new()
	enemy.add_to_group("enemies")
	add_child(enemy)
	enemy.position = pos  # Use position instead of global_position since it's a child
	enemy.force_update_transform()  # Force transform update
	
	var health := Health.new()
	health.name = "Health"  # Set the name so get_node can find it
	health.max_health = 100
	# Initialize health data directly (bypassing _ready())
	health._data = HealthData.new({"max_health": 100, "current_health": 100})
	health._is_alive = true
	enemy.add_child(health)
	
	return enemy

## Helper: Generate random position within range
func random_position(rng: RandomNumberGenerator, min_val: float, max_val: float) -> Vector3:
	return Vector3(
		rng.randf_range(min_val, max_val),
		0,  # Keep Y at 0 for ground level
		rng.randf_range(min_val, max_val)
	)

## Helper: Calculate angle between attacker forward and target
func _calculate_angle_to_target(attacker_pos: Vector3, attacker_forward: Vector3, target_pos: Vector3) -> float:
	var direction_to_target := attacker_pos.direction_to(target_pos)
	direction_to_target.y = 0
	direction_to_target = direction_to_target.normalized()
	
	var forward := attacker_forward
	forward.y = 0
	forward = forward.normalized()
	
	return rad_to_deg(forward.angle_to(direction_to_target))

## Feature: cone-melee-combat, Property 1: Angle Boundary Correctness
## Validates: Requirements 2.2
## For any attacker and target, if angle <= half cone angle, target is within angular bounds
func test_angle_boundary_correctness() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Angle boundary correctness", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Generate random attacker position and rotation
		attacker.position = random_position(rng, -10, 10)
		var rotation_y := random_float(rng, 0, TAU)
		attacker.rotation.y = rotation_y
		
		# Generate random target position within reasonable distance
		var distance := random_float(rng, 0.5, 5.0)
		var angle_offset := random_float(rng, -180, 180)
		var target_angle := rotation_y + deg_to_rad(angle_offset)
		var target_pos := attacker.position + Vector3(
			cos(target_angle) * distance,
			0,
			sin(target_angle) * distance
		)
		
		var enemy := _create_enemy(target_pos)
		
		# Calculate actual angle
		var forward := -attacker.transform.basis.z
		var actual_angle := _calculate_angle_to_target(attacker.position, forward, target_pos)
		
		# Check if target is detected in cone
		var in_cone := attacker_combat._is_target_in_cone(enemy)
		
		# Expected: in cone if angle <= half cone angle AND distance <= cone range
		var half_cone_angle := attacker_combat.cone_angle / 2.0
		var expected_in_angular_bounds := actual_angle <= half_cone_angle
		var in_distance_bounds := distance <= attacker_combat.cone_range
		var expected_in_cone := expected_in_angular_bounds and in_distance_bounds
		
		var correct := in_cone == expected_in_cone
		
		# Clean up enemy
		enemy.queue_free()
		
		return {
			"success": correct,
			"input": "angle=%.2f, half_cone=%.2f, distance=%.2f, range=%.2f" % [
				actual_angle, half_cone_angle, distance, attacker_combat.cone_range
			],
			"reason": "Target %s in cone, expected %s (angle check: %s, distance check: %s)" % [
				"is" if in_cone else "not",
				"in" if expected_in_cone else "out",
				"pass" if expected_in_angular_bounds else "fail",
				"pass" if in_distance_bounds else "fail"
			]
		}
	)

## Feature: cone-melee-combat, Property 2: Distance Boundary Correctness
## Validates: Requirements 2.3
## For any attacker and target, if distance <= cone range, target is within distance bounds
func test_distance_boundary_correctness() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Distance boundary correctness", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Position attacker
		attacker.position = Vector3.ZERO
		attacker.rotation.y = 0  # Face forward (-Z)
		
		# Generate random target directly in front (angle = 0)
		var distance := random_float(rng, 0.1, 6.0)
		var target_pos := attacker.position + Vector3(0, 0, -distance)
		
		var enemy := _create_enemy(target_pos)
		
		# Check if target is detected in cone
		var in_cone := attacker_combat._is_target_in_cone(enemy)
		
		# Expected: in cone if distance <= cone range (angle is 0, so always in angular bounds)
		var expected_in_cone := distance <= attacker_combat.cone_range
		
		var correct := in_cone == expected_in_cone
		
		# Clean up enemy
		enemy.queue_free()
		
		return {
			"success": correct,
			"input": "distance=%.2f, cone_range=%.2f" % [distance, attacker_combat.cone_range],
			"reason": "Target %s in cone, expected %s" % [
				"is" if in_cone else "not",
				"in" if expected_in_cone else "out"
			]
		}
	)

## Feature: cone-melee-combat, Property 3: Cone Inclusion Correctness
## Validates: Requirements 2.4
## For any target within both angle and distance bounds, target should be included
func test_cone_inclusion_correctness() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Cone inclusion correctness", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Position attacker
		attacker.position = Vector3.ZERO
		attacker.rotation.y = 0
		
		# Generate target WITHIN cone bounds
		var half_cone_angle := attacker_combat.cone_angle / 2.0
		var angle := random_float(rng, -half_cone_angle * 0.9, half_cone_angle * 0.9)  # 90% of half angle
		var distance := random_float(rng, 0.5, attacker_combat.cone_range * 0.9)  # 90% of range
		
		var angle_rad := deg_to_rad(angle)
		var target_pos := attacker.position + Vector3(
			sin(angle_rad) * distance,
			0,
			-cos(angle_rad) * distance
		)
		
		var enemy := _create_enemy(target_pos)
		
		# Target should be in cone
		var in_cone := attacker_combat._is_target_in_cone(enemy)
		
		# Clean up enemy
		enemy.queue_free()
		
		return {
			"success": in_cone,
			"input": "angle=%.2f (half_cone=%.2f), distance=%.2f (range=%.2f)" % [
				angle, half_cone_angle, distance, attacker_combat.cone_range
			],
			"reason": "Target within bounds but not detected in cone"
		}
	)

## Feature: cone-melee-combat, Property 4: Cone Exclusion Correctness
## Validates: Requirements 2.5
## For any target outside either angle or distance bounds, target should be excluded
func test_cone_exclusion_correctness() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Cone exclusion correctness", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Position attacker
		attacker.position = Vector3.ZERO
		attacker.rotation.y = 0
		
		# Randomly choose to violate angle OR distance bound
		var violate_angle := rng.randf() < 0.5
		
		var angle: float
		var distance: float
		var half_cone_angle := attacker_combat.cone_angle / 2.0
		
		if violate_angle:
			# Outside angle bounds, but within distance
			angle = random_float(rng, half_cone_angle * 1.1, 180.0)
			distance = random_float(rng, 0.5, attacker_combat.cone_range * 0.9)
		else:
			# Within angle bounds, but outside distance
			angle = random_float(rng, 0, half_cone_angle * 0.9)
			distance = random_float(rng, attacker_combat.cone_range * 1.1, attacker_combat.cone_range * 2.0)
		
		var angle_rad := deg_to_rad(angle)
		var target_pos := attacker.position + Vector3(
			sin(angle_rad) * distance,
			0,
			-cos(angle_rad) * distance
		)
		
		var enemy := _create_enemy(target_pos)
		
		# Target should NOT be in cone
		var in_cone := attacker_combat._is_target_in_cone(enemy)
		
		# Clean up enemy
		enemy.queue_free()
		
		return {
			"success": not in_cone,
			"input": "angle=%.2f (half_cone=%.2f), distance=%.2f (range=%.2f), violated=%s" % [
				angle, half_cone_angle, distance, attacker_combat.cone_range,
				"angle" if violate_angle else "distance"
			],
			"reason": "Target outside bounds but detected in cone"
		}
	)

## Feature: cone-melee-combat, Property 5: Multi-Target Damage Consistency
## Validates: Requirements 3.1, 3.2
## For any cone attack hitting N targets, all targets receive same damage in same frame
func test_multi_target_damage_consistency() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Multi-target damage consistency", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Position attacker
		attacker.position = Vector3.ZERO
		attacker.rotation.y = 0
		
		# Create random number of enemies (2-5) within cone
		var num_enemies := rng.randi_range(2, 5)
		var enemies: Array[Node3D] = []
		var initial_healths: Array[int] = []
		
		for i in range(num_enemies):
			var angle := random_float(rng, -40, 40)  # Within 90° cone
			var distance := random_float(rng, 0.5, 2.5)  # Within 3.0 range
			var angle_rad := deg_to_rad(angle)
			var target_pos := attacker.position + Vector3(
				sin(angle_rad) * distance,
				0,
				-cos(angle_rad) * distance
			)
			
			var enemy := _create_enemy(target_pos)
			enemies.append(enemy)
			
			var health := enemy.get_node("Health") as Health
			if health and health._data:
				initial_healths.append(health._data.current_health)
			else:
				push_error("Health component or _data is null!")
				initial_healths.append(100)  # Default value
		
		# Perform cone attack
		attacker_combat._cooldown_timer = 0.0  # Reset cooldown for test
		var hit_targets := attacker_combat.attack_cone()
		
		# Check all targets received same damage
		var all_same_damage := true
		var expected_damage := attacker_combat.attack_damage
		var num_damaged := 0
		
		for i in range(enemies.size()):
			var enemy := enemies[i]
			var health := enemy.get_node("Health") as Health
			if health and health._data:
				var actual_damage := initial_healths[i] - health._data.current_health
				
				if actual_damage > 0:
					num_damaged += 1
					if actual_damage != expected_damage:
						all_same_damage = false
						break
		
		# Check all targets were hit
		var all_hit := hit_targets.size() == num_enemies
		
		# Clean up enemies immediately - remove from group and queue for deletion
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.remove_from_group("enemies")  # Remove from group immediately
				enemy.queue_free()
		
		return {
			"success": all_same_damage and all_hit and num_damaged == num_enemies,
			"input": "num_enemies=%d, expected_damage=%d, hit=%d, damaged=%d" % [num_enemies, expected_damage, hit_targets.size(), num_damaged],
			"reason": "All targets hit: %s, All same damage: %s, All damaged: %s" % [all_hit, all_same_damage, num_damaged == num_enemies]
		}
	)

## Unit test: Zero-target attack
## Validates: Requirements 3.3
## Cone attack with no targets should complete without errors and apply cooldown
func test_zero_target_attack() -> void:
	# Position attacker
	attacker.position = Vector3.ZERO
	attacker.rotation.y = 0
	
	# Ensure no enemies exist
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	
	await get_tree().process_frame
	
	# Perform cone attack with no targets
	var hit_targets := attacker_combat.attack_cone()
	
	# Should return empty array
	assert_eq(hit_targets.size(), 0, "Should hit zero targets")
	
	# Cooldown should be applied
	assert_false(attacker_combat.is_attack_ready(), "Cooldown should be applied after attack")
	assert_gt(attacker_combat.get_cooldown_remaining(), 0.0, "Cooldown timer should be > 0")

## Feature: cone-melee-combat, Property 9: Cooldown Applied After Attack
## Validates: Requirements 3.4
## For any cone attack (0 to N targets), cooldown should be applied
func test_cooldown_applied_after_attack() -> void:
	var rng := RandomNumberGenerator.new()
	
	assert_property_holds("Cooldown applied after attack", func(seed: int) -> Dictionary:
		rng.seed = seed
		
		# Position attacker
		attacker.position = Vector3.ZERO
		attacker.rotation.y = 0
		
		# Create random number of enemies (0-5) within cone
		var num_enemies := rng.randi_range(0, 5)
		var enemies: Array[Node3D] = []
		
		for i in range(num_enemies):
			var angle := random_float(rng, -40, 40)
			var distance := random_float(rng, 0.5, 2.5)
			var angle_rad := deg_to_rad(angle)
			var target_pos := attacker.position + Vector3(
				sin(angle_rad) * distance,
				0,
				-cos(angle_rad) * distance
			)
			
			var enemy := _create_enemy(target_pos)
			enemies.append(enemy)
		
		# Ensure attack is ready before test
		attacker_combat._cooldown_timer = 0.0
		
		# Perform cone attack
		var hit_targets := attacker_combat.attack_cone()
		
		# Check cooldown is applied
		var cooldown_applied := not attacker_combat.is_attack_ready()
		var cooldown_value := attacker_combat.get_cooldown_remaining()
		var cooldown_correct := cooldown_value > 0.0
		
		# Clean up enemies
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.remove_from_group("enemies")  # Remove from group immediately
				enemy.queue_free()
		
		return {
			"success": cooldown_applied and cooldown_correct,
			"input": "num_targets=%d, hit=%d" % [num_enemies, hit_targets.size()],
			"reason": "Cooldown applied: %s, Cooldown value: %.2f" % [cooldown_applied, cooldown_value]
		}
	)
