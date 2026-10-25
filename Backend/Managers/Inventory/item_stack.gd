class_name ItemStack extends Resource
## One slot of an ItemContainer: every real Loot instance of the same species (same id).
## Each instance keeps its own state (effects, durability...)
## Only the owning ItemContainer should call add_item / remove_item / pop_item.

## Returned by get_free_space() when the stack has no limit.
const UNLIMITED: int = 1 << 30

@export var items: Array[Loot] = []
var quantity: int:
	get:
		return items.size()


func _init(p_items: Array[Loot] = []) -> void:
	items = p_items.duplicate()


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
	return maxi(limit - items.size(), 0)


func is_full() -> bool:
	return get_free_space() == 0


## Can `p_loot` join this stack? Same id, and both stackable.
## Differences in state (effects, durability) do NOT matter.
func accepts(p_loot: Loot) -> bool:
	return p_loot != null and not items.is_empty() and p_loot.can_stack() \
		and items[0].can_stack() and p_loot.id == items[0].id


func contains(p_loot: Loot) -> bool:
	return items.has(p_loot)


func add_item(p_loot: Loot) -> void:
	items.append(p_loot)


func remove_item(p_loot: Loot) -> bool:
	var index := items.find(p_loot)
	if index == -1:
		return false
	items.remove_at(index)
	return true


func pop_item() -> Loot:
	return null if items.is_empty() else items.pop_back()
