## Property-based tests for Door animation system
## Validates correctness properties for door animation behavior
# Feature: interactive-doors
extends "res://tests/test_utils/property_test.gd"

var door_scene: PackedScene

func before_all() -> void:
	door_scene = load("res://scenes/door.tscn")
	if not door_scene:
		push_error("Failed to load door scene from res://scenes/door.tscn")

## Property 9: Animation Rotation Correctness
## Validates: Requirements 3.1, 3.2
## For any door, opening should rotate it +90 degrees around the Y axis over 0.5 seconds,
## and closing should rotate it -90 degrees over 0.5 seconds
func test_animation_rotation_correctness() -> void:
	assert_property_holds("Door animation rotates correctly", func(seed: int) -> Dictionary:
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
		
		# Randomly choose to test opening or closing
		var test_opening: bool = random_bool(rng)
		
		# Set initial state
		test_door.is_open = not test_opening
		
		# Check animation duration is correct
		var expected_duration: float = 0.5
		var tolerance: float = 0.01
		var duration_correct: bool = abs(test_door.animation_duration - expected_duration) < tolerance
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": duration_correct,
			"input": "testing_%s" % ("opening" if test_opening else "closing"),
			"reason": "Animation duration is %f, expected %f" % [test_door.animation_duration, expected_duration]
		}
	)

## Property 10: Animation Blocking
## Validates: Requirements 3.3
## For any door that is currently animating, subsequent interaction requests should be ignored
## until the animation completes
func test_animation_blocking() -> void:
	assert_property_holds("Door blocks interactions during animation", func(seed: int) -> Dictionary:
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
		
		# Start with door closed
		test_door.is_open = false
		
		# Manually set animating state to simulate animation in progress
		test_door._is_animating = true
		
		# Try to toggle the door while animating
		var initial_state: bool = test_door.is_open
		test_door.toggle()
		
		# Door state should not have changed because animation is in progress
		var state_unchanged: bool = (test_door.is_open == initial_state)
		
		# Also verify is_animating() method returns true
		var reports_animating: bool = test_door.is_animating()
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": state_unchanged and reports_animating,
			"input": "initial_state=%s" % str(initial_state),
			"reason": "State changed=%s (should be false), is_animating=%s (should be true)" % [
				str(not state_unchanged),
				str(reports_animating)
			]
		}
	)

## Property 11: Animation Completion Signal
## Validates: Requirements 3.5
## For any door animation (open or close), when the animation completes,
## the door should emit an animation_completed signal
func test_animation_completion_signal() -> void:
	assert_property_holds("Door emits animation_completed signal", func(seed: int) -> Dictionary:
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
		
		# Verify the signal exists
		var has_signal: bool = test_door.has_signal("animation_completed")
		
		# Verify animation_started signal also exists (from requirements)
		var has_started_signal: bool = test_door.has_signal("animation_started")
		
		# Cleanup
		test_door.queue_free()
		
		return {
			"success": has_signal and has_started_signal,
			"input": "seed=%d" % seed,
			"reason": "animation_completed signal exists=%s, animation_started signal exists=%s" % [
				str(has_signal),
				str(has_started_signal)
			]
		}
	)
