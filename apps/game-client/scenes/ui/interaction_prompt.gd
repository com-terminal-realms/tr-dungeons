extends Control

## Interaction Prompt UI
## Displays "Press E to Open/Close" when player is near a door

func _ready() -> void:
	# Initially hide the prompt
	hide()


## Show the interaction prompt
func show_prompt() -> void:
	show()


## Hide the interaction prompt
func hide_prompt() -> void:
	hide()
