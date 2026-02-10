extends SceneTree

## Review POC layout using the new position-from-count algorithm
## This script validates the current POC layout and shows what positions
## would be calculated using the new algorithm

func _init():
	# Load metadata database
	var metadata_db = AssetMetadataDatabase.new()
	metadata_db.load_from_json("res://data/asset_metadata.json")
	
	# Create layout calculator
	var calculator = LayoutCalculator.new(metadata_db)
	
	# Get corridor metadata
	var corridor_meta = metadata_db.get_metadata("corridor")
	if corridor_meta == null:
		print("❌ ERROR: Could not load corridor metadata")
		quit()
		return
	
	print("================================================================================")
	print("POC LAYOUT REVIEW - New Algorithm Validation")
	print("================================================================================")
	print()
	
	# Display corridor metadata
	print("Corridor Metadata:")
	print("  Length: %.2f units" % corridor_meta.bounding_box.size.z)
	print("  Connection points: %d" % corridor_meta.connection_points.size())
	
	# Calculate overlap
	var overlap = calculator._calculate_overlap(corridor_meta)
	var effective_length = corridor_meta.bounding_box.size.z - (2 * overlap)
	print("  Overlap per end: %.3f units" % overlap)
	print("  Effective length: %.3f units" % effective_length)
	print()
	
	# Current POC layout
	var current_layout = {
		"Room1": 0.0,
		"Corridor1to2": {"pos": 12.0, "count": 3},
		"Room2": 24.0,
		"Corridor2to3": {"pos": 36.0, "count": 3},
		"Room3": 48.0,
		"Corridor3to4": {"pos": 60.0, "count": 3},
		"Room4": 72.0,
		"Corridor4to5": {"pos": 80.0, "count": 1},
		"Room5": 92.0
	}
	
	print("================================================================================")
	print("CURRENT POC LAYOUT")
	print("================================================================================")
	print()
	
	for key in current_layout.keys():
		if typeof(current_layout[key]) == TYPE_DICTIONARY:
			print("%s: z=%.1f (%d corridor pieces)" % [
				key, current_layout[key].pos, current_layout[key].count
			])
		else:
			print("%s: z=%.1f" % [key, current_layout[key]])
	print()
	
	# Calculate what positions SHOULD be using the new algorithm
	print("================================================================================")
	print("RECALCULATED POSITIONS (using position-from-count)")
	print("================================================================================")
	print()
	
	var room1_pos = Vector3(0, 0, 0)
	print("Room1: z=%.1f (starting position)" % room1_pos.z)
	
	# Room1 → Room2 (3 corridors)
	var room2_pos = calculator.calculate_position_from_corridor_count(
		room1_pos,
		3,  # 3 corridor pieces
		corridor_meta,
		Vector3(0, 0, 1)
	)
	var corridor1to2_pos = (room1_pos.z + room2_pos.z) / 2.0
	print("Corridor1to2: z=%.1f (3 pieces, center position)" % corridor1to2_pos)
	print("Room2: z=%.1f (calculated)" % room2_pos.z)
	
	# Room2 → Room3 (3 corridors)
	var room3_pos = calculator.calculate_position_from_corridor_count(
		room2_pos,
		3,  # 3 corridor pieces
		corridor_meta,
		Vector3(0, 0, 1)
	)
	var corridor2to3_pos = (room2_pos.z + room3_pos.z) / 2.0
	print("Corridor2to3: z=%.1f (3 pieces, center position)" % corridor2to3_pos)
	print("Room3: z=%.1f (calculated)" % room3_pos.z)
	
	# Room3 → Room4 (3 corridors)
	var room4_pos = calculator.calculate_position_from_corridor_count(
		room3_pos,
		3,  # 3 corridor pieces
		corridor_meta,
		Vector3(0, 0, 1)
	)
	var corridor3to4_pos = (room3_pos.z + room4_pos.z) / 2.0
	print("Corridor3to4: z=%.1f (3 pieces, center position)" % corridor3to4_pos)
	print("Room4: z=%.1f (calculated)" % room4_pos.z)
	
	# Room4 → Room5 (1 corridor)
	var room5_pos = calculator.calculate_position_from_corridor_count(
		room4_pos,
		1,  # 1 corridor piece
		corridor_meta,
		Vector3(0, 0, 1)
	)
	var corridor4to5_pos = (room4_pos.z + room5_pos.z) / 2.0
	print("Corridor4to5: z=%.1f (1 piece, center position)" % corridor4to5_pos)
	print("Room5: z=%.1f (calculated)" % room5_pos.z)
	print()
	
	# Compare current vs calculated
	print("================================================================================")
	print("COMPARISON: Current vs Calculated")
	print("================================================================================")
	print()
	
	var comparisons = [
		{"name": "Room1", "current": 0.0, "calculated": room1_pos.z},
		{"name": "Corridor1to2", "current": 12.0, "calculated": corridor1to2_pos},
		{"name": "Room2", "current": 24.0, "calculated": room2_pos.z},
		{"name": "Corridor2to3", "current": 36.0, "calculated": corridor2to3_pos},
		{"name": "Room3", "current": 48.0, "calculated": room3_pos.z},
		{"name": "Corridor3to4", "current": 60.0, "calculated": corridor3to4_pos},
		{"name": "Room4", "current": 72.0, "calculated": room4_pos.z},
		{"name": "Corridor4to5", "current": 80.0, "calculated": corridor4to5_pos},
		{"name": "Room5", "current": 92.0, "calculated": room5_pos.z}
	]
	
	var max_diff = 0.0
	var all_within_tolerance = true
	
	for comp in comparisons:
		var diff = abs(comp.calculated - comp.current)
		max_diff = max(max_diff, diff)
		
		var status = "✅" if diff <= 0.1 else "⚠️" if diff <= 1.0 else "❌"
		
		if diff > 0.1:
			all_within_tolerance = false
		
		print("%s %-20s Current: %6.1f  Calculated: %6.1f  Diff: %6.3f" % [
			status, comp.name + ":", comp.current, comp.calculated, diff
		])
	
	print()
	print("Maximum difference: %.3f units" % max_diff)
	print()
	
	# Validation using corridor count function
	print("================================================================================")
	print("VALIDATION: Corridor Count Detection")
	print("================================================================================")
	print()
	
	var validations = [
		{"name": "Room1→Room2", "distance": room2_pos.z - room1_pos.z, "expected": 3},
		{"name": "Room2→Room3", "distance": room3_pos.z - room2_pos.z, "expected": 3},
		{"name": "Room3→Room4", "distance": room4_pos.z - room3_pos.z, "expected": 3},
		{"name": "Room4→Room5", "distance": room5_pos.z - room4_pos.z, "expected": 1}
	]
	
	var all_counts_correct = true
	
	for val in validations:
		var detected_count = calculator.calculate_corridor_count(val.distance, corridor_meta)
		var status = "✅" if detected_count == val.expected else "❌"
		
		if detected_count != val.expected:
			all_counts_correct = false
		
		print("%s %-20s Distance: %6.2f  Expected: %d  Detected: %d" % [
			status, val.name + ":", val.distance, val.expected, detected_count
		])
	
	print()
	
	# Summary
	print("================================================================================")
	print("SUMMARY")
	print("================================================================================")
	print()
	
	if all_within_tolerance:
		print("✅ All positions match calculated values within 0.1 unit tolerance")
	else:
		print("⚠️ Some positions differ from calculated values by more than 0.1 units")
		print("   Maximum difference: %.3f units" % max_diff)
	
	if all_counts_correct:
		print("✅ All corridor counts correctly detected by validation function")
	else:
		print("❌ Some corridor counts not correctly detected")
	
	print()
	
	if all_within_tolerance and all_counts_correct:
		print("🎉 POC layout is VALID and matches the new algorithm!")
		print("   No changes needed to main.tscn")
	else:
		print("📝 POC layout could be improved:")
		print("   Consider regenerating positions using calculate_position_from_corridor_count()")
		print("   This would ensure exact alignment with the new algorithm")
	
	print()
	print("================================================================================")
	
	quit()
