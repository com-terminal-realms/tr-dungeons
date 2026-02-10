## Main scene controller
extends Node3D

# Audio players
var background_music: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var alert_sound: AudioStreamPlayer

func _ready() -> void:
	print("Main: Scene ready")
	
	# Set up audio players
	_setup_audio()
	
	# Get references
	var player = $Player
	var camera = $Camera
	var nav_region = $NavigationRegion3D
	
	print("Main: Player = ", player)
	print("Main: Camera = ", camera)
	print("Main: NavigationRegion3D = ", nav_region)
	
	if player and camera:
		# Manually set camera target
		camera.target = player
		print("Main: Camera target set to player")
	else:
		push_error("Main: Failed to find player or camera!")
	
	# Bake navigation mesh
	if nav_region:
		print("Main: Baking navigation mesh...")
		var nav_mesh = NavigationMesh.new()
		nav_mesh.cell_size = 0.25
		nav_mesh.cell_height = 0.2
		nav_mesh.agent_height = 2.0
		nav_mesh.agent_radius = 0.5
		nav_mesh.agent_max_climb = 0.5
		nav_mesh.agent_max_slope = 45.0
		nav_region.navigation_mesh = nav_mesh
		nav_region.bake_navigation_mesh()
		print("Main: Navigation mesh baked!")
	else:
		push_error("Main: NavigationRegion3D not found!")
	
	# Place doors at all connection points
	if nav_region:
		print("Main: Placing doors...")
		DoorManager.place_doors_at_connections(nav_region)
		print("Main: Door placement complete!")
	
	# Set up interaction prompt UI
	_setup_interaction_prompt()


## Set up audio players for background music and sound effects
func _setup_audio() -> void:
	# Create background music player
	background_music = AudioStreamPlayer.new()
	background_music.name = "BackgroundMusic"
	background_music.bus = "Master"
	add_child(background_music)
	
	# Load and play dungeon ambient music
	var ambient_music = load("res://assets/audio/music/dungeon_ambient.ogg") as AudioStream
	if ambient_music:
		background_music.stream = ambient_music
		background_music.volume_db = -10.0  # Slightly quieter
		background_music.autoplay = false
		background_music.stream_paused = false
		# Enable looping by setting the stream loop mode
		if ambient_music is AudioStreamOggVorbis:
			ambient_music.loop = true
		background_music.play()
		print("Main: Background music started")
	else:
		push_warning("Main: Failed to load background music")
	
	# Create boss battle music player (not playing by default)
	boss_music = AudioStreamPlayer.new()
	boss_music.name = "BossBattleMusic"
	boss_music.bus = "Master"
	add_child(boss_music)
	
	var boss_stream = load("res://assets/audio/music/boss_battle.ogg") as AudioStream
	if boss_stream:
		boss_music.stream = boss_stream
		boss_music.volume_db = -8.0
		if boss_stream is AudioStreamOggVorbis:
			boss_stream.loop = true
		print("Main: Boss battle music loaded")
	
	# Create monster alert sound player
	alert_sound = AudioStreamPlayer.new()
	alert_sound.name = "MonsterAlert"
	alert_sound.bus = "Master"
	add_child(alert_sound)
	
	var alert_stream = load("res://assets/audio/music/monster_alert.ogg") as AudioStream
	if alert_stream:
		alert_sound.stream = alert_stream
		alert_sound.volume_db = -5.0
		# Alert sound should NOT loop
		if alert_stream is AudioStreamOggVorbis:
			alert_stream.loop = false
		print("Main: Monster alert sound loaded")


## Play boss battle music (stops background music)
func play_boss_music() -> void:
	if background_music and background_music.playing:
		background_music.stop()
	if boss_music:
		boss_music.play()
		print("Main: Boss battle music started")


## Stop boss music and resume background music
func stop_boss_music() -> void:
	if boss_music and boss_music.playing:
		boss_music.stop()
	if background_music:
		background_music.play()
		print("Main: Background music resumed")


## Play monster alert sound (doesn't stop music)
func play_monster_alert() -> void:
	if alert_sound:
		alert_sound.play()
		print("Main: Monster alert sound played")



## Handle input for testing audio
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		
		# Press B to toggle boss music
		if key_event.keycode == KEY_B:
			if boss_music and boss_music.playing:
				stop_boss_music()
			else:
				play_boss_music()
		
		# Press M to play monster alert sound
		elif key_event.keycode == KEY_M:
			play_monster_alert()
		
		# Press N to toggle background music
		elif key_event.keycode == KEY_N:
			if background_music:
				if background_music.playing:
					background_music.stop()
					print("Main: Background music stopped")
				else:
					background_music.play()
					print("Main: Background music started")



## Set up interaction prompt UI for doors
func _setup_interaction_prompt() -> void:
	# Load and instantiate the interaction prompt scene
	var prompt_scene := load("res://scenes/ui/interaction_prompt.tscn") as PackedScene
	if prompt_scene:
		var prompt := prompt_scene.instantiate()
		add_child(prompt)
		DoorManager.set_interaction_prompt(prompt)
		print("Main: Interaction prompt UI created and connected to DoorManager")
	else:
		push_warning("Main: Failed to load interaction prompt scene")
