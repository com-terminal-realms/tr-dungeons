# Implementation Plan: Interactive Doors

## Overview

This implementation plan breaks down the Interactive Doors feature into discrete coding tasks. The approach follows an incremental development pattern: first establishing the core Door scene and basic functionality, then adding the DoorManager for placement and coordination, followed by state persistence, and finally integration with the existing asset system.

Each task builds on previous work, with property-based tests placed close to their corresponding implementations to catch errors early. The plan includes checkpoint tasks to ensure stability before moving to the next phase.

## Tasks

- [x] 1. Set up Door scene structure and basic components
  - Create `scenes/door.tscn` with root Node3D
  - Add MeshInstance3D child node for door visual
  - Add Area3D child node for interaction zone with SphereShape3D (radius 3.0)
  - Add StaticBody3D with CollisionShape3D (BoxShape3D: 5.2×4.4×1.4)
  - Add AudioStreamPlayer3D for sound effects
  - Create `scripts/door.gd` with Door class extending Node3D
  - Define signals: interaction_requested, state_changed, animation_started, animation_completed
  - Define exported properties: door_id, is_open, animation_duration, interaction_range
  - _Requirements: 2.5, 4.4, 7.3_

- [x] 1.1 Write property test for interaction zone dimensions
  - **Property 8: Interaction Zone Dimensions**
  - **Validates: Requirements 2.5**

- [x] 1.2 Write property test for collision shape dimensions
  - **Property 14: Collision Shape Dimensions**
  - **Validates: Requirements 4.4**

- [x] 2. Implement door state management and collision control
  - [x] 2.1 Implement door state properties and getters
    - Add `is_open` boolean property with setter
    - Implement `is_animating()` method returning animation state
    - Implement `can_close()` method checking for player obstruction
    - _Requirements: 4.5_
  
  - [x] 2.2 Implement collision state management
    - Implement `_update_collision_state()` method
    - Enable collision when door is closed
    - Disable collision when door is open
    - Call collision update immediately when state changes
    - _Requirements: 4.1, 4.2, 4.3_
  
  - [x] 2.3 Write property test for collision state matching door state
    - **Property 12: Collision State Matches Door State**
    - **Validates: Requirements 4.1, 4.2**
  
  - [x] 2.4 Write property test for immediate collision update
    - **Property 13: Immediate Collision Update**
    - **Validates: Requirements 4.3**
  
  - [x] 2.5 Write property test for player obstruction prevention
    - **Property 15: Player Obstruction Prevention**
    - **Validates: Requirements 4.5**

- [x] 3. Implement door animation system
  - [x] 3.1 Implement door opening and closing methods
    - Implement `open()` method setting target rotation to +90 degrees
    - Implement `close()` method setting target rotation to -90 degrees
    - Implement `toggle()` method switching between open/close
    - Check `is_animating()` before starting new animation
    - Emit `animation_started` signal when animation begins
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [x] 3.2 Implement smooth rotation animation with AnimationPlayer
    - Implement `_animate_door(target_rotation: float)` method
    - Use asset's built-in AnimationPlayer instead of Tween
    - Play "open" or "close" animation based on target rotation
    - Adjust playback speed to match 0.5 second duration
    - Connect to animation_finished signal
    - Emit `animation_completed` signal on completion
    - Update collision state immediately when animation starts
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 4.3_
  
  - [x] 3.3 Write property test for animation rotation correctness
    - **Property 9: Animation Rotation Correctness**
    - **Validates: Requirements 3.1, 3.2**
  
  - [x] 3.4 Write property test for animation blocking
    - **Property 10: Animation Blocking**
    - **Validates: Requirements 3.3**
  
  - [x] 3.5 Write property test for animation completion signal
    - **Property 11: Animation Completion Signal**
    - **Validates: Requirements 3.5**

- [x] 4. Checkpoint - Test door scene in isolation
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement player interaction detection
  - [x] 5.1 Implement interaction zone detection
    - Connect Area3D `body_entered` signal to `_on_interaction_area_entered`
    - Connect Area3D `body_exited` signal to `_on_interaction_area_exited`
    - Check if entered body is player (has "Player" group or class)
    - Track player presence with boolean flag
    - _Requirements: 2.1, 2.4_
  
  - [x] 5.2 Implement highlight shader control
    - Implement `set_highlight(enabled: bool)` method
    - Create ShaderMaterial with emissive glow shader
    - Set emissive color to #FFD700 (gold) when enabled
    - Apply shader to MeshInstance3D material
    - Call `set_highlight(true)` when player enters zone
    - Call `set_highlight(false)` when player exits zone
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [x] 5.3 Write property test for interaction zone highlight toggle
    - **Property 5: Interaction Zone Highlight Toggle**
    - **Validates: Requirements 2.1, 2.4, 5.1, 5.2**
  
  - [x] 5.4 Write property test for highlight shader configuration
    - **Property 16: Highlight Shader Configuration**
    - **Validates: Requirements 5.3**

- [x] 6. Implement input handling for door interaction
  - [x] 6.1 Implement keyboard input handling
    - Override `_input(event: InputEvent)` method
    - Check if player is in interaction zone
    - Check if E key is pressed (InputEventKey with keycode KEY_E)
    - Call `toggle()` method when E is pressed
    - Emit `interaction_requested` signal
    - _Requirements: 2.2_
  
  - [x] 6.2 Implement mouse click input handling
    - Add `input_event` signal connection to StaticBody3D
    - Implement `_on_input_event` callback
    - Check if event is mouse button press (MOUSE_BUTTON_LEFT)
    - Check if player is within interaction range
    - Call `toggle()` method when clicked
    - Emit `interaction_requested` signal
    - _Requirements: 2.3_
  
  - [x] 6.3 Write property test for keyboard interaction toggle
    - **Property 6: Keyboard Interaction Toggle**
    - **Validates: Requirements 2.2**
  
  - [x] 6.4 Write property test for mouse interaction toggle
    - **Property 7: Mouse Interaction Toggle**
    - **Validates: Requirements 2.3**

- [x] 7. Implement audio feedback
  - [x] 7.1 Add audio resources and configuration
    - Create placeholder audio files (door_open.ogg, door_close.ogg)
    - Configure AudioStreamPlayer3D with max_distance = 20.0
    - Set attenuation model to ATTENUATION_INVERSE_DISTANCE
    - _Requirements: 7.3, 7.4_
  
  - [x] 7.2 Implement sound effect playback
    - Implement `_play_sound_effect(sound_type: String)` method
    - Load appropriate audio stream based on sound_type
    - Call from `open()` method with "open" parameter
    - Call from `close()` method with "close" parameter
    - _Requirements: 7.1, 7.2_
  
  - [x] 7.3 Write property test for opening sound playback
    - **Property 22: Opening Sound Playback**
    - **Validates: Requirements 7.1**
  
  - [x] 7.4 Write property test for closing sound playback
    - **Property 23: Closing Sound Playback**
    - **Validates: Requirements 7.2**
  
  - [x] 7.5 Write property test for 3D audio configuration
    - **Property 24: 3D Audio Configuration**
    - **Validates: Requirements 7.3**
  
  - [x] 7.6 Write property test for audio range configuration
    - **Property 25: Audio Range Configuration**
    - **Validates: Requirements 7.4**

- [x] 8. Checkpoint - Test complete door functionality
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Create DoorManager singleton
  - [x] 9.1 Create DoorManager script and autoload
    - Create `scripts/singletons/door_manager.gd`
    - Define DoorManager class extending Node
    - Add to Project Settings autoload as "DoorManager"
    - Define signal: door_state_changed(door_id: String, is_open: bool)
    - Initialize door_states dictionary
    - _Requirements: 6.1_
  
  - [x] 9.2 Implement door registration system
    - Implement `register_door(door: Door)` method
    - Implement `unregister_door(door: Door)` method
    - Store door references in dictionary keyed by door_id
    - Connect to door's state_changed signal
    - Initialize door state in door_states dictionary
    - _Requirements: 6.1_

- [ ] 10. Implement connection point detection
  - [x] 10.1 Create ConnectionPoint data structure
    - Create `scripts/data/connection_point.gd`
    - Define ConnectionPoint class with properties: position, rotation, room_a, room_b, wall_normal
    - Implement constructor taking all parameters
    - _Requirements: 1.1_
  
  - [x] 10.2 Implement connection point detection algorithm
    - Implement `_detect_connection_points(dungeon_root: Node3D)` method
    - Iterate through all room and corridor nodes in dungeon
    - Calculate connection points at room/corridor boundaries
    - Determine wall normal from room geometry
    - Return array of ConnectionPoint objects
    - _Requirements: 1.1_
  
  - [x] 10.3 Write property test for connection point detection completeness
    - **Property 1: Connection Point Detection Completeness**
    - **Validates: Requirements 1.1**

- [ ] 11. Implement door placement system
  - [x] 11.1 Load door asset metadata
    - Implement `_load_door_metadata()` method
    - Read `data/asset_metadata.json` file
    - Parse JSON and extract door dimensions
    - Store metadata in member variable
    - Use fallback dimensions (5.2×4.4×1.4) if file missing
    - _Requirements: 8.1_
  
  - [x] 11.2 Implement door instantiation
    - Implement `_instantiate_door_at(position: Vector3, rotation: Vector3)` method
    - Load door scene (scenes/door.tscn)
    - Instantiate door scene
    - Set door position and rotation
    - Generate unique door_id
    - Set door mesh to gate-door.glb
    - Return door instance
    - _Requirements: 1.2, 1.4_
  
  - [x] 11.3 Implement door orientation calculation
    - Implement `_calculate_door_orientation(connection: ConnectionPoint)` method
    - Calculate rotation from wall_normal vector
    - Return rotation as Vector3 (Euler angles)
    - _Requirements: 1.3_
  
  - [x] 11.4 Implement main door placement method
    - Implement `place_doors_at_connections(dungeon_root: Node3D)` method
    - Call `_detect_connection_points()` to get connection points
    - For each connection point, calculate orientation
    - Instantiate door at position with calculated rotation
    - Add door to scene tree
    - Register door with DoorManager
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 11.5 Write property test for door instantiation and alignment
    - **Property 2: Door Instantiation and Alignment**
    - **Validates: Requirements 1.2, 1.3**
  
  - [x] 11.6 Write property test for correct asset usage
    - **Property 3: Correct Asset Usage**
    - **Validates: Requirements 1.4**
  
  - [x] 11.7 Write property test for no door overlap
    - **Property 4: No Door Overlap**
    - **Validates: Requirements 1.5**
  
  - [x] 11.8 Write property test for asset metadata integration
    - **Property 26: Asset Metadata Integration**
    - **Validates: Requirements 8.1**
  
  - [x] 11.9 Write property test for connection point calculation integration
    - **Property 27: Connection Point Calculation Integration**
    - **Validates: Requirements 8.2**

- [x] 12. Implement layout validation integration
  - [x] 12.1 Integrate with validation tool
    - Implement validation check after door placement
    - Call existing validation script (validate_poc_layout.gd pattern)
    - Check for gaps or overlaps exceeding 0.1 unit tolerance
    - _Requirements: 8.3_
  
  - [x] 12.2 Implement validation warning logging
    - Log warnings for any gaps or overlaps detected
    - Include door position and suggested corrections in warning
    - Format warnings for easy debugging
    - _Requirements: 8.4_
  
  - [x] 12.3 Write property test for validation tool integration
    - **Property 28: Validation Tool Integration**
    - **Validates: Requirements 8.3**
  
  - [x] 12.4 Write property test for validation warning logging
    - **Property 29: Validation Warning Logging**
    - **Validates: Requirements 8.4**

- [x] 13. Checkpoint - Test door placement system
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Implement UI prompt system
  - [x] 14.1 Create interaction prompt UI
    - Create `scenes/ui/interaction_prompt.tscn`
    - Add Label node with text "Press E to Open/Close"
    - Style label with readable font and background
    - Position at bottom-center of screen
    - Initially hide the label
    - _Requirements: 5.5_
  
  - [x] 14.2 Implement prompt display logic in DoorManager
    - Add reference to interaction_prompt UI node
    - Implement `_show_interaction_prompt()` method
    - Implement `_hide_interaction_prompt()` method
    - Connect to door interaction_area_entered signals
    - Connect to door interaction_area_exited signals
    - Show prompt when player enters any door's interaction zone
    - Hide prompt when player exits all door interaction zones
    - _Requirements: 5.5_
  
  - [x] 14.3 Write property test for interaction prompt display
    - **Property 17: Interaction Prompt Display**
    - **Validates: Requirements 5.5**

- [ ] 15. Implement state persistence
  - [x] 15.1 Implement state storage methods
    - Implement `get_door_state(door_id: String)` method
    - Implement `set_door_state(door_id: String, is_open: bool)` method
    - Update door_states dictionary when doors change state
    - Emit door_state_changed signal on state changes
    - _Requirements: 6.1_
  
  - [x] 15.2 Implement save serialization
    - Implement `save_door_states()` method
    - Serialize door_states dictionary to JSON-compatible format
    - Return dictionary with "doors" key containing all states
    - _Requirements: 6.4_
  
  - [x] 15.3 Implement load deserialization
    - Implement `load_door_states(state_data: Dictionary)` method
    - Parse state_data and extract door states
    - Update door_states dictionary
    - Apply states to registered door instances
    - Handle missing or invalid door IDs gracefully
    - _Requirements: 6.5_
  
  - [x] 15.4 Implement initial state setup
    - Initialize all doors to closed state in `place_doors_at_connections()`
    - Set is_open = false for all new door instances
    - _Requirements: 6.3_
  
  - [x] 15.5 Write property test for state storage on change
    - **Property 18: State Storage on Change**
    - **Validates: Requirements 6.1**
  
  - [x] 15.6 Write property test for state stability during navigation
    - **Property 19: State Stability During Navigation**
    - **Validates: Requirements 6.2**
  
  - [x] 15.7 Write property test for initial state consistency
    - **Property 20: Initial State Consistency**
    - **Validates: Requirements 6.3**
  
  - [x] 15.8 Write property test for save/load round trip
    - **Property 21: Save/Load Round Trip**
    - **Validates: Requirements 6.4, 6.5**

- [ ] 16. Implement multi-asset support
  - [x] 16.1 Add asset variant configuration
    - Add `door_asset_path` exported property to Door class
    - Default to "gate-door.glb"
    - Support "gate.glb" and "gate-door-window.glb" variants
    - Load mesh based on door_asset_path property
    - _Requirements: 8.5_
  
  - [x] 16.2 Update DoorManager to support asset variants
    - Add optional asset_variant parameter to `_instantiate_door_at()`
    - Set door_asset_path when instantiating doors
    - Load metadata for all asset variants from asset_metadata.json
    - _Requirements: 8.5_
  
  - [x] 16.3 Write property test for multi-asset support
    - **Property 30: Multi-Asset Support**
    - **Validates: Requirements 8.5**

- [ ] 17. Integration with main dungeon scene
  - [x] 17.1 Add DoorManager initialization to main scene
    - Open `scenes/main.tscn`
    - Add call to `DoorManager.place_doors_at_connections()` in ready function
    - Pass dungeon root node as parameter
    - _Requirements: 1.1, 1.2_
  
  - [x] 17.2 Test door placement in POC dungeon
    - Run game and verify doors appear at connection points
    - Verify doors are aligned with walls
    - Verify no overlaps or gaps
    - _Requirements: 1.1, 1.2, 1.3, 1.5_

- [x] 18. Final checkpoint - Complete integration testing
  - Ensure all tests pass, ask the user if questions arise.
  - Test complete door system in actual game environment
  - Verify all interactions work correctly
  - Verify save/load preserves door states
  - Verify audio and visual feedback

## Notes

- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Door scene is created first to enable early testing
- DoorManager is added after door functionality is complete
- State persistence is implemented after core functionality works
- Integration happens last to wire everything together
