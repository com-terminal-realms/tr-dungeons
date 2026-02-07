## Integration test for combat flow
## Tests player attacks enemy until death
extends GutTest

var player: CharacterBody3D
var enemy: CharacterBody3D
var player_combat: Node
var enemy_health: Node

func before_each() -> void:
	# Load player scene
	var player_scene = load("res://scenes/player/player.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3.ZERO
	
	# Load enemy scene
	var enemy_scene = load("res://scenes/enemies/enemy_base.tscn")
	enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = Vector3(1, 0, 0)  # Within attack range
	
	# Get components
	player_combat = player.get_node("Combat")
	enemy_health = enemy.get_node("Health")
	
	# Wait for nodes to be ready
	await get_tree().process_frame

func after_each() -> void:
	if player:
		player.queue_free()
	if enemy:
		enemy.queue_free()

func test_player_attacks_enemy_until_death() -> void:
	# Verify initial state
	assert_not_null(player_combat, "Player should have Combat component")
	assert_not_null(enemy_health, "Enemy should have Health component")
	assert_eq(enemy_health.get_current_health(), 50, "Enemy should start with 50 HP")
	
	# Track death signal
	var death_signaled := false
	enemy_health.died.connect(func(): death_signaled = true)
	
	# Attack enemy 5 times (50 HP / 10 damage = 5 attacks)
	for i in range(5):
		var success := player_combat.attack(enemy)
		assert_true(success, "Attack %d should succeed" % (i + 1))
		
		# Wait for cooldown
		await get_tree().create_timer(1.1).timeout
	
	# Verify enemy died
	assert_true(death_signaled, "Enemy should have emitted died signal")
	assert_eq(enemy_health.get_current_health(), 0, "Enemy should have 0 HP")
	assert_false(enemy_health.is_alive(), "Enemy should not be alive")

func test_damage_application() -> void:
	# Verify damage is applied correctly
	var initial_hp := enemy_health.get_current_health()
	
	player_combat.attack(enemy)
	await get_tree().process_frame
	
	var expected_hp := initial_hp - 10
	assert_eq(enemy_health.get_current_health(), expected_hp, 
		"Enemy should have %d HP after taking 10 damage" % expected_hp)

func test_attack_cooldown() -> void:
	# First attack should succeed
	var success1 := player_combat.attack(enemy)
	assert_true(success1, "First attack should succeed")
	
	# Immediate second attack should fail (cooldown)
	var success2 := player_combat.attack(enemy)
	assert_false(success2, "Second attack should fail due to cooldown")
	
	# Wait for cooldown
	await get_tree().create_timer(1.1).timeout
	
	# Third attack should succeed
	var success3 := player_combat.attack(enemy)
	assert_true(success3, "Third attack should succeed after cooldown")

func test_enemy_removal_on_death() -> void:
	# Get enemy parent
	var enemy_parent := enemy.get_parent()
	var initial_child_count := enemy_parent.get_child_count()
	
	# Kill enemy
	enemy_health.take_damage(50)
	
	# Wait for queue_free to process
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify enemy was removed
	var final_child_count := enemy_parent.get_child_count()
	assert_lt(final_child_count, initial_child_count, 
		"Enemy should be removed from scene after death")
