extends SceneTree

## Script to measure Phase 1 POC assets and generate documentation
## Measures: corridor.glb, room-small.glb, room-large.glb
## Run with: godot --headless --script scripts/utils/measure_poc_assets.gd

const POC_ASSETS = [
	"res://assets/models/kenney-dungeon/corridor.glb",
	"res://assets/models/kenney-dungeon/room-small.glb",
	"res://assets/models/kenney-dungeon/room-large.glb"
]

const OUTPUT_JSON_PATH = "res://data/asset_metadata.json"
const OUTPUT_DOCS_DIR = "res://docs/assets/"

func _init():
	print("=== Dungeon Asset Measurement Script ===")
	print("Measuring Phase 1 POC assets...")
	print()
	
	# Create database
	var database = AssetMetadataDatabase.new()
	var mapper = AssetMapper.new()
	var doc_generator = DocumentationGenerator.new()
	
	# Measure each asset
	for asset_path in POC_ASSETS:
		print("Measuring: %s" % asset_path)
		
		# Check if file exists
		if not FileAccess.file_exists(asset_path):
			push_error("Asset file not found: %s" % asset_path)
			continue
		
		# Measure asset
		var metadata = mapper.measure_asset(asset_path)
		
		if metadata == null:
			push_error("Failed to measure asset: %s" % asset_path)
			continue
		
		# Store in database
		database.store(metadata)
		print("  ✓ Measured and stored: %s" % metadata.asset_name)
		
		# Print summary
		print("    - Bounding box: %s" % metadata.bounding_box.size)
		print("    - Connection points: %d" % metadata.connection_points.size())
		print("    - Collision shapes: %d" % metadata.collision_shapes.size())
		print()
	
	# Export to JSON
	print("Exporting metadata to JSON...")
	_ensure_directory_exists(OUTPUT_JSON_PATH.get_base_dir())
	database.save_to_json(OUTPUT_JSON_PATH)
	print("  ✓ Saved to: %s" % OUTPUT_JSON_PATH)
	print()
	
	# Generate documentation for each asset
	print("Generating documentation...")
	_ensure_directory_exists(OUTPUT_DOCS_DIR)
	
	for asset_name in database.get_all_asset_names():
		var metadata = database.get_metadata(asset_name)
		if metadata == null:
			continue
		
		# Generate asset documentation
		var asset_doc = doc_generator.generate_asset_doc(metadata)
		var asset_doc_path = OUTPUT_DOCS_DIR + asset_name + ".md"
		_save_text_file(asset_doc_path, asset_doc)
		print("  ✓ Generated: %s" % asset_doc_path)
		
		# Generate rotation documentation
		var rotation_doc = doc_generator.generate_rotation_doc(metadata)
		var rotation_doc_path = OUTPUT_DOCS_DIR + asset_name + "_rotation.md"
		_save_text_file(rotation_doc_path, rotation_doc)
		print("  ✓ Generated: %s" % rotation_doc_path)
	
	# Generate spacing formula documentation
	var calculator = LayoutCalculator.new(database)
	var spacing_doc = doc_generator.generate_spacing_doc(calculator)
	var spacing_doc_path = OUTPUT_DOCS_DIR + "spacing_formulas.md"
	_save_text_file(spacing_doc_path, spacing_doc)
	print("  ✓ Generated: %s" % spacing_doc_path)
	print()
	
	print("=== Measurement Complete ===")
	print("Assets measured: %d" % database.get_all_asset_names().size())
	print("JSON export: %s" % OUTPUT_JSON_PATH)
	print("Documentation: %s" % OUTPUT_DOCS_DIR)
	print()
	
	# Exit after completion
	quit()

## Ensure directory exists, create if needed
func _ensure_directory_exists(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("Failed to create directory: %s (error: %d)" % [dir_path, err])

## Save text content to file
func _save_text_file(file_path: String, content: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: %s" % file_path)
		return
	
	file.store_string(content)
	file.close()
