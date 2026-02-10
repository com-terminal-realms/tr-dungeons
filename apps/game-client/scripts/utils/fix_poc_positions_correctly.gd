extends SceneTree

## Fix POC positions by accounting for room sizes
## The algorithm needs to calculate edge-to-edge distances, not center-to-center

func _init():
	# Load metadata
	var metadata_db = AssetMetadataDatabase.new()
	metadata_db.load_from_json("res://data/asset_metadata.json")
	
	var room_meta = metadata_db.get_metadata("room-large")
	var corridor_meta = metadata_db.get_metadata("corridor")
	
	if room_meta == null or corridor_meta == null:
		push_error("Failed to load metadata")
		quit()
		return
	
	print("\n=== Asset Dimensions ===")
	print("room-large size: ", room_meta.bounding_box.size)
	print("room-large half-size Z: ", room_meta.bounding_box.size.z / 2.0)
	print("corridor size: ", corridor_meta.bounding_box.size)
	print("corridor half-size Z: ", corridor_meta.bounding_box.size.z / 2.0)
	
	# Get connection points
	var room_conn_z = 10.0  # Room extends ±10 units, connection at edge
	var corridor_conn_z = 2.0  # Corridor extends ±2 units, connection at edge
	
	print("\n=== Connection Points ===")
	print("Room connection point (from center): ", room_conn_z)
	print("Corridor connection point (from center): ", corridor_conn_z)
	
	# Calculate overlap
	var overlap = 0.025  # Small overlap for smooth connection
	
	print("\n=== Calculating Correct Positions ===")
	
	# Room1 at origin
	var room1_z = 0.0
	print("Room1 center: z=", room1_z)
	print("  Room1 back edge: z=", room1_z - room_conn_z)
	print("  Room1 front edge: z=", room1_z + room_conn_z)
	
	# Calculate Room2 position
	# Distance from Room1 front edge to Room2 back edge = 3 corridors
	# Each corridor spans from its back connection (-2) to front connection (+2) = 4 units
	# With overlap, effective length = 4 - 2*0.025 = 3.95 units
	var corridor_effective_length = corridor_meta.bounding_box.size.z - (2 * overlap)
	var num_corridors_1to2 = 3
	var edge_to_edge_distance_1to2 = num_corridors_1to2 * corridor_effective_length
	
	# Room2 center = Room1 center + Room1 half-size + edge_to_edge_distance + Room2 half-size
	var room2_z = room1_z + room_conn_z + edge_to_edge_distance_1to2 + room_conn_z
	
	print("\nRoom2 calculation:")
	print("  Edge-to-edge distance (3 corridors): ", edge_to_edge_distance_1to2)
	print("  Room1 front edge: ", room1_z + room_conn_z)
	print("  Room2 back edge: ", room1_z + room_conn_z + edge_to_edge_distance_1to2)
	print("  Room2 center: z=", room2_z)
	
	# Corridor1to2 center (midpoint between room edges)
	var corridor1to2_z = room1_z + room_conn_z + (edge_to_edge_distance_1to2 / 2.0)
	print("  Corridor1to2 center: z=", corridor1to2_z)
	
	# Calculate Room3 position
	var num_corridors_2to3 = 3
	var edge_to_edge_distance_2to3 = num_corridors_2to3 * corridor_effective_length
	var room3_z = room2_z + room_conn_z + edge_to_edge_distance_2to3 + room_conn_z
	var corridor2to3_z = room2_z + room_conn_z + (edge_to_edge_distance_2to3 / 2.0)
	
	print("\nRoom3 calculation:")
	print("  Edge-to-edge distance (3 corridors): ", edge_to_edge_distance_2to3)
	print("  Room3 center: z=", room3_z)
	print("  Corridor2to3 center: z=", corridor2to3_z)
	
	# Calculate Room4 position
	var num_corridors_3to4 = 3
	var edge_to_edge_distance_3to4 = num_corridors_3to4 * corridor_effective_length
	var room4_z = room3_z + room_conn_z + edge_to_edge_distance_3to4 + room_conn_z
	var corridor3to4_z = room3_z + room_conn_z + (edge_to_edge_distance_3to4 / 2.0)
	
	print("\nRoom4 calculation:")
	print("  Edge-to-edge distance (3 corridors): ", edge_to_edge_distance_3to4)
	print("  Room4 center: z=", room4_z)
	print("  Corridor3to4 center: z=", corridor3to4_z)
	
	# Calculate Room5 position
	var num_corridors_4to5 = 1
	var edge_to_edge_distance_4to5 = num_corridors_4to5 * corridor_effective_length
	var room5_z = room4_z + room_conn_z + edge_to_edge_distance_4to5 + room_conn_z
	var corridor4to5_z = room4_z + room_conn_z + (edge_to_edge_distance_4to5 / 2.0)
	
	print("\nRoom5 calculation:")
	print("  Edge-to-edge distance (1 corridor): ", edge_to_edge_distance_4to5)
	print("  Room5 center: z=", room5_z)
	print("  Corridor4to5 center: z=", corridor4to5_z)
	
	print("\n=== CORRECTED POSITIONS FOR main.tscn ===")
	print("Room1: z=%.2f" % room1_z)
	print("Corridor1to2: z=%.2f (pieces at -3.95, 0, +3.95)" % corridor1to2_z)
	print("Room2: z=%.2f" % room2_z)
	print("Corridor2to3: z=%.2f (pieces at -3.95, 0, +3.95)" % corridor2to3_z)
	print("Room3: z=%.2f" % room3_z)
	print("Corridor3to4: z=%.2f (pieces at -3.95, 0, +3.95)" % corridor3to4_z)
	print("Room4: z=%.2f" % room4_z)
	print("Corridor4to5: z=%.2f (piece at 0)" % corridor4to5_z)
	print("Room5: z=%.2f" % room5_z)
	
	print("\nTotal dungeon length: %.2f units" % room5_z)
	
	quit()
