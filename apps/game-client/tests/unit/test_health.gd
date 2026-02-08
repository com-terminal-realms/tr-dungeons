## Unit tests for Health component
## Tests specific examples and edge cases
extends "res://addons/gut/test.gd"

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

## Test: Negative damage amount should error
func test_negative_damage_errors() -> void:
	# Capture error output
	var initial_health := health.get_current_health()
	
	health.take_damage(-10)
	
	# Assert that the expected error was pushed
	assert_push_error("Damage amount must be non-negative")
	
	# Health should remain unchanged
	assert_eq(health.get_current_health(), initial_health, "Health should not change on negative damage")

## Test: Negative heal amount should error
func test_negative_heal_errors() -> void:
	# Take some damage first
	health.take_damage(30)
	var damaged_health := health.get_current_health()
	
	health.heal(-10)
	
	# Assert that the expected error was pushed
	assert_push_error("Heal amount must be non-negative")
	
	# Health should remain unchanged
	assert_eq(health.get_current_health(), damaged_health, "Health should not change on negative heal")

## Test: Damage exceeding current health should clamp to 0
func test_damage_exceeds_current_health() -> void:
	health.take_damage(150)  # More than max_health
	
	assert_eq(health.get_current_health(), 0, "Health should clamp to 0")
	assert_false(health.is_alive(), "Entity should be dead")

## Test: Healing above max health should clamp to max
func test_heal_above_max_health() -> void:
	health.take_damage(30)  # Reduce to 70
	health.heal(50)  # Try to heal to 120
	
	assert_eq(health.get_current_health(), health.get_max_health(), "Health should clamp to max_health")

## Test: Died signal emits exactly once
func test_died_signal_emits_once() -> void:
	watch_signals(health)
	
	# Kill the entity multiple times
	health.take_damage(100)
	health.take_damage(50)
	health.take_damage(25)
	
	assert_signal_emitted(health, "died", "Died signal should emit")
	assert_signal_emit_count(health, "died", 1, "Died signal should emit exactly once")

## Test: Cannot heal when dead
func test_cannot_heal_when_dead() -> void:
	health.take_damage(100)  # Kill entity
	assert_false(health.is_alive(), "Entity should be dead")
	
	health.heal(50)
	
	assert_eq(health.get_current_health(), 0, "Dead entity should remain at 0 health")
	assert_false(health.is_alive(), "Dead entity should remain dead")

## Test: Cannot take damage when dead (no additional died signals)
func test_cannot_damage_when_dead() -> void:
	watch_signals(health)
	
	health.take_damage(100)  # Kill entity
	health.take_damage(50)   # Try to damage again
	
	assert_signal_emitted(health, "died", "Died signal should emit")
	assert_signal_emit_count(health, "died", 1, "Died signal should only emit once")
	assert_eq(health.get_current_health(), 0, "Health should remain at 0")

## Test: Health initialized correctly
func test_health_initialized() -> void:
	assert_eq(health.get_current_health(), 100, "Current health should equal max_health on init")
	assert_eq(health.get_max_health(), 100, "Max health should be set correctly")
	assert_true(health.is_alive(), "Entity should be alive on init")

## Test: health_changed signal emits on damage
func test_health_changed_on_damage() -> void:
	watch_signals(health)
	health.take_damage(25)
	
	assert_signal_emitted(health, "health_changed", "health_changed should emit on damage")
	assert_signal_emit_count(health, "health_changed", 1, "health_changed should emit exactly once")
	
	# Check signal parameters
	var signal_params: Array = get_signal_parameters(health, "health_changed", 0)
	assert_eq(signal_params[0], 75, "Signal should report correct current health")
	assert_eq(signal_params[1], 100, "Signal should report correct max health")

## Test: health_changed signal emits on heal
func test_health_changed_on_heal() -> void:
	health.take_damage(40)  # Reduce to 60
	
	watch_signals(health)
	health.heal(20)
	
	assert_signal_emitted(health, "health_changed", "health_changed should emit on heal")
	
	# Check signal parameters
	var signal_params: Array = get_signal_parameters(health, "health_changed", 0)
	assert_eq(signal_params[0], 80, "Signal should report correct current health")

## Test: Data model serialization
func test_data_serialization() -> void:
	health.take_damage(30)
	
	var data := health.get_data()
	var dict := data.to_dict()
	
	assert_eq(dict["max_health"], 100, "Serialized max_health should be correct")
	assert_eq(dict["current_health"], 70, "Serialized current_health should be correct")
	
	# Test deserialization
	var new_data := HealthData.from_dict(dict)
	assert_eq(new_data.max_health, 100, "Deserialized max_health should be correct")
	assert_eq(new_data.current_health, 70, "Deserialized current_health should be correct")

## Test: Data model validation
func test_data_validation() -> void:
	var invalid_data := HealthData.new({"max_health": -10, "current_health": 50})
	var validation := invalid_data.validate()
	
	assert_false(validation["valid"], "Invalid data should fail validation")
	assert_gt(validation["errors"].size(), 0, "Validation should report errors")
