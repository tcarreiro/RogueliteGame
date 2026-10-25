class_name ItemContainer extends Resource
## Holds ItemStacks. Each stack holds every real instance of one species (same id).

const Fail := ItemContainerOpResult.FailReason

signal items_added(loots: Array[Loot])
signal items_removed(loots: Array[Loot])
## For the UI: stacks created or whose contents changed, and stacks that disappeared.
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


## Where a batch would go. Built without touching the container, so can_add_all()
## and add_all() can never disagree.
class AddPlan:
	var result: ItemContainerOpResult
	var placed: Array[Loot] = []
	var not_placed: Array[Loot] = []
	var existing_stacks: Array[ItemStack] = []  # parallel to existing_loots
	var existing_loots: Array[Loot] = []
	var new_stacks: Array[ItemStack] = []


func _init(p_accept: TagQuery = null, p_capacity_slots: int = 0) -> void:
	accept = p_accept
	capacity_slots = p_capacity_slots


#region Queries
func can_add(loot: Loot) -> ItemContainerOpResult:
	return can_add_all(_as_list(loot))


## Rule violations (null, duplicate instance, tags) fail the WHOLE batch.
## Running out of room is different: the batch is partial, and `payload` holds the
## instances that did not enter.
func can_add_all(loots: Array[Loot]) -> ItemContainerOpResult:
	return _evaluate_add(loots).result


func can_remove(loot: Loot) -> ItemContainerOpResult:
	if _find_stack_of(loot) == null:
		return ItemContainerOpResult.fail(1, Fail.NOT_FOUND)
	return ItemContainerOpResult.complete(1)


func can_remove_by_id(loot_id: StringName, quantity: int = 1) -> ItemContainerOpResult:
	if quantity <= 0:
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
	var total := get_quantity(loot_id)
	if total == 0:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	if total < quantity:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_ENOUGH)
	return ItemContainerOpResult.complete(quantity)


## This exact instance.
func contains(loot: Loot) -> bool:
	return _find_stack_of(loot) != null


func get_all_with_tag(tag: StringName) -> Array[Loot]:
	var found_loot := []
	for item_stack: ItemStack in content:
		for item: Loot in item_stack.items:
			if item.has_tag(tag):
				found_loot.append(item)
	return found_loot


## Number of instances of an id, over all its stacks.
func get_quantity(loot_id: StringName) -> int:
	var total := 0
	for stack in content:
		if stack.get_loot_id() == loot_id:
			total += stack.quantity
	return total


## Every instance of an id, in stack order.
func find_by_id(loot_id: StringName) -> Array[Loot]:
	var found: Array[Loot] = []
	for stack in content:
		if stack.get_loot_id() == loot_id:
			found.append_array(stack.items)
	return found


## Every instance in the container, flattened.
func get_all_loot() -> Array[Loot]:
	var all_loot: Array[Loot] = []
	for stack in content:
		all_loot.append_array(stack.items)
	return all_loot


func used_slots() -> int:
	return content.size()


## A copy of the list. The ItemStacks inside are the live ones: read them, never change them.
func get_all() -> Array[ItemStack]:
	return content.duplicate()
#endregion


#region Mutations
func add(loot: Loot) -> ItemContainerOpResult:
	return add_all(_as_list(loot))


func add_all(loots: Array[Loot]) -> ItemContainerOpResult:
	var plan := _evaluate_add(loots)
	if not plan.result.ok:
		return _reject(&"add", plan.result)

	var updated: Array[ItemStack] = []
	for i in plan.existing_loots.size():
		var stack := plan.existing_stacks[i]
		stack.add_item(plan.existing_loots[i])
		if not updated.has(stack):
			updated.append(stack)
	for stack in plan.new_stacks:
		content.append(stack)
		updated.append(stack)
	var removed: Array[ItemStack] = []
	items_added.emit(plan.placed)
	stacks_changed.emit(updated, removed)
	return plan.result


## Removes this exact instance. `payload` is the instance.
func remove(loot: Loot) -> ItemContainerOpResult:
	var stack := _find_stack_of(loot)
	if stack == null:
		return _reject(&"remove", ItemContainerOpResult.fail(1, Fail.NOT_FOUND))
	stack.remove_item(loot)
	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []
	if stack.is_empty():
		content.erase(stack)
		removed.append(stack)
	else:
		updated.append(stack)
	var removed_loots: Array[Loot] = [loot]
	items_removed.emit(removed_loots)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(1, loot)


## Consumes `quantity` instances of an id (recipes, costs). All or nothing.
## Takes from the last stack to the first, last instance first. `payload` is the
## Array[Loot] that was removed.
func remove_by_id(loot_id: StringName, quantity: int = 1) -> ItemContainerOpResult:
	var check := can_remove_by_id(loot_id, quantity)
	if not check.ok:
		return _reject(&"remove_by_id", check)

	var removed_loots: Array[Loot] = []
	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []
	var remaining := quantity
	var i := content.size() - 1
	while i >= 0 and remaining > 0:
		var stack := content[i]
		if stack.get_loot_id() == loot_id:
			while remaining > 0 and not stack.is_empty():
				removed_loots.append(stack.pop_item())
				remaining -= 1
			if stack.is_empty():
				content.remove_at(i)
				removed.append(stack)
			else:
				updated.append(stack)
		i -= 1

	items_removed.emit(removed_loots)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(quantity, removed_loots)
#endregion


#region Internal
func _as_list(loot: Loot) -> Array[Loot]:
	return [loot]


func _find_stack_of(loot: Loot) -> ItemStack:
	if loot == null:
		return null
	for stack in content:
		if stack.contains(loot):
			return stack
	return null


func _evaluate_add(loots: Array[Loot]) -> AddPlan:
	var plan := AddPlan.new()
	var requested := loots.size()
	if requested == 0:
		plan.result = ItemContainerOpResult.fail(0, Fail.QTY_INVALID)
		return plan

	# 1) rule violations: nothing moves
	var seen := {}
	for loot in loots:
		if loot == null:
			plan.result = ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)
			return plan
		if seen.has(loot) or _find_stack_of(loot) != null:
			plan.result = ItemContainerOpResult.fail(requested, Fail.DUPLICATE)
			return plan
		seen[loot] = true
		if accept != null:
			var tag_result := accept.query_tags(loot.get_tag_set())
			if tag_result != TagQuery.TagResult.OK:
				plan.result = ItemContainerOpResult.fail(requested, _tag_result_to_fail_reason(tag_result))
				return plan

	# 2) placement, in order: existing stacks, then stacks created by this batch,
	#    then a new slot if there is capacity for one
	var extra := {}  # existing ItemStack -> instances already planned into it
	for loot in loots:
		var target: ItemStack = null
		var target_is_new := false
		if loot.can_stack():
			for stack in content:
				if stack.accepts(loot) and stack.get_free_space() - int(extra.get(stack, 0)) > 0:
					target = stack
					break
			if target == null:
				for stack in plan.new_stacks:
					if stack.accepts(loot) and stack.get_free_space() > 0:
						target = stack
						target_is_new = true
						break
		if target == null:
			if capacity_slots != 0 and content.size() + plan.new_stacks.size() >= capacity_slots:
				plan.not_placed.append(loot)
				continue
			target = ItemStack.new()
			plan.new_stacks.append(target)
			target_is_new = true
		if target_is_new:
			target.add_item(loot)
		else:
			extra[target] = int(extra.get(target, 0)) + 1
			plan.existing_stacks.append(target)
			plan.existing_loots.append(loot)
		plan.placed.append(loot)
	if plan.placed.is_empty():
		plan.result = ItemContainerOpResult.fail(requested, Fail.FULL)
	elif plan.not_placed.is_empty():
		plan.result = ItemContainerOpResult.complete(plan.placed.size())
	else:
		plan.result = ItemContainerOpResult.partial(
			plan.placed.size(), plan.not_placed.size(), plan.not_placed)
	
	return plan


func _reject(operation: StringName, result: ItemContainerOpResult) -> ItemContainerOpResult:
	operation_rejected.emit(operation, result)
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
