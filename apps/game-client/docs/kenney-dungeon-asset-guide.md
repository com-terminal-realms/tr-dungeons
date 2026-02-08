# Kenney Dungeon Asset Guide

This document provides dimensions, orientations, and usage guidelines for Kenney dungeon assets to enable quick room assembly.

## Asset Dimensions Reference

All measurements are approximate based on testing in Godot. Assets are positioned with origin at (0, 0, 0).

### Room Assets

| Asset | Width (X) | Height (Y) | Depth (Z) | Notes |
|-------|-----------|------------|-----------|-------|
| `room-small.glb` | ~4 units | ~4 units | ~4 units | Compact square room with walls |
| `room-wide.glb` | ~6 units | ~4 units | ~4 units | Rectangular room, wider |
| `room-large.glb` | ~8 units | ~4 units | ~8 units | Large square room |
| `room-corner.glb` | ~4 units | ~4 units | ~4 units | L-shaped corner room |

### Corridor Assets

| Asset | Width (X) | Height (Y) | Depth (Z) | Notes |
|-------|-----------|------------|-----------|-------|
| `corridor.glb` | ~2 units | ~4 units | ~2 units | Standard corridor segment |
| `corridor-wide.glb` | ~4 units | ~4 units | ~2 units | Wide corridor segment |
| `corridor-corner.glb` | ~2 units | ~4 units | ~2 units | 90-degree turn |
| `corridor-intersection.glb` | ~2 units | ~4 units | ~2 units | 4-way intersection |
| `corridor-junction.glb` | ~2 units | ~4 units | ~2 units | T-junction |

### Floor Templates

| Asset | Width (X) | Height (Y) | Depth (Z) | Notes |
|-------|-----------|------------|-----------|-------|
| `template-floor.glb` | ~2 units | ~0.1 units | ~2 units | Plain floor tile |
| `template-floor-detail.glb` | ~2 units | ~0.1 units | ~2 units | Detailed floor tile |
| `template-floor-big.glb` | ~2 units | ~4 units | ~2 units | Floor with pillar |
| `template-floor-layer.glb` | ~2 units | ~0.2 units | ~2 units | Layered floor |

### Wall Templates

| Asset | Width (X) | Height (Y) | Depth (Z) | Notes |
|-------|-----------|------------|-----------|-------|
| `template-wall.glb` | ~2 units | ~4 units | ~0.2 units | Standard wall segment |
| `template-wall-corner.glb` | ~2 units | ~4 units | ~2 units | Corner wall piece |
| `template-wall-half.glb` | ~2 units | ~2 units | ~0.2 units | Half-height wall |

## Coordinate System

- **X-axis**: Left (-) to Right (+)
- **Y-axis**: Down (-) to Up (+)
- **Z-axis**: Forward (-) to Back (+)
- **Default orientation**: Assets face along the +Z axis

## Current Map Layout

Our POC dungeon uses a linear north-south layout along the Z-axis:

```
Room 1 (small)    - Position: (0, 0, 0)
  Corridor (5x)   - Position: (0, 0, 10) - pieces at z: 6, 8, 10, 12, 14
Room 2 (small)    - Position: (0, 0, 20)
  Corridor (5x)   - Position: (0, 0, 30) - pieces at z: 26, 28, 30, 32, 34
Room 3 (wide)     - Position: (0, 0, 40)
  Corridor (5x)   - Position: (0, 0, 50) - pieces at z: 46, 48, 50, 52, 54
Room 4 (wide)     - Position: (0, 0, 60)
  Corridor (5x)   - Position: (0, 0, 70) - pieces at z: 66, 68, 70, 72, 74
Room 5 (large)    - Position: (0, 0, 80) - Boss room
```

### Spacing Rules

- **Room spacing**: 20 units apart (center to center)
- **Corridor placement**: Centered between rooms (at z = room1_z + 10)
- **Corridor pieces**: 5 pieces per corridor, spaced 2 units apart
- **Collision boxes**: 20x0.2x20 units, positioned at room center

## Quick Assembly Guide

### Adding a New Room

1. **Choose room type** based on size needed:
   - Small encounters: `room-small.glb`
   - Medium encounters: `room-wide.glb`
   - Boss/large areas: `room-large.glb`

2. **Position the room**:
   - Place 20 units from previous room along Z-axis
   - Keep X=0, Y=0 for linear dungeons
   - Example: If last room is at z=80, new room goes at z=100

3. **Add collision box**:
   ```gdscript
   [node name="Floor" type="StaticBody3D"]
   [node name="MeshInstance3D" type="MeshInstance3D"]
   visible = false
   mesh = SubResource("BoxMesh_floor")  # 20x0.2x20
   [node name="CollisionShape3D" type="CollisionShape3D"]
   shape = SubResource("BoxShape_floor")  # 20x0.2x20
   ```

4. **Add room asset**:
   ```gdscript
   [node name="DungeonRoom" instance=ExtResource("room_asset")]
   transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
   ```

### Connecting Rooms with Corridors

1. **Calculate midpoint**: `corridor_z = (room1_z + room2_z) / 2`

2. **Create corridor parent node**:
   ```gdscript
   [node name="CorridorXtoY" type="Node3D"]
   transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, midpoint_z)
   ```

3. **Add 5 corridor pieces** (for 20-unit gap):
   ```gdscript
   [node name="CorridorPiece1" instance=ExtResource("corridor")]
   transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, -4)
   
   [node name="CorridorPiece2" instance=ExtResource("corridor")]
   transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, -2)
   
   [node name="CorridorPiece3" instance=ExtResource("corridor")]
   transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0)
   
   [node name="CorridorPiece4" instance=ExtResource("corridor")]
   transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 2)
   
   [node name="CorridorPiece5" instance=ExtResource("corridor")]
   transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 4)
   ```
   Note: Corridors are rotated 90° to run along Z-axis

### Rotation Reference

For corridors running in different directions:

- **North-South (Z-axis)**: Rotate 90° around Y-axis
  - `Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, x, y, z)`

- **East-West (X-axis)**: No rotation needed
  - `Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z)`

- **Diagonal (45°)**: Rotate 45° around Y-axis
  - `Transform3D(0.707, 0, 0.707, 0, 1, 0, -0.707, 0, 0.707, x, y, z)`

## Scaling Guidelines

### When to Scale

- **Floor tiles**: Scale 10x in X/Z to cover 20x20 collision areas
  - `Transform3D(10, 0, 0, 0, 1, 0, 0, 0, 10, 0, 0, 0)`

- **Corridors**: Use multiple pieces instead of scaling
  - Better visual quality
  - Easier to adjust length

- **Rooms**: Use at default scale (1x)
  - Pre-built with correct proportions

### Avoid Scaling

- Don't scale walls vertically (Y-axis) - use taller wall variants instead
- Don't scale rooms - choose appropriate size variant
- Don't scale decorative elements - use as-is

## Common Patterns

### Linear Dungeon (Current)
```
Room → Corridor → Room → Corridor → Room
```
- Simple progression
- Easy navigation
- Good for tutorials

### Branching Dungeon
```
        Room
         |
    Corridor
         |
Room - Junction - Room
         |
    Corridor
         |
        Room
```
- Use `corridor-junction.glb` for splits
- Requires navigation logic updates

### Circular Dungeon
```
Room - Corridor - Room
 |                 |
Corridor       Corridor
 |                 |
Room - Corridor - Room
```
- Use `corridor-corner.glb` for turns
- Creates loop for backtracking

## Asset Positioning Tips

1. **Always position rooms first**, then add corridors
2. **Use parent nodes** for corridor groups to simplify transforms
3. **Keep Y=0** for floor level consistency
4. **Hide collision meshes** with `visible = false` but keep collision shapes
5. **Test navigation** after adding new sections
6. **Use showcase scene** (`scenes/rooms/dungeon_showcase.tscn`) to preview assets

## Troubleshooting

### Corridors don't connect
- Check midpoint calculation
- Verify corridor orientation (may need 90° rotation)
- Ensure corridor pieces overlap slightly

### Floors not visible
- Check Y position (should be at or near 0)
- Verify collision mesh is hidden (`visible = false`)
- Ensure floor asset is scaled appropriately

### Walls blocking movement
- Verify collision shapes match visual geometry
- Check for duplicate collision shapes
- Ensure walls are positioned outside playable area

## Future Enhancements

- [ ] Measure exact asset dimensions in Blender
- [ ] Create prefab scenes for common room+corridor combinations
- [ ] Add procedural dungeon generation script
- [ ] Document all asset variants (variations, details, etc.)
- [ ] Create visual diagram of asset connections
