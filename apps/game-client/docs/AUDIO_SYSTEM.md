# Audio System Documentation

## Overview

The game has a complete audio system with background music, boss battle music, and monster alert sounds.

## Audio Files

Located in `assets/audio/`:

- **door_open.ogg** - Door opening sound effect
- **door_close.ogg** - Door closing sound effect

Located in `assets/audio/music/`:

- **dungeon_ambient.ogg** - Background music (loops continuously)
- **boss_battle.ogg** - Boss battle music (loops during boss fights)
- **monster_alert.ogg** - Alert sound when enemies detect player (plays once)

## How It Works

### Background Music

- Starts automatically when the game loads
- Plays continuously in a loop
- Volume: -10dB (slightly quieter than other sounds)
- Managed by: `scenes/main.gd`

### Monster Alert Sound

- Plays when an enemy first detects the player
- Triggered by: `scripts/components/enemy_ai.gd`
- Only plays once per detection (when transitioning from IDLE to CHASE state)
- Does NOT loop
- Plays on top of background music (doesn't stop it)

### Boss Battle Music

- Plays when player gets within 15 units of a boss enemy
- Stops background music while playing
- Loops continuously during boss fight
- Stops when boss is defeated
- Resumes background music after boss is defeated
- Managed by: `scenes/enemies/enemy_base.gd` (when `is_boss = true`)

## Creating a Boss Enemy

To create a boss enemy that triggers boss music:

1. Create an enemy instance in your scene
2. Set the `is_boss` property to `true` in the Inspector
3. The boss will automatically:
   - Start boss music when player gets within 15 units
   - Stop boss music when defeated
   - Resume background music after death

Example boss stats (from ENEMY_TYPES.md):
- Scale: 2.0 (2x normal size)
- Health: 200 HP
- Damage: 15
- Attack Range: 2.0 units
- Detection Range: 15.0 units

## Testing Audio

### Keyboard Shortcuts (for testing)

Press these keys while playing to test audio:

- **B** - Toggle boss battle music on/off
- **M** - Play monster alert sound
- **N** - Toggle background music on/off

### In-Game Triggers

- **Background Music**: Plays automatically on game start
- **Monster Alert**: Walk near any enemy (within 10 units)
- **Boss Music**: Walk near a boss enemy (within 15 units)

## Technical Details

### Audio Players

All audio is managed by `AudioStreamPlayer` nodes created in `scenes/main.gd`:

- `background_music` - AudioStreamPlayer for ambient music
- `boss_music` - AudioStreamPlayer for boss battle music
- `alert_sound` - AudioStreamPlayer for monster alerts

### Door Audio

Door sounds use `AudioStreamPlayer3D` for 3D spatial audio:
- Max distance: 20 units
- Attenuation: Inverse distance
- Managed by: `scripts/door.gd`

### Audio Format

All audio files are in OGG Vorbis format (.ogg) for:
- Good compression
- Looping support
- Godot compatibility

## Adding New Audio

To add new audio files:

1. Place .ogg file in `assets/audio/` or `assets/audio/music/`
2. Open Godot editor (files will be auto-imported)
3. Load in script: `load("res://assets/audio/your_file.ogg")`
4. Create AudioStreamPlayer and set stream
5. Call `.play()` to play the sound

## Future Enhancements

Potential improvements:

- Volume controls in settings menu
- Music crossfading between tracks
- More enemy alert sound variations
- Victory music when boss is defeated
- Ambient sound effects (dripping water, wind, etc.)
- Footstep sounds for player and enemies
