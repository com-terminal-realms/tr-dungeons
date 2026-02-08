## Health component for entities
## Manages health state and emits signals for health changes
## Uses HealthData model for data storage (future orb-schema-generator output)
class_name Health
extends Node

signal health_changed(current: int, maximum: int)
signal died()

@export var max_health: int = 100

var _data: HealthData
var _is_alive: bool = true

func _ready() -> void:
	_data = HealthData.new({"max_health": max_health, "current_health": max_health})
	var validation: Dictionary = _data.validate()
	if not validation["valid"]:
		push_error("Health component invalid: %s" % validation["errors"])
		max_health = 100
		_data = HealthData.new({"max_health": 100, "current_health": 100})
	
	health_changed.emit(_data.current_health, _data.max_health)

## Apply damage to this entity
## amount: Damage amount (must be non-negative)
func take_damage(amount: int) -> void:
	if amount < 0:
		push_error("Damage amount must be non-negative: %d" % amount)
		return
	
	if not _is_alive:
		return  # Already dead, ignore damage
	
	var old_health := _data.current_health
	_data.current_health = max(0, _data.current_health - amount)
	print("Health: Took %d damage. HP: %d -> %d" % [amount, old_health, _data.current_health])
	health_changed.emit(_data.current_health, _data.max_health)
	
	if _data.current_health == 0 and _is_alive:
		_is_alive = false
		print("Health: Entity died!")
		died.emit()

## Restore health
## amount: Heal amount (must be non-negative)
func heal(amount: int) -> void:
	if amount < 0:
		push_error("Heal amount must be non-negative: %d" % amount)
		return
	
	if not _is_alive:
		return  # Cannot heal the dead
	
	_data.current_health = min(_data.max_health, _data.current_health + amount)
	health_changed.emit(_data.current_health, _data.max_health)

## Check if entity is alive
func is_alive() -> bool:
	return _is_alive

## Get current health value
func get_current_health() -> int:
	return _data.current_health

## Get maximum health value
func get_max_health() -> int:
	return _data.max_health

## Get health data model (for serialization)
func get_data() -> HealthData:
	return _data

## Set health from data model (for deserialization)
func set_data(data: HealthData) -> void:
	_data = data
	_is_alive = _data.current_health > 0
	health_changed.emit(_data.current_health, _data.max_health)

## Reset health to a specific value (useful for respawning or testing)
func reset_health(value: int) -> void:
	if not _data:
		push_error("Cannot reset health: Health component not initialized (call after _ready)")
		return
	var clamped_value: int = clamp(value, 0, _data.max_health)
	_data.current_health = clamped_value
	_is_alive = clamped_value > 0
	health_changed.emit(_data.current_health, _data.max_health)

