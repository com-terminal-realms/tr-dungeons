extends Node
class_name AbilityController

## Manages abilities for a combatant
## Handles ability registration, activation, and cooldown tracking
## Validates resource costs before activation

signal ability_cast(ability_name: String)
signal ability_cooldown_started(ability_name: String, duration: float)
signal ability_cooldown_finished(ability_name: String)

var abilities: Dictionary = {}
var stats_component: StatsComponent = null

func _ready() -> void:
	# Find StatsComponent in parent
	var parent := get_parent()
	if parent:
		stats_component = _find_stats_component(parent)
	
	# Register abilities from children
	for child in get_children():
		if child is Ability:
			register_ability(child)

## Register an ability
func register_ability(ability: Ability) -> void:
	abilities[ability.ability_name] = ability
	
	# Connect ability signals
	ability.activated.connect(func(): _on_ability_activated(ability.ability_name))
	ability.cooldown_started.connect(func(duration: float): _on_ability_cooldown_started(ability.ability_name, duration))
	ability.cooldown_finished.connect(func(): _on_ability_cooldown_finished(ability.ability_name))

## Activate an ability by name
func activate_ability(ability_name: String) -> bool:
	print("AbilityController: activate_ability('", ability_name, "') called")
	
	if not abilities.has(ability_name):
		push_warning("Ability not found: %s" % ability_name)
		print("AbilityController: Ability '", ability_name, "' not found! Available: ", abilities.keys())
		return false
	
	var ability: Ability = abilities[ability_name]
	
	print("AbilityController: Found ability, checking cooldown...")
	
	# Check if ability is on cooldown
	if ability.is_on_cooldown():
		print("AbilityController: Ability on cooldown!")
		return false
	
	print("AbilityController: Validating resources...")
	
	# Validate resource costs
	if not _validate_resources(ability):
		print("AbilityController: Resource validation failed!")
		return false
	
	print("AbilityController: Consuming resources...")
	
	# Consume resources
	if not _consume_resources(ability):
		print("AbilityController: Resource consumption failed!")
		return false
	
	print("AbilityController: Activating ability...")
	
	# Activate ability
	var result := ability.activate()
	print("AbilityController: Ability activation result: ", result)
	return result

## Check if ability is on cooldown
func is_on_cooldown(ability_name: String) -> bool:
	if not abilities.has(ability_name):
		return false
	
	var ability: Ability = abilities[ability_name]
	return ability.is_on_cooldown()

## Get cooldown remaining for ability
func get_cooldown_remaining(ability_name: String) -> float:
	if not abilities.has(ability_name):
		return 0.0
	
	var ability: Ability = abilities[ability_name]
	return ability.get_cooldown_remaining()

## Get ability by name
func get_ability(ability_name: String) -> Ability:
	if abilities.has(ability_name):
		return abilities[ability_name]
	return null

## Validate that entity has sufficient resources for ability
func _validate_resources(ability: Ability) -> bool:
	if not stats_component:
		return true  # No stats component, allow activation
	
	# Check mana
	if ability.mana_cost > 0.0 and not stats_component.has_mana(ability.mana_cost):
		return false
	
	# Check stamina
	if ability.stamina_cost > 0.0 and not stats_component.has_stamina(ability.stamina_cost):
		return false
	
	return true

## Consume resources for ability
func _consume_resources(ability: Ability) -> bool:
	if not stats_component:
		return true  # No stats component, allow activation
	
	# Consume mana
	if ability.mana_cost > 0.0:
		if not stats_component.consume_mana(ability.mana_cost):
			return false
	
	# Consume stamina
	if ability.stamina_cost > 0.0:
		if not stats_component.consume_stamina(ability.stamina_cost):
			return false
	
	return true

## Find StatsComponent in node hierarchy
func _find_stats_component(node: Node) -> StatsComponent:
	# Check direct children
	for child in node.get_children():
		if child is StatsComponent:
			return child
	
	# Check siblings (other children of parent)
	if node.get_parent():
		for sibling in node.get_parent().get_children():
			if sibling is StatsComponent:
				return sibling
	
	return null

## Signal handlers
func _on_ability_activated(ability_name: String) -> void:
	ability_cast.emit(ability_name)

func _on_ability_cooldown_started(ability_name: String, duration: float) -> void:
	ability_cooldown_started.emit(ability_name, duration)

func _on_ability_cooldown_finished(ability_name: String) -> void:
	ability_cooldown_finished.emit(ability_name)
