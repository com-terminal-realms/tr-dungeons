# Visual Verification Checklist for POC Layout

## Purpose

This checklist helps verify that the POC layout is visually correct after algorithm changes. Even though the positions don't match the new algorithm's calculated values, the layout should still be valid and functional.

## How to Verify

### 1. Open the Scene in Godot Editor

```bash
cd apps/game-client
godot --editor .
```

Then open `scenes/main.tscn` in the editor.

### 2. Visual Inspection Checklist

#### Room Positions
- [ ] **Room1** at z=0: Visible and properly positioned
- [ ] **Room2** at z=24: Visible and properly positioned
- [ ] **Room3** at z=48: Visible and properly positioned
- [ ] **Room4** at z=72: Visible and properly positioned
- [ ] **Room5** at z=92: Visible and properly positioned

#### Corridor Connections
- [ ] **Corridor1to2** (z=12): 3 pieces visible, connecting Room1 to Room2
  - Pieces at offsets: -4, 0, +4 from center
  - No visible gaps between pieces
  - Connects smoothly to both rooms

- [ ] **Corridor2to3** (z=36): 3 pieces visible, connecting Room2 to Room3
  - Pieces at offsets: -4, 0, +4 from center
  - No visible gaps between pieces
  - Connects smoothly to both rooms

- [ ] **Corridor3to4** (z=60): 3 pieces visible, connecting Room3 to Room4
  - Pieces at offsets: -4, 0, +4 from center
  - No visible gaps between pieces
  - Connects smoothly to both rooms

- [ ] **Corridor4to5** (z=80): 1 piece visible, connecting Room4 to Room5
  - Single piece at center
  - Connects smoothly to both rooms

#### Character Positions
- [ ] **Player** at (0, 1, 0): Standing on floor in Room1
  - Not floating above floor
  - Not clipping through floor
  - Y position = 1.0 (floor height + character offset)

- [ ] **Enemy1** in Room3 at (0, 1, 0): Standing on floor
  - Not floating above floor
  - Not clipping through floor

- [ ] **Enemy1** in Room4 at (-5, 1, 0): Standing on floor
  - Not floating above floor
  - Not clipping through floor

- [ ] **Enemy2** in Room4 at (5, 1, 0): Standing on floor
  - Not floating above floor
  - Not clipping through floor

- [ ] **Boss** in Room5 at (0, 1, 0): Standing on floor, scaled 2x
  - Not floating above floor
  - Not clipping through floor
  - Properly scaled (2x size)

### 3. Run the Game (F5 in Godot)

#### Movement Test
- [ ] Player can move through all rooms without collision issues
- [ ] Player can move through all corridors smoothly
- [ ] No invisible walls or collision problems
- [ ] No gaps where player can fall through

#### Visual Test During Gameplay
- [ ] All rooms render correctly
- [ ] All corridors render correctly
- [ ] No z-fighting or visual artifacts
- [ ] Lighting looks correct throughout dungeon

#### Enemy Test
- [ ] Enemies are visible in their rooms
- [ ] Enemies are standing on floor (not floating)
- [ ] Boss is properly scaled and positioned

### 4. Camera Test

- [ ] Camera follows player correctly
- [ ] Camera doesn't clip through walls
- [ ] All areas of dungeon are visible from camera
- [ ] Isometric view works correctly

## Expected Results

### ✅ All Checks Pass

If all checklist items pass:
- POC layout is visually correct
- No changes needed to scene file
- Algorithm review is complete
- Mark Task 9.4 as complete

### ❌ Some Checks Fail

If any checklist items fail:
1. Document which checks failed
2. Take screenshots of issues
3. Determine if issue is related to algorithm changes
4. Fix issues before marking Task 9.4 complete

## Notes

### Why Positions Don't Match Algorithm

The current POC uses "spacious" positioning (92 units total) while the algorithm calculates "compact" positioning (39.5 units total). This is intentional:

- **Current POC**: Manually positioned for comfortable gameplay
- **Algorithm output**: Optimized for compact, efficient layouts
- **Both are valid**: POC prioritizes player experience, algorithm prioritizes efficiency

### Future Layouts

For procedurally generated layouts, use the new `calculate_position_from_corridor_count()` function to create compact, efficient dungeons. The POC serves as a reference for "spacious" layouts.

## Completion

Once all checks pass, mark Task 9.4 as complete:

```bash
# In task list
- [x] 9.4 Visual verification in Godot editor
```

Then proceed to Task 10 (Comprehensive Test Coverage Verification).
