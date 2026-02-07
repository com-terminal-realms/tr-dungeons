# TR-Dungeons Context Summary

## Project Vision

Modernize MajorMUD (classic BBS dungeon crawler) as a **data-driven, automated 3D game** with:
- **Visual Style**: V Rising aesthetic (3D top-down/isometric camera, dark fantasy)
- **Tech Stack**: GoDot 4 (not Unity) + PostgreSQL + AWS infrastructure
- **Automation Focus**: Pipeline-driven content generation from MajorMUD database
- **Gameplay**: Real-time PvX combat, story-driven exploration

## Key Decisions from Claude.ai Chat

### 1. Engine Choice: GoDot 4 (Final Decision)
**Why GoDot over Unity:**
- Native Linux support (first-class)
- Text-based scene files (.tscn) - can be generated programmatically
- CLI automation support
- Free and open source
- Lighter weight, faster iteration
- **Critical**: Automation-first workflow (Unity requires GUI editing)

### 2. Visual Quality: Synty Studios Assets
**Asset Strategy:**
- Synty Studios modular dungeon packs (FBX format, engine-agnostic)
- Low-poly stylized look (like V Rising)
- Modular pieces snap together like LEGO
- Fast dungeon assembly
- **Key Pack**: "POLYGON Dungeon Realms"

**Other Asset Sources:**
- Sketchfab (free/CC0 models)
- Quaternius (free low-poly)
- itch.io (indie packs)
- Humble Bundle game dev bundles

### 3. Data-Driven Pipeline Architecture

```
MajorMUD Btrieve Database
         ↓
Extract (Nightmare/MMUD Explorer tools)
         ↓
PostgreSQL Database
  - rooms (id, name, description, exits, type, level_range)
  - monsters (id, name, stats, drops, spawn_rooms)
  - items (id, name, stats, type, rarity)
  - npcs (id, name, dialogue, quests)
  - quests (id, steps, rewards)
         ↓
Python Generator Script
  - Maps room types → GoDot tile prefabs
  - Maps monsters → 3D enemy models
  - Maps items → 3D props/pickups
  - Generates .tscn scene files programmatically
         ↓
GoDot Project (Synty assets pre-configured)
         ↓
Playable Game
```

### 4. What Gets Automated

| Component | Automated? | Notes |
|-----------|-----------|-------|
| Dungeon layouts | ✅ Yes | From room connection data |
| Enemy placement | ✅ Yes | From spawn data |
| Loot tables | ✅ Yes | From drop data |
| NPC dialogue | ✅ Yes | From dialogue trees |
| Quest triggers | ✅ Yes | From quest data |
| Room descriptions | ✅ Yes | UI text generation |
| 3D scene files | ✅ Yes | Programmatic .tscn generation |

### 5. What's Manual (One-Time Setup)

- Purchase and import Synty modular asset pack into GoDot
- Configure materials and textures
- Create mapping table (room_type "cave" → specific tile pieces)
- Define modular asset dimensions and snap points
- Core gameplay scripts (movement, combat, inventory)
- GoDot post-processing setup (lighting, fog, bloom)

### 6. Property-Based Testing for Asset Consistency

**Critical**: Modular assets must maintain consistent dimensions for proper snapping.

**Properties to Test:**
- **Tile Size Consistency**: All floor tiles are exactly the same dimensions
- **Wall Height Uniformity**: All wall pieces have identical height
- **Snap Point Alignment**: Connection points align perfectly across all pieces
- **Collision Box Consistency**: Collision shapes match visual boundaries
- **Door Frame Compatibility**: All door pieces fit all wall pieces
- **Corner Piece Symmetry**: Corner pieces work in all 4 rotations
- **Stair Dimensions**: Stairs connect properly to floor tiles at different elevations

**Test Implementation:**
```python
# Property: All floor tiles have identical dimensions
@given(floor_tiles=st.lists(st.sampled_from(FLOOR_TILE_ASSETS), min_size=2))
def test_floor_tile_dimensions_consistent(floor_tiles):
    dimensions = [get_tile_dimensions(tile) for tile in floor_tiles]
    assert all(d == dimensions[0] for d in dimensions), \
        "All floor tiles must have identical dimensions for proper snapping"

# Property: Wall pieces snap to floor tile edges
@given(wall=st.sampled_from(WALL_ASSETS), floor=st.sampled_from(FLOOR_TILE_ASSETS))
def test_wall_snaps_to_floor_edge(wall, floor):
    wall_width = get_asset_width(wall)
    floor_edge_length = get_tile_edge_length(floor)
    assert wall_width == floor_edge_length, \
        f"Wall width {wall_width} must match floor edge {floor_edge_length}"
```

## Technical Stack

### Backend
- **Database**: PostgreSQL (MajorMUD data)
- **API**: AWS Lambda + API Gateway (or AppSync for GraphQL)
- **Infrastructure**: AWS CDK (Python)
- **Schema Management**: orb-schema-generator (needs GDScript support)

### Frontend
- **Engine**: GoDot 4.x
- **Language**: GDScript (primary) + C# (optional)
- **Assets**: Synty Studios FBX models
- **Camera**: Fixed overhead (V Rising style)

### DevOps
- **Version Control**: GitHub
- **CI/CD**: GitHub Actions
- **Containers**: Docker for game server
- **Orchestration**: Kubernetes (if scaling needed)

## GoDot Visual Quality Setup

### 1. Post-Processing (WorldEnvironment node)
- Glow/bloom on light sources
- SSAO (ambient occlusion)
- Volumetric fog
- Tone mapping (darker/moodier)
- Color correction
- Vignette

### 2. Lighting
- SDFGI (global illumination)
- Directional light (main)
- Omni lights (torches, magic)
- Baked lightmaps (performance)

### 3. Materials
- PBR materials with normal maps
- Roughness/metallic textures
- Proper UV mapping

## orb-schema-generator Enhancement Needs

### Missing: GDScript Code Generation

**Required Features:**
1. **Data Models** - GDScript classes from YAML schemas
2. **API Client** - Type-safe HTTP request wrappers
3. **Validation** - Field validation logic
4. **Serialization** - to_dict/from_dict methods
5. **GoDot Integration** - Resource classes, signals, @export

**Example Output Needed:**
```gdscript
class_name User
extends Resource

@export var user_id: String
@export var email: String
@export var first_name: String
@export var last_name: String

func _init(data: Dictionary = {}):
    if data.has("userId"):
        user_id = data["userId"]
    # ... etc

func to_dict() -> Dictionary:
    return {
        "userId": user_id,
        "email": email,
        # ... etc
    }

static func from_dict(data: Dictionary) -> User:
    return User.new(data)
```

## MajorMUD Data Extraction

### Tools Available
- **Nightmare Redux** - MajorMUD database editor
- **MMUD Explorer** - Database viewer
- **MBBSEmu** - Emulator that can run MajorMUD

### Data to Extract
- **Rooms**: ~hundreds of designed rooms with connections
- **Monsters**: Stats, behaviors, loot drops
- **Items**: Weapons, armor, consumables, quest items
- **Spells**: Effects, costs, requirements
- **NPCs**: Dialogue trees, quest givers
- **Quests**: Steps, rewards, prerequisites

### Legal Considerations
- MajorMUD is proprietary (not open source)
- Development ended 2008 (Metropolis shutdown)
- Using game data requires legal review
- Consider fair use, abandoned software doctrine
- Consult IP lawyer before launch

## Prototype Status

### Completed (Unity - needs GoDot port)
- Player controller (WASD movement, click-to-attack)
- Enemy AI (patrol, chase, attack)
- Camera controller (overhead)
- Health system
- Combat system
- Dungeon room generator
- Enemy spawner
- Game manager

### Next Steps
1. **Port to GoDot** - Recreate Unity scripts in GDScript
2. **Import Synty Assets** - Set up modular dungeon kit
3. **Setup Post-Processing** - Lighting, fog, bloom
4. **Database Schema** - Design PostgreSQL schema for MajorMUD data
5. **Generator Script** - Python script to create .tscn files
6. **Extract MajorMUD Data** - Use Nightmare/MMUD Explorer

## Development Workflow

### Environment
- **Primary Dev**: Windows (GoDot editor)
- **Automation**: Linux (Python scripts, database)
- **Version Control**: Git + GitHub
- **Editor**: VSCode with GDScript extension

### Iteration Loop
1. Edit GDScript in VSCode
2. Save → GoDot auto-reloads
3. Press Play to test
4. Commit when working
5. Run generator script to update scenes from database

## Success Criteria

### Phase 1: Prototype
- Single dungeon room playable
- Player movement and combat working
- One enemy type functional
- Basic lighting and post-processing
- Synty assets integrated

### Phase 2: Data Pipeline
- PostgreSQL schema complete
- MajorMUD data extracted
- Generator script creates scenes
- 10+ rooms auto-generated
- Multiple enemy types

### Phase 3: Alpha
- 50+ rooms playable
- Full combat system
- Inventory and equipment
- Quest system
- Multiplayer foundation

### Phase 4: Beta
- All MajorMUD content ported
- Multiplayer functional
- Performance optimized
- Ready for testing

## Questions to Answer

1. **Database Choice**: PostgreSQL or DynamoDB?
   - PostgreSQL: Better for complex queries, relational data
   - DynamoDB: Better for scale, lower cost

2. **Multiplayer Architecture**: How many concurrent players?
   - Affects infrastructure sizing
   - Determines Lambda concurrency limits

3. **MajorMUD Fork**: Which specific version to use?
   - Need to identify the fork/version
   - Affects data extraction approach

4. **Legal Strategy**: How to handle IP concerns?
   - Fair use argument?
   - License from rights holder?
   - Clean room implementation?

## Resources

### Documentation
- [GoDot 4 Docs](https://docs.godotengine.org/en/stable/)
- [Synty Studios](https://syntystore.com/)
- [MBBSEmu](https://github.com/mbbsemu/MBBSEmu)
- [orb-schema-generator](https://github.com/com-oneredboot/orb-schema-generator)

### Community
- MajorMUD: mudinfo.net
- GoDot: godotengine.org/community
- Reddit: r/godot, r/gamedev

### Tools
- Nightmare Redux (MajorMUD editor)
- MMUD Explorer (database viewer)
- Blender (3D modeling if needed)
- GIMP (texture editing)

