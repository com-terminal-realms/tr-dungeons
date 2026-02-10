# Gate Assets - Measurement Summary

## Overview

The Kenney dungeon pack includes three gate/door assets that can be used to create barriers, doorways, or transitions between dungeon areas.

## Asset Dimensions

| Asset | Width (X) | Height (Y) | Length (Z) | Notes |
|-------|-----------|------------|------------|-------|
| gate.glb | 4.40 | 4.40 | 1.40 | Basic gate frame |
| gate-door.glb | 5.20 | 4.40 | 1.40 | Gate with door |
| gate-door-window.glb | 5.20 | 4.40 | 1.40 | Gate with door and window |

## Key Characteristics

### Dimensions
- All gates are **1.4 units thick** (Z-axis)
- All gates are **4.4 units tall** (Y-axis)
- Basic gate is **4.4 units wide** (X-axis)
- Door variants are **5.2 units wide** (X-axis) - 0.8 units wider

### Connection Points
- All gates have **2 connection points** (East and West)
- Connection type: `corridor_end`
- Doorway opening: **1.4 × 3.52 units** (W × H)
- Gates are designed to fit in corridors or doorways

### Placement
- Floor height: 0.0 units (aligned with standard dungeon floor)
- Origin offset: 2.2 units up (center of gate height)
- Default rotation: (0°, 90°, 0°) - faces along X-axis

## Usage Recommendations

### Basic Gate (gate.glb)
- Use for simple barriers or portcullises
- Symmetrical design (4.4 × 4.4 × 1.4)
- Good for blocking corridors or room entrances

### Gate with Door (gate-door.glb)
- Includes a functional door element
- Slightly wider (5.2 units) to accommodate door frame
- Use when you want a closeable entrance

### Gate with Door and Window (gate-door-window.glb)
- Same dimensions as gate-door.glb
- Includes window element for visibility
- Use when you want visual connection between areas

## Integration with Existing Assets

### Corridor Compatibility
- Corridor pieces are **4.0 × 4.0 units**
- Basic gate (4.4 units) is **0.4 units wider** than corridors
- Door variants (5.2 units) are **1.2 units wider** than corridors
- Gates will slightly overlap corridor walls when placed

### Room Compatibility
- Room doorways are approximately **2.0 × 1.8 units**
- Gate doorways are **1.4 × 3.52 units**
- Gates are narrower but taller than room doorways
- May need positioning adjustments for proper fit

## Placement Examples

### In a Corridor
```
Position gate at corridor connection point:
- Align gate's connection point with corridor's connection point
- Gate will be centered in the corridor
- 0.2 unit overlap on each side (acceptable)
```

### Between Rooms
```
Position gate at room doorway:
- Center gate on room's connection point
- Gate opening (1.4 units) is narrower than room doorway (2.0 units)
- Will create a more restrictive passage
```

## Validation Notes

- All gate assets measured with ±0.1 unit accuracy
- Measurements taken: 2026-02-10
- No collision shapes defined (will need to be added in scene)
- Walkable areas calculated automatically

## Next Steps

To use these gates in the dungeon:

1. **Choose appropriate gate variant** based on visual needs
2. **Position at connection points** using measured dimensions
3. **Add collision shapes** if needed for gameplay
4. **Test player movement** through gate openings
5. **Validate connections** using the layout validation tool

## Documentation

Full documentation for each asset:
- `docs/assets/gate.md`
- `docs/assets/gate-door.md`
- `docs/assets/gate-door-window.md`

Rotation documentation:
- `docs/assets/gate_rotation.md`
- `docs/assets/gate-door_rotation.md`
- `docs/assets/gate-door-window_rotation.md`
