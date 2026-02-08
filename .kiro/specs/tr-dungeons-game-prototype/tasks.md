# Implementation Plan: TR-Dungeons Game Prototype

## Overview

This implementation plan breaks down the TR-Dungeons game prototype into discrete, incremental tasks. The prototype demonstrates a data-driven, automated approach to modernizing MUD games using GoDot 4, PostgreSQL, AWS infrastructure, and orb-schema-generator for multi-language model generation.

The approach follows a pipeline: MajorMUD data extraction → PostgreSQL storage → Scene generation → GoDot rendering → AWS backend API.

## Tasks

- [ ] 1. Set up project structure and dependencies
  - [x] 1.1 Create GoDot 4.x project structure
    - Create project directories (scenes/, scripts/, assets/, tests/)
    - Configure project.godot with game settings
    - Set up input mappings (WASD, mouse, zoom)
    - _Requirements: 10.1_
  
  - [ ] 1.2 Set up Python development environment
    - Create Python project structure (scripts/, schemas/, tests/)
    - Set up virtual environment with requirements.txt
    - Install dependencies (psycopg2, pyyaml, hypothesis, pytest)
    - _Requirements: 7.1, 8.1, 11.1_
  
  - [ ] 1.3 Set up AWS CDK project
    - Create CDK project structure (cdk/, stacks/, constructs/)
    - Configure cdk.json for ca-central-1 region
    - Install CDK dependencies
    - _Requirements: 13.1, 13.6_
  
  - [ ] 1.4 Configure orb-schema-generator
    - Create schema-generator.yml configuration
    - Set up output directories for GDScript, Python, TypeScript
    - Configure schema directory structure
    - _Requirements: 12.1_

- [ ] 2. Define game data schemas
  - [ ] 2.1 Create Room schema
    - Define Room.yml with fields (room_id, name, description, room_type, exits)
    - Add validation constraints
    - Document field purposes
    - _Requirements: 7.1_
  
  - [ ] 2.2 Create Monster schema
    - Define Monster.yml with fields (monster_id, name, health, attack_damage, movement_speed)
    - Add spawn_rooms relationship
    - Add validation constraints
    - _Requirements: 7.2_
  
  - [ ] 2.3 Create Item schema
    - Define Item.yml with fields (item_id, name, item_type, properties)
    - Add validation constraints
    - _Requirements: 7.3_
  
  - [ ] 2.4 Create NPC schema
    - Define NPC.yml with fields (npc_id, name, dialogue, quest_associations)
    - Add validation constraints
    - _Requirements: 7.3_

- [ ] 3. Generate data models with orb-schema-generator
  - [ ] 3.1 Generate GDScript models
    - Run orb-schema-generator for GDScript output
    - Verify generated models have to_dict/from_dict methods
    - Verify type hints are correct
    - _Requirements: 12.2, 12.5_
  
  - [ ] 3.2 Generate Python Pydantic models
    - Run orb-schema-generator for Python output
    - Verify generated models have validation logic
    - Verify Pydantic configuration is correct
    - _Requirements: 12.3, 12.6_
  
  - [ ] 3.3 Generate TypeScript CDK models
    - Run orb-schema-generator for TypeScript output
    - Verify CDK construct definitions
    - _Requirements: 12.4_
  
  - [ ] 3.4 Write property test for cross-language type safety
    - **Property 28: Cross-Language Type Safety**
    - **Validates: Requirements 12.7**
    - Generate models from same schema
    - Verify type compatibility across languages

- [ ] 4. Checkpoint - Verify schema generation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Extract MajorMUD data
  - [ ] 5.1 Set up MajorMUD data extraction tool
    - Install Nightmare Redux or MMUD Explorer
    - Locate MajorMUD Btrieve database files
    - Configure extraction tool
    - _Requirements: 11.1_
  
  - [ ] 5.2 Extract room definitions
    - Export room data to CSV/JSON
    - Verify all required fields present
    - Extract at least 5 rooms for starter dungeon
    - _Requirements: 11.2, 11.7_
  
  - [ ] 5.3 Extract monster definitions
    - Export monster data to CSV/JSON
    - Verify stats, behaviors, loot drops
    - _Requirements: 11.3_
  
  - [ ] 5.4 Extract item definitions
    - Export item data to CSV/JSON
    - Verify types, stats, properties
    - _Requirements: 11.4_
  
  - [ ] 5.5 Extract NPC definitions
    - Export NPC data to CSV/JSON
    - Verify dialogue and quest data
    - _Requirements: 11.5_
  
  - [ ] 5.6 Write property test for data export completeness
    - **Property 23: Data Export Completeness**
    - **Validates: Requirements 11.2, 11.3, 11.4, 11.5**
    - Verify all required fields present in exports
  
  - [ ] 5.7 Write property test for export format validity
    - **Property 24: Export Format Validity**
    - **Validates: Requirements 11.6**
    - Verify CSV/JSON format is valid and importable

- [ ] 6. Set up PostgreSQL database
  - [ ] 6.1 Create database schema SQL
    - Write CREATE TABLE statements for rooms, monsters, items, npcs
    - Define primary keys and foreign keys
    - Add indexes for common queries
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 6.2 Write property test for referential integrity
    - **Property 17: Database Referential Integrity**
    - **Validates: Requirements 7.4**
    - Test foreign key constraint enforcement
  
  - [ ] 6.3 Import extracted data to PostgreSQL
    - Write import script (Python)
    - Load CSV/JSON data into database
    - Verify data integrity after import
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 7. Checkpoint - Verify database setup
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement scene generation pipeline
  - [ ] 8.1 Create asset mapping configuration
    - Define asset_mapping.yml
    - Map room_types to Asset_Pack prefabs
    - Configure floor, wall, ceiling assets
    - _Requirements: 8.3, 9.1_
  
  - [ ] 8.2 Implement scene generator script
    - Create scene_generator.py
    - Read room data from PostgreSQL
    - Generate .tscn files in text format
    - _Requirements: 8.1, 8.2_
  
  - [ ] 8.3 Implement room structure generation
    - Place floor tiles in grid pattern
    - Add walls around perimeter
    - Add lighting nodes
    - Configure collision shapes
    - _Requirements: 5.2, 5.3, 5.4, 5.6_
  
  - [ ] 8.4 Implement enemy spawn placement
    - Read spawn data from database
    - Place Marker3D nodes at spawn positions
    - _Requirements: 8.4_
  
  - [ ] 8.5 Write property test for scene generation mapping
    - **Property 18: Scene Generation Mapping**
    - **Validates: Requirements 8.3**
    - Verify room_type maps to correct assets
  
  - [ ] 8.6 Write property test for enemy spawn placement
    - **Property 19: Enemy Spawn Placement**
    - **Validates: Requirements 8.4**
    - Verify enemies placed at correct positions
  
  - [ ] 8.7 Write property test for scene file validity
    - **Property 15: Scene File Validity**
    - **Validates: Requirements 5.7, 8.5, 10.1, 10.2, 10.3, 10.5**
    - Verify .tscn files are text format, loadable, Git-compatible

- [ ] 9. Import and configure Synty assets
  - [x] 9.1 Import Synty POLYGON Dungeon Realms assets
    - Import FBX files to assets/models/
    - Configure import settings
    - Import textures to assets/textures/
    - _Requirements: 9.1_
  
  - [ ] 9.2 Create materials for assets
    - Assign textures to materials
    - Configure PBR properties
    - _Requirements: 9.2_
  
  - [ ] 9.3 Write property test for material assignment
    - **Property 20: Asset Material Assignment**
    - **Validates: Requirements 9.2**
    - Verify all models have materials with textures
  
  - [ ] 9.4 Configure collision shapes
    - Add CollisionShape3D to asset prefabs
    - Test collision boundaries
    - _Requirements: 9.3_
  
  - [ ] 9.5 Write property test for collision configuration
    - **Property 21: Asset Collision Configuration**
    - **Validates: Requirements 9.3**
    - Verify all models have collision shapes

- [ ] 10. Checkpoint - Verify scene generation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Implement player movement and control
  - [x] 11.1 Create Player scene
    - Add CharacterBody3D with mesh
    - Add CollisionShape3D
    - Configure exported variables
    - _Requirements: 1.1_
  
  - [x] 11.2 Implement WASD movement
    - Read input in _physics_process
    - Apply velocity to CharacterBody3D
    - Transform input relative to camera
    - _Requirements: 1.1_
  
  - [x] 11.3 Implement mouse rotation
    - Rotate player to face mouse cursor
    - Use raycast to find world position
    - _Requirements: 1.4_
  
  - [ ] 11.4 Write property test for movement direction
    - **Property 1: Movement Direction Correctness**
    - **Validates: Requirements 1.1**
    - Verify WASD keys move in correct directions
  
  - [ ] 11.5 Write property test for movement speed
    - **Property 5: Movement Speed Consistency**
    - **Validates: Requirements 1.5**
    - Verify velocity stays within 5-7 units/second
  
  - [ ] 11.6 Write property test for collision boundaries
    - **Property 3: Collision Boundary Enforcement**
    - **Validates: Requirements 1.3, 5.4**
    - Verify movement blocked at walls

- [ ] 12. Implement camera system
  - [x] 12.1 Create IsometricCamera script
    - Calculate overhead position (30-45° angle)
    - Implement smooth follow with lerp
    - Add zoom input handling
    - _Requirements: 1.2, 4.4_
  
  - [ ] 12.2 Write property test for camera follow
    - **Property 2: Camera Follow Consistency**
    - **Validates: Requirements 1.2, 4.4**
    - Verify camera maintains fixed angle and follows player

- [ ] 13. Implement combat system
  - [x] 13.1 Create Combat component
    - Implement attack() method
    - Add cooldown timer
    - Add range checking
    - _Requirements: 2.1, 2.5_
  
  - [x] 13.2 Implement click-to-attack
    - Detect mouse clicks
    - Find nearest enemy in range
    - Apply damage to target
    - _Requirements: 2.1, 2.2_
  
  - [ ] 13.3 Write property test for attack targeting
    - **Property 6: Attack Targeting Accuracy**
    - **Validates: Requirements 2.1**
    - Verify nearest enemy is targeted
  
  - [ ] 13.4 Write property test for damage application
    - **Property 7: Damage Application Correctness**
    - **Validates: Requirements 2.2, 3.5, 6.1, 6.2**
    - Verify health reduces by damage amount
  
  - [ ] 13.5 Write property test for attack cooldown
    - **Property 10: Attack Cooldown Enforcement**
    - **Validates: Requirements 2.5**
    - Verify cooldown between attacks

- [ ] 14. Implement health system
  - [x] 14.1 Create Health component
    - Track current and max health
    - Implement take_damage() and heal()
    - Emit health_changed and died signals
    - _Requirements: 6.1, 6.2_
  
  - [x] 14.2 Implement death handling
    - Remove enemies on death
    - Trigger game over for player death
    - _Requirements: 2.3, 6.3_
  
  - [x] 14.3 Create health bar UI
    - Display player health in HUD
    - Display enemy health above enemies
    - _Requirements: 6.4, 6.5_
  
  - [ ] 14.4 Write property test for health display
    - **Property 16: Health Display Consistency**
    - **Validates: Requirements 6.5**
    - Verify health bars show correct values

- [ ] 15. Implement enemy AI
  - [x] 15.1 Create Enemy scene
    - Add CharacterBody3D with mesh
    - Add NavigationAgent3D
    - Add Health and Combat components
    - _Requirements: 3.1_
  
  - [x] 15.2 Implement AI state machine
    - IDLE state with patrol behavior
    - CHASE state with pathfinding
    - ATTACK state with combat
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  
  - [ ] 15.3 Write property test for AI state transitions
    - **Property 11: AI State Transitions**
    - **Validates: Requirements 3.1, 3.2, 3.4**
    - Verify state changes based on distance
  
  - [ ] 15.4 Write property test for chase pathfinding
    - **Property 12: Chase Pathfinding**
    - **Validates: Requirements 3.3**
    - Verify enemy moves toward player

- [x] 16. Checkpoint - Verify gameplay mechanics
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 17. Build 5-room starter dungeon
  - [ ] 17.1 Generate 5 room scenes
    - Run scene generator for rooms 1-5
    - Verify .tscn files created
    - _Requirements: 5.1, 5.7_
  
  - [ ] 17.2 Configure room connections
    - Add doorways between rooms
    - Place transition triggers
    - _Requirements: 5.5_
  
  - [ ] 17.3 Write property test for dungeon connectivity
    - **Property 13: Dungeon Connectivity**
    - **Validates: Requirements 5.5**
    - Verify path exists between all rooms
  
  - [ ] 17.4 Write property test for room structure
    - **Property 14: Room Structure Validity**
    - **Validates: Requirements 5.2, 5.3, 5.4, 5.6**
    - Verify rooms have floors, walls, lights, collision

- [ ] 18. Implement visual effects and post-processing
  - [ ] 18.1 Configure WorldEnvironment
    - Add bloom effect
    - Add volumetric fog
    - Add ambient occlusion
    - _Requirements: 4.2_
  
  - [ ] 18.2 Set up lighting
    - Add DirectionalLight3D
    - Add point lights for torches
    - Configure shadows
    - _Requirements: 4.3_
  
  - [ ] 18.3 Verify rendering performance
    - Test frame rate (minimum 30 FPS)
    - Profile rendering bottlenecks
    - _Requirements: 4.5_

- [ ] 19. Set up AWS infrastructure with CDK
  - [ ] 19.1 Create RDS PostgreSQL stack
    - Define DatabaseInstance construct
    - Configure VPC and security groups
    - Set up database credentials
    - _Requirements: 13.1, 13.4_
  
  - [ ] 19.2 Create Lambda functions
    - Define Lambda constructs for API endpoints
    - Configure environment variables
    - Set up IAM roles
    - _Requirements: 13.2, 13.5_
  
  - [ ] 19.3 Create API Gateway
    - Define RestApi construct
    - Configure endpoints (GET /rooms, /monsters, /items)
    - Set up authentication
    - _Requirements: 13.3, 14.6_
  
  - [ ] 19.4 Deploy CDK stack
    - Run cdk synth to generate CloudFormation
    - Run cdk deploy to ca-central-1
    - Verify resources created
    - _Requirements: 13.6, 13.7_

- [ ] 20. Implement backend API handlers
  - [ ] 20.1 Create GET /rooms/{id} handler
    - Query PostgreSQL for room data
    - Return JSON response
    - _Requirements: 14.1_
  
  - [ ] 20.2 Create GET /monsters/{id} handler
    - Query PostgreSQL for monster data
    - Return JSON response
    - _Requirements: 14.2_
  
  - [ ] 20.3 Create GET /items/{id} handler
    - Query PostgreSQL for item data
    - Return JSON response
    - _Requirements: 14.3_
  
  - [ ] 20.4 Write property test for API response format
    - **Property 29: API Response Format**
    - **Validates: Requirements 14.4**
    - Verify responses are valid JSON
  
  - [ ] 20.5 Write property test for schema conformance
    - **Property 30: API Schema Conformance (Round-Trip)**
    - **Validates: Requirements 14.5**
    - Verify serialization/deserialization preserves data
  
  - [ ] 20.6 Write property test for authentication
    - **Property 31: API Authentication Enforcement**
    - **Validates: Requirements 14.6**
    - Verify unauthenticated requests rejected
  
  - [ ] 20.7 Write property test for HTTP status codes
    - **Property 32: HTTP Status Code Correctness**
    - **Validates: Requirements 14.7**
    - Verify appropriate status codes returned

- [ ] 21. Integrate GoDot client with API
  - [ ] 21.1 Create API client in GoDot
    - Implement HTTPRequest wrapper
    - Add authentication headers
    - Handle async responses
    - _Requirements: 14.1, 14.2, 14.3_
  
  - [ ] 21.2 Load room data from API
    - Fetch room data on scene load
    - Parse JSON response
    - Update scene with data
    - _Requirements: 14.1_
  
  - [ ] 21.3 Test API integration
    - Verify data loads correctly
    - Test error handling
    - Test network failures

- [ ] 22. Checkpoint - Verify full system integration
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 23. Write property test for multi-language model generation
  - **Property 25: Multi-Language Model Generation**
  - **Validates: Requirements 12.2, 12.3, 12.4**
  - Verify GDScript, Python, TypeScript code is valid

- [ ] 24. Write property test for GDScript serialization
  - **Property 26: GDScript Serialization Methods**
  - **Validates: Requirements 12.5**
  - Verify to_dict/from_dict methods work correctly

- [ ] 25. Write property test for Python validation
  - **Property 27: Python Model Validation**
  - **Validates: Requirements 12.6**
  - Verify Pydantic validation logic works

- [ ] 26. Write property test for Git diff visibility
  - **Property 22: Git Diff Visibility**
  - **Validates: Requirements 10.4**
  - Verify scene file changes visible in Git

- [ ] 27. Write property test for attack range indicator
  - **Property 9: Attack Range Indicator**
  - **Validates: Requirements 2.4**
  - Verify indicator shows when in range

- [ ] 28. Write property test for mouse rotation
  - **Property 4: Mouse-Based Rotation**
  - **Validates: Requirements 1.4**
  - Verify player faces mouse cursor

- [ ] 29. Final integration testing
  - [ ] 29.1 Test complete data pipeline
    - Extract → Import → Generate → Load → Render
    - Verify end-to-end flow works
  
  - [ ] 29.2 Test API integration
    - Deploy stack → Call endpoints → Verify responses
  
  - [ ] 29.3 Test gameplay
    - Play through 5-room dungeon
    - Verify all mechanics work
    - Test combat, movement, AI

- [ ] 30. Final checkpoint - Complete prototype validation
  - Verify all 32 properties pass
  - Verify all 14 requirements met
  - Verify prototype is playable
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties (100+ iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end workflows
- GDScript with type hints required for all code
- Text-based .tscn format for all scenes (version control friendly)
- Python 3.11+ for all backend code
- AWS CDK in Python for infrastructure
- orb-schema-generator for model generation across languages
