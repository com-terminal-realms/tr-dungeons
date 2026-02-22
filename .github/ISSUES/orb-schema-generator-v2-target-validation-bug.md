# Bug: v2.0 Target Validation Incorrectly Validates Cross-Generator Targets

## Environment

- **orb-schema-generator version**: v2.0.1
- **Installation**: `~/.orb-mcp-venv/bin/orb-schema`
- **Project**: tr-dungeons (customerId: `tr`, projectId: `dungeons`)

## Description

In v2.0.1, the target validation logic incorrectly validates targets across generators. When a schema references a `gdscript` target, the validator checks if it exists in the **Python** configuration and fails, even though `gdscript` is a separate generator with its own target configuration.

## Expected Behavior

When a schema has:
```yaml
targets:
  - api
  - python
  - gdscript
```

And the config has:
```yaml
output:
  code:
    python:
      targets:
        api:
          base_dir: apps/api
        python:
          base_dir: generated/python
    gdscript:
      targets:
        gdscript:
          base_dir: apps/game-client/scripts
```

The validator should:
1. Check that `api` exists in Python targets ✅
2. Check that `python` exists in Python targets ✅
3. Check that `gdscript` exists in GDScript targets ✅
4. Allow generation to proceed

## Actual Behavior

The validator fails with:
```
Target validation errors:
  ERROR: Target 'gdscript' referenced in schemas (Ability, CombatStats, EnemyType, LootTable) not found in python configuration. Valid targets: ['api', 'python']
✗ Target validation has errors
```

The validator is checking if `gdscript` exists in the **Python** configuration, which is incorrect. It should check the **GDScript** configuration.

## Root Cause

The target validation logic appears to validate all targets against a single generator's configuration, rather than checking each target against its corresponding generator.

## Impact

- **Blocks multi-language generation** - Cannot generate both Python and GDScript models from the same schema
- **Forces workarounds** - Users must either:
  - Remove GDScript targets from schemas (defeats the purpose)
  - Skip validation (unsafe)
  - Maintain separate schema files per language (duplication)

## Reproduction Steps

1. Create a schema with multiple language targets:
```yaml
type: standard
version: '1.0'
name: CombatStats
targets:
  - api
  - python
  - gdscript
model:
  attributes:
    id:
      type: string
      required: true
```

2. Configure multiple generators in v2.0 format:
```yaml
output:
  code:
    python:
      targets:
        api:
          base_dir: apps/api
        python:
          base_dir: generated/python
    gdscript:
      targets:
        gdscript:
          base_dir: apps/game-client/scripts
```

3. Run validation:
```bash
orb-schema validate-config
```

4. Observe error about `gdscript` not found in Python configuration

## Expected Fix

The target validation should:
1. Parse the target name to determine which generator it belongs to
2. Check that target exists in the **correct generator's** configuration
3. Support cross-generator target references in schemas

For example:
- Target `api` → Check in `python.targets`
- Target `python` → Check in `python.targets`
- Target `gdscript` → Check in `gdscript.targets`
- Target `typescript` → Check in `typescript.targets`

## Workaround

None currently. The validation blocks generation entirely.

## Additional Context

- This is a **regression in v2.0** - v1.3.x allowed cross-generator targets
- Issue #93 fixed GDScript target resolution in v1.3.2
- Issue #94 requested language-specific target names (which v2.0 now requires due to unique target constraint)
- The unique target constraint in v2.0 is good, but the validation logic needs to be updated to support it

## Related Issues

- #93 - GDScript generator target resolution (fixed in v1.3.2)
- #94 - Language-specific target names (enhancement request)
