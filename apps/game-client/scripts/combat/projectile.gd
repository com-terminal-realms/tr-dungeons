extends Area3D
class_name Projectile

## Projectile that moves and deals damage on collision
## Automatically destroys after hitting target or reaching max distance

signal hit(target: Node3D)
signal destroyed()

@export var damage: float = 25.0
@export var speed: float = 15.0
@export var max_distance: float = 20.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD
var source: Node = null
var distance_traveled: float = 0.0
var _lifetime_timer: float = 0.0

func _ready() -> void:
	# Connect area entered signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Set collision layer (Layer 6 for projectiles)
	collision_layer = 1 << 5  # Layer 6
	collision_mask = (1 << 2) | (1 << 0)  # Layers 3 (enemies) and 1 (world)
	
	_lifetime_timer = lifetime

func _physics_process(delta: float) -> void:
	# Move projectile
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	
	# Update lifetime
	_lifetime_timer -= delta
	
	# Check destruction conditions
	if distance_traveled >= max_distance or _lifetime_timer <= 0.0:
		_destroy()

## Set projectile direction
func set_direction(dir: Vector3) -> void:
	direction = dir.normalized()
	
	# Orient projectile to face direction
	if direction.length() > 0.001:
		look_at(global_position + direction, Vector3.UP)

## Set projectile source
func set_source(src: Node) -> void:
	source = src

## Handle area collision
func _on_area_entered(area: Area3D) -> void:
	# Check if this is a hurtbox
	if area is HurtboxArea3D:
		var hurtbox := area as HurtboxArea3D
		var target := hurtbox.get_parent()
		
		# Don't hit source
		if target == source:
			return
		
		# Deal damage
		if target and target.has_method("take_damage"):
			target.take_damage(damage, source)
		elif target:
			# Try to find combat component
			for child in target.get_children():
				if child is CombatComponent:
					child.take_damage(damage, source)
					break
		
		hit.emit(target)
		_destroy()

## Handle body collision (walls, etc.)
func _on_body_entered(_body: Node3D) -> void:
	_destroy()

## Destroy projectile
func _destroy() -> void:
	destroyed.emit()
	queue_free()
