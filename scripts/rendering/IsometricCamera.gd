## OpenIsopix - Camera Controller
## Manages POV (Point of View) with rotation, zoom, and pitch

class_name IsometricCamera
extends Camera2D

## POV settings
enum Heading { NORTH, EAST, SOUTH, WEST }
enum PitchLevel { LOW, NORMAL, HIGH, TOP_DOWN }

## Current POV state
var current_heading: Heading = Heading.NORTH
var current_pitch: PitchLevel = PitchLevel.NORMAL
var current_zoom_level: float = 1.0

## Zoom settings
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1

## Pitch angles (in degrees for visual reference)
const PITCH_ANGLES = {
	PitchLevel.LOW: 30.0,        # Closer to ground
	PitchLevel.NORMAL: 45.0,     # Standard isometric
	PitchLevel.HIGH: 60.0,       # Closer to top-down
	PitchLevel.TOP_DOWN: 90.0    # Pure top-down
}

## Movement settings
@export var pan_speed: float = 500.0
@export var smooth_movement: bool = true
@export var smoothing_factor: float = 5.0

# ---
# --- FIX: All constants are now based on your 48x24(top) 24(side) SVG art ---
# ---
# The top diamond is 48px wide (x=8 to x=56 in the SVG)
const TILE_HALF_WIDTH: float = 24.0 # (was 32.0)
# The top diamond is 24px tall (y=4 to y=28 in the SVG)
const TILE_HALF_HEIGHT: float = 12.0 # (was 16.0)
# The side faces are 24px tall (y=16 to y=40 in the SVG)
const BLOCK_TOP_FACE_HEIGHT: float = 24.0 # (was 24.0, this is correct)

var target_position: Vector2
var velocity: Vector2 = Vector2.ZERO

## Signals
signal heading_changed(new_heading: Heading)
signal pitch_changed(new_pitch: PitchLevel)
signal zoom_changed(new_zoom: float)

func _ready():
	target_position = position
	zoom = Vector2(current_zoom_level, current_zoom_level)

func _process(delta):
	if smooth_movement:
		position = position.lerp(target_position, smoothing_factor * delta)
	else:
		position = target_position
	
	# Handle camera movement
	_handle_movement(delta)

func _handle_movement(delta: float):
	var move_input = Vector2.ZERO
	
	# Get input direction
	if Input.is_action_pressed("ui_left"):
		move_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_input.x += 1
	if Input.is_action_pressed("ui_up"):
		move_input.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_input.y += 1
	
	# Apply rotation to movement based on heading
	var rotated_input = _rotate_input_by_heading(move_input)
	
	# Update target position
	if rotated_input.length() > 0:
		target_position += rotated_input.normalized() * pan_speed * delta / current_zoom_level

func _rotate_input_by_heading(input: Vector2) -> Vector2:
	match current_heading:
		Heading.NORTH:
			return input
		Heading.EAST:
			return Vector2(-input.y, input.x)
		Heading.SOUTH:
			return Vector2(-input.x, -input.y)
		Heading.WEST:
			return Vector2(input.y, -input.x)
	return input

## Rotate camera heading
func rotate_heading(clockwise: bool = true):
	if clockwise:
		current_heading = (current_heading + 1) % 4 as Heading
	else:
		current_heading = (current_heading - 1 + 4) % 4 as Heading
	heading_changed.emit(current_heading)

## Change pitch level
func cycle_pitch():
	current_pitch = (current_pitch + 1) % 4 as PitchLevel
	pitch_changed.emit(current_pitch)

## Zoom in/out
func zoom_camera(zoom_in: bool):
	var zoom_delta = zoom_speed if zoom_in else -zoom_speed
	current_zoom_level = clamp(current_zoom_level + zoom_delta, min_zoom, max_zoom)
	zoom = Vector2(current_zoom_level, current_zoom_level)
	zoom_changed.emit(current_zoom_level)

## Set camera position
func set_camera_position(new_position: Vector2):
	target_position = new_position
	if not smooth_movement:
		position = new_position

## Get current heading as rotation angle
func get_heading_rotation() -> float:
	return current_heading * 90.0

## Get current pitch angle
func get_pitch_angle() -> float:
	return PITCH_ANGLES[current_pitch]

## Convert world position to isometric screen position
func world_to_iso(world_pos: Vector3) -> Vector2:
	var pitch_factor = get_pitch_angle() / 45.0
	
	# Calculate screen x/y for the grid position (x, z)
	# This now uses the correct 24.0 and 12.0
	var iso_x = (world_pos.x - world_pos.z) * TILE_HALF_WIDTH
	var iso_y_xz = (world_pos.x + world_pos.z) * TILE_HALF_HEIGHT * pitch_factor
	
	# Calculate the vertical offset from height (y)
	# This uses the correct 24.0
	var iso_y_height = world_pos.y * BLOCK_TOP_FACE_HEIGHT
	
	# Final position is the grid position minus the height offset
	return Vector2(iso_x, iso_y_xz - iso_y_height)

## Convert screen position to world position (approximate)
func screen_to_world(screen_pos: Vector2) -> Vector3:
	# This function finds the 3D world coordinate (at y=0)
	# that corresponds to a 2D screen position.
	
	var cam_pos = get_screen_center_position()
	
	# This is the mouse's position in pixel space, relative to camera center
	# We ignore the y-offset from height, as we're solving for y=0
	var relative_pos = (screen_pos - cam_pos)
	
	var pitch_factor = get_pitch_angle() / 45.0
	if pitch_factor == 0: pitch_factor = 0.001 # Avoid divide by zero
	
	# Pre-calculate denominators for the inverse transformation
	# This now uses the correct 24.0 and 12.0
	var denom_x = TILE_HALF_WIDTH * 2.0
	var denom_y_xz = TILE_HALF_HEIGHT * 2.0 * pitch_factor
	
	# Inverse transformation (solves for world_x and world_z at y=0)
	var world_x = (relative_pos.x / denom_x) + (relative_pos.y / denom_y_xz)
	var world_z = (relative_pos.y / denom_y_xz) - (relative_pos.x / denom_x)
	
	# We only return the position on the ground plane (y=0)
	# The InteractionSystem is responsible for finding the actual block height
	return Vector3(world_x, 0, world_z)

## Rotate world position based on current heading
func _rotate_world_pos_by_heading(pos: Vector3) -> Vector3:
	match current_heading:
		Heading.NORTH:
			return pos  # No rotation
		Heading.EAST:
			return Vector3(pos.z, pos.y, -pos.x)  # 90° clockwise
		Heading.SOUTH:
			return Vector3(-pos.x, pos.y, -pos.z)  # 180°
		Heading.WEST:
			return Vector3(-pos.z, pos.y, pos.x)  # 270° clockwise
	return pos

## Reverse rotation to get actual world coordinates
func _unrotate_world_pos_by_heading(pos: Vector3) -> Vector3:
	match current_heading:
		Heading.NORTH:
			return pos  # No rotation
		Heading.EAST:
			return Vector3(-pos.z, pos.y, pos.x)  # Reverse 90° clockwise
		Heading.SOUTH:
			return Vector3(-pos.x, pos.y, -pos.z)  # Reverse 180°
		Heading.WEST:
			return Vector3(pos.z, pos.y, -pos.x)  # Reverse 270° clockwise
	return pos