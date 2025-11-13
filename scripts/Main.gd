## OpenIsopix - Main Game Manager
## Orchestrates all systems

extends Node2D

## System references
@onready var world_api = $WorldAPI
@onready var camera = $IsometricCamera
@onready var renderer = $IsometricRenderer
@onready var lighting_system = $LightingSystem
@onready var fog_system = $FogOfWarSystem
@onready var interaction_system = $InteractionSystem
@onready var ui = $UI

func _ready():
	print("OpenIsopix - Initializing...")
	
	# Connect systems
	_setup_systems()
	
	# Generate demo world
	_generate_demo_world()
	
	# Initial render
	if renderer:
		renderer.render_world()
	
	print("OpenIsopix - Ready!")
	_print_controls()

func _setup_systems():
	# Make sure all systems have their references
	if renderer:
		renderer.world_api = world_api
		renderer.camera = camera
	
	if lighting_system:
		lighting_system.world_api = world_api
	
	if fog_system:
		fog_system.world_api = world_api
	
	if interaction_system:
		interaction_system.world_api = world_api
		interaction_system.camera = camera
		interaction_system.fog_system = fog_system
		interaction_system.renderer = renderer
		interaction_system.status_label = $UI/HUD/InfoPanel/VBox/Status

func _generate_demo_world():
	if not world_api:
		return
	
	print("Generating demo world...")
	
	# Create a simple test world with various block types
	var world_size = 10
	
	# Ground layer
	for x in range(-world_size, world_size):
		for z in range(-world_size, world_size):
			# Create varied terrain
			var block_type = "grass"
			
			# Add some water
			if (x + z) % 7 == 0:
				block_type = "water"
			# Add some stone
			elif abs(x) > world_size / 2 or abs(z) > world_size / 2:
				block_type = "stone"
			
			world_api.add_block(Vector3i(x, 0, z), block_type)
	
	# Add some elevated blocks
	for i in range(5):
		var x = randi() % (world_size * 2) - world_size
		var z = randi() % (world_size * 2) - world_size
		world_api.add_block(Vector3i(x, 1, z), "stone", 0.5)
	
	# Add some light sources
	world_api.add_block(Vector3i(0, 1, 0), "torch")
	world_api.add_block(Vector3i(5, 1, 5), "torch")
	world_api.add_block(Vector3i(-5, 1, -5), "torch")
	
	# Reveal starting area
	if fog_system:
		fog_system.reveal_area(Vector3i(0, 0, 0), 12.0)
	
	print("Demo world generated!")

func _print_controls():
	print("\n=== CONTROLS ===")
	print("Arrow Keys / WASD: Move camera")
	print("Q/E: Rotate camera heading")
	print("P: Cycle camera pitch")
	print("+/-: Zoom in/out")
	print("Mouse Wheel: Zoom in/out")
	print("Left Click: Place block / Select")
	print("Right Click: Remove block")
	print("1-4: Select block type (Grass/Stone/Water/Torch)")
	print("F: Toggle fog reveal")
	print("Space: Cycle interaction mode")
	print("================\n")

func _input(event):
	# Handle rotation
	if event.is_action_pressed("rotate_left"):
		if camera:
			camera.rotate_heading(false)
			print("Rotated left")
			if renderer:
				renderer.render_world()
	
	if event.is_action_pressed("rotate_right"):
		if camera:
			camera.rotate_heading(true)
			print("Rotated right")
			if renderer:
				renderer.render_world()
	
	# Handle pitch change
	if event.is_action_pressed("change_pitch"):
		if camera:
			camera.cycle_pitch()
			if renderer:
				renderer.render_world()
	
	# Handle zoom
	if event.is_action_pressed("zoom_in"):
		if camera:
			camera.zoom_camera(true)
	
	if event.is_action_pressed("zoom_out"):
		if camera:
			camera.zoom_camera(false)
