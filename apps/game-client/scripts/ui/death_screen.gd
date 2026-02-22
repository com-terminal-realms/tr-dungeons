extends Control
class_name DeathScreen

## Death screen UI displayed when player dies
## Shows combat statistics and respawn button

signal respawn_requested

@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var respawn_button: Button = $Panel/VBoxContainer/RespawnButton

var show_delay: float = 2.0

func _ready() -> void:
	hide()
	if respawn_button:
		respawn_button.pressed.connect(_on_respawn_pressed)

## Show death screen with combat statistics
func show_death_screen(stats: Dictionary = {}) -> void:
	# Update stats label
	if stats_label:
		var stats_text := "You Died!\n\n"
		if stats.has("damage_dealt"):
			stats_text += "Damage Dealt: %.0f\n" % stats.damage_dealt
		if stats.has("damage_taken"):
			stats_text += "Damage Taken: %.0f\n" % stats.damage_taken
		if stats.has("enemies_killed"):
			stats_text += "Enemies Killed: %d\n" % stats.enemies_killed
		stats_label.text = stats_text
	
	# Hide respawn button initially
	if respawn_button:
		respawn_button.visible = false
	
	# Show screen
	show()
	
	# Show respawn button after delay
	get_tree().create_timer(show_delay).timeout.connect(func():
		if respawn_button:
			respawn_button.visible = true
	)

## Hide death screen
func hide_death_screen() -> void:
	hide()

## Handle respawn button press
func _on_respawn_pressed() -> void:
	respawn_requested.emit()
	hide_death_screen()
