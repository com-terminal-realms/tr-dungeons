# Requirements Document: Cone-Based Melee Combat System

## Introduction

This document specifies requirements for a cone-based area-of-effect melee combat system that replaces the current single-target combat with multi-target cone attacks. The system enables both players and enemies to hit multiple targets within a frontal cone area, and adds smart movement where right-clicking moves the player toward targets when out of range.

## Glossary

- **Combat_System**: The component responsible for handling attack logic, damage application, and cooldowns
- **Player**: The player-controlled character entity
- **Enemy**: Non-player character entities controlled by AI
- **Cone_Attack**: An area-of-effect attack that hits all targets within a cone-shaped area
- **Cone_Angle**: The angular width of the attack cone in degrees (e.g., 90 degrees)
- **Cone_Range**: The maximum distance from the attacker that the cone extends
- **Attack_Cooldown**: The time period after an attack during which no new attacks can be initiated
- **Melee_Range**: The distance within which a target can be attacked
- **Target**: An entity that can receive damage from an attack
- **LMB**: Left Mouse Button input
- **RMB**: Right Mouse Button input

## Requirements

### Requirement 1: Cone Attack Mechanics

**User Story:** As a player, I want to perform cone-based melee attacks, so that I can hit multiple enemies at once in front of me.

#### Acceptance Criteria

1. WHEN the Player presses LMB, THE Combat_System SHALL perform a cone attack in the direction the Player is facing
2. WHEN a cone attack is performed, THE Combat_System SHALL detect all Targets within the Cone_Angle and Cone_Range
3. WHEN Targets are detected within the attack cone, THE Combat_System SHALL apply damage to all detected Targets simultaneously
4. WHEN an Enemy performs an attack, THE Combat_System SHALL use the same cone attack mechanics as the Player
5. THE Combat_System SHALL define Cone_Angle as 90 degrees
6. THE Combat_System SHALL define Cone_Range as 3.0 units

### Requirement 2: Cone Detection Algorithm

**User Story:** As a developer, I want accurate cone detection, so that attacks hit the correct targets based on angle and distance.

#### Acceptance Criteria

1. WHEN detecting targets for a cone attack, THE Combat_System SHALL calculate the angle between the attacker's forward direction and the direction to each potential Target
2. WHEN the angle to a Target is less than or equal to half the Cone_Angle, THE Combat_System SHALL consider the Target within the cone's angular bounds
3. WHEN the distance to a Target is less than or equal to the Cone_Range, THE Combat_System SHALL consider the Target within the cone's distance bounds
4. WHEN a Target is within both angular and distance bounds, THE Combat_System SHALL include the Target in the attack
5. WHEN a Target is outside either angular or distance bounds, THE Combat_System SHALL exclude the Target from the attack

### Requirement 3: Multi-Target Damage Application

**User Story:** As a player, I want all enemies in my attack cone to take damage, so that I can fight groups of enemies effectively.

#### Acceptance Criteria

1. WHEN a cone attack hits multiple Targets, THE Combat_System SHALL apply the same damage value to each Target
2. WHEN applying damage to multiple Targets, THE Combat_System SHALL apply damage to all Targets within the same frame
3. WHEN a cone attack hits zero Targets, THE Combat_System SHALL complete the attack without applying damage
4. WHEN a cone attack is performed, THE Combat_System SHALL respect the existing Attack_Cooldown system

### Requirement 4: Smart Movement to Target

**User Story:** As a player, I want to right-click on enemies to move toward them, so that I can get into melee range efficiently.

#### Acceptance Criteria

1. WHEN the Player presses RMB on an Enemy, THE Player SHALL move toward that Enemy's position
2. WHEN the Player is moving toward a Target, THE Player SHALL stop movement when within Melee_Range of the Target
3. WHEN the Player is already within Melee_Range of a Target, THE RMB input SHALL have no effect
4. WHEN the Player presses WASD keys, THE Player SHALL cancel any active RMB movement
5. THE Player SHALL define Melee_Range as equal to Cone_Range

### Requirement 5: Enemy AI Cone Attacks

**User Story:** As a developer, I want enemies to use cone attacks, so that combat mechanics are consistent between player and enemies.

#### Acceptance Criteria

1. WHEN an Enemy is in attack state, THE Enemy SHALL perform cone attacks using the same Combat_System as the Player
2. WHEN an Enemy performs a cone attack, THE Combat_System SHALL detect the Player if the Player is within the Enemy's attack cone
3. WHEN multiple Enemies attack simultaneously, THE Combat_System SHALL handle each Enemy's cone attack independently

### Requirement 6: Combat Component Integration

**User Story:** As a developer, I want to extend the existing Combat component, so that cone attacks integrate seamlessly with the current system.

#### Acceptance Criteria

1. THE Combat_System SHALL maintain the existing attack_damage, attack_range, and attack_cooldown properties
2. THE Combat_System SHALL add cone_angle and cone_range properties for cone attack configuration
3. WHEN performing an attack, THE Combat_System SHALL use cone detection instead of single-target detection
4. THE Combat_System SHALL maintain compatibility with the existing Health component for damage application
5. THE Combat_System SHALL maintain the existing attack_performed signal, emitting it once per attack with a list of all hit Targets

### Requirement 7: Visual Feedback

**User Story:** As a player, I want to see which enemies are in my attack range, so that I can position myself effectively.

#### Acceptance Criteria

1. WHEN the Player is near Enemies, THE Combat_System SHALL provide visual indication of Enemies within attack range
2. WHEN the Player performs an attack, THE Combat_System SHALL spawn attack effects at each hit Target's position
3. WHEN the Player uses RMB to move toward a Target, THE Player SHALL provide visual feedback of the movement path

### Requirement 8: Animation Integration

**User Story:** As a player, I want attack animations to play when I attack, so that combat feels responsive and polished.

#### Acceptance Criteria

1. WHEN the Player performs a cone attack, THE Player SHALL play the existing sword attack animation
2. WHEN an Enemy performs a cone attack, THE Enemy SHALL play the existing sword attack animation
3. WHEN an attack animation is playing, THE Combat_System SHALL prevent new attacks until the animation completes
4. THE Combat_System SHALL maintain the existing animation system without modification
