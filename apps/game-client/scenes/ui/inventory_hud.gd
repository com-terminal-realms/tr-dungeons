extends Control
class_name InventoryHUD

## Simple inventory HUD showing gold and item counts

@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var items_label: Label = $MarginContainer/VBoxContainer/ItemsLabel

var _inventory: Inventory

func _ready() -> void:
	# Find player's inventory
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("Inventory"):
		_inventory = player.get_node("Inventory")
		
		# Connect to inventory signals
		_inventory.gold_changed.connect(_on_gold_changed)
		_inventory.item_added.connect(_on_item_added)
		_inventory.item_removed.connect(_on_item_removed)
		
		# Update initial display
		_update_display()
	else:
		push_warning("InventoryHUD: Could not find player inventory")

func _update_display() -> void:
	if not _inventory:
		return
	
	# Update gold
	if gold_label:
		gold_label.text = "Gold: %d" % _inventory.get_gold()
	
	# Update item count
	if items_label:
		var item_count := 0
		for qty in _inventory.get_all_items().values():
			item_count += qty
		items_label.text = "Items: %d" % item_count

func _on_gold_changed(_amount: int) -> void:
	_update_display()

func _on_item_added(_item_id: String, _quantity: int) -> void:
	_update_display()

func _on_item_removed(_item_id: String, _quantity: int) -> void:
	_update_display()
