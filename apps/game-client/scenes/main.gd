## Main scene controller
extends Node3D

func _ready() -> void:
	print("Main: Scene ready")
	
	# Get references
	var player = $Player
	var camera = $Camera
	var nav_region = $NavigationRegion3D
	
	print("Main: Player = ", player)
	print("Main: Camera = ", camera)
	print("Main: NavigationRegion3D = ", nav_region)
	
	if player and camera:
		# Manually set camera target
		camera.target = player
		print("Main: Camera target set to player")
	else:
		push_error("Main: Failed to find player or camera!")
	
	# Bake navigation mesh
	if nav_region:
		print("Main: Baking navigation mesh...")
		var nav_mesh = NavigationMesh.new()
		nav_mesh.cell_size = 0.25
		nav_mesh.cell_height = 0.2
		nav_mesh.agent_height = 2.0
		nav_mesh.agent_radius = 0.5
		nav_mesh.agent_max_climb = 0.5
		nav_mesh.agent_max_slope = 45.0
		nav_region.navigation_mesh = nav_mesh
		nav_region.bake_navigation_mesh()
		print("Main: Navigation mesh baked!")
	else:
		push_error("Main: NavigationRegion3D not found!")
	
	# Place doors at all connection points
	if nav_region:
		print("Main: Placing doors...")
		DoorManager.place_doors_at_connections(nav_region)
		print("Main: Door placement complete!")
