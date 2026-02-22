extends Resource
class_name LootDrop

## Defines a single item drop with probability and quantity
## Used by LootTable to determine what items enemies drop

@export var item_id: String = ""
@export_range(0.0, 1.0) var chance: float = 0.5
@export var min_quantity: int = 1
@export var max_quantity: int = 1

func get_quantity() -> int:
	if min_quantity == max_quantity:
		return min_quantity
	return randi_range(min_quantity, max_quantity)
