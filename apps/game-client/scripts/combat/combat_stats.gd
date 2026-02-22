extends Resource
class_name CombatStats

## Combat statistics resource for entities
## Defines all combat-related stats including health, mana, stamina, damage, and armor

@export var id: String = ""
@export var max_health: float = 100.0
@export var max_mana: float = 100.0
@export var max_stamina: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 2.0
@export var armor: float = 0.0
@export var move_speed: float = 5.0
@export var critical_chance: float = 0.1
@export var critical_multiplier: float = 2.0

func _init(
	p_id: String = "",
	p_max_health: float = 100.0,
	p_max_mana: float = 100.0,
	p_max_stamina: float = 100.0,
	p_attack_damage: float = 10.0,
	p_attack_speed: float = 1.0,
	p_attack_range: float = 2.0,
	p_armor: float = 0.0,
	p_move_speed: float = 5.0,
	p_critical_chance: float = 0.1,
	p_critical_multiplier: float = 2.0
) -> void:
	id = p_id
	max_health = p_max_health
	max_mana = p_max_mana
	max_stamina = p_max_stamina
	attack_damage = p_attack_damage
	attack_speed = p_attack_speed
	attack_range = p_attack_range
	armor = p_armor
	move_speed = p_move_speed
	critical_chance = p_critical_chance
	critical_multiplier = p_critical_multiplier
