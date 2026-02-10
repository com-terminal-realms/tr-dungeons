# Asset Validation Workflow

## Quick Reference

This document provides a quick reference for the asset validation workflow established during POC validation.

## Commands

### 1. Measure Assets
```bash
cd apps/game-client
godot --headless --script scripts/utils/measure_poc_assets.gd
```

**Output**:
- `data/asset_metadata.json`
- `docs/assets/*.md` (documentation files)

### 2. Validate Layout
```bash
cd apps/game-client
godot --headless --script scripts/utils/validate_poc_layout.gd
```

**Expected Output** (success):
```
✓ All connections are valid!
  No gaps or overlaps detected.
```

### 3. Calculate Fixes (if needed)
```bash
cd apps/game-client
godot --headless --script scripts/utils/fix_poc_layout.gd
```

**Output**: Corrected position values for `main.tscn`

## Workflow Diagram

```
┌─────────────────────┐
│  Add/Change Asset   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Measure Asset     │ ◄── Always do this first!
│  (measure_poc_      │
│   assets.gd)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Calculate          │
│  Positions          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Update main.tscn   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Validate Layout    │ ◄── Critical step!
│  (validate_poc_     │
│   layout.gd)        │
└──────────┬──────────┘
           │
           ├─── ✓ Valid ───────┐
           │                   │
           └─── ✗ Invalid      │
                  │            │
                  ▼            │
           ┌─────────────┐     │
           │  Run Fix    │     │
           │  Calculator │     │
           └──────┬──────┘     │
                  │            │
                  └────────────┤
                               │
                               ▼
                        ┌─────────────┐
                        │  Test Game  │
                        └─────────────┘
```

## Validation Criteria

| Check | Tolerance | Status |
|-------|-----------|--------|
| Connection alignment | ±0.1 units | ✅ Pass |
| Gap detection | > 0.1 units | ❌ Fail |
| Overlap detection | > 0.1 units | ❌ Fail |

## POC Results

### Before Validation
- ❌ 2 connection errors
- ❌ 1-unit gap (Room4 → Corridor4to5)
- ❌ 3-unit overlap (Corridor4to5 → Room5)

### After Validation
- ✅ 8/8 connections valid
- ✅ 0 gaps detected
- ✅ 0 overlaps detected
- ✅ All within ±0.1 unit tolerance

## Key Measurements

| Asset | Width (X) | Height (Y) | Length (Z) |
|-------|-----------|------------|------------|
| corridor.glb | 4.00 | 3.00 | 4.00 |
| room-small.glb | 12.00 | 3.13 | 12.00 |
| room-wide.glb | 20.00 | 3.33 | 12.00 |
| room-large.glb | 20.00 | 3.33 | 20.00 |

## Corrected Layout

| Element | Z Position | Notes |
|---------|------------|-------|
| Room1 | 0 | Start room (room-small) |
| Corridor1to2 | 12 | 3 pieces at -4, 0, +4 |
| Room2 | 24 | room-small |
| Corridor2to3 | 36 | 3 pieces at -4, 0, +4 |
| Room3 | 48 | room-wide |
| Corridor3to4 | 60 | 3 pieces at -4, 0, +4 |
| Room4 | 72 | room-wide |
| Corridor4to5 | 80 | 1 piece at 0 |
| Room5 | 92 | room-large (boss) |

**Total Length**: 102 units

## Files Reference

### Tools
- `scripts/utils/measure_poc_assets.gd` - Asset measurement
- `scripts/utils/validate_poc_layout.gd` - Layout validation
- `scripts/utils/fix_poc_layout.gd` - Position calculator

### Data
- `data/asset_metadata.json` - Asset metadata database

### Documentation
- `docs/LEVEL_LAYOUT_NOTES.md` - Current layout positions
- `docs/POC_LAYOUT_VALIDATION.md` - Full validation report
- `docs/assets/*.md` - Individual asset documentation

### Steering
- `.kiro/steering/asset-validation.md` - Validation workflow guide

## Tips

1. **Always measure first** - Don't assume dimensions
2. **Validate after every change** - Catch errors early
3. **Use the fix calculator** - Don't guess positions
4. **Test in-game** - Verify smooth transitions
5. **Document everything** - Update layout notes

## Success Checklist

- [ ] Assets measured and documented
- [ ] Positions calculated from measurements
- [ ] Layout updated in main.tscn
- [ ] Validation script run (all connections valid)
- [ ] Game tested (smooth movement, no gaps)
- [ ] Documentation updated (layout notes)
- [ ] Changes committed to git

## Next Steps

1. Measure additional corridor types (corners, T-junctions)
2. Add more room variations
3. Implement procedural generation using measurements
4. Create automated layout builder
5. Add visual debugging tools
