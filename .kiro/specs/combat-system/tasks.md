# Implementation Plan: Combat System

## Overview

This implementation plan breaks down the combat system into logical phases, starting with foundational components and building up to complete combat functionality. The plan follows a bottom-up approach: core data structures → components → abilities → AI → integration → testing.

The implementation will be done in the `feature/combat-system` branch and includes backend schema definitions, Python API development, and Godot component implementation.

## Tasks

- [x] 1. Setup and Foundation
  - Create feature branch `feature/combat-system` from main
  - Set up directory structure for combat scripts
  - Configure collision layers in project settings (Layers 1-7 as specified)
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 16.1, 16.2, 16.3_

- [-] 2. Backend Schema Definitions
  - [x] 2.1 Create CombatStats schema
    - Create `schemas/models/combat_stats.yaml` with all combat stat properties
    - Define validation rules for stat ranges
    - _Requirements: 11.1, 11.2_
  
  - [x] 2.2 Create EnemyType schema
    - Create `schemas/models/enemy_type.yaml` with enemy configuration
    - Include stats reference, AI parameters, loot table reference
    - _Requirements: 3.1, 10.1_
  
  - [x] 2.3 Create LootTable schema
    - Create `schemas/models/loot_table.yaml` with drop definitions
    - Define drop probability structure
    - _Requirements: 10.1, 10.2_
  
  - [x] 2.4 Create Ability schema
    - Create `schemas/models/ability.yaml` with ability parameters
    - Include cooldown, costs, damage, and effect properties
    - _Requirements: 6.1, 6.4, 6.5_
  
  - [x] 2.5 Create DynamoDB table schemas
    - Create `schemas/tables/combat_stats_table.yaml`
    - Create `schemas/tables/enemy_types_table.yaml`
    - Create `schemas/tables/loot_tables_table.yaml`
    - Create `schemas/tables/abilities_table.yaml`
    - _Requirements: 11.3_
  
  - [-] 2.6 Run schema generator
    - Execute `orb-schema-generator` to generate Python models and CDK constructs
    - Verify generated files in `apps/api/models/` and `infrastructure/cdk/resources/`
    - _Requirements: 11.3_

- [ ] 3. Core Data Structures
  - [ ] 3.1 Implement CombatStats resource
    - Create `scripts/combat/combat_stats.gd` with all stat properties
    - Add export annotations for editor configuration
    - _Requirements: 11.1, 11.2, 11.3_
  
  - [ ]* 3.2 Write property test for CombatStats serialization
    - **Property 29: Combat Stats Serialization Round-Trip**
    - **Validates: Requirements 11.3**
  
  - [ ] 3.3 Create example CombatStats resources
    - Create `data/combat_stats/player_stats.tres`
    - Create `data/combat_stats/goblin_stats.tres`
    - _Requirements: 11.2, 11.4_
  
  - [ ] 3.4 Implement DamageEvent class
    - Create `scripts/combat/damage_event.gd` for damage data
    - Include amount, source, target, is_critical, damage_type
    - _Requirements: 12.1, 12.3_

- [ ] 4. StatsComponent Implementation
  - [ ] 4.1 Create StatsComponent with resource management
    - Create `scripts/combat/stats_component.gd`
    - Implement health, mana, stamina properties and signals
    - Implement regeneration logic in _process()
    - _Requirements: 2.1, 5.1, 7.1_
  
  - [ ]* 4.2 Write property test for health bounds invariant
    - **Property 5: Health Bounds Invariant**
    - **Validates: Requirements 2.3, 2.4**
  
  - [ ]* 4.3 Write property test for resource regeneration
    - **Property 15: Resource Regeneration**
    - **Validates: Requirements 5.4, 7.3**
  
  - [ ]* 4.4 Write property test for stamina regeneration pause
    - **Property 16: Stamina Regeneration Pause**
    - **Validates: Requirements 5.5**
  
  - [ ]* 4.5 Write unit tests for StatsComponent
    - Test reduce_health, consume_mana, consume_stamina methods
    - Test edge cases (zero values, maximum values)
    - _Requirements: 17.3_

- [ ] 5. State Machine Implementation
  - [ ] 5.1 Create StateMachine with state enum and transitions
    - Create `scripts/combat/state_machine.gd`
    - Implement State enum (IDLE, MOVING, ATTACKING, DODGING, CASTING, STUNNED, DEAD)
    - Implement transition_to() with validation
    - Implement can_transition() with state rules
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8_
  
  - [ ]* 5.2 Write property test for state machine action permissions
    - **Property 34: State Machine Action Permissions**
    - **Validates: Requirements 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8**
  
  - [ ]* 5.3 Write unit tests for StateMachine
    - Test valid and invalid state transitions
    - Test can_move, can_attack, can_dodge, can_cast methods
    - _Requirements: 17.4_

- [ ] 6. Checkpoint - Core Components Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Hitbox and Hurtbox System
  - [ ] 7.1 Create HitboxArea3D script
    - Create `scripts/combat/hitbox_area3d.gd`
    - Implement get_damage() method
    - Configure collision layers (Layer 4 for player, Layer 5 for enemy)
    - _Requirements: 15.4, 15.5, 15.8_
  
  - [ ] 7.2 Create HurtboxArea3D script
    - Create `scripts/combat/hurtbox_area3d.gd`
    - Implement area_entered signal handling
    - Configure collision masks appropriately
    - _Requirements: 15.8_
  
  - [ ]* 7.3 Write property test for hitbox collision layer isolation
    - **Property 35: Hitbox Collision Layer Isolation**
    - **Validates: Requirements 15.8**

- [ ] 8. Ability System Foundation
  - [ ] 8.1 Create Ability base class
    - Create `scripts/combat/ability.gd`
    - Implement ability_name, cooldown, mana_cost, stamina_cost, cast_time properties
    - Implement activate() virtual method
    - _Requirements: 6.4, 6.5_
  
  - [ ] 8.2 Create AbilityController
    - Create `scripts/combat/ability_controller.gd`
    - Implement ability registration, activation, and cooldown tracking
    - Implement resource cost validation
    - Emit ability signals
    - _Requirements: 6.4, 6.5, 13.7, 13.8, 13.9_
  
  - [ ]* 8.3 Write property test for ability cooldown
    - **Property 20: Ability Cooldown**
    - **Validates: Requirements 6.4**
  
  - [ ]* 8.4 Write property test for ability resource consumption
    - **Property 21: Ability Resource Consumption**
    - **Validates: Requirements 6.5**
  
  - [ ]* 8.5 Write property test for resource validation for actions
    - **Property 17: Resource Validation for Actions**
    - **Validates: Requirements 5.7, 7.5**
  
  - [ ]* 8.6 Write unit tests for AbilityController
    - Test ability registration and activation
    - Test cooldown tracking
    - Test resource cost validation
    - _Requirements: 17.5_

- [ ] 9. CombatComponent Implementation
  - [ ] 9.1 Create CombatComponent with core combat logic
    - Create `scripts/combat/combat_component.gd`
    - Implement attack(), dodge(), take_damage() methods
    - Implement calculate_damage() with armor and critical hits
    - Connect to StatsComponent, StateMachine, AbilityController
    - Emit combat signals
    - _Requirements: 1.1, 1.2, 2.2, 4.1, 4.2, 12.1, 12.2, 12.3, 12.4, 13.1, 13.2_
  
  - [ ]* 9.2 Write property test for damage application
    - **Property 6: Damage Application**
    - **Validates: Requirements 2.2**
  
  - [ ]* 9.3 Write property test for damage calculation formula
    - **Property 30: Damage Calculation Formula**
    - **Validates: Requirements 12.1, 12.2**
  
  - [ ]* 9.4 Write property test for critical hit damage multiplier
    - **Property 31: Critical Hit Damage Multiplier**
    - **Validates: Requirements 12.3**
  
  - [ ]* 9.5 Write property test for critical hit probability
    - **Property 32: Critical Hit Probability**
    - **Validates: Requirements 12.4**
  
  - [ ]* 9.6 Write property test for death trigger on zero health
    - **Property 7: Death Trigger on Zero Health**
    - **Validates: Requirements 2.8**
  
  - [ ]* 9.7 Write property test for combat signal emission
    - **Property 33: Combat Signal Emission**
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8, 13.9**
  
  - [ ]* 9.8 Write unit tests for CombatComponent
    - Test attack cooldown enforcement
    - Test invulnerability frames
    - Test death and corpse persistence
    - _Requirements: 17.1, 17.2_

- [ ] 10. Checkpoint - Combat Core Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Melee Attack Ability
  - [ ] 11.1 Implement MeleeAttack ability
    - Create `scripts/combat/abilities/melee_attack.gd`
    - Implement attack animation triggering
    - Implement hitbox activation during attack frames
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_
  
  - [ ]* 11.2 Write property test for attack cooldown enforcement
    - **Property 1: Attack Cooldown Enforcement**
    - **Validates: Requirements 1.2**
  
  - [ ]* 11.3 Write property test for damage detection in attack cone
    - **Property 2: Damage Detection in Attack Cone**
    - **Validates: Requirements 1.3**
  
  - [ ]* 11.4 Write property test for damage dealing to detected enemies
    - **Property 3: Damage Dealing to Detected Enemies**
    - **Validates: Requirements 1.4**
  
  - [ ]* 11.5 Write property test for attack prevention during attack state
    - **Property 4: Attack Prevention During Attack State**
    - **Validates: Requirements 1.9**
  
  - [ ]* 11.6 Write unit tests for MeleeAttack
    - Test attack animation triggering
    - Test hitbox activation timing
    - _Requirements: 17.1_

- [ ] 12. Dodge Roll Implementation
  - [ ] 12.1 Implement dodge roll in CombatComponent
    - Implement dodge() method with direction parameter
    - Grant i-frames for 0.3 seconds
    - Apply dodge movement (4 meters)
    - Consume stamina (20)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.8_
  
  - [ ]* 12.2 Write property test for dodge i-frames
    - **Property 11: Dodge I-Frames**
    - **Validates: Requirements 4.3**
  
  - [ ]* 12.3 Write property test for dodge distance
    - **Property 12: Dodge Distance**
    - **Validates: Requirements 4.4**
  
  - [ ]* 12.4 Write property test for dodge stamina consumption
    - **Property 13: Dodge Stamina Consumption**
    - **Validates: Requirements 4.8**
  
  - [ ]* 12.5 Write property test for dodge prevention during dodge state
    - **Property 14: Dodge Prevention During Dodge State**
    - **Validates: Requirements 4.7**

- [ ] 13. Projectile System
  - [ ] 13.1 Create Projectile class
    - Create `scripts/combat/projectile.gd`
    - Implement movement, collision detection, and destruction
    - Configure collision layers (Layer 6)
    - _Requirements: 6.2, 6.3, 6.7, 6.8, 6.9, 15.6_
  
  - [ ]* 13.2 Write property test for projectile damage on hit
    - **Property 19: Projectile Damage on Hit**
    - **Validates: Requirements 6.3**
  
  - [ ]* 13.3 Write property test for projectile lifetime
    - **Property 22: Projectile Lifetime**
    - **Validates: Requirements 6.9**
  
  - [ ]* 13.4 Write unit tests for Projectile
    - Test projectile movement
    - Test collision detection
    - Test destruction conditions
    - _Requirements: 17.1_

- [ ] 14. Fireball Ability
  - [ ] 14.1 Implement Fireball ability
    - Create `scripts/combat/abilities/fireball.gd`
    - Implement cast animation and projectile spawning
    - Configure mana cost (20) and cooldown (3 seconds)
    - _Requirements: 6.1, 6.2, 6.4, 6.5, 6.6_
  
  - [ ] 14.2 Create fireball projectile scene
    - Create `scenes/projectiles/fireball.tscn`
    - Add visual effects (particle trail, explosion)
    - Configure collision shape
    - _Requirements: 6.7, 6.8_
  
  - [ ]* 14.3 Write property test for fireball projectile creation
    - **Property 18: Fireball Projectile Creation**
    - **Validates: Requirements 6.2**

- [ ] 15. Checkpoint - Abilities Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 16. Enemy AI Implementation
  - [ ] 16.1 Create EnemyAI component
    - Create `scripts/combat/enemy_ai.gd`
    - Implement AIState enum (IDLE, PATROL, CHASE, ATTACK, RETURN)
    - Implement state processing methods
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_
  
  - [ ]* 16.2 Write property test for enemy detection radius
    - **Property 8: Enemy Detection Radius**
    - **Validates: Requirements 3.3**
  
  - [ ]* 16.3 Write property test for enemy attack range transition
    - **Property 9: Enemy Attack Range Transition**
    - **Validates: Requirements 3.5**
  
  - [ ]* 16.4 Write property test for enemy return to idle
    - **Property 10: Enemy Return to Idle**
    - **Validates: Requirements 3.8**
  
  - [ ]* 16.5 Write unit tests for EnemyAI
    - Test state transitions
    - Test pathfinding integration
    - Test attack timing
    - _Requirements: 17.1_

- [ ] 17. Loot System
  - [ ] 17.1 Create LootTable resource
    - Create `scripts/loot/loot_table.gd`
    - Implement roll() method with probability calculations
    - _Requirements: 10.1, 10.2_
  
  - [ ] 17.2 Create LootDrop resource
    - Create `scripts/loot/loot_drop.gd`
    - Implement item_id, chance, quantity properties
    - _Requirements: 10.2_
  
  - [ ] 17.3 Implement loot drop spawning
    - Add loot drop logic to CombatComponent death handling
    - Create 3D pickup objects at death location
    - _Requirements: 10.2, 10.3_
  
  - [ ] 17.4 Implement item pickup system
    - Create pickup area detection (2-meter radius)
    - Implement automatic pickup on proximity
    - Display pickup notification
    - _Requirements: 10.4, 10.5, 10.6_
  
  - [ ] 17.5 Implement gold and equipment handling
    - Add gold to player total on pickup
    - Add equipment to player inventory on pickup
    - _Requirements: 10.7, 10.8_
  
  - [ ]* 17.6 Write property test for loot drop generation
    - **Property 26: Loot Drop Generation**
    - **Validates: Requirements 10.2**
  
  - [ ]* 17.7 Write property test for item pickup on proximity
    - **Property 27: Item Pickup on Proximity**
    - **Validates: Requirements 10.5**
  
  - [ ]* 17.8 Write property test for gold accumulation
    - **Property 28: Gold Accumulation**
    - **Validates: Requirements 10.7**
  
  - [ ]* 17.9 Write unit tests for loot system
    - Test loot table probability calculations
    - Test pickup detection
    - _Requirements: 17.6_

- [ ] 18. Hit Feedback System
  - [ ] 18.1 Implement visual feedback effects
    - Create slash effect for melee hits
    - Create red flash for damage taken
    - Create particle effects for hits
    - _Requirements: 1.5, 1.6, 8.4, 8.6_
  
  - [ ] 18.2 Implement audio feedback
    - Add swing sound for attacks
    - Add impact sound for hits
    - Add distinct sounds for critical hits
    - _Requirements: 1.7, 1.8, 8.5_
  
  - [ ] 18.3 Implement camera shake
    - Add camera shake on player damage
    - Scale intensity with damage amount
    - _Requirements: 8.1_
  
  - [ ] 18.4 Implement hit freeze and knockback
    - Add frame freeze for heavy hits (>20 damage)
    - Apply 0.5m knockback to hit enemies
    - _Requirements: 8.2, 8.3_
  
  - [ ]* 18.5 Write property test for knockback application
    - **Property 23: Knockback Application**
    - **Validates: Requirements 8.3**

- [ ] 19. Death and Respawn System
  - [ ] 19.1 Implement death screen UI
    - Create death screen with combat statistics
    - Add 2-second delay before showing respawn button
    - _Requirements: 9.1, 9.2_
  
  - [ ] 19.2 Implement respawn logic
    - Respawn player at last checkpoint
    - Restore health and mana to maximum
    - Reset enemies in current room
    - _Requirements: 9.3, 9.4, 9.5_
  
  - [ ] 19.3 Implement gold loss on death (optional)
    - Add configurable gold loss percentage
    - Apply gold penalty on respawn
    - _Requirements: 9.6_
  
  - [ ]* 19.4 Write property test for respawn resource restoration
    - **Property 24: Respawn Resource Restoration**
    - **Validates: Requirements 9.4**
  
  - [ ]* 19.5 Write property test for enemy reset on respawn
    - **Property 25: Enemy Reset on Respawn**
    - **Validates: Requirements 9.5**

- [ ] 20. Checkpoint - Core Systems Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 21. Backend API Development
  - [ ] 21.1 Implement CombatStats API endpoints
    - Create GET /combat-stats/{id} endpoint
    - Create POST /combat-stats endpoint
    - Create PUT /combat-stats/{id} endpoint
    - Create DELETE /combat-stats/{id} endpoint
    - _Requirements: 11.3_
  
  - [ ] 21.2 Implement EnemyType API endpoints
    - Create GET /enemy-types/{id} endpoint
    - Create GET /enemy-types (list all) endpoint
    - Create POST /enemy-types endpoint
    - _Requirements: 3.1_
  
  - [ ] 21.3 Implement LootTable API endpoints
    - Create GET /loot-tables/{id} endpoint
    - Create POST /loot-tables endpoint
    - _Requirements: 10.1_
  
  - [ ] 21.4 Implement Ability API endpoints
    - Create GET /abilities/{id} endpoint
    - Create GET /abilities (list all) endpoint
    - _Requirements: 6.1_
  
  - [ ]* 21.5 Write unit tests for API endpoints
    - Test CRUD operations for all endpoints
    - Test validation and error handling
    - _Requirements: 17.1_

- [ ] 22. Godot Backend Integration
  - [ ] 22.1 Create HTTP client for backend API
    - Create `scripts/backend/api_client.gd`
    - Implement HTTP request handling
    - Implement response parsing
    - _Requirements: 11.3_
  
  - [ ] 22.2 Implement data fetching on game start
    - Fetch enemy types from API
    - Fetch loot tables from API
    - Cache data locally
    - _Requirements: 3.1, 10.1_
  
  - [ ] 22.3 Implement resource conversion
    - Convert JSON responses to Godot resources
    - Create CombatStats from fetched data
    - Create LootTable from fetched data
    - _Requirements: 11.3_
  
  - [ ]* 22.4 Write unit tests for backend integration
    - Test API client request/response handling
    - Test resource conversion
    - Test caching logic
    - _Requirements: 17.1_

- [ ] 23. UI Implementation
  - [ ] 23.1 Create health bar UI
    - Create player health bar (screen space)
    - Create enemy health bars (world space)
    - Connect to health_changed signals
    - _Requirements: 2.6, 2.7_
  
  - [ ] 23.2 Create resource bars UI
    - Create stamina bar below health bar
    - Create mana bar below stamina bar
    - Connect to resource change signals
    - Add visual indicators for insufficient resources
    - _Requirements: 5.6, 5.8, 7.4, 7.6_
  
  - [ ] 23.3 Create damage numbers
    - Implement floating damage numbers above targets
    - Animate numbers (fade out, float up)
    - _Requirements: 2.5_
  
  - [ ] 23.4 Create ability cooldown UI
    - Display ability icons with cooldown overlays
    - Gray out abilities when insufficient resources
    - _Requirements: 7.6_

- [ ] 24. Player Entity Setup
  - [ ] 24.1 Create player scene with combat components
    - Create `scenes/entities/player.tscn`
    - Add CharacterBody3D, CollisionShape3D, MeshInstance3D
    - Add CombatComponent with all sub-components
    - Add HitboxArea3D and HurtboxArea3D
    - Configure collision layers (Layer 2)
    - _Requirements: 15.2_
  
  - [ ] 24.2 Integrate player input handling
    - Connect left mouse button to attack()
    - Connect right mouse button to fireball cast
    - Connect spacebar to dodge()
    - _Requirements: 1.1, 4.1, 6.1_
  
  - [ ] 24.3 Add player animations
    - Create or import attack animation
    - Create or import dodge animation
    - Create or import cast animation
    - Create or import death animation
    - _Requirements: 1.1, 2.9, 4.6, 6.6_

- [ ] 25. Enemy Entity Setup
  - [ ] 25.1 Create enemy scene template
    - Create `scenes/entities/enemy.tscn`
    - Add CharacterBody3D, CollisionShape3D, MeshInstance3D
    - Add CombatComponent with all sub-components
    - Add HitboxArea3D and HurtboxArea3D
    - Add NavigationAgent3D
    - Add EnemyAI component
    - Configure collision layers (Layer 3)
    - _Requirements: 15.3_
  
  - [ ] 25.2 Create goblin enemy variant
    - Instantiate enemy template
    - Assign goblin_stats.tres
    - Configure AI parameters (detection radius, attack range)
    - Assign loot table
    - _Requirements: 3.1, 10.1_
  
  - [ ] 25.3 Add enemy animations
    - Create or import idle animation
    - Create or import walk animation
    - Create or import attack animation
    - Create or import attack windup animation
    - Create or import death animation
    - _Requirements: 2.9, 3.9_

- [ ] 26. Checkpoint - Entities Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 27. Integration Testing
  - [ ]* 27.1 Write integration test for player vs enemy combat
    - Test full combat loop: player attacks enemy until death
    - Verify damage, health changes, death, loot drop
    - _Requirements: 17.1_
  
  - [ ]* 27.2 Write integration test for enemy AI behavior
    - Test detection, chase, attack sequence
    - Verify state transitions and pathfinding
    - _Requirements: 17.1_
  
  - [ ]* 27.3 Write integration test for dodge mechanics
    - Test dodge roll with i-frames against enemy attack
    - Verify stamina consumption and invulnerability
    - _Requirements: 17.1_
  
  - [ ]* 27.4 Write integration test for fireball ability
    - Test casting, projectile flight, hit detection
    - Verify mana consumption and cooldown
    - _Requirements: 17.1_
  
  - [ ]* 27.5 Write integration test for death and respawn
    - Test player death, death screen, respawn
    - Verify resource restoration and enemy reset
    - _Requirements: 17.1_

- [ ] 28. Test Scene Creation
  - [ ] 28.1 Create combat test arena
    - Create `scenes/test/combat_arena.tscn`
    - Add navigation mesh
    - Add player spawn point
    - Add enemy spawn points
    - Add checkpoint marker
    - _Requirements: 9.3_
  
  - [ ] 28.2 Populate test arena with enemies
    - Add 3-5 goblin enemies
    - Configure spawn positions
    - Test combat scenarios manually
    - _Requirements: 3.1_

- [ ] 29. Polish and Refinement
  - [ ] 29.1 Tune combat feel
    - Adjust attack cooldowns for responsiveness
    - Tune damage values for balance
    - Adjust dodge distance and i-frame duration
    - _Requirements: 1.2, 4.3, 4.4_
  
  - [ ] 29.2 Optimize performance
    - Profile combat with multiple enemies
    - Optimize signal emissions
    - Optimize collision detection
    - _Requirements: 17.1_
  
  - [ ] 29.3 Add combat sound effects
    - Add all required sound effects
    - Tune volume levels
    - _Requirements: 1.7, 1.8, 8.5_
  
  - [ ] 29.4 Add visual effects polish
    - Refine particle effects
    - Tune camera shake intensity
    - Polish UI animations
    - _Requirements: 1.5, 1.6, 6.7, 6.8, 8.1, 8.6_

- [ ] 30. Final Checkpoint - Combat System Complete
  - Run all unit tests and property tests
  - Run integration tests
  - Test combat in test arena
  - Verify all 17 requirements are met
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 31. Documentation and Merge
  - [ ] 31.1 Update project documentation
    - Document combat system architecture
    - Document API endpoints
    - Document collision layer setup
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8_
  
  - [ ] 31.2 Create pull request
    - Create PR from feature/combat-system to main
    - Include summary of changes
    - Reference requirements document
    - _Requirements: 16.4_
  
  - [ ] 31.3 Code review and merge
    - Address review feedback
    - Ensure all tests pass in CI
    - Merge to main branch
    - _Requirements: 16.4, 16.5_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at major milestones
- Property tests validate universal correctness properties (35 total)
- Unit tests validate specific examples and edge cases
- Backend integration tasks can be done in parallel with Godot component development
- The implementation follows a bottom-up approach: data → components → abilities → AI → integration
- All combat work must be done in the `feature/combat-system` branch
- Pre-commit hook will enforce that all tests pass before commits
