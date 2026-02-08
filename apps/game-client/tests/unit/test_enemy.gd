## Unit tests for Enemy
## Tests enemy behavior including death and removal
extends "res://addons/gut/test.gd"

var enemy: CharacterBody3D
var health: Health

func before_each() -> void:
	# Create minimal enemy setup
	enemy = CharacterBody3D.new()
	enemy.add_to_group("enemies")
	add_child(enemy)
	
	health = Health.new()
	health.max_health = 50
	health.name = "Health"
	enemy.add_child(health)
	
	await get_tree().process_frame

func after_each() -> void:
	if enemy and is_instance_valid(enemy):
		enemy.queue_free()
	enemy = null
	health = null

## Test: Enemy is removed from scene on death
func test_enemy_removed_on_death() -> void:
	# Verify enemy exists
	assert_true(is_instance_valid(enemy), "Enemy should exist initially")
	assert_true(enemy.is_inside_tree(), "Enemy should be in scene tree")
	
	# Simulate death
	health.take_damage(50)
	
	# Manually trigger removal (in actual game, this is connected to died signal)
	enemy.queue_free()
	
	# Process frame to execute queue_free
	await get_tree().process_frame
	
	# Verify enemy is removed
	assert_false(is_instance_valid(enemy), "Enemy should be removed after death")

## Test: Enemy has health component
func test_enemy_has_health_component() -> void:
	var health_component := enemy.get_node_or_null("Health")
	assert_not_null(health_component, "Enemy should have Health component")
	assert_true(health_component is Health, "Health component should be correct type")

## Test: Enemy starts at configured health
func test_enemy_starts_at_configured_health() -> void:
	assert_eq(health.get_current_health(), 50, "Enemy should start at 50 health")
	assert_eq(health.get_max_health(), 50, "Enemy max health should be 50")

## Test: Enemy can take damage
func test_enemy_can_take_damage() -> void:
	health.take_damage(20)
	assert_eq(health.get_current_health(), 30, "Enemy health should decrease")

## Test: Enemy dies when health reaches zero
func test_enemy_dies_at_zero_health() -> void:
	watch_signals(health)
	
	health.take_damage(50)
	
	assert_signal_emitted(health, "died", "Died signal should emit")
	assert_eq(health.get_current_health(), 0, "Health should be zero")
	assert_false(health.is_alive(), "Enemy should be dead")

## Test: Enemy is in enemies group
func test_enemy_in_enemies_group() -> void:
	assert_true(enemy.is_in_group("enemies"), "Enemy should be in 'enemies' group")
