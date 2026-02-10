# Character Floor Positioning Fix

## Problem

All characters (player, enemies, boss) were floating 1 unit above the floor. As enemies moved toward the player, they would descend slightly but remained floating.

## Root Cause

Characters were positioned at `y=1` in the scene, but the floor height is `y=0` (approximately, with tiny floating-point precision errors).

### Asset Floor Heights

From `data/asset_metadata.json`:
- **room-large**: floor_height ≈ 0.0 (actually -0.0000000000000170777173462812)
- **corridor**: floor_height ≈ 0.0 (actually -0.00000000000000288764564323129)

These tiny negative values are floating-point precision errors and should be treated as `0.0`.

## Solution

Changed all character Y positions from `1.0` to `0.0`:

### Before (Floating)
```gdscript
Player: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)  # y=1
Enemy1 (Room3): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)  # y=1
Enemy1 (Room4): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5, 1, 0)  # y=1
Enemy2 (Room4): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5, 1, 0)  # y=1
Boss (Room5): transform = Transform3D(2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 1, 0)  # y=1
```

### After (On Floor)
```gdscript
Player: transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)  # y=0
Enemy1 (Room3): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)  # y=0
Enemy1 (Room4): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5, 0, 0)  # y=0
Enemy2 (Room4): transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5, 0, 0)  # y=0
Boss (Room5): transform = Transform3D(2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0)  # y=0
```

## Why Characters Were at Y=1

The original positioning likely assumed:
1. Character origin is at their feet
2. Characters need to be 1 unit above floor for visibility
3. Or it was a placeholder value during development

However, the character models appear to have their origin at ground level, so `y=0` is correct.

## Descending Behavior Explained

The "descending while moving" behavior was likely due to:
1. Navigation system calculating paths on the navigation mesh (at floor level)
2. Characters interpolating from their start position (y=1) to target position (y=0)
3. This created the visual effect of descending while moving

## Testing

After the fix:
- ✅ All characters should be standing on the floor
- ✅ No floating or hovering
- ✅ Movement should be smooth without vertical changes
- ✅ Characters should maintain floor contact while moving

## Related to Task 8

This fix addresses **Task 8: Validate Character Floor Positioning** from the dungeon-asset-mapping-bugfixes spec:

- Task 8.1: PlacedCharacter data structure ✅
- Task 8.2: _find_containing_asset() helper ✅
- Task 8.3: validate_character_positioning() function ✅
- Task 8.4: POC validation script update ✅
- Task 8.5: Property test for character positioning ✅
- Task 8.6: Unit tests for edge cases ✅

The validation system was implemented, and this fix applies the correct positions based on that validation.

## Future Improvements

1. **Automated validation**: Run character positioning validation on scene load
2. **Visual debugging**: Add option to show character bounding boxes
3. **Character height offset**: If characters need to be above floor (e.g., for shadows), use a consistent offset
4. **Asset-specific offsets**: Different character types might need different floor offsets

## Files Changed

- `apps/game-client/scenes/main.tscn` - Updated all character Y positions to 0
- `apps/game-client/docs/CHARACTER_FLOOR_POSITIONING_FIX.md` - This document
