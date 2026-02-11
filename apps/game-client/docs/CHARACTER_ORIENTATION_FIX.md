# Character Model Orientation Issue

## Problem Statement

The player character model (Male_Ranger.gltf) is oriented 180° opposite to Godot's standard forward direction convention.

## Measurements

### Current State
- **Character Model Forward**: +Z (positive Z axis)
- **Godot Convention Forward**: -Z (negative Z axis)
- **Phase Difference**: 180 degrees

### Expected State
- Character model should face -Z to align with:
  - Godot's standard forward direction
  - Node3D.global_transform.basis.z conventions
  - Standard look_at() behavior

## Impact

### Code Workarounds Required
1. **Cone Detection** (`combat.gd`):
   - Uses `basis.z` instead of `-basis.z` for forward direction
   - Comment: "Use positive Z (opposite of normal forward) because character model is backwards"

2. **Attack Rotation** (`player.gd`):
   - Uses `look_at(global_position - direction_to_enemy)` instead of `look_at(global_position + direction_to_enemy)`
   - Comment: "Face opposite direction so the visual model faces the enemy"

### Functional Impact
- ✅ Movement works correctly (WASD in world space)
- ✅ Animations play correctly (walking forward when moving)
- ✅ Cone attacks detect targets correctly
- ❌ Code uses non-standard conventions
- ❌ Harder to maintain and understand

## Validation Criteria

A correctly oriented character model should:
1. Face -Z direction (Godot standard)
2. Allow cone detection to use `-basis.z` for forward
3. Allow attack rotation to use standard `look_at(position + direction)`
4. Walk forward when moving in -Z direction
5. Visual model and node forward direction aligned (0° phase difference)

## Fix Options

### Option 1: Rotate in Scene File (Recommended for POC)
**File**: `apps/game-client/scenes/player/player.tscn`

```gdscript
[node name="CharacterModel" parent="." instance=ExtResource("6")]
transform = Transform3D(-1, 0, 1.22465e-16, 0, 1, 0, -1.22465e-16, 0, -1, 0, -1, 0)
```

**Pros**:
- Quick fix
- No asset re-export needed
- Isolated to player scene

**Cons**:
- Walking animation plays backwards
- Not a root cause fix

### Option 2: Fix Asset Import Settings (Recommended for Production)
**File**: `apps/game-client/assets/characters/outfits/Male_Ranger.gltf.import`

Add rotation on import:
```ini
[params]
nodes/root_type="Node3D"
nodes/root_name="Male_Ranger"
nodes/apply_root_scale=true
nodes/root_scale=1.0
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
skins/use_named_skins=true
animation/import=true
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
import_script/path=""
_subresources={}
gltf/embedded_image_handling=1
# ADD THIS:
nodes/rotation_degrees=Vector3(0, 180, 0)
```

**Pros**:
- Fixes at import level
- Code can use standard conventions
- Applies to all instances

**Cons**:
- Requires Godot editor access
- May affect other uses of the asset

### Option 3: Re-export Asset (Best Long-term Solution)
Re-export Male_Ranger.gltf from source with correct orientation (-Z forward).

**Pros**:
- Fixes root cause
- No workarounds needed
- Standard conventions throughout

**Cons**:
- Requires access to source files
- May need to re-export all character variants

## Implementation Plan

### Phase 1: Document (DONE)
- ✅ Add orientation_issue to character_metadata.json
- ✅ Create CHARACTER_ORIENTATION_FIX.md
- ✅ Document current workarounds

### Phase 2: Validate (TODO)
- [ ] Create validation script to check character orientation
- [ ] Add to automated asset validation pipeline
- [ ] Document expected vs actual orientation

### Phase 3: Fix (TODO - After POC)
- [ ] Choose fix option (recommend Option 2 for production)
- [ ] Apply fix
- [ ] Remove code workarounds
- [ ] Update tests to use standard conventions
- [ ] Validate fix with automated tests

## Related Files

- `apps/game-client/data/character_metadata.json` - Character measurements
- `apps/game-client/scenes/player/player.tscn` - Player scene with CharacterModel
- `apps/game-client/scenes/player/player.gd` - Attack rotation workaround
- `apps/game-client/scripts/components/combat.gd` - Cone detection workaround
- `apps/game-client/assets/characters/outfits/Male_Ranger.gltf` - Source asset

## Notes

- This follows the same validation workflow as dungeon assets
- Workarounds are functional and tested (7/7 property tests passing)
- Fix should be applied after POC is complete
- Similar issue may exist with enemy character models
