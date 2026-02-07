# Terminal Realms: Dungeons

An isometric 3D dungeon crawler built with GoDot 4.x, featuring data-driven content generation from MajorMUD database, modular Synty asset integration, and property-based testing for correctness.

## Features

- **Isometric 3D Graphics**: V Rising-style camera with 45° overhead view
- **Component-Based Architecture**: Reusable Health, Movement, Combat, and AI components
- **Data-Driven Content**: PostgreSQL-backed dungeon generation from MajorMUD data
- **Modular Assets**: Synty Studios POLYGON Dungeon Realms integration
- **Property-Based Testing**: Comprehensive correctness guarantees with Gut + Hypothesis-style tests
- **Schema-Driven Models**: Future orb-schema-generator GDScript support

## Quick Start

### Prerequisites

- GoDot 4.2+ (tested with 4.6)
- Git for version control
- Synty Studios POLYGON Dungeon Realms asset pack (optional for prototype)

### Installation

```bash
# Clone the repository
git clone https://github.com/com-terminal-realms/tr-dungeons.git
cd tr-dungeons

# Open game client in GoDot
cd apps/game-client
godot --editor .
```

### Running the Prototype

1. Open project in GoDot Editor
2. Press F5 or click "Run Project"
3. Controls:
   - **WASD** - Move character
   - **Mouse** - Aim/target
   - **Left Click** - Attack
   - **Mouse Wheel** - Zoom camera

### Running Tests

```bash
# Run all game client tests
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd

# Run specific test suite
godot --headless --script addons/gut/gut_cmdln.gd -gtest=tests/unit/test_health.gd
```

## Project Structure

Following orb-templates Nx-style conventions with `apps/` for deployable applications:

```
tr-dungeons/
├── apps/                      # All deployable applications
│   ├── game-client/          # GoDot game client
│   │   ├── project.godot    # GoDot project configuration
│   │   ├── scenes/          # GoDot scene files (.tscn)
│   │   │   ├── main.tscn   # Main game scene
│   │   │   ├── player/     # Player character scenes
│   │   │   ├── enemies/    # Enemy scenes
│   │   │   ├── rooms/      # Dungeon room scenes
│   │   │   └── ui/         # UI scenes
│   │   ├── scripts/        # GDScript source code
│   │   │   ├── models/     # Data models (future orb-schema-generator output)
│   │   │   ├── components/ # Reusable game components
│   │   │   ├── camera/     # Camera systems
│   │   │   └── utils/      # Utility scripts
│   │   ├── assets/         # Game assets
│   │   │   ├── models/     # 3D models (Synty FBX imports)
│   │   │   ├── textures/   # Textures and materials
│   │   │   ├── materials/  # GoDot materials
│   │   │   └── audio/      # Sound effects and music
│   │   ├── tests/          # Game client tests
│   │   │   ├── unit/       # Unit tests
│   │   │   ├── integration/# Integration tests
│   │   │   ├── property/   # Property-based tests
│   │   │   └── test_utils/ # Test utilities
│   │   └── addons/         # GoDot plugins
│   │       └── gut/        # Gut testing framework
│   └── api/                 # Backend API (Python/FastAPI)
│       ├── models/          # Generated models (orb-schema-generator)
│       ├── enums/           # Generated enums
│       ├── graphql/         # Generated GraphQL schemas
│       └── lambda_functions/# AWS Lambda handlers
├── packages/                 # Publishable shared libraries (future)
│   └── game-data-models/    # Shared data models
├── infrastructure/           # AWS infrastructure
│   ├── cdk/                 # CDK constructs and stacks
│   │   ├── stacks/         # Stack definitions
│   │   └── generated/      # Generated CDK constructs
│   └── tests/              # Infrastructure tests
│       ├── unit/           # Unit tests for CDK constructs
│       ├── integration/    # Integration tests
│       └── property/       # Property-based tests
├── schemas/                  # YAML schemas (orb-schema-generator input)
│   ├── models/              # Standard data models
│   ├── tables/              # DynamoDB tables
│   └── core/                # Shared enums and types
├── docs/                     # Project documentation
├── .kiro/                    # Kiro IDE configuration
│   ├── specs/               # Feature specifications
│   ├── settings/            # Kiro settings
│   │   └── mcp.json        # MCP server configuration
│   └── steering/            # AI assistant guidance
├── .gitignore               # Git ignore rules
└── README.md                # This file
```

## Architecture

### Component-Based Design

Entities (Player, Enemy) are composed of reusable components:

- **Health**: Manages HP, damage, healing, death
- **Movement**: Handles WASD input, velocity, rotation
- **Combat**: Attack logic, cooldowns, range checking
- **EnemyAI**: Detection, pathfinding, state machine

### Data Model Separation

Data models (scripts/models/) are separated from game logic to enable future orb-schema-generator integration:

```gdscript
# Data model (future orb-schema-generator output)
class_name HealthData
extends Resource
# Serialization, validation, no game logic

# Component (hand-written game logic)
class_name Health
extends Node
# Uses HealthData, emits signals, game behavior
```

### Isometric Camera System

45° overhead camera with smooth following and zoom:

```gdscript
# Camera position calculation
var angle_rad = deg_to_rad(45.0)
var offset = Vector3(
    distance * cos(angle_rad) * 0.707,
    distance * sin(angle_rad),
    distance * cos(angle_rad) * 0.707
)
camera_pos = player_pos + offset
```

## Testing Strategy

### Dual Testing Approach

- **Unit Tests**: Specific examples, edge cases, error conditions
- **Property Tests**: Universal properties across all inputs (100+ iterations)

### Property-Based Testing

Example property test:

```gdscript
# Property: Health bounds invariant
func test_health_bounds_invariant() -> void:
    var health = Health.new()
    add_child(health)
    
    assert_property("Health stays in [0, max_health]", func(seed):
        var rng = RandomNumberGenerator.new()
        rng.seed = seed
        
        # Generate random damage/heal sequence
        for i in range(10):
            if random_bool(rng):
                health.take_damage(random_int(rng, 0, 50))
            else:
                health.heal(random_int(rng, 0, 50))
        
        var current = health.get_current_health()
        var max_hp = health.get_max_health()
        
        return {
            "success": current >= 0 and current <= max_hp,
            "input": "random damage/heal sequence",
            "reason": "Health %d not in [0, %d]" % [current, max_hp]
        }
    )
```

### Running Tests

```bash
# All tests
godot --headless --script addons/gut/gut_cmdln.gd

# Unit tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property

# With coverage (requires GUT coverage plugin)
godot --headless --script addons/gut/gut_cmdln.gd -gcoverage
```

## Schema-Driven Development (Future)

Once orb-schema-generator supports GDScript (#86-89), data models will be generated from YAML schemas:

```yaml
# schemas/models/HealthData.yml
type: standard
name: HealthData
attributes:
  max_health:
    type: integer
    required: true
    minimum: 1
  current_health:
    type: integer
    required: true
    minimum: 0
```

Generated output:
```gdscript
# scripts/models/health_data.gd (auto-generated)
class_name HealthData
extends Resource
# ... serialization, validation, etc.
```

## Development Workflow

### Feature Development

1. Create spec in `.kiro/specs/feature-name/`
   - requirements.md (user stories, acceptance criteria)
   - design.md (architecture, correctness properties)
   - tasks.md (implementation tasks)

2. Implement components with tests
   - Write property tests for correctness properties
   - Write unit tests for edge cases
   - Implement component logic

3. Integrate into game
   - Create scenes using components
   - Wire up signals and references
   - Test end-to-end gameplay

### Testing Workflow

```bash
# 1. Write property test
# tests/property/test_health_properties.gd

# 2. Run test (should fail initially)
godot --headless --script addons/gut/gut_cmdln.gd -gtest=tests/property/test_health_properties.gd

# 3. Implement component
# scripts/components/health.gd

# 4. Run test (should pass)
godot --headless --script addons/gut/gut_cmdln.gd -gtest=tests/property/test_health_properties.gd

# 5. Run all tests
godot --headless --script addons/gut/gut_cmdln.gd
```

## Integration with orb Ecosystem

### orb-schema-generator

Future integration for GDScript model generation:
- GitHub Issues: #86 (code gen), #87 (API client), #88 (validation), #89 (docs)
- Models in `scripts/models/` will be generated from `schemas/`
- Components in `scripts/components/` remain hand-written

### orb-templates

Follows orb standards where applicable:
- Property-based testing methodology
- Spec-driven development workflow
- Component-based architecture
- Separation of data models and logic

### orb-infrastructure

Future AWS backend integration:
- CDK stacks in `infrastructure/cdk/`
- Lambda functions for game server
- RDS PostgreSQL for MajorMUD data
- API Gateway for client-server communication

## Requirements

- **GoDot**: 4.2+ (tested with 4.6)
- **Assets**: Synty Studios POLYGON Dungeon Realms (optional for prototype)
- **Testing**: Gut testing framework (included in addons/)

## License

Copyright © 2024 Terminal Realms

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/com-terminal-realms/tr-dungeons).
