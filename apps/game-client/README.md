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
- **Right Click** - Move to location
- **Left Click** - Attack nearest enemy
- **H** - Heal (20 HP)
- **Mouse Wheel** - Zoom camera in/out

## Features

- **Character Models**: Quaternius character models with animations (Ranger for player, Peasant for enemies)
- **Weapon System**: Sword attachment with proper scaling and rotation
- **Auto-Facing**: Character automatically rotates to face enemies when attacking
- **Animation System**: Runtime animation loading with Idle, Walk, and Sword_Attack animations
- **Dungeon Environment**: Kenney dungeon assets with rooms and corridors

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

# Single property test (recommended to avoid log noise)
# Usage: ./run_single_test.sh <test_file> <test_method_without_test_prefix>
./run_single_test.sh test_door_placement_properties.gd property_27_connection_point_calculation_integration
```

## Assets

### Kenney Dungeon Assets

Currently using Kenney's free dungeon asset pack (CC0 license):
- Location: `assets/models/kenney-dungeon/`
- Format: GLB files
- License: CC0 (public domain)
- Documentation: See `docs/kenney-dungeon-asset-guide.md` for detailed dimensions and usage

### Quaternius Character Assets

Using Quaternius character packs (CC0 license):
- **Base Characters**: Universal Base Characters pack
- **Outfits**: Modular Character Outfits - Fantasy pack
- **Animations**: Universal Animation Library (120+ animations)
- Location: `assets/characters/`
- Documentation: See `docs/quaternius-character-guide.md` for details

### Quaternius Weapon Assets

Using Quaternius Medieval Weapons pack (CC0 license):
- Location: `assets/models/quaternius-weapons/`
- Current weapon: Sword.obj
- Scale: 0.25, Rotation: (-90, 0, 225), Offset: (0, 0.1, 0)
- Documentation: See `docs/kenney-dungeon-asset-guide.md` weapon section

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
