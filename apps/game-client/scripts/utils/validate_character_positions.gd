extends SceneTree

## Validate that all characters in the POC are at correct floor height
## This should be run whenever characters or rooms are added/modified

const METADATA_PATH = "res://data/asset_metadata.json"
const CHARACTER_METADATA_PATH = "res://data/character_metadata.json"

var database: AssetMetadataDatabase
var character_database: CharacterMetadataDatabase
var calculator: LayoutCalculator

func _init():
	print("\n=== Character Floor Position Validation ===\n")
	
	# Load metadata databases
	database = AssetMetadataDatabase.new()
	database.load_from_json(METADATA_PATH)
	
	character_database = CharacterMetadataDatabase.new()
	var load_result = character_database.load_from_json(CHARACTER_METADATA_PATH)
	if load_result != OK:
		push_error("Failed to load character metadata. Run measure_all_characters.gd first!")
		quit(1)
		return
	
	calculator = LayoutCalculator.new(database)
	
	# Load the main scene
	var main_scene = load("res://scenes/main.tscn")
	if main_scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return
	
	var scene_instance = main_scene.instantiate()
	
	# Add to scene tree so global_position works
	root.add_child(scene_instance)
	await process_frame
	
	# Build layout from scene
	var layout = _extract_layout_from_scene(scene_instance)
	print("Found %d assets in layout\n" % layout.size())
	
	# Extract characters from scene
	var characters = _extract_characters_from_scene(scene_instance)
	print("Found %d characters in scene\n" % characters.size())
	
	# Validate character positioning
	var result = calculator.validate_character_positioning(layout, characters)
	
	# Report results
	print("=== Validation Results ===\n")
	
	if result.is_valid:
		print("✅ ALL CHARACTERS CORRECTLY POSITIONED")
		print("\nAll characters are at the correct floor height!")
		quit(0)
	else:
		print("❌ CHARACTER POSITIONING ERRORS FOUND\n")
		
		for error in result.error_messages:
			print("  • %s" % error)
		
		print("\n=== Fix Instructions ===")
		print("Update the following character positions in scenes/main.tscn:\n")
		
		for character in characters:
			var containing_asset = calculator._find_containing_asset(character.position, layout)
			if containing_asset:
				var expected_y = containing_asset.metadata.floor_height + character.height_offset
				if abs(character.position.y - expected_y) > 0.1:
					print("  %s: Change y from %.2f to %.2f" % [
						character.name,
						character.position.y,
						expected_y
					])
		
		quit(1)

func _extract_layout_from_scene(scene: Node) -> Array[PlacedAsset]:
	var layout: Array[PlacedAsset] = []
	
	var nav_region = scene.get_node_or_null("NavigationRegion3D")
	if nav_region == null:
		push_error("NavigationRegion3D not found in scene")
		return layout
	
	# Extract rooms
	for room_name in ["Room1", "Room2", "Room3", "Room4", "Room5"]:
		var room_node = nav_region.get_node_or_null(room_name)
		if room_node:
			var metadata = database.get_metadata("room-large")
			if metadata:
				var placed = PlacedAsset.new()
				placed.metadata = metadata
				placed.position = room_node.global_position
				placed.rotation = room_node.rotation_degrees
				layout.append(placed)
				print("  Found %s at z=%.2f" % [room_name, placed.position.z])
	
	# Extract corridors (for completeness, though characters shouldn't be in corridors)
	for corridor_name in ["Corridor1to2", "Corridor2to3", "Corridor3to4", "Corridor4to5"]:
		var corridor_node = nav_region.get_node_or_null(corridor_name)
		if corridor_node:
			var metadata = database.get_metadata("corridor")
			if metadata:
				var placed = PlacedAsset.new()
				placed.metadata = metadata
				placed.position = corridor_node.global_position
				placed.rotation = corridor_node.rotation_degrees
				layout.append(placed)
	
	return layout

func _extract_characters_from_scene(scene: Node) -> Array[LayoutCalculator.PlacedCharacter]:
	var characters: Array[LayoutCalculator.PlacedCharacter] = []
	
	# Extract player
	var player = scene.get_node_or_null("Player")
	if player:
		var player_metadata = character_database.get_character("player")
		var floor_offset = player_metadata.floor_offset if player_metadata else 1.004
		
		var char = LayoutCalculator.PlacedCharacter.new(
			"Player",
			player.global_position,
			floor_offset
		)
		characters.append(char)
		print("  Found Player at (%.2f, %.2f, %.2f), floor_offset=%.4f" % [
			char.position.x, char.position.y, char.position.z, floor_offset
		])
	
	# Extract enemies from rooms
	var nav_region = scene.get_node_or_null("NavigationRegion3D")
	if nav_region:
		var enemy_metadata = character_database.get_character("enemy")
		var enemy_floor_offset = enemy_metadata.floor_offset if enemy_metadata else 0.01
		
		# Room3 - Enemy1
		var room3 = nav_region.get_node_or_null("Room3")
		if room3:
			var enemy1 = room3.get_node_or_null("Enemy1")
			if enemy1:
				var char = LayoutCalculator.PlacedCharacter.new(
					"Enemy1 (Room3)",
					enemy1.global_position,
					enemy_floor_offset
				)
				characters.append(char)
				print("  Found Enemy1 (Room3) at (%.2f, %.2f, %.2f), floor_offset=%.4f" % [
					char.position.x, char.position.y, char.position.z, enemy_floor_offset
				])
		
		# Room4 - Enemy1 and Enemy2
		var room4 = nav_region.get_node_or_null("Room4")
		if room4:
			var enemy1 = room4.get_node_or_null("Enemy1")
			if enemy1:
				var char = LayoutCalculator.PlacedCharacter.new(
					"Enemy1 (Room4)",
					enemy1.global_position,
					enemy_floor_offset
				)
				characters.append(char)
				print("  Found Enemy1 (Room4) at (%.2f, %.2f, %.2f), floor_offset=%.4f" % [
					char.position.x, char.position.y, char.position.z, enemy_floor_offset
				])
			
			var enemy2 = room4.get_node_or_null("Enemy2")
			if enemy2:
				var char = LayoutCalculator.PlacedCharacter.new(
					"Enemy2 (Room4)",
					enemy2.global_position,
					enemy_floor_offset
				)
				characters.append(char)
				print("  Found Enemy2 (Room4) at (%.2f, %.2f, %.2f), floor_offset=%.4f" % [
					char.position.x, char.position.y, char.position.z, enemy_floor_offset
				])
		
		# Room5 - Boss
		var room5 = nav_region.get_node_or_null("Room5")
		if room5:
			var boss = room5.get_node_or_null("Boss")
			if boss:
				var char = LayoutCalculator.PlacedCharacter.new(
					"Boss (Room5)",
					boss.global_position,
					enemy_floor_offset
				)
				characters.append(char)
				print("  Found Boss (Room5) at (%.2f, %.2f, %.2f), floor_offset=%.4f" % [
					char.position.x, char.position.y, char.position.z, enemy_floor_offset
				])
	
	return characters
	
	return characters
