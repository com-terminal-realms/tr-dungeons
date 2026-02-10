extends Node

## Loads modular clothing parts onto a base character at runtime
## Attaches clothing meshes to the skeleton

@export var outfit_parts: Array[String] = []  # Paths to modular part GLTF files

var skeleton: Skeleton3D = null

func _ready() -> void:
	# Find the skeleton in the parent character model
	skeleton = _find_skeleton(get_parent())
	
	if skeleton == null:
		push_error("ModularOutfitLoader: Could not find Skeleton3D in parent")
		return
	
	# Load and attach each outfit part
	for part_path in outfit_parts:
		_load_outfit_part(part_path)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result != null:
			return result
	
	return null

func _load_outfit_part(part_path: String) -> void:
	var part_scene = load(part_path)
	if part_scene == null:
		push_error("ModularOutfitLoader: Failed to load outfit part: " + part_path)
		return
	
	var part_instance = part_scene.instantiate()
	
	# Find the mesh in the part
	var mesh_instance = _find_mesh_instance(part_instance)
	if mesh_instance == null:
		push_error("ModularOutfitLoader: No MeshInstance3D found in: " + part_path)
		part_instance.queue_free()
		return
	
	# Attach the mesh to our skeleton
	var new_mesh = MeshInstance3D.new()
	new_mesh.mesh = mesh_instance.mesh
	new_mesh.skeleton = skeleton.get_path()
	
	# Copy materials
	for i in range(mesh_instance.get_surface_override_material_count()):
		var mat = mesh_instance.get_surface_override_material(i)
		if mat != null:
			new_mesh.set_surface_override_material(i, mat)
	
	skeleton.add_child(new_mesh)
	
	part_instance.queue_free()
	
	print("ModularOutfitLoader: Loaded outfit part: " + part_path)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result != null:
			return result
	
	return null
