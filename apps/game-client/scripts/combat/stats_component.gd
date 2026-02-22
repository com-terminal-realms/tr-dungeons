extends Node
class_name StatsComponent

## Manages combat statistics and resource regeneration
## Handles health, mana, and stamina with regeneration logic

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal died()

@export var stats: CombatStats

var current_health: float
var current_mana: float
var current_stamina: float

var _stamina_regen_pause_timer: float = 0.0

func _ready() -> void:
	if stats:
		current_health = stats.max_health
		current_mana = stats.max_mana
		current_stamina = stats.max_stamina
		health_changed.emit(current_health, stats.max_health)
		mana_changed.emit(current_mana, stats.max_mana)
		stamina_changed.emit(current_stamina, stats.max_stamina)

func _process(delta: float) -> void:
	if not stats:
		return
	
	# Mana regeneration (5 per second)
	if current_mana < stats.max_mana:
		current_mana = min(current_mana + 5.0 * delta, stats.max_mana)
		mana_changed.emit(current_mana, stats.max_mana)
	
	# Stamina regeneration (20 per second, pauses after use)
	if _stamina_regen_pause_timer > 0.0:
		_stamina_regen_pause_timer -= delta
	elif current_stamina < stats.max_stamina:
		current_stamina = min(current_stamina + 20.0 * delta, stats.max_stamina)
		stamina_changed.emit(current_stamina, stats.max_stamina)

func reduce_health(amount: float) -> void:
	if not stats:
		return
	
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, stats.max_health)
	
	if current_health <= 0.0:
		died.emit()

func consume_mana(amount: float) -> bool:
	if not stats or current_mana < amount:
		return false
	
	current_mana -= amount
	mana_changed.emit(current_mana, stats.max_mana)
	return true

func consume_stamina(amount: float) -> bool:
	if not stats or current_stamina < amount:
		return false
	
	current_stamina -= amount
	stamina_changed.emit(current_stamina, stats.max_stamina)
	_stamina_regen_pause_timer = 1.0  # Pause regen for 1 second
	return true

func has_mana(amount: float) -> bool:
	return current_mana >= amount

func has_stamina(amount: float) -> bool:
	return current_stamina >= amount

func restore_full() -> void:
	if not stats:
		return
	
	current_health = stats.max_health
	current_mana = stats.max_mana
	current_stamina = stats.max_stamina
	health_changed.emit(current_health, stats.max_health)
	mana_changed.emit(current_mana, stats.max_mana)
	stamina_changed.emit(current_stamina, stats.max_stamina)
