# OpenIsopix - Debugging & Testing Guide

## Project Setup

### Requirements

- Godot Engine 4.3 or later
- Windows/Linux/macOS

### Opening the Project

1. Clone or download the repository
2. Open Godot Engine
3. Click "Import" and select the `project.godot` file
4. Click "Import & Edit"

### Running the Demo

1. Press F5 or click the "Play" button
2. The main scene (`scenes/Main.tscn`) will launch automatically

## Debug Tools

### Console Output

The demo prints useful debug information:
- Block placement/removal confirmations
- Interaction mode changes
- Block queries (position, type, attributes)
- System initialization messages

### In-Game Debug Commands

Press the following keys to test features:

1. **World Manipulation**
   - `1-4`: Select block type (Grass/Stone/Water/Torch)
   - `LMB`: Place selected block
   - `RMB`: Remove block at cursor
   - `Space`: Cycle interaction modes (SELECT/PLACE/REMOVE/QUERY)

2. **Camera Controls**
   - `Arrow Keys`: Pan camera
   - `Q/E`: Rotate heading (90° increments)
   - `P`: Cycle pitch (LOW/NORMAL/HIGH/TOP_DOWN)
   - `+/-` or `Mouse Wheel`: Zoom in/out

3. **System Testing**
   - `F`: Reveal fog of war around cursor
   - Click blocks in QUERY mode: Print block attributes

### Query Mode

Set interaction mode to QUERY (press Space until mode shows "QUERY"), then click any block to see:

```
=== Block Query ===
Position: (x, y, z)
Type: block_type_id
HP: current/max
Height: 0.5 or 1.0
Light Level: 0.0 to 1.0
Revealed: true/false
Solid: true/false
Opaque: true/false
Climbable: true/false
Emits Light: true/false
==================
```

## Testing Scenarios

### 1. Block Management

**Test: Add and Remove Blocks**
```
1. Press '1' to select Grass
2. Left-click empty spaces to place grass blocks
3. Right-click placed blocks to remove them
4. Press '2' to select Stone, repeat
```

**Expected**: Blocks appear/disappear correctly, world updates immediately

### 2. Chunk System

**Test: Chunk Loading**
```
1. Move camera far from origin (use arrow keys)
2. Place blocks in different areas
3. Return to origin
```

**Expected**: Blocks persist, chunks load/unload seamlessly

### 3. Lighting System

**Test: Light Sources**
```
1. Press '4' to select Torch
2. Place torches in different locations
3. Observe lighting on nearby blocks
4. Remove torches and watch lighting update
```

**Expected**: 
- Torches emit yellow-orange light
- Light attenuates with distance
- Blocks in darkness are darker
- Lighting updates when torches are added/removed

### 4. Fog of War

**Test: Map Revelation**
```
1. Notice some areas are semi-transparent (unrevealed)
2. Press 'F' to reveal area around cursor
3. Move camera to unrevealed areas
4. Press 'F' to reveal more
```

**Expected**:
- Unrevealed blocks are transparent/dim
- Revealed blocks are fully visible
- Revelation persists

### 5. Camera System

**Test: Point of View Changes**
```
1. Press 'Q' repeatedly - world rotates counter-clockwise
2. Press 'E' repeatedly - world rotates clockwise
3. Press 'P' repeatedly - camera pitch changes (4 levels)
4. Use mouse wheel or +/- to zoom
```

**Expected**:
- Each rotation is 90° (4 total headings)
- Pitch changes vertical viewing angle
- Zoom maintains center point
- Movement controls adjust to rotation

### 6. Interaction Modes

**Test: Mode Switching**
```
1. Press Space to cycle modes: SELECT → PLACE → REMOVE → QUERY
2. Observe cursor highlight color changes:
   - SELECT: Yellow
   - PLACE: Green
   - REMOVE: Red
   - QUERY: Blue
```

**Expected**: Mode changes reflected in cursor and behavior

### 7. Block Heights

**Test: Multi-Level Building**
```
1. Place a block at ground level (y=0)
2. Click the same position - new block appears on top (y=1)
3. Continue clicking to stack blocks
4. Right-click to remove top blocks first
```

**Expected**: Blocks stack vertically, removal works top-to-bottom

## Common Issues & Solutions

### Issue: Blocks Not Appearing

**Possible Causes:**
1. Camera too far from world origin
2. Blocks placed outside visible area
3. Renderer not connected to WorldAPI

**Solution:**
- Reset camera position to (0, 0)
- Check console for errors
- Verify `renderer.world_api` is set in Main scene

### Issue: Input Not Working

**Possible Causes:**
1. UI overlay capturing input
2. Wrong scene running
3. Input map not configured

**Solution:**
- Ensure Main.tscn is running
- Check Project Settings → Input Map
- Verify mouse is not over UI panels

### Issue: Lighting Not Updating

**Possible Causes:**
1. LightingSystem not processing
2. Too many blocks causing queue backlog
3. WorldAPI not connected to lighting system

**Solution:**
- Check `lighting_system.world_api` reference
- Reduce world size for testing
- Verify signals are connected

### Issue: Fog Not Working

**Possible Causes:**
1. FogSystem not initialized
2. Starting area not revealed
3. Fog disabled in settings

**Solution:**
- Check `_generate_demo_world()` calls `fog_system.reveal_area()`
- Manually press 'F' to reveal
- Verify `fog_system.world_api` is set

## Unit Testing

### Manual Test Checklist

Create `tests/manual_tests.md` and track:

- [ ] Place blocks of each type
- [ ] Remove blocks
- [ ] Rotate camera all 4 directions
- [ ] Test all 4 pitch levels
- [ ] Zoom in to max
- [ ] Zoom out to min
- [ ] Place torch and verify lighting
- [ ] Remove torch and verify lighting updates
- [ ] Reveal fog of war
- [ ] Query block in QUERY mode
- [ ] Stack blocks vertically
- [ ] Move camera to chunk boundaries
- [ ] Place blocks across multiple chunks
- [ ] Test all interaction modes

### Automated Testing (Future)

For automated tests, use Godot's GUT framework:

```gdscript
# Example test structure
extends GutTest

var world_api: WorldAPI

func before_each():
    world_api = WorldAPI.new()
    add_child(world_api)

func test_add_block():
    var block = world_api.add_block(Vector3i(0, 0, 0), "grass")
    assert_not_null(block)
    assert_eq(block.get_type_id(), "grass")

func test_remove_block():
    world_api.add_block(Vector3i(0, 0, 0), "grass")
    world_api.remove_block(Vector3i(0, 0, 0))
    var block = world_api.get_block(Vector3i(0, 0, 0))
    assert_null(block)
```

## Performance Profiling

### Using Godot Profiler

1. Run project (F5)
2. Go to Debugger tab → Profiler
3. Monitor key metrics:
   - **FPS**: Should stay above 60
   - **Process Time**: Watch for spikes
   - **Physics Time**: Should be minimal (no physics used)
   - **Script Functions**: Check WorldAPI and Renderer calls

### Optimization Checkpoints

Monitor these values during gameplay:

- **Block Count**: < 10,000 for smooth performance
- **Chunk Count**: Only nearby chunks loaded (determined by `chunk_load_distance`)
- **Sprite Count**: One sprite per visible block
- **Light Updates**: Max 100 per frame (controlled by `LightingSystem._process`)

### Memory Usage

Check memory in Debugger → Monitor:
- **Object Count**: Should stabilize after world generation
- **Resource Count**: Textures cached, not recreated
- **Memory**: Should not continuously increase

## Debugging Scripts

### Enable Verbose Logging

Add to any script:

```gdscript
const DEBUG = true

func _log(message: String):
    if DEBUG:
        print("[", get_script().get_path().get_file(), "] ", message)
```

### Visualize Chunk Boundaries

Add to `IsometricRenderer`:

```gdscript
func _draw_chunk_boundaries():
    for chunk_key in world_api.chunks.keys():
        var chunk = world_api.chunks[chunk_key]
        var min_pos = chunk.min_bound
        var max_pos = chunk.max_bound
        # Draw rectangles at chunk edges
        # (implement using Line2D nodes)
```

### Inspect World State

At any time in code:

```gdscript
func _print_world_stats():
    print("=== World Stats ===")
    print("Chunks loaded: ", world_api.chunks.size())
    var total_blocks = 0
    for chunk in world_api.chunks.values():
        total_blocks += chunk.get_all_blocks().size()
    print("Total blocks: ", total_blocks)
    print("Block types: ", world_api.block_types.keys())
    print("==================")
```

## Continuous Integration

For automated testing in CI/CD:

```bash
# Example GitHub Actions workflow
- name: Run Godot Tests
  run: |
    godot --headless --path . --script tests/run_tests.gd
```

## Getting Help

If issues persist:

1. Check console output for errors
2. Verify all node paths in scenes match script expectations
3. Ensure Godot version is 4.3+
4. Review API.md for correct usage
5. Create minimal reproduction scene
6. Report issues with:
   - Console output
   - Steps to reproduce
   - Expected vs actual behavior
   - Godot version and OS
