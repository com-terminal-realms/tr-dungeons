# Animation Setup Instructions - UPDATED METHOD

## The Problem

The UAL1_Standard.glb file contains animations, but they're in a separate scene file. We need to extract those animations and add them to the player's AnimationPlayer.

## Solution: Use Animation Library

### Method 1: Direct Animation Library Import (Easiest)

1. **Open Godot Editor**
   ```bash
   cd apps/game-client
   godot --editor .
   ```

2. **Open Player Scene**
   - Navigate to `scenes/player/player.tscn`

3. **Select AnimationPlayer**
   - In Scene tree: `Player → CharacterModel → AnimationPlayer`

4. **Add Animation Library**
   - In the Inspector panel (right side), find "Libraries"
   - Click the dropdown next to "Libraries"
   - Click "Add Library"
   - Name it: `ual` (or any name you want)

5. **Load UAL Animations**
   - Click the folder icon next to the new library
   - Navigate to: `assets/characters/animations/UAL1_Standard.glb`
   - Select it and click "Open"
   - Godot will extract all animations from the file

6. **Save the Scene**
   - Press Ctrl+S to save
   - The animations should now persist!

7. **Test**
   - Press F5 to run
   - Character should animate when moving!

### Method 2: If Method 1 Doesn't Work - Copy Animation Files

If the above doesn't work, we need to manually reference the animation library:

1. **Open the UAL scene**
   - In FileSystem, navigate to `assets/characters/animations/`
   - Double-click `UAL1_Standard.glb` to open it as a scene

2. **Find the AnimationPlayer**
   - Look for an AnimationPlayer node in the UAL scene tree
   - Select it

3. **Check Available Animations**
   - In the Animation panel at bottom, you should see all animations
   - Note down some animation names (Idle, Walk_F, Run_F, etc.)

4. **Copy the Animation Library**
   - With AnimationPlayer selected, look at Inspector
   - Find "Libraries" section
   - Right-click on the library → "Copy"

5. **Paste into Player's AnimationPlayer**
   - Open `scenes/player/player.tscn`
   - Select `Player → CharacterModel → AnimationPlayer`
   - In Inspector, find "Libraries"
   - Right-click → "Paste"

6. **Save and Test**

### Method 3: Script-Based Animation (If all else fails)

If the editor methods don't work, we can load animations at runtime via script. Let me know if you need this approach.

## Checking If It Worked

Run the game and check the console output. You should see:
```
Player: AnimationPlayer found with animations: [Idle, Walk_F, Walk_B, Run_F, ...]
```

If you still see `[]`, the animations didn't load.

## Common Issues

### "Animation not found: Idle" errors
- Animations aren't loaded into AnimationPlayer
- Make sure you saved the scene after adding the library

### Animations load but character doesn't move
- The skeleton paths might not match
- The UAL skeleton is different from Male_Ranger skeleton
- May need animation retargeting (advanced)

### Can't find AnimationPlayer in CharacterModel
- Close and reopen the scene
- Or restart Godot editor
- The node should be there after the recent changes


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
