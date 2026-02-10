## Unit tests for Door component
## Tests specific examples and edge cases
extends GutTest

var door_scene: PackedScene
var door: Door

func before_all() -> void:
	door_scene = load("res://scenes/door.tscn")

func before_each() -> void:
	door = door_scene.instantiate() as Door
	add_child_autofree(door)
	await get_tree().process_frame  # Wait for _ready() to complete

func test_door_scene_loads() -> void:
	assert_not_null(door, "Door scene should load")
	assert_true(door is Door, "Door should be of type Door")

func test_door_has_required_nodes() -> void:
	assert_not_null(door.get_node("MeshInstance3D"), "Door should have MeshInstance3D")
	assert_not_null(door.get_node("InteractionArea"), "Door should have InteractionArea")
	assert_not_null(door.get_node("CollisionBody"), "Door should have CollisionBody")
	assert_not_null(door.get_node("AudioStreamPlayer3D"), "Door should have AudioStreamPlayer3D")

func test_door_initial_state() -> void:
	assert_false(door.is_open, "Door should start closed")
	assert_false(door.is_animating(), "Door should not be animating initially")
	assert_eq(door.animation_duration, 0.5, "Animation duration should be 0.5 seconds")
	assert_eq(door.interaction_range, 3.0, "Interaction range should be 3.0 units")

func test_door_toggle_opens_closed_door() -> void:
	door.is_open = false
	door.toggle()
	await wait_seconds(0.6)  # Wait for animation to complete
	assert_true(door.is_open, "Door should be open after toggle")

func test_door_toggle_closes_open_door() -> void:
	door.is_open = true
	door.rotation_degrees.y = 90.0  # Set to open position
	door.toggle()
	await wait_seconds(0.6)  # Wait for animation to complete
	assert_false(door.is_open, "Door should be closed after toggle")

func test_door_collision_disabled_when_open() -> void:
	var collision_shape: CollisionShape3D = door.get_node("CollisionBody/CollisionShape3D")
	
	door.is_open = false
	door._update_collision_state()
	assert_false(collision_shape.disabled, "Collision should be enabled when closed")
	
	door.is_open = true
	door._update_collision_state()
	assert_true(collision_shape.disabled, "Collision should be disabled when open")
