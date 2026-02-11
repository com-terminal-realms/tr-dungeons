# Design Document: Cone-Based Melee Combat System

## Overview

This design extends the existing Combat component to support cone-based area-of-effect attacks, replacing single-target attacks with multi-target cone detection. The system uses angle and distance calculations to detect all targets within a frontal cone, applies damage simultaneously to all detected targets, and integrates smart movement where right-clicking moves the player toward targets.

The design maintains compatibility with the existing Health component, animation system, and attack cooldown mechanics while adding new cone detection capabilities.

## Architecture

### Component Structure

```
Combat (modified)
├── Cone Detection System
│   ├── Angle Calculation
│   ├── Distance Calculation
│   └── Target Filtering
├── Multi-Target Damage Application
├── Attack Cooldown (existing)
└── Visual Effects (existing)

Player (modified)
├── Input Handling
│   ├── LMB → Cone Attack
│   └── RMB → Move to Target
└── Movement System (existing)

EnemyAI (modified)
└── Attack State → Cone Attack
```

### Data Flow

1. **Attack Initiation**: Player presses LMB or Enemy enters attack state
2. **Cone Detection**: Combat component queries all potential targets in scene
3. **Target Filtering**: For each target, calculate angle and distance; filter by cone bounds
4. **Damage Application**: Apply damage to all targets within cone simultaneously
5. **Visual Feedback**: Spawn attack effects at each hit target's position
6. **Cooldown**: Start attack cooldown timer

## Components and Interfaces

### Modified Combat Component

**New Properties:**
```gdscript
@export var cone_angle: float = 90.0  # Degrees
@export var cone_range: float = 3.0   # Units
```

**Modified Methods:**

```gdscript
## Perform cone attack in forward direction
## Returns: Array of targets that were hit
func attack_cone() -> Array[Node3D]:
    if not is_attack_ready():
        return []
    
    var targets := _detect_targets_in_cone()
    
    for target in targets:
        _apply_damage_to_target(target)
    
    _cooldown_timer = attack_cooldown
    
    return targets

## Detect all targets within attack cone
func _detect_targets_in_cone() -> Array[Node3D]:
    var targets_in_cone: Array[Node3D] = []
    var potential_targets := _get_potential_targets()
    
    for target in potential_targets:
        if _is_target_in_cone(target):
            targets_in_cone.append(target)
    
    return targets_in_cone

## Check if target is within cone bounds (angle and distance)
func _is_target_in_cone(target: Node3D) -> bool:
    var direction_to_target := _owner_node.global_position.direction_to(target.global_position)
    var forward := -_owner_node.global_transform.basis.z  # Forward direction
    
    # Flatten to horizontal plane (ignore Y)
    direction_to_target.y = 0
    forward.y = 0
    direction_to_target = direction_to_target.normalized()
    forward = forward.normalized()
    
    # Calculate angle between forward and target direction
    var angle := rad_to_deg(forward.angle_to(direction_to_target))
    
    # Check if within cone angle (half angle on each side)
    var half_cone_angle := cone_angle / 2.0
    if angle > half_cone_angle:
        return false
    
    # Check distance
    var distance := _owner_node.global_position.distance_to(target.global_position)
    if distance > cone_range:
        return false
    
    return true

## Get all potential targets in scene
func _get_potential_targets() -> Array[Node3D]:
    var targets: Array[Node3D] = []
    
    # Determine target group based on owner
    var target_group := "enemies" if _owner_node.is_in_group("player") else "player"
    
    var nodes := get_tree().get_nodes_in_group(target_group)
    for node in nodes:
        if node is Node3D:
            targets.append(node)
    
    return targets

## Apply damage to a single target
func _apply_damage_to_target(target: Node3D) -> void:
    var target_health := _find_health_component(target)
    if target_health:
        target_health.take_damage(attack_damage)
    
    # Spawn attack effect
    var target_color := _get_target_color(target)
    _spawn_attack_effect(target.global_position, target_color)
    
    # Emit signal for this target
    attack_performed.emit(target, attack_damage)
```

### Modified Player Component

**New Properties:**
```gdscript
var _rmb_target: Node3D = null  # Target selected by RMB
```

**Modified Methods:**

```gdscript
## Handle attack input (LMB)
func _handle_attack() -> void:
    if not _combat or _is_attacking:
        return
    
    _is_attacking = true
    
    # Find nearest enemy to face toward
    var nearest_enemy := _find_nearest_enemy_in_cone()
    if nearest_enemy:
        # Rotate to face the enemy
        var direction_to_enemy := global_position.direction_to(nearest_enemy.global_position)
        direction_to_enemy.y = 0
        if direction_to_enemy.length() > 0:
            look_at(global_position - direction_to_enemy, Vector3.UP)
    
    # Play attack animation
    if _animation_player:
        _animation_player.play("Sword_Attack")
        await _animation_player.animation_finished
    
    # Perform cone attack
    var hit_targets := _combat.attack_cone()
    print("Player: Hit ", hit_targets.size(), " targets")
    
    _is_attacking = false

## Handle RMB click for move-to-target
func _handle_move_to_click() -> void:
    if not _camera:
        return
    
    var mouse_pos := get_viewport().get_mouse_position()
    var from := _camera.project_ray_origin(mouse_pos)
    var to := from + _camera.project_ray_normal(mouse_pos) * 1000.0
    
    var space_state := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    
    var result := space_state.intersect_ray(query)
    
    if result and result.collider:
        # Check if clicked on an enemy
        var clicked_node := result.collider
        if clicked_node.is_in_group("enemies"):
            _rmb_target = clicked_node
            _is_moving_to_target = true
            print("Player: Moving to enemy at ", clicked_node.global_position)
            return
    
    # Fallback to ground movement
    if result:
        _move_target = result.position
        _move_target.y = global_position.y
        _is_moving_to_target = true
        _rmb_target = null

## Modified physics process for RMB movement
func _physics_process(delta: float) -> void:
    var input_dir := Vector3.ZERO
    
    if _is_moving_to_target:
        # Determine target position
        var target_pos := _move_target
        if _rmb_target and is_instance_valid(_rmb_target):
            target_pos = _rmb_target.global_position
        
        var direction := global_position.direction_to(target_pos)
        direction.y = 0
        
        var distance := global_position.distance_to(target_pos)
        
        # Stop if within melee range (cone_range)
        if _rmb_target and _combat:
            if distance <= _combat.cone_range:
                _is_moving_to_target = false
                _rmb_target = null
                input_dir = Vector3.ZERO
            else:
                input_dir = direction
        else:
            # Ground movement - stop at 0.5 units
            if distance < 0.5:
                _is_moving_to_target = false
                input_dir = Vector3.ZERO
            else:
                input_dir = direction
    else:
        input_dir = _get_input_direction()
        if input_dir.length() > 0:
            _is_moving_to_target = false
            _rmb_target = null
    
    var world_dir := _transform_to_world_space(input_dir)
    if _movement:
        _movement.move(world_dir, delta)
    
    _update_animation(world_dir)
```

### Modified EnemyAI Component

**Modified Methods:**

```gdscript
## Execute attack state with cone attack
func _execute_attack(_delta: float) -> void:
    if _target and _combat:
        # Face the target
        var direction_to_target := _owner_node.global_position.direction_to(_target.global_position)
        direction_to_target.y = 0
        if direction_to_target.length() > 0:
            _owner_node.look_at(_owner_node.global_position + direction_to_target, Vector3.UP)
        
        # Play attack animation
        _play_animation("Sword_Attack")
        
        # Perform cone attack
        var hit_targets := _combat.attack_cone()
        print("Enemy: Hit ", hit_targets.size(), " targets")
    
    _movement.move(Vector3.ZERO)
```

## Data Models

### CombatData (Extended)

```gdscript
class_name CombatData
extends Resource

@export var attack_damage: int = 10
@export var attack_range: float = 2.0  # Deprecated, use cone_range
@export var attack_cooldown: float = 1.0
@export var cone_angle: float = 90.0
@export var cone_range: float = 3.0

func validate() -> Dictionary:
    var errors: Array[String] = []
    
    if attack_damage < 0:
        errors.append("attack_damage must be non-negative")
    if attack_cooldown < 0:
        errors.append("attack_cooldown must be non-negative")
    if cone_angle <= 0 or cone_angle > 360:
        errors.append("cone_angle must be between 0 and 360 degrees")
    if cone_range <= 0:
        errors.append("cone_range must be positive")
    
    return {
        "valid": errors.is_empty(),
        "errors": errors
    }
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Angle Boundary Correctness

*For any* attacker position, attacker forward direction, and target position, if the angle between the attacker's forward direction and the direction to the target is less than or equal to half the cone angle, then the target should be considered within the cone's angular bounds.

**Validates: Requirements 2.2**

### Property 2: Distance Boundary Correctness

*For any* attacker position and target position, if the distance between them is less than or equal to the cone range, then the target should be considered within the cone's distance bounds.

**Validates: Requirements 2.3**

### Property 3: Cone Inclusion Correctness

*For any* attacker and target, if the target is within both angular bounds (angle ≤ half cone angle) and distance bounds (distance ≤ cone range), then the target should be included in the cone attack.

**Validates: Requirements 2.4**

### Property 4: Cone Exclusion Correctness

*For any* attacker and target, if the target is outside either angular bounds (angle > half cone angle) or distance bounds (distance > cone range), then the target should be excluded from the cone attack.

**Validates: Requirements 2.5**

### Property 5: Multi-Target Damage Consistency

*For any* cone attack that hits N targets (where N > 0), all N targets should receive the same damage value and have their health reduced within the same attack call.

**Validates: Requirements 3.1, 3.2**

### Property 6: Movement Stop at Range

*For any* player moving toward a target via RMB, when the distance to the target becomes less than or equal to melee range, the player should stop moving.

**Validates: Requirements 4.2**

### Property 7: WASD Cancels RMB Movement

*For any* player state where RMB movement is active, if any WASD input is detected, the RMB movement should be cancelled.

**Validates: Requirements 4.4**

### Property 8: Symmetric Cone Detection

*For any* attacker (player or enemy) and set of targets, the cone detection algorithm should produce the same results regardless of whether the attacker is a player or enemy.

**Validates: Requirements 1.4, 5.1, 5.2**

### Property 9: Cooldown Applied After Attack

*For any* cone attack (regardless of number of targets hit), the attack cooldown timer should be set to the configured cooldown value after the attack completes.

**Validates: Requirements 3.4**

### Property 10: Attack Effects Spawned at Target Positions

*For any* cone attack that hits N targets, exactly N attack effect nodes should be spawned at the positions of the hit targets.

**Validates: Requirements 7.2**

### Property 11: Animation Prevents Concurrent Attacks

*For any* entity performing a cone attack, while the attack animation is playing, any additional attack attempts should be blocked until the animation completes.

**Validates: Requirements 8.3**

## Error Handling

### Invalid Target Handling

- **Null targets**: Skip null targets during cone detection
- **Invalid targets**: Check `is_instance_valid()` before processing
- **Deleted targets**: Handle targets that are freed during attack animation

### Edge Cases

- **Zero targets in cone**: Complete attack normally, apply cooldown
- **Target at exact cone boundary**: Include target if angle ≤ half cone angle
- **Attacker rotation during attack**: Use rotation at attack initiation
- **Multiple simultaneous attacks**: Each attack processes independently

### Error Recovery

- **Missing Health component**: Log warning, skip damage application for that target
- **Missing Combat component**: Log error, prevent attack
- **Invalid cone parameters**: Validate in `CombatData.validate()`, use defaults if invalid

## Testing Strategy

### Unit Tests

Unit tests verify specific examples, edge cases, and error conditions:

- **Cone angle calculations**: Test specific angles (0°, 45°, 90°, 180°)
- **Distance calculations**: Test specific distances (0, range/2, range, range+1)
- **Edge cases**: Target at exact boundary, zero targets, null targets
- **Integration**: Player attack flow, enemy attack flow, RMB movement

### Property-Based Tests

Property tests verify universal properties across all inputs using Godot's GUT framework with custom property test helpers:

- **Minimum 100 iterations per property test**
- **Random generation**: Positions, rotations, distances, angles
- **Tag format**: `# Feature: cone-melee-combat, Property N: <property name>`

**Property Test Configuration:**

Each property test should:
1. Generate random attacker positions and rotations
2. Generate random target positions
3. Calculate expected results based on cone parameters
4. Verify actual results match expected results
5. Run for 100+ iterations to cover edge cases

**Example Property Test Structure:**

```gdscript
# Feature: cone-melee-combat, Property 1: Angle Boundary Correctness
func test_angle_boundary_correctness():
    for i in range(100):
        var attacker_pos = _random_position()
        var attacker_forward = _random_direction()
        var target_pos = _random_position()
        var cone_angle = 90.0
        
        var angle = _calculate_angle(attacker_pos, attacker_forward, target_pos)
        var expected_in_bounds = angle <= (cone_angle / 2.0)
        var actual_in_bounds = _is_in_angular_bounds(attacker_pos, attacker_forward, target_pos, cone_angle)
        
        assert_eq(actual_in_bounds, expected_in_bounds, 
            "Angle boundary check failed for angle %.2f" % angle)
```

### Testing Tools

- **GUT (Godot Unit Test)**: Primary testing framework
- **Custom property test helpers**: Random generation utilities
- **Visual debugging**: Optional cone visualization for manual testing
