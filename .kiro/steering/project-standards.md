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

### Kenney Dungeon Assets

- Using Kenney's free dungeon asset pack (CC0 license)
- Assets are in GLB format, located in `assets/models/kenney-dungeon/`
- Assets are modular pieces designed to be combined

#### Asset Positioning Notes

- Kenney assets have their geometry positioned relative to origin in specific ways
- Floor tiles: The floor surface is typically at y=0 or slightly below
- When using floor tiles, position at y=0 and scale up (e.g., 10x in X/Z) to cover room areas
- Hide placeholder collision meshes with `visible = false` while keeping collision shapes
- Some assets like `template-floor-big.glb` include multiple elements (floor + pillar)

#### Recommended Floor Assets

- `template-floor-detail.glb` - Detailed floor tile with good visual quality
- `template-floor.glb` - Plain floor tile
- `template-floor-layer.glb` - Layered floor variation
- Complete rooms: `room-small.glb`, `room-wide.glb`, `room-large.glb` (include walls)

#### Wall Assets

- `template-wall.glb` - Standard wall segment
- `template-wall-corner.glb` - Corner wall piece
- `template-wall-half.glb` - Half-height wall

### Legacy Asset Standards

- Synty Studios POLYGON Dungeon Realms asset pack (if used)
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

## Control Scheme Rules

**CRITICAL**: The control scheme is documented in `apps/game-client/docs/CONTROL_SCHEME.md` and must not be changed without updating that file.

### Movement Controls

- **RMB click ONLY** for all character movement
- **NO WASD MOVEMENT** - WASD keys are completely removed from movement
- WASD keys are reserved for future combat abilities
- Never re-implement WASD movement without explicit user approval

### Camera Controls

- **RMB hold + drag**: Rotate camera around player (5-pixel threshold)
- **Mouse wheel**: Zoom in/out (8.0 to 25.0 units)
- **Arrow keys**: Alternative camera controls (left/right rotate, up/down zoom)

### Combat Controls

- **LMB**: Cone attack (90° angle, 3.0 range, multi-target)
- **H key**: Heal (20 HP)

### Before Changing Controls

1. Read `apps/game-client/docs/CONTROL_SCHEME.md`
2. Understand the design rationale
3. Get user approval for changes
4. Update documentation after changes
5. Test all controls before committing
