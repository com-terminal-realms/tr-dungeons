class_name Door
extends Node3D

## Interactive door that can be opened and closed by the player
## Handles animation, collision, visual feedback, and audio

# Signals
signal interaction_requested()
signal state_changed(is_open: bool)
signal animation_started()
signal animation_completed()

# Exported properties
@export var door_id: String = ""
@export var is_open: bool = false
@export var animation_duration: float = 0.5
@export var interaction_range: float = 3.0
@export var door_asset_path: String = "gate-door.glb"

# Private state
var _is_animating: bool = false
var _player_in_zone: bool = false
var animation_player: AnimationPlayer = null  # Set by DoorManager after loading model

# Node references (will be set in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interaction_area: Area3D = $InteractionArea
@onready var collision_body: StaticBody3D = $CollisionBody
@onready var collision_shape: CollisionShape3D = $CollisionBody/CollisionShape3D
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	# Connect signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	# Initialize collision state
	_update_collision_state()


func _input(event: InputEvent) -> void:
	# Handle keyboard input (E key)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_E and _player_in_zone:
			toggle()


## Toggle door between open and closed states
func toggle() -> void:
	if is_animating():
		return
	
	if is_open:
		close()
	else:
		open()


## Open the door
func open() -> void:
	if is_animating() or is_open:
		return
	
	is_open = true
	_animate_door(90.0)
	state_changed.emit(is_open)
	_play_sound_effect("open")


## Close the door
func close() -> void:
	if is_animating() or not is_open:
		return
	
	if not can_close():
		return
	
	is_open = false
	_animate_door(0.0)
	state_changed.emit(is_open)
	_play_sound_effect("close")


## Check if door is currently animating
func is_animating() -> bool:
	return _is_animating


## Check if door can be closed (no player obstruction)
func can_close() -> bool:
	# Check if any bodies are in the collision area
	if not collision_body:
		return true
	
	# Get all overlapping bodies in the door's collision area
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	
	# Use the door's collision shape for the query
	if collision_shape and collision_shape.shape:
		query.shape = collision_shape.shape
		query.transform = collision_body.global_transform * collision_shape.transform
		query.collision_mask = collision_body.collision_mask
		
		var results := space_state.intersect_shape(query, 10)
		
		# Check if any result is the player
		for result in results:
			var collider: Variant = result.get("collider")
			if collider and (collider.is_in_group("Player") or collider.name == "Player"):
				return false
	
	return true


## Enable or disable highlight shader effect
func set_highlight(enabled: bool) -> void:
	# Find all MeshInstance3D nodes recursively
	var mesh_instances := _find_mesh_instances(self)
	
	if mesh_instances.is_empty():
		return
	
	if enabled:
		# Create highlight shader material
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color("#FFD700")  # Gold color
		material.emission_energy_multiplier = 2.0
		
		# Apply to all mesh instances
		for mesh_inst in mesh_instances:
			if mesh_inst.mesh:
				for i in range(mesh_inst.mesh.get_surface_count()):
					mesh_inst.set_surface_override_material(i, material)
	else:
		# Remove highlight from all mesh instances
		for mesh_inst in mesh_instances:
			if mesh_inst.mesh:
				for i in range(mesh_inst.mesh.get_surface_count()):
					mesh_inst.set_surface_override_material(i, null)


## Private: Recursively find all MeshInstance3D nodes
func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	
	return result


## Private: Handle player entering interaction zone
func _on_interaction_area_entered(body: Node3D) -> void:
	# Check if the body is the player
	if body.is_in_group("Player") or body.name == "Player":
		_player_in_zone = true
		set_highlight(true)
		interaction_requested.emit()


## Private: Handle player exiting interaction zone
func _on_interaction_area_exited(body: Node3D) -> void:
	# Check if the body is the player
	if body.is_in_group("Player") or body.name == "Player":
		_player_in_zone = false
		set_highlight(false)


## Private: Animate door using AnimationPlayer
func _animate_door(target_rotation_y: float) -> void:
	_is_animating = true
	animation_started.emit()
	
	# Update collision state immediately
	_update_collision_state()
	
	# Use AnimationPlayer if available
	if animation_player:
		# Determine which animation to play based on target rotation
		var animation_name := "open" if target_rotation_y > 0 else "close"
		
		# Adjust playback speed to match our desired duration (0.5s)
		# Asset animations are 1 second, so speed = 1.0 / 0.5 = 2.0
		animation_player.speed_scale = 1.0 / animation_duration
		
		# Connect to animation_finished signal if not already connected
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
		
		# Play the animation
		animation_player.play(animation_name)
		print("Door: Playing animation '%s' at speed %.2f" % [animation_name, animation_player.speed_scale])
	else:
		# Fallback: use Tween rotation (shouldn't happen if DoorManager loaded model correctly)
		push_warning("Door: No AnimationPlayer available, using fallback Tween rotation")
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "rotation_degrees:y", target_rotation_y, animation_duration)
		tween.finished.connect(_on_animation_finished)


## Private: Handle animation completion
func _on_animation_finished(anim_name: String = "") -> void:
	_is_animating = false
	animation_completed.emit()
	
	# Disconnect the signal to avoid multiple connections
	if animation_player and animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)


## Private: Update collision shape based on door state
func _update_collision_state() -> void:
	# Get collision shape reference (handles case where @onready hasn't run yet)
	var coll_shape: CollisionShape3D = collision_shape
	if not coll_shape:
		var coll_body: StaticBody3D = get_node_or_null("CollisionBody")
		if coll_body:
			coll_shape = coll_body.get_node_or_null("CollisionShape3D")
	
	if not coll_shape:
		return
	
	# Enable collision when closed, disable when open
	coll_shape.disabled = is_open


## Private: Play sound effect for door action
func _play_sound_effect(sound_type: String) -> void:
	if not audio_player:
		return
	
	# TODO: Load actual audio files
	# For now, just prepare the audio player
	# audio_player.stream = load("res://assets/audio/door_" + sound_type + ".ogg")
	# audio_player.play()


func _exit_tree() -> void:
	# Clean up animation player signal connections
	if animation_player and animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)
