# Implementation Plan: Dungeon Asset Mapping System

## Overview

This implementation plan breaks down the Dungeon Asset Mapping System into discrete coding tasks. The system measures and documents dungeon assets (any format: GLB, FBX, etc.) to enable rapid dungeon construction. Phase 1 validates with three Kenney assets: corridor.glb, room-small.glb, room-large.glb.

The implementation follows an incremental approach: core data structures → measurement → storage → calculation → validation → documentation.

## Tasks

- [x] 1. Set up core data structures and testing framework
  - Create AssetMetadata, ConnectionPoint, CollisionData, ValidationResult classes
  - Set up GUT testing framework directories (tests/unit, tests/property)
  - Create test helper utilities for generating random test data
  - _Requirements: 6.1, 6.2_

- [x] 2. Implement AssetMapper measurement core
  - [x] 2.1 Implement bounding box calculation
    - Write `_calculate_bounding_box()` to recursively find all MeshInstance3D nodes
    - Combine AABBs in world space with ±0.1 unit accuracy
    - Handle empty assets and missing geometry gracefully
    - _Requirements: 1.1_
  
  - [x] 2.2 Write property test for bounding box accuracy
    - **Property 1: Bounding Box Measurement Accuracy**
    - **Validates: Requirements 1.1**
  
  - [x] 2.3 Implement origin offset calculation
    - Write `_find_origin_offset()` to calculate center of bounding box
    - Return offset from origin to geometric center
    - _Requirements: 1.2_
  
  - [x] 2.4 Write property test for origin offset
    - **Property 2: Origin Offset Calculation**
    - **Validates: Requirements 1.2**
  
  - [x] 2.5 Implement visual vs collision extent distinction
    - Write `_extract_collision_geometry()` to find CollisionShape3D nodes
    - Calculate collision AABB separately from visual AABB
    - _Requirements: 1.3, 5.1_
  
  - [x] 2.6 Write property test for extent distinction
    - **Property 3: Visual vs Collision Extent Distinction**
    - **Validates: Requirements 1.3**

- [x] 3. Implement connection point detection
  - [x] 3.1 Implement connection point finder
    - Write `_find_connection_points()` using geometry analysis
    - Identify openings by analyzing mesh boundaries and gaps
    - Calculate connection coordinates and outward-facing normals
    - Support corridors (2 points) and rooms (multiple points)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 3.2 Write property test for connection point discovery
    - **Property 4: Connection Point Discovery**
    - **Validates: Requirements 2.1, 2.2**
  
  - [ ] 3.3 Write property test for coordinate system
    - **Property 5: Connection Point Coordinate System**
    - **Validates: Requirements 2.4**
  
  - [ ] 3.4 Implement floor and wall measurements
    - Write `_measure_floor_height()` to find lowest walkable surface
    - Write wall thickness calculation for wall assets
    - Write doorway dimension measurement
    - _Requirements: 1.4, 1.5, 1.6_

- [ ] 4. Checkpoint - Ensure measurement tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement rotation and transformation
  - [ ] 5.1 Implement rotation detection and transforms
    - Write `_determine_default_rotation()` to analyze geometry orientation
    - Implement rotation transformations for N/S/E/W (0°, 90°, 180°, 270°)
    - Write `ConnectionPoint.transform_by_rotation()` method
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 5.2 Write property test for rotation round-trip
    - **Property 9: Rotation Transform Round-Trip**
    - **Validates: Requirements 4.3**
  
  - [ ] 5.3 Write property test for cardinal direction completeness
    - **Property 10: Cardinal Direction Rotation Completeness**
    - **Validates: Requirements 4.2**
  
  - [ ] 5.4 Write property test for rotation preserving alignment
    - **Property 11: Rotation Preserves Connection Alignment**
    - **Validates: Requirements 4.5, 7.5**

- [ ] 6. Implement collision and walkable area analysis
  - [ ] 6.1 Implement collision geometry extraction
    - Extract all CollisionShape3D dimensions and positions
    - Document collision shape types (box, sphere, capsule, etc.)
    - _Requirements: 5.1, 5.3_
  
  - [ ] 6.2 Implement walkable area calculation
    - Calculate walkable area boundaries for room assets
    - Verify walkable areas don't overlap wall collision
    - Map wall collision boundaries
    - _Requirements: 5.2, 5.5_
  
  - [ ] 6.3 Write property test for walkable area containment
    - **Property 12: Walkable Area Containment**
    - **Validates: Requirements 5.2, 5.5**
  
  - [ ] 6.4 Write property test for collision documentation
    - **Property 13: Collision Geometry Documentation Completeness**
    - **Validates: Requirements 5.1, 5.3**

- [ ] 7. Implement AssetMetadataDatabase storage
  - [ ] 7.1 Implement database storage and retrieval
    - Write `store()`, `get_metadata()`, `has_metadata()` methods
    - Implement in-memory Dictionary storage
    - Ensure query performance < 1ms
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [ ] 7.2 Implement JSON export/import
    - Write `save_to_json()` and `load_from_json()` methods
    - Implement `AssetMetadata.to_dict()` and `from_dict()` methods
    - Handle all data types (Vector3, AABB, arrays)
    - _Requirements: 6.5_
  
  - [ ] 7.3 Write property test for metadata storage round-trip
    - **Property 14: Metadata Storage Round-Trip**
    - **Validates: Requirements 6.1, 6.2**
  
  - [ ] 7.4 Write property test for JSON round-trip
    - **Property 15: JSON Export Round-Trip**
    - **Validates: Requirements 6.5**
  
  - [ ] 7.5 Write property test for query performance
    - **Property 16: Metadata Query Performance**
    - **Validates: Requirements 6.3**
  
  - [ ] 7.6 Implement version history
    - Store previous versions when metadata is updated
    - Implement version comparison functionality
    - _Requirements: 6.4_
  
  - [ ] 7.7 Write property test for version preservation
    - **Property 17: Version History Preservation**
    - **Validates: Requirements 6.4**

- [ ] 8. Checkpoint - Ensure storage tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement LayoutCalculator spacing formulas
  - [ ] 9.1 Implement corridor count calculation
    - Write `calculate_corridor_count()` with spacing formula
    - Implement `_calculate_overlap()` for connection points
    - Formula: count = ceil((distance - overlap) / effective_length)
    - _Requirements: 3.1, 3.2_
  
  - [ ] 9.2 Write property test for corridor count formula
    - **Property 7: Corridor Count Formula**
    - **Validates: Requirements 3.1, 3.2**
  
  - [ ] 9.3 Write unit test for known spacing case
    - Test that 20 units = 3 corridor pieces (Kenney corridor)
    - Test distances at 10, 15, 30 units
    - _Requirements: 3.3, 3.4_
  
  - [ ] 9.4 Write property test for overlap consistency
    - **Property 8: Overlap Calculation Consistency**
    - **Validates: Requirements 3.2, 3.5**

- [ ] 10. Implement LayoutCalculator validation
  - [ ] 10.1 Implement connection validation
    - Write `validate_connection()` to check two assets
    - Detect gaps > 0.2 units and overlaps > 0.5 units
    - Check normal alignment (should face opposite directions)
    - Return ValidationResult with detailed feedback
    - _Requirements: 2.5, 7.1, 7.2_
  
  - [ ] 10.2 Write property test for gap/overlap detection
    - **Property 18: Gap and Overlap Detection**
    - **Validates: Requirements 7.1, 7.2**
  
  - [ ] 10.3 Implement layout validation
    - Write `validate_layout()` to check entire layout
    - Verify all connection points align within tolerance
    - Check navigation path continuity
    - _Requirements: 7.3, 7.4_
  
  - [ ] 10.4 Write property test for layout connection validation
    - **Property 19: Layout Connection Validation**
    - **Validates: Requirements 7.3**
  
  - [ ] 10.5 Write property test for navigation continuity
    - **Property 20: Navigation Path Continuity**
    - **Validates: Requirements 7.4**

- [ ] 11. Implement DocumentationGenerator
  - [ ] 11.1 Implement asset documentation generation
    - Write `generate_asset_doc()` to create markdown for single asset
    - Include dimensions, connection points, collision geometry
    - Add visual diagrams (ASCII art or Mermaid)
    - Include timestamp and measurement accuracy
    - _Requirements: 8.1, 8.2, 8.5_
  
  - [ ] 11.2 Implement spacing formula documentation
    - Write `generate_spacing_doc()` with worked examples
    - Include examples at 10, 15, 20, 30 units
    - _Requirements: 8.3_
  
  - [ ] 11.3 Implement rotation documentation
    - Write `generate_rotation_doc()` with transformation matrices
    - Include all four cardinal directions
    - _Requirements: 8.4_
  
  - [ ] 11.4 Write property test for documentation completeness
    - **Property 21: Documentation Generation Completeness**
    - **Validates: Requirements 8.1, 8.2, 8.4, 8.5**

- [ ] 12. Measure Phase 1 POC assets
  - [ ] 12.1 Create measurement script for POC assets
    - Write script to measure corridor.glb, room-small.glb, room-large.glb
    - Store measurements in database
    - Export to JSON for version control
    - _Requirements: All_
  
  - [ ] 12.2 Generate documentation for POC assets
    - Run DocumentationGenerator on all three assets
    - Save markdown files to docs/ directory
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [ ] 12.3 Write integration test for complete workflow
    - Test: load asset → measure → store → retrieve → validate
    - Use all three POC assets
    - _Requirements: All_

- [ ] 13. Final checkpoint - Ensure all tests pass
  - Run all unit tests and property tests
  - Verify POC assets are fully documented
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive test coverage
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties (100+ iterations each)
- Unit tests validate specific examples and edge cases
- Checkpoints ensure incremental validation
- Phase 1 focuses on three Kenney assets; system is designed to work with any dungeon asset format
