extends SceneTree

## Script to generate corrected POC layout positions
## Based on measured asset metadata
## Run with: godot --headless --script scripts/utils/fix_poc_layout.gd

const METADATA_PATH = "res://data/asset_metadata.json"

var database: AssetMetadataDatabase

func _init():
	print("=== POC Layout Fix Calculator ===")
	print()
	
	# Load metadata database
	database = AssetMetadataDatabase.new()
	database.load_from_json(METADATA_PATH)
	
	if database.get_all_asset_names().is_empty():
		push_error("Failed to load asset metadata")
		quit(1)
		return
	
	# Get asset dimensions
	var corridor = database.get_metadata("corridor")
	var room_small = database.get_metadata("room-small")
	var room_wide = database.get_metadata("room-wide")
	var room_large = database.get_metadata("room-large")
	
	print("Asset Dimensions:")
	print("  corridor: %.2f × %.2f × %.2f" % [
		corridor.bounding_box.size.x,
		corridor.bounding_box.size.y,
		corridor.bounding_box.size.z
	])
	print("  room-small: %.2f × %.2f × %.2f" % [
		room_small.bounding_box.size.x,
		room_small.bounding_box.size.y,
		room_small.bounding_box.size.z
	])
	print("  room-wide: %.2f × %.2f × %.2f" % [
		room_wide.bounding_box.size.x,
		room_wide.bounding_box.size.y,
		room_wide.bounding_box.size.z
	])
	print("  room-large: %.2f × %.2f × %.2f" % [
		room_large.bounding_box.size.x,
		room_large.bounding_box.size.y,
		room_large.bounding_box.size.z
	])
	print()
	
	# Calculate corrected layout
	print("=== Corrected Layout ===")
	print()
	
	var z_pos = 0.0
	var corridor_size = corridor.bounding_box.size.z
	var corridor_half = corridor_size / 2.0
	
	# Room 1 (room-small)
	print("Room1 (room-small):")
	print("  Position: z=%.2f" % z_pos)
	var room1_half = room_small.bounding_box.size.z / 2.0
	z_pos += room1_half
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Corridor 1to2 (3 pieces)
	var corridor1_start = z_pos
	var corridor1_center = corridor1_start + (3 * corridor_size) / 2.0
	z_pos = corridor1_start + (3 * corridor_size)
	print("Corridor1to2 (3 pieces):")
	print("  Center: z=%.2f" % corridor1_center)
	print("  Pieces at offsets: -%.2f, 0, +%.2f" % [corridor_size, corridor_size])
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Room 2 (room-small)
	var room2_half = room_small.bounding_box.size.z / 2.0
	var room2_center = z_pos + room2_half
	z_pos += room_small.bounding_box.size.z
	print("Room2 (room-small):")
	print("  Position: z=%.2f" % room2_center)
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Corridor 2to3 (3 pieces)
	var corridor2_start = z_pos
	var corridor2_center = corridor2_start + (3 * corridor_size) / 2.0
	z_pos = corridor2_start + (3 * corridor_size)
	print("Corridor2to3 (3 pieces):")
	print("  Center: z=%.2f" % corridor2_center)
	print("  Pieces at offsets: -%.2f, 0, +%.2f" % [corridor_size, corridor_size])
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Room 3 (room-wide)
	var room3_half = room_wide.bounding_box.size.z / 2.0
	var room3_center = z_pos + room3_half
	z_pos += room_wide.bounding_box.size.z
	print("Room3 (room-wide):")
	print("  Position: z=%.2f" % room3_center)
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Corridor 3to4 (3 pieces)
	var corridor3_start = z_pos
	var corridor3_center = corridor3_start + (3 * corridor_size) / 2.0
	z_pos = corridor3_start + (3 * corridor_size)
	print("Corridor3to4 (3 pieces):")
	print("  Center: z=%.2f" % corridor3_center)
	print("  Pieces at offsets: -%.2f, 0, +%.2f" % [corridor_size, corridor_size])
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Room 4 (room-wide)
	var room4_half = room_wide.bounding_box.size.z / 2.0
	var room4_center = z_pos + room4_half
	z_pos += room_wide.bounding_box.size.z
	print("Room4 (room-wide):")
	print("  Position: z=%.2f" % room4_center)
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Corridor 4to5 (1 piece) - THIS IS THE FIX!
	var corridor4_start = z_pos
	var corridor4_center = corridor4_start + corridor_half
	z_pos = corridor4_start + corridor_size
	print("Corridor4to5 (1 piece) - FIXED:")
	print("  Center: z=%.2f" % corridor4_center)
	print("  Single piece at offset: 0")
	print("  End: z=%.2f" % z_pos)
	print()
	
	# Room 5 (room-large)
	var room5_half = room_large.bounding_box.size.z / 2.0
	var room5_center = z_pos + room5_half
	z_pos += room_large.bounding_box.size.z
	print("Room5 (room-large):")
	print("  Position: z=%.2f" % room5_center)
	print("  End: z=%.2f" % z_pos)
	print()
	
	print("=== Summary ===")
	print("Total dungeon length: %.2f units" % z_pos)
	print()
	print("Key changes:")
	print("  - Corridor4to5: Changed from 2 pieces to 1 piece")
	print("  - Corridor4to5 center: Changed from z=70 to z=%.2f" % corridor4_center)
	print()
	
	quit(0)
