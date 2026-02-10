# Requirements Document: Dungeon Asset Mapping System - Bug Fixes

## Introduction

This specification addresses 12 critical bugs discovered through property-based testing in the Dungeon Asset Mapping System. While unit tests show 100% pass rate, property-based tests reveal significant correctness issues in core algorithms, validation logic, and test infrastructure.

The bugs fall into three categories:
1. **Test Infrastructure Issues** (2 bugs) - Scene tree initialization errors blocking proper testing
2. **Core Algorithm Failures** (4 bugs) - Corridor spacing formula and gap detection calculation errors
3. **Validation System Failures** (5 bugs) - Layout validation cannot distinguish valid from invalid layouts
4. **Component Edge Cases** (1 bug) - Health signal emission edge cases

## Glossary

- **Property-Based Test (PBT)**: A test that validates universal properties across 100+ randomized inputs
- **Scene Tree**: Godot's node hierarchy; nodes must be added to tree before accessing transform data
- **Corridor Count Formula**: Algorithm that calculates how many corridor pieces fit in a target distance
- **Gap Detection**: Validation logic that identifies spacing errors between connected assets
- **Overlap Detection**: Validation logic that identifies collision issues between assets
- **Layout Validation**: System that verifies entire dungeon layouts for correctness
- **Navigation Continuity**: Property ensuring walkable areas form continuous paths
- **Health Signal**: Event emitted when health changes or character dies

## Requirements

### Requirement 1: Fix Scene Tree Initialization in Property Tests

**User Story:** As a developer, I want property tests to properly initialize scene nodes, so that transform data can be accessed without engine errors.

#### Acceptance Criteria

1. WHEN a property test creates asset nodes, THE test SHALL add nodes to the scene tree before accessing transform data
2. WHEN accessing `get_global_transform()`, THE node SHALL be in the scene tree (no "!is_inside_tree()" errors)
3. WHEN property tests complete, THE test SHALL properly clean up scene tree nodes
4. WHEN running "Walkable Area Containment" property test, THE test SHALL complete without 500+ engine errors
5. WHEN running "Collision Documentation Completeness" property test, THE test SHALL complete without 100+ engine errors

### Requirement 2: Fix Corridor Count Formula Calculation

**User Story:** As a level designer, I want the corridor count formula to accurately calculate spacing, so that generated layouts match target distances within tolerance.

#### Acceptance Criteria

1. WHEN calculating corridor count for any distance, THE formula SHALL produce layouts within ±0.5 units of target distance
2. WHEN testing with 100 random distances, THE formula SHALL pass at least 95% of iterations (currently: 8% pass rate)
3. WHEN calculating overlap at connection points, THE overlap value SHALL be accurate and consistent
4. WHEN placing calculated number of corridors, THE actual total length SHALL match the target distance within tolerance
5. WHEN the formula fails, THE error SHALL be less than 0.5 units (currently: errors up to 4.74 units observed)

### Requirement 3: Fix Gap and Overlap Detection Logic

**User Story:** As a level designer, I want gap and overlap detection to accurately identify spacing issues, so that layout validation catches all connection errors.

#### Acceptance Criteria

1. WHEN two assets have a gap > 0.2 units, THE validator SHALL detect the gap
2. WHEN two assets overlap (distance < 0), THE validator SHALL detect the overlap
3. WHEN testing with 100 random asset placements, THE detection SHALL pass at least 95% of iterations (currently: 66% pass rate)
4. WHEN assets are within tolerance (gap ≤ 0.2 units), THE validator SHALL NOT report false positives
5. WHEN overlap distance is -0.15 units or greater, THE validator SHALL detect it (currently: not detected)

### Requirement 4: Fix Layout Connection Validation

**User Story:** As a level designer, I want layout validation to correctly distinguish valid from invalid layouts, so that I can trust the validation results.

#### Acceptance Criteria

1. WHEN a layout has proper spacing (no gaps > 0.2 units), THE validator SHALL mark it as valid
2. WHEN a layout has gaps > 0.2 units, THE validator SHALL mark it as invalid and report gap locations
3. WHEN testing with 100 random layouts, THE validation SHALL pass at least 95% of iterations (currently: 0% pass rate)
4. WHEN validation reports a gap, THE reported gap size SHALL be accurate within ±0.01 units
5. WHEN all connections are within tolerance, THE validator SHALL NOT report false positive gap errors

### Requirement 5: Fix Navigation Path Continuity Validation

**User Story:** As a level designer, I want navigation validation to detect missing walkable areas, so that I can ensure characters can navigate the entire dungeon.

#### Acceptance Criteria

1. WHEN an asset has no walkable area defined, THE validator SHALL detect and report it
2. WHEN walkable areas are disconnected, THE validator SHALL detect the discontinuity
3. WHEN testing with 100 random layouts, THE validation SHALL pass at least 95% of iterations (currently: 0% pass rate)
4. WHEN all walkable areas are properly defined and connected, THE validator SHALL mark the layout as valid
5. WHEN validation detects missing walkable areas, THE error message SHALL identify which asset is missing the walkable area

### Requirement 6: Fix Health Signal Emission Edge Cases

**User Story:** As a game developer, I want health signals to emit correctly in all scenarios, so that UI and game logic can reliably track health changes.

#### Acceptance Criteria

1. WHEN health changes due to damage or healing, THE health_changed signal SHALL emit exactly once per operation
2. WHEN health reaches zero, THE died signal SHALL emit exactly once
3. WHEN testing with 100 random damage/heal sequences, THE signal emission SHALL pass at least 95% of iterations (currently: 95% pass rate, needs 100%)
4. WHEN multiple damage operations occur in sequence, THE signal count SHALL match the operation count
5. WHEN health is already at zero, THE health_changed signal SHALL NOT emit for additional damage

### Requirement 7: Validate POC Layout Against Fixed Algorithms

**User Story:** As a developer, I want to verify that the POC layout is actually valid, so that I can trust the validation system's assessment.

#### Acceptance Criteria

1. WHEN the POC layout is validated with fixed algorithms, THE validation SHALL still pass
2. WHEN corridor spacing is recalculated for the POC, THE calculated positions SHALL match actual positions within ±0.1 units
3. WHEN gap detection runs on POC connections, THE detector SHALL find no gaps > 0.2 units
4. WHEN the POC validation script reports "all connections valid", THE property tests SHALL agree
5. WHEN comparing old and new validation results, THE POC layout SHALL remain valid (no regression)

### Requirement 8: Validate Character Floor Positioning

**User Story:** As a level designer, I want to ensure characters and creatures are positioned at the correct floor height, so that they appear to be standing on the floor rather than floating or clipping through it.

#### Acceptance Criteria

1. WHEN a character is placed in a room, THE character's Y position SHALL match the room's floor height plus the character's height offset
2. WHEN validating a layout with characters, THE validator SHALL check that all characters are at the correct floor height
3. WHEN testing with 100 random character placements, THE validation SHALL pass at least 95% of iterations
4. WHEN a character's Y position is incorrect, THE validator SHALL report the expected Y position and the actual Y position
5. WHEN all characters are correctly positioned, THE validator SHALL mark the layout as valid

### Requirement 9: Comprehensive Test Coverage for Bug Fixes

**User Story:** As a developer, I want comprehensive tests for all bug fixes, so that I can verify correctness and prevent regressions.

#### Acceptance Criteria

1. WHEN all bug fixes are complete, ALL property tests SHALL pass with 100+ iterations each
2. WHEN running the full test suite, THE pass rate SHALL be 100% (currently: 89%)
3. WHEN property tests run, THE test execution SHALL complete without engine errors
4. WHEN unit tests run, THE pass rate SHALL remain 100% (no regressions)
5. WHEN integration tests run, THE POC workflow SHALL complete successfully with fixed algorithms

## Success Criteria

All requirements must be satisfied:
- ✅ All 12 failing property tests pass with 100+ iterations
- ✅ No engine errors during test execution
- ✅ POC layout validation still passes with fixed algorithms
- ✅ Unit test pass rate remains 100%
- ✅ Character floor positioning validation passes
- ✅ Overall test pass rate reaches 100% (114/114 tests passing)

## Out of Scope

The following are explicitly out of scope for this bug-fix specification:
- Adding new features to the asset mapping system
- Expanding the system to support additional asset types
- Performance optimizations beyond correctness fixes
- UI improvements or documentation updates (unless required for bug fixes)
- Refactoring code that is working correctly

## Priority Ranking

Based on impact and dependencies:

1. **Critical** (Blocks all other fixes):
   - Requirement 1: Scene tree initialization (blocks proper testing)

2. **High** (Core algorithm failures):
   - Requirement 2: Corridor count formula (affects all spacing calculations)
   - Requirement 3: Gap/overlap detection (required for validation)

3. **Medium** (Validation system):
   - Requirement 4: Layout connection validation (depends on #2 and #3)
   - Requirement 5: Navigation continuity (depends on walkable area calculations)

4. **Low** (Edge cases):
   - Requirement 6: Health signal emission (independent component)

5. **Verification** (Final validation):
   - Requirement 7: POC layout validation (verifies no regressions)
   - Requirement 8: Character floor positioning (ensures correct Y positioning)
   - Requirement 9: Comprehensive test coverage (verifies all fixes)

## Notes

- The POC layout validation script reports success, but property tests reveal underlying issues
- This suggests the validation script has overly permissive tolerances or incorrect logic
- The bug fixes must maintain backward compatibility with the POC layout
- All fixes must be validated with both unit tests and property tests
- Property tests must run 100+ iterations to ensure statistical confidence
