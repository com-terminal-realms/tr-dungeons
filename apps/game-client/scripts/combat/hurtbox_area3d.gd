extends Area3D
class_name HurtboxArea3D

## Hurtbox for receiving damage from hitboxes
## Signals parent CombatComponent when hit
## Configured with collision masks to only receive damage from appropriate sources

signal hit_received(hitbox: HitboxArea3D)

func _ready() -> void:
	# Connect to area_entered signal
	area_entered.connect(_on_area_entered)
	
	# Enable monitoring
	monitoring = true
	monitorable = true

func _on_area_entered(area: Area3D) -> void:
	# Check if this is a hitbox
	if area is HitboxArea3D:
		var hitbox := area as HitboxArea3D
		hit_received.emit(hitbox)
		
		# Notify parent CombatComponent if it exists
		var parent := get_parent()
		if parent and parent.has_method("_on_hurtbox_hit"):
			parent._on_hurtbox_hit(hitbox)
