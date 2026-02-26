extends Node
class_name Inventory

## Player inventory system
## Tracks gold and equipment items

signal gold_changed(amount: int)
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)

var gold: int = 0
var items: Dictionary = {}  # item_id -> quantity

func _ready() -> void:
	pass

## Add gold to inventory
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	print("Gold: %d (+%d)" % [gold, amount])
	
	# Notify stats tracker
	if DungeonStatsTracker.instance:
		DungeonStatsTracker.instance.record_gold_collected(amount)

## Remove gold from inventory
func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	
	gold -= amount
	gold_changed.emit(gold)
	return true

## Get current gold amount
func get_gold() -> int:
	return gold

## Add item to inventory
func add_item(item_data: Dictionary) -> void:
	var item_id: String = item_data.get("item_id", "")
	var quantity: int = item_data.get("quantity", 1)
	
	if item_id.is_empty():
		return
	
	if items.has(item_id):
		items[item_id] += quantity
	else:
		items[item_id] = quantity
	
	item_added.emit(item_id, quantity)
	print("Added item: %s x%d" % [item_id, quantity])
	
	# Notify stats tracker
	if DungeonStatsTracker.instance:
		DungeonStatsTracker.instance.record_item_collected(item_data)

## Remove item from inventory
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not items.has(item_id):
		return false
	
	if items[item_id] < quantity:
		return false
	
	items[item_id] -= quantity
	
	if items[item_id] <= 0:
		items.erase(item_id)
	
	item_removed.emit(item_id, quantity)
	return true

## Check if inventory has item
func has_item(item_id: String, quantity: int = 1) -> bool:
	if not items.has(item_id):
		return false
	
	return items[item_id] >= quantity

## Get item quantity
func get_item_quantity(item_id: String) -> int:
	return items.get(item_id, 0)

## Get all items
func get_all_items() -> Dictionary:
	return items.duplicate()

## Clear inventory
func clear() -> void:
	gold = 0
	items.clear()
	gold_changed.emit(gold)
