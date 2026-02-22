extends Label3D
class_name DamageNumber

## Floating damage number that appears above targets
## Animates upward and fades out

var velocity: Vector3 = Vector3(0, 2, 0)
var lifetime: float = 1.0
var elapsed: float = 0.0

func _ready() -> void:
	# Set initial properties
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	elapsed += delta
	
	# Move upward
	global_position += velocity * delta
	
	# Fade out
	var alpha := 1.0 - (elapsed / lifetime)
	modulate.a = alpha
	
	# Remove when lifetime expires
	if elapsed >= lifetime:
		queue_free()

## Create and spawn a damage number at position
static func spawn(damage: float, position: Vector3, is_critical: bool = false) -> void:
	var damage_number := DamageNumber.new()
	damage_number.text = "%.0f" % damage
	damage_number.global_position = position + Vector3(0, 1, 0)
	
	# Critical hits are larger and yellow
	if is_critical:
		damage_number.modulate = Color(1.0, 1.0, 0.0, 1.0)
		damage_number.outline_modulate = Color(1.0, 0.5, 0.0, 1.0)
		damage_number.font_size = 64
	else:
		damage_number.modulate = Color(1.0, 0.0, 0.0, 1.0)
		damage_number.outline_modulate = Color(0.5, 0.0, 0.0, 1.0)
		damage_number.font_size = 48
	
	# Add to scene
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(damage_number)
