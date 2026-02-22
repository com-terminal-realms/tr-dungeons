# Enhancement: Support Language-Specific Target Names

## Current Behavior

Currently, targets are language-agnostic identifiers (e.g., `api`, `game`, `web`) that are shared across all language generators:

```yaml
# Schema
targets:
  - api
  - game

# Config
output:
  python:
    targets:
      api: {...}
      game: {...}
  gdscript:
    targets:
      game: {...}
```

This works but can be confusing when:
- Multiple languages use the same target name
- Target names don't clearly indicate which language they're for
- Developers need to cross-reference config to understand which language a target uses

## Proposed Enhancement

Support language-specific target names that make the configuration more explicit and self-documenting:

```yaml
# Schema
targets:
  - python
  - gdscript

# Config
output:
  python:
    targets:
      python:
        base_dir: apps/api
        models_subdir: models
  
  gdscript:
    targets:
      gdscript:
        base_dir: apps/game-client/scripts
        models_subdir: models
```

## Benefits

1. **Clarity**: Target names immediately indicate which language they're for
2. **Self-documenting**: No need to cross-reference config to understand targets
3. **Consistency**: Target name matches the language generator
4. **Simplicity**: One target per language in most cases

## Use Cases

### Single-Language Projects
```yaml
targets:
  - python

output:
  python:
    targets:
      python:
        base_dir: src
```

### Multi-Language Projects
```yaml
targets:
  - python
  - gdscript
  - typescript

output:
  python:
    targets:
      python:
        base_dir: apps/api
  
  gdscript:
    targets:
      gdscript:
        base_dir: apps/game-client/scripts
  
  typescript:
    targets:
      typescript:
        base_dir: apps/web/src
```

### Multiple Targets Per Language (Advanced)
```yaml
targets:
  - python-api
  - python-lambda
  - gdscript

output:
  python:
    targets:
      python-api:
        base_dir: apps/api
      python-lambda:
        base_dir: infrastructure/lambdas
  
  gdscript:
    targets:
      gdscript:
        base_dir: apps/game-client/scripts
```

## Backward Compatibility

This should be additive - continue supporting generic target names like `api`, `game`, `web` for backward compatibility, but also support language-specific names like `python`, `gdscript`, `typescript`.

## Implementation Suggestion

When resolving targets, check both:
1. Language-specific target name (e.g., `gdscript`)
2. Generic target name (e.g., `game`)

This allows gradual migration and supports both styles.

## Related Issues

This enhancement would make the configuration more intuitive and reduce confusion about which language a target uses.
