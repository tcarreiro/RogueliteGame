class_name ItemStack extends Resource
## One slot of an ItemContainer: every real Loot instance of the same species (same id)
## when Loot has 'uuid'.
## Each instance keeps its own state (effects, durability...), like a collapsible stack
## in Project Zomboid. `quantity` is simply how many instances there are.
## If Loot doesn't have 'uuid', saves only one instance and keep track of quantity in
## common_quantity
## Only the owning ItemContainer should call add_item / remove_item / pop_item.

## Returned by get_free_space() when the stack has no limit.
const UNLIMITED: int = 1 << 30

## For non-unique Loot (no UUID), saves only one instance at items[0]
@export var items: Array[Loot] = []
## Used only for non-unique Loot (no UUID)
@export var common_quantity: int = 0
@export var _unique: bool = false

var quantity: int:
	get:
		return items.size() if _unique else common_quantity


# Defaults are required: Godot calls _init() with no arguments when loading a .tres
func _init(p_items: Array[Loot] = []) -> void:
	if not p_items.is_empty():
		if "uuid" in p_items[0]:
			items = p_items.duplicate()
			common_quantity = 0
			_unique = true
		else:
			items = [p_items[0].duplicate()]
			common_quantity = p_items.size()
			_unique = false


static func has_identity(p_loot: Loot) -> bool:
	return "uuid" in p_loot


func is_empty() -> bool:
	return items.is_empty()


func get_loot_id() -> StringName:
	return &"" if items.is_empty() else items[0].id


## Any instance, for display (name, icon). Do not rely on it for per-instance state.
func get_sample() -> Loot:
	return null if items.is_empty() else items[0]


func get_max_stack() -> int:
	return 1 if items.is_empty() else items[0].get_max_stack()


func get_free_space() -> int:
	if items.is_empty():
		return 0
	var limit := get_max_stack()
	if limit == 0:
		return UNLIMITED
	return maxi(limit - quantity, 0)


func is_full() -> bool:
	return get_free_space() == 0


## The units at positions [p_start, p_start + p_count) of the stack, as a flat list.
## Unique: the real instances, in order. Common: the representative repeated once per unit.
## The range is clamped to the stack, so asking for more than it has just returns what exists.
func get_units(p_start: int, p_count: int) -> Array[Loot]:
	var units: Array[Loot] = []
	var first := clampi(p_start, 0, quantity)
	var last := clampi(p_start + p_count, first, quantity)
	if _unique:
		for i in range(first, last):
			units.append(items[i])
	else:
		for i in range(last - first):
			units.append(items[0])
	return units


## Every unit of the stack. Unique: each instance. Common: the representative once per unit.
func get_all_units() -> Array[Loot]:
	return get_units(0, quantity)


## The first `p_count` units, in stack order.
func get_first_units(p_count: int) -> Array[Loot]:
	return get_units(0, p_count)


## The last `p_count` units, in stack order (the ones that leave first in a split or merge).
func get_last_units(p_count: int) -> Array[Loot]:
	var count := clampi(p_count, 0, quantity)
	return get_units(quantity - count, count)


## Can `p_loot` join this stack?
## Same id, the same kind (unique with unique, common with common), and both stackable.
## Differences in state (effects, durability) do NOT matter.
## Whether the stack still has room is a separate question: see get_free_space().
func accepts(p_loot: Loot) -> bool:
	if p_loot == null or items.is_empty():
		return false
	if p_loot.id != items[0].id:
		return false
	if _unique != has_identity(p_loot):
		return false
	return p_loot.can_stack() and items[0].can_stack()


func contains(p_loot: Loot) -> bool:
	return find_index_of(p_loot) != -1


func find_index_of(p_loot: Loot) -> int:
	if p_loot == null:
		return -1
	if _unique:
		return items.find(p_loot)
	return items.find_custom(func(l: Loot): return l.id == p_loot.id)


func add_item(p_loot: Loot) -> void:
	if p_loot == null:
		return
	if items.is_empty():
		items.append(p_loot)
		_unique = has_identity(p_loot)
		if not _unique:
			common_quantity = 1
		return
	if not accepts(p_loot) or is_full():
		return
	# Unique items preserve their instances.
	if _unique:
		items.append(p_loot)
		return
	# Common items share one representative instance.
	common_quantity += 1


func remove_item(p_loot: Loot) -> bool:
	if p_loot == null or items.is_empty():
		return false
	var index := find_index_of(p_loot)
	if index == -1:
		return false
	if _unique:
		items.remove_at(index)
		return true
	common_quantity -= 1
	if common_quantity == 0:
		items.clear()
	return true


func pop_item() -> Loot:
	if items.is_empty():
		return null
	if not _unique:
		common_quantity -= 1
		var dupe:= items[0].duplicate()
		if common_quantity == 0:
			items.clear()
		return dupe
	return items.pop_back()


func is_unique() -> bool:
	return _unique
