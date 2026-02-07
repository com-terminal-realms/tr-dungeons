## Attack effect particle system
## Auto-removes after animation completes
extends GPUParticles3D

func _ready() -> void:
	# Start emitting
	emitting = true
	
	# Auto-remove after lifetime + small buffer
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
