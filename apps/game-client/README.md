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

Place Synty Studios assets in `assets/models/` after import.

See [asset import guide](../../docs/asset-import.md) for details.
