## OpenIsopix - Lighting System
## Manages environmental and block-emitted lighting

class_name LightingSystem
extends Node

@export var world_api: WorldAPI

## Environmental lighting levels (0.0 to 1.0)
enum EnvironmentalLevel {
	PITCH_BLACK,
	VERY_DARK,
	DARK,
	DIM,
	NORMAL,
	BRIGHT,
	VERY_BRIGHT
}

const LIGHTING_VALUES = {
	EnvironmentalLevel.PITCH_BLACK: 0.1,
	EnvironmentalLevel.VERY_DARK: 0.2,
	EnvironmentalLevel.DARK: 0.4,
	EnvironmentalLevel.DIM: 0.6,
	EnvironmentalLevel.NORMAL: 0.8,
	EnvironmentalLevel.BRIGHT: 0.9,
	EnvironmentalLevel.VERY_BRIGHT: 1.0
}

var current_environmental_level: EnvironmentalLevel = EnvironmentalLevel.NORMAL
var base_light_level: float = 0.8

## Light propagation queue
var light_update_queue: Array[Vector3i] = []

signal lighting_updated(position: Vector3i, light_level: float)

func _ready():
	if world_api:
		world_api.block_added.connect(_on_block_added)
		world_api.block_removed.connect(_on_block_removed)

func _process(_delta):
	# Process light updates in batches
	var updates_per_frame = 100
	while not light_update_queue.is_empty() and updates_per_frame > 0:
		var pos = light_update_queue.pop_front()
		_update_block_lighting(pos)
		updates_per_frame -= 1

## Set environmental lighting level
func set_environmental_level(level: EnvironmentalLevel):
	current_environmental_level = level
	base_light_level = LIGHTING_VALUES[level]
	_recalculate_all_lighting()

## Calculate lighting for a specific block
func calculate_block_lighting(world_pos: Vector3i) -> float:
	var light_level = base_light_level
	
	# Check for nearby light-emitting blocks
	var nearby_light = _get_nearby_light_contribution(world_pos)
	light_level = max(light_level, nearby_light)
	
	# Check for occlusion (blocks above reducing light)
	var occlusion = _calculate_occlusion(world_pos)
	light_level *= (1.0 - occlusion * 0.5)
	
	return clamp(light_level, 0.0, 1.0)

func _get_nearby_light_contribution(world_pos: Vector3i) -> float:
	if not world_api:
		return 0.0
	
	var max_light = 0.0
	var search_radius = 5  # Search in a reasonable radius
	
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			for z in range(-search_radius, search_radius + 1):
				var check_pos = world_pos + Vector3i(x, y, z)
				var block = world_api.get_block(check_pos)
				
				if block and block.block_type and block.block_type.emits_light:
					var distance = world_pos.distance_to(check_pos)
					var light_radius = block.block_type.light_radius / 32.0  # Convert to world units
					
					if distance <= light_radius:
						var attenuation = 1.0 - (distance / light_radius)
						var contribution = block.block_type.light_intensity * attenuation
						max_light = max(max_light, contribution)
	
	return max_light

func _calculate_occlusion(world_pos: Vector3i) -> float:
	if not world_api:
		return 0.0
	
	var occlusion = 0.0
	var check_height = 5  # Check up to 5 blocks above
	
	for y in range(1, check_height + 1):
		var check_pos = world_pos + Vector3i(0, y, 0)
		var block = world_api.get_block(check_pos)
		
		if block and block.block_type and block.block_type.is_opaque:
			occlusion += 0.2  # Each opaque block above reduces light
	
	return clamp(occlusion, 0.0, 1.0)

func _update_block_lighting(world_pos: Vector3i):
	var light_level = calculate_block_lighting(world_pos)
	
	if world_api:
		world_api.modify_block(world_pos, "light_level", light_level)
	
	lighting_updated.emit(world_pos, light_level)

func _recalculate_all_lighting():
	if not world_api:
		return
	
	# Queue all loaded blocks for lighting update
	for chunk_key in world_api.chunks.keys():
		var chunk = world_api.chunks[chunk_key]
		if chunk.is_loaded:
			var blocks = chunk.get_all_blocks()
			for block in blocks:
				if block:
					light_update_queue.append(block.position)

func _propagate_light_from_source(world_pos: Vector3i):
	# Add neighboring blocks to update queue
	var neighbors = [
		world_pos + Vector3i(1, 0, 0),
		world_pos + Vector3i(-1, 0, 0),
		world_pos + Vector3i(0, 1, 0),
		world_pos + Vector3i(0, -1, 0),
		world_pos + Vector3i(0, 0, 1),
		world_pos + Vector3i(0, 0, -1),
	]
	
	for neighbor in neighbors:
		if neighbor not in light_update_queue:
			light_update_queue.append(neighbor)

## Signal handlers
func _on_block_added(position: Vector3i, block: BlockInstance):
	light_update_queue.append(position)
	if block and block.block_type and block.block_type.emits_light:
		_propagate_light_from_source(position)

func _on_block_removed(position: Vector3i):
	light_update_queue.append(position)
	_propagate_light_from_source(position)
