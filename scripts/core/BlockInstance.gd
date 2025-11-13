## OpenIsopix - Block Instance

# Represents a single block instance in the world
class_name BlockInstance
extends RefCounted

## Block position in world space (x, y, z)
var position: Vector3i

## Block type reference
var block_type: BlockType

## Current health points
var hp: float

## Custom properties (extensible for game-specific data)
var custom_data: Dictionary = {}

## Height level (0.5 or 1.0)
var height: float = 1.0

## Current lighting level (0.0 to 1.0)
var light_level: float = 1.0

## Whether this block has been revealed (for fog of war)
var is_revealed: bool = false

func _init(p_position: Vector3i, p_block_type: BlockType, p_height: float = 1.0):
	position = p_position
	block_type = p_block_type
	height = p_height
	hp = p_block_type.max_hp if p_block_type else 100.0

func take_damage(amount: float) -> bool:
	hp -= amount
	return hp <= 0

func heal(amount: float) -> void:
	hp = min(hp + amount, block_type.max_hp if block_type else 100.0)

func is_destroyed() -> bool:
	return hp <= 0

func get_type_id() -> String:
	return block_type.id if block_type else ""
