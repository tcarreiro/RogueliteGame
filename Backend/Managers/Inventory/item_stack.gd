class_name ItemStack extends Resource
## One entry of an ItemContainer: a Loot and how many units of it.
## Non-stackable items (max_stack == 1, or with effects) are stacks of quantity 1.
## Stackable loot is treated as a stateless prototype: units share the same instance,
## so never modify an instance that is still standing for other units.

## Returned by get_free_space() when the stack has no limit.
const UNLIMITED: int = 1 << 30

@export var loot: Loot
## Only the owning ItemContainer should change this. 0 is allowed here because the
## container removes the entry the moment it reaches 0.
@export var quantity: int = 0:
	set(v):
		quantity = maxi(v, 0)


# Defaults are required: Godot calls _init() with no arguments when loading a .tres
func _init(p_loot: Loot = null, p_quantity: int = 0) -> void:
	loot = p_loot
	quantity = p_quantity


func get_free_space() -> int:
	if not loot.can_stack():
		return 0
	var limit := loot.get_max_stack()
	if limit == 0:
		return UNLIMITED
	return maxi(limit - quantity, 0)


func is_full() -> bool:
	return get_free_space() == 0


## Can `p_loot` be merged into this stack?
func accepts(p_loot: Loot) -> bool:
	return p_loot != null and loot != null \
		and p_loot.id == loot.id and p_loot.can_stack() and loot.can_stack()
