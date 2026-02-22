extends Node
class_name DungeonStatsTracker

## Tracks all combat and dungeon statistics for database storage
## Singleton pattern - access via DungeonStatsTracker.instance

static var instance: DungeonStatsTracker = null

# Session data
var session_id: String = ""
var session_start_time: float = 0.0
var session_end_time: float = 0.0

# Player stats
var player_damage_dealt: float = 0.0
var player_damage_taken: float = 0.0
var player_deaths: int = 0
var player_heals_used: int = 0
var player_attacks_made: int = 0
var player_attacks_hit: int = 0
var player_attacks_missed: int = 0

# Enemy stats
var enemies_killed: int = 0
var enemies_encountered: int = 0
var boss_killed: bool = false

# Room stats
var rooms_visited: Array[String] = []
var current_room: String = ""

# Combat events (for CombatEventModel)
var combat_events: Array[Dictionary] = []

# Loot collected
var gold_collected: int = 0
var items_collected: Array[Dictionary] = []

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# Generate session ID
	session_id = _generate_session_id()
	session_start_time = Time.get_unix_time_from_system()
	
	print("DungeonStatsTracker: Session started - ID: ", session_id)

## Generate unique session ID
func _generate_session_id() -> String:
	var timestamp := Time.get_unix_time_from_system()
	var random_suffix := randi() % 10000
	return "session_%d_%04d" % [int(timestamp), random_suffix]

## Record player attack
func record_player_attack(hit: bool, damage: float, target_name: String) -> void:
	player_attacks_made += 1
	if hit:
		player_attacks_hit += 1
		player_damage_dealt += damage
		
		# Record combat event
		_add_combat_event({
			"event_type": "player_attack_hit",
			"damage": damage,
			"target": target_name,
			"timestamp": Time.get_unix_time_from_system()
		})
	else:
		player_attacks_missed += 1
		
		_add_combat_event({
			"event_type": "player_attack_miss",
			"target": target_name,
			"timestamp": Time.get_unix_time_from_system()
		})

## Record player taking damage
func record_player_damage(damage: float, source_name: String) -> void:
	player_damage_taken += damage
	
	_add_combat_event({
		"event_type": "player_damaged",
		"damage": damage,
		"source": source_name,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record player death
func record_player_death() -> void:
	player_deaths += 1
	
	_add_combat_event({
		"event_type": "player_death",
		"room": current_room,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record player heal
func record_player_heal(amount: float) -> void:
	player_heals_used += 1
	
	_add_combat_event({
		"event_type": "player_heal",
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record enemy killed
func record_enemy_killed(enemy_name: String, is_boss: bool = false) -> void:
	enemies_killed += 1
	if is_boss:
		boss_killed = true
		# Trigger victory screen
		_show_victory_screen()
	
	_add_combat_event({
		"event_type": "enemy_killed",
		"enemy_name": enemy_name,
		"is_boss": is_boss,
		"room": current_room,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record enemy encountered
func record_enemy_encountered(enemy_name: String) -> void:
	enemies_encountered += 1
	
	_add_combat_event({
		"event_type": "enemy_encountered",
		"enemy_name": enemy_name,
		"room": current_room,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record room entered
func record_room_entered(room_name: String) -> void:
	current_room = room_name
	if not rooms_visited.has(room_name):
		rooms_visited.append(room_name)
	
	_add_combat_event({
		"event_type": "room_entered",
		"room": room_name,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record gold collected
func record_gold_collected(amount: int) -> void:
	gold_collected += amount
	
	_add_combat_event({
		"event_type": "gold_collected",
		"amount": amount,
		"room": current_room,
		"timestamp": Time.get_unix_time_from_system()
	})

## Record item collected
func record_item_collected(item_data: Dictionary) -> void:
	items_collected.append(item_data)
	
	_add_combat_event({
		"event_type": "item_collected",
		"item": item_data,
		"room": current_room,
		"timestamp": Time.get_unix_time_from_system()
	})

## End session and display stats
func end_session() -> void:
	session_end_time = Time.get_unix_time_from_system()
	var duration := session_end_time - session_start_time
	
	print("\n" + "=".repeat(60))
	print("DUNGEON RUN COMPLETE - SESSION STATS")
	print("=".repeat(60))
	print("\nSession ID: ", session_id)
	print("Duration: %.1f seconds (%.1f minutes)" % [duration, duration / 60.0])
	print("\n--- PLAYER STATS ---")
	print("Damage Dealt: %.1f" % player_damage_dealt)
	print("Damage Taken: %.1f" % player_damage_taken)
	print("Deaths: %d" % player_deaths)
	print("Heals Used: %d" % player_heals_used)
	print("Attacks Made: %d" % player_attacks_made)
	print("Attacks Hit: %d (%.1f%%)" % [player_attacks_hit, _get_hit_percentage()])
	print("Attacks Missed: %d" % player_attacks_missed)
	print("\n--- ENEMY STATS ---")
	print("Enemies Encountered: %d" % enemies_encountered)
	print("Enemies Killed: %d" % enemies_killed)
	print("Boss Killed: %s" % ("Yes" if boss_killed else "No"))
	print("\n--- EXPLORATION ---")
	print("Rooms Visited: %d" % rooms_visited.size())
	print("Room List: %s" % str(rooms_visited))
	print("\n--- LOOT ---")
	print("Gold Collected: %d" % gold_collected)
	print("Items Collected: %d" % items_collected.size())
	print("\n--- DATABASE PAYLOAD ---")
	print("Combat Events Recorded: %d" % combat_events.size())
	print("\nPlayerSessionModel data:")
	print(JSON.stringify(_get_player_session_data(), "  "))
	print("\nCombatDataModel data:")
	print(JSON.stringify(_get_combat_data(), "  "))
	print("\n" + "=".repeat(60))

## Get hit percentage
func _get_hit_percentage() -> float:
	if player_attacks_made == 0:
		return 0.0
	return (float(player_attacks_hit) / float(player_attacks_made)) * 100.0

## Add combat event
func _add_combat_event(event: Dictionary) -> void:
	combat_events.append(event)

## Get player session data (for PlayerSessionModel)
func _get_player_session_data() -> Dictionary:
	return {
		"session_id": session_id,
		"player_id": "player_001",  # TODO: Get from player system
		"start_time": session_start_time,
		"end_time": session_end_time,
		"duration_seconds": session_end_time - session_start_time,
		"rooms_visited": rooms_visited,
		"enemies_killed": enemies_killed,
		"deaths": player_deaths,
		"gold_collected": gold_collected,
		"items_collected": items_collected,
		"completed": boss_killed
	}

## Get combat data (for CombatDataModel)
func _get_combat_data() -> Dictionary:
	return {
		"session_id": session_id,
		"player_damage_dealt": player_damage_dealt,
		"player_damage_taken": player_damage_taken,
		"player_attacks_made": player_attacks_made,
		"player_attacks_hit": player_attacks_hit,
		"player_attacks_missed": player_attacks_missed,
		"enemies_killed": enemies_killed,
		"boss_killed": boss_killed,
		"combat_events": combat_events
	}

## Get all combat events (for CombatEventModel array)
func get_combat_events() -> Array[Dictionary]:
	return combat_events

## Show victory screen with stats
func _show_victory_screen() -> void:
	# End the session
	session_end_time = Time.get_unix_time_from_system()
	
	# Find or create the stats screen
	var stats_screen: Control = null
	
	# Check if it already exists in the scene
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		stats_screen = main.get_node_or_null("DungeonStatsScreen")
	
	# If not found, instantiate it
	if not stats_screen:
		var stats_screen_scene := load("res://scenes/ui/dungeon_stats_screen.tscn") as PackedScene
		if stats_screen_scene:
			stats_screen = stats_screen_scene.instantiate()
			if main:
				main.add_child(stats_screen)
			else:
				get_tree().root.add_child(stats_screen)
	
	# Show the stats
	if stats_screen and stats_screen.has_method("show_stats"):
		stats_screen.show_stats(self)
	
	# Also print to console for debugging
	print("\n" + "=".repeat(60))
	print("BOSS DEFEATED - DUNGEON COMPLETE!")
	print("=".repeat(60))
	end_session()
