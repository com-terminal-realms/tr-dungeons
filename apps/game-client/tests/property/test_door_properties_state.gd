## Property-based tests for Door state persistence
## Validates correctness properties for door state management and persistence
# Feature: interactive-doors
extends "res://tests/test_utils/property_test.gd"

var door_scene: PackedScene

func before_all() -> void:
	door_scene = load("res://scenes/door.tscn")
	if not door_scene:
		push_error("Failed to load door scene from res://scenes/door.tscn")


## Property 18: State Storage on Change
## Validates: Requirements 6.1
## For any door that changes state, the DoorManager should immediately store
## the new state in its internal state dictionary
func test_state_storage_on_change() -> void:
	# Feature: interactive-doors, Property 18: State Storage on Change
	
	assert_property_holds("DoorManager stores state immediately on change", func(seed: int) -> Dictionary:
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
		test_door.door_id = "test_door_state_%d" % seed
		
		# Set initial state (randomly open or closed)
		var initial_state: bool = rng.randf() > 0.5
		test_door.is_open = initial_state
		
		# Register door with DoorManager
		DoorManager.register_door(test_door)
		
		# Wait for registration to complete
		await get_tree().process_frame
		
		# Verify initial state is stored
		var stored_initial_state: bool = DoorManager.get_door_state(test_door.door_id)
		var initial_state_matches: bool = (stored_initial_state == initial_state)
		
		# Change door state by toggling
		var target_state: bool = not initial_state
		if target_state:
			test_door.open()
		else:
			test_door.close()
		
		# Wait for state change to process
		await get_tree().process_frame
		
		# Verify new state is stored immediately
		var stored_new_state: bool = DoorManager.get_door_state(test_door.door_id)
		var new_state_matches: bool = (stored_new_state == target_state)
		
		# Unregister door
		DoorManager.unregister_door(test_door)
		
		var success: bool = initial_state_matches and new_state_matches
		
		return {
			"success": success,
			"input": "seed=%d, initial=%s, target=%s" % [seed, str(initial_state), str(target_state)],
			"reason": "initial_matches=%s, new_matches=%s" % [
				str(initial_state_matches),
				str(new_state_matches)
			]
		}
	)


## Property 19: State Stability During Navigation
## Validates: Requirements 6.2
## For any set of doors with arbitrary states, when the player moves between rooms,
## all door states should remain unchanged
func test_state_stability_during_navigation() -> void:
	# Feature: interactive-doors, Property 19: State Stability During Navigation
	
	assert_property_holds("Door states remain stable during player movement", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create multiple test doors with random states
		var num_doors: int = rng.randi_range(2, 5)
		var doors: Array[Door] = []
		var initial_states: Dictionary = {}
		
		for i in range(num_doors):
			var test_door: Door = door_scene.instantiate() as Door
			if not test_door:
				continue
			
			add_child_autofree(test_door)
			test_door.door_id = "test_door_nav_%d_%d" % [seed, i]
			
			# Set random initial state
			var initial_state: bool = rng.randf() > 0.5
			test_door.is_open = initial_state
			initial_states[test_door.door_id] = initial_state
			
			# Register door
			DoorManager.register_door(test_door)
			doors.append(test_door)
		
		# Wait for registration
		await get_tree().process_frame
		
		# Simulate player navigation by waiting several frames
		# (In real game, player would be moving between rooms)
		for _frame in range(10):
			await get_tree().process_frame
		
		# Verify all door states remain unchanged
		var all_states_stable: bool = true
		for door in doors:
			var current_state: bool = DoorManager.get_door_state(door.door_id)
			var expected_state: bool = initial_states[door.door_id]
			if current_state != expected_state:
				all_states_stable = false
				break
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)
		
		return {
			"success": all_states_stable,
			"input": "seed=%d, num_doors=%d" % [seed, num_doors],
			"reason": "all_states_stable=%s" % str(all_states_stable)
		}
	)


## Property 20: Initial State Consistency
## Validates: Requirements 6.3
## For any newly loaded dungeon, all doors should initialize in the closed state
func test_initial_state_consistency() -> void:
	# Feature: interactive-doors, Property 20: Initial State Consistency
	
	assert_property_holds("All new doors initialize in closed state", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create multiple test doors
		var num_doors: int = rng.randi_range(2, 5)
		var doors: Array[Door] = []
		var all_closed: bool = true
		
		for i in range(num_doors):
			var test_door: Door = door_scene.instantiate() as Door
			if not test_door:
				continue
			
			add_child_autofree(test_door)
			test_door.door_id = "test_door_init_%d_%d" % [seed, i]
			
			# Don't set is_open - let it use default value
			# Register door (this simulates door placement in new dungeon)
			DoorManager.register_door(test_door)
			doors.append(test_door)
			
			# Check if door is closed
			if test_door.is_open:
				all_closed = false
		
		# Wait for registration
		await get_tree().process_frame
		
		# Verify all doors are stored as closed in DoorManager
		var all_stored_closed: bool = true
		for door in doors:
			var stored_state: bool = DoorManager.get_door_state(door.door_id)
			if stored_state:  # If true (open), then not all are closed
				all_stored_closed = false
				break
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)
		
		var success: bool = all_closed and all_stored_closed
		
		return {
			"success": success,
			"input": "seed=%d, num_doors=%d" % [seed, num_doors],
			"reason": "all_closed=%s, all_stored_closed=%s" % [
				str(all_closed),
				str(all_stored_closed)
			]
		}
	)


## Property 21: Save/Load Round Trip
## Validates: Requirements 6.4, 6.5
## For any set of door states, saving the game and then loading it should restore
## all door states to their exact values before the save
func test_save_load_round_trip() -> void:
	# Feature: interactive-doors, Property 21: Save/Load Round Trip
	
	assert_property_holds("Save/load preserves all door states", func(seed: int) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create multiple test doors with random states
		var num_doors: int = rng.randi_range(2, 5)
		var doors: Array[Door] = []
		var original_states: Dictionary = {}
		
		for i in range(num_doors):
			var test_door: Door = door_scene.instantiate() as Door
			if not test_door:
				continue
			
			add_child_autofree(test_door)
			test_door.door_id = "test_door_save_%d_%d" % [seed, i]
			
			# Set random state
			var random_state: bool = rng.randf() > 0.5
			test_door.is_open = random_state
			original_states[test_door.door_id] = random_state
			
			# Register door
			DoorManager.register_door(test_door)
			doors.append(test_door)
		
		# Wait for registration
		await get_tree().process_frame
		
		# Save door states
		var save_data: Dictionary = DoorManager.save_door_states()
		
		# Verify save data has "doors" key
		var has_doors_key: bool = save_data.has("doors")
		if not has_doors_key:
			# Cleanup
			for door in doors:
				DoorManager.unregister_door(door)
			
			return {
				"success": false,
				"input": "seed=%d" % seed,
				"reason": "Save data missing 'doors' key"
			}
		
		# Modify door states (toggle all doors)
		for door in doors:
			door.is_open = not door.is_open
		
		# Wait for state changes
		await get_tree().process_frame
		
		# Verify states are different now
		var states_changed: bool = false
		for door in doors:
			var current_state: bool = DoorManager.get_door_state(door.door_id)
			var original_state: bool = original_states[door.door_id]
			if current_state != original_state:
				states_changed = true
				break
		
		# Load saved states
		DoorManager.load_door_states(save_data)
		
		# Wait for load to complete
		await get_tree().process_frame
		
		# Verify all states match original states
		var all_states_restored: bool = true
		for door in doors:
			var restored_state: bool = DoorManager.get_door_state(door.door_id)
			var original_state: bool = original_states[door.door_id]
			if restored_state != original_state:
				all_states_restored = false
				break
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)
		
		var success: bool = has_doors_key and states_changed and all_states_restored
		
		return {
			"success": success,
			"input": "seed=%d, num_doors=%d" % [seed, num_doors],
			"reason": "has_doors_key=%s, states_changed=%s, all_restored=%s" % [
				str(has_doors_key),
				str(states_changed),
				str(all_states_restored)
			]
		}
	)
