# Design Document: Interactive Doors

## Overview

The Interactive Doors system adds functional doors to the TR-Dungeons game using Godot 4.x's scene system, animation framework, and physics engine. The system consists of a Door scene prefab, a DoorManager singleton for placement and state management, and integration with the existing asset measurement system.

The design follows Godot's node-based architecture with a reusable Door scene that can be instantiated at connection points. Each door handles its own interaction detection, animation, and collision management, while the DoorManager coordinates placement and state persistence.

## Architecture

### Component Overview

```
DoorManager (Singleton)
├── Door Placement System
│   ├── Connection Point Detection
│   ├── Door Instantiation
│   └── Orientation Alignment
├── State Management
│   ├── Door State Storage
│   ├── Save/Load Integration
│   └── State Synchronization
└── Interaction Coordination
    ├── Interaction Zone Tracking
    └── UI Prompt Management

Door (Scene Prefab)
├── Visual Components
│   ├── MeshInstance3D (door model)
│   └── Highlight Shader
├── Interaction Components
│   ├── Area3D (interaction zone)
│   └── Input Handler
├── Animation Components
│   ├── AnimationPlayer
│   └── Tween (for smooth rotation)
├── Collision Components
│   ├── StaticBody3D
│   └── CollisionShape3D
└── Audio Components
    └── AudioStreamPlayer3D
```

### Integration Points

1. **Asset System Integration**: Uses `data/asset_metadata.json` for door dimensions
2. **Layout System Integration**: Reads connection points from scene structure
3. **Player System Integration**: Detects player proximity and input
4. **Save System Integration**: Serializes door states to save data
5. **Validation System Integration**: Validates door placement using existing tools

## Components and Interfaces

### DoorManager (Singleton)

**Responsibilities:**
- Detect connection points between rooms and corridors
- Instantiate Door scenes at connection points
- Track all door instances and their states
- Coordinate save/load operations
- Manage UI prompts for interaction

**Interface:**

```gdscript
class_name DoorManager
extends Node

# Signals
signal door_state_changed(door_id: String, is_open: bool)

# Public Methods
func place_doors_at_connections(dungeon_root: Node3D) -> void
func get_door_state(door_id: String) -> bool
func set_door_state(door_id: String, is_open: bool) -> void
func save_door_states() -> Dictionary
func load_door_states(state_data: Dictionary) -> void
func register_door(door: Door) -> void
func unregister_door(door: Door) -> void

# Private Methods
func _detect_connection_points(dungeon_root: Node3D) -> Array[ConnectionPoint]
func _instantiate_door_at(position: Vector3, rotation: Vector3) -> Door
func _calculate_door_orientation(connection: ConnectionPoint) -> Vector3
func _load_door_metadata() -> Dictionary
```

### Door (Scene Prefab)

**Responsibilities:**
- Handle player interaction (keyboard and mouse)
- Animate opening/closing transitions
- Manage collision state
- Provide visual feedback (highlight shader)
- Play audio feedback
- Emit state change signals

**Interface:**

```gdscript
class_name Door
extends Node3D

# Signals
signal interaction_requested()
signal state_changed(is_open: bool)
signal animation_started()
signal animation_completed()

# Properties
@export var door_id: String = ""
@export var is_open: bool = false
@export var animation_duration: float = 0.5
@export var interaction_range: float = 3.0

# Public Methods
func toggle() -> void
func open() -> void
func close() -> void
func set_highlight(enabled: bool) -> void
func is_animating() -> bool
func can_close() -> bool

# Private Methods
func _on_interaction_area_entered(body: Node3D) -> void
func _on_interaction_area_exited(body: Node3D) -> void
func _handle_input_event(event: InputEvent) -> void
func _animate_door(target_rotation: float) -> void
func _update_collision_state() -> void
func _play_sound_effect(sound_type: String) -> void
```

### ConnectionPoint (Data Structure)

**Purpose:** Represents a location where a door should be placed

```gdscript
class_name ConnectionPoint
extends RefCounted

var position: Vector3
var rotation: Vector3
var room_a: Node3D
var room_b: Node3D
var wall_normal: Vector3

func _init(pos: Vector3, rot: Vector3, a: Node3D, b: Node3D, normal: Vector3):
    position = pos
    rotation = rot
    room_a = a
    room_b = b
    wall_normal = normal
```

## Data Models

### Door State Data

```gdscript
# Stored in DoorManager
var door_states: Dictionary = {
    "door_001": {
        "is_open": false,
        "position": Vector3(10, 0, 5),
        "rotation": Vector3(0, 90, 0)
    },
    "door_002": {
        "is_open": true,
        "position": Vector3(30, 0, 5),
        "rotation": Vector3(0, 0, 0)
    }
}
```

### Asset Metadata Structure

```json
{
    "gate-door.glb": {
        "dimensions": {
            "width": 5.2,
            "height": 4.4,
            "length": 1.4
        },
        "collision_shape": {
            "type": "box",
            "size": [5.2, 4.4, 1.4]
        },
        "pivot_offset": [0, 0, 0.7]
    }
}
```

### Save Data Format

```gdscript
# Serialized to JSON for save files
{
    "doors": {
        "door_001": {"is_open": false},
        "door_002": {"is_open": true},
        "door_003": {"is_open": false}
    }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Connection Point Detection Completeness
*For any* dungeon layout with known connection points between rooms and corridors, the Door_System should identify all connection points without missing any or detecting false positives.
**Validates: Requirements 1.1**

### Property 2: Door Instantiation and Alignment
*For any* detected connection point, the Door_System should instantiate a door at the correct position and align it with the wall orientation at that connection point.
**Validates: Requirements 1.2, 1.3**

### Property 3: Correct Asset Usage
*For any* door instance created by the Door_System, the mesh resource should reference the gate-door.glb asset.
**Validates: Requirements 1.4**

### Property 4: No Door Overlap
*For any* set of placed doors, no two doors should have overlapping collision shapes or positions within 0.1 unit tolerance.
**Validates: Requirements 1.5**

### Property 5: Interaction Zone Highlight Toggle
*For any* door instance, when the player enters the interaction zone the highlight should be enabled, and when the player exits the interaction zone the highlight should be disabled.
**Validates: Requirements 2.1, 2.4, 5.1, 5.2**

### Property 6: Keyboard Interaction Toggle
*For any* door in any state, when the player presses E while in the interaction zone, the door state should toggle (closed→open or open→closed).
**Validates: Requirements 2.2**

### Property 7: Mouse Interaction Toggle
*For any* door within interaction range, when the player clicks on it, the door state should toggle.
**Validates: Requirements 2.3**

### Property 8: Interaction Zone Dimensions
*For any* door instance, the interaction zone Area3D collision shape should extend 3 units from the door center in all directions.
**Validates: Requirements 2.5**

### Property 9: Animation Rotation Correctness
*For any* door, opening should rotate it +90 degrees around the Y axis over 0.5 seconds, and closing should rotate it -90 degrees over 0.5 seconds.
**Validates: Requirements 3.1, 3.2**

### Property 10: Animation Blocking
*For any* door that is currently animating, subsequent interaction requests should be ignored until the animation completes.
**Validates: Requirements 3.3**

### Property 11: Animation Completion Signal
*For any* door animation (open or close), when the animation completes, the door should emit an animation_completed signal.
**Validates: Requirements 3.5**

### Property 12: Collision State Matches Door State
*For any* door instance, the collision shape should be enabled when the door is closed and disabled when the door is open.
**Validates: Requirements 4.1, 4.2**

### Property 13: Immediate Collision Update
*For any* door that begins animating, the collision state should update immediately when the animation starts, not when it completes.
**Validates: Requirements 4.3**

### Property 14: Collision Shape Dimensions
*For any* door instance, the collision shape dimensions should match the door geometry (5.2×4.4×1.4 units).
**Validates: Requirements 4.4**

### Property 15: Player Obstruction Prevention
*For any* door, if the player's collision shape intersects the door's collision area, attempting to close the door should be prevented until the player moves away.
**Validates: Requirements 4.5**

### Property 16: Highlight Shader Configuration
*For any* door instance with highlight enabled, the shader should use an emissive glow with color #FFD700 (gold).
**Validates: Requirements 5.3**

### Property 17: Interaction Prompt Display
*For any* door, when the player enters its interaction zone, the UI should display the prompt "Press E to Open/Close".
**Validates: Requirements 5.5**

### Property 18: State Storage on Change
*For any* door that changes state, the DoorManager should immediately store the new state in its internal state dictionary.
**Validates: Requirements 6.1**

### Property 19: State Stability During Navigation
*For any* set of doors with arbitrary states, when the player moves between rooms, all door states should remain unchanged.
**Validates: Requirements 6.2**

### Property 20: Initial State Consistency
*For any* newly loaded dungeon, all doors should initialize in the closed state.
**Validates: Requirements 6.3**

### Property 21: Save/Load Round Trip
*For any* set of door states, saving the game and then loading it should restore all door states to their exact values before the save.
**Validates: Requirements 6.4, 6.5**

### Property 22: Opening Sound Playback
*For any* door that begins opening, the door should trigger playback of the door-opening sound effect.
**Validates: Requirements 7.1**

### Property 23: Closing Sound Playback
*For any* door that begins closing, the door should trigger playback of the door-closing sound effect.
**Validates: Requirements 7.2**

### Property 24: 3D Audio Configuration
*For any* door instance, the audio player should be configured as 3D positional audio with distance-based falloff.
**Validates: Requirements 7.3**

### Property 25: Audio Range Configuration
*For any* door instance, the audio player's maximum audible range should be set to 20 units.
**Validates: Requirements 7.4**

### Property 26: Asset Metadata Integration
*For any* door placement operation, the Door_System should retrieve door dimensions from asset_metadata.json.
**Validates: Requirements 8.1**

### Property 27: Connection Point Calculation Integration
*For any* door placement, the door position should match the connection point calculated by the asset mapping system.
**Validates: Requirements 8.2**

### Property 28: Validation Tool Integration
*For any* door placement operation, the Door_System should invoke the layout validation tool to check for gaps or overlaps.
**Validates: Requirements 8.3**

### Property 29: Validation Warning Logging
*For any* door placement that creates gaps or overlaps exceeding 0.1 unit tolerance, the Door_System should log a warning message with correction suggestions.
**Validates: Requirements 8.4**

### Property 30: Multi-Asset Support
*For any* door asset variant (gate.glb, gate-door.glb, gate-door-window.glb), the Door_System should successfully instantiate and configure a functional door.
**Validates: Requirements 8.5**

## Error Handling

### Invalid Placement Detection

**Error Condition:** Door placement would create overlap with existing geometry
**Handling Strategy:**
- Validate placement using collision detection before instantiation
- Log warning with position and suggested correction
- Skip placement and continue with remaining doors
- Report summary of skipped doors to console

**Error Condition:** Connection point has invalid orientation (wall normal is zero vector)
**Handling Strategy:**
- Log error with connection point details
- Use default orientation (facing +Z direction)
- Mark door as "needs manual adjustment" in debug mode

### Animation Errors

**Error Condition:** Animation interrupted by scene change or door deletion
**Handling Strategy:**
- Cancel active Tween animations in _exit_tree()
- Emit animation_completed signal even if interrupted
- Ensure collision state is set to match final door state

**Error Condition:** Multiple animation requests during active animation
**Handling Strategy:**
- Check is_animating() flag before starting new animation
- Ignore subsequent requests until current animation completes
- Log debug message if multiple requests detected

### Interaction Errors

**Error Condition:** Player attempts to close door while standing in doorway
**Handling Strategy:**
- Check for player collision overlap before allowing close
- Display feedback message: "Move away from door to close"
- Play error sound effect (optional)
- Keep door in open state

**Error Condition:** Input event received but door reference is invalid
**Handling Strategy:**
- Validate door reference before processing input
- Log error if reference is null or freed
- Gracefully ignore input event

### State Persistence Errors

**Error Condition:** Save data contains door_id that doesn't exist in current dungeon
**Handling Strategy:**
- Log warning about orphaned door state
- Skip loading state for non-existent door
- Continue loading remaining valid door states

**Error Condition:** Save data is corrupted or missing door state section
**Handling Strategy:**
- Initialize all doors to default closed state
- Log warning about missing save data
- Allow game to continue with default states

### Asset Loading Errors

**Error Condition:** asset_metadata.json file not found or invalid
**Handling Strategy:**
- Use fallback dimensions (5.2×4.4×1.4 from requirements)
- Log warning about missing metadata
- Continue with door placement using fallback values

**Error Condition:** Door asset file (gate-door.glb) not found
**Handling Strategy:**
- Log error with asset path
- Skip door instantiation for affected connection points
- Display placeholder cube in debug mode (optional)

## Testing Strategy

### Dual Testing Approach

The Interactive Doors system will use both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests** will focus on:
- Specific examples of door placement at known connection points
- Edge cases like player standing in doorway
- Error conditions like missing assets or invalid save data
- Integration points between Door and DoorManager
- Specific animation timing and easing curves

**Property-Based Tests** will focus on:
- Universal properties that hold for all doors and all states
- Randomized door configurations and player positions
- State transitions across many iterations
- Save/load round-trip consistency
- Collision and interaction zone geometry

### Property-Based Testing Configuration

**Framework:** GUT (Godot Unit Test) with custom property test helpers
**Minimum Iterations:** 100 per property test
**Tag Format:** `# Feature: interactive-doors, Property N: [property text]`

Each correctness property listed above will be implemented as a single property-based test that:
1. Generates random test inputs (door positions, states, player positions)
2. Executes the system behavior
3. Verifies the property holds for all generated inputs
4. Reports any counterexamples that violate the property

### Test Organization

```
tests/
├── unit/
│   ├── test_door_placement.gd
│   ├── test_door_interaction.gd
│   ├── test_door_animation.gd
│   ├── test_door_collision.gd
│   └── test_door_state_persistence.gd
└── property/
    ├── test_door_properties_placement.gd
    ├── test_door_properties_interaction.gd
    ├── test_door_properties_animation.gd
    ├── test_door_properties_collision.gd
    └── test_door_properties_state.gd
```

### Test Data Generation

Property tests will use generators for:
- **Random door positions:** Vector3 within dungeon bounds
- **Random door orientations:** Rotations in 90-degree increments
- **Random door states:** Open or closed
- **Random player positions:** Vector3 within interaction range or outside
- **Random dungeon layouts:** Varying numbers of rooms and corridors
- **Random save data:** Dictionaries with varying door state configurations

### Integration Testing

Integration tests will verify:
- Door placement works with actual dungeon scenes (main.tscn)
- Doors integrate correctly with player controller
- Save/load works with actual save file system
- Asset metadata integration with real asset_metadata.json
- Validation tool integration with actual validation scripts

### Performance Testing

While not part of property-based testing, performance should be monitored:
- Door placement time for large dungeons (100+ doors)
- Animation performance with many simultaneous door animations
- Memory usage for door state storage
- Save/load time with many doors

### Manual Testing Checklist

After automated tests pass, manual verification should include:
- Visual inspection of door placement alignment
- Smooth animation feel and timing
- Audio feedback quality and positioning
- Highlight shader appearance
- UI prompt readability
- Player movement through doorways feels natural
