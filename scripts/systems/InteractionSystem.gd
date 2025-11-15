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
enum InteractionMode { SELECT, PLACE, REMOVE }
var current_mode: InteractionMode = InteractionMode.SELECT

## Currently selected block type for placement
var selected_block_type: String = "grass"
var selected_block_height_override: float = -1.0  # -1 means use default from block type
var last_selected_block: String = ""  # Track for double-press detection

## Undo/Redo history
var action_history: Array[Dictionary] = []
var history_index: int = -1
const MAX_HISTORY_SIZE: int = 50

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
	# Do nothing on _ready, wait for Main.gd to initialize
	pass

func initialize():
	# This is called by Main.gd after references are set
	_create_highlight_sprite()
	_update_cursor_texture()
	_update_status_ui()

func _process(_delta):
	_update_mouse_position()
	_update_hovered_block()

func _input(event):
	# Handle mouse clicks
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			_handle_place_block()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_handle_remove_block()

func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_block_with_height_toggle("grass")
			KEY_2:
				_select_block_with_height_toggle("stone")
			KEY_3:
				_select_block_with_height_toggle("water")
			KEY_4:
				_select_block_with_height_toggle("wood")
			KEY_5:
				_select_block_with_height_toggle("soil")
			KEY_SPACE:
				cycle_mode()
			KEY_F:
				_toggle_fog()
			KEY_G:
				_toggle_fog_globally()
			KEY_Z:
				if event.ctrl_pressed:
					undo()
			KEY_Y:
				if event.ctrl_pressed:
					redo()

func _create_highlight_sprite():
	highlight_sprite = Sprite2D.new()
	# Add to renderer's world_layer instead of interaction system
	if renderer:
		renderer.world_layer.add_child(highlight_sprite)
	else:
		add_child(highlight_sprite)
	highlight_sprite.z_index = 10000  # Always on top
	highlight_sprite.centered = true  # Ensure sprite is centered on position

func _update_mouse_position():
	mouse_position = get_viewport().get_mouse_position()

func _update_hovered_block():
	if not camera:
		return
	
	# Convert screen position to world position
	var world_pos_3d = camera.screen_to_world(mouse_position)
	var block_pos = Vector3i(
		roundi(world_pos_3d.x),
		0,  # We'll check the topmost block
		roundi(world_pos_3d.z)
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
	if not is_position_valid or not highlight_sprite or not camera:
		if highlight_sprite:
			highlight_sprite.visible = false
		return
	
	highlight_sprite.visible = true
	
	# Always draw the cursor AT the hovered_position in world space (same as blocks)
	var iso_pos = camera.world_to_iso(Vector3(hovered_position.x, hovered_position.y, hovered_position.z))
	
	# Set position directly (cursor is now in world_layer, same as blocks)
	highlight_sprite.position = iso_pos
	
	# Use actual block texture with transparency based on mode
	var alpha = 0.7
	match current_mode:
		InteractionMode.SELECT:
			alpha = 0.5
		InteractionMode.PLACE:
			alpha = 0.8
		InteractionMode.REMOVE:
			alpha = 0.6
	
	highlight_sprite.modulate = Color(1, 1, 1, alpha)

func _handle_place_block():
	if not world_api or not is_position_valid:
		print("ERROR: world_api is null or position invalid!")
		return

	if current_mode == InteractionMode.PLACE:
		# ---
		# --- NEW HYBRID FIX ---
		# ---
		var place_pos = hovered_position
		
		# If cursor is above ground (y > 0), target the block *below* the cursor
		if hovered_position.y > 0:
			place_pos.y -= 1
		# If cursor is on the ground (y == 0), target the block *at* the cursor
		else:
			place_pos.y = 0
		
		print("Placing ", selected_block_type, " at ", place_pos)
		
		# Check if a block already exists at the target location
		var existing_block = world_api.get_block(place_pos)
		var old_block_type = existing_block.get_type_id() if existing_block else null
		
		if existing_block:
			# If it's the same type, do nothing
			if existing_block.get_type_id() == selected_block_type:
				return
			# If it's a different type, remove it first
			world_api.remove_block(place_pos)
		
		# Get the block type's height (use override if set)
		var block_height = _get_selected_block_height()
		
		# Add the new block at the calculated position with correct height
		world_api.add_block(place_pos, selected_block_type, block_height)
		
		# Record action for undo
		_record_action({
			"type": "place",
			"position": place_pos,
			"block_type": selected_block_type,
			"old_block_type": old_block_type
		})
		
		# Keep the cursor at the original hovered position
		
	elif current_mode == InteractionMode.SELECT:
		selected_position = hovered_position
		block_selected.emit(selected_position)
		print("Selected block at: ", selected_position)

func _handle_remove_block():
	if not world_api or not is_position_valid:
		return

	# This allows right-click to always remove, regardless of mode
	var block = world_api.get_block(hovered_position)
	if block:
		var block_type = block.get_type_id()
		world_api.remove_block(hovered_position)
		print("Removed block at ", hovered_position)
		
		# Record action for undo
		_record_action({
			"type": "remove",
			"position": hovered_position,
			"block_type": block_type
		})

func cycle_mode():
	current_mode = (current_mode + 1) % 3 as InteractionMode
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

func _update_cursor_texture():
	if not highlight_sprite:
		return
	
	# Load the actual block SVG texture for the cursor
	var texture_path = "res://assets/blocks/isometric-" + selected_block_type + ".svg"
	var texture = load(texture_path)
	if texture:
		highlight_sprite.texture = texture
		
		# Scale cursor based on selected height
		var display_height = _get_selected_block_height()
		highlight_sprite.scale = Vector2(1, display_height)
	else:
		print("WARNING: Could not load cursor texture: ", texture_path)

func _select_block_with_height_toggle(block_type: String):
	# Check if same block pressed twice
	if selected_block_type == block_type and last_selected_block == block_type:
		# Toggle between default and full height
		var default_height = world_api.get_block_type(block_type).height if world_api else 1.0
		if selected_block_height_override < 0 or selected_block_height_override == default_height:
			# Switch to full height
			selected_block_height_override = 1.0
			print("Selected: ", block_type.capitalize(), " (Full height)")
		else:
			# Switch back to default height
			selected_block_height_override = -1.0
			print("Selected: ", block_type.capitalize(), " (Default height)")
	else:
		# New block type selected, use default height
		selected_block_type = block_type
		selected_block_height_override = -1.0
		print("Selected: ", block_type.capitalize())
	
	last_selected_block = block_type
	_update_cursor_texture()
	_update_status_ui()

func _get_selected_block_height() -> float:
	# Return override height if set, otherwise use block type's default
	if selected_block_height_override >= 0:
		return selected_block_height_override
	var block_type = world_api.get_block_type(selected_block_type) if world_api else null
	return block_type.height if block_type else 1.0

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

func _toggle_fog_globally():
	if fog_system:
		fog_system.toggle_fog_globally()

func _record_action(action: Dictionary):
	# Clear any redo history when a new action is recorded
	if history_index < action_history.size() - 1:
		action_history.resize(history_index + 1)
	
	# Add the new action
	action_history.append(action)
	history_index += 1
	
	# Limit history size
	if action_history.size() > MAX_HISTORY_SIZE:
		action_history.pop_front()
		history_index = MAX_HISTORY_SIZE - 1
	
	print("Action recorded: ", action["type"], " at ", action["position"])

func undo():
	if history_index < 0 or action_history.is_empty():
		print("Nothing to undo")
		return
	
	var action = action_history[history_index]
	history_index -= 1
	
	match action["type"]:
		"place":
			# Undo a place: remove the placed block
			world_api.remove_block(action["position"])
			# If there was an old block, restore it
			if action["old_block_type"]:
				world_api.add_block(action["position"], action["old_block_type"])
			print("Undone place at ", action["position"])
		
		"remove":
			# Undo a remove: restore the removed block
			world_api.add_block(action["position"], action["block_type"])
			print("Undone remove at ", action["position"])

func redo():
	if history_index >= action_history.size() - 1:
		print("Nothing to redo")
		return
	
	history_index += 1
	var action = action_history[history_index]
	
	match action["type"]:
		"place":
			# Redo a place: remove old block if any, then place new block
			if action["old_block_type"]:
				world_api.remove_block(action["position"])
			world_api.add_block(action["position"], action["block_type"])
			print("Redone place at ", action["position"])
		
		"remove":
			# Redo a remove: remove the block again
			world_api.remove_block(action["position"])
			print("Redone remove at ", action["position"])
