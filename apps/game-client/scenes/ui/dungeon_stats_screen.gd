extends Control
class_name DungeonStatsScreen

## Victory screen showing dungeon run statistics

@onready var stats_label: Label = $Panel/MarginContainer/VBoxContainer/StatsLabel
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	# Hide by default
	visible = false
	
	# Connect continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

## Show the stats screen with dungeon statistics
func show_stats(tracker: Node) -> void:
	if not tracker:
		return
	
	# Build stats text
	var stats_text := ""
	
	# Get session data
	var session_data: Dictionary = tracker.call("_get_player_session_data")
	var combat_data: Dictionary = tracker.call("_get_combat_data")
	
	var duration: float = session_data.get("duration_seconds", 0.0)
	var minutes := int(duration / 60.0)
	var seconds := int(duration) % 60
	
	stats_text += "=== DUNGEON COMPLETE ===\n\n"
	stats_text += "Duration: %d:%02d\n\n" % [minutes, seconds]
	
	stats_text += "--- COMBAT ---\n"
	stats_text += "Damage Dealt: %.0f\n" % combat_data.get("player_damage_dealt", 0.0)
	stats_text += "Damage Taken: %.0f\n" % combat_data.get("player_damage_taken", 0.0)
	stats_text += "Attacks: %d\n" % combat_data.get("player_attacks_made", 0)
	stats_text += "Hits: %d\n" % combat_data.get("player_attacks_hit", 0)
	stats_text += "Accuracy: %.1f%%\n\n" % _calculate_accuracy(combat_data)
	
	stats_text += "--- ENEMIES ---\n"
	stats_text += "Killed: %d\n" % combat_data.get("enemies_killed", 0)
	stats_text += "Boss Defeated: %s\n\n" % ("Yes" if combat_data.get("boss_killed", false) else "No")
	
	stats_text += "--- EXPLORATION ---\n"
	stats_text += "Rooms Visited: %d\n" % session_data.get("rooms_visited", []).size()
	stats_text += "Deaths: %d\n\n" % session_data.get("deaths", 0)
	
	stats_text += "--- LOOT ---\n"
	stats_text += "Gold: %d\n" % session_data.get("gold_collected", 0)
	stats_text += "Items: %d\n" % session_data.get("items_collected", []).size()
	
	if stats_label:
		stats_label.text = stats_text
	
	# Show the screen
	visible = true
	
	# Pause the game
	get_tree().paused = true

## Calculate accuracy percentage
func _calculate_accuracy(combat_data: Dictionary) -> float:
	var attacks_made: int = combat_data.get("player_attacks_made", 0)
	var attacks_hit: int = combat_data.get("player_attacks_hit", 0)
	
	if attacks_made == 0:
		return 0.0
	
	return (float(attacks_hit) / float(attacks_made)) * 100.0

## Handle continue button press
func _on_continue_pressed() -> void:
	# Unpause game
	get_tree().paused = false
	
	# Hide screen
	visible = false
	
	# Could reload scene or return to menu here
	# For now just hide the screen
