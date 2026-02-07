# GoDot Setup and Isometric 3D Prototype - Design Document

## 1. Overview

This design document describes the technical architecture for a minimal playable prototype of an isometric 3D dungeon crawler built with GoDot 4.x. The prototype demonstrates core mechanics including player movement, click-to-attack combat, enemy AI with pathfinding, and modular room assembly using Synty assets.

### 1.1 Design Philosophy

The design follows a component-based architecture where game entities (Player, Enemy) are composed of reusable components (Health, Movement, Combat). This approach:
- Promotes code reuse across different entity types
- Simplifies testing by isolating concerns
- Enables easy extension for future features
- Follows GoDot's node-based composition model

### 1.2 Technology Stack

- **Engine**: GoDot 4.2+ (Vulkan renderer)
- **Language**: GDScript with type hints
- **Physics**: Built-in 3D physics engine
- **Navigation**: NavigationAgent3D for pathfinding
- **Assets**: Synty Studios POLYGON Dungeon Realms
- **Scene Format**: Text-based .tscn for version control and automation

### 1.3 Key Technical Decisions

**Why GDScript over C#?**
- Native GoDot integration with better documentation
- Faster iteration during prototyping
- Simpler deployment (no Mono runtime)
- Sufficient performance for this prototype scope

**Why Text-based .tscn?**
- Version control friendly (readable diffs)
- Enables automated scene generation/validation
- Supports property-based testing of scene structure
- Standard GoDot format (no special configuration)

**Why Component-based Architecture?**
- Reusable across Player, Enemy, and future entities
- Testable in isolation
- Follows GoDot's node composition pattern
- Easier to reason about than inheritance hierarchies

## 2. Architecture

### 2.1 Scene Hierarchy

```
Main (Node3D)
├── Environment (WorldEnvironment)
├── DirectionalLight3D
├── Camera (IsometricCamera extends Camera3D)
├── Player (CharacterBody3D)
│   ├── MeshInstance3D (visual)
│   ├── CollisionShape3D
│   ├── Health (Node)
│   ├── Movement (Node)
│   ├── Combat (Node)
│   └── HealthBar (Control)
├── Enemies (Node3D)
│   └── Enemy (CharacterBody3D) [multiple instances]
│       ├── MeshInstance3D
│       ├── CollisionShape3D
│       ├── NavigationAgent3D
│       ├── Health (Node)
│       ├── EnemyAI (Node)
│       ├── Combat (Node)
│       └── HealthBar (Control)
├── Room (Node3D)
│   ├── Floor (StaticBody3D)
│   ├── Walls (StaticBody3D) [multiple]
│   ├── NavigationRegion3D
│   └── Lighting (Node3D)
└── UI (CanvasLayer)
    └── HUD (Control)
```

### 2.2 Component System

Components are implemented as Node scripts attached to entity nodes. They communicate via signals and direct references.

**Health Component** (`health.gd`)
- Tracks current_health and max_health
- Emits `health_changed(new_health, max_health)` signal
- Emits `died()` signal when health reaches 0
- Provides `take_damage(amount: int)` and `heal(amount: int)` methods

**Movement Component** (`movement.gd`)
- Handles WASD input for player
- Applies velocity to CharacterBody3D
- Manages facing direction
- Provides `move(direction: Vector3, delta: float)` method

**Combat Component** (`combat.gd`)
- Manages attack cooldown timer
- Provides `attack(target: Node3D)` method
- Emits `attack_performed(target)` signal
- Handles damage dealing to target's Health component

**EnemyAI Component** (`enemy_ai.gd`)
- Uses NavigationAgent3D for pathfinding
- Implements detection range checking
- Manages chase and attack states
- Updates navigation target each frame

### 2.3 Data Flow

```
Input → Movement Component → CharacterBody3D.velocity → Physics Engine → Position Update
                                                                              ↓
                                                                         Camera Follow

Mouse Click → Combat Component → Attack Target → Health Component → Health Update → Signal
                                                                                        ↓
                                                                                   Health Bar UI

Enemy AI → NavigationAgent3D → Target Position → Movement → Proximity Check → Combat Component
```

## 3. Components and Interfaces

### 3.1 Health Component

```gdscript
class_name Health
extends Node

signal health_changed(current: int, maximum: int)
signal died()

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health
    health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
    """Apply damage and emit signals. Amount must be non-negative."""
    assert(amount >= 0, "Damage amount must be non-negative")
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    """Restore health up to max. Amount must be non-negative."""
    assert(amount >= 0, "Heal amount must be non-negative")
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func is_alive() -> bool:
    return current_health > 0
```

### 3.2 Movement Component

```gdscript
class_name Movement
extends Node

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0

var character_body: CharacterBody3D

func _ready() -> void:
    character_body = get_parent() as CharacterBody3D
    assert(character_body != null, "Movement must be child of CharacterBody3D")

func move(direction: Vector3, delta: float) -> void:
    """Move character in direction (world space, normalized)."""
    if direction.length() > 0:
        direction = direction.normalized()
        character_body.velocity.x = direction.x * move_speed
        character_body.velocity.z = direction.z * move_speed
        
        # Face movement direction
        var target_rotation = atan2(direction.x, direction.z)
        character_body.rotation.y = lerp_angle(
            character_body.rotation.y,
            target_rotation,
            rotation_speed * delta
        )
    else:
        character_body.velocity.x = 0
        character_body.velocity.z = 0
    
    character_body.move_and_slide()

func get_velocity() -> Vector3:
    return character_body.velocity
```

### 3.3 Combat Component

```gdscript
class_name Combat
extends Node

signal attack_performed(target: Node3D)

@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 2.0

var cooldown_timer: float = 0.0

func _process(delta: float) -> void:
    if cooldown_timer > 0:
        cooldown_timer -= delta

func can_attack() -> bool:
    return cooldown_timer <= 0

func attack(target: Node3D) -> bool:
    """Attempt to attack target. Returns true if attack succeeded."""
    if not can_attack():
        return false
    
    var distance = get_parent().global_position.distance_to(target.global_position)
    if distance > attack_range:
        return false
    
    # Find Health component on target
    var health = target.find_child("Health") as Health
    if health and health.is_alive():
        health.take_damage(attack_damage)
        cooldown_timer = attack_cooldown
        attack_performed.emit(target)
        return true
    
    return false
```

### 3.4 EnemyAI Component

```gdscript
class_name EnemyAI
extends Node

@export var detection_range: float = 10.0
@export var update_interval: float = 0.2  # Update path 5 times per second

var player: Node3D
var navigation_agent: NavigationAgent3D
var combat: Combat
var movement: Movement
var update_timer: float = 0.0

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")
    navigation_agent = get_parent().find_child("NavigationAgent3D") as NavigationAgent3D
    combat = get_parent().find_child("Combat") as Combat
    movement = get_parent().find_child("Movement") as Movement
    
    assert(player != null, "Player must be in 'player' group")
    assert(navigation_agent != null, "Enemy must have NavigationAgent3D child")
    assert(combat != null, "Enemy must have Combat component")
    assert(movement != null, "Enemy must have Movement component")

func _process(delta: float) -> void:
    update_timer -= delta
    
    var distance_to_player = get_parent().global_position.distance_to(player.global_position)
    
    # Not in detection range - idle
    if distance_to_player > detection_range:
        movement.move(Vector3.ZERO, delta)
        return
    
    # In attack range - attack
    if distance_to_player <= combat.attack_range:
        movement.move(Vector3.ZERO, delta)
        combat.attack(player)
        return
    
    # In detection range but not attack range - chase
    if update_timer <= 0:
        navigation_agent.target_position = player.global_position
        update_timer = update_interval
    
    if navigation_agent.is_navigation_finished():
        movement.move(Vector3.ZERO, delta)
        return
    
    var next_position = navigation_agent.get_next_path_position()
    var direction = (next_position - get_parent().global_position).normalized()
    movement.move(direction, delta)
```

### 3.5 IsometricCamera

```gdscript
class_name IsometricCamera
extends Camera3D

@export var target: Node3D  # Player to follow
@export var camera_angle: float = 45.0  # Degrees from horizontal
@export var camera_distance: float = 15.0
@export var follow_speed: float = 5.0
@export var zoom_min: float = 10.0
@export var zoom_max: float = 20.0
@export var zoom_speed: float = 2.0

var current_zoom: float

func _ready() -> void:
    current_zoom = camera_distance
    update_camera_position()

func _process(delta: float) -> void:
    # Handle zoom input
    var zoom_input = Input.get_axis("zoom_in", "zoom_out")
    if zoom_input != 0:
        current_zoom = clamp(
            current_zoom + zoom_input * zoom_speed,
            zoom_min,
            zoom_max
        )
    
    # Smooth follow
    if target:
        var target_position = calculate_camera_position(target.global_position)
        global_position = global_position.lerp(target_position, follow_speed * delta)

func calculate_camera_position(target_pos: Vector3) -> Vector3:
    """Calculate camera position for isometric view."""
    var angle_rad = deg_to_rad(camera_angle)
    var offset = Vector3(
        current_zoom * cos(angle_rad) * 0.707,  # 45° horizontal angle
        current_zoom * sin(angle_rad),
        current_zoom * cos(angle_rad) * 0.707
    )
    return target_pos + offset

func update_camera_position() -> void:
    """Set camera rotation for isometric view."""
    look_at(target.global_position if target else Vector3.ZERO, Vector3.UP)
```

## 4. Data Models

### 4.1 Entity Stats

Entities (Player, Enemy) use exported variables for configuration:

```gdscript
# Player configuration (in player.gd)
@export_group("Stats")
@export var max_health: int = 100
@export var move_speed: float = 5.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 2.0

# Enemy configuration (in enemy.gd)
@export_group("Stats")
@export var max_health: int = 50
@export var move_speed: float = 3.0
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 2.0
@export var detection_range: float = 10.0
```

### 4.2 Scene Structure Data

Modular room pieces follow a naming convention for automated assembly:

```
room_floor_4x4.tscn       # Floor tile (4x4 units)
room_wall_straight.tscn   # Straight wall segment
room_wall_corner.tscn     # Corner wall piece
room_door_frame.tscn      # Door opening
room_pillar.tscn          # Decorative pillar
```

Each piece includes:
- MeshInstance3D with imported Synty model
- StaticBody3D with CollisionShape3D
- Metadata for dimensions (width, height, depth)

### 4.3 Navigation Mesh Data

NavigationRegion3D bakes a navigation mesh from room geometry:
- Cell size: 0.25 units (fine granularity)
- Agent radius: 0.5 units (character width)
- Agent height: 2.0 units (character height)
- Max climb: 0.5 units (step height)

### 4.4 Input Mapping

GoDot project.godot defines input actions:

```
[input]
move_forward={...}  # W key
move_back={...}     # S key
move_left={...}     # A key
move_right={...}    # D key
zoom_in={...}       # Mouse wheel up
zoom_out={...}      # Mouse wheel down
attack={...}        # Left mouse button
```

## 5. Isometric Camera Mathematics

### 5.1 Camera Position Calculation

For a true isometric view at 45° angle:

```
Given:
- target_pos: Player position (x, y, z)
- distance: Camera distance from player
- angle: 45° from horizontal

Camera offset from target:
- horizontal_dist = distance * cos(45°) = distance * 0.707
- vertical_dist = distance * sin(45°) = distance * 0.707

For isometric (45° horizontal rotation):
- offset_x = horizontal_dist * cos(45°) = distance * 0.5
- offset_y = vertical_dist = distance * 0.707
- offset_z = horizontal_dist * sin(45°) = distance * 0.5

Camera position:
- camera_pos = target_pos + offset
```

### 5.2 Input Direction Transformation

WASD input is relative to camera view, not world axes:

```
Given:
- raw_input: Vector2 from Input.get_vector("left", "right", "forward", "back")
- camera_rotation: 45° around Y axis

Transform to world space:
- forward_dir = Vector3(-0.707, 0, -0.707)  # Camera forward in world
- right_dir = Vector3(0.707, 0, -0.707)     # Camera right in world

world_direction = (forward_dir * raw_input.y) + (right_dir * raw_input.x)
```

### 5.3 Zoom Implementation

Zoom adjusts camera distance while maintaining angle:

```
current_zoom = clamp(current_zoom + zoom_delta, zoom_min, zoom_max)
camera_position = calculate_camera_position(target_pos, current_zoom)
```

## 6. Navigation and Pathfinding

### 6.1 NavigationAgent3D Setup

Each enemy has a NavigationAgent3D node configured:

```gdscript
# In enemy scene
NavigationAgent3D:
    path_desired_distance: 0.5      # How close to get to waypoints
    target_desired_distance: 1.0    # How close to get to final target
    path_max_distance: 3.0          # Max distance before recalculating
    avoidance_enabled: true         # Enable collision avoidance
    radius: 0.5                     # Agent radius for avoidance
    max_speed: 3.0                  # Maximum movement speed
```

### 6.2 Pathfinding Update Loop

Enemy AI updates navigation target periodically (not every frame):

```gdscript
# Update path 5 times per second (0.2s interval)
if update_timer <= 0:
    navigation_agent.target_position = player.global_position
    update_timer = 0.2

# Follow current path
var next_pos = navigation_agent.get_next_path_position()
var direction = (next_pos - global_position).normalized()
movement.move(direction, delta)
```

### 6.3 Navigation Mesh Baking

NavigationRegion3D automatically bakes navmesh from StaticBody3D collision shapes:

1. Room pieces have CollisionShape3D children
2. NavigationRegion3D encompasses entire room
3. Bake navmesh in editor (Navigation → Bake NavigationMesh)
4. Navmesh stored in .tscn file
5. Enemies use navmesh for pathfinding

## 7. Modular Room Assembly

### 7.1 Asset Dimensions

Synty assets use consistent grid dimensions:
- Floor tiles: 4x4 units
- Wall height: 4 units
- Wall thickness: 0.5 units
- Door width: 2 units

### 7.2 Snap-to-Grid System

Room pieces snap to 0.5 unit grid:

```gdscript
func snap_to_grid(position: Vector3, grid_size: float = 0.5) -> Vector3:
    return Vector3(
        round(position.x / grid_size) * grid_size,
        round(position.y / grid_size) * grid_size,
        round(position.z / grid_size) * grid_size
    )
```

### 7.3 Room Assembly Validation

Validate room assembly by checking:
- All pieces have collision shapes
- No gaps between adjacent pieces (distance < 0.1 units)
- Floor pieces form continuous surface
- Walls enclose playable area
- Navigation mesh covers floor area

## 8. Performance Optimization

### 8.1 Target Performance

- 60 FPS minimum (16.67ms frame time)
- <100ms input latency
- Smooth camera following (no jitter)

### 8.2 Optimization Strategies

**Reduce Draw Calls**:
- Merge static room geometry where possible
- Use texture atlases for materials
- Batch similar meshes

**Optimize Physics**:
- Use simple collision shapes (capsules, boxes)
- Limit physics updates to 60Hz
- Disable physics for distant objects (future)

**Optimize Navigation**:
- Update paths at 5Hz (not 60Hz)
- Limit active enemies to 10
- Use simpler navmesh (larger cells) if needed

**Optimize Rendering**:
- Use Vulkan renderer (better performance)
- Enable occlusion culling for rooms
- Use LOD for distant objects (future)
- Limit shadow-casting lights

### 8.3 Profiling

Use GoDot's built-in profiler:
- Monitor frame time (target: <16.67ms)
- Check physics time (target: <5ms)
- Check script time (target: <3ms)
- Check rendering time (target: <8ms)


## 9. Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing the acceptance criteria, I identified several areas where properties can be consolidated:

- **Camera properties (3.3)**: The camera angle, distance, and rotation properties all relate to maintaining the isometric view geometry. These can be combined into comprehensive properties about camera positioning.
- **Damage properties (3.5, 3.6)**: Both player and enemy damage dealing follow the same pattern. These can be unified into a single property about damage application.
- **Detection and attack range properties (3.6)**: Enemy detection and attack are both range-based behaviors that can be tested together.
- **Health bounds (3.8)**: Health tracking can be validated with a single invariant property rather than separate properties for damage and healing.

### 9.1 Camera System Properties

**Property 1: Isometric Camera Angle Invariant**

*For any* player position in the game world, the camera should maintain a 45° angle from the horizontal plane (measured from camera to player).

**Validates: Requirements 3.3**

**Property 2: Camera Distance Bounds**

*For any* zoom input sequence, the camera distance from the player should always remain within the configured [zoom_min, zoom_max] range.

**Validates: Requirements 3.3**

**Property 3: Camera Rotation Invariant**

*For any* player movement or position change, the camera's rotation around the Y axis should remain constant at 45° (isometric view does not rotate).

**Validates: Requirements 3.3**

### 9.2 Movement System Properties

**Property 4: Movement Velocity Magnitude**

*For any* non-zero input direction, the resulting character velocity magnitude should equal the configured move_speed (within floating-point tolerance of 0.01).

**Validates: Requirements 3.4**

**Property 5: Movement Direction Alignment**

*For any* input direction vector, the character's forward-facing direction should align with the movement direction (within 5° tolerance after rotation completes).

**Validates: Requirements 3.4**

### 9.3 Combat System Properties

**Property 6: Damage Application**

*For any* entity with a Health component and current_health > 0, when damage is applied, the new current_health should equal max(0, old_health - damage_amount).

**Validates: Requirements 3.5, 3.6**

**Property 7: Attack Cooldown Enforcement**

*For any* sequence of attack attempts on a Combat component, the time interval between successful attacks should be greater than or equal to the configured attack_cooldown.

**Validates: Requirements 3.5**

**Property 8: Attack Range Validation**

*For any* attack attempt, the attack should only succeed if the distance between attacker and target is less than or equal to attack_range.

**Validates: Requirements 3.5, 3.6**

### 9.4 Enemy AI Properties

**Property 9: Detection Range Behavior**

*For any* enemy and player position, the enemy should chase the player if and only if the distance between them is less than or equal to detection_range.

**Validates: Requirements 3.6**

**Property 10: Navigation Path Validity**

*For any* valid player position within a navigable area, the NavigationAgent3D should produce a path where each step moves closer to the target (monotonically decreasing distance).

**Validates: Requirements 3.6**

### 9.5 Health System Properties

**Property 11: Health Bounds Invariant**

*For any* sequence of damage and heal operations on a Health component, the current_health should always satisfy: 0 <= current_health <= max_health.

**Validates: Requirements 3.8**

**Property 12: Health Signal Emission**

*For any* Health component, when take_damage() is called, the health_changed signal should emit with the correct (current_health, max_health) values, and when current_health reaches 0, the died signal should emit exactly once.

**Validates: Requirements 3.8**

### 9.6 Room Assembly Properties

**Property 13: Room Piece Collision Shapes**

*For any* room piece scene file (.tscn), the scene should contain at least one CollisionShape3D node as a descendant of a StaticBody3D node.

**Validates: Requirements 3.7**

**Property 14: Adjacent Piece Alignment**

*For any* two room pieces placed adjacent to each other on the grid, the gap between their collision boundaries should be less than 0.1 units (no visible gaps).

**Validates: Requirements 3.7**

### 9.7 Scene Structure Properties

**Property 15: Component Presence Validation**

*For any* entity scene (Player or Enemy), the scene should contain the required component nodes: Health, Movement, and Combat as children of the root CharacterBody3D.

**Validates: Requirements 3.4, 3.5, 3.6, 3.8**

**Property 16: Scene File Format Consistency**

*For any* .tscn scene file in the project, parsing the file as text should succeed and the file should contain valid GDScript resource definitions (text-based format, not binary).

**Validates: Requirements 7.1** (Technical Specifications - scene format)

## 10. Error Handling

### 10.1 Component Initialization Errors

**Missing Parent Node**:
```gdscript
func _ready() -> void:
    character_body = get_parent() as CharacterBody3D
    if character_body == null:
        push_error("Movement component must be child of CharacterBody3D")
        set_process(false)
        return
```

**Missing Required Child**:
```gdscript
func _ready() -> void:
    health = find_child("Health") as Health
    if health == null:
        push_error("Entity missing required Health component")
        set_process(false)
        return
```

### 10.2 Combat Errors

**Invalid Target**:
```gdscript
func attack(target: Node3D) -> bool:
    if target == null:
        push_warning("Attack called with null target")
        return false
    
    var health = target.find_child("Health") as Health
    if health == null:
        push_warning("Attack target has no Health component")
        return false
    
    if not health.is_alive():
        return false  # Target already dead, silently fail
    
    # ... proceed with attack
```

**Out of Range**:
```gdscript
func attack(target: Node3D) -> bool:
    var distance = get_parent().global_position.distance_to(target.global_position)
    if distance > attack_range:
        # Silently fail - this is expected behavior
        return false
    # ... proceed with attack
```

### 10.3 Navigation Errors

**No Navigation Mesh**:
```gdscript
func _ready() -> void:
    navigation_agent = get_parent().find_child("NavigationAgent3D") as NavigationAgent3D
    if navigation_agent == null:
        push_error("Enemy missing NavigationAgent3D component")
        set_process(false)
        return
    
    # Wait for navigation map to be ready
    await get_tree().physics_frame
    if not navigation_agent.is_navigation_finished():
        # Navigation mesh available
        pass
    else:
        push_warning("Navigation mesh may not be baked for this area")
```

**Unreachable Target**:
```gdscript
func _process(delta: float) -> void:
    navigation_agent.target_position = player.global_position
    
    if navigation_agent.is_navigation_finished():
        # Path complete or unreachable
        if global_position.distance_to(player.global_position) > attack_range:
            # Target unreachable - try direct movement as fallback
            var direction = (player.global_position - global_position).normalized()
            movement.move(direction, delta)
        return
```

### 10.4 Health System Errors

**Negative Damage/Heal**:
```gdscript
func take_damage(amount: int) -> void:
    if amount < 0:
        push_error("Damage amount must be non-negative: %d" % amount)
        return
    # ... proceed
```

**Invalid Max Health**:
```gdscript
func _ready() -> void:
    if max_health <= 0:
        push_error("max_health must be positive, got: %d" % max_health)
        max_health = 100  # Fallback to default
    current_health = max_health
```

### 10.5 Camera Errors

**Missing Target**:
```gdscript
func _process(delta: float) -> void:
    if target == null:
        push_warning("IsometricCamera has no target to follow")
        return
    # ... proceed with following
```

**Invalid Zoom Range**:
```gdscript
func _ready() -> void:
    if zoom_min >= zoom_max:
        push_error("zoom_min must be less than zoom_max")
        zoom_min = 10.0
        zoom_max = 20.0
    current_zoom = clamp(camera_distance, zoom_min, zoom_max)
```

### 10.6 Asset Loading Errors

**Missing Scene File**:
```gdscript
func spawn_enemy(enemy_scene_path: String, position: Vector3) -> void:
    if not ResourceLoader.exists(enemy_scene_path):
        push_error("Enemy scene not found: %s" % enemy_scene_path)
        return
    
    var enemy_scene = load(enemy_scene_path) as PackedScene
    if enemy_scene == null:
        push_error("Failed to load enemy scene: %s" % enemy_scene_path)
        return
    
    var enemy = enemy_scene.instantiate()
    enemy.global_position = position
    add_child(enemy)
```

**Invalid Asset Dimensions**:
```gdscript
func validate_room_piece(piece: Node3D) -> bool:
    var metadata = piece.get_meta("dimensions", null)
    if metadata == null:
        push_warning("Room piece missing dimensions metadata: %s" % piece.name)
        return false
    
    if not (metadata is Dictionary and metadata.has("width") and metadata.has("depth")):
        push_error("Invalid dimensions metadata format: %s" % piece.name)
        return false
    
    return true
```

## 11. Testing Strategy

### 11.1 Dual Testing Approach

This project uses both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs

Both approaches are complementary and necessary. Unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across a wide range of inputs.

### 11.2 Property-Based Testing Framework

**Framework Selection**: GDScript does not have a mature property-based testing library. We will use **Gut (GoDot Unit Test)** for unit testing and implement a lightweight property-based testing harness.

**Property Test Harness**:
```gdscript
# test_utils/property_test.gd
class_name PropertyTest
extends GutTest

const ITERATIONS = 100  # Minimum iterations per property

func assert_property(property_name: String, test_func: Callable) -> void:
    """Run property test with multiple random inputs."""
    var failures = []
    
    for i in range(ITERATIONS):
        var result = test_func.call(i)  # Pass iteration as seed
        if not result.success:
            failures.append({
                "iteration": i,
                "input": result.input,
                "reason": result.reason
            })
    
    if failures.size() > 0:
        var msg = "Property '%s' failed %d/%d times:\n" % [property_name, failures.size(), ITERATIONS]
        for failure in failures.slice(0, 5):  # Show first 5 failures
            msg += "  Iteration %d: %s (input: %s)\n" % [failure.iteration, failure.reason, failure.input]
        fail_test(msg)
    else:
        pass_test("Property '%s' passed %d iterations" % [property_name, ITERATIONS])

func random_vector3(rng: RandomNumberGenerator, min_val: float, max_val: float) -> Vector3:
    return Vector3(
        rng.randf_range(min_val, max_val),
        rng.randf_range(min_val, max_val),
        rng.randf_range(min_val, max_val)
    )

func random_int(rng: RandomNumberGenerator, min_val: int, max_val: int) -> int:
    return rng.randi_range(min_val, max_val)
```

### 11.3 Property Test Examples

**Property 1: Isometric Camera Angle**
```gdscript
# tests/property/test_camera_properties.gd
extends PropertyTest

# Feature: godot-setup-and-isometric-prototype, Property 1: Isometric Camera Angle Invariant
func test_camera_maintains_45_degree_angle() -> void:
    var camera = IsometricCamera.new()
    var player = Node3D.new()
    add_child(player)
    add_child(camera)
    camera.target = player
    camera.camera_angle = 45.0
    camera.camera_distance = 15.0
    
    assert_property("Camera maintains 45° angle", func(seed):
        var rng = RandomNumberGenerator.new()
        rng.seed = seed
        
        # Generate random player position
        var player_pos = random_vector3(rng, -50, 50)
        player.global_position = player_pos
        
        # Update camera
        camera.update_camera_position()
        
        # Calculate angle
        var offset = camera.global_position - player_pos
        var horizontal_dist = Vector2(offset.x, offset.z).length()
        var angle = rad_to_deg(atan2(offset.y, horizontal_dist))
        
        var success = abs(angle - 45.0) < 1.0  # 1° tolerance
        return {
            "success": success,
            "input": player_pos,
            "reason": "Angle was %.2f°, expected 45°" % angle if not success else ""
        }
    )
```

**Property 11: Health Bounds Invariant**
```gdscript
# tests/property/test_health_properties.gd
extends PropertyTest

# Feature: godot-setup-and-isometric-prototype, Property 11: Health Bounds Invariant
func test_health_stays_within_bounds() -> void:
    assert_property("Health stays in [0, max_health]", func(seed):
        var rng = RandomNumberGenerator.new()
        rng.seed = seed
        
        var health = Health.new()
        health.max_health = 100
        health._ready()
        
        # Generate random sequence of damage and heal operations
        var operations = rng.randi_range(5, 20)
        for i in range(operations):
            if rng.randf() < 0.5:
                health.take_damage(rng.randi_range(0, 50))
            else:
                health.heal(rng.randi_range(0, 50))
        
        var in_bounds = health.current_health >= 0 and health.current_health <= health.max_health
        return {
            "success": in_bounds,
            "input": "After %d operations" % operations,
            "reason": "Health was %d, expected [0, 100]" % health.current_health if not in_bounds else ""
        }
    )
```

### 11.4 Unit Test Examples

**Unit Test: Player Respawn on Death**
```gdscript
# tests/unit/test_player.gd
extends GutTest

func test_player_respawns_on_death() -> void:
    var player = preload("res://scenes/player/player.tscn").instantiate()
    add_child(player)
    
    var spawn_point = Vector3(0, 0, 0)
    player.global_position = spawn_point
    
    # Move player away
    player.global_position = Vector3(10, 0, 10)
    
    # Kill player
    var health = player.find_child("Health") as Health
    health.take_damage(health.max_health)
    
    # Wait for respawn
    await get_tree().create_timer(0.1).timeout
    
    # Check player is back at spawn
    assert_almost_eq(player.global_position, spawn_point, Vector3(0.1, 0.1, 0.1))
```

**Unit Test: Enemy Removed on Death**
```gdscript
# tests/unit/test_enemy.gd
extends GutTest

func test_enemy_removed_on_death() -> void:
    var enemy = preload("res://scenes/enemies/enemy_base.tscn").instantiate()
    add_child(enemy)
    
    var health = enemy.find_child("Health") as Health
    var initial_child_count = get_child_count()
    
    # Kill enemy
    health.take_damage(health.max_health)
    
    # Wait for cleanup
    await get_tree().create_timer(0.1).timeout
    
    # Check enemy is removed
    assert_eq(get_child_count(), initial_child_count - 1)
```

### 11.5 Integration Tests

**Integration Test: Combat Flow**
```gdscript
# tests/integration/test_combat_flow.gd
extends GutTest

func test_player_attacks_enemy_until_death() -> void:
    var player = preload("res://scenes/player/player.tscn").instantiate()
    var enemy = preload("res://scenes/enemies/enemy_base.tscn").instantiate()
    add_child(player)
    add_child(enemy)
    
    # Position enemy in attack range
    player.global_position = Vector3(0, 0, 0)
    enemy.global_position = Vector3(1, 0, 0)
    
    var player_combat = player.find_child("Combat") as Combat
    var enemy_health = enemy.find_child("Health") as Health
    
    var initial_health = enemy_health.current_health
    var attacks_needed = ceil(float(initial_health) / player_combat.attack_damage)
    
    # Attack until enemy dies
    for i in range(attacks_needed):
        player_combat.attack(enemy)
        await get_tree().create_timer(player_combat.attack_cooldown + 0.1).timeout
    
    # Check enemy is dead
    assert_eq(enemy_health.current_health, 0)
    assert_false(enemy_health.is_alive())
```

### 11.6 Scene Structure Tests

**Property 15: Component Presence**
```gdscript
# tests/property/test_scene_structure.gd
extends PropertyTest

# Feature: godot-setup-and-isometric-prototype, Property 15: Component Presence Validation
func test_entity_scenes_have_required_components() -> void:
    var entity_scenes = [
        "res://scenes/player/player.tscn",
        "res://scenes/enemies/enemy_base.tscn"
    ]
    
    for scene_path in entity_scenes:
        var scene = load(scene_path) as PackedScene
        var entity = scene.instantiate()
        
        assert_not_null(entity.find_child("Health"), "%s missing Health component" % scene_path)
        assert_not_null(entity.find_child("Movement"), "%s missing Movement component" % scene_path)
        assert_not_null(entity.find_child("Combat"), "%s missing Combat component" % scene_path)
        
        entity.queue_free()
```

### 11.7 Test Configuration

**Gut Configuration** (in `.gutconfig.json`):
```json
{
  "dirs": ["res://tests/unit/", "res://tests/integration/", "res://tests/property/"],
  "include_subdirs": true,
  "log_level": 1,
  "ignore_pause": true,
  "hide_orphans": true
}
```

**Running Tests**:
```bash
# Run all tests
godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test suite
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/property/

# Run with verbose output
godot --headless -s addons/gut/gut_cmdln.gd -glog=2
```

### 11.8 Test Coverage Goals

- **Component scripts**: 90%+ coverage (Health, Movement, Combat)
- **AI scripts**: 80%+ coverage (EnemyAI, pathfinding)
- **Camera scripts**: 85%+ coverage (IsometricCamera)
- **Integration flows**: All critical paths tested (combat, death, respawn)
- **Property tests**: All 16 properties implemented and passing

### 11.9 Continuous Testing

**Pre-commit Hook**:
```bash
#!/bin/bash
# .git/hooks/pre-commit
godot --headless -s addons/gut/gut_cmdln.gd -gexit
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

**CI/CD Integration** (GitHub Actions):
```yaml
name: Run Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup GoDot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.2.0
      - name: Run Tests
        run: godot --headless -s addons/gut/gut_cmdln.gd -gexit
```

## 12. Implementation Notes

### 12.1 Development Workflow

1. **Setup Phase**: Install GoDot, import Synty assets, configure project
2. **Component Phase**: Implement Health, Movement, Combat components with tests
3. **Entity Phase**: Create Player and Enemy scenes using components
4. **Camera Phase**: Implement IsometricCamera with property tests
5. **AI Phase**: Implement EnemyAI with navigation
6. **Room Phase**: Assemble test room from modular pieces
7. **Integration Phase**: Wire everything together, test full gameplay loop
8. **Polish Phase**: Add visual feedback, optimize performance

### 12.2 GDScript Best Practices

**Type Hints**:
```gdscript
# Always use type hints
var health: int = 100
var speed: float = 5.0
var target: Node3D = null

func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)
```

**Exported Variables**:
```gdscript
# Use export for designer-configurable values
@export var max_health: int = 100
@export var move_speed: float = 5.0
@export_range(0.1, 5.0) var attack_cooldown: float = 1.0
```

**Signals**:
```gdscript
# Use signals for loose coupling
signal health_changed(current: int, maximum: int)
signal died()

# Emit with typed parameters
health_changed.emit(current_health, max_health)
```

**Node References**:
```gdscript
# Cache node references in _ready()
var health: Health
var movement: Movement

func _ready() -> void:
    health = find_child("Health") as Health
    movement = find_child("Movement") as Movement
```

### 12.3 Performance Considerations

**Update Frequencies**:
- Player input: Every frame (60Hz)
- Enemy AI pathfinding: 5Hz (0.2s interval)
- Health bar UI: On signal (event-driven)
- Camera following: Every frame with lerp smoothing

**Object Pooling** (future optimization):
```gdscript
# Pool for attack effects
var effect_pool: Array[Node3D] = []

func get_effect() -> Node3D:
    if effect_pool.size() > 0:
        return effect_pool.pop_back()
    return attack_effect_scene.instantiate()

func return_effect(effect: Node3D) -> void:
    effect.visible = false
    effect_pool.append(effect)
```

### 12.4 Debugging Tools

**Visual Debug Helpers**:
```gdscript
# Draw detection range in editor
func _draw_debug() -> void:
    if Engine.is_editor_hint():
        var mesh = ImmediateMesh.new()
        # Draw detection range circle
        # ...
```

**Console Commands**:
```gdscript
# Debug commands for testing
func _input(event: InputEvent) -> void:
    if OS.is_debug_build():
        if event.is_action_pressed("debug_kill_all_enemies"):
            get_tree().call_group("enemies", "queue_free")
        if event.is_action_pressed("debug_spawn_enemy"):
            spawn_enemy_at_cursor()
```

### 12.5 Asset Pipeline

**FBX Import Settings**:
- Scale: 1.0 (Synty assets are pre-scaled)
- Generate Collisions: Disabled (manual collision shapes)
- Materials: Import as separate resources
- Meshes: Split by material

**Material Setup**:
- Use StandardMaterial3D with PBR textures
- Enable albedo, normal, roughness maps
- Configure for Vulkan renderer
- Batch similar materials

**Texture Atlasing** (future optimization):
- Combine similar textures into atlases
- Reduce draw calls
- Use texture arrays for variations

