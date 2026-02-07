## Property tests for scene structure validation
## **Property 15: Component Presence Validation**
## **Validates: Requirements 3.4, 3.5, 3.6, 3.8**
extends GutTest

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemies/enemy_base.tscn")

## Property 15: Component Presence Validation
## Verify Player and Enemy scenes contain required components
func test_property_15_component_presence_validation() -> void:
	var iterations := 10
	
	for i in range(iterations):
		# Test Player scene
		var player := PLAYER_SCENE.instantiate()
		add_child_autofree(player)
		
		# Verify Player has required components
		var player_health := _find_component(player, "Health")
		var player_movement := _find_component(player, "Movement")
		var player_combat := _find_component(player, "Combat")
		
		assert_not_null(player_health, "Player must have Health component (iteration %d)" % i)
		assert_not_null(player_movement, "Player must have Movement component (iteration %d)" % i)
		assert_not_null(player_combat, "Player must have Combat component (iteration %d)" % i)
		
		# Test Enemy scene
		var enemy := ENEMY_SCENE.instantiate()
		add_child_autofree(enemy)
		
		# Verify Enemy has required components
		var enemy_health := _find_component(enemy, "Health")
		var enemy_movement := _find_component(enemy, "Movement")
		var enemy_combat := _find_component(enemy, "Combat")
		var enemy_ai := _find_component(enemy, "EnemyAI")
		
		assert_not_null(enemy_health, "Enemy must have Health component (iteration %d)" % i)
		assert_not_null(enemy_movement, "Enemy must have Movement component (iteration %d)" % i)
		assert_not_null(enemy_combat, "Enemy must have Combat component (iteration %d)" % i)
		assert_not_null(enemy_ai, "Enemy must have EnemyAI component (iteration %d)" % i)

## Find component by name in node's children
func _find_component(node: Node, component_name: String) -> Node:
	for child in node.get_children():
		if child.name == component_name:
			return child
	return null
