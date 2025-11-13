## OpenIsopix - Interaction System
## Handles user input and world interaction

class_name InteractionSystem
extends Node

@export var world_api: WorldAPI
@export var camera: IsometricCamera
@export var fog_system: FogOfWarSystem
@export var renderer: Node2D

## UI References
var status_label: Label

## Current interaction mode
enum InteractionMode { SELECT, PLACE, REMOVE, QUERY }
var current_mode: InteractionMode = InteractionMode.SELECT

## Currently selected block type for placement
var selected_block_type: String = "grass"

## Currently hovered/selected block
var hovered_position: Vector3i = Vector3i.ZERO
var selected_position: Vector3i = Vector3i.ZERO
var is_position_valid: bool = false

## Highlight sprite for cursor
var highlight_sprite: Sprite2D

## Mouse/controller state
var mouse_position: Vector2 = Vector2.ZERO

signal block_selected(position: Vector3i)
signal block_hovered(position: Vector3i)
signal interaction_mode_changed(mode: InteractionMode)

func _ready():
	_create_highlight_sprite()
	_update_status_ui()

func _process(_delta):
	_update_mouse_position()
	_update_hovered_block()
	_handle_mouse_input()

func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				selected_block_type = "grass"
				print("Selected: Grass")
				_update_status_ui()
			KEY_2:
				selected_block_type = "stone"
				print("Selected: Stone")
				_update_status_ui()
			KEY_3:
				selected_block_type = "water"
				print("Selected: Water")
				_update_status_ui()
			KEY_4:
				selected_block_type = "torch"
				print("Selected: Torch")
				_update_status_ui()
			KEY_SPACE:
				cycle_mode()
			KEY_F:
				_toggle_fog()

func _create_highlight_sprite():
	highlight_sprite = Sprite2D.new()
	add_child(highlight_sprite)
	
	# Create a simple highlight texture
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 0, 0.5))  # Yellow semi-transparent
	highlight_sprite.texture = ImageTexture.create_from_image(image)
	highlight_sprite.z_index = 10000  # Always on top

func _update_mouse_position():
	mouse_position = get_viewport().get_mouse_position()

func _update_hovered_block():
	if not camera:
		return
	
	# Convert screen position to world position
	var world_pos = camera.screen_to_world(mouse_position)
	var block_pos = Vector3i(
		roundi(world_pos.x),
		0,  # We'll check the topmost block
		roundi(world_pos.z)
	)
	
	# Find the highest block at this x,z position
	if world_api:
		var found_block = false
		for y in range(10, -1, -1):  # Check from top to bottom
			block_pos.y = y
			var block = world_api.get_block(block_pos)
			if block:
				hovered_position = block_pos
				found_block = true
				is_position_valid = true
				break
		
		if not found_block:
			# No block found, hover over ground level
			hovered_position = Vector3i(block_pos.x, 0, block_pos.z)
			is_position_valid = true
		
		# Update highlight position
		_update_highlight()
		block_hovered.emit(hovered_position)

func _update_highlight():
	if not is_position_valid or not highlight_sprite:
		highlight_sprite.visible = false
		return
	
	highlight_sprite.visible = true
	var iso_pos = _world_to_iso(hovered_position)
	highlight_sprite.position = iso_pos
	
	# Change color based on mode
	match current_mode:
		InteractionMode.SELECT:
			highlight_sprite.modulate = Color(1, 1, 0, 0.5)  # Yellow
		InteractionMode.PLACE:
			highlight_sprite.modulate = Color(0, 1, 0, 0.5)  # Green
		InteractionMode.REMOVE:
			highlight_sprite.modulate = Color(1, 0, 0, 0.5)  # Red
		InteractionMode.QUERY:
			highlight_sprite.modulate = Color(0, 0.5, 1, 0.5)  # Blue

func _handle_mouse_input():
	# Main interactions
	if Input.is_action_just_pressed("place_block"):
		_handle_place_block()
	
	if Input.is_action_just_pressed("remove_block"):
		_handle_remove_block()

func _handle_place_block():
	print("=== PLACE BLOCK ATTEMPT ===")
	print("world_api exists: ", world_api != null)
	print("is_position_valid: ", is_position_valid)
	print("current_mode: ", InteractionMode.keys()[current_mode])
	print("hovered_position: ", hovered_position)
	
	if not world_api:
		print("ERROR: world_api is null!")
		return
	
	if current_mode != InteractionMode.PLACE:
		print("Not in PLACE mode, skipping")
		return
	
	# Place block at hovered position (or above if occupied)
	var place_pos = hovered_position
	var existing_block = world_api.get_block(place_pos)
	if existing_block:
		place_pos.y += 1  # Place above
	
	world_api.add_block(place_pos, selected_block_type)
	print("Placed ", selected_block_type, " at ", place_pos)
	if renderer:
		renderer.render_world()

func _handle_remove_block():
	if not world_api or not is_position_valid:
		return
	
	var block = world_api.get_block(hovered_position)
	if block:
		world_api.remove_block(hovered_position)
		print("Removed block at ", hovered_position)
		if renderer:
			renderer.render_world()

func _query_block(pos: Vector3i):
	if not world_api:
		return
	
	var block = world_api.get_block(pos)
	if block:
		print("=== Block Query ===")
		print("Position: ", pos)
		print("Type: ", block.get_type_id())
		print("HP: ", block.hp, "/", block.block_type.max_hp)
		print("Height: ", block.height)
		print("Light Level: ", block.light_level)
		print("Revealed: ", block.is_revealed)
		if block.block_type:
			print("Solid: ", block.block_type.is_solid)
			print("Opaque: ", block.block_type.is_opaque)
			print("Climbable: ", block.block_type.is_climbable)
			print("Emits Light: ", block.block_type.emits_light)
		print("==================")
	else:
		print("No block at ", pos)

func cycle_mode():
	current_mode = (current_mode + 1) % 4 as InteractionMode
	interaction_mode_changed.emit(current_mode)
	print("Interaction mode: ", InteractionMode.keys()[current_mode])
	_update_status_ui()

func set_mode(mode: InteractionMode):
	current_mode = mode
	interaction_mode_changed.emit(current_mode)
	_update_status_ui()

func _update_status_ui():
	if status_label:
		var mode_text = InteractionMode.keys()[current_mode]
		var block_text = selected_block_type.capitalize()
		status_label.text = "Mode: " + mode_text + "\nBlock: " + block_text

func _toggle_fog():
	if fog_system:
		# Reveal area around camera center
		var center_pos = Vector3i(0, 0, 0)
		if camera:
			var viewport_size = get_viewport().get_visible_rect().size
			var world_center = camera.screen_to_world(viewport_size / 2)
			center_pos = Vector3i(roundi(world_center.x), 0, roundi(world_center.z))
		
		fog_system.reveal_area(center_pos, fog_system.revelation_radius * 2)
		print("Revealed area around ", center_pos)

func _world_to_iso(world_pos: Vector3i) -> Vector2:
	var iso_x = (world_pos.x - world_pos.z) * 16
	var iso_y = (world_pos.x + world_pos.z) * 8 - world_pos.y * 32
	return Vector2(iso_x, iso_y)
