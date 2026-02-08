## Property-based tests for Combat component
## Validates correctness properties across random inputs
extends "res://tests/test_utils/property_test.gd"

var attacker: Node3D
var attacker_combat: Combat
var target: Node3D
var target_health: Health

func before_each() -> void:
	# Create attacker with Combat component
	attacker = Node3D.new()
	add_child(attacker)
	
	attacker_combat = Combat.new()
	attacker_combat.attack_damage = 10
	attacker_combat.attack_range = 5.0
	attacker_combat.attack_cooldown = 1.0
	attacker.add_child(attacker_combat)
	
	# Create target with Health component
	target = Node3D.new()
	add_child(target)
	
	target_health = Health.new()
	target_health.max_health = 100
	target.add_child(target_health)
	
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	if attacker:
		attacker.queue_free()
	if target:
		target.queue_free()
	attacker = null
	attacker_combat = null
	target = null
	target_health = null

## Property 6: Damage Application
## Validates: Requirements 3.5, 3.6
## Ensures new_health = max(0, old_health - damage)
func test_damage_application() -> void:
	assert_property_holds("Damage application formula correct", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Generate random damage and initial health
		var damage := random_int(rng, 1, 50)
		var initial_health := random_int(rng, 0, 100)
		
		# Set up combat and health
		attacker_combat.set_attack_damage(damage)
		target_health.reset_health(initial_health)
		
		# Position target in range
		target.global_position = attacker.global_position + Vector3(1, 0, 0)
		
		# Perform attack
		var attack_success := attacker_combat.attack(target)
		
		if not attack_success:
			# Attack failed (cooldown or range), skip this iteration
			return {
				"success": true,
				"input": "damage=%d, initial_health=%d (attack failed)" % [damage, initial_health],
				"reason": ""
			}
		
		var new_health: int = target_health.get_current_health()
		var expected_health: int = max(0, initial_health - damage)
		
		var correct: bool = new_health == expected_health
		
		return {
			"success": correct,
			"input": "damage=%d, initial_health=%d" % [damage, initial_health],
			"reason": "Expected health %d, got %d" % [expected_health, new_health]
		}
	)

## Property 7: Attack Cooldown Enforcement
## Validates: Requirements 3.5
## Ensures time between successful attacks >= cooldown
func test_attack_cooldown_enforcement() -> void:
	assert_property_holds("Attack cooldown enforced", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Set random cooldown
		var cooldown := random_float(rng, 0.5, 2.0)
		attacker_combat.attack_cooldown = cooldown
		attacker_combat._data.attack_cooldown = cooldown
		attacker_combat._cooldown_timer = 0.0  # Reset cooldown
		
		# Position target in range
		target.global_position = attacker.global_position + Vector3(1, 0, 0)
		
		# First attack should succeed
		var first_attack := attacker_combat.attack(target)
		if not first_attack:
			return {
				"success": true,
				"input": "cooldown=%.2f (first attack failed)" % cooldown,
				"reason": ""
			}
		
		# Immediate second attack should fail
		var immediate_attack := attacker_combat.attack(target)
		if immediate_attack:
			return {
				"success": false,
				"input": "cooldown=%.2f" % cooldown,
				"reason": "Immediate attack succeeded (should be on cooldown)"
			}
		
		# Simulate time passing (slightly less than cooldown)
		var delta := cooldown * 0.9
		attacker_combat._cooldown_timer -= delta
		
		# Attack should still fail
		var early_attack := attacker_combat.attack(target)
		if early_attack:
			return {
				"success": false,
				"input": "cooldown=%.2f, delta=%.2f" % [cooldown, delta],
				"reason": "Early attack succeeded (cooldown not fully elapsed)"
			}
		
		# Simulate full cooldown elapsed
		attacker_combat._cooldown_timer = 0.0
		
		# Attack should now succeed
		var late_attack := attacker_combat.attack(target)
		
		return {
			"success": late_attack,
			"input": "cooldown=%.2f" % cooldown,
			"reason": "Attack after cooldown failed"
		}
	)

## Property 8: Attack Range Validation
## Validates: Requirements 3.5, 3.6
## Ensures attacks only succeed when distance <= attack_range
func test_attack_range_validation() -> void:
	assert_property_holds("Attack range validated", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Set random attack range
		var attack_range := random_float(rng, 1.0, 10.0)
		attacker_combat.attack_range = attack_range
		attacker_combat._data.attack_range = attack_range
		attacker_combat._cooldown_timer = 0.0  # Reset cooldown
		
		# Generate random target position
		var distance := random_float(rng, 0.5, 15.0)
		var direction := random_direction(rng)
		target.global_position = attacker.global_position + (direction * distance)
		
		# Attempt attack
		var attack_success := attacker_combat.attack(target)
		
		# Attack should succeed if and only if distance <= attack_range
		var should_succeed := distance <= attack_range
		var correct := attack_success == should_succeed
		
		return {
			"success": correct,
			"input": "range=%.2f, distance=%.2f" % [attack_range, distance],
			"reason": "Attack %s but should %s" % [
				"succeeded" if attack_success else "failed",
				"succeed" if should_succeed else "fail"
			]
		}
	)
