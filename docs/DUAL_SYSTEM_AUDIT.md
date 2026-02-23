# Dual System Audit - Combat System Migration Issues

## Overview

During the combat system integration, we created NEW combat components while keeping OLD components for compatibility. This has created synchronization issues where the two systems can get out of sync, causing bugs like enemies dying early.

## Critical Issue: Boss Dying at 30% Health

**Root Cause**: Enemy has TWO death handlers that trigger independently:

1. **OLD Health component** (`scripts/components/health.gd`)
   - Connected in `enemy_base.gd`
   - Calls `queue_free()` immediately on death
   - Has its own max_health value

2. **NEW StatsComponent** (`scripts/combat/stats_component.gd`)
   - Connected in `combat_component.gd`
   - Schedules removal after 5 seconds
   - Has its own max_health value in CombatStats

**The Problem**: 
- `combat_component.gd` applies damage to BOTH systems
- If max_health values differ, they reach 0 at different times
- OLD Health reaches 0 first → enemy removed immediately
- NEW StatsComponent still has health → health bar shows 30%
- HealthBar displays NEW system, but OLD system controls death

**STATUS**: ✅ FIXED - Enemy now only connects to NEW StatsComponent.died

## Critical Issue: Player Dying at 50% Health

**Root Cause**: Player has TWO death handlers that trigger independently:

1. **OLD Health component** - Connected in `player.gd`
2. **NEW StatsComponent** - Also connected in `player.gd`

**The Problem**:
- Player was connected to BOTH death signals
- OLD Health reached 0 first (damaged by OLD Combat system)
- Player respawned even though health bar showed 50%
- Health bar displays NEW StatsComponent, but OLD Health triggered death

**STATUS**: ✅ FIXED - Player now only connects to NEW StatsComponent.died

## Critical Issue: Player Healing Not Working

**Root Cause**: Player's `_handle_heal()` function uses OLD Health component, but health bar displays NEW StatsComponent.

**The Problem**:
- Pressing H key heals OLD Health component
- Health bar shows NEW StatsComponent (unchanged)
- Player sees no visual feedback from healing

**STATUS**: ✅ FIXED - Healing now uses NEW StatsComponent

## Critical Issue: Damage Number Spawn Error

**Root Cause**: Trying to spawn damage numbers on enemies that have already been removed from the scene tree.

**The Problem**:
- Enemy dies and gets removed from tree
- Damage number tries to get `global_position` from removed node
- Error: "Condition '!is_inside_tree()' is true"

**STATUS**: ✅ FIXED - Check `is_inside_tree()` before spawning damage number

## Dual Systems Identified

### 1. Health System

**OLD System**:
- Component: `Health` (`scripts/components/health.gd`)
- Data Model: `HealthData` (`scripts/models/health_data.gd`)
- Signal: `died()`
- Used by: `enemy_base.gd`, `player.gd`, OLD combat tests

**NEW System**:
- Component: `StatsComponent` (`scripts/combat/stats_component.gd`)
- Resource: `CombatStats` (`scripts/combat/combat_stats.gd`)
- Signal: `died()`
- Used by: `combat_component.gd`, `health_bar.gd`

**Synchronization Point**:
```gdscript
# In combat_component.gd take_damage()
# Apply damage to NEW stats component
if stats_component:
    stats_component.reduce_health(final_damage)

# ALSO apply damage to OLD Health component for health bar compatibility
var parent := get_parent()
if parent:
    for child in parent.get_children():
        if child is Health:
            child.take_damage(int(final_damage))
            break
```

**Issues**:
- Two separate max_health values can differ
- Two separate death signals
- Health bar watches NEW system
- Enemy death handler watches OLD system
- Damage applied to both, but they can desync

### 2. Combat System

**OLD System**:
- Component: `Combat` (`scripts/components/combat.gd`)
- Data Model: `CombatData` (`scripts/models/combat_data.gd`)
- Simple attack logic with cooldowns
- Used by: `player.gd` (fallback), OLD tests

**NEW System**:
- Component: `CombatComponent` (`scripts/combat/combat_component.gd`)
- Uses: `StatsComponent`, `StateMachine`, `AbilityController`
- Advanced combat with abilities, states, hitboxes
- Used by: `player.gd` (primary), enemies with NEW system

**Synchronization Point**:
```gdscript
# In player.gd _process()
if _combat_component:
    var attack_result = _combat_component.attack()
else:
    _handle_attack()  # Falls back to OLD Combat system
```

**Issues**:
- Player has both systems
- NEW system is primary, OLD is fallback
- No synchronization between them
- Different attack mechanics

### 3. Movement System

**Status**: Single system only
- Component: `Movement` (`scripts/components/movement.gd`)
- No dual system issues

## Files Using OLD Health System

### Core Files:
- `scenes/enemies/enemy_base.gd` - **CRITICAL**: Connects to OLD Health.died signal
- `scenes/player/player.gd` - Has reference to OLD Health component
- `scripts/components/combat.gd` - OLD Combat finds OLD Health

### Test Files:
- `tests/unit/test_health.gd`
- `tests/unit/test_player.gd`
- `tests/unit/test_enemy.gd`
- `tests/property/test_health_properties.gd`
- `tests/property/test_combat_properties.gd`
- `tests/integration/test_combat_flow.gd`
- `tests/integration/test_full_playthrough.gd`

## Files Using NEW StatsComponent

### Core Files:
- `scripts/combat/combat_component.gd` - Connects to NEW StatsComponent.died signal
- `scripts/ui/health_bar.gd` - **CRITICAL**: Displays NEW StatsComponent health
- `scripts/combat/ability_controller.gd` - Uses NEW StatsComponent for resources
- `scripts/combat/enemy_ai.gd` - Uses NEW StatsComponent for move speed
- `scripts/systems/respawn_manager.gd` - Restores NEW StatsComponent health

## Recommended Fixes

### Option 1: Remove OLD System (Recommended)

**Pros**:
- Single source of truth
- No synchronization issues
- Cleaner codebase

**Cons**:
- Need to update all references
- Need to update all tests
- More work upfront

**Steps**:
1. Remove OLD Health component from enemy_base.tscn
2. Remove OLD Health component from player.tscn
3. Update enemy_base.gd to connect to StatsComponent.died
4. Update player.gd to remove OLD Health references
5. Remove OLD Combat component references
6. Update all tests to use NEW system
7. Remove compatibility code from combat_component.gd

### Option 2: Synchronize Systems (Not Recommended)

**Pros**:
- Less code changes
- Tests still work

**Cons**:
- Complex synchronization logic
- Still have two sources of truth
- Easy to introduce bugs
- Technical debt

## Immediate Fix for Boss Death Bug

**Quick Fix** (to unblock testing):
```gdscript
# In enemy_base.gd _ready()
# Comment out OLD Health connection
# if _health:
#     _health.died.connect(_on_death)

# Connect to NEW StatsComponent instead
var combat_comp := $CombatComponent
if combat_comp and combat_comp.stats_component:
    combat_comp.stats_component.died.connect(_on_death)
```

**Proper Fix** (Option 1 above):
- Remove OLD Health component entirely
- Migrate all code to use NEW StatsComponent
- Update all tests

## Action Items

1. **IMMEDIATE**: Fix boss death bug (use Quick Fix above)
2. **SHORT TERM**: Audit all enemy/player scenes for dual components
3. **MEDIUM TERM**: Migrate all code to NEW system (Option 1)
4. **LONG TERM**: Remove OLD system components and files

## Testing Checklist

After fixing dual systems:
- [ ] Boss health bar shows correct percentage
- [ ] Boss dies when health bar reaches 0%
- [ ] Player health bar shows correct percentage
- [ ] Player respawn works correctly
- [ ] Enemy health bars show correct percentage
- [ ] All unit tests pass
- [ ] All property tests pass
- [ ] All integration tests pass

## Related Documentation

- `docs/COMBAT_INTEGRATION_STATUS.md` - Combat system status
- `docs/COORDINATE_SYSTEM.md` - Coordinate system standards
- `.kiro/steering/project-standards.md` - Project standards
