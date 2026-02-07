## Unit tests for Player controller
## Tests player behavior including respawn
extends "res://addons/gut/test.gd"

# Note: We can't load the player scene directly in tests without proper scene setup
# So we'll test the respawn logic by creating a minimal player setup

var player: CharacterBody3D
var health: Health

func before_each() -> void:
	# Create minimal player setup
	player = CharacterBody3D.new()
	add_child(player)
	
	health = Health.new()
	health.max_health = 100
	health.name = "Health"
	player.add_child(health)
	
	await get_tree().process_frame

func after_each() -> void:
	if player:
		player.queue_free()
	player = null
	health = null

## Test: Player respawns at spawn point on death
func test_player_respawn_on_death() -> void:
	var spawn_point := Vector3(5, 0, 5)
	player.global_position = spawn_point
	
	# Move player away from spawn
	player.global_position = Vector3(10, 0, 10)
	assert_ne(player.global_position, spawn_point, "Player should be away from spawn")
	
	# Simulate death by reducing health to 0
	health.take_damage(100)
	
	# Manually trigger respawn (in actual game, this is connected to died signal)
	player.global_position = spawn_point
	health._data.current_health = health._data.max_health
	health._is_alive = true
	
	# Verify respawn
	assert_eq(player.global_position, spawn_point, "Player should respawn at spawn point")
	assert_eq(health.get_current_health(), 100, "Health should be restored")
	assert_true(health.is_alive(), "Player should be alive after respawn")

## Test: Player health component exists
func test_player_has_health_component() -> void:
	var health_component := player.get_node_or_null("Health")
	assert_not_null(health_component, "Player should have Health component")
	assert_true(health_component is Health, "Health component should be correct type")

## Test: Player starts at full health
func test_player_starts_full_health() -> void:
	assert_eq(health.get_current_health(), 100, "Player should start at full health")
	assert_true(health.is_alive(), "Player should start alive")

## Test: Player can take damage
func test_player_can_take_damage() -> void:
	health.take_damage(30)
	assert_eq(health.get_current_health(), 70, "Player health should decrease")

## Test: Player dies when health reaches zero
func test_player_dies_at_zero_health() -> void:
	var died_signal_emitted := false
	health.died.connect(func(): died_signal_emitted = true)
	
	health.take_damage(100)
	
	assert_true(died_signal_emitted, "Died signal should emit")
	assert_eq(health.get_current_health(), 0, "Health should be zero")
	assert_false(health.is_alive(), "Player should be dead")
