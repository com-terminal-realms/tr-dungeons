# Troubleshooting Guide

## Animation System Issues

### Problem: Characters Not Visible or Animations Not Working

**Symptoms:**
- Characters are invisible (only healthbars and indicators visible)
- Console errors: "RuntimeAnimationLoader: Failed to load res://assets/characters/animations/UAL1_Standard.glb"
- Console errors: "Animation not found: Idle"
- Console errors: "No AnimationPlayer found"

**Cause:**
This typically happens when:
1. The `.godot/imported/` cache has been cleared
2. Asset import files are missing or corrupted
3. AnimationPlayer node is in the wrong location in the scene tree

**Solution:**

1. **Reimport Assets:**
   ```bash
   cd apps/game-client
   godot --editor .
   ```
   Wait for the editor to fully load and import all assets (5-10 seconds).
   Then close the editor and run the game normally.

2. **Verify Scene Structure:**
   The AnimationPlayer must be a sibling of CharacterModel, not a child:
   ```
   Player (CharacterBody3D)
   ├── CharacterModel (instanced glTF scene)
   ├── AnimationPlayer (sibling, not child!)
   └── RuntimeAnimationLoader (sibling)
   ```

3. **Check RuntimeAnimationLoader Path:**
   The `animation_player_path` should be `NodePath("../AnimationPlayer")`

### Problem: WeaponAttachment Not Finding Skeleton

**Symptoms:**
- Console error: "WeaponAttachment: No Skeleton3D found!"
- Weapon not visible in character's hand

**Cause:**
The Skeleton3D node is inside the instanced glTF scene and needs to be found recursively.

**Solution:**
The WeaponAttachment component automatically searches for Skeleton3D recursively. Ensure:
1. The character model is a glTF file with a skeleton
2. The WeaponAttachment is a child of the CharacterModel node
3. The `hand_bone_name` matches a bone in the skeleton (e.g., "hand_r")

## Asset Import Issues

### Problem: Kenney Dungeon Assets Not Loading

**Symptoms:**
- Console errors: "Failed loading resource: res://assets/models/kenney-dungeon/room-small.glb"
- Missing dungeon geometry

**Cause:**
Asset import files in `.godot/imported/` are missing.

**Solution:**
Open the Godot editor to trigger asset reimport:
```bash
cd apps/game-client
godot --editor .
```

## Performance Issues

### Problem: Low FPS or Stuttering

**Symptoms:**
- Performance monitor shows FPS below 60
- Game feels laggy

**Solutions:**
1. Check the performance monitor output in console
2. Reduce number of enemies in the scene
3. Simplify navigation mesh (increase cell size)
4. Disable unnecessary visual effects

## Common Errors

### "Node not found: '../AnimationPlayer'"

**Fix:** AnimationPlayer must be a sibling of RuntimeAnimationLoader, not a child of CharacterModel.

### "Animation not found: Idle"

**Fix:** Animations haven't loaded yet. Reimport assets by opening the Godot editor.

### "No Skeleton3D found!"

**Fix:** Ensure the character model is a glTF file with a skeleton, and WeaponAttachment is a child of CharacterModel.
