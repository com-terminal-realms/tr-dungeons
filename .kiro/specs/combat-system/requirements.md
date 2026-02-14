# Requirements Document: Combat System

## Introduction

This document specifies the requirements for a real-time PvX combat system for a MajorMUD-inspired isometric 3D action RPG built in Godot 4. The combat system provides responsive, satisfying combat with clear visual feedback, supporting both PvE dungeon crawling and PvP encounters. The system includes melee attacks, ranged abilities, resource management (health, mana, stamina), enemy AI, dodge mechanics, and loot drops.

## Glossary

- **Combat_System**: The complete combat implementation including player attacks, enemy AI, damage calculation, and feedback systems
- **Player**: The player-controlled character entity
- **Enemy**: AI-controlled hostile entities
- **Combatant**: Any entity that can participate in combat (Player or Enemy)
- **Hitbox**: Area3D that deals damage when overlapping with a Hurtbox
- **Hurtbox**: Area3D that receives damage when overlapping with a Hitbox
- **Combat_Stats**: Resource containing combat-related attributes (health, damage, armor, etc.)
- **Ability**: A combat action with cooldown and resource cost (mana or stamina)
- **I_Frames**: Invulnerability frames during which a Combatant cannot take damage
- **Loot_Table**: Database definition of items an Enemy can drop on death
- **State_Machine**: System managing Combatant behavior states (IDLE, ATTACKING, DODGING, etc.)
- **Navigation_Agent**: Godot NavigationAgent3D used for pathfinding
- **Projectile**: A moving entity that deals damage on collision
- **Checkpoint**: A location where the Player respawns after death

## Requirements

### Requirement 1: Basic Melee Attack

**User Story:** As a player, I want to attack enemies by clicking, so that I can deal damage and defeat monsters.

#### Acceptance Criteria

1. WHEN the Player presses the left mouse button AND is not in ATTACKING state, THE Combat_System SHALL trigger a melee attack animation
2. WHEN a melee attack is triggered, THE Combat_System SHALL apply an attack cooldown of 0.5 seconds
3. WHEN a melee attack animation is playing, THE Combat_System SHALL detect all Enemies within a 2-meter cone in front of the Player
4. WHEN an Enemy is within the attack cone during the attack, THE Combat_System SHALL deal damage to that Enemy
5. WHEN damage is dealt to an Enemy, THE Combat_System SHALL display a slash visual effect at the hit location
6. WHEN an Enemy is hit, THE Combat_System SHALL flash the Enemy red for 0.1 seconds
7. WHEN a melee attack is triggered, THE Combat_System SHALL play a swing sound effect
8. WHEN a melee attack hits an Enemy, THE Combat_System SHALL play an impact sound effect
9. WHEN the Player is in ATTACKING state, THE Combat_System SHALL prevent additional attack inputs
10. WHEN a melee attack is triggered, THE Combat_System SHALL interrupt Player movement for 0.2 seconds

### Requirement 2: Health and Damage

**User Story:** As a player or enemy, I want to have health that decreases when damaged, so that combat has meaningful consequences.

#### Acceptance Criteria

1. THE Combat_System SHALL provide all Combatants with max_health and current_health properties
2. WHEN a Combatant's take_damage method is called with an amount and source, THE Combat_System SHALL reduce current_health by that amount
3. THE Combat_System SHALL ensure current_health never goes below 0
4. THE Combat_System SHALL ensure current_health never exceeds max_health
5. WHEN a Combatant takes damage, THE Combat_System SHALL display floating damage numbers above the target
6. WHEN an Enemy exists in the scene, THE Combat_System SHALL display a health bar above that Enemy in world space
7. WHEN the Player exists in the scene, THE Combat_System SHALL display a health bar in screen space UI
8. WHEN a Combatant's current_health reaches 0, THE Combat_System SHALL trigger the death state for that Combatant
9. WHEN a Combatant enters the death state, THE Combat_System SHALL play a death animation
10. WHEN a Combatant's death animation completes, THE Combat_System SHALL persist the corpse for 5 seconds before removal

### Requirement 3: Enemy Combat AI

**User Story:** As an enemy, I want to detect, chase, and attack the player, so that dungeons feel dangerous.

#### Acceptance Criteria

1. THE Combat_System SHALL provide each Enemy with a detection radius property (default 10 meters)
2. WHILE an Enemy is in IDLE state, THE Combat_System SHALL make the Enemy patrol randomly within its spawn area
3. WHEN the Player enters an Enemy's detection radius, THE Combat_System SHALL transition that Enemy to CHASE state
4. WHILE an Enemy is in CHASE state, THE Combat_System SHALL navigate the Enemy toward the Player using Navigation_Agent
5. WHEN an Enemy in CHASE state is within 2 meters of the Player, THE Combat_System SHALL transition that Enemy to ATTACK state
6. WHILE an Enemy is in ATTACK state, THE Combat_System SHALL rotate the Enemy to face the Player
7. WHILE an Enemy is in ATTACK state, THE Combat_System SHALL trigger attacks on a cooldown of 1.5 seconds
8. WHEN the Player moves beyond an Enemy's detection radius multiplied by 1.5, THE Combat_System SHALL transition that Enemy back to IDLE state
9. WHEN an Enemy is about to attack, THE Combat_System SHALL play a 0.5-second windup animation before dealing damage

### Requirement 4: Dodge Roll

**User Story:** As a player, I want to dodge incoming attacks, so that combat has skill expression.

#### Acceptance Criteria

1. WHEN the Player presses the spacebar AND has sufficient stamina, THE Combat_System SHALL trigger a dodge roll in the current movement direction
2. WHEN the Player presses the spacebar while stationary AND has sufficient stamina, THE Combat_System SHALL trigger a dodge roll in the facing direction
3. WHEN a dodge roll is triggered, THE Combat_System SHALL grant the Player 0.3 seconds of I_Frames
4. WHEN a dodge roll is triggered, THE Combat_System SHALL move the Player 4 meters in the dodge direction
5. WHEN a dodge roll is triggered, THE Combat_System SHALL apply a 1-second cooldown before the next dodge
6. WHEN a dodge roll is triggered, THE Combat_System SHALL play the dodge animation
7. WHILE the Player is in DODGING state, THE Combat_System SHALL prevent attack inputs
8. WHEN a dodge roll is triggered, THE Combat_System SHALL consume 20 stamina

### Requirement 5: Stamina System

**User Story:** As a player, I want to manage stamina for combat actions, so that combat requires resource management.

#### Acceptance Criteria

1. THE Combat_System SHALL provide the Player with max_stamina (default 100) and current_stamina properties
2. WHEN the Player performs a dodge roll, THE Combat_System SHALL reduce current_stamina by 20
3. WHILE the Player is sprinting, THE Combat_System SHALL drain current_stamina at 10 per second
4. WHILE the Player is not sprinting, THE Combat_System SHALL regenerate current_stamina at 15 per second
5. WHEN the Player uses stamina, THE Combat_System SHALL pause stamina regeneration for 1 second
6. THE Combat_System SHALL display a stamina bar in the UI below the health bar
7. WHEN the Player attempts to dodge with current_stamina less than 20, THE Combat_System SHALL prevent the dodge action
8. WHEN current_stamina reaches 0, THE Combat_System SHALL flash the stamina bar as a visual indicator

### Requirement 6: Basic Ranged Ability (Fireball)

**User Story:** As a player, I want to cast a ranged fireball spell, so that I have ranged combat options.

#### Acceptance Criteria

1. WHEN the Player presses the right mouse button AND has sufficient mana, THE Combat_System SHALL cast a fireball toward the cursor position
2. WHEN a fireball is cast, THE Combat_System SHALL create a Projectile moving at 15 meters per second
3. WHEN a Projectile hits an Enemy, THE Combat_System SHALL deal 25 base damage to that Enemy
4. WHEN a fireball is cast, THE Combat_System SHALL apply a 3-second cooldown before the next fireball
5. WHEN a fireball is cast, THE Combat_System SHALL consume 20 mana
6. WHEN a fireball is cast, THE Combat_System SHALL play a 0.4-second cast animation before spawning the Projectile
7. WHEN a Projectile exists, THE Combat_System SHALL display a particle trail effect following the Projectile
8. WHEN a Projectile hits a target, THE Combat_System SHALL display an explosion effect at the impact location
9. WHEN a Projectile hits an Enemy, wall, or reaches 20 meters distance, THE Combat_System SHALL destroy the Projectile

### Requirement 7: Mana System

**User Story:** As a player, I want to manage mana for abilities, so that ability usage is strategic.

#### Acceptance Criteria

1. THE Combat_System SHALL provide the Player with max_mana (default 100) and current_mana properties
2. WHEN the Player casts an Ability, THE Combat_System SHALL reduce current_mana by the Ability's mana cost
3. THE Combat_System SHALL regenerate current_mana at 5 per second
4. THE Combat_System SHALL display a mana bar in the UI below the stamina bar
5. WHEN the Player attempts to cast an Ability with current_mana less than the Ability's cost, THE Combat_System SHALL prevent the cast
6. WHEN current_mana is less than an Ability's cost, THE Combat_System SHALL gray out the Ability icon in the UI

### Requirement 8: Hit Feedback

**User Story:** As a player, I want to feel satisfying feedback when I hit or get hit, so that combat feels impactful.

#### Acceptance Criteria

1. WHEN the Player takes damage, THE Combat_System SHALL apply camera shake with intensity proportional to the damage amount
2. WHEN a heavy hit occurs (damage greater than 20), THE Combat_System SHALL freeze the frame for 0.05 seconds
3. WHEN an Enemy is hit, THE Combat_System SHALL apply 0.5 meters of knockback to that Enemy
4. WHEN the Player takes damage, THE Combat_System SHALL flash the screen red for 0.1 seconds
5. THE Combat_System SHALL play distinct sound effects for hit, miss, critical hit, and block events
6. WHEN a Combatant is hit, THE Combat_System SHALL display particle effects (blood or sparks) at the hit location

### Requirement 9: Death and Respawn

**User Story:** As a player, I want to respawn after dying, so that I can continue playing.

#### Acceptance Criteria

1. WHEN the Player's current_health reaches 0, THE Combat_System SHALL display a death screen with combat statistics
2. WHEN the death screen is displayed for 2 seconds, THE Combat_System SHALL show a "Respawn" button
3. WHEN the Player clicks the "Respawn" button, THE Combat_System SHALL respawn the Player at the last Checkpoint
4. WHEN the Player respawns, THE Combat_System SHALL restore current_health and current_mana to their maximum values
5. WHEN the Player respawns, THE Combat_System SHALL reset all Enemies in the current room to their initial state
6. WHERE gold loss on death is configured, THE Combat_System SHALL reduce the Player's gold by the configured percentage

### Requirement 10: Loot Drops

**User Story:** As a player, I want enemies to drop loot when killed, so that I am rewarded for combat.

#### Acceptance Criteria

1. THE Combat_System SHALL provide each Enemy with a Loot_Table reference
2. WHEN an Enemy dies, THE Combat_System SHALL roll against the Enemy's Loot_Table to determine dropped items
3. WHEN items are dropped, THE Combat_System SHALL spawn 3D objects on the ground at the Enemy's death location
4. THE Combat_System SHALL provide dropped items with a 2-meter pickup radius
5. WHEN the Player enters a dropped item's pickup radius, THE Combat_System SHALL automatically pick up the item
6. WHEN an item is picked up, THE Combat_System SHALL display the item name briefly (e.g., "+5 Gold", "Iron Sword")
7. WHEN gold is picked up, THE Combat_System SHALL add the gold amount to the Player's total
8. WHEN equipment is picked up, THE Combat_System SHALL add the equipment to the Player's inventory

### Requirement 11: Combat Stats Structure

**User Story:** As a system architect, I want a standardized combat stats structure, so that all combatants share consistent attributes.

#### Acceptance Criteria

1. THE Combat_System SHALL define a Combat_Stats resource class with the following properties: max_health, max_mana, max_stamina, attack_damage, attack_speed, attack_range, armor, move_speed, critical_chance, and critical_multiplier
2. THE Combat_System SHALL provide default values for all Combat_Stats properties
3. THE Combat_System SHALL allow Combat_Stats to be exported as a resource for configuration
4. THE Combat_System SHALL use Combat_Stats for both Player and Enemy entities

### Requirement 12: Damage Calculation

**User Story:** As a system architect, I want consistent damage calculation, so that combat is predictable and balanced.

#### Acceptance Criteria

1. WHEN damage is calculated, THE Combat_System SHALL compute final_damage as (base_damage multiplied by ability_multiplier) minus target armor
2. THE Combat_System SHALL ensure final_damage is never less than 1
3. WHEN a critical hit occurs, THE Combat_System SHALL multiply final_damage by the attacker's critical_multiplier
4. WHEN an attack is made, THE Combat_System SHALL roll against the attacker's critical_chance to determine if a critical hit occurs

### Requirement 13: Signal Architecture

**User Story:** As a system architect, I want a signal-based architecture, so that combat components are loosely coupled.

#### Acceptance Criteria

1. THE Combat_System SHALL emit a damage_taken signal when a Combatant takes damage, including amount and source
2. THE Combat_System SHALL emit a damage_dealt signal when a Combatant deals damage, including amount and target
3. THE Combat_System SHALL emit a health_changed signal when a Combatant's health changes, including new_health and max_health
4. THE Combat_System SHALL emit a mana_changed signal when mana changes, including new_mana and max_mana
5. THE Combat_System SHALL emit a stamina_changed signal when stamina changes, including new_stamina and max_stamina
6. THE Combat_System SHALL emit a died signal when a Combatant dies, including the killer
7. THE Combat_System SHALL emit an ability_cast signal when an Ability is cast, including the ability name
8. THE Combat_System SHALL emit an ability_cooldown_started signal when an Ability cooldown begins, including ability name and duration
9. THE Combat_System SHALL emit an ability_cooldown_finished signal when an Ability cooldown completes, including ability name

### Requirement 14: State Machine

**User Story:** As a system architect, I want a state machine for combat states, so that combatant behavior is well-defined.

#### Acceptance Criteria

1. THE Combat_System SHALL implement a State_Machine with the following states: IDLE, MOVING, ATTACKING, DODGING, CASTING, STUNNED, and DEAD
2. WHILE a Combatant is in IDLE state, THE Combat_System SHALL allow movement, attack, and dodge actions
3. WHILE a Combatant is in MOVING state, THE Combat_System SHALL allow attack and dodge actions
4. WHILE a Combatant is in ATTACKING state, THE Combat_System SHALL prevent movement and other actions until the attack completes
5. WHILE a Combatant is in DODGING state, THE Combat_System SHALL prevent all actions except movement
6. WHILE a Combatant is in CASTING state, THE Combat_System SHALL prevent all actions until the cast completes
7. WHILE a Combatant is in STUNNED state, THE Combat_System SHALL prevent all actions
8. WHILE a Combatant is in DEAD state, THE Combat_System SHALL prevent all actions and await respawn

### Requirement 15: Collision Layer Setup

**User Story:** As a system architect, I want properly configured collision layers, so that combat interactions work correctly.

#### Acceptance Criteria

1. THE Combat_System SHALL use Layer 1 for world geometry (floors, walls)
2. THE Combat_System SHALL use Layer 2 for the Player entity
3. THE Combat_System SHALL use Layer 3 for Enemy entities
4. THE Combat_System SHALL use Layer 4 for Player Hitboxes that damage Enemies
5. THE Combat_System SHALL use Layer 5 for Enemy Hitboxes that damage the Player
6. THE Combat_System SHALL use Layer 6 for Projectiles
7. THE Combat_System SHALL use Layer 7 for pickup items
8. THE Combat_System SHALL configure collision masks so that Hitboxes only interact with appropriate Hurtboxes

### Requirement 16: Feature Branch and Development Workflow

**User Story:** As a developer, I want all combat system work isolated in a feature branch, so that development follows proper version control practices.

#### Acceptance Criteria

1. THE Combat_System SHALL be developed in a feature branch named "feature/combat-system"
2. THE Combat_System SHALL follow orb-templates naming conventions for the feature branch
3. WHEN development begins, THE Combat_System SHALL create the feature branch from the main branch
4. WHEN the Combat_System is complete, THE Combat_System SHALL be merged back to main via pull request
5. WHILE the feature branch exists, THE Combat_System SHALL restrict all combat-related work to that branch

### Requirement 17: Unit Testing

**User Story:** As a developer, I want comprehensive unit tests for the combat system, so that correctness is verified and regressions are prevented.

#### Acceptance Criteria

1. THE Combat_System SHALL include unit tests for all combat components
2. THE Combat_System SHALL include unit tests for damage calculation logic
3. THE Combat_System SHALL include unit tests for resource management (health, mana, stamina)
4. THE Combat_System SHALL include unit tests for state machine transitions
5. THE Combat_System SHALL include unit tests for ability cooldown logic
6. THE Combat_System SHALL include unit tests for loot drop calculations
7. THE Combat_System SHALL ensure all unit tests pass before committing code
8. THE Combat_System SHALL use the GUT testing framework for Godot
9. THE Combat_System SHALL organize unit tests in the tests/unit directory
10. THE Combat_System SHALL achieve meaningful test coverage of core combat logic
