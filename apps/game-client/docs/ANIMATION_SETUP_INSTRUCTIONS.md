# Animation Setup - WORKING SOLUTION

## How It Works

Animations are loaded automatically at runtime using the `RuntimeAnimationLoader` component. No manual editor work required!

## Implementation

### RuntimeAnimationLoader Component

Located: `scripts/components/runtime_animation_loader.gd`

This script:
1. Loads the UAL1_Standard.glb scene at runtime
2. Finds the AnimationPlayer inside it
3. Extracts all 45 animations
4. Creates an AnimationLibrary
5. Adds it to the character's AnimationPlayer

### Player Scene Setup

The player scene has:
- `CharacterModel` (Male_Ranger.gltf instance)
  - `AnimationPlayer` (empty at start)
  - `RuntimeAnimationLoader` (loads animations on ready)

### Animation Playback

The player script (`scenes/player/player.gd`) automatically switches between:
- **Idle** - When standing still
- **Walk** - When moving

## Available Animations

45 animations loaded from UAL1_Standard.glb:
- Locomotion: Idle, Walk, Sprint, Jog_Fwd, Crouch_Fwd
- Combat: Sword_Attack, Punch_Jab, Punch_Cross, Roll
- Actions: Jump, Jump_Start, Jump_Land, PickUp_Table
- Emotes: Dance, Sitting_Idle, Spell_Simple_Shoot
- And 30+ more...

## Adding New Animations

To use different animations, edit `player.gd`:

```gdscript
func _update_animation(direction: Vector3) -> void:
    if not _animation_player:
        return
    
    var is_moving := direction.length() > 0.1
    
    if is_moving:
        _animation_player.play("Sprint")  # Change to Sprint
    else:
        _animation_player.play("Idle")
```

## Why This Approach Works

- **No manual editor work** - Everything loads at runtime
- **No animation retargeting needed** - UAL animations are compatible with Quaternius characters
- **Automatic** - Just add RuntimeAnimationLoader to any character
- **Flexible** - Easy to change which animations play

## Troubleshooting

### Character in T-pose
- Check console for "RuntimeAnimationLoader: Successfully loaded X animations"
- If 0 animations, check the animation_library_path

### Wrong animation playing
- Check animation names with: `print(_animation_player.get_animation_list())`
- Animation names are case-sensitive

### Character floating
- This is a known issue - character model origin is slightly above ground
- Quick fix: Adjust CharacterModel position.y in player.tscn


## Available Animations

Once imported, you'll have access to:

- **Idle** - Standing still
- **Walk_F** - Walk forward
- **Walk_B** - Walk backward
- **Run_F** - Run forward
- **Jump** - Jumping
- **Punch_L** / **Punch_R** - Attacks
- And 100+ more...

## Troubleshooting

### Animations don't play
- Make sure AnimationPlayer is a child of Player node
- Check that animations were imported (should see them in Animation dropdown)
- Verify the animation names match exactly (case-sensitive)

### Character animates but doesn't match movement direction
- You may need to use different animations for different directions
- Or rotate the CharacterModel node to face movement direction

### Animations look weird
- The skeleton might need retargeting
- In Scene tree, find the Skeleton3D node inside CharacterModel
- Right-click → Skeleton3D → Retarget Skeleton
- Map bones from UAL1 to Male_Ranger

## Alternative: Simple Bobbing Animation

If you don't want to set up full skeletal animations, you can use the simple walk animation script I created:

1. The `SimpleWalkAnimation` component is already in the player scene
2. It makes the character bob up and down when moving
3. This is a placeholder until you set up proper animations

To enable it, make sure this node exists in player.tscn:
```
[node name="SimpleWalkAnimation" type="Node" parent="."]
script = ExtResource("7")
movement_component_path = NodePath("../Movement")
```

This won't move arms/legs, but gives visual feedback that the character is moving.
