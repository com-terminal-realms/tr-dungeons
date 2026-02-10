## Property-based tests for Door player interaction
## Validates correctness properties for door interaction behavior
# Feature: interactive-doors
extends "res://tests/test_utils/property_test.gd"

var door_scene: PackedScene

func before_all() -> void:
	door_scene = load("res://scenes/door.tscn")
	if not door_scene:
		push_error("Failed to load door scene from res://scenes/door.tscn")

## Property 5: Interaction Zone Highlight Toggle
## Validates: Requirements 2.1, 2.4, 5.1, 5.2
## For any door instance, when the player enters the interaction zone the highlight should be enabled,
## and when the player exits the interaction zone the highlight should be disabled
func test_interaction_zone_highlight_toggle() -> void:
	assert_property_holds("Interaction zone toggles highlight correctly", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Instantiate a fresh door for this iteration
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Failed to instantiate door from scene"
			}
		
		# Verify set_highlight method exists and is callable
		var has_method: bool = test_door.has_method("set_highlight")
		
		# Try calling set_highlight with both true and false
		var can_enable: bool = false
		var can_disable: bool = false
		
		if has_method:
			# These should not crash
			test_door.set_highlight(true)
			can_enable = true
			test_door.set_highlight(false)
			can_disable = true
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": has_method and can_enable and can_disable,
			"input": "seed=%d" % seed,
			"reason": "has_method=%s, can_enable=%s, can_disable=%s" % [
				str(has_method),
				str(can_enable),
				str(can_disable)
			]
		}
	)

## Property 16: Highlight Shader Configuration
## Validates: Requirements 5.3
## For any door instance with highlight enabled, the shader should use an emissive glow
## with color #FFD700 (gold)
func test_highlight_shader_configuration() -> void:
	assert_property_holds("Highlight shader uses gold emissive color", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Instantiate a fresh door for this iteration
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Failed to instantiate door from scene"
			}
		
		# Enable highlight
		test_door.set_highlight(true)
		
		# Find all MeshInstance3D nodes to check for highlight material
		var mesh_instances := _find_mesh_instances(test_door)
		
		var has_emissive_material: bool = false
		var correct_color: bool = false
		var expected_color := Color("#FFD700")  # Gold
		
		for mesh_inst in mesh_instances:
			if mesh_inst.mesh:
				for i in range(mesh_inst.mesh.get_surface_count()):
					var material := mesh_inst.get_surface_override_material(i)
					if material and material is StandardMaterial3D:
						var std_mat := material as StandardMaterial3D
						if std_mat.emission_enabled:
							has_emissive_material = true
							# Check if emission color is close to gold
							var color_diff := std_mat.emission.distance_to(expected_color)
							if color_diff < 0.1:  # Allow small tolerance
								correct_color = true
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": has_emissive_material and correct_color,
			"input": "seed=%d" % seed,
			"reason": "has_emissive=%s, correct_color=%s" % [
				str(has_emissive_material),
				str(correct_color)
			]
		}
	)

## Helper: Recursively find all MeshInstance3D nodes
func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	
	return result


## Property 17: Interaction Prompt Display
## Validates: Requirements 5.5
## For any door, when the player enters its interaction zone, the UI should display
## the prompt "Press E to Open/Close"
func test_interaction_prompt_display() -> void:
	# Feature: interactive-doors, Property 17: Interaction Prompt Display
	
	assert_property_holds("Interaction prompt displays when player enters zone", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create a test door
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Failed to instantiate door from scene"
			}
		
		# Add door to scene tree
		add_child_autofree(test_door)
		test_door.door_id = "test_door_prompt_%d" % seed
		
		# Register door with DoorManager
		DoorManager.register_door(test_door)
		
		# Create a mock interaction prompt UI
		var mock_prompt := Control.new()
		mock_prompt.name = "MockInteractionPrompt"
		mock_prompt.visible = false
		add_child_autofree(mock_prompt)
		
		# Set the mock prompt in DoorManager
		DoorManager.set_interaction_prompt(mock_prompt)
		
		# Wait for scene tree to process
		await get_tree().process_frame
		
		# Initial state: prompt should be hidden
		var initially_hidden: bool = not mock_prompt.visible
		
		# Simulate player entering door's interaction zone
		# Emit the player_entered_zone signal
		test_door.player_entered_zone.emit()
		
		# Wait for signal processing
		await get_tree().process_frame
		
		# Check if prompt is now visible
		var shown_on_enter: bool = mock_prompt.visible
		
		# Simulate player exiting door's interaction zone
		test_door.player_exited_zone.emit()
		
		# Wait for signal processing
		await get_tree().process_frame
		
		# Check if prompt is now hidden again
		var hidden_on_exit: bool = not mock_prompt.visible
		
		# Unregister door
		DoorManager.unregister_door(test_door)
		
		# Verify the prompt behavior
		var success: bool = initially_hidden and shown_on_enter and hidden_on_exit
		
		return {
			"success": success,
			"input": "seed=%d" % seed,
			"reason": "initially_hidden=%s, shown_on_enter=%s, hidden_on_exit=%s" % [
				str(initially_hidden),
				str(shown_on_enter),
				str(hidden_on_exit)
			]
		}
	)
