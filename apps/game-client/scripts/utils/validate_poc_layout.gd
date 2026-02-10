extends SceneTree

## Script to validate the POC dungeon layout using measured asset metadata
## Checks for proper alignment, gaps, and overlaps
## Run with: godot --headless --script scripts/utils/validate_poc_layout.gd

const METADATA_PATH = "res://data/asset_metadata.json"
const TOLERANCE = 0.1  # ±0.1 units for connection alignment

# Current layout from main.tscn
const LAYOUT = {
	"Room1": {"z": 0, "asset": "room-small"},
	"Corridor1to2": {"z": 12, "pieces": 3, "offsets": [-4, 0, 4]},
	"Room2": {"z": 24, "asset": "room-small"},
	"Corridor2to3": {"z": 36, "pieces": 3, "offsets": [-4, 0, 4]},
	"Room3": {"z": 48, "asset": "room-wide"},
	"Corridor3to4": {"z": 60, "pieces": 3, "offsets": [-4, 0, 4]},
	"Room4": {"z": 72, "asset": "room-wide"},
	"Corridor4to5": {"z": 80, "pieces": 1, "offsets": [0]},
	"Room5": {"z": 92, "asset": "room-large"}
}

var database: AssetMetadataDatabase
var issues: Array[String] = []
var warnings: Array[String] = []

func _init():
	print("=== POC Layout Validation ===")
	print()
	
	# Load metadata database
	database = AssetMetadataDatabase.new()
	database.load_from_json(METADATA_PATH)
	
	if database.get_all_asset_names().is_empty():
		push_error("Failed to load asset metadata from: %s" % METADATA_PATH)
		quit(1)
		return
	
	print("Loaded metadata for %d assets" % database.get_all_asset_names().size())
	print()
	
	# Validate each connection
	_validate_connection("Room1", "Corridor1to2")
	_validate_connection("Corridor1to2", "Room2")
	_validate_connection("Room2", "Corridor2to3")
	_validate_connection("Corridor2to3", "Room3")
	_validate_connection("Room3", "Corridor3to4")
	_validate_connection("Corridor3to4", "Room4")
	_validate_connection("Room4", "Corridor4to5")
	_validate_connection("Corridor4to5", "Room5")
	
	# Print results
	print()
	print("=== Validation Results ===")
	print()
	
	if issues.is_empty() and warnings.is_empty():
		print("✓ All connections are valid!")
		print("  No gaps or overlaps detected.")
	else:
		if not issues.is_empty():
			print("❌ ISSUES FOUND (%d):" % issues.size())
			for issue in issues:
				print("  - %s" % issue)
			print()
		
		if not warnings.is_empty():
			print("⚠ WARNINGS (%d):" % warnings.size())
			for warning in warnings:
				print("  - %s" % warning)
			print()
	
	# Print recommendations
	if not issues.is_empty():
		print("=== Recommendations ===")
		print()
		_print_recommendations()
	
	quit(0 if issues.is_empty() else 1)

func _validate_connection(from_name: String, to_name: String) -> void:
	print("Validating: %s → %s" % [from_name, to_name])
	
	var from_data = LAYOUT.get(from_name)
	var to_data = LAYOUT.get(to_name)
	
	if from_data == null or to_data == null:
		issues.append("Missing layout data for %s or %s" % [from_name, to_name])
		return
	
	# Calculate connection points
	var from_end_z: float
	var to_start_z: float
	
	# From element's end point
	if "asset" in from_data:
		# It's a room
		var metadata = database.get_metadata(from_data.asset)
		if metadata == null:
			issues.append("Missing metadata for asset: %s" % from_data.asset)
			return
		
		var room_half_size = metadata.bounding_box.size.z / 2.0
		from_end_z = from_data.z + room_half_size
		print("  %s (room): z=%s, half_size=%.2f, end_z=%.2f" % [
			from_name, from_data.z, room_half_size, from_end_z
		])
	else:
		# It's a corridor
		var corridor_metadata = database.get_metadata("corridor")
		if corridor_metadata == null:
			issues.append("Missing metadata for corridor asset")
			return
		
		var corridor_size = corridor_metadata.bounding_box.size.z
		var last_offset = from_data.offsets[-1]
		var corridor_half_size = corridor_size / 2.0
		from_end_z = from_data.z + last_offset + corridor_half_size
		print("  %s (corridor): z=%s, last_offset=%s, half_size=%.2f, end_z=%.2f" % [
			from_name, from_data.z, last_offset, corridor_half_size, from_end_z
		])
	
	# To element's start point
	if "asset" in to_data:
		# It's a room
		var metadata = database.get_metadata(to_data.asset)
		if metadata == null:
			issues.append("Missing metadata for asset: %s" % to_data.asset)
			return
		
		var room_half_size = metadata.bounding_box.size.z / 2.0
		to_start_z = to_data.z - room_half_size
		print("  %s (room): z=%s, half_size=%.2f, start_z=%.2f" % [
			to_name, to_data.z, room_half_size, to_start_z
		])
	else:
		# It's a corridor
		var corridor_metadata = database.get_metadata("corridor")
		if corridor_metadata == null:
			issues.append("Missing metadata for corridor asset")
			return
		
		var corridor_size = corridor_metadata.bounding_box.size.z
		var first_offset = to_data.offsets[0]
		var corridor_half_size = corridor_size / 2.0
		to_start_z = to_data.z + first_offset - corridor_half_size
		print("  %s (corridor): z=%s, first_offset=%s, half_size=%.2f, start_z=%.2f" % [
			to_name, to_data.z, first_offset, corridor_half_size, to_start_z
		])
	
	# Calculate gap/overlap
	var gap = to_start_z - from_end_z
	print("  Gap/Overlap: %.2f units" % gap)
	
	# Validate
	if abs(gap) <= TOLERANCE:
		print("  ✓ Connection is valid (within tolerance)")
	elif gap > TOLERANCE:
		issues.append("%s → %s: GAP of %.2f units (should be ≤%.2f)" % [
			from_name, to_name, gap, TOLERANCE
		])
		print("  ❌ GAP detected!")
	else:
		issues.append("%s → %s: OVERLAP of %.2f units (should be ≥-%.2f)" % [
			from_name, to_name, abs(gap), TOLERANCE
		])
		print("  ❌ OVERLAP detected!")
	
	print()

func _print_recommendations() -> void:
	print("Based on measured asset dimensions:")
	print()
	
	var corridor_meta = database.get_metadata("corridor")
	var room_small_meta = database.get_metadata("room-small")
	var room_large_meta = database.get_metadata("room-large")
	
	if corridor_meta:
		print("Corridor dimensions: %.2f × %.2f × %.2f" % [
			corridor_meta.bounding_box.size.x,
			corridor_meta.bounding_box.size.y,
			corridor_meta.bounding_box.size.z
		])
	
	if room_small_meta:
		print("Room-small dimensions: %.2f × %.2f × %.2f" % [
			room_small_meta.bounding_box.size.x,
			room_small_meta.bounding_box.size.y,
			room_small_meta.bounding_box.size.z
		])
	
	if room_large_meta:
		print("Room-large dimensions: %.2f × %.2f × %.2f" % [
			room_large_meta.bounding_box.size.x,
			room_large_meta.bounding_box.size.y,
			room_large_meta.bounding_box.size.z
		])
	
	print()
	print("Suggested fixes:")
	print("1. Corridor pieces are 4×4 units (square), not long hallways")
	print("2. Consider using different corridor spacing or fewer pieces")
	print("3. Adjust room positions to account for actual asset sizes")
