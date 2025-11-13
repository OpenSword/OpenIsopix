## OpenIsopix - World Manager API
## Core API for world interaction - decoupled from UI

class_name WorldAPI
extends Node

## Signals for world events
signal block_added(position: Vector3i, block: BlockInstance)
signal block_removed(position: Vector3i)
signal block_modified(position: Vector3i, block: BlockInstance)
signal block_clicked(position: Vector3i, block: BlockInstance)
signal block_walked_over(position: Vector3i, block: BlockInstance)
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)
signal lighting_changed(position: Vector3i, light_level: float)

const CHUNK_SIZE = 16

## All loaded chunks [chunk_pos_key] = Chunk
var chunks: Dictionary = {}

## Block type registry [type_id] = BlockType
var block_types: Dictionary = {}

## Chunk load distance (in chunks)
@export var chunk_load_distance: int = 3

func _ready():
	_register_default_block_types()

## Register a new block type
func register_block_type(block_type: BlockType) -> void:
	if block_type.id.is_empty():
		push_error("Cannot register block type with empty ID")
		return
	block_types[block_type.id] = block_type

## Get a registered block type
func get_block_type(type_id: String) -> BlockType:
	return block_types.get(type_id)

## Add a block to the world
func add_block(world_pos: Vector3i, type_id: String, height: float = 1.0) -> BlockInstance:
	var block_type = get_block_type(type_id)
	if not block_type:
		push_error("Unknown block type: " + type_id)
		return null
	
	var chunk_pos = _world_to_chunk_pos(world_pos)
	var chunk = _get_or_create_chunk(chunk_pos)
	var local_pos = _world_to_local_pos(world_pos)
	
	var block = BlockInstance.new(world_pos, block_type, height)
	chunk.set_block(local_pos, block)
	
	block_added.emit(world_pos, block)
	return block

## Remove a block from the world
func remove_block(world_pos: Vector3i) -> void:
	var chunk_pos = _world_to_chunk_pos(world_pos)
	var chunk = _get_chunk(chunk_pos)
	if not chunk:
		return
	
	var local_pos = _world_to_local_pos(world_pos)
	chunk.remove_block(local_pos)
	block_removed.emit(world_pos)

## Get a block at world position
func get_block(world_pos: Vector3i) -> BlockInstance:
	var chunk_pos = _world_to_chunk_pos(world_pos)
	var chunk = _get_chunk(chunk_pos)
	if not chunk:
		return null
	
	var local_pos = _world_to_local_pos(world_pos)
	return chunk.get_block(local_pos)

## Modify a block's properties
func modify_block(world_pos: Vector3i, property: String, value: Variant) -> void:
	var block = get_block(world_pos)
	if not block:
		return
	
	match property:
		"hp":
			block.hp = value
		"light_level":
			block.light_level = value
			lighting_changed.emit(world_pos, value)
		"is_revealed":
			block.is_revealed = value
		_:
			block.custom_data[property] = value
	
	block_modified.emit(world_pos, block)

## Query block attributes
func get_block_attribute(world_pos: Vector3i, attribute: String) -> Variant:
	var block = get_block(world_pos)
	if not block:
		return null
	
	match attribute:
		"position": return block.position
		"type_id": return block.get_type_id()
		"hp": return block.hp
		"height": return block.height
		"light_level": return block.light_level
		"is_revealed": return block.is_revealed
		"is_solid": return block.block_type.is_solid if block.block_type else false
		"is_opaque": return block.block_type.is_opaque if block.block_type else false
		"is_climbable": return block.block_type.is_climbable if block.block_type else false
		_: return block.custom_data.get(attribute)

## Load a chunk
func load_chunk(chunk_pos: Vector2i) -> Chunk:
	var chunk = _get_or_create_chunk(chunk_pos)
	if not chunk.is_loaded:
		chunk.is_loaded = true
		chunk_loaded.emit(chunk_pos)
	return chunk

## Unload a chunk
func unload_chunk(chunk_pos: Vector2i) -> void:
	var key = _chunk_pos_to_key(chunk_pos)
	if chunks.has(key):
		chunks[key].is_loaded = false
		chunks.erase(key)
		chunk_unloaded.emit(chunk_pos)

## Get all blocks in a chunk
func get_chunk_blocks(chunk_pos: Vector2i) -> Array[BlockInstance]:
	var chunk = _get_chunk(chunk_pos)
	if not chunk:
		return []
	return chunk.get_all_blocks()

## Trigger block click event
func trigger_block_click(world_pos: Vector3i) -> void:
	var block = get_block(world_pos)
	if block and block.block_type and block.block_type.on_click_enabled:
		block_clicked.emit(world_pos, block)

## Trigger block walk over event
func trigger_block_walk_over(world_pos: Vector3i) -> void:
	var block = get_block(world_pos)
	if block and block.block_type and block.block_type.on_walk_over_enabled:
		block_walked_over.emit(world_pos, block)

## Helper functions
func _world_to_chunk_pos(world_pos: Vector3i) -> Vector2i:
	return Vector2i(
		floori(float(world_pos.x) / CHUNK_SIZE),
		floori(float(world_pos.z) / CHUNK_SIZE)
	)

func _world_to_local_pos(world_pos: Vector3i) -> Vector3i:
	return Vector3i(
		posmod(world_pos.x, CHUNK_SIZE),
		world_pos.y,
		posmod(world_pos.z, CHUNK_SIZE)
	)

func _chunk_pos_to_key(chunk_pos: Vector2i) -> String:
	return str(chunk_pos.x) + "," + str(chunk_pos.y)

func _get_chunk(chunk_pos: Vector2i) -> Chunk:
	var key = _chunk_pos_to_key(chunk_pos)
	return chunks.get(key)

func _get_or_create_chunk(chunk_pos: Vector2i) -> Chunk:
	var key = _chunk_pos_to_key(chunk_pos)
	if not chunks.has(key):
		var chunk = Chunk.new(chunk_pos)
		chunks[key] = chunk
	return chunks[key]

func _register_default_block_types():
	# Register some default block types
	var grass = BlockType.new("grass", "Grass Block")
	grass.is_solid = true
	grass.is_opaque = true
	register_block_type(grass)
	
	var stone = BlockType.new("stone", "Stone Block")
	stone.is_solid = true
	stone.is_opaque = true
	stone.hardness = 2.0
	register_block_type(stone)
	
	var water = BlockType.new("water", "Water")
	water.is_solid = false
	water.is_opaque = false
	water.is_walkable = false
	register_block_type(water)
