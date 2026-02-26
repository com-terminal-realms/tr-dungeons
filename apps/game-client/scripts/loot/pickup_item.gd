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
	print("PickupItem: _ready() called - item_id:", item_id, " position:", global_position)
	
	# Set up collision - Layer 7 for pickups, detect Layer 1 (player CharacterBody3D)
	collision_layer = 1 << 6  # Layer 7 for pickups
	collision_mask = 1 << 0  # Detect player on Layer 1 (default CharacterBody3D layer)
	
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
	
	print("PickupItem: Collision setup complete - layer:", collision_layer, " mask:", collision_mask)

func _on_body_entered(body: Node3D) -> void:
	print("PickupItem: body_entered - body: ", body.name, " picked_up: ", _picked_up)
	if _picked_up:
		return
	
	# Check if this is the player
	if not body.is_in_group("player"):
		print("PickupItem: Not player, ignoring")
		return
	
	print("PickupItem: Player detected, picking up item")
	# Pick up item
	_pickup(body)

func _pickup(player: Node3D) -> void:
	_picked_up = true
	print("PickupItem: _pickup() called - item_id:", item_id, " quantity:", quantity, " type:", item_type)
	
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
	
	print("PickupItem: Item picked up, removing from scene")
	# Remove pickup
	queue_free()

func _notify_player(player: Node3D, item_data: Dictionary) -> void:
	# Show floating pickup text
	_show_pickup_text(item_data)
	
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

## Show floating pickup text notification
func _show_pickup_text(item_data: Dictionary) -> void:
	var label := Label3D.new()
	
	# Set text based on item type
	match item_type:
		"gold":
			label.text = "+%d Gold" % quantity
			label.modulate = Color(1.0, 0.84, 0.0)  # Gold color
		"equipment":
			label.text = "+%s" % item_id.capitalize()
			label.modulate = Color(0.5, 0.5, 1.0)  # Blue
		"consumable":
			label.text = "+%d %s" % [quantity, item_id.capitalize()]
			label.modulate = Color(0.0, 1.0, 0.5)  # Green
	
	# Position above pickup location
	label.global_position = global_position + Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	
	# Add to scene
	get_tree().root.add_child(label)
	
	# Animate: float up and fade out
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 2.0, 0), 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free).set_delay(1.5)

## Create and spawn a pickup item at position
static func spawn(item_data: Dictionary, position: Vector3) -> PickupItem:
	print("PickupItem: spawn() called with item_data: ", item_data, " at position: ", position)
	
	var pickup := PickupItem.new()
	pickup.item_id = item_data.get("item_id", "")
	pickup.quantity = item_data.get("quantity", 1)
	pickup.item_type = _determine_item_type(item_data.get("item_id", ""))
	
	# Set position at ground level (y = 0.5 to be slightly above ground)
	pickup.global_position = Vector3(position.x, 0.5, position.z)
	
	print("PickupItem: Created pickup - id:", pickup.item_id, " qty:", pickup.quantity, " type:", pickup.item_type, " pos:", pickup.global_position)
	
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
		print("PickupItem: Added to scene tree")
	else:
		print("PickupItem: ERROR - Could not get scene tree")
	
	return pickup

## Determine item type from item_id
static func _determine_item_type(item_id: String) -> String:
	if item_id == "gold":
		return "gold"
	elif item_id.ends_with("_potion") or item_id.ends_with("_elixir"):
		return "consumable"
	else:
		return "equipment"
