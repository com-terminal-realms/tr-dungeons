extends Area3D
class_name PickupItem

## 3D pickup item that can be collected by the player
## Automatically picked up when player enters detection radius

signal picked_up(item_data: Dictionary)

@export var item_id: String = ""
@export var quantity: int = 1
@export var pickup_radius: float = 2.0
@export var item_type: String = "gold"  # gold, equipment, consumable

var _picked_up: bool = false

func _ready() -> void:
	# Set up collision
	collision_layer = 1 << 6  # Layer 7 for pickups
	collision_mask = 1 << 1  # Detect player on Layer 2
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Set up detection sphere
	var collision_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = pickup_radius
	collision_shape.shape = sphere
	add_child(collision_shape)
	
	# Enable monitoring
	monitoring = true
	monitorable = false

func _on_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	
	# Check if this is the player
	if not body.is_in_group("player"):
		return
	
	# Pick up item
	_pickup(body)

func _pickup(player: Node3D) -> void:
	_picked_up = true
	
	# Create item data
	var item_data := {
		"item_id": item_id,
		"quantity": quantity,
		"item_type": item_type
	}
	
	# Emit signal
	picked_up.emit(item_data)
	
	# Notify player
	_notify_player(player, item_data)
	
	# Remove pickup
	queue_free()

func _notify_player(player: Node3D, item_data: Dictionary) -> void:
	# Find player's inventory or gold tracker
	match item_type:
		"gold":
			var gold_amount := quantity
			print("Picked up %d gold" % gold_amount)
			
			# Try to add to player's gold
			if player.has_method("add_gold"):
				player.add_gold(gold_amount)
			elif player.has_node("Inventory"):
				var inventory = player.get_node("Inventory")
				if inventory.has_method("add_gold"):
					inventory.add_gold(gold_amount)
		
		"equipment":
			print("Picked up equipment: %s" % item_id)
			
			# Try to add to player's inventory
			if player.has_method("add_item"):
				player.add_item(item_data)
			elif player.has_node("Inventory"):
				var inventory = player.get_node("Inventory")
				if inventory.has_method("add_item"):
					inventory.add_item(item_data)
		
		"consumable":
			print("Picked up consumable: %s x%d" % [item_id, quantity])
			
			# Try to add to player's inventory
			if player.has_method("add_item"):
				player.add_item(item_data)
			elif player.has_node("Inventory"):
				var inventory = player.get_node("Inventory")
				if inventory.has_method("add_item"):
					inventory.add_item(item_data)

## Create and spawn a pickup item at position
static func spawn(item_data: Dictionary, position: Vector3) -> PickupItem:
	var pickup := PickupItem.new()
	pickup.item_id = item_data.get("item_id", "")
	pickup.quantity = item_data.get("quantity", 1)
	pickup.item_type = item_data.get("item_type", "gold")
	pickup.global_position = position
	
	# Add visual representation
	var mesh_instance := MeshInstance3D.new()
	var mesh: Mesh
	
	match pickup.item_type:
		"gold":
			# Gold coin mesh
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.2
			cylinder.bottom_radius = 0.2
			cylinder.height = 0.05
			mesh = cylinder
			
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 0.84, 0.0)  # Gold color
			material.metallic = 1.0
			material.roughness = 0.3
			mesh_instance.material_override = material
		
		"equipment":
			# Cube for equipment
			var box := BoxMesh.new()
			box.size = Vector3(0.3, 0.3, 0.3)
			mesh = box
			
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.5, 0.5, 1.0)  # Blue
			mesh_instance.material_override = material
		
		_:
			# Default sphere
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			mesh = sphere
	
	mesh_instance.mesh = mesh
	pickup.add_child(mesh_instance)
	
	# Add to scene
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(pickup)
	
	return pickup
