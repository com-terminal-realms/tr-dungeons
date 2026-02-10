# Character Floor Positioning Fix

## Problem

All characters (player, enemies, boss) were floating above or sinking into the floor because their origin points are at different heights relative to their feet.

## Root Cause

Different character models have their origin (pivot point) at different locations:
- **Player**: Origin is 1.004 units ABOVE the feet (feet are below origin)
- **Enemies**: Origin is 0.0095 units ABOVE the feet (almost at feet level)

When we positioned characters at y=0 (floor level), we were placing their ORIGIN at floor level, not their FEET.

## Solution: Automated Character Measurement System

We created an automated system to measure character models and store their floor offsets, similar to how we measure dungeon assets.

### New Components

1. **CharacterMetadata** (`scripts/utils/character_metadata.gd`)
   - Stores floor_offset, character_height, bounding_box, collision data
   - Similar to AssetMetadata but for characters

2. **CharacterMetadataDatabase** (`scripts/utils/character_metadata_database.gd`)
   - Manages collection of character measurements
   - Saves/loads from `data/character_metadata.json`

3. **Automated Measurement Script** (`scripts/utils/measure_all_characters.gd`)
   - Measures all character scenes automatically
   - Calculates floor offset by finding lowest mesh point
   - Generates `character_metadata.json`

### Measurement Results

From `data/character_metadata.json`:
```json
{
  "player": {
    "floor_offset": 1.0040,
    "character_height": 2.3796,
    "scene_path": "res://scenes/player/player.tscn"
  },
  "enemy": {
    "floor_offset": 0.0095,
    "character_height": 2.8095,
    "scene_path": "res://scenes/enemies/enemy_base.tscn"
  }
}
```

### Character Positions in main.tscn

Characters are now positioned at floor_height + floor_offset:

```gdscript
# Floor is at y=0, so:
Player: y = 0 + 1.004 = 1.004
Enemies: y = 0 + 0.01 = 0.01  (rounded from 0.0095)
```

## Workflow Integration

### When Adding New Characters

1. Add character scene path to `measure_all_characters.gd`
2. Run measurement script:
   ```bash
   cd apps/game-client
   godot --headless --script scripts/utils/measure_all_characters.gd
   ```
3. Commit updated `character_metadata.json`
4. Use floor_offset when positioning characters in scenes

### Validation

Run validation to check all characters are at correct floor height:
```bash
cd apps/game-client
godot --headless --script scripts/utils/validate_character_positions.gd
```

The validation script now automatically loads character metadata and uses the correct floor offsets.

## Benefits

1. **Automatic**: No manual measurement needed
2. **Consistent**: All characters use same measurement system
3. **Validated**: Validation script ensures correct positioning
4. **Version Controlled**: Measurements stored in JSON, tracked in git
5. **Scalable**: Easy to add new character types

## Comparison to Manual Approach

### Before (Manual)
- Hardcoded floor offsets in validation script
- Had to visually inspect and guess offsets
- Easy to make mistakes when adding new characters
- No documentation of measurements

### After (Automated)
- Measurements stored in database
- Automatic calculation from mesh geometry
- Validation uses database automatically
- Clear documentation and workflow

## Related Files

- `apps/game-client/scripts/utils/character_metadata.gd` - Character metadata class
- `apps/game-client/scripts/utils/character_metadata_database.gd` - Database class
- `apps/game-client/scripts/utils/measure_all_characters.gd` - Measurement script
- `apps/game-client/scripts/utils/validate_character_positions.gd` - Validation script (updated)
- `apps/game-client/data/character_metadata.json` - Measurement database
- `apps/game-client/scenes/main.tscn` - Character positions (updated)

## Future Improvements

1. **Automatic scene updates**: Script to update all character Y positions in scenes
2. **Editor integration**: Godot plugin to show floor offset in inspector
3. **Animation offsets**: Measure floor offset for different animations
4. **Collision shapes**: Auto-generate collision shapes from measurements
