# Asset Mapping Testing Plan

## Goal
Create a comprehensive, testable system for mapping Kenney dungeon assets to game coordinates, enabling rapid and accurate dungeon construction.

## Critical Mapping Requirements

### 1. Asset Dimensions (Physical Measurements)
**What we need to know:**
- Exact bounding box dimensions (X, Y, Z) for each asset
- Origin point location within each asset
- Visual extent vs collision extent
- Floor height (where characters walk)
- Wall thickness
- Doorway/opening dimensions

**Why it's critical:**
- Prevents overlapping geometry
- Ensures proper spacing between rooms
- Enables accurate collision detection
- Allows procedural generation

**How to test:**
```gdscript
# Test: Measure asset bounds
func test_asset_dimensions():
    var asset = load("res://assets/models/kenney-dungeon/corridor.glb").instantiate()
    var aabb = _get_visual_bounds(asset)
    assert_eq(aabb.size.z, 2.0, "Corridor depth should be 2 units")
    assert_eq(aabb.size.x, 2.0, "Corridor width should be 2 units")
    assert_eq(aabb.size.y, 4.0, "Corridor height should be 4 units")
```

### 2. Connection Points (Snap Points)
**What we need to know:**
- Where corridors connect to rooms
- Door/opening positions on each room type
- Alignment points for seamless connections
- Entry/exit coordinates

**Why it's critical:**
- Ensures visual continuity (no gaps or overlaps)
- Enables automatic room connection
- Supports multiple connection types (N/S/E/W)

**How to test:**
```gdscript
# Test: Verify corridor connects to room without gap
func test_corridor_room_connection():
    var room = create_room_at(Vector3(0, 0, 0))
    var corridor = create_corridor_at(Vector3(0, 0, 10))
    
    var room_exit = room.get_exit_point("north")
    var corridor_entry = corridor.get_entry_point("south")
    
    var gap = room_exit.distance_to(corridor_entry)
    assert_lt(gap, 0.1, "Gap between room and corridor should be < 0.1 units")
```

### 3. Spacing Rules (Layout Mathematics)
**What we need to know:**
- Minimum distance between rooms
- Corridor length formulas based on room spacing
- How many corridor pieces needed for given distance
- Overlap tolerance (how much pieces can overlap)

**Why it's critical:**
- Enables consistent layouts
- Supports procedural generation
- Prevents visual artifacts
- Optimizes performance (fewer pieces)

**How to test:**
```gdscript
# Test: Calculate corridor pieces needed
func test_corridor_piece_calculation():
    var room1_pos = Vector3(0, 0, 0)
    var room2_pos = Vector3(0, 0, 20)
    
    var pieces_needed = calculate_corridor_pieces(room1_pos, room2_pos)
    assert_eq(pieces_needed, 3, "20-unit gap should need 3 corridor pieces")
    
    var piece_positions = calculate_corridor_positions(room1_pos, room2_pos)
    assert_eq(piece_positions.size(), 3)
    assert_eq(piece_positions[0].z, 8.0)  # First piece
    assert_eq(piece_positions[1].z, 10.0) # Middle piece
    assert_eq(piece_positions[2].z, 12.0) # Last piece
```

### 4. Rotation and Orientation
**What we need to know:**
- Default facing direction for each asset
- Rotation matrices for N/S/E/W orientations
- How rotation affects connection points
- Pivot point for rotations

**Why it's critical:**
- Enables corridors in any direction
- Supports complex layouts (L-shapes, T-junctions)
- Prevents misaligned connections

**How to test:**
```gdscript
# Test: Corridor rotation for different directions
func test_corridor_rotation():
    # North-South (along Z-axis)
    var ns_transform = get_corridor_transform("north")
    assert_eq(ns_transform.basis.x, Vector3(0, 0, 1))
    
    # East-West (along X-axis)
    var ew_transform = get_corridor_transform("east")
    assert_eq(ew_transform.basis.z, Vector3(1, 0, 0))
```

### 5. Collision Geometry
**What we need to know:**
- Collision shape dimensions for each asset
- Walkable area within rooms
- Wall collision boundaries
- Navigation mesh generation parameters

**Why it's critical:**
- Defines playable space
- Prevents characters walking through walls
- Enables pathfinding
- Affects gameplay feel

**How to test:**
```gdscript
# Test: Verify collision matches visual bounds
func test_collision_accuracy():
    var room = load("res://assets/models/kenney-dungeon/room-small.glb").instantiate()
    var visual_bounds = _get_visual_bounds(room)
    var collision_bounds = _get_collision_bounds(room)
    
    var difference = (visual_bounds.size - collision_bounds.size).length()
    assert_lt(difference, 0.5, "Collision should closely match visual bounds")
```

## Testing Strategy

### Phase 1: Asset Measurement (Property-Based Tests)
**Goal**: Measure and verify all asset dimensions

**Tests to write:**
1. `test_all_room_dimensions()` - Measure all room variants
2. `test_all_corridor_dimensions()` - Measure all corridor variants
3. `test_all_wall_dimensions()` - Measure wall pieces
4. `test_all_floor_dimensions()` - Measure floor tiles
5. `test_asset_origin_points()` - Verify origin is at expected location

**Property**: All assets of the same type should have consistent dimensions
```gdscript
# Property: All corridor variants have same depth
func test_corridor_depth_consistency():
    var corridor_types = ["corridor.glb", "corridor-wide.glb"]
    var depths = []
    
    for type in corridor_types:
        var asset = load("res://assets/models/kenney-dungeon/" + type).instantiate()
        depths.append(_get_visual_bounds(asset).size.z)
    
    # All corridors should have same depth for consistent spacing
    assert_almost_eq(depths[0], depths[1], 0.1)
```

### Phase 2: Connection Testing (Integration Tests)
**Goal**: Verify assets connect properly

**Tests to write:**
1. `test_room_corridor_connection()` - No gaps between room and corridor
2. `test_corridor_corridor_connection()` - Multiple corridor pieces align
3. `test_corner_connections()` - Corner pieces connect at 90°
4. `test_junction_connections()` - T-junctions and intersections
5. `test_rotated_connections()` - Connections work in all directions

**Example:**
```gdscript
func test_three_corridor_pieces_align():
    var corridor_parent = Node3D.new()
    corridor_parent.position = Vector3(0, 0, 10)
    
    var piece1 = create_corridor_piece(Vector3(0, 0, -2))
    var piece2 = create_corridor_piece(Vector3(0, 0, 0))
    var piece3 = create_corridor_piece(Vector3(0, 0, 2))
    
    corridor_parent.add_child(piece1)
    corridor_parent.add_child(piece2)
    corridor_parent.add_child(piece3)
    
    # Verify no gaps between pieces
    var gap1 = _measure_gap(piece1, piece2)
    var gap2 = _measure_gap(piece2, piece3)
    
    assert_lt(gap1, 0.01, "No gap between piece 1 and 2")
    assert_lt(gap2, 0.01, "No gap between piece 2 and 3")
```

### Phase 3: Layout Generation (Unit Tests)
**Goal**: Test mathematical formulas for layout

**Tests to write:**
1. `test_calculate_midpoint()` - Corridor placement between rooms
2. `test_calculate_corridor_count()` - How many pieces needed
3. `test_calculate_piece_positions()` - Where each piece goes
4. `test_room_spacing_validation()` - Minimum/maximum spacing
5. `test_layout_bounds()` - Total dungeon dimensions

**Example:**
```gdscript
func test_corridor_count_formula():
    # Formula: pieces = ceil((distance - room_overlap) / piece_depth)
    assert_eq(calculate_corridor_pieces(20), 3)  # 20 units = 3 pieces
    assert_eq(calculate_corridor_pieces(10), 2)  # 10 units = 2 pieces
    assert_eq(calculate_corridor_pieces(30), 5)  # 30 units = 5 pieces
```

### Phase 4: Collision and Navigation (Integration Tests)
**Goal**: Verify gameplay works correctly

**Tests to write:**
1. `test_character_can_walk_through_corridor()` - Pathfinding works
2. `test_character_cannot_walk_through_walls()` - Collision works
3. `test_navigation_mesh_generation()` - NavMesh covers walkable areas
4. `test_room_walkable_area()` - Characters can reach all room areas
5. `test_doorway_traversal()` - Characters can enter/exit rooms

**Example:**
```gdscript
func test_corridor_is_walkable():
    var dungeon = create_test_dungeon()
    var start = Vector3(0, 1, 0)  # Room 1
    var end = Vector3(0, 1, 20)   # Room 2
    
    var path = dungeon.get_navigation_path(start, end)
    
    assert_not_null(path, "Path should exist through corridor")
    assert_gt(path.size(), 0, "Path should have waypoints")
    
    # Verify path goes through corridor midpoint
    var corridor_point = Vector3(0, 1, 10)
    var path_passes_corridor = false
    for point in path:
        if point.distance_to(corridor_point) < 2.0:
            path_passes_corridor = true
            break
    
    assert_true(path_passes_corridor, "Path should go through corridor")
```

### Phase 5: Visual Validation (Manual + Screenshot Tests)
**Goal**: Ensure layouts look correct

**Tests to write:**
1. `test_no_visual_gaps()` - Screenshot comparison
2. `test_no_z_fighting()` - Check for overlapping geometry
3. `test_lighting_consistency()` - Shadows render correctly
4. `test_texture_alignment()` - Textures don't stretch/distort

## Data Structures Needed

### 1. Asset Metadata Database
```gdscript
# res://data/asset_metadata.gd
const ASSET_DATA = {
    "corridor.glb": {
        "dimensions": Vector3(2, 4, 2),
        "origin": Vector3(0, 0, 0),
        "connection_points": {
            "north": Vector3(0, 0, 1),
            "south": Vector3(0, 0, -1)
        },
        "collision_shape": "box",
        "walkable_area": Rect2(-0.8, -0.8, 1.6, 1.6)
    },
    "room-small.glb": {
        "dimensions": Vector3(4, 4, 4),
        "origin": Vector3(0, 0, 0),
        "connection_points": {
            "north": Vector3(0, 0, 2),
            "south": Vector3(0, 0, -2),
            "east": Vector3(2, 0, 0),
            "west": Vector3(-2, 0, 0)
        },
        "collision_shape": "box",
        "walkable_area": Rect2(-1.5, -1.5, 3.0, 3.0)
    }
}
```

### 2. Layout Calculator
```gdscript
# res://scripts/utils/dungeon_layout_calculator.gd
class_name DungeonLayoutCalculator

static func calculate_corridor_pieces(distance: float, piece_depth: float = 2.0) -> int:
    return ceili(distance / piece_depth)

static func calculate_corridor_positions(room1_pos: Vector3, room2_pos: Vector3) -> Array[Vector3]:
    var midpoint = (room1_pos + room2_pos) / 2.0
    var distance = room1_pos.distance_to(room2_pos)
    var piece_count = calculate_corridor_pieces(distance)
    
    var positions: Array[Vector3] = []
    var start_offset = -(piece_count - 1) * 1.0  # Assuming 2-unit pieces with 2-unit spacing
    
    for i in range(piece_count):
        var offset = start_offset + (i * 2.0)
        positions.append(midpoint + Vector3(0, 0, offset))
    
    return positions

static func get_rotation_for_direction(direction: String) -> Transform3D:
    match direction:
        "north", "south":
            return Transform3D(Basis(Vector3(0, 1, 0), PI/2), Vector3.ZERO)
        "east", "west":
            return Transform3D.IDENTITY
        _:
            push_error("Invalid direction: " + direction)
            return Transform3D.IDENTITY
```

### 3. Asset Loader with Validation
```gdscript
# res://scripts/utils/validated_asset_loader.gd
class_name ValidatedAssetLoader

static func load_room(asset_name: String, position: Vector3) -> Node3D:
    var metadata = AssetMetadata.get_data(asset_name)
    if metadata == null:
        push_error("No metadata for asset: " + asset_name)
        return null
    
    var asset = load("res://assets/models/kenney-dungeon/" + asset_name).instantiate()
    asset.position = position
    
    # Validate dimensions match metadata
    var actual_bounds = _get_bounds(asset)
    var expected_bounds = metadata.dimensions
    
    if not actual_bounds.is_equal_approx(expected_bounds):
        push_warning("Asset dimensions don't match metadata: " + asset_name)
    
    return asset
```

## Implementation Priority

### High Priority (Week 1)
1. ✅ Measure all corridor dimensions accurately
2. ✅ Test corridor piece spacing (3 pieces for 20 units)
3. ✅ Verify room-corridor connections
4. Create asset metadata database
5. Write dimension measurement tests

### Medium Priority (Week 2)
6. Test all room types (small, wide, large, corner)
7. Test corridor variants (wide, corner, junction)
8. Create layout calculator utility
9. Write connection validation tests
10. Test rotation for all directions

### Low Priority (Week 3)
11. Test complex layouts (branches, loops)
12. Create visual validation tests
13. Document all findings
14. Create dungeon builder tool
15. Add procedural generation

## Success Criteria

✅ **Complete** when:
1. All asset dimensions documented with ±0.1 unit accuracy
2. 100% of connection tests pass (no gaps/overlaps)
3. Layout calculator produces correct positions for any room spacing
4. Navigation works through all generated layouts
5. Visual inspection shows no artifacts
6. Documentation enables anyone to build dungeons quickly

## Tools Needed

1. **Asset Inspector Tool** - GUI to measure and visualize asset bounds
2. **Layout Visualizer** - Top-down view showing room/corridor positions
3. **Connection Validator** - Highlights gaps/overlaps in real-time
4. **Test Dungeon Generator** - Creates test layouts automatically
5. **Screenshot Comparison** - Detects visual regressions

## Next Steps

1. Create `asset_metadata.gd` with initial measurements
2. Write `test_corridor_dimensions.gd` property test
3. Create `dungeon_layout_calculator.gd` utility
4. Write `test_corridor_spacing.gd` integration test
5. Document findings in `ASSET_MAPPING_RESULTS.md`
