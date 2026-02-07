## Property-based testing harness for GoDot
## Provides utilities for running property tests with random inputs
class_name PropertyTest
extends "res://addons/gut/test.gd"

const ITERATIONS: int = 100  # Minimum iterations per property

## Run a property test with multiple random inputs
## property_name: Name of the property being tested
## test_func: Callable that takes iteration number and returns result dict
func assert_property(property_name: String, test_func: Callable) -> void:
	var failures: Array = []
	
	for i in range(ITERATIONS):
		var result: Dictionary = test_func.call(i)
		if not result.get("success", false):
			failures.append({
				"iteration": i,
				"input": result.get("input", "unknown"),
				"reason": result.get("reason", "no reason provided")
			})
	
	if failures.size() > 0:
		var msg: String = "Property '%s' failed %d/%d times:\n" % [property_name, failures.size(), ITERATIONS]
		for failure in failures.slice(0, min(5, failures.size())):  # Show first 5 failures
			msg += "  Iteration %d: %s (input: %s)\n" % [failure.iteration, failure.reason, failure.input]
		fail_test(msg)
	else:
		pass_test("Property '%s' passed %d iterations" % [property_name, ITERATIONS])

## Generate random Vector3 within range
func random_vector3(rng: RandomNumberGenerator, min_val: float, max_val: float) -> Vector3:
	return Vector3(
		rng.randf_range(min_val, max_val),
		rng.randf_range(min_val, max_val),
		rng.randf_range(min_val, max_val)
	)

## Generate random integer within range
func random_int(rng: RandomNumberGenerator, min_val: int, max_val: int) -> int:
	return rng.randi_range(min_val, max_val)

## Generate random float within range
func random_float(rng: RandomNumberGenerator, min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)

## Generate random boolean
func random_bool(rng: RandomNumberGenerator) -> bool:
	return rng.randi() % 2 == 0

## Generate random normalized direction vector
func random_direction(rng: RandomNumberGenerator) -> Vector3:
	var dir: Vector3 = random_vector3(rng, -1.0, 1.0)
	return dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
