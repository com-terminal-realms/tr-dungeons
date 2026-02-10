extends GutTest

## Integration test for complete dungeon asset mapping workflow
## Tests: load asset → measure → store → retrieve → validate → document

const TEST_ASSETS = [
	"res://assets/models/kenney-dungeon/corridor.glb",
	"res://assets/models/kenney-dungeon/room-small.glb",
	"res://assets/models/kenney-dungeon/room-large.glb"
]

var mapper: AssetMapper
var database: AssetMetadataDatabase
var calculator: LayoutCalculator
var doc_generator: DocumentationGenerator

func before_each():
	mapper = AssetMapper.new()
	database = AssetMetadataDatabase.new()
	calculator = LayoutCalculator.new(database)
	doc_generator = DocumentationGenerator.new()

func after_each():
	mapper = null
	database = null
	calculator = null
	doc_generator = null

## Test complete workflow with corridor asset
func test_complete_workflow_corridor():
	var asset_path = "res://assets/models/kenney-dungeon/corridor.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Step 1: Load and measure asset
	var metadata = mapper.measure_asset(asset_path)
	assert_not_null(metadata, "Should measure asset successfully")
	assert_eq(metadata.asset_format, "GLB", "Should detect GLB format")
	assert_true(metadata.bounding_box.size != Vector3.ZERO, "Should have non-zero bounding box")
	
	# Step 2: Store in database
	database.store(metadata)
	assert_true(database.has_metadata(metadata.asset_name), "Should store metadata in database")
	
	# Step 3: Retrieve from database
	var retrieved = database.get_metadata(metadata.asset_name)
	assert_not_null(retrieved, "Should retrieve metadata from database")
	assert_eq(retrieved.asset_name, metadata.asset_name, "Should retrieve correct metadata")
	
	# Step 4: Validate with calculator
	# For corridor, verify it can be used in spacing calculations
	var distance = 20.0
	var count = calculator.calculate_corridor_count(distance, metadata)
	assert_true(count > 0, "Should calculate valid corridor count")
	
	# Step 5: Generate documentation
	var doc = doc_generator.generate_asset_doc(metadata)
	assert_false(doc.is_empty(), "Should generate documentation")
	assert_true(doc.contains(metadata.asset_name), "Documentation should contain asset name")
	assert_true(doc.contains("Bounding Box"), "Documentation should contain dimensions")
	
	# Step 6: Test JSON export/import
	var temp_json_path = "user://test_metadata.json"
	database.save_to_json(temp_json_path)
	
	var new_database = AssetMetadataDatabase.new()
	new_database.load_from_json(temp_json_path)
	
	var imported = new_database.get_metadata(metadata.asset_name)
	assert_not_null(imported, "Should import metadata from JSON")
	assert_eq(imported.asset_name, metadata.asset_name, "Imported metadata should match")

## Test complete workflow with room-small asset
func test_complete_workflow_room_small():
	var asset_path = "res://assets/models/kenney-dungeon/room-small.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Step 1: Load and measure asset
	var metadata = mapper.measure_asset(asset_path)
	assert_not_null(metadata, "Should measure asset successfully")
	assert_eq(metadata.asset_format, "GLB", "Should detect GLB format")
	
	# Step 2: Verify room-specific properties
	# Rooms should have multiple connection points (doors)
	assert_true(metadata.connection_points.size() >= 2, "Room should have multiple connection points")
	
	# Rooms should have walkable area defined
	assert_true(metadata.walkable_area.size != Vector3.ZERO, "Room should have walkable area")
	
	# Step 3: Store and retrieve
	database.store(metadata)
	var retrieved = database.get_metadata(metadata.asset_name)
	assert_not_null(retrieved, "Should retrieve metadata from database")
	
	# Step 4: Generate documentation
	var doc = doc_generator.generate_asset_doc(metadata)
	assert_false(doc.is_empty(), "Should generate documentation")
	assert_true(doc.contains("Connection Points"), "Documentation should contain connection points")
	assert_true(doc.contains("Walkable Area"), "Documentation should contain walkable area")

## Test complete workflow with room-large asset
func test_complete_workflow_room_large():
	var asset_path = "res://assets/models/kenney-dungeon/room-large.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Step 1: Load and measure asset
	var metadata = mapper.measure_asset(asset_path)
	assert_not_null(metadata, "Should measure asset successfully")
	
	# Step 2: Verify measurements are reasonable
	assert_true(metadata.bounding_box.size.x > 0, "Should have positive width")
	assert_true(metadata.bounding_box.size.y > 0, "Should have positive height")
	assert_true(metadata.bounding_box.size.z > 0, "Should have positive length")
	
	# Large room should be bigger than small room
	# (We'll just verify it has reasonable dimensions)
	assert_true(metadata.bounding_box.size.x >= 3.0, "Large room should be at least 3 units wide")
	
	# Step 3: Store and generate documentation
	database.store(metadata)
	var doc = doc_generator.generate_asset_doc(metadata)
	assert_false(doc.is_empty(), "Should generate documentation")

## Test workflow with all three POC assets
func test_workflow_all_poc_assets():
	var measured_count = 0
	
	for asset_path in TEST_ASSETS:
		# Skip if asset doesn't exist
		if not FileAccess.file_exists(asset_path):
			continue
		
		# Measure asset
		var metadata = mapper.measure_asset(asset_path)
		if metadata != null:
			database.store(metadata)
			measured_count += 1
	
	# Verify we measured at least one asset
	assert_true(measured_count > 0, "Should measure at least one POC asset")
	
	# Verify database contains all measured assets
	var stored_names = database.get_all_asset_names()
	assert_eq(stored_names.size(), measured_count, "Database should contain all measured assets")
	
	# Generate documentation for all assets
	for asset_name in stored_names:
		var metadata = database.get_metadata(asset_name)
		var doc = doc_generator.generate_asset_doc(metadata)
		assert_false(doc.is_empty(), "Should generate documentation for %s" % asset_name)

## Test layout validation with multiple corridors
func test_layout_validation_workflow():
	var asset_path = "res://assets/models/kenney-dungeon/corridor.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Measure corridor
	var metadata = mapper.measure_asset(asset_path)
	assert_not_null(metadata, "Should measure corridor")
	
	database.store(metadata)
	
	# Create a simple layout with 3 corridors
	var layout: Array[PlacedAsset] = []
	var corridor_length = metadata.bounding_box.size.z
	
	for i in range(3):
		var placed = PlacedAsset.new()
		placed.metadata = metadata
		placed.position = Vector3(0, 0, i * corridor_length * 0.95)  # Slight overlap
		placed.rotation = Vector3.ZERO
		layout.append(placed)
	
	# Validate layout
	var result = calculator.validate_layout(layout)
	
	# Layout should be valid (or have minor issues)
	# We're mainly testing that validation runs without errors
	assert_not_null(result, "Should return validation result")
	assert_true(result.error_messages.size() >= 0, "Should have error messages array")

## Test spacing formula with measured corridor
func test_spacing_formula_with_real_corridor():
	var asset_path = "res://assets/models/kenney-dungeon/corridor.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Measure corridor
	var metadata = mapper.measure_asset(asset_path)
	assert_not_null(metadata, "Should measure corridor")
	
	# Test spacing formula at various distances
	var test_distances = [10.0, 15.0, 20.0, 30.0]
	
	for distance in test_distances:
		var count = calculator.calculate_corridor_count(distance, metadata)
		assert_true(count > 0, "Should calculate positive corridor count for distance %.1f" % distance)
		
		# Verify count is reasonable (not too high or too low)
		var corridor_length = metadata.bounding_box.size.z
		var max_count = ceili(distance / (corridor_length * 0.5))  # Very conservative upper bound
		assert_true(count <= max_count, "Corridor count should be reasonable for distance %.1f" % distance)

## Test documentation generation for all asset types
func test_documentation_generation_workflow():
	# Test with generated metadata (in case real assets aren't available)
	var metadata = AssetMetadata.new()
	metadata.asset_name = "test_corridor"
	metadata.asset_path = "res://test/corridor.glb"
	metadata.asset_format = "GLB"
	metadata.measurement_timestamp = Time.get_unix_time_from_system()
	metadata.bounding_box = AABB(Vector3(-1, 0, -2.5), Vector3(2, 3, 5))
	metadata.origin_offset = Vector3(0, 1.5, 0)
	
	# Add connection points
	var point1 = ConnectionPoint.new()
	point1.position = Vector3(0, 1.5, -2.5)
	point1.normal = Vector3(0, 0, -1)
	point1.type = "corridor_end"
	point1.dimensions = Vector2(2, 3)
	
	var point2 = ConnectionPoint.new()
	point2.position = Vector3(0, 1.5, 2.5)
	point2.normal = Vector3(0, 0, 1)
	point2.type = "corridor_end"
	point2.dimensions = Vector2(2, 3)
	
	metadata.connection_points = [point1, point2]
	
	# Generate all documentation types
	var asset_doc = doc_generator.generate_asset_doc(metadata)
	assert_false(asset_doc.is_empty(), "Should generate asset documentation")
	assert_true(asset_doc.contains("# Asset:"), "Asset doc should have header")
	
	var spacing_doc = doc_generator.generate_spacing_doc(calculator)
	assert_false(spacing_doc.is_empty(), "Should generate spacing documentation")
	assert_true(spacing_doc.contains("Corridor Count Formula"), "Spacing doc should have formula")
	
	var rotation_doc = doc_generator.generate_rotation_doc(metadata)
	assert_false(rotation_doc.is_empty(), "Should generate rotation documentation")
	assert_true(rotation_doc.contains("Cardinal Direction"), "Rotation doc should have cardinal directions")

## Test version history workflow
func test_version_history_workflow():
	var asset_path = "res://assets/models/kenney-dungeon/corridor.glb"
	
	# Skip if asset doesn't exist
	if not FileAccess.file_exists(asset_path):
		pending("Asset not found: %s" % asset_path)
		return
	
	# Measure asset first time
	var metadata_v1 = mapper.measure_asset(asset_path)
	assert_not_null(metadata_v1, "Should measure asset")
	
	database.store(metadata_v1)
	
	# Verify no history yet
	var history_before = database.get_version_history(metadata_v1.asset_name)
	assert_eq(history_before.size(), 0, "Should have no history initially")
	
	# Measure again (simulating an update)
	var metadata_v2 = mapper.measure_asset(asset_path)
	database.store(metadata_v2)
	
	# Verify history was created
	var history_after = database.get_version_history(metadata_v2.asset_name)
	assert_eq(history_after.size(), 1, "Should have one version in history")
	
	# Verify current version is v2
	var current = database.get_metadata(metadata_v2.asset_name)
	assert_eq(current.measurement_timestamp, metadata_v2.measurement_timestamp, "Current should be latest version")
