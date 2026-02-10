# Asset Import Guide

## Critical: Asset Import Process

**IMPORTANT**: Godot requires all assets to be imported through the editor before they can be used at runtime. This creates `.import` files and cached versions in `.godot/imported/`.

## When Assets Need Reimporting

Assets need to be reimported when:
1. The `.godot/imported/` directory is cleared or deleted
2. New assets are added to the project
3. After a git reset or checkout that changes asset files
4. After cloning the repository fresh

## How to Import Assets

### Step 1: Open the Godot Editor
```bash
cd apps/game-client
godot --editor .
```

### Step 2: Wait for Import to Complete
- The editor will automatically scan and import all assets
- Wait 15-20 seconds for all assets to import
- You'll see import progress in the editor's output panel
- Look for messages like "Importing: [asset_name]"

### Step 3: Close the Editor
Once import is complete, close the editor.

### Step 4: Run the Game
```bash
cd apps/game-client
godot .
```

## What Gets Imported

The following assets require import:
- **Character Models**: `assets/characters/outfits/*.gltf`
- **Animations**: `assets/characters/animations/UAL1_Standard.glb`
- **Dungeon Assets**: `assets/models/kenney-dungeon/*.glb`
- **Weapons**: `assets/models/quaternius-weapons/*.obj`
- **Textures**: All `.png` files

## Troubleshooting

### Problem: "Failed loading resource" errors
**Cause**: Assets haven't been imported yet.
**Solution**: Open the editor to trigger import.

### Problem: Characters/dungeon not visible
**Cause**: glTF/GLB files not imported.
**Solution**: Open the editor, wait for import, then run game.

### Problem: Animations not working
**Cause**: UAL1_Standard.glb not imported.
**Solution**: Open the editor to import animation file.

## DO NOT Commit

Never commit the `.godot/imported/` directory to git. It's in `.gitignore` and should stay there. Each developer needs to import assets locally.

## Quick Recovery After Git Reset

If you do a `git reset --hard` or checkout:
1. Clear the import cache: `rm -rf apps/game-client/.godot/imported/*`
2. Open editor: `godot --editor apps/game-client`
3. Wait 15-20 seconds
4. Close editor
5. Run game: `godot apps/game-client`

This ensures all assets are freshly imported and match the current code state.
