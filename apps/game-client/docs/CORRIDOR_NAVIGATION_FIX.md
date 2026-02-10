# Corridor Navigation Fix

## Problem

Corridors were not clickable for navigation - the player couldn't right-click on corridors to move there. However, clicking on rooms worked fine, and the player would walk through corridors to reach the destination.

## Root Cause

The corridors lacked **collision shapes** for the navigation mesh baking system to detect.

### How Navigation Works in Godot

1. `NavigationRegion3D` bakes a navigation mesh based on collision shapes
2. Collision shapes (StaticBody3D + CollisionShape3D) define walkable areas
3. Without collision shapes, the navigation mesh doesn't include those areas
4. Areas without navigation mesh can't be clicked for pathfinding

### What Was Missing

- **Rooms**: Had `Floor` StaticBody3D nodes with BoxShape3D collision ✅
- **Corridors**: Only had visual meshes (GLB instances), no collision ❌

## Solution

Added collision shapes to all corridor pieces:

```gdscript
# For each corridor piece, add:
[node name="Floor1" type="StaticBody3D" parent="NavigationRegion3D/Corridor1to2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -3.95)

[node name="CollisionShape3D" type="CollisionShape3D" parent="NavigationRegion3D/Corridor1to2/Floor1"]
shape = SubResource("BoxShape_floor")  # Reuses the 20x0.2x20 box
transform = Transform3D(0.2, 0, 0, 0, 1, 0, 0, 0, 0.2, 0, 0, 0)  # Scaled to 4x0.2x4
```

### Collision Shape Details

- **Shape**: BoxShape3D (reused from rooms)
- **Size**: 20×0.2×20 units (base size)
- **Scale**: 0.2 in X and Z axes → 4×0.2×4 units (corridor size)
- **Position**: Matches each corridor piece position

## Changes Made

### Corridor1to2 (3 pieces)
- Added Floor1, Floor2, Floor3 with collision shapes
- Positioned at z=-3.95, 0, +3.95 relative to corridor center

### Corridor2to3 (3 pieces)
- Added Floor1, Floor2, Floor3 with collision shapes
- Positioned at z=-3.95, 0, +3.95 relative to corridor center

### Corridor3to4 (3 pieces)
- Added Floor1, Floor2, Floor3 with collision shapes
- Positioned at z=-3.95, 0, +3.95 relative to corridor center

### Corridor4to5 (1 piece)
- Added Floor1 with collision shape
- Positioned at z=0 relative to corridor center

## Testing

After reloading the scene:

1. **Navigation mesh should rebake** automatically (main.gd calls `bake_navigation_mesh()`)
2. **Corridors should be clickable** - right-click should work
3. **Pathfinding should work** - player should navigate to clicked corridor positions
4. **Visual check**: No visible changes (collision shapes are invisible)

## Future Improvements

1. **Proper corridor collision**: Use corridor-specific collision shapes (4×4 units) instead of scaled room boxes
2. **Automated setup**: Create a corridor scene with built-in collision
3. **Navigation mesh optimization**: Fine-tune cell size and agent parameters
4. **Visual debugging**: Add option to visualize navigation mesh

## Related Files

- `apps/game-client/scenes/main.tscn` - Added collision shapes
- `apps/game-client/scenes/main.gd` - Navigation mesh baking logic
- `apps/game-client/docs/CORRIDOR_NAVIGATION_FIX.md` - This document
