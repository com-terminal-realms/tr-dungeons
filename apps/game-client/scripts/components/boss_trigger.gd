## BossTrigger component
## Triggers boss battle music when player enters the area
class_name BossTrigger
extends Area3D

var _boss_music_playing: bool = false
var _main_scene: Node = null

func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Get reference to main scene
	_main_scene = get_tree().root.get_node_or_null("Main")
	if not _main_scene:
		push_warning("BossTrigger: Could not find Main scene")

func _on_body_entered(body: Node3D) -> void:
	# Check if player entered
	if body.is_in_group("player") or body.name == "Player":
		_start_boss_music()

func _on_body_exited(body: Node3D) -> void:
	# Check if player exited
	if body.is_in_group("player") or body.name == "Player":
		_stop_boss_music()

func _start_boss_music() -> void:
	if _boss_music_playing:
		return
	
	if _main_scene and _main_scene.has_method("play_boss_music"):
		_main_scene.play_boss_music()
		_boss_music_playing = true
		print("BossTrigger: Boss music started")

func _stop_boss_music() -> void:
	if not _boss_music_playing:
		return
	
	if _main_scene and _main_scene.has_method("stop_boss_music"):
		_main_scene.stop_boss_music()
		_boss_music_playing = false
		print("BossTrigger: Boss music stopped")
