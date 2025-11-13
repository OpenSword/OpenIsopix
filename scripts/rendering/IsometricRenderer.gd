## OpenIsopix - Isometric Renderer
## Renders the block-based world in isometric view

class_name IsometricRenderer
extends Node2D

@export var world_api: WorldAPI
@export var camera: IsometricCamera

## Tile size in pixels
const TILE_SIZE = 32
const HALF_TILE = TILE_SIZE / 2

## Rendering layers
var world_layer: Node2D
var fog_layer: CanvasLayer

## Cache for rendered sprites
var block_sprites: Dictionary = {}  # [world_pos_key] = Sprite2D

## Placeholder textures (will be generated)
var textures: Dictionary = {}

# --- FIX: Do nothing on _ready, wait for Main.gd to initialize ---
func _ready():
	pass

# --- FIX: Renamed _ready() to initialize() ---
func initialize():
	_setup_layers()
	_generate_placeholder_textures()
	
	if world_api:
		world_api.block_added.connect(_on_block_added)
		world_api.block_removed.connect(_on_block_removed)
		world_api.block_modified.connect(_on_block_modified)
		world_api.chunk_loaded.connect(_on_chunk_loaded)
	
	if camera:
		camera.heading_changed.connect(_on_heading_changed)
		camera.pitch_changed.connect(_on_pitch_changed)

func _setup_layers():
	world_layer = Node2D.new()
	# Apply the camera's transform to the world layer
	# This makes all children (sprites) move with the camera
	world_layer.transform = camera.get_transform()
	add_child(world_layer)
	
	fog_layer = CanvasLayer.new()
	fog_layer.layer = 2
	add_child(fog_layer)

func _generate_placeholder_textures():
	# Load SVG textures for block types
	textures["grass"] = load("res://assets/blocks/grass.svg")
	textures["stone"] = load("res://assets/blocks/stone.svg")
	textures["water"] = load("res://assets/blocks/water.svg")
	# --- REMOVED TORCH ---
	# textures["torch"] = load("res://assets/blocks/torch.svg")
	
	print("Loaded block textures: ", textures.keys())

func _create_colored_texture(color: Color) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Add some shading for 3D effect
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if x < 4 or y < 4:  # Top and left edges lighter
				var current = image.get_pixel(x, y)
				image.set_pixel(x, y, current.lightened(0.2))
			elif x >= TILE_SIZE - 4 or y >= TILE_SIZE - 4:  # Bottom and right edges darker
				var current = image.get_pixel(x, y)
				image.set_pixel(x, y, current.darkened(0.2))
	
	return ImageTexture.create_from_image(image)

func render_world():
	# Clear existing sprites
	_clear_all_sprites()
	
	if not world_api:
		return
	
	# Get all chunks and render blocks
	for chunk_key in world_api.chunks.keys():
		var chunk = world_api.chunks[chunk_key]
		if chunk.is_loaded:
			_render_chunk(chunk)

func _render_chunk(chunk: Chunk):
	var blocks = chunk.get_all_blocks()
	
	# Sort blocks by position for proper rendering order (back to front)
	blocks.sort_custom(_sort_blocks_for_rendering)
	
	for block in blocks:
		_render_block(block)

func _render_block(block: BlockInstance):
	if not block or not block.block_type:
		return
	
	var world_pos = block.position
	var key = _world_pos_to_key(world_pos)
	
	# Create sprite if it doesn't exist
	if not block_sprites.has(key):
		var sprite = Sprite2D.new()
		world_layer.add_child(sprite)
		block_sprites[key] = sprite
	
	var sprite = block_sprites[key]
	
	# Set texture
	var texture = textures.get(block.block_type.id)
	if texture:
		sprite.texture = texture
	else:
		print("WARNING: No texture for block type: ", block.block_type.id)
	
	# --- FIX: Use the camera to calculate position ---
	# We pass a Vector3, as the camera's function expects it
	var iso_pos = camera.world_to_iso(Vector3(world_pos.x, world_pos.y + block.height, world_pos.z))
	sprite.position = iso_pos
	
	# --- FIX: Use a normal scale, not 4x ---
	sprite.scale = Vector2(1, 1) 
	
	# Apply lighting
	sprite.modulate = Color(block.light_level, block.light_level, block.light_level, 1.0)
	
	# Apply fog of war
	if not block.is_revealed:
		sprite.modulate.a = 0.3
	
	# Z-index for proper layering
	sprite.z_index = world_pos.x + world_pos.z + world_pos.y * 1000

func _clear_all_sprites():
	for key in block_sprites.keys():
		var sprite = block_sprites[key]
		if sprite:
			sprite.queue_free()
	block_sprites.clear()

func _remove_sprite(world_pos: Vector3i):
	var key = _world_pos_to_key(world_pos)
	if block_sprites.has(key):
		var sprite = block_sprites[key]
		sprite.queue_free()
		block_sprites.erase(key)

func _world_pos_to_key(pos: Vector3i) -> String:
	return str(pos.x) + "," + str(pos.y) + "," + str(pos.z)

func _sort_blocks_for_rendering(a: BlockInstance, b: BlockInstance) -> bool:
	# Sort by depth (back to front for isometric)
	var depth_a = a.position.x + a.position.z + a.position.y * 1000
	var depth_b = b.position.x + b.position.z + b.position.y * 1000
	return depth_a < depth_b

## Signal handlers
func _on_block_added(position: Vector3i, block: BlockInstance):
	_render_block(block)

func _on_block_removed(position: Vector3i):
	_remove_sprite(position)

func _on_block_modified(position: Vector3i, block: BlockInstance):
	_render_block(block)

func _on_chunk_loaded(chunk_pos: Vector2i):
	render_world()

func _on_heading_changed(new_heading):
	# Re-render world with new rotation
	render_world()

func _on_pitch_changed(new_pitch):
	# Re-render world with new pitch
	render_world()