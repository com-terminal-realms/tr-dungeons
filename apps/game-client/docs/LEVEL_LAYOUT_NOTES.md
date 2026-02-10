# Level Layout Notes

## Room and Corridor Positioning

This document tracks the positioning of rooms and corridors in the main dungeon scene.

**IMPORTANT**: All positions are calculated using measured asset dimensions from the asset mapping system. See `data/asset_metadata.json` for exact measurements.

### Asset Dimensions (Measured)

- **corridor.glb**: 4×3×4 units (W×H×L) - Square piece, not a long hallway!
- **room-small.glb**: 12×3.13×12 units
- **room-wide.glb**: 20×3.33×12 units (wide in X, same Z as room-small)
- **room-large.glb**: 20×3.33×20 units

### Room Positions (Z-axis)

- **Room1**: z=0 (Start room, room-large)
- **Room2**: z=31.85 (room-large)
- **Room3**: z=63.70 (room-large, 1 enemy)
- **Room4**: z=95.55 (room-large, 2 enemies)
- **Room5**: z=119.50 (room-large, Boss)

### Corridor Positions (Z-axis)

All corridors use 4×4 unit pieces with effective length of 3.95 units. Offsets are relative to the corridor's center position.

- **Corridor1to2**: z=15.93 (3 pieces at offsets -3.95, 0, +3.95)
- **Corridor2to3**: z=47.78 (3 pieces at offsets -3.95, 0, +3.95)
- **Corridor3to4**: z=79.63 (3 pieces at offsets -3.95, 0, +3.95)
- **Corridor4to5**: z=107.53 (1 piece at offset 0)

### Corridor Piece Rotation

All corridor pieces use the same rotation to align them along the Z-axis:
```
transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, x, y, z)
```

This rotates the corridor 90 degrees to run north-south instead of east-west.

### Connection Validation

All connections have been validated using the asset mapping system:
- ✅ All 8 connections are within ±0.1 unit tolerance
- ✅ No gaps detected
- ✅ No overlaps detected

Run validation: `godot --headless --script scripts/utils/validate_poc_layout.gd`

### Enemy Placement

- **Room3**: 1 enemy at (0, 1, 0) relative to room
- **Room4**: 2 enemies at (-5, 1, 0) and (5, 1, 0) relative to room
- **Room5**: 1 boss at (0, 1, 0) relative to room, scaled 2x

### Design Notes

- Total dungeon length: 119.5 units (properly accounts for room sizes)
- Corridor pieces are 4×4 units (square), with effective length of 3.95 units
- Each corridor piece connects perfectly to room doorways
- All spacing calculated accounting for room half-sizes (±10 units for room-large)
- Corridor4to5 uses only 1 piece (shortest corridor in the dungeon)
- Layout generated using edge-to-edge distance calculation

### Future Improvements

- Consider adding corner pieces for more interesting layouts
- Add side rooms or branches
- Implement procedural generation based on these spacing rules
- Add more enemy variety in later rooms
- Use the asset mapping system to automatically calculate positions


---

## Algorithm Implementation (February 2026)

### New Position-from-Count Algorithm Applied

The POC layout has been **updated** to use the new `calculate_position_from_corridor_count()` algorithm:

**New Correct Layout:**
- Total length: 119.5 units (properly accounts for room sizes!)
- Uses edge-to-edge distance calculation
- Corridor effective length: 3.95 units (4.0 - 2×0.025 overlap)
- Room half-size: 10 units (room-large is 20×20)
- All positions calculated accounting for room dimensions

**Corridor Count:**
- ✅ Room1→Room2: 3 corridors (edge-to-edge distance: 11.85 units)
- ✅ Room2→Room3: 3 corridors (edge-to-edge distance: 11.85 units)
- ✅ Room3→Room4: 3 corridors (edge-to-edge distance: 11.85 units)
- ✅ Room4→Room5: 1 corridor (edge-to-edge distance: 3.95 units)

### Benefits of New Layout

1. **Exact positioning**: No tolerance issues, positions are mathematically precise
2. **Compact design**: More efficient use of space (39.5 vs 92 units)
3. **Algorithm-driven**: Demonstrates the new position-from-count method
4. **Predictable**: Easy to calculate and verify positions

### How Positions Were Calculated

```gdscript
# The key insight: calculate edge-to-edge distances, not center-to-center!
# Room-large has connection points at ±10 units from center

var room_half_size = 10.0  # room-large is 20×20 units
var corridor_effective_length = 3.95  # 4.0 - 2*0.025 overlap

# Room1 at origin
var room1_z = 0.0

# Room2 position = Room1 center + Room1 half-size + corridor distance + Room2 half-size
var room2_z = room1_z + room_half_size + (3 * corridor_effective_length) + room_half_size
# Result: 0 + 10 + 11.85 + 10 = 31.85

# Corridor1to2 center = midpoint between room edges
var corridor1to2_z = room1_z + room_half_size + (3 * corridor_effective_length / 2.0)
# Result: 0 + 10 + 5.925 = 15.93

# And so on...
```

See `scripts/utils/fix_poc_positions_correctly.gd` for the complete calculation.
