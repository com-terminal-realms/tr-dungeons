extends Resource
class_name LootTable

## Defines loot drops for enemies
## Rolls against drop chances to determine what items are dropped

@export var drops: Array[LootDrop] = []

## Roll for loot drops and return array of dropped items
## Returns array of dictionaries with {item_id: String, quantity: int}
func roll() -> Array[Dictionary]:
	var dropped_items: Array[Dictionary] = []
	
	for drop in drops:
		if randf() < drop.chance:
			var item := {
				"item_id": drop.item_id,
				"quantity": drop.get_quantity()
			}
			dropped_items.append(item)
	
	return dropped_items
