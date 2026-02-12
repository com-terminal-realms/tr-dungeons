# TR-Dungeons Control Scheme

## Overview

TR-Dungeons uses a **RMB-only movement system** with camera controls. WASD keys are **completely removed** from movement and reserved for future combat abilities.

## Control Reference

| Input | Action | Details |
|-------|--------|---------|
| **RMB Click** | Move to location | Click ground to move, click enemy to move within attack range |
| **RMB Hold + Drag** | Rotate camera | Hold RMB and move mouse to rotate camera around player (5-pixel threshold) |
| **Mouse Wheel** | Zoom camera | Scroll to zoom in/out (range: 8.0 to 25.0 units) |
| **Arrow Keys** | Alternative camera controls | Left/Right: Rotate camera, Up/Down: Zoom in/out |
| **LMB** | Attack | Cone-based attack (90° angle, 3.0 range, multi-target) |
| **H Key** | Heal | Restore 20 HP |
| **WASD** | **RESERVED** | Not used for movement - reserved for future combat abilities |

## Critical Design Decisions

### Why RMB-Only Movement?

1. **WASD is reserved for combat abilities** - Future skills will be mapped to QWER or WASD
2. **Click-to-move is intuitive** - Common in action RPGs and MOBAs
3. **Reduces hand movement** - Mouse controls both movement and camera
4. **Prevents accidental movement** - Deliberate clicks instead of held keys

### Why RMB Drag for Camera?

1. **Feels natural** - Similar to 3D modeling software and strategy games
2. **5-pixel threshold** - Distinguishes between click (move) and drag (rotate)
3. **Smooth rotation** - Direct mouse movement translates to camera rotation
4. **No mode switching** - Same button for movement and camera control

## Implementation Details

### Movement System

**File**: `apps/game-client/scenes/player/player.gd`

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            # RMB click - move to location
            var ray_result = raycast_from_camera(event.position)
            if ray_result:
                if ray_result.collider.is_in_group("enemies"):
                    # Move to attack range, not to enemy position
                    move_to_attack_range(ray_result.collider)
                else:
                    # Move to ground location
                    move_to_position(ray_result.position)
```

### Camera Rotation

**File**: `apps/game-client/scripts/camera/isometric_camera.gd`

```gdscript
const DRAG_THRESHOLD := 5.0  # Pixels to distinguish click from drag

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed:
                is_rmb_pressed = true
                rmb_press_position = event.position
            else:
                is_rmb_pressed = false
                
    elif event is InputEventMouseMotion and is_rmb_pressed:
        var drag_distance = event.position.distance_to(rmb_press_position)
        if drag_distance > DRAG_THRESHOLD:
            # RMB drag - rotate camera
            var delta = event.relative
            rotation_degrees.y -= delta.x * rotation_speed
```

### Camera Zoom

**File**: `apps/game-client/scripts/camera/isometric_camera.gd`

```gdscript
const ZOOM_MIN := 8.0
const ZOOM_MAX := 25.0
const ZOOM_SPEED := 1.0

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            # Zoom in
            distance = max(ZOOM_MIN, distance - ZOOM_SPEED)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            # Zoom out
            distance = min(ZOOM_MAX, distance + ZOOM_SPEED)
```

### Arrow Key Alternative

**File**: `apps/game-client/scripts/camera/isometric_camera.gd`

```gdscript
func _process(delta: float) -> void:
    # Arrow keys for camera control
    if Input.is_action_pressed("ui_left"):
        rotation_degrees.y += rotation_speed * 50 * delta
    if Input.is_action_pressed("ui_right"):
        rotation_degrees.y -= rotation_speed * 50 * delta
    if Input.is_action_pressed("ui_up"):
        distance = max(ZOOM_MIN, distance - ZOOM_SPEED * 10 * delta)
    if Input.is_action_pressed("ui_down"):
        distance = min(ZOOM_MAX, distance + ZOOM_SPEED * 10 * delta)
```

### Cone Attack

**File**: `apps/game-client/scripts/components/combat.gd`

```gdscript
const CONE_ANGLE := 90.0  # Degrees
const CONE_RANGE := 3.0   # Units

func get_enemies_in_cone() -> Array[Node3D]:
    var enemies_in_cone: Array[Node3D] = []
    var forward = owner.basis.z  # Character forward direction (with orientation workaround)
    
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var to_enemy = enemy.global_position - owner.global_position
        var distance = to_enemy.length()
        
        if distance <= CONE_RANGE:
            var angle = rad_to_deg(forward.angle_to(to_enemy.normalized()))
            if angle <= CONE_ANGLE / 2.0:
                enemies_in_cone.append(enemy)
    
    return enemies_in_cone
```

## Testing Checklist

Before committing any control changes, verify:

- [ ] RMB click moves player to ground location
- [ ] RMB click on enemy moves player to attack range (not to enemy)
- [ ] RMB drag rotates camera (5-pixel threshold working)
- [ ] Mouse wheel zooms in/out (8.0 to 25.0 range)
- [ ] Arrow keys rotate camera (left/right)
- [ ] Arrow keys zoom camera (up/down)
- [ ] LMB attacks enemies in cone
- [ ] H key heals player
- [ ] WASD keys do nothing (reserved for future)
- [ ] No accidental movement from keyboard
- [ ] Camera rotation is smooth
- [ ] Zoom limits are enforced

## Known Issues

### Character Orientation

The Male_Ranger.gltf model faces +Z instead of Godot standard -Z (180° out of phase). Workarounds are in place:

- `combat.gd` uses `basis.z` instead of `-basis.z`
- `player.gd` uses `look_at(position - direction)` instead of `look_at(position + direction)`

See `CHARACTER_ORIENTATION_FIX.md` for full details and post-POC fix options.

## Future Enhancements

### Planned Combat Abilities (WASD)

- **Q**: Ability 1 (TBD)
- **W**: Ability 2 (TBD)
- **E**: Ability 3 (TBD)
- **R**: Ultimate ability (TBD)

Or alternative mapping:

- **W**: Forward dash/charge
- **A**: Left strafe ability
- **S**: Defensive ability
- **D**: Right strafe ability

### Potential Camera Improvements

- **MMB drag**: Alternative camera rotation
- **Shift + RMB**: Fast camera rotation
- **Ctrl + Mouse Wheel**: Adjust camera angle (pitch)
- **Camera presets**: Number keys for preset camera angles

## Design Rationale

### Why Not WASD Movement?

1. **Combat ability space** - Need 4+ keys for abilities
2. **Click-to-move is standard** - Diablo, Path of Exile, League of Legends all use it
3. **Reduces complexity** - One input method for movement
4. **Better for combat** - Hands free for abilities while moving

### Why 5-Pixel Drag Threshold?

- **Too low (1-2 pixels)**: Accidental drags when trying to click
- **Too high (10+ pixels)**: Feels unresponsive, hard to start rotation
- **5 pixels**: Sweet spot - distinguishes intent without feeling laggy

### Why 90° Cone Angle?

- **60° too narrow**: Hard to hit multiple enemies
- **120° too wide**: Hits enemies behind player
- **90°**: Quarter circle, intuitive, good for 2-3 enemy groups

### Why 3.0 Unit Attack Range?

- **2.0 too short**: Player must get very close, takes damage
- **4.0 too long**: Feels like ranged attack, not melee
- **3.0**: Comfortable melee range, matches visual expectations

## Version History

- **v1.0** (2026-02-12): Initial documentation
  - RMB-only movement system
  - RMB drag camera rotation with 5-pixel threshold
  - Mouse wheel zoom (8.0 to 25.0 units)
  - Arrow key alternative controls
  - WASD reserved for future combat abilities
  - Cone attack system (90° angle, 3.0 range)
