# TR-Dungeons Coordinate System and Orientation

## Overview

This document defines the coordinate system, rotation conventions, and directional calculations used throughout the TR-Dungeons project. Following these standards ensures consistency across movement, combat, and visual systems.

## Godot Coordinate System

TR-Dungeons uses Godot's standard 3D coordinate system:

- **X-axis**: Right (positive) / Left (negative)
- **Y-axis**: Up (positive) / Down (negative)
- **Z-axis**: Backward (positive) / Forward (negative)

**Forward direction in Godot**: Negative Z (`-Z`)

## Rotation Conventions

### Y-Axis Rotation (Horizontal Plane)

All character rotations use Y-axis rotation for horizontal facing direction:

```gdscript
# Standard rotation calculation
rotation.y = atan2(direction.x, direction.z)
```

**Rotation values:**
- `0.0` radians = Facing forward (negative Z)
- `PI/2` radians = Facing right (positive X)
- `PI` radians = Facing backward (positive Z)
- `-PI/2` radians = Facing left (negative X)

### Forward Vector Calculation

**Standard Godot forward vector:**
```gdscript
var forward = -global_transform.basis.z
```

This gives the direction the entity is facing based on its rotation.

## Character Model Orientation Issue

### The Problem

The character model assets (Male_Ranger.gltf, Superhero_Male_FullBody.gltf) face **backwards** in their original files. The mesh geometry points in the **positive Z direction** instead of the standard **negative Z direction**.

### The Solution

We compensate for the backwards-facing model in the **attack system only**:

```gdscript
# In melee_attack.gd - uses +Z instead of -Z
var attacker_forward: Vector3 = attacker.global_transform.basis.z
```

**Why this works:**
- Movement system rotates the Player node correctly using standard `atan2(x, z)`
- The backwards model rotates with the Player node
- When Player faces forward (rotation.y = 0), the backwards model visually faces forward
- Attack forward vector uses `+basis.z` to match the visual direction

### What NOT to Do

❌ **Don't rotate the CharacterModel node** - This breaks movement
❌ **Don't invert rotation calculations** - This breaks everything
❌ **Don't change movement system** - It's using standard Godot conventions

## System Alignment

### Movement System (`movement.gd`)

```gdscript
# Standard Godot rotation
var target_rotation := atan2(direction.x, direction.z)
_character_body.rotation.y = target_rotation
```

**Status**: ✅ Correct - Uses standard Godot conventions

### Player Rotation (`player.gd`)

```gdscript
# Rotate to face clicked position
var direction_to_click := global_position.direction_to(result.position)
var target_rotation := atan2(direction_to_click.x, direction_to_click.z)
rotation.y = target_rotation
```

**Status**: ✅ Correct - Uses standard Godot conventions

### Attack Direction (`melee_attack.gd`)

```gdscript
# Compensates for backwards-facing model
var attacker_forward: Vector3 = attacker.global_transform.basis.z
```

**Status**: ✅ Correct - Compensates for model orientation

## Verification Checklist

When implementing new directional features, verify:

1. ✅ Character faces correct direction visually
2. ✅ Movement goes in the direction character is facing
3. ✅ Attacks hit targets in front of character
4. ✅ Rotation values match expected directions
5. ✅ Forward vector calculations are consistent

## Current Working State

**Confirmed working as of latest commit:**

- Character starts facing south (correct visual direction)
- Walks forward when clicking ahead
- Turns to face clicked position
- Attacks deal damage in the direction character is facing
- All systems are aligned and consistent

## Future Considerations

If we ever replace the character models with properly-oriented assets (facing negative Z), we will need to:

1. Change attack forward vector back to `-global_transform.basis.z`
2. Update this documentation
3. Test all directional systems

**Do not make this change unless the model assets are actually replaced.**

## Reference

- Godot coordinate system: https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html
- Transform basis vectors: https://docs.godotengine.org/en/stable/classes/class_transform3d.html
