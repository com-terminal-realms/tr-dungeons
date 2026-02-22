extends CharacterBody3D

## Combat-enabled player character
## Handles movement and combat input

@export var move_speed: float = 6.0
@export var gravity: float = 9.8

@onready var combat_component: CombatComponent = $CombatComponent
@onready var stats_component: StatsComponent = $StatsComponent
@onready var inventory: Inventory = $Inventory

var _camera: Camera3D

func _ready() -> void:
	# Find camera
	if has_node("Camera3D"):
		_camera = get_node("Camera3D") as Camera3D
	else:
		_camera = get_viewport().get_camera_3d() as Camera3D
	
	# Connect death signal
	if stats_component:
		stats_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get movement input
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Apply movement
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# Face movement direction
		if direction.length() > 0.1:
			rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if not combat_component:
		return
	
	# Attack (left mouse button)
	if event.is_action_pressed("attack"):
		combat_component.attack()
	
	# Dodge (spacebar)
	if event.is_action_pressed("dodge"):
		var dodge_direction := Vector3.ZERO
		
		# Get movement direction for dodge
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0.1:
			dodge_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		else:
			# Dodge forward if not moving
			dodge_direction = -global_transform.basis.z
		
		combat_component.dodge(dodge_direction)
	
	# Cast fireball (right mouse button)
	if event.is_action_pressed("cast_fireball"):
		if combat_component.ability_controller:
			combat_component.ability_controller.activate_ability("fireball")

func _on_died() -> void:
	# Notify respawn manager
	var respawn_manager: Node = get_tree().get_first_node_in_group("respawn_manager")
	if respawn_manager and respawn_manager.has_method("on_player_died"):
		respawn_manager.on_player_died(self)

## Add gold to inventory
func add_gold(amount: int) -> void:
	if inventory:
		inventory.add_gold(amount)

## Add item to inventory
func add_item(item_data: Dictionary) -> void:
	if inventory:
		inventory.add_item(item_data)
