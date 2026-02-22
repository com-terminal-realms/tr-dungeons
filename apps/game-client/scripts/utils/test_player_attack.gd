extends SceneTree

## Test script to verify player attack animation

func _init():
	# Load player scene
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	
	# Get AnimationPlayer
	var anim_player = player.get_node("CharacterModel/AnimationPlayer")
	
	if not anim_player:
		print("ERROR: AnimationPlayer not found!")
		quit()
		return
	
	print("AnimationPlayer found!")
	print("Available animations: ", anim_player.get_animation_list())
	
	# Check if Sword_Attack exists
	if anim_player.has_animation("Sword_Attack"):
		print("✓ Sword_Attack animation exists")
		
		# Get animation details
		var anim = anim_player.get_animation("Sword_Attack")
		print("  Duration: ", anim.length, " seconds")
		print("  Track count: ", anim.get_track_count())
		
		# List all tracks
		for i in range(anim.get_track_count()):
			var track_path = anim.track_get_path(i)
			var track_type = anim.track_get_type(i)
			print("  Track ", i, ": ", track_path, " (type: ", track_type, ")")
	else:
		print("✗ Sword_Attack animation NOT found!")
	
	player.queue_free()
	quit()
