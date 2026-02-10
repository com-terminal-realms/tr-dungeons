# Audio Download Guide

This guide provides links to download free, CC0-licensed audio files for the TR-Dungeons game.

## Required Audio Files

### 1. Door Sounds

**Door Opening Sound:**
- Visit: https://pixabay.com/sound-effects/search/door%20open/
- Recommended: "wooden-door-opening" or "heavy-door-open"
- Download as: `door_open.ogg`
- Save to: `apps/game-client/assets/audio/door_open.ogg`

**Door Closing Sound:**
- Visit: https://pixabay.com/sound-effects/search/door%20close/
- Recommended: "wooden-door-closing" or "heavy-door-close"
- Download as: `door_close.ogg`
- Save to: `apps/game-client/assets/audio/door_close.ogg`

### 2. Background Music (Ambient)

**Scary Dungeon Ambient:**
- Visit: https://pixabay.com/music/ambient-horror-ambience-background-256022/
- Title: "Horror Ambience Background"
- Download as: `dungeon_ambient.ogg`
- Save to: `apps/game-client/assets/audio/music/dungeon_ambient.ogg`

Alternative options:
- https://pixabay.com/music/ambient-dark-horror-suspense-263069/
- https://pixabay.com/music/ambient-horror-background-atmosphere-13-246915/

### 3. Boss Battle Music

**Epic Boss Battle:**
- Visit: https://pixabay.com/music/main-title-battle-epic-162477/
- Title: "Battle Epic"
- Download as: `boss_battle.ogg`
- Save to: `apps/game-client/assets/audio/music/boss_battle.ogg`

Alternative options:
- Search: https://pixabay.com/music/search/epic%20battle%20music/
- Look for intense, orchestral tracks with high energy

### 4. Monster Alert/Chase Music

**Monster Alert:**
- Visit: https://pixabay.com/music/search/horror%20chase/
- Recommended: Tracks with "chase", "pursuit", or "tension" in the title
- Download as: `monster_alert.ogg`
- Save to: `apps/game-client/assets/audio/music/monster_alert.ogg`

Alternative search terms:
- "horror tension"
- "suspense chase"
- "dark pursuit"

## Download Instructions

1. **Visit Pixabay** (all links above are from Pixabay - CC0 license, no attribution required)

2. **Click the download button** on each audio page

3. **Convert to OGG format** if needed:
   - Pixabay provides MP3 files
   - Use FFmpeg to convert: `ffmpeg -i input.mp3 output.ogg`
   - Or use online converter: https://convertio.co/mp3-ogg/

4. **Place files in correct directories:**
   ```
   apps/game-client/assets/audio/
   ├── door_open.ogg
   ├── door_close.ogg
   └── music/
       ├── dungeon_ambient.ogg
       ├── boss_battle.ogg
       └── monster_alert.ogg
   ```

5. **Verify files in Godot:**
   - Open Godot editor
   - Navigate to FileSystem panel
   - Check that all audio files appear
   - Double-click to preview audio

## License Information

All audio from Pixabay is released under the Pixabay Content License:
- Free for commercial and non-commercial use
- No attribution required
- CC0 equivalent (public domain)

## Quick Download Commands

If you have `wget` or `curl`, you can download directly (replace URLs with actual file URLs from Pixabay):

```bash
# Create directories
mkdir -p apps/game-client/assets/audio/music

# Download door sounds (example - replace with actual URLs)
# wget -O apps/game-client/assets/audio/door_open.mp3 "PIXABAY_URL_HERE"
# wget -O apps/game-client/assets/audio/door_close.mp3 "PIXABAY_URL_HERE"

# Download music (example - replace with actual URLs)
# wget -O apps/game-client/assets/audio/music/dungeon_ambient.mp3 "PIXABAY_URL_HERE"
# wget -O apps/game-client/assets/audio/music/boss_battle.mp3 "PIXABAY_URL_HERE"
# wget -O apps/game-client/assets/audio/music/monster_alert.mp3 "PIXABAY_URL_HERE"

# Convert MP3 to OGG (requires ffmpeg)
# for file in apps/game-client/assets/audio/*.mp3; do
#     ffmpeg -i "$file" "${file%.mp3}.ogg"
#     rm "$file"
# done
# for file in apps/game-client/assets/audio/music/*.mp3; do
#     ffmpeg -i "$file" "${file%.mp3}.ogg"
#     rm "$file"
# done
```

## Testing Audio

After downloading, test the audio in-game:
1. Run the game: `cd apps/game-client && godot .`
2. Approach a door and press E to open/close
3. Listen for door sound effects
4. Background music should play automatically (when implemented)

## Notes

- OGG Vorbis format is recommended for Godot (better compression than WAV, open-source)
- Keep file sizes reasonable (< 5MB for sound effects, < 10MB for music)
- Test audio volume levels in-game and adjust if needed
- Consider adding volume controls in game settings (future enhancement)
