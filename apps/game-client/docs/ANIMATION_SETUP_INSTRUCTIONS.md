# Animation Setup Instructions

The character models are currently in T-pose and don't animate when moving. To add walking animations, you need to set up the AnimationPlayer in the Godot editor.

## Why This Requires the Editor

Animation retargeting (mapping animations from one skeleton to another) cannot be done via text files. It requires the Godot editor's visual tools.

## Steps to Add Animations

### 1. Open Godot Editor

```bash
cd apps/game-client
godot --editor .
```

### 2. Open Player Scene

In the FileSystem panel, navigate to:
- `scenes/player/player.tscn`

Double-click to open it.

### 3. Locate the AnimationPlayer Node

In the Scene tree, you should see:
- Player (CharacterBody3D)
  - CharacterModel (Male_Ranger instance)
  - AnimationPlayer ← Select this

### 4. Import Animations from UAL1_Standard.glb

With AnimationPlayer selected:

1. Click the **Animation** button at the bottom panel
2. Click the **Animation** dropdown menu → **Manage Animations**
3. Click **Load** button
4. Navigate to: `assets/characters/animations/UAL1_Standard.glb`
5. Select it and click **Open**
6. Godot will import all 120+ animations

### 5. Test an Animation

In the Animation panel:
1. Select "Idle" from the animation dropdown
2. Click the Play button (▶) to preview
3. The character should now animate!

### 6. Set Up Basic Animation Script

The AnimationPlayer now has animations, but we need to switch between them based on movement.

Open `scenes/player/player.gd` and add this to the `_physics_process` function:

```gdscript
func _physics_process(delta: float) -> void:
    # ... existing movement code ...
    
    # Animation switching
    var anim_player = $AnimationPlayer
    if anim_player:
        if velocity.length() > 0.1:
            if not anim_player.is_playing() or anim_player.current_animation != "Walk_F":
                anim_player.play("Walk_F")
        else:
            if not anim_player.is_playing() or anim_player.current_animation != "Idle":
                anim_player.play("Idle")
```

### 7. Save and Test

1. Save the scene (Ctrl+S)
2. Press F5 to run the game
3. Character should now walk when moving!

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
