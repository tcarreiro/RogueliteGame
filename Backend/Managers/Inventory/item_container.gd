class_name ItemContainer extends Resource
## Holds ItemStacks. A unique item is just a stack of quantity 1.
## Every mutation is validated first (can_*), applied, and then announced:
## signals are emitted only after the container is consistent, once per operation.

const Fail := ItemContainerOpResult.FailReason

## `quantity` is what actually moved (a partial add reports only what entered).
signal item_added(loot: Loot, quantity: int)
signal item_removed(loot: Loot, quantity: int)
## For the UI: stacks created or whose quantity changed, and stacks that disappeared.
signal stacks_changed(updated: Array[ItemStack], removed: Array[ItemStack])
signal operation_rejected(operation: StringName, result: ItemContainerOpResult)

@export var id: UUID = UUID.new_uuid()
## null = accepts anything.
@export var accept: TagQuery
## 0 = unlimited.
@export var capacity_slots: int = 0:
	set(v):
		capacity_slots = maxi(v, 0)
## Only the container's own methods may change this list.
@export var content: Array[ItemStack] = []


# Defaults are required: Godot calls _init() with no arguments when loading a .tres
func _init(p_accept: TagQuery = null, p_capacity_slots: int = 0) -> void:
	accept = p_accept
	capacity_slots = p_capacity_slots


#region Queries (never change anything)
func can_add(loot: Loot, quantity: int = 1) -> ItemContainerOpResult:
	print("A")
	if loot == null:
		print("B")
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	if quantity <= 0:
		print("C")
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
	if not loot.can_stack():
		if quantity != 1:
			print("D")
			return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
		if not _matching_stacks(loot).is_empty():
			print("E")
			return ItemContainerOpResult.fail(quantity, Fail.DUPLICATE)
	if accept != null:
		var tag_result := accept.query_tags(loot.get_tag_set())
		if tag_result != TagQuery.TagResult.OK:
			print("F")
			return ItemContainerOpResult.fail(quantity, _tag_result_to_fail_reason(tag_result))
	var fit := _how_many_fit(loot, quantity)
	if fit <= 0:
		print("G")
		return ItemContainerOpResult.fail(quantity, Fail.FULL)
	if fit < quantity:
		print("H")
		return ItemContainerOpResult.partial(fit, quantity - fit)
	return ItemContainerOpResult.complete(quantity)


func can_remove(loot: Loot, quantity: int = 1) -> ItemContainerOpResult:
	if loot == null:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	if quantity <= 0:
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
	if not loot.can_stack() and quantity != 1:
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
	var matching := _matching_stacks(loot)
	if matching.is_empty():
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	var available := 0
	for stack in matching:
		available += stack.quantity
	if available < quantity:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_ENOUGH)
	return ItemContainerOpResult.complete(quantity)


## Unique item: this exact instance. Stackable: any stack of the same id.
func contains(loot: Loot) -> bool:
	return not _matching_stacks(loot).is_empty()


func get_all_with_tag(tag: StringName) -> Array[Loot]:
	var matching_stacks: Array[ItemStack] = content.filter(func(s: ItemStack): return s.loot.has_tag(tag))
	return matching_stacks.map(func(s: ItemStack): return s.loot)


## Units of an id, summed over all its stacks.
func get_quantity(loot_id: StringName) -> int:
	var total := 0
	for stack in content:
		if stack.loot.id == loot_id:
			total += stack.quantity
	return total


func used_slots() -> int:
	return content.size()


## A copy of the list. The ItemStacks inside are the live ones: read them, never change them.
func get_all() -> Array[ItemStack]:
	return content.duplicate()
#endregion


#region Mutations
## Complete, partial or fail.
func add(loot: Loot, quantity: int = 1) -> ItemContainerOpResult:
	var result := can_add(loot, quantity)
	if not result.ok:
		return _reject(&"add", result)

	var to_place := result.moved_quantity
	var remaining := to_place
	var updated: Array[ItemStack] = []

	# 1) fill existing compatible stacks, in list order
	if loot.can_stack():
		for stack in content:
			if remaining <= 0:
				break
			if not stack.accepts(loot):
				continue
			var moved := mini(stack.get_free_space(), remaining)
			if moved <= 0:
				continue
			stack.quantity += moved
			remaining -= moved
			updated.append(stack)

	# 2) the rest goes into new stacks of up to max_stack units (0 = all in one)
	var per_stack := loot.get_max_stack()
	while remaining > 0:
		var chunk := remaining if per_stack == 0 else mini(per_stack, remaining)
		var new_stack := ItemStack.new(loot, chunk)
		
		content.append(new_stack)
		updated.append(new_stack)
		remaining -= chunk

	item_added.emit(loot, to_place)
	stacks_changed.emit(updated, [] as Array[ItemStack])
	return result


## All or nothing: asking for more than exists fails with NOT_ENOUGH.
## Takes from the last stack to the first. `payload` is the stored Loot; for a stackable
## it is the shared prototype (see ItemStack), so do not modify it.
func remove(loot: Loot, quantity: int = 1) -> ItemContainerOpResult:
	var check := can_remove(loot, quantity)
	if not check.ok:
		return _reject(&"remove", check)

	var matching := _matching_stacks(loot)
	var stored_loot: Loot = matching[0].loot
	var remaining := quantity
	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []

	for i in range(matching.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var stack := matching[i]
		var taken := mini(stack.quantity, remaining)
		stack.quantity -= taken
		remaining -= taken
		if stack.quantity == 0:
			content.erase(stack)
			removed.append(stack)
		else:
			updated.append(stack)

	item_removed.emit(stored_loot, quantity)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(quantity, stored_loot)
#endregion


#region Internal
## Unique item: the entry holding this exact instance. Stackable: every stack of the same id.
func _matching_stacks(loot: Loot) -> Array[ItemStack]:
	var matching: Array[ItemStack] = []
	if loot == null:
		return matching
	for stack in content:
		if loot.can_stack():
			if stack.accepts(loot):
				matching.append(stack)
		elif stack.loot == loot:
			matching.append(stack)
	return matching


func _how_many_fit(loot: Loot, quantity: int) -> int:
	if capacity_slots == 0:
		return quantity
	var room := 0
	if loot.can_stack():
		for stack in content:
			if stack.accepts(loot):
				room += stack.get_free_space()
				if room >= quantity:
					return quantity
	var free_slots := maxi(capacity_slots - content.size(), 0)
	if free_slots == 0:
		return mini(quantity, room)
	var per_slot := loot.get_max_stack()
	if per_slot == 0:
		return quantity  # a new unlimited stack takes everything
	return mini(quantity, room + free_slots * per_slot)


func _reject(operation: StringName, result: ItemContainerOpResult) -> ItemContainerOpResult:
	operation_rejected.emit(operation, result)
	GameLogger.warn("operationg %s rejected"%[operation])
	return result


## TagQuery does not know ItemContainerOpResult; this container knows both and translates.
func _tag_result_to_fail_reason(tag_result: TagQuery.TagResult) -> ItemContainerOpResult.FailReason:
	match tag_result:
		TagQuery.TagResult.MISSING:
			return Fail.TAG_REJECTED
		TagQuery.TagResult.FORBIDDEN:
			return Fail.TAG_FORBIDDEN
	return Fail.NONE
#endregion
