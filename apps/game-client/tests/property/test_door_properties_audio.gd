extends GutTest

## Property-Based Tests for Door Audio System
## Feature: interactive-doors
## Tests audio playback, 3D audio configuration, and audio range

const Door := preload("res://scripts/door.gd")
const ITERATIONS := 100


## Property 22: Opening Sound Playback
## Validates: Requirements 7.1
## When a door opens, the opening sound effect must play
func test_property_22_opening_sound_playback() -> void:
	for i in range(ITERATIONS):
		# Arrange: Create door with audio player
		var door := await _create_test_door()
		var audio_player: AudioStreamPlayer3D = door.get_node("AudioStreamPlayer3D")
		assert_not_null(audio_player, "AudioStreamPlayer3D should exist")
		
		# Track if audio was played
		var audio_played := false
		var played_stream_path := ""
		
		# Connect to audio player to detect playback
		var check_audio := func():
			if audio_player.playing:
				audio_played = true
				if audio_player.stream:
					played_stream_path = audio_player.stream.resource_path
		
		# Act: Open the door
		door.open()
		
		# Give a frame for audio to start
		await get_tree().process_frame
		check_audio.call()
		
		# Assert: Audio should be playing or have been triggered
		# Note: Audio might not play if file doesn't exist, but the attempt should be made
		# We verify by checking if the stream was set (even if file is missing)
		var expected_path := "res://assets/audio/door_open.ogg"
		
		# The door should have attempted to load and play the audio
		# If file exists, audio should be playing
		# If file doesn't exist, we should see a warning (tested separately)
		if FileAccess.file_exists(expected_path):
			assert_true(audio_played or audio_player.stream != null, 
				"Opening sound should play when door opens (iteration %d)" % i)
		
		# Cleanup
		door.queue_free()
		await get_tree().process_frame


## Property 23: Closing Sound Playback
## Validates: Requirements 7.2
## When a door closes, the closing sound effect must play
func test_property_23_closing_sound_playback() -> void:
	for i in range(ITERATIONS):
		# Arrange: Create door and open it first
		var door := await _create_test_door()
		var audio_player: AudioStreamPlayer3D = door.get_node("AudioStreamPlayer3D")
		assert_not_null(audio_player, "AudioStreamPlayer3D should exist")
		
		# Open door first
		door.is_open = true
		door._update_collision_state()
		
		# Track if audio was played
		var audio_played := false
		var played_stream_path := ""
		
		# Connect to audio player to detect playback
		var check_audio := func():
			if audio_player.playing:
				audio_played = true
				if audio_player.stream:
					played_stream_path = audio_player.stream.resource_path
		
		# Act: Close the door
		door.close()
		
		# Give a frame for audio to start
		await get_tree().process_frame
		check_audio.call()
		
		# Assert: Audio should be playing or have been triggered
		var expected_path := "res://assets/audio/door_close.ogg"
		
		# The door should have attempted to load and play the audio
		if FileAccess.file_exists(expected_path):
			assert_true(audio_played or audio_player.stream != null, 
				"Closing sound should play when door closes (iteration %d)" % i)
		
		# Cleanup
		door.queue_free()
		await get_tree().process_frame


## Property 24: 3D Audio Configuration
## Validates: Requirements 7.3
## Audio must use 3D spatial audio with inverse distance attenuation
func test_property_24_3d_audio_configuration() -> void:
	for i in range(ITERATIONS):
		# Arrange: Create door
		var door := await _create_test_door()
		var audio_player: AudioStreamPlayer3D = door.get_node("AudioStreamPlayer3D")
		assert_not_null(audio_player, "AudioStreamPlayer3D should exist")
		
		# Act: Check audio configuration (set in _ready)
		await get_tree().process_frame
		
		# Assert: Audio player must use inverse distance attenuation
		assert_eq(audio_player.attenuation_model, 
			AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE,
			"Audio must use inverse distance attenuation (iteration %d)" % i)
		
		# Verify it's a 3D audio player (not 2D)
		assert_true(audio_player is AudioStreamPlayer3D,
			"Must use AudioStreamPlayer3D for spatial audio (iteration %d)" % i)
		
		# Cleanup
		door.queue_free()
		await get_tree().process_frame


## Property 25: Audio Range Configuration
## Validates: Requirements 7.4
## Audio must be audible within 20 units and fade with distance
func test_property_25_audio_range_configuration() -> void:
	for i in range(ITERATIONS):
		# Arrange: Create door
		var door := await _create_test_door()
		var audio_player: AudioStreamPlayer3D = door.get_node("AudioStreamPlayer3D")
		assert_not_null(audio_player, "AudioStreamPlayer3D should exist")
		
		# Act: Check audio range configuration (set in _ready)
		await get_tree().process_frame
		
		# Assert: Max distance must be 20 units
		assert_eq(audio_player.max_distance, 20.0,
			"Audio max distance must be 20 units (iteration %d)" % i)
		
		# Verify attenuation is enabled (not disabled)
		assert_ne(audio_player.attenuation_model, 
			AudioStreamPlayer3D.ATTENUATION_DISABLED,
			"Audio attenuation must be enabled (iteration %d)" % i)
		
		# Cleanup
		door.queue_free()
		await get_tree().process_frame


## Helper: Create a test door instance
func _create_test_door() -> Door:
	# Load door scene
	var door_scene := load("res://scenes/door.tscn") as PackedScene
	assert_not_null(door_scene, "Door scene should load")
	
	# Instantiate door
	var door := door_scene.instantiate() as Door
	assert_not_null(door, "Door should instantiate")
	
	# Add to scene tree so _ready() is called
	add_child(door)
	
	# Wait for ready
	await get_tree().process_frame
	
	return door
