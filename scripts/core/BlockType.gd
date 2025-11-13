## OpenIsopix - Core Block Types

# Represents a single block type definition
class_name BlockType
extends Resource

## Block type identifier (e.g., "grass", "stone", "water")
@export var id: String = ""

## Display name
@export var display_name: String = ""

## Behavior flags
@export var is_solid: bool = true
@export var is_opaque: bool = true
@export var is_climbable: bool = false
@export var is_walkable: bool = true

## Visual attributes
@export var texture: Texture2D = null
@export var animated: bool = false
@export var animation_frames: Array[Texture2D] = []
@export var animation_speed: float = 1.0
@export var emits_light: bool = false
@export var light_color: Color = Color.WHITE
@export var light_intensity: float = 1.0
@export var light_radius: float = 100.0

## Numeric attributes
@export var max_hp: float = 100.0
@export var material_type: String = "generic"
@export var hardness: float = 1.0

## Interaction callbacks (will be handled by signals)
@export var on_click_enabled: bool = true
@export var on_walk_over_enabled: bool = false

func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_texture: Texture2D = null
):
	id = p_id
	display_name = p_display_name
	texture = p_texture

func get_current_frame(time: float) -> Texture2D:
	if not animated or animation_frames.is_empty():
		return texture
	var frame_index = int(time * animation_speed) % animation_frames.size()
	return animation_frames[frame_index]
