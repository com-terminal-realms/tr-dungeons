---
inclusion: always
---

# Asset Validation and Layout Management

## Overview

When working with dungeon assets and level layouts, always use the asset mapping system to ensure proper alignment and prevent gaps or overlaps.

## Asset Measurement

### Before Using Any Asset

1. **Measure the asset first** using the asset mapping system
2. **Never assume dimensions** from visual inspection
3. **Document measurements** in the asset metadata database

### Measurement Command

```bash
cd apps/game-client
godot --headless --script scripts/utils/measure_poc_assets.gd
```

This generates:
- `data/asset_metadata.json` - Complete metadata database
- `docs/assets/*.md` - Documentation for each asset
- Rotation transforms and spacing formulas

## Layout Validation

### Always Validate After Changes

Whenever you modify room or corridor positions in `scenes/main.tscn`, validate the layout:

```bash
cd apps/game-client
godot --headless --script scripts/utils/validate_poc_layout.gd
```

### Validation Criteria

- ✅ All connections must be within ±0.1 unit tolerance
- ❌ Gaps larger than 0.1 units are errors
- ❌ Overlaps larger than 0.1 units are errors

### If Validation Fails

1. Run the fix calculator to get correct positions:
   ```bash
   godot --headless --script scripts/utils/fix_poc_layout.gd
   ```

2. Update `scenes/main.tscn` with the calculated positions

3. Re-run validation to confirm the fix

## Key Lessons from POC Validation

### Corridor Assets

- **corridor.glb is 4×4 units** (square piece, not a long hallway)
- Corridor pieces must be spaced at 4-unit intervals
- Use multiple pieces to create longer corridors
- Single pieces work for short connections

### Room Assets

- **room-small.glb**: 12×12 units
- **room-wide.glb**: 20×12 units (wide in X, same Z as small)
- **room-large.glb**: 20×20 units

### Connection Points

- All Kenney dungeon assets have connection points at their edges
- Connection points are at the center of each wall
- Doorway dimensions are approximately 2×1.8 units

## Workflow for New Layouts

1. **Measure all assets** you plan to use
2. **Calculate positions** using asset dimensions
3. **Place assets** in the scene
4. **Validate connections** using the validation script
5. **Fix any issues** using the fix calculator
6. **Test in-game** to verify smooth transitions

## Tools Reference

### Measurement Tool
- **File**: `scripts/utils/measure_poc_assets.gd`
- **Purpose**: Measure asset dimensions and generate metadata
- **Output**: JSON database + markdown documentation

### Validation Tool
- **File**: `scripts/utils/validate_poc_layout.gd`
- **Purpose**: Check for gaps and overlaps in layout
- **Output**: Connection validation report

### Fix Calculator
- **File**: `scripts/utils/fix_poc_layout.gd`
- **Purpose**: Calculate correct positions based on measurements
- **Output**: Corrected position values

## Documentation

### Always Update After Changes

When you modify the layout:

1. Update `docs/LEVEL_LAYOUT_NOTES.md` with new positions
2. Document any special cases (e.g., single-piece corridors)
3. Note the total dungeon length
4. List all connection points

### Asset Documentation

Each measured asset should have:
- Full dimensions (W×H×L)
- Connection point positions
- Collision geometry
- Walkable area
- Rotation transforms

## Common Mistakes to Avoid

1. ❌ **Don't assume asset sizes** - Always measure first
2. ❌ **Don't eyeball positions** - Use calculated values
3. ❌ **Don't skip validation** - Always validate after changes
4. ❌ **Don't ignore warnings** - Fix all connection errors
5. ❌ **Don't forget to test** - Run the game to verify

## Success Criteria

A properly validated layout has:
- ✅ All connections within ±0.1 unit tolerance
- ✅ No visible gaps between assets
- ✅ Smooth player movement through all areas
- ✅ No collision issues at connection points
- ✅ Complete documentation of all positions

## Example: POC Validation Success

The POC dungeon was successfully validated with:
- 8 connections checked
- 0 gaps detected
- 0 overlaps detected
- All connections within tolerance
- Total dungeon length: 102 units

This demonstrates the effectiveness of the asset mapping system for ensuring proper layout alignment.
