# Terminal Realms: Dungeons - Development Context

## Project Overview

Terminal Realms: Dungeons is an isometric 3D dungeon crawler built with GoDot 4.x, featuring data-driven content generation from MajorMUD database, modular Synty asset integration, and property-based testing for correctness.

**Purpose**: Modernize classic BBS-era MajorMUD gameplay with contemporary graphics and cloud infrastructure while preserving the original game's depth and content.

**Tech Stack**:
- **Frontend**: GoDot 4.6+ (GDScript)
- **Backend**: Python/FastAPI on AWS Lambda
- **Database**: PostgreSQL (MajorMUD data)
- **Infrastructure**: AWS CDK
- **Testing**: Gut (GoDot) + pytest (Python)

## Key Directories

### `apps/game-client/` - GoDot Game Client
The playable game built in GoDot 4.x.

**Key subdirectories**:
- `scenes/` - GoDot scene files (.tscn format, text-based for version control)
- `scripts/models/` - Data models (future orb-schema-generator GDScript output)
- `scripts/components/` - Reusable game components (Health, Movement, Combat, AI)
- `assets/` - 3D models, textures, audio (Synty Studios assets)
- `tests/` - Gut test suite (unit, integration, property tests)

**Important**: GoDot project root is `apps/game-client/`, not repository root.

### `apps/api/` - Backend API
Python/FastAPI backend for game server logic.

**Key subdirectories**:
- `models/` - Generated Pydantic models (orb-schema-generator output)
- `lambda_functions/` - AWS Lambda handlers
- `graphql/` - Generated GraphQL schemas

### `infrastructure/` - AWS Infrastructure
CDK stacks for deploying backend services.

**Key subdirectories**:
- `cdk/stacks/` - Stack definitions
- `tests/` - Infrastructure tests (unit, integration, property)

### `schemas/` - Data Model Definitions
YAML schemas for orb-schema-generator.

**Generates**:
- Python models → `apps/api/models/`
- GDScript models → `apps/game-client/scripts/models/` (future)
- GraphQL schemas → `apps/api/graphql/`
- CDK constructs → `infrastructure/cdk/generated/`

### `.kiro/specs/` - Feature Specifications
Kiro spec-driven development workflow.

**Structure**:
- `requirements.md` - User stories, acceptance criteria (EARS patterns)
- `design.md` - Architecture, correctness properties
- `tasks.md` - Implementation tasks with property-based testing

## Local Development Setup

### Prerequisites
- GoDot 4.2+ (tested with 4.6)
- Python 3.11+
- AWS CLI (for backend development)
- Synty Studios POLYGON Dungeon Realms asset pack (optional for prototype)

### Game Client Setup
```bash
cd apps/game-client
godot --editor .  # Opens GoDot Editor
```

### Backend Setup
```bash
cd apps/api
pipenv install --dev
pipenv run pytest
```

### Infrastructure Setup
```bash
cd infrastructure/cdk
pipenv install --dev
pipenv run pytest
```

## Testing Approach

### Dual Testing Strategy
- **Unit Tests**: Specific examples, edge cases, error conditions
- **Property Tests**: Universal properties across all inputs (100+ iterations)

### Game Client Tests (Gut)
```bash
cd apps/game-client

# All tests
godot --headless --script addons/gut/gut_cmdln.gd

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

### Backend Tests (pytest)
```bash
cd apps/api
pipenv run pytest
pipenv run pytest --cov=. --cov-report=html
```

### Property-Based Testing
Example property test (GDScript):
```gdscript
# Property: Health bounds invariant
func test_health_bounds_invariant() -> void:
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

## Deployment Process

### Game Client
- Manual distribution (itch.io, Steam, etc.)
- Export from GoDot Editor
- Platform-specific builds (Windows, Linux, macOS)

### Backend API
```bash
cd infrastructure/cdk
pipenv run cdk deploy --all --profile terminal-realms
```

### Database Migrations
```bash
cd apps/api
pipenv run alembic upgrade head
```

## Architecture Patterns

### Component-Based Design
Entities (Player, Enemy) composed of reusable components:
- **Health**: HP management, damage, healing, death
- **Movement**: WASD input, velocity, rotation
- **Combat**: Attack logic, cooldowns, range checking
- **EnemyAI**: Detection, pathfinding, state machine

### Data Model Separation
Data models separated from game logic for orb-schema-generator compatibility:

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
45° overhead camera with smooth following:
```gdscript
var angle_rad = deg_to_rad(45.0)
var offset = Vector3(
    distance * cos(angle_rad) * 0.707,
    distance * sin(angle_rad),
    distance * cos(angle_rad) * 0.707
)
camera_pos = player_pos + offset
```

## Context Inheritance

This project inherits context from:
- **Parent Organization**: [com-terminal-realms](../../CLAUDE.md)
- **Root Governance**: [tpf-master-plan](../../../../../CLAUDE.md)
- **Architectural Controls**: [docs/architectural-controls.md](../../../../../docs/architectural-controls.md)

## orb Ecosystem Integration

### orb-schema-generator
- **Status**: Awaiting GDScript support (GitHub issues #86-89)
- **Current**: Python models generated for backend
- **Future**: GDScript models for game client

### orb-templates
- **Standards**: Property-based testing, spec-driven development
- **MCP Server**: Configured in `.kiro/settings/mcp.json`
- **Project Structure**: Nx-style with `apps/` for deployable applications

### orb-infrastructure
- **CDK Stacks**: Shared infrastructure patterns
- **GitHub Actions**: CI/CD workflows
- **CodeArtifact**: Package publishing

## Common Tasks

### Add New Game Component
1. Create spec in `.kiro/specs/component-name/`
2. Create data model in `apps/game-client/scripts/models/`
3. Create component in `apps/game-client/scripts/components/`
4. Write property tests in `apps/game-client/tests/property/`
5. Write unit tests in `apps/game-client/tests/unit/`
6. Create scene in `apps/game-client/scenes/`

### Generate Models from Schemas
```bash
# From repository root
orb-schema generate --config schema-generator.yml
```

### Run All Tests
```bash
# Game client
cd apps/game-client && godot --headless --script addons/gut/gut_cmdln.gd

# Backend
cd apps/api && pipenv run pytest

# Infrastructure
cd infrastructure/cdk && pipenv run pytest
```

### Deploy to AWS
```bash
cd infrastructure/cdk
pipenv run cdk deploy --all --profile terminal-realms
```

## Important Notes

- **GoDot Project Root**: `apps/game-client/`, not repository root
- **Text-Based Scenes**: All .tscn files are text format for version control
- **Data Model Isolation**: Models in `scripts/models/` ready for orb-schema-generator
- **Property Testing**: All correctness properties must have property tests
- **Spec-Driven**: All features require spec (requirements, design, tasks)

## Support and Resources

- **Repository**: https://github.com/com-terminal-realms/tr-dungeons
- **Organization**: https://github.com/com-terminal-realms
- **orb-templates**: https://github.com/com-oneredboot/orb-templates
- **GoDot Docs**: https://docs.godotengine.org/en/stable/
- **Synty Assets**: https://syntystore.com/

## License

Copyright © 2024 Terminal Realms
