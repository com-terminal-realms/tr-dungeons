# Requirements Document: TR-Dungeons Game Prototype

## Introduction

This document specifies the requirements for the Terminal Realms: Dungeons game prototype (Phase 1). The prototype will demonstrate the core technical approach: a data-driven, automated 3D dungeon crawler that modernizes MajorMUD using GoDot 4, PostgreSQL, AWS CDK infrastructure, and a content generation pipeline. The prototype focuses on proving the technical architecture with a 5-room starter dungeon, basic combat, MajorMUD data extraction, and the V Rising visual aesthetic using Synty Studios assets. The orb-schema-generator tool will generate data models for both the GoDot frontend (GDScript) and AWS Lambda backend (Python).

## Glossary

- **Game_Engine**: GoDot 4.x game engine used for rendering and gameplay
- **Player_Character**: The 3D character controlled by the user
- **Enemy**: A hostile NPC that attacks the Player_Character
- **Dungeon_Room**: A 3D environment representing a single room in the game world
- **Starter_Dungeon**: A connected sequence of 5 Dungeon_Rooms for the prototype
- **MajorMUD_Database**: The original Btrieve database files containing MajorMUD game data
- **Data_Extraction_Tool**: Software tool (Nightmare Redux or MMUD Explorer) for reading MajorMUD_Database files
- **orb_schema_generator**: Tool that generates data models from YAML schemas for multiple languages
- **CDK_Stack**: AWS Cloud Development Kit infrastructure definition in Python
- **Lambda_Function**: AWS Lambda serverless function for backend game logic
- **API_Gateway**: AWS API Gateway providing REST endpoints for the game client
- **Combat_System**: The subsystem handling damage, attacks, and health
- **Camera_Controller**: The component managing the fixed overhead camera view
- **Asset_Pack**: Synty Studios modular 3D dungeon assets (FBX format)
- **Database**: PostgreSQL database containing game data
- **Generator_Script**: Python script that generates GoDot scene files from database data
- **Scene_File**: GoDot .tscn text-based scene definition file
- **Movement_System**: The subsystem handling Player_Character movement via WASD input
- **Attack_Action**: Player-initiated combat action triggered by mouse click
- **AI_System**: The subsystem controlling Enemy behavior (patrol, chase, attack)
- **Post_Processing**: Visual effects applied to the rendered scene (bloom, fog, color grading)

## Requirements

### Requirement 1: Player Movement and Control

**User Story:** As a player, I want to move my character through the dungeon using WASD keys, so that I can explore the environment and position myself for combat.

#### Acceptance Criteria

1. WHEN the player presses W, A, S, or D keys, THE Movement_System SHALL move the Player_Character in the corresponding direction relative to the camera view
2. WHEN the Player_Character moves, THE Camera_Controller SHALL maintain a fixed overhead angle following the Player_Character position
3. WHEN the Player_Character reaches a collision boundary, THE Movement_System SHALL prevent further movement in that direction
4. WHEN the player moves the mouse, THE Player_Character SHALL rotate to face the mouse cursor position
5. THE Movement_System SHALL provide smooth movement at a consistent speed of 5-7 units per second

### Requirement 2: Combat System

**User Story:** As a player, I want to attack enemies by clicking on them, so that I can defeat hostile creatures in the dungeon.

#### Acceptance Criteria

1. WHEN the player clicks the left mouse button, THE Combat_System SHALL execute an Attack_Action targeting the nearest Enemy within attack range
2. WHEN an Attack_Action hits an Enemy, THE Combat_System SHALL reduce the Enemy health by the attack damage value
3. WHEN an Enemy health reaches zero, THE Combat_System SHALL remove the Enemy from the scene
4. WHEN the Player_Character is within attack range of an Enemy, THE Combat_System SHALL display a visual indicator
5. THE Combat_System SHALL enforce a cooldown period of 0.5-1.0 seconds between Attack_Actions

### Requirement 3: Enemy AI Behavior

**User Story:** As a player, I want enemies to patrol, detect, and attack me, so that the game provides engaging combat challenges.

#### Acceptance Criteria

1. WHEN no Player_Character is detected, THE AI_System SHALL move the Enemy along a patrol path
2. WHEN the Player_Character enters detection range, THE AI_System SHALL transition the Enemy to chase behavior
3. WHILE chasing, THE AI_System SHALL move the Enemy toward the Player_Character position using pathfinding
4. WHEN the Enemy is within attack range of the Player_Character, THE AI_System SHALL execute attack behavior
5. WHEN the Enemy attacks, THE Combat_System SHALL reduce Player_Character health by the Enemy attack damage value

### Requirement 4: Visual Quality and Aesthetics

**User Story:** As a player, I want the game to have a dark fantasy aesthetic similar to V Rising, so that the dungeon atmosphere is immersive and visually appealing.

#### Acceptance Criteria

1. THE Game_Engine SHALL render the scene using 3D models from the Asset_Pack
2. THE Game_Engine SHALL apply Post_Processing effects including bloom, volumetric fog, and ambient occlusion
3. THE Game_Engine SHALL use dynamic lighting with at least one directional light and point lights for torches
4. THE Camera_Controller SHALL maintain a fixed overhead isometric-style angle between 30-45 degrees from horizontal
5. THE Game_Engine SHALL render at a minimum of 30 frames per second on target hardware

### Requirement 5: Dungeon Environment

**User Story:** As a player, I want to explore a 5-room starter dungeon with walls, floors, and atmospheric elements, so that I can experience connected dungeon exploration.

#### Acceptance Criteria

1. THE Starter_Dungeon SHALL contain exactly 5 connected Dungeon_Rooms
2. EACH Dungeon_Room SHALL contain floor tiles, wall sections, and corner pieces from the Asset_Pack
3. EACH Dungeon_Room SHALL include at least one light source (torch or ambient light)
4. EACH Dungeon_Room SHALL have collision boundaries preventing the Player_Character from moving through walls
5. THE Dungeon_Rooms SHALL be connected by doorways or passages allowing Player_Character movement between rooms
6. EACH Dungeon_Room SHALL be constructed using modular Asset_Pack pieces that snap together
7. THE Starter_Dungeon SHALL be defined in Scene_Files that can be loaded by the Game_Engine

### Requirement 6: Health and Damage System

**User Story:** As a player, I want to see my health and enemy health, so that I can make tactical decisions during combat.

#### Acceptance Criteria

1. THE Player_Character SHALL have a health value that decreases when receiving damage
2. THE Enemy SHALL have a health value that decreases when receiving damage
3. WHEN the Player_Character health reaches zero, THE Game_Engine SHALL trigger a game over state
4. THE Game_Engine SHALL display the Player_Character health value in the user interface
5. THE Game_Engine SHALL display Enemy health values above each Enemy

### Requirement 7: Database Schema

**User Story:** As a developer, I want game data stored in a PostgreSQL database, so that content can be managed and queried efficiently.

#### Acceptance Criteria

1. THE Database SHALL contain a table for room definitions with columns for id, name, description, room_type, and connections
2. THE Database SHALL contain a table for monster definitions with columns for id, name, health, attack_damage, and movement_speed
3. THE Database SHALL contain a table for item definitions with columns for id, name, item_type, and properties
4. THE Database SHALL enforce referential integrity between related tables
5. THE Database SHALL support queries for retrieving room data, monster data, and item data

### Requirement 8: Content Generation Pipeline

**User Story:** As a developer, I want to generate GoDot scene files from database data, so that game content can be created programmatically without manual editor work.

#### Acceptance Criteria

1. THE Generator_Script SHALL read room data from the Database
2. THE Generator_Script SHALL create Scene_File definitions in .tscn text format
3. WHEN generating a Scene_File, THE Generator_Script SHALL map room_type values to corresponding Asset_Pack prefabs
4. WHEN generating a Scene_File, THE Generator_Script SHALL place Enemy instances based on spawn data
5. THE Generator_Script SHALL produce Scene_Files that can be loaded by the Game_Engine without errors

### Requirement 9: Asset Integration

**User Story:** As a developer, I want Synty Studios assets integrated into GoDot, so that the game has professional-quality 3D models.

#### Acceptance Criteria

1. THE Game_Engine SHALL import FBX files from the Asset_Pack
2. THE Game_Engine SHALL assign textures to materials for each imported asset
3. THE Game_Engine SHALL configure collision shapes for Asset_Pack models
4. THE Asset_Pack models SHALL render with proper lighting and shadows
5. THE Asset_Pack models SHALL maintain their visual quality when viewed from the overhead camera angle

### Requirement 10: Automation and Version Control

**User Story:** As a developer, I want scene files to be text-based and version-controllable, so that changes can be tracked and automated.

#### Acceptance Criteria

1. THE Scene_File SHALL be stored in .tscn text format
2. THE Scene_File SHALL be human-readable and editable in a text editor
3. THE Scene_File SHALL be compatible with Git version control
4. WHEN the Generator_Script modifies a Scene_File, THE changes SHALL be visible in Git diffs
5. THE Game_Engine SHALL load Scene_Files without requiring manual editor intervention

### Requirement 11: MajorMUD Data Extraction

**User Story:** As a developer, I want to extract all game data from MajorMUD databases, so that I can use the original content in the modernized game.

#### Acceptance Criteria

1. THE Data_Extraction_Tool SHALL read MajorMUD_Database files in Btrieve format
2. THE Data_Extraction_Tool SHALL export room definitions including name, description, exits, and room type
3. THE Data_Extraction_Tool SHALL export monster definitions including name, stats, behaviors, and loot drops
4. THE Data_Extraction_Tool SHALL export item definitions including name, type, stats, and properties
5. THE Data_Extraction_Tool SHALL export NPC definitions including name, dialogue, and quest associations
6. THE Data_Extraction_Tool SHALL produce output in a format compatible with Database import (CSV or JSON)
7. THE extracted data SHALL include at least 5 rooms suitable for the Starter_Dungeon

### Requirement 12: Schema-Driven Model Generation

**User Story:** As a developer, I want data models automatically generated from schemas, so that frontend and backend code stays synchronized with the database structure.

#### Acceptance Criteria

1. THE orb_schema_generator SHALL read YAML schema definitions for game entities
2. THE orb_schema_generator SHALL generate GDScript model classes for the Game_Engine frontend
3. THE orb_schema_generator SHALL generate Python Pydantic model classes for Lambda_Functions
4. THE orb_schema_generator SHALL generate TypeScript CDK construct definitions for infrastructure
5. THE generated GDScript models SHALL include serialization methods (to_dict, from_dict)
6. THE generated Python models SHALL include validation logic
7. THE generated models SHALL maintain type safety across frontend and backend

### Requirement 13: AWS Infrastructure

**User Story:** As a developer, I want AWS infrastructure defined as code using CDK, so that the backend can be deployed consistently and automatically.

#### Acceptance Criteria

1. THE CDK_Stack SHALL define an RDS PostgreSQL Database instance
2. THE CDK_Stack SHALL define Lambda_Functions for game logic endpoints
3. THE CDK_Stack SHALL define an API_Gateway with REST endpoints
4. THE CDK_Stack SHALL configure VPC networking for Database access
5. THE CDK_Stack SHALL define IAM roles and policies for Lambda_Functions
6. THE CDK_Stack SHALL be deployable to AWS ca-central-1 region
7. THE CDK_Stack SHALL use orb_schema_generator output for infrastructure definitions

### Requirement 14: Backend API

**User Story:** As a developer, I want REST API endpoints for game data, so that the GoDot client can retrieve room, monster, and item information.

#### Acceptance Criteria

1. THE API_Gateway SHALL provide a GET endpoint for retrieving room data by room ID
2. THE API_Gateway SHALL provide a GET endpoint for retrieving monster data by monster ID
3. THE API_Gateway SHALL provide a GET endpoint for retrieving item data by item ID
4. THE Lambda_Functions SHALL query the Database and return JSON responses
5. THE API responses SHALL match the schema definitions used by orb_schema_generator
6. THE API_Gateway SHALL enforce authentication for all endpoints
7. THE API endpoints SHALL return appropriate HTTP status codes for success and error conditions
