# TR-Dungeons Development Process

## Problem Statement

Making one change breaks everything, leading to hours of debugging instead of development. We need a process that prevents cascading failures and maintains a stable development baseline.

## Core Principles

1. **Always maintain a known-good baseline** - Tag every working state
2. **Test before every commit** - Run the game and verify core features work
3. **Small incremental changes** - One feature at a time
4. **Clear rollback procedures** - Know how to get back to working state
5. **Stop after 3 failed attempts** - Revert and rethink approach

## Git Workflow

### Branch Strategy

- **main**: Always working, always deployable
- **feature/\***: New features, merge when complete and tested
- **experiment/\***: Risky changes, may be abandoned
- **hotfix/\***: Critical bug fixes

### Tagging Strategy

Tag every working milestone with descriptive names:

```bash
# Format: v<major>.<minor>.<patch>-<feature-name>
git tag -a "v0.3.1-baseline" -m "Baseline: Last known working state"
git tag -a "v0.4.0-transparent-walls" -m "Feature: Transparent wall occlusion system"
```

### Current Baseline

**v0.3.1-baseline** (same as v0.3.0-cone-combat-camera-relative)
- RMB click to move (ground or enemy)
- RMB drag to rotate camera (5-pixel threshold)
- Mouse wheel zoom (8.0 to 25.0 units)
- Arrow key camera controls
- LMB cone attacks (90° angle, 3.0 range, multi-target)
- Character auto-rotation to face enemies
- All 7 property tests passing
- Game displays correctly

## Development Workflow

### Before Starting Work

1. **Ensure you're on a working baseline**
   ```bash
   git checkout main
   git pull
   # Test the game - verify it works
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **For risky changes, use experiment branch**
   ```bash
   git checkout -b experiment/risky-idea
   ```

### During Development

1. **Make small, incremental changes**
   - Change one thing at a time
   - Test after each change
   - Commit when it works

2. **Test before every commit**
   - Run the smoke test checklist (see below)
   - All tests must pass
   - No console errors (warnings OK)

3. **Commit with descriptive messages**
   ```bash
   git add .
   git commit -m "feat: add transparent wall occlusion system"
   ```

### Smoke Test Checklist

Run this checklist before EVERY commit:

- [ ] Game starts without errors
- [ ] Can see game world (not grey screen)
- [ ] Player character visible
- [ ] Camera positioned correctly
- [ ] Can move with RMB click
- [ ] Can rotate camera with RMB drag
- [ ] Can attack with LMB
- [ ] Health bar displays
- [ ] No console errors (warnings OK)

### When Things Break

#### The 3-Attempt Rule

If you can't fix an issue after 3 attempts:

1. **STOP** - Don't keep trying
2. **REVERT** - Go back to last working tag
3. **RETHINK** - Consider a different approach

```bash
# Revert to last working state
git checkout main
git reset --hard v0.3.1-baseline

# Or if on a feature branch
git checkout feature/my-feature
git reset --hard main
```

#### Red Flags to Stop and Revert

- Camera script not executing (no _ready() logs)
- Grey screen with no visible game world
- Player character not visible
- Movement controls not responding
- More than 3 failed fix attempts
- Debugging taking longer than 30 minutes

### Completing a Feature

1. **Verify all tests pass**
   ```bash
   cd apps/game-client
   godot --headless --script addons/gut/gut_cmdln.gd
   ```

2. **Run full smoke test**
   - Complete the checklist above
   - Test all core features
   - Verify no regressions

3. **Merge to main**
   ```bash
   git checkout main
   git merge feature/my-feature
   ```

4. **Tag the milestone**
   ```bash
   git tag -a "v0.4.0-my-feature" -m "Feature: Description of what works"
   git push origin main --tags
   ```

### Abandoning Experiments

If an experiment doesn't work out:

```bash
# Switch back to main
git checkout main

# Delete the experiment branch
git branch -D experiment/failed-idea

# No need to merge or tag
```

## Testing Requirements

### Before Commit

- Run smoke test checklist
- Verify core features work
- Check for console errors

### Before Merge to Main

- All unit tests pass
- All property tests pass (100+ iterations)
- Full smoke test completed
- No known regressions

### Property Test Standards

- Minimum 100 iterations per test
- Tag with feature name: `# Feature: tr-dungeons-game-prototype, Property N: Name`
- Test must validate correctness properties, not just examples

## Documentation Requirements

### Always Update

When you make changes, update relevant documentation:

- **Control changes**: Update `apps/game-client/docs/CONTROL_SCHEME.md`
- **Architecture changes**: Update relevant design docs
- **New features**: Update feature spec files
- **Workarounds**: Document in appropriate files (e.g., CHARACTER_ORIENTATION_FIX.md)

### Documentation Files

- `.kiro/steering/project-standards.md` - Project-wide standards
- `.kiro/steering/development-process.md` - This file
- `apps/game-client/docs/CONTROL_SCHEME.md` - Authoritative control reference
- `.kiro/specs/*/requirements.md` - Feature requirements
- `.kiro/specs/*/design.md` - Feature designs
- `.kiro/specs/*/tasks.md` - Implementation tasks

## Common Mistakes to Avoid

1. ❌ **Don't commit broken code to main** - Use feature branches
2. ❌ **Don't skip testing** - Always run smoke test before commit
3. ❌ **Don't make multiple changes at once** - One feature at a time
4. ❌ **Don't keep debugging after 3 attempts** - Revert and rethink
5. ❌ **Don't forget to tag working states** - Tag every milestone
6. ❌ **Don't forget to update documentation** - Keep docs in sync with code

## Success Criteria

A successful development session:

- ✅ Started from a working baseline
- ✅ Made small, incremental changes
- ✅ Tested after each change
- ✅ All tests passing
- ✅ Documentation updated
- ✅ New working state tagged
- ✅ No regressions introduced

## Emergency Procedures

### Game Won't Start

```bash
# Return to last known working state
git checkout main
git reset --hard v0.3.1-baseline
```

### Tests Failing

```bash
# Check what changed
git diff main

# If too many changes, revert
git checkout main
git reset --hard v0.3.1-baseline
```

### Lost Work

```bash
# Find your commits
git reflog

# Recover if needed
git checkout <commit-hash>
git checkout -b recovery/my-work
```

## Process Review

Review this process after every major milestone:

- What worked well?
- What caused problems?
- How can we improve?
- Update this document with lessons learned

## Version History

- **v1.0** (2026-02-12): Initial process established after grey screen debugging session
  - Established 3-attempt rule
  - Created smoke test checklist
  - Defined branch strategy
  - Set baseline at v0.3.1-baseline
