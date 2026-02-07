## Attack effect particle system
## Auto-removes after animation completes
extends GPUParticles3D

func _ready() -> void:
	# Auto-remove after lifetime + small buffer
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = lifetime + 0.1
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()
