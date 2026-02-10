## Property-based tests for Health component
## Validates correctness properties across random inputs
extends "res://tests/test_utils/property_test.gd"

var health: Health

func before_each() -> void:
	health = Health.new()
	health.max_health = 100
	add_child(health)
	await get_tree().process_frame  # Wait for _ready() to complete

func after_each() -> void:
	if health:
		health.queue_free()
	health = null

## Property 11: Health Bounds Invariant
## Validates: Requirements 3.8
## Ensures current_health always stays within [0, max_health] regardless of damage/heal sequence
func test_health_bounds_invariant() -> void:
	assert_property_holds("Health stays in [0, max_health]", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Reset health to random starting value
		var start_health := random_int(rng, 0, health.get_max_health())
		health.reset_health(start_health)
		
		# Generate random sequence of damage/heal operations
		var operations: Array[String] = []
		for i in range(10):
			if random_bool(rng):
				var damage := random_int(rng, 0, 50)
				health.take_damage(damage)
				operations.append("damage(%d)" % damage)
			else:
				var heal_amount := random_int(rng, 0, 50)
				health.heal(heal_amount)
				operations.append("heal(%d)" % heal_amount)
		
		var current := health.get_current_health()
		var max_hp := health.get_max_health()
		var in_bounds := current >= 0 and current <= max_hp
		
		return {
			"success": in_bounds,
			"input": "start=%d, ops=%s" % [start_health, str(operations)],
			"reason": "Health %d not in [0, %d]" % [current, max_hp]
		}
	)

## Property 12: Health Signal Emission
## Validates: Requirements 3.8
## Ensures health_changed emits on damage/heal and died emits exactly once when health reaches 0
func test_health_signal_emission() -> void:
	assert_property_holds("Health signals emit correctly", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Reset health to random starting value (ensure alive)
		var start_health := random_int(rng, 50, health.get_max_health())
		health.reset_health(start_health)
		
		# Track signal emissions using arrays (captured by reference)
		var health_changed_count := [0]  # Use array for reference capture
		var died_count := [0]  # Use array for reference capture
		
		var health_changed_callback := func(_current: int, _maximum: int) -> void:
			health_changed_count[0] += 1
		
		var died_callback := func() -> void:
			died_count[0] += 1
		
		health.health_changed.connect(health_changed_callback)
		health.died.connect(died_callback)
		
		# Perform operations and track expected emissions
		var expected_health_changed := 0
		var expected_died := 0
		var operations: Array[String] = []
		
		for i in range(5):
			if random_bool(rng):
				var damage := random_int(rng, 10, 30)
				var old_health := health.get_current_health()
				health.take_damage(damage)
				operations.append("damage(%d)" % damage)
				# Damage always emits if entity was alive (even when dying)
				if old_health > 0:
					expected_health_changed += 1
				if health.get_current_health() == 0 and expected_died == 0:
					expected_died = 1
			else:
				var heal_amount := random_int(rng, 5, 20)
				var old_health := health.get_current_health()
				health.heal(heal_amount)
				operations.append("heal(%d)" % heal_amount)
				# Heal only emits if alive AND health actually changed
				if health.is_alive():
					var new_health := min(health.get_max_health(), old_health + heal_amount)
					if new_health != old_health:
						expected_health_changed += 1
		
		# Disconnect signals
		health.health_changed.disconnect(health_changed_callback)
		health.died.disconnect(died_callback)
		
		var signals_correct: bool = (
			health_changed_count[0] == expected_health_changed and
			died_count[0] == expected_died
		)
		
		return {
			"success": signals_correct,
			"input": "start=%d, ops=%s" % [start_health, str(operations)],
			"reason": "Expected health_changed=%d (got %d), died=%d (got %d)" % [
				expected_health_changed, health_changed_count[0],
				expected_died, died_count[0]
			]
		}
	)

