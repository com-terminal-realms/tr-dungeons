extends RefCounted
class_name DamageEvent

## Represents a damage event in combat
## Contains all information about a damage instance

var amount: float
var source: Node
var target: Node
var is_critical: bool
var damage_type: String

func _init(
	p_amount: float,
	p_source: Node,
	p_target: Node,
	p_is_critical: bool = false,
	p_damage_type: String = "physical"
) -> void:
	amount = p_amount
	source = p_source
	target = p_target
	is_critical = p_is_critical
	damage_type = p_damage_type
