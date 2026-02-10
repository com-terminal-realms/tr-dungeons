# Quaternius Character Asset Guide

This document provides information about the Quaternius character assets used in TR-Dungeons.

## Asset Information

- **Source**: Quaternius (https://quaternius.com)
- **License**: CC0 (Public Domain) - Free for personal and commercial use
- **Formats**: GLTF/GLB (Godot-compatible)
- **Rig**: Humanoid rig compatible with Godot retargeting

## Downloaded Packs

### 1. Universal Base Characters
- **Location**: `assets/models/quaternius-characters/Universal Base Characters[Standard]/`
- **Contents**: 6 base character models (male/female in different proportions)
- **Used for**: Base character meshes

### 2. Modular Character Outfits - Fantasy
- **Location**: `assets/models/quaternius-characters/Modular Character Outfits - Fantasy[Standard]/`
- **Contents**: 12 fantasy outfits with 62 modular parts
- **Used for**: Player and enemy character models
- **Outfits include**: Ranger, Peasant, Knight, Mage, etc.

### 3. Universal Animation Library
- **Location**: `assets/models/quaternius-characters/Universal Animation Library[Standard]/`
- **Contents**: 120+ animations (locomotion, combat, emotes)
- **File**: `UAL1_Standard.glb`
- **Compatible with**: Godot humanoid rig retargeting

## Current Character Assignments

### Player (Human Warrior)
- **Model**: `Male_Ranger.gltf`
- **Location**: `assets/characters/outfits/Male_Ranger.gltf`
- **Description**: Armored ranger/warrior outfit
- **Textures**: 
  - `T_Ranger_BaseColor.png`
  - `T_Ranger_Normal.png`
  - `T_Ranger_ORM.png` (Occlusion/Roughness/Metallic)

### Enemies (Kobolds)
- **Model**: `Superhero_Male_FullBody.gltf`
- **Location**: `assets/characters/outfits/Superhero_Male_FullBody.gltf`
- **Description**: Athletic base body in tight suit (very different from armored player)
- **Textures**: 
  - `T_Superhero_Male_Dark.png`
  - `T_Superhero_Male_Normal.png`
  - `T_Superhero_Male_Roughness.png`
- **Note**: Using Superhero base model for maximum visual distinction from player's armored ranger

### Boss (Orc) - Future
- **Planned**: Use larger/modified character model
- **Options**: Knight outfit with dark textures, or scaled-up peasant

## Available Outfits

The Fantasy pack includes these complete outfits (in `Outfits/` folder):

1. **Male_Ranger** - Armored ranger/scout (COMPLETE - includes all body parts) ✅
   - CURRENTLY USED: Player
2. **Female_Ranger** - Female version of ranger (COMPLETE - includes all body parts) ✅
3. **Superhero_Male_FullBody** - Athletic base body in tight suit (COMPLETE) ✅
   - CURRENTLY USED: Enemies
3. **Male_Peasant** - Simple clothing (MODULAR - missing head, legs, feet) ⚠️
4. **Female_Peasant** - Female version of peasant (MODULAR - missing head, legs, feet) ⚠️

**Note**: Male_Peasant and Female_Peasant are modular outfits that only include the body/torso. They require additional modular parts (head, legs, feet) to be complete. For simplicity, we use Male_Ranger for both player and enemies since it's a complete model.

Additional outfits available in modular parts:
- Knight (heavy armor)
- Mage (robes)
- Rogue (light armor)
- Barbarian (fur/leather)
- And more...

## Using Characters in Godot

### Basic Setup

1. **Import the GLTF file** as a scene:
   ```gdscript
   [ext_resource type="PackedScene" path="res://assets/characters/outfits/Male_Ranger.gltf" id="X"]
   ```

2. **Instance in your character scene**:
   ```gdscript
   [node name="CharacterModel" parent="." instance=ExtResource("X")]
   transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
   ```

3. **Keep collision shapes** separate from visual model

### Character Dimensions

- **Height**: ~2 units (matches our capsule collision)
- **Width**: ~0.5 units radius
- **Origin**: At feet (y=0)

### Animations (Future Implementation)

The Universal Animation Library (`UAL1_Standard.glb`) contains 120+ animations that can be used with these characters. Animation setup requires manual work in the Godot editor and is not currently implemented.

Available animation categories:
- **Locomotion**: Idle, Walk, Run, Sprint, Jump, Fall, Land
- **Combat**: Melee attacks, Block, Dodge, Roll, Death
- **Interactions**: Pick up, Use item, Open door, Sit, Crouch
- **Emotes**: Wave, Point, Cheer, Dance

Animation setup will be done when needed for gameplay.

## Customization Options

### Texture Variations

Each outfit comes with 3 texture variations:
- Default (included)
- Dark variant
- Light variant

### Modular Parts

You can mix and match parts from `Modular Parts/` folder:
- Head (with/without helmet, hood)
- Body (chest armor, clothing)
- Arms (sleeves, gauntlets)
- Legs (pants, leg armor)
- Feet (boots, shoes)
- Accessories (pauldrons, belts, capes)

### Creating Custom Characters

1. Start with base character from Universal Base Characters
2. Add modular parts from Fantasy Outfits
3. Apply custom textures or color variations
4. Export as new GLTF file

## Performance Notes

- **Poly count**: Low-poly, optimized for real-time
- **Textures**: 2K resolution (can be downscaled if needed)
- **Rig**: Standard humanoid rig (efficient)
- **Animations**: Shared across all characters (memory efficient)

## Future Enhancements

- [ ] Add character customization (swap outfits)
- [ ] Create distinct boss character (scaled/modified)
- [ ] Add weapon models (swords, shields, etc.)
- [ ] Implement character color tinting for team identification
- [ ] Add particle effects for abilities

## Troubleshooting

### Character appears too small/large
- Check transform scale in scene
- Default scale should be 1:1
- Adjust collision capsule to match visual size

### Textures not loading
- Ensure .bin and .png files are in same directory as .gltf
- Check Godot import settings
- Reimport assets if needed

### Character floating/sinking
- Check Y position (should be 0 at feet)
- Verify collision shape position matches visual model
- Adjust transform if needed

## License Reminder

All Quaternius assets are CC0 (Public Domain):
- ✅ Free for personal use
- ✅ Free for commercial use
- ✅ No attribution required (but appreciated)
- ✅ Can modify and redistribute
- ✅ Can use in any project

## Additional Resources

- **Quaternius Website**: https://quaternius.com
- **Itch.io Page**: https://quaternius.itch.io
- **Animation Library Docs**: See `Godot_Setup.png` in animation folder
- **Modular System Guide**: See `Readme.txt` in Fantasy Outfits folder
