# TR-Dungeons Project Standards

## Game Engine

This project uses **Godot 4.x** (NOT Unity). All references to Unity should be removed from documentation.

### Godot Installation

Godot is installed at: `/home/fishbeak/.local/bin/godot`

Verify installation:
```bash
godot --version
```

### Starting the Godot Editor

To open the game client in the Godot editor:

```bash
cd apps/game-client
godot --editor .
```

Or from the repository root:
```bash
godot --editor apps/game-client
```

### Running the Game

To run the game without opening the editor:
```bash
cd apps/game-client
godot .
```

### Running Tests

To run all tests:
```bash
cd apps/game-client
godot --headless --script addons/gut/gut_cmdln.gd
```

To run specific test directories:
```bash
# Unit tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Property tests only
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/property
```

## Quick Commands

When the user asks to "start the Godot editor" or "open Godot", use:
```bash
cd organizations/com-oneredboot/organizations/com-terminal-realms/repositories/tr-dungeons/apps/game-client && godot --editor .
```

This should be run as a background process so logs can be monitored.

## Development Workflow

1. **Edit code** in VSCode or your preferred editor
2. **Godot auto-reloads** when files are saved
3. **Press F5** in Godot to run the game
4. **View logs** in the Godot output panel or terminal

## Commit Standards

**CRITICAL: Never commit code with errors.**

### Pre-Commit Requirements

Before every commit:
1. **All errors must be fixed** - No `ERROR:` or `SCRIPT ERROR:` in logs
2. **Warnings are acceptable** - But should be minimized
3. **Game must start** - No crashes during initialization
4. **Pre-commit hook must pass** - Automatically enforced

### Pre-Commit Hook

A git pre-commit hook automatically runs the game and checks for errors:
- Runs game in headless mode for 5 seconds
- Scans logs for `ERROR:` or `SCRIPT ERROR:`
- **Blocks commit if errors found**
- Allows commit if only warnings present

**NEVER use `git commit --no-verify` without explicit user approval.**

Using `--no-verify` bypasses the pre-commit hook and allows broken code to be committed. This defeats the purpose of the safety check and can lead to cascading failures.

**Only use `--no-verify` when:**
- Explicitly approved by user for a specific reason
- Committing documentation-only changes that can't affect game code
- Emergency situations where the hook itself is broken

### If Pre-Commit Hook Blocks Your Commit

1. **Read the error log** - Check `/tmp/godot-precommit.log`
2. **Fix the errors** - Don't try to bypass the hook
3. **Test the fix** - Run the game manually to verify
4. **Commit again** - The hook will re-check

### Installing the Pre-Commit Hook

The hook is located at `.git/hooks/pre-commit` and is automatically active. If it's missing, reinstall it:

```bash
# The hook should already exist, but if needed:
chmod +x .git/hooks/pre-commit
```

## Fix Approval Process

**CRITICAL: Never attempt to fix issues without user approval of the fix plan first.**

When encountering bugs, errors, or issues:

1. **STOP** - Do not attempt to fix immediately
2. **ANALYZE** - Understand the problem and root cause
3. **PROPOSE** - Create a detailed fix plan including:
   - What is broken and why
   - Proposed solution approach
   - Files that will be modified
   - Potential risks or side effects
   - Testing strategy to verify the fix
4. **WAIT** - Get explicit user approval before proceeding
5. **EXECUTE** - Only after approval, implement the fix
6. **VERIFY** - Test and confirm the fix works

This process prevents cascading failures and ensures we maintain control over changes.

## Reset to Working Baseline Process

**When the game is non-functional (errors, grey screen, crashes):**

1. **STOP** - Stop the game if running
2. **IDENTIFY** - Find the last working tag (format: `v*.*.*-working-baseline`)
3. **PROPOSE** - Present reset plan to user:
   - Which tag to reset to
   - What commits will be lost
   - What needs to be re-applied after reset
4. **WAIT** - Get explicit user approval
5. **RESET** - Execute: `git reset --hard <tag-name>`
6. **START** - Start the game for user to test
7. **CONFIRM** - User confirms game is working
8. **TAG** - Create new semver tag with `-working-baseline` suffix:
   ```bash
   git tag -a "v0.X.X-working-baseline" -m "Baseline: <description>"
   git push --tags
   ```

**Tag Naming Convention:**
- Format: `v<major>.<minor>.<patch>-working-baseline`
- Increment patch for fixes, minor for features, major for breaking changes
- Always include `-working-baseline` suffix for baseline tags
- Example: `v0.3.4-working-baseline`

## Asset Standards

### Kenney Dungeon Assets

- Using Kenney's free dungeon asset pack (CC0 license)
- Assets are in GLB format, located in `assets/models/kenney-dungeon/`
- Assets are modular pieces designed to be combined

#### Asset Positioning Notes

- Kenney assets have their geometry positioned relative to origin in specific ways
- Floor tiles: The floor surface is typically at y=0 or slightly below
- When using floor tiles, position at y=0 and scale up (e.g., 10x in X/Z) to cover room areas
- Hide placeholder collision meshes with `visible = false` while keeping collision shapes
- Some assets like `template-floor-big.glb` include multiple elements (floor + pillar)

#### Recommended Floor Assets

- `template-floor-detail.glb` - Detailed floor tile with good visual quality
- `template-floor.glb` - Plain floor tile
- `template-floor-layer.glb` - Layered floor variation
- Complete rooms: `room-small.glb`, `room-wide.glb`, `room-large.glb` (include walls)

#### Wall Assets

- `template-wall.glb` - Standard wall segment
- `template-wall-corner.glb` - Corner wall piece
- `template-wall-half.glb` - Half-height wall

### Legacy Asset Standards

- Synty Studios POLYGON Dungeon Realms asset pack (if used)
- All assets must be FBX format
- Import settings: 1 unit = 1 meter
- Materials must support PBR workflow

## Code Standards

- Use GDScript (not C#)
- Type hints required for all functions
- Follow orb coding standards where applicable
- Documentation comments for public methods

## Testing Standards

- Write both unit tests and property-based tests
- Property tests must run 100+ iterations
- Tag property tests with: `# Feature: tr-dungeons-game-prototype, Property N: Name`
- All tests must pass before committing

## Scene File Standards

- All scenes must be in .tscn text format (not binary)
- Scenes must be version-controllable in Git
- Use modular prefab-style scenes for reusable components
