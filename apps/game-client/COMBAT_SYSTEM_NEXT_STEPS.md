# Combat System - Next Steps for Integration

## Current Status

All core combat system code has been implemented (Tasks 1-23). The system is ready for integration but requires scene-level work to connect with existing game entities.

## Immediate Next Steps

### 1. Player Scene Integration (Priority 1)

**File**: `scenes/player/player.tscn`

**Required Changes:**
1. Add new combat components:
   - StatsComponent (with player_stats.tres)
   - StateMachine
   - AbilityController
   - HitboxArea3D (Layer 4, Mask 5)
   - HurtboxArea3D (Layer 4, Mask 5)

2. Add abilities as children of AbilityController:
   - MeleeAttack instance
   - Fireball instance

3. Update player.gd script:
   ```gdscript
   # Add references
   @onready var combat_component: CombatComponent = $CombatComponent
   
   # Update input handling
   func _input(event):
       if event.is_action_pressed("attack"):
           combat_component.attack()
       if event.is_action_pressed("dodge"):
           var direction = get_movement_direction()
           combat_component.dodge(direction)
       if event.is_action_pressed("cast_fireball"):
           combat_component.ability_controller.activate_ability("fireball")
   ```

4. Configure collision layers:
   - CharacterBody3D: Layer 2 (player)
   - HitboxArea3D: Layer 4, Mask 5 (hits enemies)
   - HurtboxArea3D: Layer 4, Mask 5 (hit by enemies)

### 2. Enemy Scene Integration (Priority 1)

**File**: `scenes/enemies/enemy_base.tscn`

**Required Changes:**
1. Add new combat components:
   - StatsComponent (with goblin_stats.tres or other enemy stats)
   - StateMachine
   - EnemyAI
   - NavigationAgent3D
   - HitboxArea3D (Layer 5, Mask 4)
   - HurtboxArea3D (Layer 5, Mask 4)

2. Configure EnemyAI:
   - detection_radius: 10.0
   - attack_range: 2.0
   - patrol_radius: 5.0

3. Add loot table resource

4. Configure collision layers:
   - CharacterBody3D: Layer 3 (enemy)
   - HitboxArea3D: Layer 5, Mask 4 (hits player)
   - HurtboxArea3D: Layer 5, Mask 4 (hit by player)

### 3. UI Integration (Priority 2)

**File**: `scenes/ui/hud.tscn` (or main scene)

**Required Changes:**
1. Add UI components:
   - HealthBar (connect to player's StatsComponent)
   - ResourceBars (connect to player's StatsComponent)
   - DeathScreen (add to UI layer, initially hidden)

2. Add RespawnManager to main scene:
   - Set initial checkpoint position
   - Connect to player's CombatComponent.died signal

3. Update main scene script:
   ```gdscript
   @onready var respawn_manager: RespawnManager = $RespawnManager
   @onready var player: Node3D = $Player
   
   func _ready():
       # Set initial checkpoint
       respawn_manager.set_checkpoint(player.global_position)
       
       # Connect player death
       var combat = player.get_node("CombatComponent")
       if combat:
           combat.stats_component.died.connect(func():
               respawn_manager.on_player_died(player)
           )
   ```

### 4. Test Arena Creation (Priority 3)

**File**: `scenes/test/combat_arena.tscn`

**Create:**
1. NavigationRegion3D with baked navigation mesh
2. Player spawn point (Marker3D)
3. 3-5 enemy spawn points
4. Checkpoint marker
5. Simple floor and walls for testing

**Purpose**: Isolated environment for testing combat mechanics without full game integration

## Input Actions Required

Add to project settings (Project > Project Settings > Input Map):

```
attack: Left Mouse Button
dodge: Spacebar
cast_fireball: Right Mouse Button
```

## Collision Layer Configuration

Add to project settings (Project > Project Settings > Layer Names > 3D Physics):

```
Layer 1: World (environment, walls)
Layer 2: Player (player character body)
Layer 3: Enemy (enemy character bodies)
Layer 4: PlayerCombat (player hitbox/hurtbox)
Layer 5: EnemyCombat (enemy hitbox/hurtbox)
Layer 6: Projectile (projectiles)
Layer 7: Pickup (loot items)
```

## Testing Checklist

After integration, test:

- [ ] Player can attack enemies with melee
- [ ] Player can dodge roll (consumes stamina, grants i-frames)
- [ ] Player can cast fireball (consumes mana)
- [ ] Enemies detect and chase player
- [ ] Enemies attack player when in range
- [ ] Damage numbers appear on hits
- [ ] Health/stamina/mana bars update correctly
- [ ] Player dies when health reaches 0
- [ ] Death screen shows with stats
- [ ] Respawn button appears after 2 seconds
- [ ] Player respawns at checkpoint with full resources
- [ ] Enemies reset on respawn
- [ ] Enemies drop loot on death
- [ ] Loot can be picked up

## Known Limitations

1. **Audio**: Hit feedback audio is placeholder (not implemented)
2. **Animations**: Requires attack/dodge/cast/death animations
3. **Inventory**: Loot pickup only prints to console (no inventory system)
4. **Backend**: No API integration (all data is local resources)
5. **Multiplayer**: Not implemented (schemas exist for future use)

## Migration Strategy

**Option A: Gradual Migration**
1. Keep old components alongside new ones
2. Migrate player first, test thoroughly
3. Migrate enemies one type at a time
4. Remove old components when all entities migrated

**Option B: Clean Break**
1. Create new player/enemy prefabs with new components
2. Replace all instances in scenes
3. Delete old component scripts
4. Update all references

**Recommendation**: Option A for safety, Option B for cleaner codebase

## Component Comparison

### Old System → New System

| Old Component | New Component | Notes |
|--------------|---------------|-------|
| Health | StatsComponent | Includes health, mana, stamina |
| Combat | CombatComponent | More comprehensive combat logic |
| Movement | (unchanged) | Movement component still valid |
| (none) | StateMachine | New state management |
| (none) | AbilityController | New ability system |
| (none) | EnemyAI | New AI system |

## Documentation

See also:
- `COMBAT_SYSTEM_IMPLEMENTATION_STATUS.md` - Detailed implementation status
- `.kiro/specs/combat-system/design.md` - System architecture
- `.kiro/specs/combat-system/requirements.md` - Requirements specification
- `.kiro/specs/combat-system/tasks.md` - Task list with completion status

## Questions?

If you encounter issues during integration:
1. Check component dependencies in COMBAT_SYSTEM_IMPLEMENTATION_STATUS.md
2. Verify collision layers are configured correctly
3. Ensure all required components are present and connected
4. Check console for error messages about missing components
