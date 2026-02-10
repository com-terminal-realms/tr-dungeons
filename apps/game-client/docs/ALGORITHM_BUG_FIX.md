# Algorithm Bug Fix: Room Size Accounting

## The Problem

The `calculate_position_from_corridor_count()` algorithm was calculating **center-to-center** distances between rooms, but it should have been calculating **edge-to-edge** distances.

### What Went Wrong

```gdscript
// INCORRECT (what we did):
room2_pos = room1_pos + (corridor_count * corridor_effective_length)
// This calculates center-to-center distance

// CORRECT (what we should do):
room2_pos = room1_pos + room_half_size + (corridor_count * corridor_effective_length) + room_half_size
// This calculates edge-to-edge distance and accounts for room sizes
```

### Visual Explanation

```
INCORRECT (center-to-center):
Room1 center at 0
  |<-- 10 units -->|
  [================]  Room1 (20 units wide)
                   ^
                   Room1 edge at +10

Room2 center at 11.85 (WRONG!)
  |<-- 10 units -->|
  [================]  Room2 (20 units wide)
  ^
  Room2 edge at 1.85

Result: Rooms OVERLAP by 8.15 units!


CORRECT (edge-to-edge):
Room1 center at 0
  |<-- 10 units -->|
  [================]  Room1 (20 units wide)
                   ^
                   Room1 edge at +10
                   
  |<-- 11.85 units of corridor -->|
  
                                  ^
                                  Room2 edge at 21.85
                   |<-- 10 units -->|
                   [================]  Room2 (20 units wide)
                   
Room2 center at 31.85 (CORRECT!)

Result: Perfect connection with 3 corridor pieces!
```

## The Fix

### Corrected Formula

```gdscript
func calculate_room_position_with_corridors(
    start_room_center: Vector3,
    start_room_half_size: float,
    corridor_count: int,
    corridor_effective_length: float,
    end_room_half_size: float,
    direction: Vector3
) -> Vector3:
    # Calculate edge-to-edge distance
    var edge_to_edge_distance = corridor_count * corridor_effective_length
    
    # Calculate end room center position
    var end_room_center = start_room_center + direction * (
        start_room_half_size +  # Distance from start center to start edge
        edge_to_edge_distance + # Distance between edges (corridors)
        end_room_half_size      # Distance from end edge to end center
    )
    
    return end_room_center
```

### Corrected POC Positions

| Asset | Old (Wrong) Z | New (Correct) Z | Difference |
|-------|---------------|-----------------|------------|
| Room1 | 0.0 | 0.0 | - |
| Corridor1to2 | 5.93 | 15.93 | +10.0 |
| Room2 | 11.85 | 31.85 | +20.0 |
| Corridor2to3 | 17.78 | 47.78 | +30.0 |
| Room3 | 23.70 | 63.70 | +40.0 |
| Corridor3to4 | 29.63 | 79.63 | +50.0 |
| Room4 | 35.55 | 95.55 | +60.0 |
| Corridor4to5 | 37.53 | 107.53 | +70.0 |
| Room5 | 39.50 | 119.50 | +80.0 |

**Total dungeon length:**
- Wrong: 39.5 units (rooms overlapping!)
- Correct: 119.5 units (proper spacing)

## Why This Matters

### For room-large (20×20 units):
- Room extends ±10 units from center
- Connection points are at the edges (±10 units)
- When calculating next room position, must add:
  - Start room half-size: +10 units
  - Corridor distance: +11.85 units (3 corridors)
  - End room half-size: +10 units
  - **Total: +31.85 units from start center**

### The Pattern

For any two rooms connected by corridors:
```
next_room_center = current_room_center + 
                   current_room_half_size + 
                   (corridor_count * corridor_effective_length) + 
                   next_room_half_size
```

## Lessons Learned

1. **Always account for asset dimensions** when calculating positions
2. **Connection points are at edges**, not centers
3. **Test visually** - the wrong algorithm produced overlapping rooms
4. **Edge-to-edge vs center-to-center** - critical distinction for layout algorithms

## Next Steps

1. ✅ Fix POC layout with correct positions
2. ⏳ Update `LayoutCalculator.calculate_position_from_corridor_count()` to account for room sizes
3. ⏳ Add room metadata parameter to the function
4. ⏳ Update all tests to use corrected algorithm
5. ⏳ Document the corrected formula in design documents

## Files Changed

- `apps/game-client/scenes/main.tscn` - Updated with correct positions
- `apps/game-client/docs/LEVEL_LAYOUT_NOTES.md` - Updated documentation
- `apps/game-client/scripts/utils/fix_poc_positions_correctly.gd` - Calculation script
- `apps/game-client/docs/ALGORITHM_BUG_FIX.md` - This document
