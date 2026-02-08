# Animation Setup Guide for Quaternius Characters

This guide explains how to set up the Quaternius Universal Animation Library with your character models in Godot.

## Quick Setup (In Godot Editor)

### Step 1: Import Animation Library

The animation library is already imported at:
- `res://assets/characters/animations/UAL1_Standard.glb`

### Step 2: Set Up Animation Player (Manual Method)

1. **Open the player scene** in Godot: `scenes/player/player.tscn`

2. **Select the CharacterModel node**

3. **In the Scene dock**, expand the imported Male_Ranger.gltf scene

4. **Find the Skeleton3D node** inside the character model

5. **Add an AnimationPlayer** as a child of the Player root node (if not already there)

6. **Import animations from UAL1_Standard.glb**:
   - Click on AnimationPlayer
   - Go to Animation menu → Manage Animations
   - Click "Load" and select `UAL1_Standard.glb`
   - This will import all 120+ animations

### Step 3: Set Up Animation Tree (Recommended)

1. **Add AnimationTree node** as child of Player

2. **In AnimationTree properties**:
   - Set "Anim Player" to point to your AnimationPlayer
   - Create a new AnimationNodeStateMachine for "Tree Root"

3. **Add animation states**:
   - Idle
   - Walk
   - Run
   - Attack (optional)

4. **Connect states** with transitions

5. **Set up blend positions** for smooth transitions

## Available Animations

The UAL1_Standard.glb contains these animation categories:

### Locomotion
- `Idle` - Standing still
- `Walk_F` - Walk forward
- `Walk_B` - Walk backward  
- `Walk_L` - Walk left
- `Walk_R` - Walk right
- `Run_F` - Run forward
- `Run_B` - Run backward
- `Run_L` - Run left
- `Run_R` - Run right
- `Jump` - Jump
- `Fall` - Falling
- `Land` - Landing

### Combat
- `Punch_L` - Left punch
- `Punch_R` - Right punch
- `Kick` - Kick attack
- `Block` - Blocking
- `Hit` - Taking damage
- `Death` - Death animation

### Interactions
- `PickUp` - Pick up item
- `Use` - Use/interact
- `Sit` - Sitting down
- `Stand` - Standing up

## Simple Animation Script

For basic idle/walk animations, use this script approach:

```gdscript
extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var movement = $Movement

func _process(_delta):
    if animation_player:
        var velocity = movement.velocity if movement else Vector3.ZERO
        
        if velocity.length() > 0.1:
            animation_player.play("Walk_F")
        else:
            animation_player.play("Idle")
```

## Animation Retargeting (Advanced)

If animations don't work immediately:

1. **Check Skeleton Compatibility**:
   - Both character and animation must use humanoid rig
   - Bone names should match

2. **Use Godot's Retargeting**:
   - Select Skeleton3D node
   - Go to Skeleton3D menu → "Retarget Skeleton"
   - Map bones from animation to character

3. **Verify Bone Mapping**:
   - Hips → Hips
   - Spine → Spine
   - Head → Head
   - LeftArm → LeftArm
   - RightArm → RightArm
   - LeftLeg → LeftLeg
   - RightLeg → RightLeg

## Troubleshooting

### Animations don't play
- Check that AnimationPlayer has animations loaded
- Verify animation names (case-sensitive)
- Ensure AnimationPlayer is active

### Character doesn't move with animation
- Root motion might be disabled
- Check if animations have root bone movement
- May need to enable "Root Motion" in AnimationTree

### Animations look wrong
- Skeleton might not be compatible
- Try retargeting animations
- Check bone mapping

### Performance issues
- Reduce number of active animations
- Use AnimationTree for blending
- Consider LOD for distant characters

## Next Steps

1. **Test basic animations** in Godot editor
2. **Set up AnimationTree** for smooth blending
3. **Add combat animations** when combat system is ready
4. **Implement animation events** for footsteps, attacks, etc.

## Resources

- Quaternius Setup Guide: `assets/models/quaternius-characters/Universal Animation Library[Standard]/Godot_Setup.png`
- Godot Animation Docs: https://docs.godotengine.org/en/stable/tutorials/animation/
- AnimationTree Tutorial: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
