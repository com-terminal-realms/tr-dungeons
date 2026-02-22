extends Area3D
class_name HitboxArea3D

## Hitbox for dealing damage to enemies
## Configured with collision layers to only hit appropriate targets
## Activated/deactivated during attack animations

@export var damage: float = 10.0
@export var source: Node = null

func _ready() -> void:
	# Disable by default - activated during attack frames
	monitoring = false
	monitorable = false

## Get damage amount for this hitbox
func get_damage() -> float:
	return damage

## Set damage amount
func set_damage(value: float) -> void:
	damage = value

## Get the source node (attacker)
func get_source() -> Node:
	return source if source else get_parent()

## Enable hitbox (called during attack animation)
func enable() -> void:
	monitoring = true
	monitorable = true

## Disable hitbox (called after attack animation)
func disable() -> void:
	monitoring = false
	monitorable = false
