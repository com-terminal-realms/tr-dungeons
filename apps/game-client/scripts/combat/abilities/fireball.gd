extends Ability
class_name Fireball

## Fireball ranged ability
## Spawns a projectile that travels toward target and deals damage on hit

@export var projectile_scene: PackedScene
@export var projectile_damage: float = 25.0
@export var projectile_speed: float = 15.0

var combat_component: CombatComponent = null

func _ready() -> void:
	super._ready()
	ability_name = "fireball"
	cooldown = 3.0
	mana_cost = 20.0
	cast_time = 0.4

func _execute() -> void:
	super._execute()
	
	if not combat_component:
		var parent := get_parent()
		if parent and parent.get_parent():
			combat_component = _find_combat_component(parent.get_parent())
	
	if not combat_component:
		return
	
	# Play cast animation
	if combat_component.animation_player and combat_component.animation_player.has_animation("cast"):
		combat_component.animation_player.play("cast")
		combat_component.animation_player.animation_finished.connect(_on_cast_finished, CONNECT_ONE_SHOT)
	
	# Spawn projectile
	_spawn_projectile()

## Spawn fireball projectile
func _spawn_projectile() -> void:
	if not combat_component:
		return
	
	var caster := combat_component.get_parent()
	if not caster is Node3D:
		return
	
	var caster_node := caster as Node3D
	
	# Create projectile
	var projectile: Projectile
	
	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		# Create basic projectile if no scene provided
		projectile = Projectile.new()
		
		# Add visual (sphere mesh)
		var mesh_instance := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		mesh_instance.mesh = sphere
		projectile.add_child(mesh_instance)
		
		# Add collision shape
		var collision_shape := CollisionShape3D.new()
		var sphere_shape := SphereShape3D.new()
		sphere_shape.radius = 0.2
		collision_shape.shape = sphere_shape
		projectile.add_child(collision_shape)
	
	# Configure projectile
	projectile.damage = projectile_damage
	projectile.speed = projectile_speed
	projectile.set_source(caster_node)
	
	# Set projectile position
	projectile.global_position = caster_node.global_position + Vector3(0, 1.0, 0)
	
	# Set projectile direction (forward from caster)
	var direction := -caster_node.global_transform.basis.z
	projectile.set_direction(direction)
	
	# Add to scene
	get_tree().root.add_child(projectile)

## Handle cast animation finished
func _on_cast_finished(_anim_name: String) -> void:
	if combat_component and combat_component.state_machine:
		combat_component.state_machine.transition_to(StateMachine.State.IDLE)

## Find CombatComponent in node hierarchy
func _find_combat_component(node: Node) -> CombatComponent:
	for child in node.get_children():
		if child is CombatComponent:
			return child
	return null
