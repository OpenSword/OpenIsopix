## OpenIsopix - Fog of War System
## Manages map revelation and exploration

class_name FogOfWarSystem
extends Node

@export var world_api: WorldAPI

## Revelation settings
@export var revelation_radius: float = 8.0
@export var auto_reveal: bool = false

## Global fog state
var is_fog_disabled: bool = false

## Revealed positions cache
var revealed_positions: Dictionary = {}  # [position_key] = true

signal area_revealed(center: Vector3i, radius: float)
signal block_revealed(position: Vector3i)

func _ready():
	pass

## Reveal an area around a position
func reveal_area(center: Vector3i, radius: float = -1.0):
	if radius < 0:
		radius = revelation_radius
	
	var radius_squared = radius * radius
	var int_radius = int(ceil(radius))
	
	for x in range(-int_radius, int_radius + 1):
		for z in range(-int_radius, int_radius + 1):
			for y in range(-2, 3):  # Check a few height levels
				var offset = Vector3i(x, y, z)
				var check_pos = center + offset
				
				# Check if within radius
				var distance_squared = offset.x * offset.x + offset.z * offset.z
				if distance_squared <= radius_squared:
					_reveal_block(check_pos)
	
	area_revealed.emit(center, radius)

## Reveal a single block
func _reveal_block(world_pos: Vector3i):
	var key = _pos_to_key(world_pos)
	
	if revealed_positions.has(key):
		return  # Already revealed
	
	revealed_positions[key] = true
	
	if world_api:
		var block = world_api.get_block(world_pos)
		if block and not block.is_revealed:
			world_api.modify_block(world_pos, "is_revealed", true)
			block_revealed.emit(world_pos)

## Check if a position is revealed
func is_revealed(world_pos: Vector3i) -> bool:
	var key = _pos_to_key(world_pos)
	return revealed_positions.has(key)

## Hide an area (for dynamic fog)
func hide_area(center: Vector3i, radius: float = -1.0):
	if radius < 0:
		radius = revelation_radius
	
	var radius_squared = radius * radius
	var int_radius = int(ceil(radius))
	
	for x in range(-int_radius, int_radius + 1):
		for z in range(-int_radius, int_radius + 1):
			for y in range(-2, 3):
				var offset = Vector3i(x, y, z)
				var check_pos = center + offset
				
				var distance_squared = offset.x * offset.x + offset.z * offset.z
				if distance_squared <= radius_squared:
					_hide_block(check_pos)

func _hide_block(world_pos: Vector3i):
	var key = _pos_to_key(world_pos)
	revealed_positions.erase(key)
	
	if world_api:
		world_api.modify_block(world_pos, "is_revealed", false)

## Reveal entire map (cheat/debug mode)
func reveal_all():
	if not world_api:
		return
	
	for chunk_key in world_api.chunks.keys():
		var chunk = world_api.chunks[chunk_key]
		if chunk.is_loaded:
			var blocks = chunk.get_all_blocks()
			for block in blocks:
				if block:
					_reveal_block(block.position)

## Hide entire map
func hide_all():
	revealed_positions.clear()
	
	if world_api:
		for chunk_key in world_api.chunks.keys():
			var chunk = world_api.chunks[chunk_key]
			if chunk.is_loaded:
				var blocks = chunk.get_all_blocks()
				for block in blocks:
					if block:
						world_api.modify_block(block.position, "is_revealed", false)

## Toggle fog globally (reveal all or hide all)
func toggle_fog_globally():
	is_fog_disabled = not is_fog_disabled
	if is_fog_disabled:
		reveal_all()
		print("Fog disabled - all blocks revealed")
	else:
		hide_all()
		print("Fog enabled - all blocks hidden")

func _pos_to_key(pos: Vector3i) -> String:
	return str(pos.x) + "," + str(pos.y) + "," + str(pos.z)
