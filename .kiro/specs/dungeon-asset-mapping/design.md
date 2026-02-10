# Design Document: Dungeon Asset Mapping System

## Overview

The Dungeon Asset Mapping System is a measurement and analysis tool for **all dungeon assets** in the TR-Dungeons game. It provides precise dimensional data, connection formulas, and validation utilities to enable rapid, accurate dungeon construction regardless of asset source (Kenney, Synty, custom, etc.).

The system is designed to be asset-agnostic, working with any GLB or FBX format dungeon assets. It analyzes geometry, collision, and connection points without requiring asset-specific knowledge.

The system consists of two main components:
1. **Asset_Mapper**: Measures and documents asset properties (dimensions, connection points, collision geometry)
2. **Layout_Calculator**: Computes spacing formulas and validates dungeon layouts

**Phase 1 (POC)** focuses on three Kenney assets to validate the system: corridor.glb, room-small.glb, and room-large.glb. Once proven, the system will extend to all dungeon assets from any source.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                  Dungeon Asset Mapping                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐         ┌───────────────────┐   │
│  │  Asset_Mapper    │────────▶│  Asset_Metadata   │   │
│  │                  │         │  Database         │   │
│  │ - Measure dims   │         │                   │   │
│  │ - Find origins   │         │ - Dimensions      │   │
│  │ - Map collision  │         │ - Connections     │   │
│  │ - Doc connections│         │ - Collision       │   │
│  └──────────────────┘         │ - Rotations       │   │
│           │                   └───────────────────┘   │
│           │                            │              │
│           ▼                            ▼              │
│  ┌──────────────────┐         ┌───────────────────┐   │
│  │ Layout_Calculator│◀────────│  Spacing_Formula  │   │
│  │                  │         │  Engine           │   │
│  │ - Calc spacing   │         │                   │   │
│  │ - Validate gaps  │         │ - Distance→Count  │   │
│  │ - Check overlaps │         │ - Overlap calc    │   │
│  │ - Verify nav     │         │ - Tolerance check │   │
│  └──────────────────┘         └───────────────────┘   │
│           │                                            │
│           ▼                                            │
│  ┌──────────────────┐                                 │
│  │  Documentation   │                                 │
│  │  Generator       │                                 │
│  │                  │                                 │
│  │ - Markdown docs  │                                 │
│  │ - Visual diagrams│                                 │
│  │ - Formula examples│                                │
│  └──────────────────┘                                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Measurement Phase**: Asset_Mapper loads GLB files and extracts geometric data
2. **Analysis Phase**: Asset_Mapper computes connection points, collision boundaries, and rotation transforms
3. **Storage Phase**: Measurements are stored in Asset_Metadata database (GDScript Dictionary/JSON)
4. **Calculation Phase**: Layout_Calculator uses metadata to compute spacing and validate layouts
5. **Documentation Phase**: Documentation_Generator creates human-readable reference materials

## Components and Interfaces

### Asset_Mapper

The Asset_Mapper is responsible for measuring and analyzing individual assets. It works with **any dungeon asset** regardless of source (Kenney GLB, Synty FBX, custom models, etc.) by analyzing the actual geometry and collision data.

**Interface:**
```gdscript
class_name AssetMapper
extends RefCounted

# Measure an asset and return metadata
# Works with GLB, FBX, or any Godot-compatible 3D format
func measure_asset(asset_path: String) -> AssetMetadata:
    var scene = load(asset_path).instantiate()
    var metadata = AssetMetadata.new()
    
    metadata.asset_path = asset_path
    metadata.asset_format = _detect_format(asset_path)  # GLB, FBX, etc.
    metadata.bounding_box = _calculate_bounding_box(scene)
    metadata.origin_offset = _find_origin_offset(scene)
    metadata.floor_height = _measure_floor_height(scene)
    metadata.connection_points = _find_connection_points(scene)
    metadata.collision_geometry = _extract_collision_geometry(scene)
    metadata.default_rotation = _determine_default_rotation(scene)
    
    scene.queue_free()
    return metadata

# Calculate AABB for the asset
func _calculate_bounding_box(node: Node3D) -> AABB:
    # Recursively find all MeshInstance3D nodes
    # Combine their AABBs in world space
    # Return unified bounding box

# Find where origin is relative to geometry
func _find_origin_offset(node: Node3D) -> Vector3:
    # Calculate center of bounding box
    # Return offset from origin to center

# Measure floor height (Y coordinate where characters walk)
func _measure_floor_height(node: Node3D) -> float:
    # Find lowest walkable surface
    # Return Y coordinate

# Identify connection points (doors, corridor ends)
func _find_connection_points(node: Node3D) -> Array[ConnectionPoint]:
    # Look for specific markers or geometry patterns
    # Calculate connection coordinates and normals
    # Return array of connection points

# Extract collision shape data
func _extract_collision_geometry(node: Node3D) -> CollisionData:
    # Find all CollisionShape3D nodes
    # Extract shape dimensions and positions
    # Calculate walkable area boundaries

# Determine default facing direction
func _determine_default_rotation(node: Node3D) -> Vector3:
    # Analyze geometry orientation
    # Return default rotation (Euler angles)
```

**Key Methods:**
- `measure_asset(path)`: Main entry point, returns complete AssetMetadata. Works with any 3D asset format.
- `_detect_format(path)`: Identifies asset format (GLB, FBX, etc.) from file extension
- `_calculate_bounding_box(node)`: Computes AABB with ±0.1 unit accuracy, works with any mesh type
- `_find_connection_points(node)`: Identifies doors and corridor ends using geometry analysis (not asset-specific markers)
- `_extract_collision_geometry(node)`: Maps collision boundaries from CollisionShape3D nodes (standard across all assets)

### AssetMetadata

Data structure holding all measurements for a single asset. **Asset-agnostic** - works with any dungeon asset source.

**Structure:**
```gdscript
class_name AssetMetadata
extends Resource

@export var asset_name: String
@export var asset_path: String
@export var asset_format: String  # "GLB", "FBX", etc.
@export var asset_source: String  # "Kenney", "Synty", "Custom", etc. (optional metadata)
@export var measurement_timestamp: int

# Dimensions
@export var bounding_box: AABB
@export var origin_offset: Vector3
@export var floor_height: float
@export var wall_thickness: float

# Connections
@export var connection_points: Array[ConnectionPoint]
@export var doorway_dimensions: Vector2  # Width x Height

# Collision
@export var collision_shapes: Array[CollisionData]
@export var walkable_area: AABB

# Rotation
@export var default_rotation: Vector3
@export var rotation_pivot: Vector3

# Metadata
@export var measurement_accuracy: float = 0.1

func to_dict() -> Dictionary:
    # Convert to dictionary for JSON export

func from_dict(data: Dictionary) -> void:
    # Load from dictionary
```

### ConnectionPoint

Represents a point where assets connect.

**Structure:**
```gdscript
class_name ConnectionPoint
extends Resource

@export var position: Vector3  # Local space coordinates
@export var normal: Vector3    # Direction facing outward
@export var type: String       # "door", "corridor_end", "opening"
@export var dimensions: Vector2 # Width x Height

func transform_by_rotation(rotation: Vector3) -> ConnectionPoint:
    # Return new ConnectionPoint with rotated position and normal
```

### Layout_Calculator

Computes spacing requirements and validates layouts.

**Interface:**
```gdscript
class_name LayoutCalculator
extends RefCounted

var metadata_db: AssetMetadataDatabase

# Calculate number of corridor pieces needed for distance
func calculate_corridor_count(distance: float, corridor_metadata: AssetMetadata) -> int:
    var corridor_length = corridor_metadata.bounding_box.size.z
    var overlap = _calculate_overlap(corridor_metadata)
    var effective_length = corridor_length - overlap
    
    # Formula: count = ceil((distance - overlap) / effective_length)
    return ceili((distance - overlap) / effective_length)

# Calculate overlap at connection points
func _calculate_overlap(metadata: AssetMetadata) -> float:
    # Analyze connection points to determine overlap
    # Return overlap distance

# Validate connection between two assets
func validate_connection(
    asset_a: AssetMetadata, 
    pos_a: Vector3, 
    rot_a: Vector3,
    asset_b: AssetMetadata, 
    pos_b: Vector3, 
    rot_b: Vector3
) -> ValidationResult:
    
    var result = ValidationResult.new()
    
    # Transform connection points by rotation
    var conn_a = _find_closest_connection(asset_a, pos_a, rot_a, pos_b)
    var conn_b = _find_closest_connection(asset_b, pos_b, rot_b, pos_a)
    
    # Check alignment
    var gap = conn_a.position.distance_to(conn_b.position)
    result.has_gap = gap > 0.2
    result.has_overlap = gap < -0.5
    result.gap_distance = gap
    
    # Check normal alignment (should face opposite directions)
    var normal_alignment = conn_a.normal.dot(conn_b.normal)
    result.normals_aligned = abs(normal_alignment + 1.0) < 0.1
    
    return result

# Validate entire layout
func validate_layout(layout: Array[PlacedAsset]) -> LayoutValidationResult:
    # Check all connections
    # Verify navigation continuity
    # Return comprehensive validation result
```

**Key Methods:**
- `calculate_corridor_count(distance, metadata)`: Implements spacing formula
- `validate_connection(a, b)`: Checks for gaps/overlaps between two assets
- `validate_layout(assets)`: Validates entire dungeon layout

### AssetMetadataDatabase

Stores and retrieves asset metadata.

**Interface:**
```gdscript
class_name AssetMetadataDatabase
extends Resource

var _metadata: Dictionary = {}  # asset_name -> AssetMetadata

func store(metadata: AssetMetadata) -> void:
    _metadata[metadata.asset_name] = metadata

func get_metadata(asset_name: String) -> AssetMetadata:
    return _metadata.get(asset_name)

func has_metadata(asset_name: String) -> bool:
    return _metadata.has(asset_name)

func save_to_json(path: String) -> void:
    var data = {}
    for key in _metadata:
        data[key] = _metadata[key].to_dict()
    
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()

func load_from_json(path: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()
    
    var data = JSON.parse_string(json_string)
    for key in data:
        var metadata = AssetMetadata.new()
        metadata.from_dict(data[key])
        _metadata[key] = metadata
```

### Documentation_Generator

Generates human-readable documentation.

**Interface:**
```gdscript
class_name DocumentationGenerator
extends RefCounted

func generate_asset_doc(metadata: AssetMetadata) -> String:
    # Generate markdown documentation for single asset
    # Include dimensions, connection points, diagrams

func generate_spacing_doc(calculator: LayoutCalculator) -> String:
    # Generate documentation for spacing formulas
    # Include worked examples at 10, 15, 20, 30 units

func generate_rotation_doc(metadata: AssetMetadata) -> String:
    # Generate rotation transformation documentation
    # Include matrices for N/S/E/W orientations
```

## Data Models

### AssetMetadata Schema

Example for a Kenney corridor asset (Phase 1 POC):

```json
{
  "asset_name": "corridor",
  "asset_path": "res://assets/models/kenney-dungeon/corridor.glb",
  "asset_format": "GLB",
  "asset_source": "Kenney",
  "measurement_timestamp": 1234567890,
  "bounding_box": {
    "position": {"x": -1.0, "y": 0.0, "z": -2.5},
    "size": {"x": 2.0, "y": 3.0, "z": 5.0}
  },
  "origin_offset": {"x": 0.0, "y": 0.0, "z": 0.0},
  "floor_height": 0.0,
  "wall_thickness": 0.2,
  "connection_points": [
    {
      "position": {"x": 0.0, "y": 1.5, "z": -2.5},
      "normal": {"x": 0.0, "y": 0.0, "z": -1.0},
      "type": "corridor_end",
      "dimensions": {"x": 2.0, "y": 3.0}
    },
    {
      "position": {"x": 0.0, "y": 1.5, "z": 2.5},
      "normal": {"x": 0.0, "y": 0.0, "z": 1.0},
      "type": "corridor_end",
      "dimensions": {"x": 2.0, "y": 3.0}
    }
  ],
  "collision_shapes": [
    {
      "type": "box",
      "position": {"x": 0.0, "y": 1.5, "z": 0.0},
      "size": {"x": 2.0, "y": 3.0, "z": 5.0}
    }
  ],
  "walkable_area": {
    "position": {"x": -0.9, "y": 0.0, "z": -2.4},
    "size": {"x": 1.8, "y": 0.1, "z": 4.8}
  },
  "default_rotation": {"x": 0.0, "y": 0.0, "z": 0.0},
  "rotation_pivot": {"x": 0.0, "y": 0.0, "z": 0.0},
  "measurement_accuracy": 0.1
}
```

### ValidationResult Schema

```gdscript
class_name ValidationResult
extends RefCounted

var is_valid: bool
var has_gap: bool
var has_overlap: bool
var gap_distance: float
var normals_aligned: bool
var error_messages: Array[String]
```

### PlacedAsset Schema

```gdscript
class_name PlacedAsset
extends RefCounted

var metadata: AssetMetadata
var position: Vector3
var rotation: Vector3  # Euler angles
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Bounding Box Measurement Accuracy

*For any* asset loaded by the Asset_Mapper, the measured bounding box dimensions should be within ±0.1 units of the actual geometry extent in all three axes (X, Y, Z).

**Validates: Requirements 1.1**

### Property 2: Origin Offset Calculation

*For any* asset with known geometry, the calculated origin offset should correctly represent the vector from the origin point (0,0,0) to the geometric center of the asset.

**Validates: Requirements 1.2**

### Property 3: Visual vs Collision Extent Distinction

*For any* asset containing both visual geometry and collision shapes, the Asset_Mapper should correctly identify both extents and they should be measurably different (collision extent should not equal visual extent for assets with distinct collision geometry).

**Validates: Requirements 1.3**

### Property 4: Connection Point Discovery

*For any* corridor asset, the Asset_Mapper should identify exactly 2 connection points (entry and exit), and for any room asset, all identified connection points should correspond to actual openings in the geometry.

**Validates: Requirements 2.1, 2.2**

### Property 5: Connection Point Coordinate System

*For any* connection point documented by the Asset_Mapper, the coordinates should be in local asset space (relative to the asset's origin), not world space.

**Validates: Requirements 2.4**

### Property 6: Connection Alignment Tolerance

*For any* two assets placed at connection points, the Layout_Calculator should validate that connection points align within ±0.1 unit tolerance, rejecting connections with greater misalignment.

**Validates: Requirements 2.5**

### Property 7: Corridor Count Formula

*For any* target distance and corridor metadata, the Layout_Calculator should compute a corridor count such that placing that many corridors results in a total length within ±0.5 units of the target distance.

**Validates: Requirements 3.1, 3.2**

### Property 8: Overlap Calculation Consistency

*For any* pair of connecting assets, the calculated overlap at connection points should be consistent regardless of which asset is considered first or second in the calculation.

**Validates: Requirements 3.2, 3.5**

### Property 9: Rotation Transform Round-Trip

*For any* asset and any rotation angle, applying a rotation transformation to connection points and then applying the inverse rotation should return connection points to their original positions within ±0.01 unit tolerance.

**Validates: Requirements 4.3**

### Property 10: Cardinal Direction Rotation Completeness

*For any* asset, the Asset_Mapper should provide rotation transformations for all four cardinal directions (North, South, East, West), and each transformation should produce distinct orientations.

**Validates: Requirements 4.2**

### Property 11: Rotation Preserves Connection Alignment

*For any* asset rotated to any cardinal direction, the transformed connection points should maintain valid alignment properties (normals should still face outward, dimensions should be preserved).

**Validates: Requirements 4.5, 7.5**

### Property 12: Walkable Area Containment

*For any* room asset, the defined walkable area boundaries should be fully contained within the room's bounding box and should not overlap with wall collision boundaries.

**Validates: Requirements 5.2, 5.5**

### Property 13: Collision Geometry Documentation Completeness

*For any* asset with collision shapes, the Asset_Mapper should document all collision shape dimensions, and the documented dimensions should match the actual collision shape extents within ±0.1 units.

**Validates: Requirements 5.1, 5.3**

### Property 14: Metadata Storage Round-Trip

*For any* AssetMetadata object, storing it to GDScript format and then loading it back should produce an equivalent metadata object with all fields preserved (dimensions, connection points, collision data).

**Validates: Requirements 6.1, 6.2**

### Property 15: JSON Export Round-Trip

*For any* AssetMetadata object, exporting to JSON format and then importing should produce an equivalent metadata object with all numerical values preserved within ±0.001 precision.

**Validates: Requirements 6.5**

### Property 16: Metadata Query Performance

*For any* asset name in the database, querying its metadata should complete within 1 millisecond, measured across at least 100 consecutive queries.

**Validates: Requirements 6.3**

### Property 17: Version History Preservation

*For any* metadata update operation, the previous version of the metadata should remain accessible, and comparing old and new versions should show only the intended changes.

**Validates: Requirements 6.4**

### Property 18: Gap and Overlap Detection

*For any* two assets placed at specified positions, the Layout_Calculator should correctly detect gaps larger than 0.2 units and overlaps larger than 0.5 units at connection points, with no false positives or false negatives.

**Validates: Requirements 7.1, 7.2**

### Property 19: Layout Connection Validation

*For any* layout containing multiple connected assets, the Layout_Calculator should verify that all connection points align within tolerance, and validation should fail if any connection exceeds tolerance.

**Validates: Requirements 7.3**

### Property 20: Navigation Path Continuity

*For any* valid layout, the walkable areas of connected assets should form continuous paths (no gaps in walkable areas at connection points).

**Validates: Requirements 7.4**

### Property 21: Documentation Generation Completeness

*For any* asset with complete metadata, the generated markdown documentation should include all required sections (dimensions, connection points, collision geometry, rotation transforms) and should be valid markdown syntax.

**Validates: Requirements 8.1, 8.2, 8.4, 8.5**

## Error Handling

### Measurement Errors

**Missing Geometry:**
- If an asset has no MeshInstance3D nodes, Asset_Mapper should return an error indicating no geometry found
- Bounding box should be set to zero-size AABB at origin

**Invalid Asset Path:**
- If asset file doesn't exist or can't be loaded, Asset_Mapper should return null metadata with error message
- Error should include the attempted path for debugging

**Malformed Collision:**
- If collision shapes are malformed or have zero dimensions, Asset_Mapper should log warning and skip that collision shape
- Continue processing other collision shapes

### Calculation Errors

**Invalid Distance:**
- If distance is negative or zero, Layout_Calculator should return error
- Corridor count should be -1 to indicate error state

**Missing Metadata:**
- If required metadata is not in database, Layout_Calculator should return error with asset name
- Validation should fail gracefully with descriptive error message

**Numerical Precision:**
- All floating-point comparisons should use epsilon tolerance (0.0001) to handle precision errors
- Avoid exact equality checks on floats

### Validation Errors

**Disconnected Layout:**
- If layout has assets with no valid connections, validation should report which assets are disconnected
- Provide suggestions for fixing (e.g., "Asset A has no connection points facing Asset B")

**Rotation Errors:**
- If rotation angle is not a multiple of 90 degrees, round to nearest cardinal direction and log warning
- Invalid rotation matrices should be rejected with error

## Testing Strategy

### Dual Testing Approach

This system requires both **unit tests** and **property-based tests** for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs using randomized testing

### Unit Testing Focus

Unit tests should cover:
- **Phase 1 POC assets**: Specific tests for corridor.glb, room-small.glb, room-large.glb (Kenney)
- **Multiple asset formats**: Test both GLB (Kenney) and FBX (Synty) format handling
- **Edge cases**: Empty assets, assets with no collision, malformed geometry (any source)
- **Error conditions**: Missing files, invalid paths, null inputs
- **Integration points**: Database storage/retrieval, JSON export/import
- **Specific examples**: 20 units = 3 corridors (Kenney), test distances at 10, 15, 30 units

**Example unit tests:**
```gdscript
func test_kenney_corridor_measurement():
    # Phase 1: Test Kenney GLB asset
    var mapper = AssetMapper.new()
    var metadata = mapper.measure_asset("res://assets/models/kenney-dungeon/corridor.glb")
    assert_not_null(metadata)
    assert_eq(metadata.asset_format, "GLB")
    assert_eq(metadata.asset_source, "Kenney")
    assert_almost_eq(metadata.bounding_box.size.z, 5.0, 0.1)

func test_synty_corridor_measurement():
    # Future: Test Synty FBX asset (when available)
    var mapper = AssetMapper.new()
    var metadata = mapper.measure_asset("res://assets/models/synty-dungeon/SM_Prop_Hallway_01.fbx")
    assert_not_null(metadata)
    assert_eq(metadata.asset_format, "FBX")
    assert_eq(metadata.asset_source, "Synty")

func test_spacing_formula_known_case():
    # Validates Requirements 3.3 (using Kenney corridor)
    var calculator = LayoutCalculator.new()
    var corridor_metadata = _load_corridor_metadata()
    var count = calculator.calculate_corridor_count(20.0, corridor_metadata)
    assert_eq(count, 3, "20 units should equal 3 corridor pieces")
```

### Property-Based Testing Configuration

**Library:** Use GDScript property-based testing library (or implement minimal generator framework)

**Configuration:**
- Minimum **100 iterations** per property test
- Each test must reference its design document property
- Tag format: `# Feature: dungeon-asset-mapping, Property N: [property text]`

**Property Test Examples:**

```gdscript
# Feature: dungeon-asset-mapping, Property 1: Bounding Box Measurement Accuracy
func test_property_bounding_box_accuracy():
    for i in range(100):
        var test_asset = _generate_random_test_asset()
        var mapper = AssetMapper.new()
        var metadata = mapper.measure_asset(test_asset.path)
        
        var actual_size = _calculate_actual_geometry_size(test_asset)
        assert_almost_eq(metadata.bounding_box.size.x, actual_size.x, 0.1)
        assert_almost_eq(metadata.bounding_box.size.y, actual_size.y, 0.1)
        assert_almost_eq(metadata.bounding_box.size.z, actual_size.z, 0.1)

# Feature: dungeon-asset-mapping, Property 9: Rotation Transform Round-Trip
func test_property_rotation_round_trip():
    for i in range(100):
        var metadata = _generate_random_asset_metadata()
        var rotation = _generate_random_rotation()  # 0, 90, 180, 270 degrees
        
        var original_points = metadata.connection_points.duplicate()
        
        # Apply rotation
        var rotated_points = []
        for point in original_points:
            rotated_points.append(point.transform_by_rotation(rotation))
        
        # Apply inverse rotation
        var inverse_rotation = Vector3(0, -rotation.y, 0)
        var restored_points = []
        for point in rotated_points:
            restored_points.append(point.transform_by_rotation(inverse_rotation))
        
        # Verify round-trip
        for j in range(original_points.size()):
            assert_almost_eq(
                original_points[j].position.distance_to(restored_points[j].position),
                0.0,
                0.01
            )

# Feature: dungeon-asset-mapping, Property 15: JSON Export Round-Trip
func test_property_json_round_trip():
    for i in range(100):
        var original_metadata = _generate_random_asset_metadata()
        
        # Export to JSON
        var json_string = JSON.stringify(original_metadata.to_dict())
        
        # Import from JSON
        var restored_metadata = AssetMetadata.new()
        restored_metadata.from_dict(JSON.parse_string(json_string))
        
        # Verify equivalence
        assert_almost_eq(
            original_metadata.bounding_box.size.x,
            restored_metadata.bounding_box.size.x,
            0.001
        )
        assert_eq(
            original_metadata.connection_points.size(),
            restored_metadata.connection_points.size()
        )
```

### Test Data Generation

For property-based tests, implement generators for:
- Random asset metadata with valid dimensions
- Random connection points with valid positions and normals
- Random rotations (0°, 90°, 180°, 270°)
- Random layouts with multiple connected assets
- Edge cases: zero-size assets, single-point assets, assets with many connections

### Integration Testing

Integration tests should verify:
- Complete measurement workflow: load asset → measure → store → retrieve (any format)
- Complete layout workflow: load metadata → calculate spacing → validate layout
- Documentation generation: measure asset → generate docs → verify completeness
- **Multi-source compatibility**: Mix Kenney and Synty assets in same layout (future phase)
- End-to-end: measure POC assets → calculate spacing → build test layout → validate

### Test Execution

Run tests using Godot's GUT framework:
```bash
# All tests
godot --headless --script addons/gut/gut_cmdln.gd

# Unit tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

### Success Criteria

All tests must pass before considering the system complete:
- All unit tests pass (specific examples and edge cases)
- All property tests pass with 100+ iterations each
- Integration tests verify end-to-end workflows
- **Phase 1 POC**: Kenney assets (corridor, room-small, room-large) fully documented with passing tests
- **System validates asset-agnostic design**: Works with any GLB/FBX dungeon asset, not just Kenney
