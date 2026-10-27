class_name ItemContainer extends Resource
## Holds ItemStacks. Each stack holds every real instance of one species (same id).
## The position of a stack is its index in `_content`: there are no holes. Swapping two
## slots swaps two indexes; dropping on "an empty slot" means moving to the end.
## Every mutation is validated first (can_*), applied, and then announced:
## signals are emitted only after the container(s) are consistent, once per operation.
## Quantities are always counts of instances: adding 3 potions = adding 3 Loot objects.

const Fail := ItemContainerOpResult.FailReason

signal items_added(loots: Array[Loot])
signal items_removed(loots: Array[Loot])
## For the UI: stacks created or whose contents changed, and stacks that disappeared.
signal stacks_changed(updated: Array[ItemStack], removed: Array[ItemStack])
## Stacks changed position inside this container (the list order is the slot order).
signal order_changed()
signal operation_rejected(operation: StringName, result: ItemContainerOpResult)

@export var id: UUID = UUID.new_uuid()
## null = accepts anything.
@export var accept: TagQuery
## Total number of slots in the container. 0 = unlimited.
@export var capacity_slots: int = 0:
	set(v):
		capacity_slots = maxi(v, 0)
## Only the container's own methods may change this list.
@export var _content: Array[ItemStack] = []


## Where a batch would go. Built without touching the container, so can_add_all()
## and add_all() can never disagree.
class AddPlan:
	var result: ItemContainerOpResult
	var placed: Array[Loot] = []
	var not_placed: Array[Loot] = []
	var existing_stacks: Array[ItemStack] = []  # parallel to existing_loots
	var existing_loots: Array[Loot] = []
	var new_stacks: Array[ItemStack] = []


## What a move between two containers would do.
class MovePlan:
	var result: ItemContainerOpResult
	var placed: Array[Loot] = []


## What merging one stack into another would do.
class MergePlan:
	var result: ItemContainerOpResult
	var stack_from: ItemStack
	var stack_to: ItemStack
	var moved: Array[Loot] = []


# Defaults are required: Godot calls _init() with no arguments when loading a .tres
func _init(p_accept: TagQuery = null, p_capacity_slots: int = 0) -> void:
	accept = p_accept
	capacity_slots = p_capacity_slots


#region Queries (never change anything)
func can_add(loot: Loot) -> ItemContainerOpResult:
	return can_add_all(_as_list(loot))


## Rule violations (null, duplicate instance, tags) fail the WHOLE batch.
## Running out of room is different: the batch is partial, and `payload` holds the
## instances that did not enter.
func can_add_all(loots: Array[Loot]) -> ItemContainerOpResult:
	return _evaluate_add(loots).result


func can_remove(loot: Loot) -> ItemContainerOpResult:
	return can_remove_all(_as_list(loot))


## Removal has no "partial": every instance is here, or nothing is removed.
func can_remove_all(loots: Array[Loot]) -> ItemContainerOpResult:
	var requested := loots.size()
	if requested == 0:
		return ItemContainerOpResult.fail(0, Fail.QTY_INVALID)
	var seen := {}
	for loot in loots:
		if loot == null or _find_stack_of(loot) == null:
			return ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)
		if seen.has(loot):
			return ItemContainerOpResult.fail(requested, Fail.DUPLICATE)
		seen[loot] = true
	return ItemContainerOpResult.complete(requested)


func can_remove_by_id(loot_id: StringName, quantity: int = 1) -> ItemContainerOpResult:
	if quantity <= 0:
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)
	var total := get_quantity(loot_id)
	if total == 0:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	if total < quantity:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_ENOUGH)
	return ItemContainerOpResult.complete(quantity)


## Would splitting `quantity` instances from `stack` into `destination` work?
func can_split(stack: ItemStack, quantity: int, destination: ItemContainer) -> ItemContainerOpResult:
	if stack == null or destination == null:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)

	if not _content.has(stack):
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)

	if quantity <= 0 or quantity >= stack.quantity:
		return ItemContainerOpResult.fail(quantity, Fail.QTY_INVALID)

	var loots: Array[Loot] = []
	if stack.is_unique():
		for i in range(stack.quantity - quantity, stack.quantity):
			loots.append(stack.items[i])
	else:
		for i in quantity:
			loots.append(stack.get_sample())

	if destination == self:
		if capacity_slots != 0 and _content.size() >= capacity_slots:
			return ItemContainerOpResult.fail(quantity, Fail.FULL)

		var tag_reason := _tag_fail_reason_for_all(loots)
		if tag_reason != Fail.NONE:
			return ItemContainerOpResult.fail(quantity, tag_reason)

		return ItemContainerOpResult.complete(quantity)

	var addition := destination._evaluate_add(loots)
	if not addition.result.ok:
		return addition.result

	if addition.result.is_partial():
		return ItemContainerOpResult.fail(quantity, Fail.FULL)

	return ItemContainerOpResult.complete(quantity)


## This exact instance.
func contains(loot: Loot) -> bool:
	return _find_stack_of(loot) != null


func get_all_with_tag(tag: StringName) -> Array[Loot]:
	var found_loot := []
	for item_stack: ItemStack in _content:
		for item: Loot in item_stack.items:
			if item.has_tag(tag):
				found_loot.append(item)
	return found_loot


## Number of instances of an id, over all its stacks.
func get_quantity(loot_id: StringName) -> int:
	var total := 0
	for stack in _content:
		if stack.get_loot_id() == loot_id:
			total += stack.quantity
	return total


## Every instance of an id, in stack order.
func find_by_id(loot_id: StringName) -> Array[Loot]:
	var found: Array[Loot] = []
	for stack in _content:
		if stack.get_loot_id() == loot_id:
			found.append_array(stack.items)
	return found


## Every instance in the container, flattened.
func get_all_loot() -> Array[Loot]:
	var all_loot: Array[Loot] = []
	for stack in _content:
		if stack.is_unique():
			all_loot.append_array(stack.items)
		else:
			for i in stack.quantity:
				all_loot.append(stack.get_sample())
	return all_loot


func used_slots() -> int:
	return _content.size()


## A copy of the list. The ItemStacks inside are the live ones: read them, never change them.
func get_all() -> Array[ItemStack]:
	return _content.duplicate()
#endregion


#region Mutations (inside one container)
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
		_content.append(stack)
		updated.append(stack)

	var removed: Array[ItemStack] = []
	items_added.emit(plan.placed)
	stacks_changed.emit(updated, removed)
	return plan.result


## Removes this exact instance. `payload` is the instance.
func remove(loot: Loot) -> ItemContainerOpResult:
	var result := remove_all(_as_list(loot))
	if result.ok:
		result.payload = loot
	return result


## Removes exactly these instances, in one operation (one items_removed, one stacks_changed).
## `payload` is the same Array[Loot], in the order given.
func remove_all(loots: Array[Loot]) -> ItemContainerOpResult:
	var check := can_remove_all(loots)
	if not check.ok:
		return _reject(&"remove", check)

	var affected: Array[ItemStack] = []
	for loot in loots:
		var stack := _find_stack_of(loot)
		stack.remove_item(loot)
		if not affected.has(stack):
			affected.append(stack)

	# a stack is only classified after ALL its instances left
	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []
	for stack in affected:
		if stack.is_empty():
			_content.erase(stack)
			removed.append(stack)
		else:
			updated.append(stack)

	var removed_loots: Array[Loot] = loots.duplicate()
	items_removed.emit(removed_loots)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(removed_loots.size(), removed_loots)


## Consumes `quantity` instances of an id (recipes, costs). All or nothing.
## Takes from the last stack to the first, last instance first. `payload` is the
## Array[Loot] that was removed.
func remove_by_id(loot_id: StringName, quantity: int = 1) -> ItemContainerOpResult:
	var check := can_remove_by_id(loot_id, quantity)
	if not check.ok:
		return _reject(&"remove_by_id", check)
	
	var picked := _pick_from_end(loot_id, quantity)
	var affected: Array[ItemStack] = []
	for loot in picked:
		var stack := _find_stack_of(loot)
		if stack == null:
			continue
		stack.remove_item(loot)
		if not affected.has(stack):
			affected.append(stack)

	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []

	for stack in affected:
		if stack.is_empty():
			_content.erase(stack)
			removed.append(stack)
		else:
			updated.append(stack)

	items_removed.emit(picked)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(picked.size(), picked)


## Moves a whole stack to another position of the same container (the others shift).
## Dropping on an "empty slot" = to_index is the last index.
func move_stack(from_index: int, to_index: int) -> ItemContainerOpResult:
	if not _is_valid_index(from_index) or not _is_valid_index(to_index) or from_index == to_index:
		return _reject(&"move_stack", ItemContainerOpResult.fail(0, Fail.SLOT_INVALID))
	var stack: ItemStack = _content.pop_at(from_index)
	_content.insert(to_index, stack)
	order_changed.emit()
	return ItemContainerOpResult.complete(stack.quantity)
#endregion


#region Operations between containers
## The result is reported (operation_rejected) on the ORIGIN container only.

## Would `move` work? `moved_quantity` counts instances.
static func can_move(from: ItemContainer, to: ItemContainer, loots: Array[Loot], allow_partial: bool = true) -> ItemContainerOpResult:
	return _evaluate_move(from, to, loots, allow_partial).result


## Moves exactly these instances from one container to another.
##  - Rule violations (not in origin, duplicates, tags, same container) fail everything.
##  - No room: with allow_partial, moves what fits (payload = what stayed in the origin);
##    without it, fails with FULL and nothing moves.
## Origin signals are emitted before destination signals, both after both are consistent.
static func move(from: ItemContainer, to: ItemContainer, loots: Array[Loot], allow_partial: bool = true) -> ItemContainerOpResult:
	var plan := _evaluate_move(from, to, loots, allow_partial)
	if not plan.result.ok:
		if from != null:
			from._reject(&"move", plan.result)
		return plan.result

	var removed := from._remove_for_move(plan.placed)
	if not removed.ok:
		return removed  # cannot happen: validated above
	var added := to.add_all(plan.placed)
	if not added.ok:
		from.add_all(plan.placed)  # cannot happen: planned above. Never lose an item.
		return added
	return plan.result


## Moves `quantity` instances of an id (taken from the end of the origin).
static func transfer(from: ItemContainer, to: ItemContainer, loot_id: StringName, quantity: int = 1, allow_partial: bool = true) -> ItemContainerOpResult:
	if from == null:
		return ItemContainerOpResult.fail(quantity, Fail.NOT_FOUND)
	var check := from.can_remove_by_id(loot_id, quantity)
	if not check.ok:
		return from._reject(&"transfer", check)
	return move(from, to, from._pick_from_end(loot_id, quantity), allow_partial)


## The "transfer all" hotkey: everything the origin has, validated against the
## destination's rules and room BEFORE anything moves.
static func transfer_all(from: ItemContainer, to: ItemContainer, allow_partial: bool = true) -> ItemContainerOpResult:
	if from == null:
		return ItemContainerOpResult.fail(0, Fail.NOT_FOUND)
	return move(from, to, from.get_all_loot(), allow_partial)


## Would `swap_stacks` work?
static func can_swap_stacks(a: ItemContainer, index_a: int, b: ItemContainer, index_b: int) -> ItemContainerOpResult:
	if a == null or b == null:
		return ItemContainerOpResult.fail(0, Fail.NOT_FOUND)
	if not a._is_valid_index(index_a) or not b._is_valid_index(index_b):
		return ItemContainerOpResult.fail(0, Fail.SLOT_INVALID)
	if a == b and index_a == index_b:
		return ItemContainerOpResult.fail(0, Fail.SLOT_INVALID)
	var stack_a := a._content[index_a]
	var stack_b := b._content[index_b]
	var affected := stack_a.quantity + stack_b.quantity
	if a != b:
		# Whole stacks trade places, so slot counts and stack sizes do not change:
		# swapping works even when both containers are full. Only the tags can say no.
		var reason := b._tag_fail_reason_for_all(stack_a.items)
		if reason == Fail.NONE:
			reason = a._tag_fail_reason_for_all(stack_b.items)
		if reason != Fail.NONE:
			return ItemContainerOpResult.fail(affected, reason)
		# swap is the one path that does not go through _evaluate_add, so it checks
		# on its own that no instance would end up twice in the same container
		if b._has_other_copy_of(stack_a.items, stack_b) or a._has_other_copy_of(stack_b.items, stack_a):
			return ItemContainerOpResult.fail(affected, Fail.DUPLICATE)
	return ItemContainerOpResult.complete(affected)


## Swaps the stack at slot `index_a` of `a` with the one at `index_b` of `b`.
## Same container: the two stacks trade positions (order_changed).
## Different containers: each stack leaves one and enters the other.
## `moved_quantity` = instances of both stacks.
static func swap_stacks(a: ItemContainer, index_a: int, b: ItemContainer, index_b: int) -> ItemContainerOpResult:
	var check := can_swap_stacks(a, index_a, b, index_b)
	if not check.ok:
		if a != null:
			a._reject(&"swap", check)
		return check

	var stack_a := a._content[index_a]
	var stack_b := b._content[index_b]
	if a == b:
		a._content[index_a] = stack_b
		a._content[index_b] = stack_a
		a.order_changed.emit()
		return check

	# change both containers first, announce afterwards
	a._content[index_a] = stack_b
	b._content[index_b] = stack_a
	var left_a := _get_logical_loots(stack_a)
	var left_b := _get_logical_loots(stack_b)
	var in_a: Array[ItemStack] = [stack_b]
	var out_a: Array[ItemStack] = [stack_a]
	var in_b: Array[ItemStack] = [stack_a]
	var out_b: Array[ItemStack] = [stack_b]
	a.items_removed.emit(left_a)
	a.items_added.emit(left_b)
	a.stacks_changed.emit(in_a, out_a)
	b.items_removed.emit(left_b)
	b.items_added.emit(left_a)
	b.stacks_changed.emit(in_b, out_b)
	return check


## Splits `quantity` instances from `stack` into `destination`.
## Same container: creates a separate stack, without merging.
## Different containers: uses the destination's normal stacking rules.
func split(stack: ItemStack, quantity: int, destination: ItemContainer) -> ItemContainerOpResult:
	var check := can_split(stack, quantity, destination)
	if not check.ok:
		return _reject(&"split", check)

	var loots: Array[Loot] = []
	if stack.is_unique():
		for i in range(stack.quantity - quantity, stack.quantity):
			loots.append(stack.items[i])
	else:
		for i in quantity:
			loots.append(stack.get_sample())

	if destination == self:
		var new_stack: ItemStack
		if stack.is_unique():
			new_stack = ItemStack.new(loots)
		else:
			new_stack = ItemStack.new(loots)

		for loot in loots:
			stack.remove_item(loot)

		_content.append(new_stack)

		var updated: Array[ItemStack] = [stack, new_stack]
		var removed: Array[ItemStack] = []
		stacks_changed.emit(updated, removed)

		var moved: Array[Loot] = loots.duplicate()
		return ItemContainerOpResult.complete(quantity, moved)

	var removed_result := _remove_for_move(loots)
	if not removed_result.ok:
		return removed_result

	var added_result := destination.add_all(loots)
	if not added_result.ok:
		# This should not happen: can_split validated the destination first.
		add_all(loots)
		return added_result

	return ItemContainerOpResult.complete(quantity, loots)


## Same species (same id) and stackable, with room in the target? Then dropping one
## stack on the other should merge them instead of swapping.
static func would_merge(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> bool:
	if from == null or to == null:
		return false
	if not from._is_valid_index(from_index) or not to._is_valid_index(to_index):
		return false
	if from == to and from_index == to_index:
		return false
	var stack_to := to._content[to_index]
	return stack_to.accepts(from._content[from_index].get_sample()) and stack_to.get_free_space() > 0


## Would `merge_stacks` work?
static func can_merge_stacks(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> ItemContainerOpResult:
	return _evaluate_merge(from, from_index, to, to_index).result


## Moves instances of the stack at (from, from_index) into the stack at (to, to_index).
## Both must be the same stackable species. What fits in the target moves, taken from
## the END of the source stack. If everything fits, the source stack disappears;
## otherwise it keeps the rest (partial; payload = the instances that stayed).
## Each instance keeps its own state: effects and durability do not matter here.
static func merge_stacks(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> ItemContainerOpResult:
	var plan := _evaluate_merge(from, from_index, to, to_index)
	
	if not plan.result.ok:
		if from != null:
			from._reject(&"merge", plan.result)
		return plan.result

	# change everything first, announce afterwards
	for loot in plan.moved:
		plan.stack_from.remove_item(loot)
		plan.stack_to.add_item(loot)
	var source_gone := plan.stack_from.is_empty()
	if source_gone:
		from._content.erase(plan.stack_from)

	var updated_from: Array[ItemStack] = []
	var removed_from: Array[ItemStack] = []
	if source_gone:
		removed_from.append(plan.stack_from)
	else:
		updated_from.append(plan.stack_from)
	var updated_to: Array[ItemStack] = [plan.stack_to]
	var no_stacks: Array[ItemStack] = []

	if from == to:
		# the instances never left the container: only the stacks changed
		updated_to.append_array(updated_from)
		from.stacks_changed.emit(updated_to, removed_from)
	else:
		var left: Array[Loot] = plan.moved.duplicate()
		var arrived: Array[Loot] = plan.moved.duplicate()
		from.items_removed.emit(left)
		from.stacks_changed.emit(updated_from, removed_from)
		to.items_added.emit(arrived)
		to.stacks_changed.emit(updated_to, no_stacks)
	return plan.result


## Would `drop_stack` work?
static func can_drop_stack(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> ItemContainerOpResult:
	if would_merge(from, from_index, to, to_index):
		return can_merge_stacks(from, from_index, to, to_index)
	return can_swap_stacks(from, from_index, to, to_index)


## What the UI calls when the player drops a picked stack on a slot:
## same stackable species with room -> merge; anything else -> swap.
static func drop_stack(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> ItemContainerOpResult:
	if would_merge(from, from_index, to, to_index):
		return merge_stacks(from, from_index, to, to_index)
	return swap_stacks(from, from_index, to, to_index)
#endregion


#region Internal
func _as_list(loot: Loot) -> Array[Loot]:
	var list: Array[Loot] = []
	list.append(loot)
	return list


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _content.size()


## Is any of these instances already here, outside of `leaving_stack`?
func _has_other_copy_of(loots: Array[Loot], leaving_stack: ItemStack) -> bool:
	for loot in loots:
		var found := _find_stack_of(loot)
		if found != null and found != leaving_stack:
			return true
	return false


func _find_stack_of(loot: Loot) -> ItemStack:
	if loot == null:
		return null
	for stack in _content:
		if stack.contains(loot):
			return stack
	return null


## `quantity` instances of an id, last stack first, last instance first. Assumes enough exist.
func _pick_from_end(loot_id: StringName, quantity: int) -> Array[Loot]:
	var picked: Array[Loot] = []
	var remaining := quantity

	for i in range(_content.size() - 1, -1, -1):
		var stack := _content[i]
		if stack.get_sample().id != loot_id:
			continue
		if stack.is_unique():
			for j in range(stack.items.size() - 1, -1, -1):
				if remaining <= 0:
					return picked
				picked.append(stack.items[j])
				remaining -= 1
		else:
			var count := mini(remaining, stack.quantity)
			for j in count:
				picked.append(stack.get_sample())
			remaining -= count
		if remaining <= 0:
			return picked
	return picked


func _validate_move_removal(loots: Array[Loot]) -> ItemContainerOpResult:
	var requested := loots.size()
	if requested == 0:
		return ItemContainerOpResult.fail(0, Fail.QTY_INVALID)

	var seen: Dictionary = {}
	var counts: Dictionary = {}

	for loot in loots:
		if loot == null:
			return ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)

		var stack := _find_stack_of(loot)
		if stack == null:
			return ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)

		if stack.is_unique():
			if seen.has(loot):
				return ItemContainerOpResult.fail(requested, Fail.DUPLICATE)
			seen[loot] = true
		elif loot != stack.get_sample():
			return ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)

		counts[stack] = int(counts.get(stack, 0)) + 1

	for stack: ItemStack in counts:
		if counts[stack] > stack.quantity:
			return ItemContainerOpResult.fail(requested, Fail.NOT_ENOUGH)

	return ItemContainerOpResult.complete(requested)


func _remove_for_move(loots: Array[Loot]) -> ItemContainerOpResult:
	var grouped: Dictionary = {}

	for loot in loots:
		var stack := _find_stack_of(loot)
		if not grouped.has(stack):
			grouped[stack] = []
		grouped[stack].append(loot)

	var affected: Array[ItemStack] = []
	for stack: ItemStack in grouped:
		for loot: Loot in grouped[stack]:
			stack.remove_item(loot)
		affected.append(stack)

	var updated: Array[ItemStack] = []
	var removed: Array[ItemStack] = []
	for stack in affected:
		if stack.is_empty():
			_content.erase(stack)
			removed.append(stack)
		else:
			updated.append(stack)

	var removed_loots: Array[Loot] = loots.duplicate()
	items_removed.emit(removed_loots)
	stacks_changed.emit(updated, removed)
	return ItemContainerOpResult.complete(removed_loots.size(), removed_loots)


static func _get_logical_loots(stack: ItemStack) -> Array[Loot]:
	var loots: Array[Loot] = []

	if stack.is_unique():
		loots.append_array(stack.items)
	else:
		for i in stack.quantity:
			loots.append(stack.get_sample())

	return loots


static func _evaluate_merge(from: ItemContainer, from_index: int, to: ItemContainer, to_index: int) -> MergePlan:
	var plan := MergePlan.new()
	if from == null or to == null:
		plan.result = ItemContainerOpResult.fail(0, Fail.NOT_FOUND)
		return plan
	if not from._is_valid_index(from_index) or not to._is_valid_index(to_index):
		plan.result = ItemContainerOpResult.fail(0, Fail.SLOT_INVALID)
		return plan
	if from == to and from_index == to_index:
		plan.result = ItemContainerOpResult.fail(0, Fail.SLOT_INVALID)
		return plan

	plan.stack_from = from._content[from_index]
	plan.stack_to = to._content[to_index]
	var requested := plan.stack_from.quantity
	if not plan.stack_to.accepts(plan.stack_from.get_sample()):
		plan.result = ItemContainerOpResult.fail(requested, Fail.STACK_MISMATCH)
		return plan
	var room := plan.stack_to.get_free_space()
	if room <= 0:
		plan.result = ItemContainerOpResult.fail(requested, Fail.FULL)
		return plan

	var count := mini(requested, room)
	if plan.stack_from.is_unique():
		for i in range(requested - count, requested):
			plan.moved.append(plan.stack_from.items[i])
	else:
		for i in range(count):
			plan.moved.append(plan.stack_from.get_sample())

	## Different containers
	if from != to:
		var reason := to._tag_fail_reason_for_all(plan.moved)
		if reason != Fail.NONE:
			plan.result = ItemContainerOpResult.fail(requested, reason)
			print(reason)
			return plan
		if plan.stack_from.is_unique():
			for loot in plan.moved:
				if to._find_stack_of(loot) != null:
					plan.result = ItemContainerOpResult.fail(requested, Fail.DUPLICATE)
					return plan

	if count == requested:
		plan.result = ItemContainerOpResult.complete(count)
	else:
		var stayed: Array[Loot] = []
		if plan.stack_from.is_unique():
			for i in range(requested - count):
				stayed.append(plan.stack_from.items[i])
		else:
			for i in range(requested - count):
				stayed.append(plan.stack_from.get_sample())
		plan.result = ItemContainerOpResult.partial(count, requested - count, stayed)
	return plan


static func _evaluate_move(from: ItemContainer, to: ItemContainer, loots: Array[Loot], allow_partial: bool) -> MovePlan:
	var plan := MovePlan.new()
	var requested := loots.size()
	if from == null or to == null:
		plan.result = ItemContainerOpResult.fail(requested, Fail.NOT_FOUND)
		return plan
	if from == to:
		plan.result = ItemContainerOpResult.fail(requested, Fail.SAME_CONTAINER)
		return plan
	var removal := from._validate_move_removal(loots)
	if not removal.ok:
		plan.result = removal
		return plan
	var addition := to._evaluate_add(loots)
	if not addition.result.ok:
		plan.result = addition.result
		return plan
	if addition.result.is_partial() and not allow_partial:
		plan.result = ItemContainerOpResult.fail(requested, Fail.FULL)
		return plan
	plan.placed = addition.placed
	plan.result = addition.result
	return plan


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
		var is_unique = "uuid" in loot
		if is_unique:
			if seen.has(loot) or _find_stack_of(loot) != null:
				plan.result = ItemContainerOpResult.fail(requested, Fail.DUPLICATE)
				return plan
		seen[loot] = true
		var tag_reason := _tag_fail_reason(loot)
		if tag_reason != Fail.NONE:
			plan.result = ItemContainerOpResult.fail(requested, tag_reason)
			return plan

	# 2) placement, in order: existing stacks, then stacks created by this batch,
	#    then a new slot if there is capacity for one
	var extra := {}  # existing ItemStack -> instances already planned into it
	for loot in loots:
		var target: ItemStack = null
		var target_is_new := false
		if loot.can_stack():
			for stack in _content:
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
			if capacity_slots != 0 and _content.size() + plan.new_stacks.size() >= capacity_slots:
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
func _tag_fail_reason(loot: Loot) -> ItemContainerOpResult.FailReason:
	if accept == null:
		return Fail.NONE
	return _tag_result_to_fail_reason(accept.query_tags(loot.get_tag_set()))


func _tag_fail_reason_for_all(loots: Array[Loot]) -> ItemContainerOpResult.FailReason:
	for loot in loots:
		var reason := _tag_fail_reason(loot)
		if reason != Fail.NONE:
			return reason
	return Fail.NONE


func _tag_result_to_fail_reason(tag_result: TagQuery.TagResult) -> ItemContainerOpResult.FailReason:
	match tag_result:
		TagQuery.TagResult.MISSING:
			return Fail.TAG_REJECTED
		TagQuery.TagResult.FORBIDDEN:
			return Fail.TAG_FORBIDDEN
	return Fail.NONE
#endregion
