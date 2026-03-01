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
	
	# Run multiple iterations manually since we need await
	for seed in range(10):  # Reduced iterations since we need await
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create a test door
		var test_door: Door = door_scene.instantiate() as Door
		if not test_door:
			fail_test("Failed to instantiate door from scene (seed=%d)" % seed)
			return
		
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
		assert_eq(stored_initial_state, initial_state, "Initial state should be stored (seed=%d)" % seed)
		
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
		assert_eq(stored_new_state, target_state, "New state should be stored (seed=%d)" % seed)
		
		# Unregister door
		DoorManager.unregister_door(test_door)


## Property 19: State Stability During Navigation
## Validates: Requirements 6.2
## For any set of doors with arbitrary states, when the player moves between rooms,
## all door states should remain unchanged
func test_state_stability_during_navigation() -> void:
	# Feature: interactive-doors, Property 19: State Stability During Navigation
	
	# Run multiple iterations manually since we need await
	for seed in range(10):
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
		for door in doors:
			var current_state: bool = DoorManager.get_door_state(door.door_id)
			var expected_state: bool = initial_states[door.door_id]
			assert_eq(current_state, expected_state, "Door state should remain stable (seed=%d, door=%s)" % [seed, door.door_id])
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)


## Property 20: Initial State Consistency
## Validates: Requirements 6.3
## For any newly loaded dungeon, all doors should initialize in the closed state
func test_initial_state_consistency() -> void:
	# Feature: interactive-doors, Property 20: Initial State Consistency
	
	# Run multiple iterations manually since we need await
	for seed in range(10):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		
		# Create multiple test doors
		var num_doors: int = rng.randi_range(2, 5)
		var doors: Array[Door] = []
		
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
			assert_false(test_door.is_open, "New door should be closed (seed=%d, door=%d)" % [seed, i])
		
		# Wait for registration
		await get_tree().process_frame
		
		# Verify all doors are stored as closed in DoorManager
		for door in doors:
			var stored_state: bool = DoorManager.get_door_state(door.door_id)
			assert_false(stored_state, "Stored state should be closed (seed=%d, door=%s)" % [seed, door.door_id])
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)


## Property 21: Save/Load Round Trip
## Validates: Requirements 6.4, 6.5
## For any set of door states, saving the game and then loading it should restore
## all door states to their exact values before the save
func test_save_load_round_trip() -> void:
	# Feature: interactive-doors, Property 21: Save/Load Round Trip
	
	# Run multiple iterations manually since we need await
	for seed in range(10):
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
		assert_true(save_data.has("doors"), "Save data should have 'doors' key (seed=%d)" % seed)
		
		# Modify door states (toggle all doors)
		for door in doors:
			door.is_open = not door.is_open
		
		# Wait for state changes
		await get_tree().process_frame
		
		# Load saved states
		DoorManager.load_door_states(save_data)
		
		# Wait for load to complete
		await get_tree().process_frame
		
		# Verify all states match original states
		for door in doors:
			var restored_state: bool = DoorManager.get_door_state(door.door_id)
			var original_state: bool = original_states[door.door_id]
			assert_eq(restored_state, original_state, "State should be restored (seed=%d, door=%s)" % [seed, door.door_id])
		
		# Cleanup
		for door in doors:
			DoorManager.unregister_door(door)
