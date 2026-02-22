extends Node
class_name Ability

## Base class for combat abilities
## Defines common properties and virtual methods for all abilities

signal activated()
signal cooldown_started(duration: float)
signal cooldown_finished()

@export var ability_name: String = "ability"
@export var cooldown: float = 1.0
@export var mana_cost: float = 0.0
@export var stamina_cost: float = 0.0
@export var cast_time: float = 0.0

var _cooldown_timer: float = 0.0
var _is_casting: bool = false
var _cast_timer: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Update cooldown timer
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			cooldown_finished.emit()
	
	# Update cast timer
	if _is_casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_is_casting = false
			_execute()

## Activate the ability (called by AbilityController)
## Returns true if activation started successfully
func activate() -> bool:
	if is_on_cooldown():
		return false
	
	if not can_activate():
		return false
	
	# Start cast time if needed
	if cast_time > 0.0:
		_is_casting = true
		_cast_timer = cast_time
	else:
		_execute()
	
	return true

## Execute the ability effect (override in subclasses)
func _execute() -> void:
	# Override in subclasses
	activated.emit()
	_start_cooldown()

## Start cooldown timer
func _start_cooldown() -> void:
	_cooldown_timer = cooldown
	cooldown_started.emit(cooldown)

## Check if ability is on cooldown
func is_on_cooldown() -> bool:
	return _cooldown_timer > 0.0

## Get remaining cooldown time
func get_cooldown_remaining() -> float:
	return max(0.0, _cooldown_timer)

## Check if ability can be activated (override for additional checks)
func can_activate() -> bool:
	return true

## Check if currently casting
func is_casting() -> bool:
	return _is_casting

## Cancel casting
func cancel_cast() -> void:
	_is_casting = false
	_cast_timer = 0.0
