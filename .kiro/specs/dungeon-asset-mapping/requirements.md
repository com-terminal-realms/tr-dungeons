# Requirements Document: Dungeon Asset Mapping System

## Introduction

The Dungeon Asset Mapping System provides precise measurements and connection formulas for **all dungeon assets** in the TR-Dungeons game to enable rapid, accurate dungeon construction. The system is asset-agnostic, working with any GLB or FBX format dungeon assets from any source (Kenney, Synty Studios, custom models, etc.).

Phase 1 focuses on validating the system with three Kenney assets currently used in the proof-of-concept: corridor.glb, room-small.glb, and room-large.glb. Once proven, the system will extend to all dungeon assets.

## Glossary

- **Asset**: A 3D model file (GLB or FBX format) representing a dungeon component from any source (Kenney, Synty, custom, etc.)
- **Bounding_Box**: The rectangular volume that fully contains an asset's geometry
- **Origin_Point**: The (0,0,0) coordinate within an asset's local space
- **Connection_Point**: A specific coordinate where one asset connects to another
- **Spacing_Formula**: A mathematical function that calculates corridor count from distance
- **Collision_Geometry**: The physical boundaries used for collision detection and navigation
- **Walkable_Area**: The region within a room where characters can move
- **Asset_Mapper**: The system that measures and documents asset properties
- **Layout_Calculator**: The utility that computes spacing and placement
- **Navigation_Mesh**: The mesh defining valid pathfinding areas

## Requirements

### Requirement 1: Asset Dimension Measurement

**User Story:** As a level designer, I want precise measurements of asset dimensions, so that I can accurately position and connect dungeon pieces.

#### Acceptance Criteria

1. WHEN an asset is loaded, THE Asset_Mapper SHALL measure its bounding box dimensions in X, Y, and Z axes with ±0.1 unit accuracy
2. WHEN measuring an asset, THE Asset_Mapper SHALL identify the origin point location relative to the asset geometry
3. WHEN analyzing an asset, THE Asset_Mapper SHALL distinguish between visual extent and collision extent
4. WHEN measuring floor assets, THE Asset_Mapper SHALL determine the floor height where characters walk
5. WHEN measuring wall assets, THE Asset_Mapper SHALL calculate wall thickness
6. WHEN measuring room assets, THE Asset_Mapper SHALL identify doorway and opening dimensions

### Requirement 2: Connection Point Documentation

**User Story:** As a level designer, I want to know where assets connect to each other, so that I can create seamless dungeon layouts without gaps or overlaps.

#### Acceptance Criteria

1. WHEN analyzing a corridor asset, THE Asset_Mapper SHALL document both entry and exit connection points
2. WHEN analyzing a room asset, THE Asset_Mapper SHALL identify all door and opening positions
3. WHEN two assets are connected, THE Asset_Mapper SHALL define alignment points that ensure seamless connections
4. WHEN documenting connection points, THE Asset_Mapper SHALL record coordinates in local asset space
5. WHEN a connection is validated, THE Asset_Mapper SHALL verify that connection points align within ±0.1 unit tolerance

### Requirement 3: Spacing Formula Calculation

**User Story:** As a level designer, I want formulas that calculate corridor requirements, so that I can quickly determine how many corridor pieces are needed for any distance.

#### Acceptance Criteria

1. WHEN given a target distance, THE Layout_Calculator SHALL compute the number of corridor pieces required
2. WHEN calculating spacing, THE Layout_Calculator SHALL account for asset overlap at connection points
3. WHEN validating the formula, THE Layout_Calculator SHALL verify that 20 units equals 3 corridor pieces (current working configuration)
4. WHEN testing spacing, THE Layout_Calculator SHALL validate formulas at distances of 10, 15, 20, and 30 units
5. WHEN computing corridor count, THE Layout_Calculator SHALL define acceptable overlap tolerance ranges

### Requirement 4: Rotation and Orientation Mapping

**User Story:** As a level designer, I want to understand how asset rotation affects placement, so that I can orient dungeon pieces in any direction while maintaining correct connections.

#### Acceptance Criteria

1. WHEN documenting an asset, THE Asset_Mapper SHALL record its default facing direction
2. WHEN rotating an asset, THE Asset_Mapper SHALL provide rotation transformations for North, South, East, and West orientations
3. WHEN an asset is rotated, THE Asset_Mapper SHALL transform connection points according to the rotation
4. WHEN rotating an asset, THE Asset_Mapper SHALL identify the pivot point used for rotation
5. WHEN connection points are rotated, THE Asset_Mapper SHALL ensure transformed coordinates maintain connection alignment

### Requirement 5: Collision Geometry Analysis

**User Story:** As a level designer, I want collision boundaries documented, so that I can ensure proper navigation and prevent characters from walking through walls.

#### Acceptance Criteria

1. WHEN analyzing an asset, THE Asset_Mapper SHALL document collision shape dimensions
2. WHEN analyzing a room asset, THE Asset_Mapper SHALL define the walkable area boundaries
3. WHEN analyzing wall assets, THE Asset_Mapper SHALL map wall collision boundaries
4. WHEN generating navigation data, THE Asset_Mapper SHALL document navigation mesh generation parameters
5. WHEN validating collision geometry, THE Asset_Mapper SHALL verify that walkable areas do not overlap with wall collision boundaries

### Requirement 6: Asset Metadata Storage

**User Story:** As a developer, I want asset measurements stored in a queryable format, so that the game can programmatically access dimension and connection data.

#### Acceptance Criteria

1. WHEN measurements are complete, THE Asset_Mapper SHALL store asset metadata in GDScript-compatible format
2. WHEN storing metadata, THE Asset_Mapper SHALL include all dimensional measurements, connection points, and collision data
3. WHEN metadata is queried, THE Asset_Mapper SHALL return measurements for a specified asset within 1 millisecond
4. WHEN metadata is updated, THE Asset_Mapper SHALL preserve previous measurements for version comparison
5. WHEN exporting metadata, THE Asset_Mapper SHALL support JSON format for external tool integration

### Requirement 7: Layout Validation

**User Story:** As a level designer, I want automated validation of dungeon layouts, so that I can detect gaps, overlaps, and navigation issues before testing in-game.

#### Acceptance Criteria

1. WHEN two assets are placed, THE Layout_Calculator SHALL detect gaps larger than 0.2 units at connection points
2. WHEN two assets are placed, THE Layout_Calculator SHALL detect overlaps larger than 0.5 units at connection points
3. WHEN a layout is validated, THE Layout_Calculator SHALL verify that all connection points align within tolerance
4. WHEN validating navigation, THE Layout_Calculator SHALL confirm that walkable areas form continuous paths
5. WHEN rotation is applied, THE Layout_Calculator SHALL verify that rotated assets maintain valid connections

### Requirement 8: Documentation Generation

**User Story:** As a level designer, I want human-readable documentation of asset properties, so that I can reference measurements and formulas without reading code.

#### Acceptance Criteria

1. WHEN measurements are complete, THE Asset_Mapper SHALL generate markdown documentation for each asset
2. WHEN documenting an asset, THE Asset_Mapper SHALL include visual diagrams showing dimensions and connection points
3. WHEN documenting spacing formulas, THE Asset_Mapper SHALL provide worked examples at multiple distances
4. WHEN documenting rotation, THE Asset_Mapper SHALL include transformation matrices for all cardinal directions
5. WHEN documentation is generated, THE Asset_Mapper SHALL include timestamp and measurement accuracy metadata
