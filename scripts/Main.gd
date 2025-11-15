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
		# --- FIX: Call initialize AFTER references are set ---
		renderer.initialize() 
	
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
		# --- FIX: Call initialize AFTER references are set ---
		interaction_system.initialize()

	# --- FIX: Connect the block selection buttons ---
	var block_buttons = $UI/HUD/BottomPanel/HBox/BlockButtons
	if block_buttons:
		block_buttons.get_node("GrassBtn").pressed.connect(_on_grass_btn_pressed)
		block_buttons.get_node("StoneBtn").pressed.connect(_on_stone_btn_pressed)
		block_buttons.get_node("WaterBtn").pressed.connect(_on_water_btn_pressed)
		block_buttons.get_node("WoodBtn").pressed.connect(_on_wood_btn_pressed)
		block_buttons.get_node("SoilBtn").pressed.connect(_on_soil_btn_pressed)

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
	
	# Reveal starting area
	if fog_system:
		fog_system.reveal_area(Vector3i(0, 0, 0), 12.0)
	
	print("Demo world generated!")

func _print_controls():
	print("\n=== CONTROLS ===")
	print("Arrow Keys / WASD: Move camera")
	print("P: Cycle camera pitch")
	print("+/-: Zoom in/out")
	print("Mouse Wheel: Zoom in/out")
	print("Left Click: Place block / Select")
	print("Right Click: Remove block")
	print("1-5: Select block type (press twice for full height)")
	print("F: Reveal fog area")
	print("G: Toggle fog globally")
	print("Space: Cycle interaction mode")
	print("Ctrl+Z: Undo")
	print("Ctrl+Y: Redo")
	print("================\n")

func _input(event):
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

# --- FIX: Add button handler functions ---
func _on_grass_btn_pressed():
	if interaction_system:
		interaction_system.selected_block_type = "grass"
		interaction_system._update_cursor_texture()
		interaction_system._update_status_ui()

func _on_stone_btn_pressed():
	if interaction_system:
		interaction_system.selected_block_type = "stone"
		interaction_system._update_cursor_texture()
		interaction_system._update_status_ui()

func _on_water_btn_pressed():
	if interaction_system:
		interaction_system.selected_block_type = "water"
		interaction_system._update_cursor_texture()
		interaction_system._update_status_ui()

func _on_wood_btn_pressed():
	if interaction_system:
		interaction_system.selected_block_type = "wood"
		interaction_system._update_cursor_texture()
		interaction_system._update_status_ui()

func _on_soil_btn_pressed():
	if interaction_system:
		interaction_system.selected_block_type = "soil"
		interaction_system._update_cursor_texture()
		interaction_system._update_status_ui()
