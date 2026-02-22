## Detection indicator for enemies
## Shows "Attacking!" text that fades away
extends Label3D

@export var offset_y: float = 2.5  # Height above enemy
@export var display_duration: float = 1.0  # How long to show before fading

var elapsed: float = 0.0
var is_showing: bool = false

func _ready() -> void:
	# Set up label properties
	text = "Attacking!"
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	font_size = 48
	modulate = Color(1.0, 0.3, 0.0, 0.0)  # Orange color, start invisible
	outline_modulate = Color(0.5, 0.0, 0.0, 1.0)
	outline_size = 8
	visible = false

func _process(delta: float) -> void:
	if not is_showing:
		return
	
	elapsed += delta
	
	# Position above parent
	if get_parent() is Node3D:
		position = Vector3(0, offset_y, 0)
	
	# Fade in quickly (first 0.2 seconds)
	if elapsed < 0.2:
		var alpha := elapsed / 0.2
		modulate.a = alpha
	# Stay visible
	elif elapsed < display_duration:
		modulate.a = 1.0
	# Fade out (last 0.5 seconds)
	else:
		var fade_time := elapsed - display_duration
		var alpha := 1.0 - (fade_time / 0.5)
		modulate.a = max(0.0, alpha)
		
		# Hide when fully faded
		if alpha <= 0.0:
			hide_indicator()

## Show the indicator
func show_indicator() -> void:
	visible = true
	is_showing = true
	elapsed = 0.0
	modulate.a = 0.0

## Hide the indicator
func hide_indicator() -> void:
	visible = false
	is_showing = false
	elapsed = 0.0
