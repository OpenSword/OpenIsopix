# OpenIsopix API Documentation

## Overview

OpenIsopix provides a complete API for building 2D isometric block-based worlds with pixel-art graphics. The system is fully decoupled from UI, allowing easy integration into any game or application.

## Core Components

### 1. WorldAPI (`scripts/core/WorldAPI.gd`)

The main interface for world manipulation. All world interactions should go through this API.

#### Key Methods

```gdscript
# Register a new block type
func register_block_type(block_type: BlockType) -> void

# Add a block to the world
func add_block(world_pos: Vector3i, type_id: String, height: float = 1.0) -> BlockInstance

# Remove a block from the world
func remove_block(world_pos: Vector3i) -> void

# Get a block at world position
func get_block(world_pos: Vector3i) -> BlockInstance

# Modify a block's properties
func modify_block(world_pos: Vector3i, property: String, value: Variant) -> void

# Query block attributes
func get_block_attribute(world_pos: Vector3i, attribute: String) -> Variant

# Chunk management
func load_chunk(chunk_pos: Vector2i) -> Chunk
func unload_chunk(chunk_pos: Vector2i) -> void
func get_chunk_blocks(chunk_pos: Vector2i) -> Array[BlockInstance]

# Trigger events
func trigger_block_click(world_pos: Vector3i) -> void
func trigger_block_walk_over(world_pos: Vector3i) -> void
```

#### Signals

```gdscript
signal block_added(position: Vector3i, block: BlockInstance)
signal block_removed(position: Vector3i)
signal block_modified(position: Vector3i, block: BlockInstance)
signal block_clicked(position: Vector3i, block: BlockInstance)
signal block_walked_over(position: Vector3i, block: BlockInstance)
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)
signal lighting_changed(position: Vector3i, light_level: float)
```

#### Example Usage

```gdscript
# Get reference to WorldAPI
var world_api = get_node("/root/Main/WorldAPI")

# Create a custom block type
var custom_block = BlockType.new("my_block", "My Custom Block")
custom_block.is_solid = true
custom_block.emits_light = true
custom_block.light_color = Color.CYAN
world_api.register_block_type(custom_block)

# Place blocks
world_api.add_block(Vector3i(0, 0, 0), "grass")
world_api.add_block(Vector3i(1, 0, 0), "my_block")

# Query a block
var block = world_api.get_block(Vector3i(0, 0, 0))
if block:
    print("Block type: ", block.get_type_id())
    print("Block HP: ", block.hp)

# Listen for events
world_api.block_added.connect(_on_block_added)
func _on_block_added(pos: Vector3i, block: BlockInstance):
    print("Block added at ", pos)
```

### 2. BlockType (`scripts/core/BlockType.gd`)

Defines a block type with all its properties.

#### Properties

```gdscript
# Identification
@export var id: String
@export var display_name: String

# Behavior flags
@export var is_solid: bool = true
@export var is_opaque: bool = true
@export var is_climbable: bool = false
@export var is_walkable: bool = true

# Visual attributes
@export var texture: Texture2D
@export var animated: bool = false
@export var animation_frames: Array[Texture2D]
@export var emits_light: bool = false
@export var light_color: Color = Color.WHITE
@export var light_intensity: float = 1.0
@export var light_radius: float = 100.0

# Numeric attributes
@export var max_hp: float = 100.0
@export var material_type: String = "generic"
@export var hardness: float = 1.0

# Interaction
@export var on_click_enabled: bool = true
@export var on_walk_over_enabled: bool = false
```

### 3. BlockInstance (`scripts/core/BlockInstance.gd`)

Represents a single block in the world.

#### Properties

```gdscript
var position: Vector3i          # World position
var block_type: BlockType       # Type reference
var hp: float                   # Current health
var height: float = 1.0         # Height (0.5 or 1.0)
var light_level: float = 1.0    # Lighting (0.0 to 1.0)
var is_revealed: bool = false   # Fog of war state
var custom_data: Dictionary     # Extensible properties
```

#### Methods

```gdscript
func take_damage(amount: float) -> bool  # Returns true if destroyed
func heal(amount: float) -> void
func is_destroyed() -> bool
func get_type_id() -> String
```

### 4. Chunk (`scripts/core/Chunk.gd`)

Manages a 16x16 region of blocks.

#### Constants

```gdscript
const CHUNK_SIZE = 16
```

#### Methods

```gdscript
func set_block(local_pos: Vector3i, block: BlockInstance) -> void
func get_block(local_pos: Vector3i) -> BlockInstance
func remove_block(local_pos: Vector3i) -> void
func to_world_pos(local_pos: Vector3i) -> Vector3i
func get_all_blocks() -> Array[BlockInstance]
```

### 5. IsometricCamera (`scripts/rendering/IsometricCamera.gd`)

Controls camera POV with rotation, zoom, and pitch.

#### Enums

```gdscript
enum Heading { NORTH, EAST, SOUTH, WEST }
enum PitchLevel { LOW, NORMAL, HIGH, TOP_DOWN }
```

#### Methods

```gdscript
func rotate_heading(clockwise: bool = true) -> void
func cycle_pitch() -> void
func zoom_camera(zoom_in: bool) -> void
func set_camera_position(new_position: Vector2) -> void
func world_to_iso(world_pos: Vector3) -> Vector2
func screen_to_world(screen_pos: Vector2) -> Vector3
```

#### Signals

```gdscript
signal heading_changed(new_heading: Heading)
signal pitch_changed(new_pitch: PitchLevel)
signal zoom_changed(new_zoom: float)
```

### 6. LightingSystem (`scripts/systems/LightingSystem.gd`)

Manages environmental and block-emitted lighting.

#### Enums

```gdscript
enum EnvironmentalLevel {
    PITCH_BLACK, VERY_DARK, DARK, DIM, 
    NORMAL, BRIGHT, VERY_BRIGHT
}
```

#### Methods

```gdscript
func set_environmental_level(level: EnvironmentalLevel) -> void
func calculate_block_lighting(world_pos: Vector3i) -> float
```

#### Signals

```gdscript
signal lighting_updated(position: Vector3i, light_level: float)
```

### 7. FogOfWarSystem (`scripts/systems/FogOfWarSystem.gd`)

Manages map revelation and exploration.

#### Methods

```gdscript
func reveal_area(center: Vector3i, radius: float = -1.0) -> void
func is_revealed(world_pos: Vector3i) -> bool
func hide_area(center: Vector3i, radius: float = -1.0) -> void
func reveal_all() -> void
func hide_all() -> void
```

#### Signals

```gdscript
signal area_revealed(center: Vector3i, radius: float)
signal block_revealed(position: Vector3i)
```

### 8. InteractionSystem (`scripts/systems/InteractionSystem.gd`)

Handles user input and world interaction.

#### Enums

```gdscript
enum InteractionMode { SELECT, PLACE, REMOVE, QUERY }
```

#### Methods

```gdscript
func cycle_mode() -> void
func set_mode(mode: InteractionMode) -> void
```

#### Signals

```gdscript
signal block_selected(position: Vector3i)
signal block_hovered(position: Vector3i)
signal interaction_mode_changed(mode: InteractionMode)
```

## Complete Example: Creating a Custom Game

```gdscript
extends Node2D

var world_api: WorldAPI
var camera: IsometricCamera
var lighting: LightingSystem

func _ready():
    # Get system references
    world_api = $WorldAPI
    camera = $IsometricCamera
    lighting = $LightingSystem
    
    # Register custom blocks
    _register_custom_blocks()
    
    # Generate world
    _generate_world()
    
    # Setup game logic
    world_api.block_clicked.connect(_on_block_clicked)

func _register_custom_blocks():
    # Create a glowing crystal block
    var crystal = BlockType.new("crystal", "Magic Crystal")
    crystal.is_solid = true
    crystal.is_opaque = false
    crystal.emits_light = true
    crystal.light_color = Color(0.5, 0.0, 1.0)
    crystal.light_intensity = 1.5
    crystal.max_hp = 50.0
    world_api.register_block_type(crystal)
    
    # Create a trap block
    var trap = BlockType.new("trap", "Spike Trap")
    trap.is_solid = true
    trap.on_walk_over_enabled = true
    world_api.register_block_type(trap)
    world_api.block_walked_over.connect(_on_trap_activated)

func _generate_world():
    # Create a 20x20 world
    for x in range(-10, 10):
        for z in range(-10, 10):
            world_api.add_block(Vector3i(x, 0, z), "grass")
    
    # Add some crystals
    world_api.add_block(Vector3i(0, 1, 0), "crystal")
    world_api.add_block(Vector3i(5, 1, 5), "crystal")
    
    # Set darker environment
    lighting.set_environmental_level(LightingSystem.EnvironmentalLevel.DARK)

func _on_block_clicked(pos: Vector3i, block: BlockInstance):
    if block.get_type_id() == "crystal":
        print("Collected magic crystal!")
        world_api.remove_block(pos)

func _on_trap_activated(pos: Vector3i, block: BlockInstance):
    print("Player took damage from trap!")
```

## Architecture Notes

### Decoupling

The system is designed with clear separation:
- **Core**: Data structures and world management (no rendering)
- **Rendering**: Visual representation (uses core data)
- **Systems**: Game logic (lighting, fog, interaction)
- **UI**: User interface (optional, demo only)

### Extensibility

Add new features by:
1. Creating new `BlockType` definitions
2. Using `custom_data` dictionary in `BlockInstance`
3. Connecting to WorldAPI signals
4. Extending systems (create new nodes)

### Performance

- Chunk-based loading (16x16 blocks per chunk)
- Incremental lighting updates (100 blocks per frame)
- Sprite caching for rendered blocks
- Z-index based rendering order

## Input Mapping

Default input actions (defined in `project.godot`):

- `ui_left/right/up/down`: Camera movement
- `zoom_in/out`: Camera zoom
- `rotate_left/right`: Camera rotation (Q/E)
- `change_pitch`: Cycle pitch levels (P)
- `place_block`: Place block (LMB)
- `remove_block`: Remove block (RMB)
- `toggle_fog`: Toggle fog reveal (F)

## Next Steps

1. **Add Custom Blocks**: Create new `BlockType` resources
2. **Implement Game Logic**: Connect to WorldAPI signals
3. **Create Assets**: Replace placeholder textures with pixel art
4. **Extend Systems**: Add entities, AI, procedural generation
5. **Optimize**: Profile and optimize for target platform
