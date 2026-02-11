# Implementation Plan: Cone-Based Melee Combat System

## Overview

This implementation plan converts the existing single-target combat system into a cone-based area-of-effect system. The approach is incremental: first extend the Combat component with cone detection, then update player and enemy behavior, and finally add smart RMB movement. Each step includes property-based tests to validate correctness.

## Tasks

- [x] 1. Extend Combat component with cone detection
  - [x] 1.1 Add cone parameters to Combat component
    - Add `cone_angle` and `cone_range` exported variables
    - Update `CombatData` model with new fields
    - Add validation for cone parameters in `CombatData.validate()`
    - _Requirements: 6.2_
  
  - [x] 1.2 Implement cone detection algorithm
    - Create `_is_target_in_cone(target: Node3D) -> bool` method
    - Calculate angle between attacker forward and target direction
    - Check if angle is within half cone angle
    - Check if distance is within cone range
    - Return true only if both conditions met
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x] 1.3 Implement multi-target detection
    - Create `_get_potential_targets() -> Array[Node3D]` method
    - Determine target group based on attacker group (player vs enemies)
    - Create `_detect_targets_in_cone() -> Array[Node3D]` method
    - Filter potential targets using `_is_target_in_cone()`
    - _Requirements: 1.2_
  
  - [x] 1.4 Implement cone attack method
    - Create `attack_cone() -> Array[Node3D]` method
    - Check if attack is ready (cooldown)
    - Detect all targets in cone
    - Apply damage to each target
    - Start cooldown timer
    - Return array of hit targets
    - _Requirements: 1.1, 3.1, 3.2, 3.3, 3.4_
  
  - [x] 1.5 Write property test for angle boundary correctness
    - **Property 1: Angle Boundary Correctness**
    - Generate random attacker positions and forward directions
    - Generate random target positions
    - Calculate expected angle
    - Verify targets within half cone angle are detected
    - Run 100+ iterations
    - _Requirements: 2.2_
  
  - [x] 1.6 Write property test for distance boundary correctness
    - **Property 2: Distance Boundary Correctness**
    - Generate random attacker and target positions
    - Calculate expected distance
    - Verify targets within cone range are detected
    - Run 100+ iterations
    - _Requirements: 2.3_
  
  - [x] 1.7 Write property test for cone inclusion correctness
    - **Property 3: Cone Inclusion Correctness**
    - Generate random positions where both angle and distance are within bounds
    - Verify all such targets are included in cone attack
    - Run 100+ iterations
    - _Requirements: 2.4_
  
  - [x] 1.8 Write property test for cone exclusion correctness
    - **Property 4: Cone Exclusion Correctness**
    - Generate random positions where either angle or distance is outside bounds
    - Verify all such targets are excluded from cone attack
    - Run 100+ iterations
    - _Requirements: 2.5_

- [x] 2. Update Player to use cone attacks
  - [x] 2.1 Modify player attack handling
    - Update `_handle_attack()` to call `attack_cone()` instead of `attack()`
    - Find nearest enemy in cone to face toward
    - Rotate player to face the nearest enemy
    - Play attack animation
    - Call `attack_cone()` after animation
    - Log number of targets hit
    - _Requirements: 1.1, 8.1_
  
  - [x] 2.2 Update player attack input
    - Ensure LMB triggers cone attack
    - Maintain existing animation blocking during attack
    - _Requirements: 1.1_
  
  - [x] 2.3 Write property test for multi-target damage consistency
    - **Property 5: Multi-Target Damage Consistency**
    - Generate random sets of targets in cone
    - Perform cone attack
    - Verify all targets receive same damage value
    - Verify all targets processed in same attack call
    - Run 100+ iterations
    - _Requirements: 3.1, 3.2_
  
  - [x] 2.4 Write unit test for zero-target attack
    - Create scenario with no targets in cone
    - Perform cone attack
    - Verify attack completes without errors
    - Verify cooldown is applied
    - _Requirements: 3.3_
  
  - [x] 2.5 Write property test for cooldown application
    - **Property 9: Cooldown Applied After Attack**
    - Generate random cone attacks with varying target counts (0 to N)
    - Verify cooldown timer is set after each attack
    - Run 100+ iterations
    - _Requirements: 3.4_

- [x] 3. Checkpoint - Verify cone attacks work for player
  - All property tests passing (7/7)
  - Character model orientation issue resolved:
    - Cone detection uses correct forward direction (-Z)
    - Player rotation during attacks uses normal look_at
    - Player starts facing south (180°) for POC dungeon layout
  - RMB movement enabled and working
  - Debug logging removed

- [x] 4. Implement smart RMB movement
  - [x] 4.1 Add RMB target tracking to Player
    - Add `_rmb_target: Node3D` variable
    - Update `_handle_move_to_click()` to detect enemy clicks
    - Set `_rmb_target` when clicking on enemy
    - Fallback to ground movement for non-enemy clicks
    - _Requirements: 4.1_
  
  - [x] 4.2 Implement move-to-target behavior
    - Update `_physics_process()` to handle RMB target movement
    - Calculate direction to `_rmb_target` if valid
    - Stop movement when within `cone_range` of target
    - Clear `_rmb_target` when stopping
    - _Requirements: 4.2, 4.5_
  
  - [x] 4.3 Implement WASD cancellation
    - Check for WASD input in `_physics_process()`
    - Cancel RMB movement when WASD is pressed
    - Clear `_rmb_target` when cancelling
    - _Requirements: 4.4_
  
  - [x] 4.4 Handle already-in-range case
    - Check if already within range before starting movement
    - Ignore RMB input if already in range
    - _Requirements: 4.3_
  
  - [x] 4.5 Write property test for movement stop at range
    - **Property 6: Movement Stop at Range**
    - Generate random player and target positions
    - Simulate RMB movement toward target
    - Verify movement stops when distance <= cone_range
    - Run 100+ iterations
    - _Requirements: 4.2_
  
  - [x] 4.6 Write property test for WASD cancellation
    - **Property 7: WASD Cancels RMB Movement**
    - Set up active RMB movement
    - Simulate WASD input
    - Verify RMB movement is cancelled
    - Run 100+ iterations
    - _Requirements: 4.4_

- [ ] 5. Update EnemyAI to use cone attacks
  - [ ] 5.1 Modify enemy attack execution
    - Update `_execute_attack()` to call `attack_cone()` instead of `attack()`
    - Face the target before attacking
    - Play attack animation
    - Call `attack_cone()` during attack state
    - Log number of targets hit
    - _Requirements: 1.4, 5.1, 5.2, 8.2_
  
  - [ ] 5.2 Write property test for symmetric cone detection
    - **Property 8: Symmetric Cone Detection**
    - Generate random attacker (player or enemy) and target positions
    - Perform cone detection from both player and enemy perspective
    - Verify same targets detected regardless of attacker type
    - Run 100+ iterations
    - _Requirements: 1.4, 5.1, 5.2_
  
  - [ ] 5.3 Write unit test for multiple simultaneous enemy attacks
    - Create scenario with multiple enemies attacking
    - Verify each enemy's cone attack processes independently
    - Verify no interference between attacks
    - _Requirements: 5.3_

- [ ] 6. Checkpoint - Verify enemies use cone attacks correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Add visual feedback and polish
  - [ ] 7.1 Verify attack effects spawn at target positions
    - Ensure `_spawn_attack_effect()` is called for each hit target
    - Verify effects spawn at correct positions
    - _Requirements: 7.2_
  
  - [ ] 7.2 Write property test for attack effects
    - **Property 10: Attack Effects Spawned at Target Positions**
    - Generate random cone attacks with N targets
    - Verify exactly N attack effects are spawned
    - Verify effects are at correct target positions
    - Run 100+ iterations
    - _Requirements: 7.2_
  
  - [ ] 7.3 Write property test for animation blocking
    - **Property 11: Animation Prevents Concurrent Attacks**
    - Start attack animation
    - Attempt additional attacks while animating
    - Verify additional attacks are blocked
    - Run 100+ iterations
    - _Requirements: 8.3_
  
  - [ ] 7.4 Write integration tests
    - Test full player attack flow (input → animation → damage → effects)
    - Test full enemy attack flow (AI state → animation → damage → effects)
    - Test RMB movement flow (click → move → stop at range)
    - Test WASD cancellation flow (RMB movement → WASD → cancel)

- [ ] 8. Final checkpoint - Complete system verification
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Each property test should run minimum 100 iterations
- Property tests should be tagged with: `# Feature: cone-melee-combat, Property N: <name>`
- Cone parameters: angle = 90 degrees, range = 3.0 units
- The existing `attack()` method can be deprecated but kept for backward compatibility
- All tests should use GUT (Godot Unit Test) framework
