# Tasks: Dungeon Asset Mapping System - Bug Fixes

## Overview

This task list implements fixes for 12 critical bugs discovered through property-based testing, plus adds character floor positioning validation.

**Total Tasks**: 10 major tasks with 34 subtasks

## Task Status Legend

- `[ ]` Not started
- `[~]` Queued
- `[-]` In progress
- `[x]` Completed
- `[ ]*` Optional task

---

## 1. Fix Scene Tree Initialization in Property Tests

**Priority**: Critical (blocks all other testing)
**Estimated Effort**: 2 hours
**Dependencies**: None

### Subtasks

- [x] 1.1 Update `AssetTestHelpers.create_test_asset_scene()` to add nodes to scene tree
  - Add scene to Engine.get_main_loop().root
  - Wait for scene to be ready with `await tree.process_frame`
  - Ensure proper cleanup in teardown

- [x] 1.2 Update `test_property_walkable_area_containment()` to use scene tree
  - Add test scene to tree before calling `_calculate_walkable_area()`
  - Verify no "!is_inside_tree()" errors in output
  - Ensure proper cleanup after test

- [x] 1.3 Update `test_property_collision_documentation_completeness()` to use scene tree
  - Add test scene to tree before calling `_extract_collision_geometry()`
  - Verify no "!is_inside_tree()" errors in output
  - Ensure proper cleanup after test

- [x] 1.4 Run property tests and verify no engine errors
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property`
  - Verify: No "!is_inside_tree()" errors
  - Verify: Tests complete without 500+ engine errors

**Acceptance Criteria**:
- ✅ Property tests complete without scene tree errors
- ✅ "Walkable Area Containment" test runs without 500+ errors
- ✅ "Collision Documentation Completeness" test runs without 100+ errors

---

## 2. Implement Position-from-Count Function (Design Pattern Change)

**Priority**: High (fundamental design improvement)
**Estimated Effort**: 3 hours
**Dependencies**: Task 1 (for proper testing)

### Subtasks

- [x] 2.1 Implement `calculate_position_from_corridor_count()` function
  - Accept: start_position, corridor_count, corridor_metadata, direction
  - Calculate: effective_length = corridor_length - (2 × overlap)
  - Return: start_position + (direction × corridor_count × effective_length)
  - Add validation: corridor_count >= 1, metadata not null

- [x] 2.2 Update `calculate_corridor_count()` documentation
  - Mark as VALIDATION function (not generation)
  - Add comment: "Use calculate_position_from_corridor_count() for layout generation"
  - Keep existing implementation for validation purposes

- [x] 2.3 Add unit tests for position-from-count function
  - Test: 1 corridor → correct distance
  - Test: 2 corridors → 2× distance
  - Test: 5 corridors → 5× distance
  - Test: Different directions (north, south, east, west)
  - Test: Invalid inputs (count < 1, null metadata)

- [x] 2.4 Add property test: "Position-Count Round-Trip"
  - Generate random corridor metadata
  - Generate random corridor count (1-10)
  - Calculate position using calculate_position_from_corridor_count()
  - Calculate distance from start to calculated position
  - Verify calculate_corridor_count(distance) returns original count
  - Should pass 100% of iterations (exact match, no tolerance needed)

- [x] 2.5 Update layout generation examples
  - Update POC layout script to use new function
  - Document the design pattern change
  - Show before/after comparison

**Acceptance Criteria**:
- ✅ New function generates exact positions (no tolerance issues)
- ✅ Round-trip test passes 100% of iterations
- ✅ Unit tests cover all edge cases
- ✅ Documentation clearly explains the design pattern

---

## 3. Fix Corridor Count Formula Calculation (Validation Function)

**Priority**: Medium (now used for validation only)
**Estimated Effort**: 2 hours
**Dependencies**: Task 1, Task 2

### Subtasks

- [x] 3.1 Implement corrected `_calculate_overlap()` function
  - Extract connection point positions along Z axis
  - Calculate distance from edge to connection point
  - Return average overlap value
  - Handle edge case: no connection points defined

- [x] 3.2 Update `calculate_corridor_count()` with corrected formula
  - Use formula: `count = max(1, ceil(distance / effective_length))`
  - Where: `effective_length = corridor_length - (2 * overlap)`
  - Add smart rounding: pick floor or ceil based on which is closer
  - Add warning logging for large discrepancies

- [x] 3.3 Add unit tests for corridor count edge cases
  - Test: distance = 0 (should return error)
  - Test: distance < corridor_length (should return 1)
  - Test: distance = corridor_length (should return 1)
  - Test: distance = 2 * corridor_length (should return 2)
  - Test: null metadata (should return error)

- [x] 3.4 Update property test: "Corridor Count Accuracy"
  - Change test to validate round-trip with position-from-count
  - Generate corridor count → calculate position → validate count
  - Should pass 100% of iterations (exact match)
  - Remove tolerance-based validation (no longer needed)

**Acceptance Criteria**:
- ✅ Validation function correctly identifies corridor counts
- ✅ Round-trip test passes 100% (with position-from-count)
- ✅ Unit tests cover all edge cases
- ✅ Function documented as validation-only

---

## 4. Fix Gap and Overlap Detection Logic

**Priority**: High (required for validation)
**Estimated Effort**: 4 hours
**Dependencies**: Task 1 (for proper testing)

### Subtasks

- [x] 4.1 Implement `_transform_connection_to_world()` helper
  - Apply rotation using Basis.from_euler()
  - Apply translation
  - Return world-space position

- [x] 4.2 Implement `_transform_normal_to_world()` helper
  - Apply rotation to normal vector
  - Return world-space normal direction

- [x] 4.3 Update `validate_connection()` with corrected gap calculation
  - Transform connection points to world space
  - Calculate gap vector and distance
  - Determine sign based on normal alignment (negative = overlap)
  - Use thresholds: gap > 0.2 is error, overlap > 0.1 is error

- [x] 4.4 Add normal alignment validation
  - Check that connection normals point toward each other
  - Verify dot product ≈ -1 (opposite directions)
  - Report error if normals not aligned

- [x] 4.5 Run property test: "Gap Detection Accuracy"
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property -gtest=test_property_gap_detection_accuracy`
  - Verify: Pass rate ≥ 95% (currently 66%)
  - Verify: Detects overlaps ≥ -0.15 units

**Acceptance Criteria**:
- ✅ Property test passes with 95%+ success rate
- ✅ Gaps > 0.2 units are detected
- ✅ Overlaps > 0.1 units are detected
- ✅ No false positives for valid connections

---

## 5. Fix Layout Connection Validation

**Priority**: Medium (depends on tasks 2, 3, and 4)
**Estimated Effort**: 3 hours
**Dependencies**: Tasks 2, 3, 4

### Subtasks

- [x] 5.1 Update `validate_layout()` to use corrected validation logic
  - Iterate through adjacent asset pairs
  - Call `validate_connection()` for each pair
  - Aggregate errors and set overall validity

- [x] 5.2 Add detailed error reporting
  - Report which connection failed (index pair)
  - Report gap/overlap distance
  - Report normal alignment issues

- [x] 5.3 Run property test: "Layout Validation Correctness"
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property -gtest=test_property_layout_validation_correctness`
  - Verify: Pass rate ≥ 95% (currently 0%)
  - Verify: Valid layouts marked as valid
  - Verify: Invalid layouts marked as invalid

**Acceptance Criteria**:
- ✅ Property test passes with 95%+ success rate
- ✅ Validation correctly distinguishes valid from invalid layouts
- ✅ Error messages identify specific connection failures

---

## 6. Fix Navigation Path Continuity Validation

**Priority**: Medium (depends on walkable area calculations)
**Estimated Effort**: 3 hours
**Dependencies**: Task 1

### Subtasks

- [x] 6.1 Implement `_validate_navigation_continuity()` function
  - Check all assets have walkable areas defined
  - Transform walkable areas to world space
  - Check for gaps between adjacent walkable areas

- [x] 6.2 Implement `_transform_aabb_to_world()` helper
  - Apply rotation and translation to AABB
  - Return world-space AABB

- [x] 6.3 Implement `_calculate_aabb_gap()` helper
  - Calculate gap between two AABBs
  - Return 0 if overlapping, positive if gap exists
  - Handle all three axes (X, Y, Z)

- [x] 6.4 Run property test: "Navigation Continuity"
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property -gtest=test_property_navigation_continuity`
  - Verify: Pass rate ≥ 95% (currently 0%)
  - Verify: Detects missing walkable areas
  - Verify: Detects disconnected walkable areas

**Acceptance Criteria**:
- ✅ Property test passes with 95%+ success rate
- ✅ Missing walkable areas are detected
- ✅ Gaps in walkable areas are detected

---

## 7. Fix Health Signal Emission Edge Cases

**Priority**: Low (independent component)
**Estimated Effort**: 1 hour
**Dependencies**: None

### Subtasks

- [x] 7.1 Update `take_damage()` to handle edge cases
  - Return early if already dead (don't emit signals)
  - Always emit `health_changed` when taking damage
  - Emit `died` signal only when transitioning from alive to dead

- [x] 7.2 Update `heal()` to handle edge cases
  - Return early if already dead (don't emit signals)
  - Only emit `health_changed` if health actually changed

- [x] 7.3 Run property test: "Health Signal Emission"
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property -gtest=test_property_health_signal_emission`
  - Verify: Pass rate = 100% (currently 95%)
  - Verify: Signals emit exactly once per operation

**Acceptance Criteria**:
- ✅ Property test passes with 100% success rate
- ✅ Signals emit correctly when health reaches zero
- ✅ No signals emitted when already dead

---

## 8. Validate Character Floor Positioning

**Priority**: Medium (ensures correct visual appearance)
**Estimated Effort**: 3 hours
**Dependencies**: Task 1 (for proper testing)

### Subtasks

- [x] 8.1 Implement `PlacedCharacter` data structure
  - Add name, position, and height_offset fields
  - Add constructor with default height_offset = 1.0

- [x] 8.2 Implement `_find_containing_asset()` helper
  - Transform asset bounding boxes to world space
  - Check if character position is inside any asset
  - Return the containing asset or null

- [x] 8.3 Implement `validate_character_positioning()` function
  - For each character, find containing asset
  - Calculate expected Y position: floor_height + height_offset
  - Check if actual Y matches expected within 0.1 unit tolerance
  - Report errors with expected vs actual positions

- [x] 8.4 Update POC validation script to include character validation
  - Extract player position from scene
  - Extract enemy positions from scene
  - Create PlacedCharacter instances for all characters
  - Call validate_character_positioning()
  - Report results

- [x] 8.5 Add property test: "Character Floor Positioning"
  - Generate random rooms with random character positions
  - Validate characters at correct floor height
  - Test with 100 iterations
  - Verify: Pass rate ≥ 95%

- [x] 8.6 Add unit tests for character positioning edge cases
  - Test: Character outside all assets (should report error)
  - Test: Character at correct height (should pass)
  - Test: Character floating above floor (should report error)
  - Test: Character clipping through floor (should report error)
  - Test: Different character types with different height offsets

**Acceptance Criteria**:
- ✅ Property test passes with 95%+ success rate
- ✅ POC validation includes character positioning check
- ✅ All characters in POC are at correct floor height
- ✅ Error messages identify which character and expected Y position

---

## 9. Validate POC Layout Against Fixed Algorithms

**Priority**: Verification (ensures no regressions)
**Estimated Effort**: 2 hours
**Dependencies**: Tasks 2, 3, 4, 5, 8

### Subtasks

- [x] 9.1 Run POC layout validation script
  - Run: `godot --headless --script scripts/utils/validate_poc_layout.gd`
  - Verify: All connections still valid
  - Verify: No gaps > 0.2 units detected
  - Verify: All characters at correct floor height

- [x] 9.2 Recalculate POC corridor positions using fixed formula
  - Calculate expected positions using corrected formula
  - Compare with actual positions in main.tscn
  - Verify: Positions match within ±0.1 units

- [x] 9.3 Document any discrepancies
  - If positions don't match, document the differences
  - Explain why the POC layout is still valid
  - Update LEVEL_LAYOUT_NOTES.md if needed

- [x] 9.4 Visual verification in Godot editor
  - Open main.tscn in Godot editor
  - Verify: Correct number of corridors between rooms
  - Verify: No visible gaps or overlaps
  - Verify: Characters standing on floor (not floating or clipping)

**Acceptance Criteria**:
- ✅ POC layout validation still passes
- ✅ Calculated positions match actual positions within tolerance
- ✅ Visual inspection confirms correct layout
- ✅ All characters at correct floor height

---

## 10. Comprehensive Test Coverage Verification

**Priority**: Verification (final validation)
**Estimated Effort**: 1 hour
**Dependencies**: Tasks 1-6

### Subtasks

- [x] 10.1 Run full property test suite
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property`
  - Verify: All 34 property tests pass
  - Verify: No engine errors during execution

- [x] 10.2 Run full unit test suite
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit`
  - Verify: All 80 unit tests pass (no regressions)

- [x] 10.3 Run complete test suite
  - Run: `godot --headless --script addons/gut/gut_cmdln.gd`
  - Verify: 114/114 tests pass (100%)
  - Verify: No warnings or errors in output

- [x] 10.4 Update ERROR_SUMMARY.md
  - Mark all 12 bugs as FIXED
  - Document the fixes applied
  - Update test pass rates

**Acceptance Criteria**:
- ✅ All 114 tests pass (100% pass rate)
- ✅ No engine errors during test execution
- ✅ ERROR_SUMMARY.md updated with fix status

---

## Testing Commands

### Run All Tests
```bash
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd
```

### Run Property Tests Only
```bash
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

### Run Specific Property Test
```bash
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property -gtest=test_property_corridor_count_accuracy
```

### Validate POC Layout
```bash
cd apps/game-client
godot --headless --script scripts/utils/validate_poc_layout.gd
```

---

## Success Criteria

All tasks must be completed with:
- ✅ All 12 failing property tests now pass
- ✅ Character floor positioning validation passes
- ✅ Test pass rate: 114/114 (100%)
- ✅ No engine errors during test execution
- ✅ POC layout remains valid with corrected algorithms
- ✅ Visual verification: Correct number of corridors between rooms
- ✅ Visual verification: Characters standing on floor (not floating)

---

## Notes

### Implementation Order

Follow this order to minimize rework:
1. Task 1 (enables proper testing)
2. Tasks 2, 3, 7, 8 (can be done in parallel - independent fixes)
3. Tasks 4, 5, 6 (depend on tasks 2 and 3)
4. Task 9 (verification - depends on tasks 2-6 and 8)
5. Task 10 (final verification - depends on all tasks)
5. Task 10 (final verification - depends on all tasks)

### Testing Strategy

After each task:
1. Run the specific property test for that fix
2. Verify the test passes with 95%+ success rate
3. Run the full test suite to check for regressions
4. Document any issues or unexpected behavior

### Rollback Plan

If a fix causes regressions:
1. Revert the changes
2. Analyze the failure
3. Update the design document with new findings
4. Re-implement with corrected approach

### Documentation Updates

After all fixes are complete:
1. Update ERROR_SUMMARY.md with fix status
2. Update LEVEL_LAYOUT_NOTES.md if POC positions changed
3. Update asset-validation.md with corrected formulas
4. Add lessons learned to project documentation
