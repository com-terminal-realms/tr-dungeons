## Enemy base script
## Handles enemy death and removal from scene
extends CharacterBody3D

@export var is_boss: bool = false  # Mark this enemy as a boss

var _health: Health
var _boss_music_started: bool = false

func _ready() -> void:
	# Get component references
	_health = $Health
	
	# Connect to death signal for removal
	if _health:
		_health.died.connect(_on_death)
	
	# If this is a boss, start boss music when player gets close
	if is_boss:
		# Add to boss group for easy identification
		add_to_group("boss")
		print("Enemy: This is a BOSS enemy - will trigger boss music")
	else:
		print("Enemy: This is a regular enemy - no boss music")

## Handle death and remove from scene
func _on_death() -> void:
	print("Enemy: Died! Removing from scene...")
	
	# If this was a boss, stop boss music
	if is_boss:
		_stop_boss_music()
	
	# Remove enemy from scene
	queue_free()


func _physics_process(_delta: float) -> void:
	# If this is a boss and hasn't started music yet, check if player is nearby
	if is_boss and not _boss_music_started:
		var player = _find_player()
		if player:
			var distance = global_position.distance_to(player.global_position)
			# Start boss music when player gets within 15 units
			if distance <= 15.0:
				_start_boss_music()

## Find player in scene
func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node3D:
		return players[0]
	return null

## Start boss battle music
func _start_boss_music() -> void:
	if _boss_music_started:
		print("Boss (%s): Music already started, skipping" % name)
		return
	
	# Check if another boss already started music
	var bosses = get_tree().get_nodes_in_group("boss")
	for boss in bosses:
		if boss != self and boss.has("_boss_music_started") and boss._boss_music_started:
			print("Boss (%s): Another boss already playing music, skipping" % name)
			return
	
	print("=== Boss (%s): Starting boss battle music ===" % name)
	var main_scene := get_tree().root.get_node_or_null("Main")
	if main_scene and main_scene.has_method("play_boss_music"):
		main_scene.play_boss_music()
		_boss_music_started = true
		print("Boss (%s): Boss music started successfully" % name)
	else:
		print("Boss (%s): ERROR - Could not find Main scene or play_boss_music method" % name)

## Stop boss battle music
func _stop_boss_music() -> void:
	if not _boss_music_started:
		print("Boss (%s): Music not started, nothing to stop" % name)
		return
	
	print("=== Boss (%s): Stopping boss battle music ===" % name)
	var main_scene := get_tree().root.get_node_or_null("Main")
	if main_scene and main_scene.has_method("stop_boss_music"):
		main_scene.stop_boss_music()
		_boss_music_started = false
		print("Boss (%s): Boss music stopped successfully" % name)
	else:
		print("Boss (%s): ERROR - Could not find Main scene or stop_boss_music method" % name)
