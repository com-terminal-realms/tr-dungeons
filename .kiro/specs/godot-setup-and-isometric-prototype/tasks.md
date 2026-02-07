`# Implementation Plan: GoDot Setup and Isometric 3D Prototype

## Overview

This implementation plan breaks down the GoDot isometric dungeon crawler prototype into discrete, incremental coding tasks. Each task builds on previous work, starting with environment setup, then core components, entity assembly, camera system, AI, room building, and finally integration. Testing tasks are included as sub-tasks to validate functionality early and often.

## Tasks

- [x] 1. Set up GoDot project structure and testing framework
  - Create project directory structure (scenes/, scripts/, assets/, tests/)
  - Configure project.godot with input mappings (WASD, zoom, attack)
  - Install and configure Gut testing framework
  - Create property test harness (test_utils/property_test.gd) with random generators
  - Verify project opens and runs without errors
  - _Requirements: 3.1, 3.2, 7.1_

- [x] 2. Implement Health component with property-based tests
  - [x] 2.1 Create Health component script (scripts/components/health.gd)
    - Implement max_health and current_health tracking
    - Implement take_damage() and heal() methods with bounds checking
    - Implement health_changed and died signals
    - Add type hints and documentation comments
    - _Requirements: 3.8_
  
  - [x] 2.2 Write property test for Health bounds invariant
    - **Property 11: Health Bounds Invariant**
    - **Validates: Requirements 3.8**
    - Generate random sequences of damage/heal operations
    - Verify current_health always in [0, max_health]
  
  - [x] 2.3 Write property test for Health signal emission
    - **Property 12: Health Signal Emission**
    - **Validates: Requirements 3.8**
    - Verify health_changed emits on damage/heal
    - Verify died emits exactly once when health reaches 0
  
  - [x] 2.4 Write unit tests for Health edge cases
    - Test negative damage/heal amounts (should error)
    - Test damage exceeding current health (should clamp to 0)
    - Test healing above max health (should clamp to max)
    - _Requirements: 3.8_

- [x] 3. Implement Movement component with property-based tests
  - [x] 3.1 Create Movement component script (scripts/components/movement.gd)
    - Implement move() method with velocity application
    - Implement character rotation to face movement direction
    - Add CharacterBody3D reference and validation
    - Add type hints and documentation
    - _Requirements: 3.4_
  
  - [x] 3.2 Write property test for movement velocity magnitude
    - **Property 4: Movement Velocity Magnitude**
    - **Validates: Requirements 3.4**
    - Generate random input directions
    - Verify velocity magnitude equals move_speed (±0.01 tolerance)
  
  - [x] 3.3 Write property test for movement direction alignment
    - **Property 5: Movement Direction Alignment**
    - **Validates: Requirements 3.4**
    - Generate random movement directions
    - Verify character faces movement direction (±5° tolerance)

- [x] 4. Implement Combat component with property-based tests
  - [x] 4.1 Create Combat component script (scripts/components/combat.gd)
    - Implement attack() method with range checking
    - Implement cooldown timer management
    - Implement attack_performed signal
    - Add damage application to target Health component
    - _Requirements: 3.5, 3.6_
  
  - [x] 4.2 Write property test for damage application
    - **Property 6: Damage Application**
    - **Validates: Requirements 3.5, 3.6**
    - Generate random damage amounts and initial health values
    - Verify new_health = max(0, old_health - damage)
  
  - [x] 4.3 Write property test for attack cooldown enforcement
    - **Property 7: Attack Cooldown Enforcement**
    - **Validates: Requirements 3.5**
    - Generate random sequences of attack attempts
    - Verify time between successful attacks >= cooldown
  
  - [x] 4.4 Write property test for attack range validation
    - **Property 8: Attack Range Validation**
    - **Validates: Requirements 3.5, 3.6**
    - Generate random attacker/target positions
    - Verify attacks only succeed when distance <= attack_range

- [x] 5. Checkpoint - Ensure component tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create Player scene with components
  - [x] 6.1 Create Player scene (scenes/player/player.tscn)
    - Add CharacterBody3D root node with CapsuleMesh placeholder
    - Add CollisionShape3D with capsule shape
    - Add Health, Movement, Combat component nodes
    - Configure exported variables (max_health=100, move_speed=5.0, attack_damage=10)
    - Add to "player" group for AI targeting
    - _Requirements: 3.4, 3.5, 3.8_
  
  - [x] 6.2 Create Player controller script (scenes/player/player.gd)
    - Implement _process() to read WASD input
    - Transform input to world space (isometric camera orientation)
    - Call Movement.move() with transformed direction
    - Implement mouse click detection for attack targeting
    - Implement respawn on death (connect to Health.died signal)
    - _Requirements: 3.4, 3.5, 3.8_
  
  - [x] 6.3 Write unit test for player respawn on death
    - Verify player returns to spawn point when health reaches 0
    - _Requirements: 3.8_

- [x] 7. Create Enemy scene with AI component
  - [x] 7.1 Create Enemy base scene (scenes/enemies/enemy_base.tscn)
    - Add CharacterBody3D root node with CapsuleMesh placeholder
    - Add CollisionShape3D with capsule shape
    - Add NavigationAgent3D node with configuration
    - Add Health, Movement, Combat component nodes
    - Configure exported variables (max_health=50, move_speed=3.0, attack_damage=5)
    - Add to "enemies" group
    - _Requirements: 3.6, 3.8_
  
  - [x] 7.2 Create EnemyAI component script (scripts/components/enemy_ai.gd)
    - Implement player detection logic (detection_range check)
    - Implement NavigationAgent3D path updates (5Hz update rate)
    - Implement state machine (idle, chase, attack)
    - Call Movement.move() with navigation direction
    - Call Combat.attack() when in range
    - _Requirements: 3.6_
  
  - [x] 7.3 Write property test for detection range behavior
    - **Property 9: Detection Range Behavior**
    - **Validates: Requirements 3.6**
    - Generate random enemy/player positions
    - Verify enemy chases if distance <= detection_range
  
  - [x] 7.4 Write property test for navigation path validity
    - **Property 10: Navigation Path Validity**
    - **Validates: Requirements 3.6**
    - Generate random target positions
    - Verify each path step moves closer to target
  
  - [x] 7.5 Write unit test for enemy removed on death
    - Verify enemy node is removed from scene when health reaches 0
    - _Requirements: 3.8_

- [x] 8. Implement IsometricCamera with property-based tests
  - [x] 8.1 Create IsometricCamera script (scripts/camera/isometric_camera.gd)
    - Implement calculate_camera_position() with 45° angle math
    - Implement smooth follow with lerp
    - Implement zoom input handling (mouse wheel)
    - Implement update_camera_position() for initial setup
    - Add target reference validation
    - _Requirements: 3.3_
  
  - [x] 8.2 Write property test for camera angle invariant
    - **Property 1: Isometric Camera Angle Invariant**
    - **Validates: Requirements 3.3**
    - Generate random player positions
    - Verify camera maintains 45° angle from horizontal (±1° tolerance)
  
  - [x] 8.3 Write property test for camera distance bounds
    - **Property 2: Camera Distance Bounds**
    - **Validates: Requirements 3.3**
    - Generate random zoom input sequences
    - Verify camera distance stays in [zoom_min, zoom_max]
  
  - [x] 8.4 Write property test for camera rotation invariant
    - **Property 3: Camera Rotation Invariant**
    - **Validates: Requirements 3.3**
    - Generate random player movements
    - Verify camera Y rotation remains constant at 45°

- [x] 9. Checkpoint - Ensure entity and camera tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Import and configure Synty assets
  - [ ] 10.1 Import Synty POLYGON Dungeon Realms FBX files
    - Import FBX models into assets/models/
    - Configure import settings (scale=1.0, no auto-collision)
    - Import textures into assets/textures/
    - Create materials in assets/materials/ with PBR textures
    - _Requirements: 3.7, 4.3_
  
  - [ ] 10.2 Create modular room piece scenes
    - Create room_floor_4x4.tscn with floor mesh and collision
    - Create room_wall_straight.tscn with wall mesh and collision
    - Create room_wall_corner.tscn with corner mesh and collision
    - Add metadata for dimensions (width, height, depth) to each piece
    - Test that pieces snap to 0.5 unit grid
    - _Requirements: 3.7_
  
  - [ ] 10.3 Write property test for room piece collision shapes
    - **Property 13: Room Piece Collision Shapes**
    - **Validates: Requirements 3.7**
    - Load each room piece scene
    - Verify each contains CollisionShape3D under StaticBody3D
  
  - [ ] 10.4 Write property test for adjacent piece alignment
    - **Property 14: Adjacent Piece Alignment**
    - **Validates: Requirements 3.7**
    - Place random pairs of adjacent pieces
    - Verify gap between collision boundaries < 0.1 units

- [ ] 11. Build test room scene with navigation
  - [ ] 11.1 Create test room scene (scenes/rooms/test_room.tscn)
    - Assemble 4x4 floor grid using room_floor_4x4 pieces
    - Add walls around perimeter using wall pieces
    - Add DirectionalLight3D for lighting
    - Add WorldEnvironment with default environment
    - _Requirements: 3.7_
  
  - [ ] 11.2 Configure NavigationRegion3D for pathfinding
    - Add NavigationRegion3D node encompassing room
    - Configure navigation mesh parameters (cell_size=0.25, agent_radius=0.5)
    - Bake navigation mesh from room collision shapes
    - Verify navmesh covers floor area
    - _Requirements: 3.6_

- [ ] 12. Create main game scene and wire components
  - [x] 12.1 Create main scene (scenes/main.tscn)
    - Add test_room as child
    - Instantiate Player at spawn point (0, 0, 0)
    - Instantiate 3-5 Enemy instances at various positions
    - Add IsometricCamera with Player as target
    - Configure input action mappings
    - _Requirements: 3.3, 3.4, 3.5, 3.6_
  
  - [ ] 12.2 Implement health bar UI component
    - Create HealthBar scene (scenes/ui/health_bar.tscn) with ProgressBar
    - Create health_bar.gd script to update bar on health_changed signal
    - Attach HealthBar to Player and Enemy scenes
    - Position above character using Control node
    - _Requirements: 3.8, 3.9_
  
  - [ ] 12.3 Write integration test for combat flow
    - Test player attacks enemy until death
    - Verify damage application, cooldown, and enemy removal
    - _Requirements: 3.5, 3.6, 3.8_

- [ ] 13. Add visual feedback for combat
  - [ ] 13.1 Create attack effect particle system
    - Create attack_effect.tscn with GPUParticles3D
    - Configure particle emission (burst on attack)
    - Spawn effect at attack position on attack_performed signal
    - Auto-remove effect after animation completes
    - _Requirements: 3.9_
  
  - [ ] 13.2 Add enemy detection indicator (optional)
    - Add visual indicator above enemy when player detected
    - Show/hide based on EnemyAI state
    - _Requirements: 3.9_

- [ ] 14. Implement scene structure validation tests
  - [ ] 14.1 Write property test for component presence
    - **Property 15: Component Presence Validation**
    - **Validates: Requirements 3.4, 3.5, 3.6, 3.8**
    - Load Player and Enemy scenes
    - Verify each contains Health, Movement, Combat components
  
  - [ ] 14.2 Write property test for scene file format
    - **Property 16: Scene File Format Consistency**
    - **Validates: Requirements 7.1**
    - Parse all .tscn files as text
    - Verify valid GDScript resource format (not binary)

- [ ] 15. Performance optimization and profiling
  - [ ] 15.1 Profile frame time and optimize bottlenecks
    - Run GoDot profiler with 1 player + 5 enemies
    - Identify frame time bottlenecks (target: <16.67ms)
    - Optimize high-cost operations (physics, rendering, scripts)
    - Verify 60 FPS maintained during gameplay
    - _Requirements: 3.10_
  
  - [ ] 15.2 Optimize navigation updates
    - Verify enemy AI updates paths at 5Hz (not 60Hz)
    - Add update_timer to prevent excessive pathfinding
    - Test with 10 enemies to ensure performance
    - _Requirements: 3.10_

- [ ] 16. Final checkpoint - Full playthrough validation
  - Run complete playthrough with all mechanics
  - Verify WASD movement works smoothly
  - Verify camera follows and zoom works
  - Verify click-to-attack combat works
  - Verify enemies detect, chase, and attack
  - Verify health system and death/respawn
  - Verify no console errors during gameplay
  - Ensure all tests pass, ask the user if questions arise.
  - _Requirements: 11.2_

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties (100+ iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end gameplay flows
- GDScript with type hints required for all code
- Text-based .tscn format for all scenes (version control friendly)
- Component-based architecture enables reuse and testability
