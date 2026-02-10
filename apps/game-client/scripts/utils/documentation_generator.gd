class_name DocumentationGenerator
extends RefCounted

## Generates human-readable documentation for dungeon assets

## Generate markdown documentation for a single asset
func generate_asset_doc(metadata: AssetMetadata) -> String:
	if metadata == null:
		return "# Error: No metadata provided\n"
	
	var doc = ""
	
	# Header
	doc += "# Asset: %s\n\n" % metadata.asset_name
	
	# Metadata section
	doc += "## Metadata\n\n"
	doc += "- **Asset Path**: `%s`\n" % metadata.asset_path
	doc += "- **Asset Format**: %s\n" % metadata.asset_format
	if not metadata.asset_source.is_empty():
		doc += "- **Asset Source**: %s\n" % metadata.asset_source
	doc += "- **Measurement Timestamp**: %s\n" % Time.get_datetime_string_from_unix_time(metadata.measurement_timestamp)
	doc += "- **Measurement Accuracy**: ±%.2f units\n\n" % metadata.measurement_accuracy
	
	# Dimensions section
	doc += "## Dimensions\n\n"
	doc += "### Bounding Box\n\n"
	doc += "- **Position**: (%.2f, %.2f, %.2f)\n" % [
		metadata.bounding_box.position.x,
		metadata.bounding_box.position.y,
		metadata.bounding_box.position.z
	]
	doc += "- **Size**: (%.2f, %.2f, %.2f)\n" % [
		metadata.bounding_box.size.x,
		metadata.bounding_box.size.y,
		metadata.bounding_box.size.z
	]
	doc += "- **Width (X)**: %.2f units\n" % metadata.bounding_box.size.x
	doc += "- **Height (Y)**: %.2f units\n" % metadata.bounding_box.size.y
	doc += "- **Length (Z)**: %.2f units\n\n" % metadata.bounding_box.size.z
	
	# Origin offset
	doc += "### Origin Offset\n\n"
	doc += "- **Offset from Origin**: (%.2f, %.2f, %.2f)\n" % [
		metadata.origin_offset.x,
		metadata.origin_offset.y,
		metadata.origin_offset.z
	]
	doc += "- **Distance**: %.2f units\n\n" % metadata.origin_offset.length()
	
	# Floor and wall measurements
	doc += "### Floor and Walls\n\n"
	doc += "- **Floor Height**: %.2f units\n" % metadata.floor_height
	if metadata.wall_thickness > 0:
		doc += "- **Wall Thickness**: %.2f units\n" % metadata.wall_thickness
	if metadata.doorway_dimensions != Vector2.ZERO:
		doc += "- **Doorway Dimensions**: %.2f × %.2f units (W × H)\n" % [
			metadata.doorway_dimensions.x,
			metadata.doorway_dimensions.y
		]
	doc += "\n"
	
	# Connection points section
	doc += "## Connection Points\n\n"
	if metadata.connection_points.is_empty():
		doc += "No connection points defined.\n\n"
	else:
		doc += "Total: %d connection point(s)\n\n" % metadata.connection_points.size()
		for i in range(metadata.connection_points.size()):
			var point = metadata.connection_points[i]
			doc += "### Connection Point %d\n\n" % (i + 1)
			doc += "- **Type**: %s\n" % point.type
			doc += "- **Position**: (%.2f, %.2f, %.2f)\n" % [
				point.position.x,
				point.position.y,
				point.position.z
			]
			doc += "- **Normal**: (%.2f, %.2f, %.2f)\n" % [
				point.normal.x,
				point.normal.y,
				point.normal.z
			]
			doc += "- **Dimensions**: %.2f × %.2f units (W × H)\n\n" % [
				point.dimensions.x,
				point.dimensions.y
			]
	
	# Collision geometry section
	doc += "## Collision Geometry\n\n"
	if metadata.collision_shapes.is_empty():
		doc += "No collision shapes defined.\n\n"
	else:
		doc += "Total: %d collision shape(s)\n\n" % metadata.collision_shapes.size()
		for i in range(metadata.collision_shapes.size()):
			var shape = metadata.collision_shapes[i]
			doc += "### Collision Shape %d\n\n" % (i + 1)
			doc += "- **Type**: %s\n" % shape.shape_type
			doc += "- **Position**: (%.2f, %.2f, %.2f)\n" % [
				shape.position.x,
				shape.position.y,
				shape.position.z
			]
			
			if shape.shape_type == "box":
				doc += "- **Size**: (%.2f, %.2f, %.2f)\n" % [
					shape.size.x,
					shape.size.y,
					shape.size.z
				]
			elif shape.shape_type == "sphere":
				doc += "- **Radius**: %.2f units\n" % shape.radius
			elif shape.shape_type == "capsule":
				doc += "- **Radius**: %.2f units\n" % shape.radius
				doc += "- **Height**: %.2f units\n" % shape.height
			
			doc += "\n"
	
	# Walkable area section
	doc += "## Walkable Area\n\n"
	if metadata.walkable_area.size == Vector3.ZERO:
		doc += "No walkable area defined.\n\n"
	else:
		doc += "- **Position**: (%.2f, %.2f, %.2f)\n" % [
			metadata.walkable_area.position.x,
			metadata.walkable_area.position.y,
			metadata.walkable_area.position.z
		]
		doc += "- **Size**: (%.2f, %.2f, %.2f)\n" % [
			metadata.walkable_area.size.x,
			metadata.walkable_area.size.y,
			metadata.walkable_area.size.z
		]
		doc += "- **Area**: %.2f square units\n\n" % (
			metadata.walkable_area.size.x * metadata.walkable_area.size.z
		)
	
	# Rotation section
	doc += "## Rotation\n\n"
	doc += "- **Default Rotation**: (%.1f°, %.1f°, %.1f°)\n" % [
		metadata.default_rotation.x,
		metadata.default_rotation.y,
		metadata.default_rotation.z
	]
	doc += "- **Rotation Pivot**: (%.2f, %.2f, %.2f)\n\n" % [
		metadata.rotation_pivot.x,
		metadata.rotation_pivot.y,
		metadata.rotation_pivot.z
	]
	
	# Visual diagram (ASCII art)
	doc += "## Visual Diagram\n\n"
	doc += "```\n"
	doc += _generate_ascii_diagram(metadata)
	doc += "```\n\n"
	
	return doc

## Generate documentation for spacing formulas
func generate_spacing_doc(calculator: LayoutCalculator) -> String:
	if calculator == null:
		return "# Error: No calculator provided\n"
	
	var doc = ""
	
	# Header
	doc += "# Spacing Formula Documentation\n\n"
	
	# Formula explanation
	doc += "## Corridor Count Formula\n\n"
	doc += "The number of corridor pieces required for a given distance is calculated using:\n\n"
	doc += "```\n"
	doc += "count = ceil((distance - overlap) / effective_length)\n"
	doc += "```\n\n"
	doc += "Where:\n"
	doc += "- `distance` = target distance between two points\n"
	doc += "- `overlap` = distance that corridors overlap at connection points\n"
	doc += "- `effective_length` = corridor_length - overlap\n"
	doc += "- `corridor_length` = full length of a single corridor piece\n\n"
	
	# Worked examples
	doc += "## Worked Examples\n\n"
	doc += "Assuming a corridor with:\n"
	doc += "- Length: 5.0 units\n"
	doc += "- Overlap: 0.5 units\n"
	doc += "- Effective length: 4.5 units\n\n"
	
	var example_distances = [10.0, 15.0, 20.0, 30.0]
	var corridor_length = 5.0
	var overlap = 0.5
	var effective_length = corridor_length - overlap
	
	for distance in example_distances:
		var count = ceili((distance - overlap) / effective_length)
		var actual_length = overlap + (count * effective_length)
		
		doc += "### Distance: %.1f units\n\n" % distance
		doc += "```\n"
		doc += "count = ceil((%.1f - %.1f) / %.1f)\n" % [distance, overlap, effective_length]
		doc += "count = ceil(%.2f / %.1f)\n" % [(distance - overlap), effective_length]
		doc += "count = ceil(%.2f)\n" % ((distance - overlap) / effective_length)
		doc += "count = %d\n" % count
		doc += "```\n\n"
		doc += "**Result**: %d corridor pieces\n" % count
		doc += "**Actual length**: %.2f units (difference: %.2f units)\n\n" % [
			actual_length,
			abs(actual_length - distance)
		]
	
	# Tolerance notes
	doc += "## Tolerance\n\n"
	doc += "- The formula ensures the actual length is within ±0.5 units of the target distance\n"
	doc += "- Connection points should align within ±0.1 units for valid connections\n"
	doc += "- Gaps larger than 0.2 units are considered errors\n"
	doc += "- Overlaps larger than 0.5 units are considered errors\n\n"
	
	return doc

## Generate documentation for rotation transforms
func generate_rotation_doc(metadata: AssetMetadata) -> String:
	if metadata == null:
		return "# Error: No metadata provided\n"
	
	var doc = ""
	
	# Header
	doc += "# Rotation Transform Documentation\n\n"
	doc += "Asset: %s\n\n" % metadata.asset_name
	
	# Cardinal directions
	doc += "## Cardinal Direction Rotations\n\n"
	doc += "| Direction | Y Rotation | Euler Angles |\n"
	doc += "|-----------|------------|---------------|\n"
	doc += "| North     | 0°         | (0°, 0°, 0°)  |\n"
	doc += "| East      | 90°        | (0°, 90°, 0°) |\n"
	doc += "| South     | 180°       | (0°, 180°, 0°)|\n"
	doc += "| West      | 270°       | (0°, 270°, 0°)|\n\n"
	
	# Connection point transformations
	if not metadata.connection_points.is_empty():
		doc += "## Connection Point Transformations\n\n"
		doc += "Original connection points and their transformations for each cardinal direction:\n\n"
		
		for i in range(metadata.connection_points.size()):
			var point = metadata.connection_points[i]
			doc += "### Connection Point %d (%s)\n\n" % [i + 1, point.type]
			doc += "**Original**:\n"
			doc += "- Position: (%.2f, %.2f, %.2f)\n" % [
				point.position.x,
				point.position.y,
				point.position.z
			]
			doc += "- Normal: (%.2f, %.2f, %.2f)\n\n" % [
				point.normal.x,
				point.normal.y,
				point.normal.z
			]
			
			# Transform for each direction
			var directions = {
				"North (0°)": Vector3(0, 0, 0),
				"East (90°)": Vector3(0, 90, 0),
				"South (180°)": Vector3(0, 180, 0),
				"West (270°)": Vector3(0, 270, 0)
			}
			
			for direction_name in directions:
				var rotation = directions[direction_name]
				var transformed = point.transform_by_rotation(rotation)
				
				doc += "**%s**:\n" % direction_name
				doc += "- Position: (%.2f, %.2f, %.2f)\n" % [
					transformed.position.x,
					transformed.position.y,
					transformed.position.z
				]
				doc += "- Normal: (%.2f, %.2f, %.2f)\n\n" % [
					transformed.normal.x,
					transformed.normal.y,
					transformed.normal.z
				]
	
	# Rotation matrices
	doc += "## Rotation Matrices\n\n"
	doc += "Y-axis rotation matrices for cardinal directions:\n\n"
	doc += "### North (0°)\n\n"
	doc += "```\n"
	doc += "[ 1  0  0 ]\n"
	doc += "[ 0  1  0 ]\n"
	doc += "[ 0  0  1 ]\n"
	doc += "```\n\n"
	
	doc += "### East (90°)\n\n"
	doc += "```\n"
	doc += "[ 0  0  1 ]\n"
	doc += "[ 0  1  0 ]\n"
	doc += "[-1  0  0 ]\n"
	doc += "```\n\n"
	
	doc += "### South (180°)\n\n"
	doc += "```\n"
	doc += "[-1  0  0 ]\n"
	doc += "[ 0  1  0 ]\n"
	doc += "[ 0  0 -1 ]\n"
	doc += "```\n\n"
	
	doc += "### West (270°)\n\n"
	doc += "```\n"
	doc += "[ 0  0 -1 ]\n"
	doc += "[ 0  1  0 ]\n"
	doc += "[ 1  0  0 ]\n"
	doc += "```\n\n"
	
	return doc

## Generate a simple ASCII diagram of the asset
func _generate_ascii_diagram(metadata: AssetMetadata) -> String:
	var diagram = ""
	var bbox = metadata.bounding_box
	
	# Top view (XZ plane)
	diagram += "Top View (XZ plane):\n\n"
	diagram += "    +Z (North)\n"
	diagram += "       ^\n"
	diagram += "       |\n"
	diagram += "       |\n"
	diagram += "  +----+----+\n"
	diagram += "  |         |\n"
	diagram += "  |    O    |  <-- Origin\n"
	diagram += "  |         |\n"
	diagram += "  +----+----+\n"
	diagram += "       |\n"
	diagram += "  -X <-+-> +X (East)\n\n"
	
	# Side view (XY plane)
	diagram += "Side View (XY plane):\n\n"
	diagram += "    +Y (Up)\n"
	diagram += "       ^\n"
	diagram += "       |\n"
	diagram += "  +----+----+\n"
	diagram += "  |         |\n"
	diagram += "  |    O    |  <-- Origin\n"
	diagram += "  |         |\n"
	diagram += "  +----+----+\n"
	diagram += "       |\n"
	diagram += "  -X <-+-> +X\n\n"
	
	# Dimensions
	diagram += "Dimensions:\n"
	diagram += "  Width (X):  %.2f units\n" % bbox.size.x
	diagram += "  Height (Y): %.2f units\n" % bbox.size.y
	diagram += "  Length (Z): %.2f units\n\n" % bbox.size.z
	
	# Connection points markers
	if not metadata.connection_points.is_empty():
		diagram += "Connection Points:\n"
		for i in range(metadata.connection_points.size()):
			var point = metadata.connection_points[i]
			var direction = ""
			if abs(point.normal.z) > 0.9:
				direction = "North" if point.normal.z > 0 else "South"
			elif abs(point.normal.x) > 0.9:
				direction = "East" if point.normal.x > 0 else "West"
			else:
				direction = "Unknown"
			
			diagram += "  [%d] %s facing %s\n" % [i + 1, point.type, direction]
	
	return diagram
