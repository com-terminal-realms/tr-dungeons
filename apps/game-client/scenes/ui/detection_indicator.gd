## Detection indicator for enemies
## Shows/hides based on enemy AI state
extends MeshInstance3D

@export var offset_y: float = 2.0  # Height above enemy

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	# Position above parent
	if get_parent() is Node3D:
		position = Vector3(0, offset_y, 0)

## Show the indicator
func show_indicator() -> void:
	visible = true

## Hide the indicator
func hide_indicator() -> void:
	visible = false
