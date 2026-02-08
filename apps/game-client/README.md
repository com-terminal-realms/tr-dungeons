# Terminal Realms: Dungeons - Game Client

GoDot 4.x game client for Terminal Realms: Dungeons.

## Quick Start

```bash
# Open in GoDot Editor
godot --editor .

# Run game
godot .

# Run tests
godot --headless --script addons/gut/gut_cmdln.gd
```

## Controls

- **WASD** - Move character
- **Mouse** - Aim/target
- **Left Click** - Attack
- **Mouse Wheel** - Zoom camera

## Structure

See [main README](../../README.md) for full project structure.

## Development

### Adding New Components

1. Create data model in `scripts/models/` (future orb-schema-generator output)
2. Create component in `scripts/components/`
3. Write property tests in `tests/property/`
4. Write unit tests in `tests/unit/`
5. Create scene in `scenes/`

### Testing

```bash
# All tests
godot --headless --script addons/gut/gut_cmdln.gd

# Unit tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

## Assets

### Kenney Dungeon Assets

Currently using Kenney's free dungeon asset pack (CC0 license):
- Location: `assets/models/kenney-dungeon/`
- Format: GLB files
- License: CC0 (public domain)

#### Working with Kenney Assets

**Floor Tiles:**
- Use `template-floor-detail.glb` for detailed floors
- Scale 10x in X/Z to cover 20x20 room areas
- Position at y=0 for proper visibility
- Hide placeholder meshes: set `visible = false` on MeshInstance3D (keep CollisionShape3D)

**Wall Pieces:**
- `template-wall.glb` - Standard wall segment
- `template-wall-corner.glb` - Corner pieces
- Scale and position to match room dimensions

**Complete Rooms:**
- `room-small.glb`, `room-wide.glb`, `room-large.glb` include walls + floors
- Use for quick room prototyping

#### Asset Preview

Open `scenes/rooms/dungeon_showcase.tscn` to preview different Kenney assets side-by-side.

### Legacy: Synty Studios Assets

If using Synty Studios POLYGON Dungeon Realms:
- Place in `assets/models/` after import
- See [asset import guide](../../docs/asset-import.md) for details
