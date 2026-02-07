## Attack effect particle system
## Auto-removes after animation completes
extends GPUParticles3D

func _ready() -> void:
	# Start emitting
	emitting = true
	
	# Auto-remove after lifetime + small buffer
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()

## Set the particle color
func set_particle_color(color: Color) -> void:
	# Update the material color
	var material := draw_pass_1.surface_get_material(0) as StandardMaterial3D
	if material:
		material = material.duplicate()  # Duplicate to avoid affecting other instances
		material.albedo_color = color
		material.emission = color
		draw_pass_1.surface_set_material(0, material)
