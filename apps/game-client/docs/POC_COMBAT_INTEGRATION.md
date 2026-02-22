# POC Dungeon Combat Integration Guide

## Overview

This guide shows how to integrate the new combat system into the existing POC dungeon (`scenes/main.tscn`).

## Current POC Structure

The POC dungeon has:
- NavigationRegion3D with baked navigation
- 5 rooms (Room1-5) with Kenney dungeon assets
- Corridors connecting rooms
- Existing player with Health/Movement/Combat components
- Enemy spawns

## Integration Steps

### Step 1: Add Combat Components to Existing Player

The existing player scene (`scenes/player/player.tscn`) uses old components. Add new combat components alongside:

1. Open `scenes/player/player.tscn` in Godot editor
2. Add these nodes as children of Player:
   - StatsComponent (script: `res://scripts/combat/stats_component.gd`)
     - Set stats resource to `res://data/combat_stats/player_stats.tres`
   - StateMachine (script: `res://scripts/combat/state_machine.gd`)
   - CombatComponent (script: `res://scripts/combat/combat_component.gd`)
   - Inventory (script: `res://scripts/systems/inventory.gd`)

3. Add AbilityController as child of CombatComponent:
   - AbilityController (script: `res://scripts/combat/ability_controller.gd`)
   - Add MeleeAttack as child (script: `res://scripts/combat/abilities/melee_attack.gd`)
   - Add Fireball as child (script: `res://scripts/combat/abilities/fireball.gd`)

4. Add collision areas as children of Player:
   - HitboxArea3D (script: `res://scripts/combat/hitbox_area3d.gd`)
     - Collision Layer: 16 (Layer 5)
     - Collision Mask: 32 (Layer 6)
     - Add CollisionShape3D child with SphereShape3D (radius 2.0)
   - HurtboxArea3D (script: `res://scripts/combat/hurtbox_area3d.gd`)
     - Collision Layer: 16 (Layer 5)
     - Collision Mask: 32 (Layer 6)
     - Add CollisionShape3D child with SphereShape3D (radius 1.0)

5. Update player.gd script to add combat input handling (see below)

### Step 2: Update Player Script

Add to `scenes/player/player.gd`:

```gdscript
# Add references
@onready var combat_component: CombatComponent = $CombatComponent
@onready var inventory: Inventory = $Inventory

# Add to _input() or create new input handler
func _input(event: InputEvent) -> void:
    if not combat_component:
        return
    
    # Attack (left mouse button)
    if event.is_action_pressed("attack"):
        combat_component.attack()
    
    # Dodge (spacebar)
    if event.is_action_pressed("dodge"):
        var dodge_dir = velocity.normalized() if velocity.length() > 0.1 else -global_transform.basis.z
        combat_component.dodge(dodge_dir)
    
    # Cast fireball (right mouse button)
    if event.is_action_pressed("cast_fireball"):
        if combat_component.ability_controller:
            combat_component.ability_controller.activate_ability("fireball")

# Add inventory methods
func add_gold(amount: int) -> void:
    if inventory:
        inventory.add_gold(amount)

func add_item(item_data: Dictionary) -> void:
    if inventory:
        inventory.add_item(item_data)
```

### Step 3: Add Combat to Existing Enemies

The POC has enemy_base.tscn. Update it:

1. Open `scenes/enemies/enemy_base.tscn`
2. Add these nodes as children:
   - StatsComponent (with goblin_stats.tres)
   - StateMachine
   - CombatComponent (with goblin_loot.tres)
   - EnemyAI (configure detection_radius: 10.0, attack_range: 2.0)
   - NavigationAgent3D (if not already present)
   - HitboxArea3D (Layer 32, Mask 16)
   - HurtboxArea3D (Layer 32, Mask 16)

3. Update enemy script to work with EnemyAI (movement handled by AI)

### Step 4: Add RespawnManager to Main Scene

1. Open `scenes/main.tscn`
2. Add RespawnManager node as child of Main:
   - Script: `res://scripts/systems/respawn_manager.gd`
   - Add to group: "respawn_manager"

3. Update main.gd to set checkpoint:

```gdscript
@onready var respawn_manager: RespawnManager = $RespawnManager
@onready var player = $Player

func _ready():
    if respawn_manager and player:
        respawn_manager.set_checkpoint(player.global_position)
        
        # Connect player death
        var stats = player.get_node_or_null("StatsComponent")
        if stats:
            stats.died.connect(func(): respawn_manager.on_player_died(player))
```

### Step 5: Add UI to Main Scene

Add UI layer to main.tscn:

1. Add CanvasLayer node as child of Main
2. Add these UI components as children of CanvasLayer:
   - HealthBar (connect to player's StatsComponent)
   - ResourceBars (connect to player's StatsComponent)
   - DeathScreen (initially hidden)
   - AbilityCooldownUI (connect to player's AbilityController)

### Step 6: Configure Input Actions

Add to Project Settings > Input Map:
- `attack`: Left Mouse Button
- `dodge`: Spacebar
- `cast_fireball`: Right Mouse Button
- `move_forward`: W
- `move_backward`: S
- `move_left`: A
- `move_right`: D

### Step 7: Test in POC Dungeon

1. Open `scenes/main.tscn`
2. Press F5 to run
3. Test combat:
   - Move through dungeon with WASD
   - Attack enemies with left click
   - Dodge with spacebar
   - Cast fireball with right click
   - Collect loot from defeated enemies
   - Test death and respawn

## Alternative: Use Combat-Ready Scenes

If you prefer, you can replace the existing player/enemy with the new combat-ready versions:

1. In `scenes/main.tscn`, change player instance from:
   ```
   [node name="Player" parent="." instance=ExtResource("1")]
   ```
   To:
   ```
   [ext_resource type="PackedScene" path="res://scenes/entities/combat_player.tscn" id="combat_player"]
   [node name="Player" parent="." instance=ExtResource("combat_player")]
   ```

2. Replace enemy instances with:
   ```
   [ext_resource type="PackedScene" path="res://scenes/entities/goblin.tscn" id="goblin"]
   [node name="Enemy1" parent="NavigationRegion3D/Room2" instance=ExtResource("goblin")]
   ```

## Collision Layer Setup

Ensure these layers are configured in Project Settings > Layer Names > 3D Physics:

- Layer 1: World
- Layer 2: Player
- Layer 3: Enemy
- Layer 4: PlayerCombat
- Layer 5: EnemyCombat
- Layer 6: Projectile
- Layer 7: Pickup

## Testing Checklist

After integration:
- [ ] Player can move through POC dungeon
- [ ] Player can attack enemies
- [ ] Player can dodge roll
- [ ] Player can cast fireball
- [ ] Enemies detect and chase player
- [ ] Enemies attack player
- [ ] Damage numbers appear
- [ ] Health/mana/stamina bars work
- [ ] Player can die and respawn
- [ ] Enemies drop loot
- [ ] Loot can be picked up
- [ ] Navigation works in all rooms

## Troubleshooting

**Enemies not moving?**
- Check NavigationRegion3D has baked navigation mesh
- Verify EnemyAI has NavigationAgent3D reference
- Check enemy collision layers

**Combat not working?**
- Verify collision layers are configured correctly
- Check that CombatComponent has all sub-components
- Ensure hitbox/hurtbox collision shapes are present

**Input not responding?**
- Check input actions are configured in Project Settings
- Verify player script has _input() method
- Check console for errors

## Benefits of POC Integration

✅ Uses existing validated dungeon layout  
✅ Preserves navigation mesh  
✅ Keeps existing character models  
✅ Tests combat in real dungeon environment  
✅ No need for separate test arena  

## Next Steps

After successful integration:
1. Add more enemy types to different rooms
2. Add loot variety
3. Add boss to Room5
4. Add checkpoints at room entrances
5. Add UI polish
6. Add audio
