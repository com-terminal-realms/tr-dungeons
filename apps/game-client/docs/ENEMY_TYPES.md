# Enemy Type Mapping

## Overview

This document defines the enemy types used in the game and their configurations.

## Enemy Types

### peasant_sword

**Model**: Female_Ranger (Quaternius Character Pack)
**Weapon**: Sword (Quaternius Medieval Weapons Pack)
**Scale**: 1.0 (normal size)
**Usage**: Standard melee enemy
**Note**: Using Female_Ranger (complete armored outfit). Female vs Male provides some visual distinction from player.

**Stats**:
- Health: 50 HP
- Damage: 5
- Attack Range: 1.5 units
- Attack Cooldown: 1.5 seconds
- Move Speed: 3.0
- Detection Range: 10.0 units

**Animations**:
- Idle: Standing still
- Walk: Moving/chasing player
- Sword_Attack: Melee attack (plays when attacking player)

**Weapon Configuration**:
- Hand Bone: `hand_r`
- Weapon Offset: (0, 0.1, 0)
- Weapon Rotation: (-90, 0, 225)
- Weapon Scale: 0.25

**Scene**: `scenes/enemies/enemy_base.tscn`

### Boss Variant

**Type**: peasant_sword (scaled up)
**Scale**: 2.0 (2x the regular enemy)
**Health**: 200 HP
**Damage**: 15
**Attack Range**: 2.0 units
**Attack Cooldown**: 2.0 seconds
**Move Speed**: 2.5
**Detection Range**: 15.0 units

## Future Enemy Types

### peasant_bow (planned)
- Ranged enemy with bow
- Same model, different weapon

### ranger_sword (planned)
- Male_Ranger model with sword
- Tougher melee enemy

### ranger_bow (planned)
- Male_Ranger model with bow
- Tougher ranged enemy

## Adding New Enemy Types

1. Create new scene inheriting from `enemy_base.tscn`
2. Change CharacterModel to desired model
3. Update WeaponAttachment weapon path
4. Adjust stats in component properties
5. Add entry to this document
