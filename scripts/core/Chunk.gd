## OpenIsopix - World Chunk

# Represents a 16x16 chunk of blocks
class_name Chunk
extends RefCounted

const CHUNK_SIZE = 16

## Chunk position in chunk coordinates
var chunk_pos: Vector2i

## 3D array of block instances [x][y][z]
## y represents height layers (we support multiple height levels)
var blocks: Array = []

## Whether this chunk is currently loaded
var is_loaded: bool = false

## Chunk bounds (for optimization)
var min_bound: Vector3i
var max_bound: Vector3i

func _init(p_chunk_pos: Vector2i):
	chunk_pos = p_chunk_pos
	min_bound = Vector3i(chunk_pos.x * CHUNK_SIZE, 0, chunk_pos.y * CHUNK_SIZE)
	max_bound = Vector3i((chunk_pos.x + 1) * CHUNK_SIZE, 10, (chunk_pos.y + 1) * CHUNK_SIZE)
	_initialize_blocks()

func _initialize_blocks():
	blocks = []
	for x in range(CHUNK_SIZE):
		blocks.append([])
		for z in range(CHUNK_SIZE):
			blocks[x].append([])

func set_block(local_pos: Vector3i, block: BlockInstance) -> void:
	if not _is_valid_local_pos(local_pos):
		return
	
	# Ensure height array exists
	while blocks[local_pos.x][local_pos.z].size() <= local_pos.y:
		blocks[local_pos.x][local_pos.z].append(null)
	
	blocks[local_pos.x][local_pos.z][local_pos.y] = block

func get_block(local_pos: Vector3i) -> BlockInstance:
	if not _is_valid_local_pos(local_pos):
		return null
	
	if local_pos.y >= blocks[local_pos.x][local_pos.z].size():
		return null
	
	return blocks[local_pos.x][local_pos.z][local_pos.y]

func remove_block(local_pos: Vector3i) -> void:
	if not _is_valid_local_pos(local_pos):
		return
	
	if local_pos.y < blocks[local_pos.x][local_pos.z].size():
		blocks[local_pos.x][local_pos.z][local_pos.y] = null

func _is_valid_local_pos(local_pos: Vector3i) -> bool:
	return (local_pos.x >= 0 and local_pos.x < CHUNK_SIZE and
			local_pos.z >= 0 and local_pos.z < CHUNK_SIZE and
			local_pos.y >= 0)

func to_world_pos(local_pos: Vector3i) -> Vector3i:
	return Vector3i(
		chunk_pos.x * CHUNK_SIZE + local_pos.x,
		local_pos.y,
		chunk_pos.y * CHUNK_SIZE + local_pos.z
	)

func get_all_blocks() -> Array[BlockInstance]:
	var result: Array[BlockInstance] = []
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			for y in range(blocks[x][z].size()):
				var block = blocks[x][z][y]
				if block != null:
					result.append(block)
	return result
