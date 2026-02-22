# Bug: GDScript Generator Not Reading Targets Configuration in v1.3.1

## Environment

- **orb-schema-generator version**: v1.3.1
- **Installation**: `~/.orb-mcp-venv/bin/orb-schema`
- **Project**: tr-dungeons (customerId: `tr`, projectId: `dungeons`)

## Description

The GDScript generator is not reading the `targets` configuration from `schema-generator.yml` and skips generation with a warning. Python generation works perfectly with the same target structure.

## Expected Behavior

When a schema has `targets: [api, game]` and the config has:

```yaml
output:
  gdscript:
    enabled: true
    targets:
      game:
        base_dir: apps/game-client/scripts
        models_subdir: models
        enums_subdir: enums
        api_clients_subdir: backend
```

The GDScript generator should:
1. Read the `game` target from the schema
2. Find the matching `gdscript.targets.game` configuration
3. Generate GDScript files in `apps/game-client/scripts/models/`

## Actual Behavior

Generator logs:
```
WARNING - No output configuration for target game, skipping
```

No GDScript files are generated, even though:
- The schema has `targets: [api, game]`
- The config has `gdscript.targets.game` defined
- Python generation works perfectly with the same target

## Reproduction Steps

1. Create schema with `targets: [api, game]`:
```yaml
type: standard
version: '1.0'
name: CombatStats
targets:
  - api
  - game
model:
  attributes:
    id:
      type: string
      required: true
```

2. Configure both Python and GDScript for `game` target:
```yaml
output:
  python:
    enabled: true
    targets:
      game:
        base_dir: generated/python
        models_subdir: models
  gdscript:
    enabled: true
    targets:
      game:
        base_dir: apps/game-client/scripts
        models_subdir: models
```

3. Run generator:
```bash
orb-schema generate
```

4. Observe:
   - Python files generated in `generated/python/models/` ✅
   - GDScript files NOT generated, warning logged ❌

## Configuration Files

**schema-generator.yml**:
```yaml
project:
  name: tr-dungeons
  customerId: tr
  projectId: dungeons

paths:
  schemas: schemas

output:
  python:
    enabled: true
    targets:
      api:
        base_dir: apps/api
        models_subdir: models
      game:
        base_dir: generated/python
        models_subdir: models
  
  gdscript:
    enabled: true
    targets:
      game:
        base_dir: apps/game-client/scripts
        models_subdir: models
        enums_subdir: enums
        api_clients_subdir: backend
```

**schemas/models/CombatStats.yml**:
```yaml
type: standard
version: '1.0'
name: CombatStats
targets:
  - api
  - game
model:
  attributes:
    id:
      type: string
      required: true
    max_health:
      type: number
      required: true
```

## Impact

- Blocks GDScript model generation for game client
- Forces manual creation of GDScript models
- Python generation works, suggesting the issue is specific to GDScript generator

## Workaround

None currently. Manually creating GDScript models defeats the purpose of the schema generator.

## Additional Context

- Bug #92 (GDScript validator warning) was fixed in v1.3.1 ✅
- This is a NEW bug discovered after upgrading to v1.3.1
- The validator now works correctly, but the generator doesn't read targets
