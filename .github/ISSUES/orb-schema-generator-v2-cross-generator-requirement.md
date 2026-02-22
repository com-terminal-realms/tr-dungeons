# Bug: v2.0.2 Requires All Targets to Exist in All Enabled Generators

## Environment

- **orb-schema-generator version**: v2.0.2
- **Installation**: `~/.orb-mcp-venv/bin/orb-schema`
- **Project**: tr-dungeons (customerId: `tr`, projectId: `dungeons`)

## Description

In v2.0.2, when a schema references a target (e.g., `client`), ALL enabled code generators must have that target configured, even if the target is only intended for one specific language. This prevents language-specific target usage and forces unnecessary duplicate configurations.

## Expected Behavior

When a schema has:
```yaml
targets:
  - api
  - client
```

And the config has:
```yaml
output:
  code:
    python:
      targets:
        api:
          base_dir: apps/api
    gdscript:
      targets:
        client:
          base_dir: apps/game-client/scripts
```

The generator should:
1. Generate Python models for `api` target only
2. Generate GDScript models for `client` target only
3. Each generator processes only the targets it has configured

## Actual Behavior

The generator fails with:
```
Generation failed: No Python output config for target 'client'. Add it to output.code.python.targets in schema-generator.yml
```

Even though `client` is only intended for GDScript, the Python generator requires it to be configured.

## Root Cause

v2.0.2 validates that every target referenced in schemas must exist in EVERY enabled generator's configuration. This prevents language-specific targets.

## Impact

- **Blocks language-specific targets** - Cannot have GDScript-only or Python-only targets
- **Forces duplicate configurations** - Must configure unused targets in all generators
- **Creates unnecessary files** - Generates Python files for GDScript-only models
- **Confusing for users** - Target names don't clearly indicate which language they're for

## Workaround

Add dummy target configurations to all generators:
```yaml
output:
  code:
    python:
      targets:
        api:
          base_dir: apps/api
        client:
          base_dir: generated/python/client  # Unused, but required
    gdscript:
      targets:
        client:
          base_dir: apps/game-client/scripts
```

This generates unnecessary Python files that won't be used.

## Reproduction Steps

1. Create a schema with a GDScript-only target:
```yaml
type: standard
version: '1.0'
name: CombatStats
targets:
  - api
  - client
model:
  attributes:
    id:
      type: string
      required: true
```

2. Configure only GDScript for `client` target:
```yaml
output:
  code:
    python:
      targets:
        api:
          base_dir: apps/api
    gdscript:
      targets:
        client:
          base_dir: apps/game-client/scripts
```

3. Run generator:
```bash
orb-schema generate
```

4. Observe error requiring Python to have `client` target

## Expected Fix

The generator should:
1. Allow targets to be generator-specific
2. Only validate that a target exists in the generator that will process it
3. Skip targets that aren't configured for a specific generator

For example:
- Schema has `targets: [api, client]`
- Python generator processes `api` target only (skips `client`)
- GDScript generator processes `client` target only (skips `api`)

## Use Case

This is essential for multi-language projects where:
- Python models go to the API backend (`api` target)
- GDScript models go to the game client (`client` target)
- Some models are shared (both targets)
- Some models are language-specific (one target only)

## Related Issues

- #97 - v2.0 target validation incorrectly validates cross-generator targets (closed, but related)
- #94 - Language-specific target names (closed as won't implement)

## Additional Context

v2.0.2 fixed the duplicate target name issue from #97, but introduced a new requirement that all targets must exist in all generators. This is overly restrictive and prevents common multi-language use cases.
