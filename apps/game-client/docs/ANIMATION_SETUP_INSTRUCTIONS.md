# Animation Setup Instructions - CRITICAL ISSUE FOUND

## The Problem

The AnimationPlayer is at the wrong level in the scene tree. The UAL animations target a Skeleton3D node that's inside the Male_Ranger model, but the AnimationPlayer can't reach it from the Player root.

## Solution: Move AnimationPlayer Inside CharacterModel

You need to do this in the Godot editor:

### 1. Open Godot Editor

```bash
cd apps/game-client
godot --editor .
```

### 2. Open Player Scene

Navigate to: `scenes/player/player.tscn`

### 3. Restructure the Scene Tree

Current structure (WRONG):
```
Player (CharacterBody3D)
├── CharacterModel (Male_Ranger instance)
│   └── Skeleton3D (inside here somewhere)
├── AnimationPlayer ← Can't reach Skeleton3D!
└── ...
```

You need to make it:
```
Player (CharacterBody3D)
├── CharacterModel (Male_Ranger instance)
│   ├── Skeleton3D
│   └── AnimationPlayer ← Move it here!
└── ...
```

### 4. Steps to Move AnimationPlayer

1. In the Scene tree, **right-click** on `AnimationPlayer`
2. Select **"Reparent"** or **"Change Parent"**
3. Select `CharacterModel` as the new parent
4. Click OK

OR:

1. **Drag** the `AnimationPlayer` node
2. **Drop** it onto the `CharacterModel` node

### 5. Import Animations

Now with AnimationPlayer inside CharacterModel:

1. Select the `AnimationPlayer` node
2. Click **Animation** panel at bottom
3. Click **Animation** dropdown → **Manage Animations**
4. Click **Load**
5. Navigate to: `assets/characters/animations/UAL1_Standard.glb`
6. Select and **Open**
7. All animations should now import successfully!

### 6. Update the Player Script

The player script needs to find the AnimationPlayer at the new location.

Change this line in `scenes/player/player.gd`:

```gdscript
# OLD (wrong path):
_animation_player = $AnimationPlayer

# NEW (correct path):
_animation_player = $CharacterModel/AnimationPlayer
```

### 7. Test

1. Save the scene (Ctrl+S)
2. Press F5 to run
3. Character should now animate when moving!

## Why This Happens

Skeletal animations need to target a Skeleton3D node. The UAL animations have bone tracks like:
- `Skeleton3D:Hips`
- `Skeleton3D:Spine`
- etc.

If the AnimationPlayer isn't in the same subtree as the Skeleton3D, it can't find these bones and the animations won't work.

## Alternative: Animation Root Path

Instead of moving the AnimationPlayer, you could set its `root_node` property to point to CharacterModel, but moving it is simpler and more reliable.


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
