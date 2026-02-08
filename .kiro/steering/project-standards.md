# TR-Dungeons Project Standards

## Game Engine

This project uses **Godot 4.x** (NOT Unity). All references to Unity should be removed from documentation.

### Godot Installation

Godot is installed at: `/home/fishbeak/.local/bin/godot`

Verify installation:
```bash
godot --version
```

### Starting the Godot Editor

To open the game client in the Godot editor:

```bash
cd apps/game-client
godot --editor .
```

Or from the repository root:
```bash
godot --editor apps/game-client
```

### Running the Game

To run the game without opening the editor:
```bash
cd apps/game-client
godot .
```

### Running Tests

To run all tests:
```bash
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd
```

To run specific test directories:
```bash
# Unit tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

## Quick Commands

When the user asks to "start the Godot editor" or "open Godot", use:
```bash
cd organizations/com-oneredboot/organizations/com-terminal-realms/repositories/tr-dungeons/apps/game-client && godot --editor .
```

This should be run as a background process so logs can be monitored.

## Development Workflow

1. **Edit code** in VSCode or your preferred editor
2. **Godot auto-reloads** when files are saved
3. **Press F5** in Godot to run the game
4. **View logs** in the Godot output panel or terminal

## Asset Standards

- Use Synty Studios POLYGON Dungeon Realms asset pack
- All assets must be FBX format
- Import settings: 1 unit = 1 meter
- Materials must support PBR workflow

## Code Standards

- Use GDScript (not C#)
- Type hints required for all functions
- Follow orb coding standards where applicable
- Documentation comments for public methods

## Testing Standards

- Write both unit tests and property-based tests
- Property tests must run 100+ iterations
- Tag property tests with: `# Feature: tr-dungeons-game-prototype, Property N: Name`
- All tests must pass before committing

## Scene File Standards

- All scenes must be in .tscn text format (not binary)
- Scenes must be version-controllable in Git
- Use modular prefab-style scenes for reusable components
