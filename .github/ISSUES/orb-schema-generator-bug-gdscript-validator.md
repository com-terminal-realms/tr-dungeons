# Bug: GDScript configuration field not recognized by validator

## Description

The orb-schema-generator v1.3.0 validator does not recognize the `gdscript` field in the YAML configuration, even though the GDScript generator code exists and is functional.

## Evidence

1. **GDScript generator exists**: 
   - File: `orb_schema_generator/generators/gdscript_generator.py`
   - Contains complete implementation for GDScript code generation

2. **Config class has field defined**:
   - File: `orb_schema_generator/core/config.py`
   - Line: 551
   - Field: `gdscript_output: OutputConfig`

3. **Validator missing field**:
   - File: `orb_schema_generator/core/validator.py`
   - Lines: 108-200 (KNOWN_KEYS dictionary)
   - Issue: `"gdscript"` is NOT included in the `"output"` section set
   - Other languages present: `"python"`, `"typescript"`, `"dart"`, `"graphql"`

4. **Warning produced**:
   ```
   WARNING: Unknown field 'gdscript'
   ```

## Expected Behavior

The validator should recognize `gdscript` as a valid field under the `output` section, similar to `python`, `typescript`, `dart`, etc.

## Actual Behavior

When using the following configuration:

```yaml
output:
  gdscript:
    enabled: true
    targets:
      game:
        base_dir: apps/game-client/scripts
        models_subdir: models
        enums_subdir: enums
```

The validator warns: `WARNING: Unknown field 'gdscript'`

## Steps to Reproduce

1. Install orb-schema-generator v1.3.0
2. Create a `schema-generator.yml` with `gdscript:` under `output:`
3. Run `orb-schema validate-config`
4. Observe warning about unknown field

## Proposed Fix

In `orb_schema_generator/core/validator.py`, line ~112:

```python
KNOWN_KEYS: Dict[str, Set[str]] = {
    "output": {
        "python",
        "typescript",
        "dart",
        "gdscript",  # ADD THIS
        "graphql",
        "infrastructure",
        "cdk",
    },
    # ... existing keys ...
    "output.gdscript": {  # ADD THIS SECTION
        "enabled",
        "base_dir",
        "output",
        "enums_subdir",
        "models_subdir",
        "targets",
    },
    # ... rest of config ...
}
```

## Impact

- **Severity**: Low - Warning only, does not block functionality
- **User Experience**: Confusing warning message suggests configuration error when none exists
- **Workaround**: Ignore the warning (generation still works)

## Environment

- orb-schema-generator version: 1.3.0
- Python version: 3.12
- Installation: pip install from CodeArtifact

## Additional Context

The GDScript generator was added in v1.2.0 (features #86-89 per CHANGELOG), but the validator was not updated to recognize the new configuration field.
