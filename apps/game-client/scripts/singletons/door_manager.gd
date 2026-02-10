extends Node

## DoorManager Singleton
## Manages door placement, state tracking, and coordination across the dungeon

# Signals
signal door_state_changed(door_id: String, is_open: bool)

# Door tracking
var door_states: Dictionary = {}  # door_id -> {is_open: bool, position: Vector3, rotation: Vector3}
var registered_doors: Dictionary = {}  # door_id -> Door instance

# Asset metadata
var door_metadata: Dictionary = {}

# Door scene
var door_scene: PackedScene


func _ready() -> void:
	door_scene = load("res://scenes/door.tscn")
	_load_door_metadata()


## Load door asset metadata from asset_metadata.json
func _load_door_metadata() -> void:
	var metadata_path := "res://data/asset_metadata.json"
	
	if not FileAccess.file_exists(metadata_path):
		push_warning("DoorManager: asset_metadata.json not found, using fallback dimensions")
		_use_fallback_metadata()
		return
	
	var file := FileAccess.open(metadata_path, FileAccess.READ)
	if not file:
		push_warning("DoorManager: Failed to open asset_metadata.json, using fallback dimensions")
		_use_fallback_metadata()
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	
	if error != OK:
		push_error("DoorManager: Failed to parse asset_metadata.json: %s" % json.get_error_message())
		_use_fallback_metadata()
		return
	
	var data: Dictionary = json.data
	if data.has("metadata"):
		door_metadata = data["metadata"]
		print("DoorManager: Loaded asset metadata for %d assets" % door_metadata.size())
	else:
		push_warning("DoorManager: No metadata section in asset_metadata.json")
		_use_fallback_metadata()


## Use fallback dimensions if metadata file is unavailable
func _use_fallback_metadata() -> void:
	door_metadata = {
		"gate-door": {
			"bounding_box": {
				"size": {"x": 5.2, "y": 4.4, "z": 1.4}
			},
			"origin_offset": {"x": 0.0, "y": 2.2, "z": 0.0}
		}
	}
	print("DoorManager: Using fallback door dimensions (5.2×4.4×1.4)")


## Register a door instance with the manager
func register_door(door: Door) -> void:
	if door.door_id.is_empty():
		push_error("DoorManager: Cannot register door with empty door_id")
		return
	
	registered_doors[door.door_id] = door
	
	# Initialize state if not already present
	if not door_states.has(door.door_id):
		door_states[door.door_id] = {
			"is_open": door.is_open,
			"position": door.global_position,
			"rotation": door.rotation
		}
	
	# Connect to door's state_changed signal
	if not door.state_changed.is_connected(_on_door_state_changed):
		door.state_changed.connect(_on_door_state_changed.bind(door.door_id))
	
	print("DoorManager: Registered door '%s' at %s" % [door.door_id, door.global_position])


## Unregister a door instance
func unregister_door(door: Door) -> void:
	if registered_doors.has(door.door_id):
		registered_doors.erase(door.door_id)
		print("DoorManager: Unregistered door '%s'" % door.door_id)


## Get door state by ID
func get_door_state(door_id: String) -> bool:
	if door_states.has(door_id):
		return door_states[door_id]["is_open"]
	return false


## Set door state by ID
func set_door_state(door_id: String, is_open: bool) -> void:
	if door_states.has(door_id):
		door_states[door_id]["is_open"] = is_open
		
		# Update the actual door instance if registered
		if registered_doors.has(door_id):
			var door: Door = registered_doors[door_id]
			if door.is_open != is_open:
				door.toggle()


## Save all door states to dictionary
func save_door_states() -> Dictionary:
	var save_data := {}
	for door_id in door_states.keys():
		save_data[door_id] = {"is_open": door_states[door_id]["is_open"]}
	return {"doors": save_data}


## Load door states from dictionary
func load_door_states(state_data: Dictionary) -> void:
	if not state_data.has("doors"):
		push_warning("DoorManager: No 'doors' section in save data")
		return
	
	var doors_data: Dictionary = state_data["doors"]
	for door_id in doors_data.keys():
		if door_states.has(door_id):
			var is_open: bool = doors_data[door_id].get("is_open", false)
			set_door_state(door_id, is_open)
		else:
			push_warning("DoorManager: Save data contains unknown door_id '%s'" % door_id)


## Place doors at all connection points in the dungeon
func place_doors_at_connections(dungeon_root: Node3D) -> void:
	print("DoorManager: Placing test doors at all four exits of Room1...")
	
	# Room1 is at (0, 0, 0), room-large is 20x20 units
	# Room half-size is 10 units, so walls are at ±10 from center
	
	# Define all four door positions and rotations
	var door_configs := [
		{
			"name": "West",
			"position": Vector3(-10.0, 0.0, 0.0),
			"rotation": Vector3(0, 90, 0)  # Facing east (into room)
		},
		{
			"name": "East",
			"position": Vector3(10.0, 0.0, 0.0),
			"rotation": Vector3(0, -90, 0)  # Facing west (into room)
		},
		{
			"name": "North",
			"position": Vector3(0.0, 0.0, -10.0),
			"rotation": Vector3(0, 0, 0)  # Facing south (into room)
		},
		{
			"name": "South",
			"position": Vector3(0.0, 0.0, 10.0),
			"rotation": Vector3(0, 180, 0)  # Facing north (into room)
		}
	]
	
	# Place a door at each exit
	for config in door_configs:
		var door := _instantiate_door_at(config["position"], config["rotation"])
		if door:
			dungeon_root.add_child(door)
			register_door(door)
			print("DoorManager: %s door placed at %s" % [config["name"], config["position"]])


## Detect connection points between rooms and corridors
func _detect_connection_points(dungeon_root: Node3D) -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	
	# Find all rooms and corridors
	var rooms: Array[Node3D] = []
	var corridors: Array[Node3D] = []
	
	_find_rooms_and_corridors(dungeon_root, rooms, corridors)
	
	print("DoorManager: Found %d rooms and %d corridors" % [rooms.size(), corridors.size()])
	
	# Check each room against each corridor for connections
	for room in rooms:
		for corridor in corridors:
			var connection := _check_connection(room, corridor)
			if not connection.is_empty():
				connections.append(connection)
	
	return connections


## Recursively find room and corridor nodes
func _find_rooms_and_corridors(node: Node, rooms: Array[Node3D], corridors: Array[Node3D]) -> void:
	# Check if this node is a room or corridor based on name
	if node.name.begins_with("Room") and node is Node3D:
		rooms.append(node as Node3D)
	elif node.name.begins_with("Corridor") and node is Node3D:
		corridors.append(node as Node3D)
	
	# Recurse through children
	for child in node.get_children():
		_find_rooms_and_corridors(child, rooms, corridors)


## Check if a room and corridor are connected
func _check_connection(room: Node3D, corridor: Node3D) -> Dictionary:
	# Get positions
	var room_pos := room.global_position
	var corridor_pos := corridor.global_position
	
	# Calculate distance between room and corridor
	var delta := corridor_pos - room_pos
	
	# Room-large is 20x20, so connection points are at ±10 from center
	var room_half_size := 10.0
	
	# Check if corridor is directly north or south of room (along Z axis)
	if abs(delta.x) < 2.0:  # Corridor is centered on room's X axis
		if abs(delta.z) > 8.0 and abs(delta.z) < 18.0:  # Corridor is near room edge
			# Door should be at room's north or south wall
			var wall_normal := Vector3(0, 0, -sign(delta.z))  # Normal points INTO the room
			var z_offset := room_half_size if delta.z > 0 else -room_half_size
			var connection_pos := room_pos + Vector3(0, 1.66345, z_offset)
			var rotation := _calculate_door_orientation_from_normal(wall_normal)
			
			var connection := {
				"position": connection_pos,
				"door_rotation": rotation,
				"room_a": room,
				"room_b": corridor,
				"wall_normal": wall_normal
			}
			
			print("DoorManager: Found connection between %s and %s at %s" % [room.name, corridor.name, connection_pos])
			return connection
	
	# Check if corridor is directly east or west of room (along X axis)
	if abs(delta.z) < 2.0:  # Corridor is centered on room's Z axis
		if abs(delta.x) > 8.0 and abs(delta.x) < 18.0:  # Corridor is near room edge
			# Door should be at room's east or west wall
			var wall_normal := Vector3(-sign(delta.x), 0, 0)  # Normal points INTO the room
			var x_offset := room_half_size if delta.x > 0 else -room_half_size
			var connection_pos := room_pos + Vector3(x_offset, 1.66345, 0)
			var rotation := _calculate_door_orientation_from_normal(wall_normal)
			
			var connection := {
				"position": connection_pos,
				"door_rotation": rotation,
				"room_a": room,
				"room_b": corridor,
				"wall_normal": wall_normal
			}
			
			print("DoorManager: Found connection between %s and %s at %s" % [room.name, corridor.name, connection_pos])
			return connection
	
	return {}


## Get room metadata from asset_metadata.json
func _get_room_metadata(room: Node3D) -> Dictionary:
	# Try to find DungeonRoom child which has the actual asset
	var dungeon_room := room.get_node_or_null("DungeonRoom")
	if not dungeon_room:
		return {}
	
	# Determine room type from scene file path or name
	# For now, assume room-large for all rooms
	var room_type := "room-large"
	
	if door_metadata.has(room_type):
		return door_metadata[room_type]
	
	return {}


## Calculate door orientation from wall normal vector
func _calculate_door_orientation_from_normal(wall_normal: Vector3) -> Vector3:
	# Wall normal points into the room from the wall
	# Door should be perpendicular to the wall
	
	# For walls facing along X axis (east/west walls), door rotates 90 degrees
	if abs(wall_normal.x) > 0.5:
		return Vector3(0, 90, 0)
	
	# For walls facing along Z axis (north/south walls), door faces forward (0 degrees)
	if abs(wall_normal.z) > 0.5:
		return Vector3(0, 0, 0)
	
	# Default: no rotation
	return Vector3(0, 0, 0)


## Instantiate a door at the specified position and rotation
func _instantiate_door_at(position: Vector3, rotation: Vector3, asset_variant: String = "gate-door") -> Door:
	if not door_scene:
		push_error("DoorManager: Door scene not loaded")
		return null
	
	var door: Door = door_scene.instantiate() as Door
	if not door:
		push_error("DoorManager: Failed to instantiate door scene")
		return null
	
	# Generate unique door ID
	var door_id := "door_%03d" % door_states.size()
	door.door_id = door_id
	
	# Set door asset path
	door.door_asset_path = asset_variant + ".glb"
	
	# Load the door model (no offset needed - asset has proper structure)
	_load_door_model(door, asset_variant)
	
	# Set position - door floor should be at the specified position's Y coordinate
	door.position = position
	door.rotation_degrees = rotation
	
	# Initialize to closed state
	door.is_open = false
	
	print("DoorManager: Instantiated door at position=%s, rotation=%s" % [position, rotation])
	
	return door


## Load door model into the door's MeshInstance3D
func _load_door_model(door: Door, asset_variant: String) -> void:
	var asset_path := "res://assets/models/kenney-dungeon/%s.glb" % asset_variant
	
	if not FileAccess.file_exists(asset_path):
		push_error("DoorManager: Door asset not found: %s" % asset_path)
		return
	
	var door_model_scene := load(asset_path) as PackedScene
	if not door_model_scene:
		push_error("DoorManager: Failed to load door asset: %s" % asset_path)
		return
	
	var door_model := door_model_scene.instantiate()
	if not door_model:
		push_error("DoorManager: Failed to instantiate door model")
		return
	
	# Find the MeshInstance3D in the door
	var mesh_instance := door.get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.add_child(door_model)
		
		# Find and store reference to AnimationPlayer in the door model
		var anim_player := _find_animation_player(door_model)
		if anim_player:
			door.animation_player = anim_player
			print("DoorManager: Loaded door model '%s' for door '%s' with AnimationPlayer" % [asset_variant, door.door_id])
		else:
			push_warning("DoorManager: No AnimationPlayer found in door model '%s'" % asset_variant)
	else:
		push_error("DoorManager: MeshInstance3D not found in door scene")
		door_model.queue_free()


## Recursively find AnimationPlayer in node tree
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	
	return null


## Handle door state changes
func _on_door_state_changed(is_open: bool, door_id: String) -> void:
	if door_states.has(door_id):
		door_states[door_id]["is_open"] = is_open
		door_state_changed.emit(door_id, is_open)
