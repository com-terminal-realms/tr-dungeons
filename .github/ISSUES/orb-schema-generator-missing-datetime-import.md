# Bug: Generated Python Models Missing datetime Import

## Environment

- **orb-schema-generator version**: v2.0.2 (also affects v1.3.0, v1.3.1)
- **Installation**: `~/.orb-mcp-venv/bin/orb-schema`
- **Project**: tr-dungeons (customerId: `tr`, projectId: `dungeons`)

## Description

When schemas define fields with `type: datetime`, the Python generator creates type annotations using `datetime` but does not add `from datetime import datetime` to the imports section. This causes F821 "Undefined name `datetime`" errors in linters (Ruff, Flake8, mypy).

## Expected Behavior

When a schema has datetime fields:
```yaml
model:
  attributes:
    created_at:
      type: datetime
      required: true
      description: Timestamp when created
```

The generated Python model should include:
```python
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field
```

## Actual Behavior

Generated file is missing the datetime import:
```python
# Missing: from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

class Ability(BaseModel):
    created_at: datetime = Field(...)  # ❌ datetime not imported
```

## Impact

- **Linting errors**: Ruff/Flake8 report F821 undefined name errors
- **Type checking failures**: mypy cannot resolve datetime type
- **Pre-commit hooks fail**: Blocks commits when linters are configured
- **CI/CD failures**: Automated checks fail on generated code

## Reproduction

1. Create schema with datetime field:

```yaml
# schemas/models/Example.yml
type: standard
version: '1.0'
name: Example
targets:
  - api
model:
  attributes:
    id:
      type: string
      required: true
    created_at:
      type: datetime
      required: true
```

2. Run generator:
```bash
orb-schema generate
```

3. Check generated file - datetime import is missing
4. Run linter:
```bash
ruff check apps/api/models/ExampleModel.py
```

5. Observe F821 error: `Undefined name 'datetime'`

## Affected Files

All generated Python model files with datetime fields:
- `apps/api/models/AbilityModel.py`
- `apps/api/models/CombatEventModel.py`
- `apps/api/models/CombatStatsModel.py`
- `apps/api/models/EnemyTypeModel.py`
- `apps/api/models/LootTableModel.py`
- `apps/api/models/PlayerSessionModel.py`
- `apps/api/models/RoomStateModel.py`
- `generated/python/models/*.py` (all with datetime)

## Root Cause

The Python generator template does not check for datetime field types and conditionally add the datetime import.

## Expected Fix

The generator should:
1. Scan all model attributes for `type: datetime`
2. If any datetime fields exist, add `from datetime import datetime` to imports
3. Place it before other imports (after comments, before typing imports)

## Workaround

Manually add `from datetime import datetime` to each generated file (not recommended as files are auto-generated).

## Versions Affected

- v2.0.2 (confirmed)
- v1.3.1 (confirmed via git history)
- v1.3.0 (confirmed via git history)
- Likely all versions with Python generator

## Additional Context

This bug has existed since at least v1.3.0 and affects all projects using datetime fields in schemas.
