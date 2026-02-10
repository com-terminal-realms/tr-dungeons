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

- **Room1**: z=0 (Start room, room-small)
- **Room2**: z=24 (room-small)
- **Room3**: z=48 (room-wide, 1 enemy)
- **Room4**: z=72 (room-wide, 2 enemies)
- **Room5**: z=92 (room-large, Boss)

### Corridor Positions (Z-axis)

All corridors use 4×4 unit pieces. Offsets are relative to the corridor's center position.

- **Corridor1to2**: z=12 (3 pieces at offsets -4, 0, +4)
- **Corridor2to3**: z=36 (3 pieces at offsets -4, 0, +4)
- **Corridor3to4**: z=60 (3 pieces at offsets -4, 0, +4)
- **Corridor4to5**: z=80 (1 piece at offset 0)

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

- Total dungeon length: 102 units
- Corridor pieces are 4×4 units (square), not long hallways
- Each corridor piece connects perfectly to room doorways
- All spacing calculated from measured asset dimensions
- Corridor4to5 uses only 1 piece (shortest corridor in the dungeon)

### Future Improvements

- Consider adding corner pieces for more interesting layouts
- Add side rooms or branches
- Implement procedural generation based on these spacing rules
- Add more enemy variety in later rooms
- Use the asset mapping system to automatically calculate positions
