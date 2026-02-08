## Combat component for entities
## Handles attack logic, cooldowns, and damage application
## Uses CombatData model for data storage (future orb-schema-generator output)
class_name Combat
extends Node

signal attack_performed(target: Node3D, damage: int)

@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

const ATTACK_EFFECT = preload("res://scenes/effects/attack_effect.tscn")

var _data: CombatData
var _cooldown_timer: float = 0.0
var _owner_node: Node3D

func _ready() -> void:
	_data = CombatData.new({
		"attack_damage": attack_damage,
		"attack_range": attack_range,
		"attack_cooldown": attack_cooldown
	})
	var validation: Dictionary = _data.validate()
	if not validation["valid"]:
		push_error("Combat component invalid: %s" % validation["errors"])
		attack_damage = 10
		attack_range = 2.0
		attack_cooldown = 1.0
		_data = CombatData.new({
			"attack_damage": 10,
			"attack_range": 2.0,
			"attack_cooldown": 1.0
		})
	
	# Find Node3D parent for position
	_owner_node = _find_node3d(get_parent())
	if not _owner_node:
		push_error("Combat component requires Node3D parent or ancestor")

func _process(delta: float) -> void:
	# Update cooldown timer
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

## Attempt to attack a target
## target: The target Node3D to attack
## Returns: true if attack was successful, false if on cooldown or out of range
func attack(target: Node3D) -> bool:
	if not _owner_node:
		push_error("Cannot attack: Node3D owner not found")
		return false
	
	if not target:
		push_error("Cannot attack: target is null")
		return false
	
	# Check cooldown
	if _cooldown_timer > 0:
		return false
	
	# Check range
	var distance := _owner_node.global_position.distance_to(target.global_position)
	if distance > _data.attack_range:
		return false
	
	# Apply damage to target's Health component
	var target_health := _find_health_component(target)
	if target_health:
		print("Combat: Found health component, applying %d damage" % _data.attack_damage)
		target_health.take_damage(_data.attack_damage)
	else:
		print("Combat: No health component found on target ", target.name)
	
	# Start cooldown
	_cooldown_timer = _data.attack_cooldown
	
	# Get target color from mesh
	var target_color := _get_target_color(target)
	
	# Spawn attack effect at target position with target's color
	_spawn_attack_effect(target.global_position, target_color)
	
	# Emit signal
	attack_performed.emit(target, _data.attack_damage)
	
	return true

## Check if attack is ready (not on cooldown)
func is_attack_ready() -> bool:
	return _cooldown_timer <= 0

## Get remaining cooldown time
func get_cooldown_remaining() -> float:
	return max(0.0, _cooldown_timer)

## Get cooldown progress (0.0 = ready, 1.0 = just attacked)
func get_cooldown_progress() -> float:
	if _data.attack_cooldown <= 0:
		return 0.0
	return clamp(_cooldown_timer / _data.attack_cooldown, 0.0, 1.0)

## Check if target is in attack range
func is_in_range(target: Node3D) -> bool:
	if not _owner_node or not target:
		return false
	var distance := _owner_node.global_position.distance_to(target.global_position)
	return distance <= _data.attack_range

## Get combat data model (for serialization)
func get_data() -> CombatData:
	return _data

## Set combat from data model (for deserialization)
func set_data(data: CombatData) -> void:
	_data = data
	attack_damage = _data.attack_damage
	attack_range = _data.attack_range
	attack_cooldown = _data.attack_cooldown

## Set attack damage (updates both exported var and internal data)
func set_attack_damage(value: int) -> void:
	attack_damage = value
	if _data:
		_data.attack_damage = value

## Find Node3D in parent hierarchy
func _find_node3d(node: Node) -> Node3D:
	if node is Node3D:
		return node
	if node.get_parent():
		return _find_node3d(node.get_parent())
	return null

## Find Health component in target node
func _find_health_component(node: Node) -> Health:
	print("Combat: Searching for Health component in ", node.name)
	print("Combat: Node has ", node.get_child_count(), " children")
	
	# Check direct children
	for child in node.get_children():
		print("Combat: Checking child: ", child.name, " type: ", child.get_class())
		if child is Health:
			print("Combat: Found Health component!")
			return child
		# Also check by class name string (fallback)
		if child.get_class() == "Health" or child.name == "Health":
			print("Combat: Found Health by name!")
			return child
	
	print("Combat: No Health component found")
	return null

## Spawn attack effect at position with color
func _spawn_attack_effect(position: Vector3, color: Color = Color.ORANGE) -> void:
	if not ATTACK_EFFECT:
		return
	
	var effect := ATTACK_EFFECT.instantiate()
	get_tree().root.add_child(effect)
	effect.global_position = position
	
	# Set particle color if the effect has the method
	if effect.has_method("set_particle_color"):
		effect.set_particle_color(color)

## Get target's color from its mesh
func _get_target_color(target: Node3D) -> Color:
	# Find MeshInstance3D in target
	for child in target.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			# Check for material override first
			var material := mesh_instance.get_surface_override_material(0)
			if material and material is StandardMaterial3D:
				return material.albedo_color
			# Check mesh material
			if mesh_instance.mesh:
				material = mesh_instance.mesh.surface_get_material(0)
				if material and material is StandardMaterial3D:
					return material.albedo_color
	
	# Default to orange if no color found
	return Color.ORANGE
