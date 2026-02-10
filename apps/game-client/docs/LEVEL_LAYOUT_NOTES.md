# Level Layout Notes

## Room and Corridor Positioning

This document tracks the positioning of rooms and corridors in the main dungeon scene.

### Room Positions (Z-axis)

- **Room1**: z=0 (Start room, small)
- **Room2**: z=20 (Small room)
- **Room3**: z=40 (Wide room, 1 enemy)
- **Room4**: z=60 (Wide room, 2 enemies)
- **Room5**: z=80 (Large room, Boss)

### Corridor Positions (Z-axis)

Corridors are positioned between rooms. Each corridor consists of 3 pieces positioned at offsets -2, 0, +2 relative to the corridor's base position.

- **Corridor1to2**: z=10 (centered between Room1 and Room2)
- **Corridor2to3**: z=30 (centered between Room2 and Room3)
- **Corridor3to4**: z=50 (centered between Room3 and Room4)
- **Corridor4to5**: z=70 (centered between Room4 and Room5)
  - **Note**: Uses only 2 corridor pieces instead of 3 to shorten the corridor length
  - Pieces at offsets -1 and +1 (instead of -2, 0, +2)

### Corridor Piece Rotation

All corridor pieces use the same rotation to align them along the Z-axis:
```
transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, x, y, z)
```

This rotates the corridor 90 degrees to run north-south instead of east-west.

**Note**: Corridor4to5 uses only 2 pieces (at z offsets -1 and +1) instead of 3 pieces to create a shorter corridor.

### Enemy Placement

- **Room3**: 1 enemy at (0, 1, 0) relative to room
- **Room4**: 2 enemies at (-5, 1, 0) and (5, 1, 0) relative to room
- **Room5**: 1 boss at (0, 1, 0) relative to room, scaled 2x

### Design Notes

- Rooms are spaced 20 units apart on the Z-axis
- Corridors are typically centered between rooms (10 units from each)
- Corridor4to5 uses only 2 pieces instead of 3 to create a shorter corridor
- All rooms use Kenney dungeon assets (room-small, room-wide, room-large)
- Corridors use the standard corridor.glb asset with 3 pieces each

### Future Improvements

- Consider adding corner pieces for more interesting layouts
- Add side rooms or branches
- Implement procedural generation based on these spacing rules
- Add more enemy variety in later rooms
