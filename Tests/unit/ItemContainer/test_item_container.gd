extends GutTest

#region Initialization and queries
func test_empty_container_has_no_items_or_slots_used() -> void:
	var container := ItemContainer.new()

	assert_eq(container.used_slots(), 0)
	assert_eq(container.get_quantity(&"herb"), 0)
	assert_true(container.get_all_loot().is_empty())
	assert_true(container.get_all().is_empty())


func test_container_accepts_anything_without_tag_query() -> void:
	var container := ItemContainer.new()

	assert_true(container.can_add(MockTestUtils.create_loot()).ok)


func test_get_quantity_counts_instances_across_stacks() -> void:
	var container := ItemContainer.new()
	var herb_a := MockTestUtils.create_loot()
	var herb_b := MockTestUtils.create_loot()

	# Mesmo id: devem ocupar a mesma pilha.
	var result_a := container.add(herb_a)
	var result_b := container.add(herb_b)

	assert_true(result_a.ok)
	assert_true(result_b.ok)
	assert_eq(container.get_quantity(&"herb"), 2)


func test_find_by_id_returns_all_instances() -> void:
	var container := ItemContainer.new()
	var first := MockTestUtils.create_loot()
	var second := MockTestUtils.create_loot()

	container.add(first)
	container.add(second)

	var found := container.find_by_id(&"herb")

	assert_eq(container.get_quantity(&"herb"), 2)
	assert_eq(found.size(), 1)


func test_get_all_returns_a_copy_of_the_stack_list() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_loot())

	var stacks := container.get_all()
	stacks.clear()

	assert_eq(container.used_slots(), 1)
#endregion


#region Adding
func test_add_common_loot_to_empty_container() -> void:
	var container := ItemContainer.new()
	var loot := MockTestUtils.create_loot()

	var result := container.add(loot)

	assert_true(result.ok)
	assert_true(result.is_complete())
	assert_eq(result.moved_quantity, 1)
	assert_eq(container.get_quantity(loot.id), 1)
	assert_eq(container.used_slots(), 1)
	assert_true(container.contains(loot))


func test_add_unique_loot_preserves_instance() -> void:
	var container := ItemContainer.new()
	var loot := MockTestUtils.create_unique_loot()

	var result := container.add(loot)

	assert_true(result.ok)
	assert_true(container.contains(loot))
	assert_same(container.get_all_loot()[0], loot)


func test_add_same_species_to_existing_stack() -> void:
	var container := ItemContainer.new()
	var first := MockTestUtils.create_loot(&"herb", 20)
	var second := MockTestUtils.create_loot(&"herb", 20)

	assert_true(container.add(first).ok)
	var result := container.add(second)

	assert_true(result.ok)
	assert_eq(container.get_quantity(&"herb"), 2)
	assert_eq(container.used_slots(), 1)


func test_add_null_loot_is_rejected() -> void:
	var container := ItemContainer.new()

	var result := container.add(null)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_FOUND)
	assert_eq(container.used_slots(), 0)


func test_add_duplicate_unique_instance_is_rejected() -> void:
	var container := ItemContainer.new()
	var loot := MockTestUtils.create_unique_loot()

	assert_true(container.add(loot).ok)

	var result := container.add(loot)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.DUPLICATE)
	assert_eq(container.get_all_loot().size(), 1)


func test_add_all_rejects_duplicate_in_batch_atomically() -> void:
	var container := ItemContainer.new()
	var loot := MockTestUtils.create_unique_loot()
	var batch: Array[Loot] = [loot, loot]

	var result := container.add_all(batch)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.DUPLICATE)
	assert_eq(container.used_slots(), 0)


func test_add_all_returns_partial_when_slots_are_full() -> void:
	var container := ItemContainer.new(null, 1)
	var first := MockTestUtils.create_unique_loot(&"sword")
	var second := MockTestUtils.create_unique_loot(&"axe")
	var batch: Array[Loot] = [first, second]

	var result := container.add_all(batch)

	assert_true(result.ok)
	assert_true(result.is_partial())
	assert_eq(result.moved_quantity, 1)
	assert_eq(result.remained_quantity, 1)
	assert_eq(result.payload.size(), 1)
	assert_same(result.payload[0], second)
	assert_eq(container.used_slots(), 1)
	assert_true(container.contains(first))
	assert_false(container.contains(second))


func test_add_emits_signals_once_with_added_item() -> void:
	var container := ItemContainer.new()
	var added: Array = []
	var changed: Array = []
	var removed: Array = []

	container.items_added.connect(func(loots): added.append_array(loots))
	container.stacks_changed.connect(func(updated, gone):
		changed.append_array(updated)
		removed.append_array(gone)
	)

	var loot := MockTestUtils.create_loot()
	var result := container.add(loot)

	assert_true(result.ok)
	assert_eq(added.size(), 1)
	assert_eq(added[0], loot)
	assert_eq(changed.size(), 1)
	assert_eq(removed.size(), 0)


func test_add_all_emits_signals_once_for_batch() -> void:
	var container := ItemContainer.new()
	var added_calls: Array = []
	var changed_calls: Array = []

	container.items_added.connect(func(loot_list): added_calls.append_array(loot_list.duplicate()))
	container.stacks_changed.connect(func(updated, gone):
		changed_calls.append({"updated": updated.duplicate(), "removed": gone.duplicate()})
	)

	var loots: Array[Loot] = [
		MockTestUtils.create_loot(&"herb"),
		MockTestUtils.create_loot(&"herb"),
		MockTestUtils.create_loot(&"potion"),
	]

	var result := container.add_all(loots)
	assert_true(result.ok)
	assert_eq(added_calls.size(), 3)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 2)
	assert_eq(changed_calls[0]["removed"].size(), 0)


func test_add_common_item_emits_expected_signals() -> void:
	var container := ItemContainer.new()
	var herb := MockTestUtils.create_loot(&"herb")

	var added_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)
	container.order_changed.connect(func(): order_calls.append(true))

	var result := container.add(herb)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 1)
	assert_eq(container.get_quantity(&"herb"), 1)

	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 1)
	assert_eq(added_calls[0][0].id, &"herb")

	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_eq(changed_calls[0]["removed"].size(), 0)
	assert_eq(order_calls.size(), 0)


func test_add_common_item_to_existing_stack_emits_once() -> void:
	var container := ItemContainer.new()
	var first := MockTestUtils.create_loot(&"herb")
	var second := MockTestUtils.create_loot(&"herb")

	assert_true(container.add(first).ok)

	var added_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)
	container.order_changed.connect(func(): order_calls.append(true))

	var result := container.add(second)

	assert_true(result.ok)
	assert_eq(container.get_quantity(&"herb"), 2)

	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 1)
	assert_eq(added_calls[0][0].id, &"herb")

	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_eq(changed_calls[0]["removed"].size(), 0)
	assert_eq(order_calls.size(), 0)


func test_add_all_common_items_emits_one_batch() -> void:
	var container := ItemContainer.new()
	var loots: Array[Loot] = []

	for i in 3:
		loots.append(MockTestUtils.create_loot(&"herb"))

	var added_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)
	container.order_changed.connect(func(): order_calls.append(true))

	var result := container.add_all(loots)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 3)
	assert_eq(container.get_quantity(&"herb"), 3)

	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 3)
	for loot in added_calls[0]:
		assert_eq(loot.id, &"herb")

	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_eq(changed_calls[0]["removed"].size(), 0)
	assert_eq(order_calls.size(), 0)


func test_add_all_to_existing_common_stack_emits_once() -> void:
	var container := ItemContainer.new()
	assert_true(container.add(MockTestUtils.create_loot(&"herb")).ok)

	var loots: Array[Loot] = []
	for i in 2:
		loots.append(MockTestUtils.create_loot(&"herb"))

	var added_calls: Array = []
	var changed_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)

	var result := container.add_all(loots)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 2)
	assert_eq(container.get_quantity(&"herb"), 3)

	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 2)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_eq(changed_calls[0]["removed"].size(), 0)


func test_add_unique_item_preserves_instance_and_emits_signals() -> void:
	var container := ItemContainer.new()
	var item := MockTestUtils.create_unique_loot(&"sword")
	item.uuid = UUID.new_uuid()

	var added_calls: Array = []
	var changed_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)

	var result := container.add(item)

	assert_true(result.ok)
	assert_eq(container.get_quantity(&"sword"), 1)
	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 1)
	assert_same(added_calls[0][0], item)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_same(changed_calls[0]["updated"][0].items[0], item)


func test_add_all_unique_items_preserves_instances_and_emits_once() -> void:
	var container := ItemContainer.new()
	var items: Array[Loot] = []

	for i in 3:
		var item := MockTestUtils.create_unique_loot(&"sword")
		item.uuid = UUID.new_uuid()
		items.append(item)

	var added_calls: Array = []
	var changed_calls: Array = []

	container.items_added.connect(func(loots): added_calls.append(loots))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({"updated": updated, "removed": removed})
	)

	var result := container.add_all(items)

	assert_true(result.ok)
	assert_eq(container.get_quantity(&"sword"), 3)
	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 3)
	assert_eq(changed_calls.size(), 1)
	for i in items.size():
		assert_same(added_calls[0][i], items[i])

	assert_eq(container._content.size(), items.size())
	for i in items.size():
		var stored_stack: ItemStack = container._content[i]
		assert_eq(stored_stack.items.size(), 1)
		assert_same(stored_stack.items[0], items[i])


func test_add_unique_items_creates_separate_stacks() -> void:
	var container := ItemContainer.new()

	var first := MockTestUtils.create_unique_loot(&"sword")
	first.uuid = UUID.new_uuid()
	var second := MockTestUtils.create_unique_loot(&"sword")
	second.uuid = UUID.new_uuid()

	assert_true(container.add(first).ok)
	var result := container.add(second)

	assert_true(result.ok)
	assert_eq(container.get_quantity(&"sword"), 2)
	assert_eq(container._content.size(), 2)
	assert_same(container._content[0].items[0], first)
	assert_same(container._content[1].items[0], second)


func test_rejected_add_all_duplicate_unique_instance_preserves_container() -> void:
	var container := ItemContainer.new()
	var item := MockTestUtils.create_unique_loot(&"sword")
	item.uuid = UUID.new_uuid()

	var added_calls: Array = []
	var changed_calls: Array = []
	var rejected_calls: Array = []

	container.items_added.connect(func(items_list): added_calls.append(items_list))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var items: Array[Loot] = [item, item]
	var result := container.add_all(items)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.DUPLICATE)
	assert_eq(container.get_quantity(&"sword"), 0)
	assert_eq(container._content.size(), 0)
	assert_eq(added_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
#endregion


#region Tag Restrictions
func test_add_rejects_loot_missing_required_tag() -> void:
	var query := TagQuery.create([&"herb"])
	var container := ItemContainer.new(query)
	var loot := MockTestUtils.create_loot(&"potion")

	var result := container.add(loot)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_REJECTED)
	assert_eq(container.used_slots(), 0)


func test_add_rejects_forbidden_tag() -> void:
	var query := TagQuery.create([], [], ["quest"])
	var container := ItemContainer.new(query)
	var loot := MockTestUtils.create_loot()

	loot.extra_tags.append(&"quest")

	var result := container.add(loot)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_FORBIDDEN)
	assert_eq(container.used_slots(), 0)
#endregion


#region Removing
func test_remove_common_loot_decrements_quantity() -> void:
	var container := ItemContainer.new()
	var first := MockTestUtils.create_loot()
	var second := MockTestUtils.create_loot()

	assert_true(container.add(first).ok)
	assert_true(container.add(second).ok)

	var result := container.remove(first)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 1)
	assert_same(result.payload, first)
	assert_eq(container.get_quantity(&"herb"), 1)
	assert_eq(container.used_slots(), 1)


func test_remove_last_loot_removes_empty_stack() -> void:
	var container := ItemContainer.new()
	var loot := MockTestUtils.create_unique_loot()

	assert_true(container.add(loot).ok)

	var result := container.remove(loot)

	assert_true(result.ok)
	assert_eq(container.used_slots(), 0)
	assert_false(container.contains(loot))


func test_remove_missing_loot_changes_nothing() -> void:
	var container := ItemContainer.new()
	var existing := MockTestUtils.create_unique_loot()
	var missing := MockTestUtils.create_unique_loot()

	assert_true(container.add(existing).ok)

	var result := container.remove(missing)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_FOUND)
	assert_eq(container.used_slots(), 1)
	assert_true(container.contains(existing))


func test_remove_all_is_atomic_when_an_item_is_missing() -> void:
	var container := ItemContainer.new()
	var existing := MockTestUtils.create_unique_loot()
	var missing := MockTestUtils.create_unique_loot()
	var batch: Array[Loot] = [existing, missing]

	assert_true(container.add(existing).ok)

	var result := container.remove_all(batch)

	assert_false(result.ok)
	assert_eq(container.used_slots(), 1)
	assert_true(container.contains(existing))


func test_remove_by_id_rejects_invalid_quantity() -> void:
	var container := ItemContainer.new()

	var result := container.remove_by_id(&"herb", 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.QTY_INVALID)


func test_remove_by_id_rejects_insufficient_quantity() -> void:
	var container := ItemContainer.new()
	assert_true(container.add(MockTestUtils.create_loot()).ok)

	var result := container.remove_by_id(&"herb", 2)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_ENOUGH)
	assert_eq(container.get_quantity(&"herb"), 1)



func test_remove_by_id_removes_multiple_common_items_from_one_stack() -> void:
	var container := ItemContainer.new()
	var items: Array[Loot] = []

	for i in 5:
		items.append(MockTestUtils.create_loot(&"herb", 20))

	assert_true(container.add_all(items).ok)
	assert_eq(container.get_quantity(&"herb"), 5)
	assert_eq(container.used_slots(), 1)

	var result := container.remove_by_id(&"herb", 3)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 3)
	assert_eq(container.get_quantity(&"herb"), 2)
	assert_eq(container.used_slots(), 1)


func test_remove_by_id_removes_all_common_items_from_one_stack() -> void:
	var container := ItemContainer.new()
	var items: Array[Loot] = []

	for i in 3:
		items.append(MockTestUtils.create_loot(&"herb", 20))

	assert_true(container.add_all(items).ok)

	var result := container.remove_by_id(&"herb", 3)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 3)
	assert_eq(container.get_quantity(&"herb"), 0)
	assert_eq(container.used_slots(), 0)


func test_remove_emits_signals_once_with_removed_instance() -> void:
	var container := ItemContainer.new()
	var removed_calls: Array = []
	var changed_calls: Array = []

	var loot := MockTestUtils.create_loot()
	assert_true(container.add(loot).ok)

	container.items_removed.connect(func(loots): removed_calls.append(loots.duplicate()))
	container.stacks_changed.connect(func(updated, gone):
		changed_calls.append({"updated": updated.duplicate(), "removed": gone.duplicate()})
	)

	var result := container.remove(loot)

	assert_true(result.ok)
	assert_eq(removed_calls.size(), 1)
	assert_eq(removed_calls[0].size(), 1)
	assert_eq(removed_calls[0][0], loot)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 0)
	assert_eq(changed_calls[0]["removed"].size(), 1)


func test_remove_all_emits_signals_once_for_batch() -> void:
	var container := ItemContainer.new()
	var removed_calls: Array = []
	var changed_calls: Array = []

	var herb := MockTestUtils.create_loot(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")
	assert_true(container.add_all([herb, potion]).ok)

	container.items_removed.connect(func(loots): removed_calls.append(loots.duplicate()))
	container.stacks_changed.connect(func(updated, gone):
		changed_calls.append({"updated": updated.duplicate(), "removed": gone.duplicate()})
	)

	var result := container.remove_all([herb, potion])

	assert_true(result.ok)
	assert_eq(removed_calls.size(), 1)
	assert_eq(removed_calls[0].size(), 2)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 0)
	assert_eq(changed_calls[0]["removed"].size(), 2)


func test_remove_by_id_emits_one_signal_with_all_removed_units() -> void:
	var container := ItemContainer.new()
	var removed_calls: Array = []
	var changed_calls: Array = []

	var loots: Array[Loot] = []
	for i in 5:
		loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(container.add_all(loots).ok)
	assert_eq(container.used_slots(), 1)

	container.items_removed.connect(func(items): removed_calls.append(items.duplicate()))
	container.stacks_changed.connect(func(updated, gone):
		changed_calls.append({"updated": updated.duplicate(), "removed": gone.duplicate()})
	)

	var result := container.remove_by_id(&"herb", 3)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 3)
	assert_eq(removed_calls.size(), 1)
	assert_eq(removed_calls[0].size(), 3)
	assert_eq(removed_calls[0][0], loots[0])
	assert_eq(removed_calls[0][1], loots[0])
	assert_eq(removed_calls[0][2], loots[0])
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 1)
	assert_eq(changed_calls[0]["removed"].size(), 0)
	assert_eq(container.get_quantity(&"herb"), 2)
#endregion


#region Operations
func test_move_stack_changes_stack_order() -> void:
	var container := ItemContainer.new()
	var sword := MockTestUtils.create_unique_loot(&"sword")
	var shield := MockTestUtils.create_unique_loot(&"shield")
	var potion := MockTestUtils.create_unique_loot(&"potion")

	container.add(sword)
	container.add(shield)
	container.add(potion)

	var result := container.move_stack(0, 2)

	assert_true(result.ok)
	assert_true(result.is_complete())
	assert_eq(result.moved_quantity, 1)

	var stacks := container.get_all()
	assert_same(stacks[0].items[0], shield)
	assert_same(stacks[1].items[0], potion)
	assert_same(stacks[2].items[0], sword)


func test_move_stack_emits_order_changed() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_unique_loot(&"sword"))
	container.add(MockTestUtils.create_unique_loot(&"shield"))

	watch_signals(container)

	container.move_stack(0, 1)

	assert_signal_emitted(container, "order_changed")


func test_move_stack_rejects_invalid_source_index() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_unique_loot(&"sword"))

	var result := container.move_stack(-1, 0)

	assert_false(result.ok)
	assert_eq(container.used_slots(), 1)


func test_move_stack_rejects_invalid_destination_index() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_unique_loot(&"sword"))

	var result := container.move_stack(0, 1)

	assert_false(result.ok)
	assert_eq(container.used_slots(), 1)


func test_move_stack_rejects_same_source_and_destination() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_unique_loot(&"sword"))

	var result := container.move_stack(0, 0)

	assert_false(result.ok)
	assert_eq(container.used_slots(), 1)



func test_swap_common_stacks_between_containers_preserves_quantities() -> void:
	var first := ItemContainer.new()
	var second := ItemContainer.new()
	var herbs: Array[Loot] = []
	var potions: Array[Loot] = []

	for i in 4:
		herbs.append(MockTestUtils.create_loot(&"herb", 20))
	for i in 2:
		potions.append(MockTestUtils.create_loot(&"potion", 20))

	assert_true(first.add_all(herbs).ok)
	assert_true(second.add_all(potions).ok)

	var result := ItemContainer.swap_stacks(first, 0, second, 0)

	assert_true(result.ok)
	assert_eq(first.get_quantity(&"potion"), 2)
	assert_eq(second.get_quantity(&"herb"), 4)
	assert_eq(first.get_quantity(&"herb"), 0)
	assert_eq(second.get_quantity(&"potion"), 0)
	assert_eq(first.used_slots(), 1)
	assert_eq(second.used_slots(), 1)


func test_swap_common_stacks_rejected_by_tags_preserves_both_containers() -> void:
	var herb := MockTestUtils.create_loot(&"herb")
	herb.add_tag(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")
	potion.add_tag(&"potion")

	var herbs := ItemContainer.new(TagQuery.create([&"herb"]))
	var potions := ItemContainer.new(TagQuery.create([&"potion"]))

	assert_true(herbs.add(herb).ok)
	assert_true(potions.add(potion).ok)

	var result := ItemContainer.swap_stacks(herbs, 0, potions, 0)

	assert_false(result.ok)
	assert_eq(herbs.get_quantity(&"herb"), 1)
	assert_eq(potions.get_quantity(&"potion"), 1)
	assert_eq(herbs.used_slots(), 1)
	assert_eq(potions.used_slots(), 1)


func test_rejected_add_emits_only_operation_rejected() -> void:
	var container := ItemContainer.new()
	var added_calls: Array = []
	var changed_calls: Array = []
	var rejected_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(_updated, _gone): changed_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var result := container.add(null)

	assert_false(result.ok)
	assert_eq(added_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"add")
#endregion


#region Swap Stacks
func test_swap_stacks_changes_order_within_same_container() -> void:
	var container := ItemContainer.new()
	var sword := MockTestUtils.create_unique_loot(&"sword")
	var shield := MockTestUtils.create_unique_loot(&"shield")
	var potion := MockTestUtils.create_unique_loot(&"potion")
	container.add_all([sword, shield, potion])

	var result := ItemContainer.swap_stacks(container, 0, container, 2)

	assert_true(result.ok)
	assert_true(result.is_complete())
	assert_eq(result.moved_quantity, 2)
	var stacks := container.get_all()
	assert_same(stacks[0].items[0], potion)
	assert_same(stacks[1].items[0], shield)
	assert_same(stacks[2].items[0], sword)


func test_swap_stacks_emits_order_changed_within_same_container() -> void:
	var container := ItemContainer.new()
	container.add_all([
		MockTestUtils.create_unique_loot(&"sword"),
		MockTestUtils.create_unique_loot(&"shield")
	])
	watch_signals(container)

	ItemContainer.swap_stacks(container, 0, container, 1)

	assert_signal_emitted(container, "order_changed")


func test_swap_stacks_between_containers() -> void:
	var first := ItemContainer.new()
	var second := ItemContainer.new()
	var sword := MockTestUtils.create_unique_loot(&"sword")
	var shield := MockTestUtils.create_unique_loot(&"shield")
	first.add(sword)
	second.add(shield)

	var result := ItemContainer.swap_stacks(first, 0, second, 0)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 2)
	assert_same(first.get_all()[0].items[0], shield)
	assert_same(second.get_all()[0].items[0], sword)
	assert_true(first.contains(shield))
	assert_true(second.contains(sword))


func test_swap_stacks_between_full_containers() -> void:
	var first := ItemContainer.new(null, 1)
	var second := ItemContainer.new(null, 1)
	var sword := MockTestUtils.create_unique_loot(&"sword")
	var shield := MockTestUtils.create_unique_loot(&"shield")
	first.add(sword)
	second.add(shield)

	var result := ItemContainer.swap_stacks(first, 0, second, 0)

	assert_true(result.ok)
	assert_eq(first.used_slots(), 1)
	assert_eq(second.used_slots(), 1)
	assert_same(first.get_all()[0].items[0], shield)
	assert_same(second.get_all()[0].items[0], sword)


func test_swap_stacks_rejects_invalid_index() -> void:
	var container := ItemContainer.new()
	var sword := MockTestUtils.create_unique_loot(&"sword")
	container.add(sword)

	var result := ItemContainer.swap_stacks(container, -1, container, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.SLOT_INVALID)
	assert_eq(container.used_slots(), 1)
	assert_same(container.get_all()[0].items[0], sword)


func test_swap_stacks_rejects_same_slot() -> void:
	var container := ItemContainer.new()
	var sword := MockTestUtils.create_unique_loot(&"sword")
	container.add(sword)

	var result := ItemContainer.swap_stacks(container, 0, container, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.SLOT_INVALID)
	assert_same(container.get_all()[0].items[0], sword)


func test_swap_stacks_rejects_null_container() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_unique_loot(&"sword"))

	var result := ItemContainer.swap_stacks(container, 0, null, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_FOUND)
	assert_eq(container.used_slots(), 1)


func test_swap_common_stacks_emits_all_logical_items() -> void:
	var herbs := ItemContainer.new()
	var potions := ItemContainer.new()
	var herb_loots: Array[Loot] = []
	var potion_loots: Array[Loot] = []

	for i in 5:
		herb_loots.append(MockTestUtils.create_loot(&"herb"))
	for i in 3:
		potion_loots.append(MockTestUtils.create_loot(&"potion"))

	assert_true(herbs.add_all(herb_loots).ok)
	assert_true(potions.add_all(potion_loots).ok)

	var herbs_added: Array = []
	var herbs_removed: Array = []
	var potions_added: Array = []
	var potions_removed: Array = []

	herbs.items_added.connect(func(items): herbs_added.append_array(items))
	herbs.items_removed.connect(func(items): herbs_removed.append_array(items))
	potions.items_added.connect(func(items): potions_added.append_array(items))
	potions.items_removed.connect(func(items): potions_removed.append_array(items))

	var result := ItemContainer.swap_stacks(herbs, 0, potions, 0)

	assert_true(result.ok)
	assert_eq(herbs.get_quantity(&"potion"), 3)
	assert_eq(potions.get_quantity(&"herb"), 5)
	assert_eq(herbs_removed.size(), 5)
	assert_eq(herbs_added.size(), 3)
	assert_eq(potions_removed.size(), 3)
	assert_eq(potions_added.size(), 5)


func test_swap_common_stacks_emits_stacks_changed_once_per_container() -> void:
	var herbs := ItemContainer.new()
	var potions := ItemContainer.new()
	var herb_loots: Array[Loot] = []
	var potion_loots: Array[Loot] = []

	for i in 5:
		herb_loots.append(MockTestUtils.create_loot(&"herb"))
	for i in 3:
		potion_loots.append(MockTestUtils.create_loot(&"potion"))

	assert_true(herbs.add_all(herb_loots).ok)
	assert_true(potions.add_all(potion_loots).ok)

	var herbs_calls: Array = []
	var potions_calls: Array = []

	herbs.stacks_changed.connect(func(updated, removed):
		herbs_calls.append({"updated": updated.duplicate(), "removed": removed.duplicate()})
	)
	potions.stacks_changed.connect(func(updated, removed):
		potions_calls.append({"updated": updated.duplicate(), "removed": removed.duplicate()})
	)

	var result := ItemContainer.swap_stacks(herbs, 0, potions, 0)

	assert_true(result.ok)
	assert_eq(herbs_calls.size(), 1)
	assert_eq(potions_calls.size(), 1)
	assert_eq(herbs_calls[0]["updated"].size(), 1)
	assert_eq(herbs_calls[0]["removed"].size(), 1)
	assert_eq(potions_calls[0]["updated"].size(), 1)
	assert_eq(potions_calls[0]["removed"].size(), 1)

#endregion


#region Merging Stacks
func test_merge_stacks_moves_all_items_and_removes_source_stack() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var herb_a := MockTestUtils.create_loot(&"herb", 10)
	var herb_b := MockTestUtils.create_loot(&"herb", 10)
	var herb_c := MockTestUtils.create_loot(&"herb", 10)
	var herb_d := MockTestUtils.create_loot(&"herb", 10)

	source.add_all([herb_a, herb_b])
	target.add_all([herb_c, herb_d])

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_true(result.is_complete())
	assert_eq(result.moved_quantity, 2)
	assert_eq(source.used_slots(), 0)
	assert_eq(target.used_slots(), 1)
	assert_eq(source.get_quantity(&"herb"), 0)
	assert_eq(target.get_quantity(&"herb"), 4)


func test_merge_stacks_moves_only_what_fits() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_items: Array[Loot] = []
	var target_items: Array[Loot] = []

	for i in 5:
		source_items.append(MockTestUtils.create_loot(&"herb", 10))
	for i in 8:
		target_items.append(MockTestUtils.create_loot(&"herb", 10))

	source.add_all(source_items)
	target.add_all(target_items)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_true(result.is_partial())
	assert_eq(result.moved_quantity, 2)
	assert_eq(result.remained_quantity, 3)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(target.get_quantity(&"herb"), 10)
	assert_eq(source.used_slots(), 1)
	assert_eq(target.used_slots(), 1)


func test_merge_stacks_preserves_remaining_source_instances() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_items: Array[Loot] = []
	var target_items: Array[Loot] = []

	for i in 4:
		source_items.append(MockTestUtils.create_loot(&"herb", 10))
	for i in 8:
		target_items.append(MockTestUtils.create_loot(&"herb", 10))

	source.add_all(source_items)
	target.add_all(target_items)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_true(result.is_partial())
	assert_eq(source.get_quantity(&"herb"), 2)
	assert_eq(target.get_quantity(&"herb"), 10)
	assert_eq(result.moved_quantity, 2)
	assert_eq(result.remained_quantity, 2)


func test_merge_stacks_rejects_different_species() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	source.add(MockTestUtils.create_loot(&"herb", 10))
	target.add(MockTestUtils.create_loot(&"potion", 10))

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.STACK_MISMATCH)
	assert_eq(source.get_quantity(&"herb"), 1)
	assert_eq(target.get_quantity(&"potion"), 1)


func test_merge_stacks_rejects_full_target() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_items: Array[Loot] = []
	var target_items: Array[Loot] = []

	for i in 2:
		source_items.append(MockTestUtils.create_loot(&"herb", 10))
	for i in 10:
		target_items.append(MockTestUtils.create_loot(&"herb", 10))

	source.add_all(source_items)
	target.add_all(target_items)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.FULL)
	assert_eq(source.get_quantity(&"herb"), 2)
	assert_eq(target.get_quantity(&"herb"), 10)


func test_merge_stacks_rejects_invalid_source_index() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	source.add(MockTestUtils.create_loot(&"herb", 10))
	target.add(MockTestUtils.create_loot(&"herb", 10))

	var result := ItemContainer.merge_stacks(source, -1, target, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.SLOT_INVALID)
	assert_eq(source.get_quantity(&"herb"), 1)
	assert_eq(target.get_quantity(&"herb"), 1)


func test_merge_stacks_rejects_same_stack() -> void:
	var container := ItemContainer.new()
	container.add(MockTestUtils.create_loot(&"herb", 10))

	var result := ItemContainer.merge_stacks(container, 0, container, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.SLOT_INVALID)
	assert_eq(container.get_quantity(&"herb"), 1)


func test_merge_stacks_emits_signals_after_cross_container_merge() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	source.add(MockTestUtils.create_loot(&"herb", 10))
	target.add(MockTestUtils.create_loot(&"herb", 10))
#
	watch_signals(source)
	watch_signals(target)
	
	ItemContainer.merge_stacks(source, 0, target, 0)

	assert_signal_emitted(source, "items_removed")
	assert_signal_emitted(source, "stacks_changed")
	assert_signal_emitted(target, "items_added")
	assert_signal_emitted(target, "stacks_changed")


func test_merge_common_stack_moves_all_quantity() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_items: Array[Loot] = []
	var target_items: Array[Loot] = []

	for i in 4:
		source_items.append(MockTestUtils.create_loot(&"herb", 20))
	for i in 2:
		target_items.append(MockTestUtils.create_loot(&"herb", 20))

	assert_true(source.add_all(source_items).ok)
	assert_true(target.add_all(target_items).ok)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_true(result.is_complete())
	assert_eq(result.moved_quantity, 4)
	assert_eq(source.get_quantity(&"herb"), 0)
	assert_eq(target.get_quantity(&"herb"), 6)
	assert_eq(source.used_slots(), 0)
	assert_eq(target.used_slots(), 1)


func test_merge_common_stack_partial_move_preserves_remaining_quantity() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_items: Array[Loot] = []
	var target_items: Array[Loot] = []

	for i in 5:
		source_items.append(MockTestUtils.create_loot(&"herb", 10))
	for i in 8:
		target_items.append(MockTestUtils.create_loot(&"herb", 10))

	assert_true(source.add_all(source_items).ok)
	assert_true(target.add_all(target_items).ok)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_true(result.is_partial())
	assert_eq(result.moved_quantity, 2)
	assert_eq(result.remained_quantity, 3)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(target.get_quantity(&"herb"), 10)
	assert_eq(source.used_slots(), 1)
	assert_eq(target.used_slots(), 1)


func test_merge_common_stack_emits_all_logical_items_when_complete() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_loots: Array[Loot] = []
	var target_loots: Array[Loot] = []

	for i in 5:
		source_loots.append(MockTestUtils.create_loot(&"herb"))
	for i in 3:
		target_loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(source.add_all(source_loots).ok)
	assert_true(target.add_all(target_loots).ok)

	var removed_calls: Array = []
	var added_calls: Array = []
	var source_changed: Array = []
	var target_changed: Array = []

	source.items_removed.connect(func(items): removed_calls.append(items.duplicate()))
	target.items_added.connect(func(items): added_calls.append(items.duplicate()))
	source.stacks_changed.connect(func(updated, removed):
		source_changed.append({"updated": updated.duplicate(), "removed": removed.duplicate()})
	)
	target.stacks_changed.connect(func(updated, removed):
		target_changed.append({"updated": updated.duplicate(), "removed": removed.duplicate()})
	)

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_eq(source.get_quantity(&"herb"), 0)
	assert_eq(target.get_quantity(&"herb"), 8)
	assert_eq(source.used_slots(), 0)
	assert_eq(target.used_slots(), 1)

	assert_eq(removed_calls.size(), 1)
	assert_eq(removed_calls[0].size(), 5)
	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 5)

	assert_eq(source_changed.size(), 1)
	assert_eq(source_changed[0]["updated"].size(), 0)
	assert_eq(source_changed[0]["removed"].size(), 1)
	assert_eq(target_changed.size(), 1)
	assert_eq(target_changed[0]["updated"].size(), 1)
	assert_eq(target_changed[0]["removed"].size(), 0)


func test_merge_common_stack_emits_moved_items_when_partial() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var source_loots: Array[Loot] = []
	var target_loots: Array[Loot] = []

	for i in 5:
		source_loots.append(MockTestUtils.create_loot(&"herb"))
	for i in 18:
		target_loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(source.add_all(source_loots).ok)
	assert_true(target.add_all(target_loots).ok)

	var removed_calls: Array = []
	var added_calls: Array = []

	source.items_removed.connect(func(items): removed_calls.append(items.duplicate()))
	target.items_added.connect(func(items): added_calls.append(items.duplicate()))

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 2)
	assert_eq(result.remained_quantity, 3)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(target.get_quantity(&"herb"), 20)

	assert_eq(removed_calls.size(), 1)
	assert_eq(removed_calls[0].size(), 2)
	assert_eq(added_calls.size(), 1)
	assert_eq(added_calls[0].size(), 2)


func test_merge_common_stacks_inside_same_container_emits_only_stacks_changed() -> void:
	var container := ItemContainer.new()
	var loots: Array[Loot] = []

	for i in 23:
		loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(container.add_all(loots).ok)
	assert_eq(container.used_slots(), 2)

	var added_calls: Array = []
	var removed_calls: Array = []
	var changed_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items.duplicate()))
	container.items_removed.connect(func(items): removed_calls.append(items.duplicate()))
	container.stacks_changed.connect(func(updated, removed):
		changed_calls.append({
			"updated": updated.duplicate(),
			"removed": removed.duplicate()
		})
	)

	var result := ItemContainer.merge_stacks(container, 0, container, 1)

	assert_true(result.ok)
	assert_eq(result.moved_quantity, 17)
	assert_eq(result.remained_quantity, 3)
	assert_eq(container.get_quantity(&"herb"), 23)
	assert_eq(container.used_slots(), 2)

	assert_eq(added_calls.size(), 0)
	assert_eq(removed_calls.size(), 0)
	assert_eq(changed_calls.size(), 1)
	assert_eq(changed_calls[0]["updated"].size(), 2)
	assert_eq(changed_calls[0]["removed"].size(), 0)

#endregion


#region Transfer Stacks
func test_transfer_multiple_items_from_common_stack() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var loots: Array[Loot] = []

	for i in 5:
		loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(source.add_all(loots).ok)
	assert_eq(source.used_slots(), 1)

	var result := ItemContainer.transfer(source, target, &"herb", 3)

	assert_true(result.ok)
	assert_eq(source.get_quantity(&"herb"), 2)
	assert_eq(target.get_quantity(&"herb"), 3)
	assert_eq(source.used_slots(), 1)
	assert_eq(target.used_slots(), 1)


func test_transfer_all_moves_all_common_stack_quantities() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var loots: Array[Loot] = []

	for i in 5:
		loots.append(MockTestUtils.create_loot(&"herb"))

	for i in 2:
		loots.append(MockTestUtils.create_loot(&"potion"))

	assert_true(source.add_all(loots).ok)
	assert_eq(source.used_slots(), 2)

	var result := ItemContainer.transfer_all(source, target)

	assert_true(result.ok)
	assert_eq(source.get_quantity(&"herb"), 0)
	assert_eq(source.get_quantity(&"potion"), 0)
	assert_eq(target.get_quantity(&"herb"), 5)
	assert_eq(target.get_quantity(&"potion"), 2)
	assert_eq(source.used_slots(), 0)
	assert_eq(target.used_slots(), 2)


func test_rejected_transfer_emits_only_operation_rejected() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var loots: Array[Loot] = []

	for i in 2:
		loots.append(MockTestUtils.create_loot(&"herb"))

	assert_true(source.add_all(loots).ok)

	var added_calls: Array = []
	var removed_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []
	var rejected_calls: Array = []

	source.items_added.connect(func(items): added_calls.append(items))
	source.items_removed.connect(func(items): removed_calls.append(items))
	source.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	source.order_changed.connect(func(): order_calls.append(true))
	source.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var result := ItemContainer.transfer(source, target, &"herb", 3)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_ENOUGH)
	assert_eq(source.get_quantity(&"herb"), 2)
	assert_eq(target.get_quantity(&"herb"), 0)

	assert_eq(added_calls.size(), 0)
	assert_eq(removed_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(order_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"transfer")


func test_rejected_merge_emits_only_operation_rejected() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new()
	var herbs: Array[Loot] = []
	var potions: Array[Loot] = []

	for i in 3:
		herbs.append(MockTestUtils.create_loot(&"herb"))
	for i in 2:
		potions.append(MockTestUtils.create_loot(&"potion"))

	assert_true(source.add_all(herbs).ok)
	assert_true(target.add_all(potions).ok)

	var source_added: Array = []
	var source_removed: Array = []
	var source_changed: Array = []
	var source_order: Array = []
	var source_rejected: Array = []
	var target_added: Array = []
	var target_removed: Array = []
	var target_changed: Array = []
	var target_order: Array = []

	source.items_added.connect(func(items): source_added.append(items))
	source.items_removed.connect(func(items): source_removed.append(items))
	source.stacks_changed.connect(func(_updated, _removed): source_changed.append(true))
	source.order_changed.connect(func(): source_order.append(true))
	source.operation_rejected.connect(func(operation, res):
		source_rejected.append({"operation": operation, "result": res})
	)

	target.items_added.connect(func(items): target_added.append(items))
	target.items_removed.connect(func(items): target_removed.append(items))
	target.stacks_changed.connect(func(_updated, _removed): target_changed.append(true))
	target.order_changed.connect(func(): target_order.append(true))

	var result := ItemContainer.merge_stacks(source, 0, target, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.STACK_MISMATCH)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(target.get_quantity(&"potion"), 2)

	assert_eq(source_added.size(), 0)
	assert_eq(source_removed.size(), 0)
	assert_eq(source_changed.size(), 0)
	assert_eq(source_order.size(), 0)
	assert_eq(target_added.size(), 0)
	assert_eq(target_removed.size(), 0)
	assert_eq(target_changed.size(), 0)
	assert_eq(target_order.size(), 0)

	assert_eq(source_rejected.size(), 1)
	assert_eq(source_rejected[0]["operation"], &"merge")

#endregion


#region Rejections
func test_rejected_move_by_tags_emits_only_operation_rejected() -> void:
	var herb := MockTestUtils.create_loot(&"herb")
	herb.add_tag(&"herb")

	var source := ItemContainer.new()
	var target := ItemContainer.new(TagQuery.create([&"potion"]))

	assert_true(source.add(herb).ok)

	var source_removed: Array = []
	var source_changed: Array = []
	var source_rejected: Array = []
	var target_added: Array = []
	var target_changed: Array = []

	source.items_removed.connect(func(items): source_removed.append(items))
	source.stacks_changed.connect(func(_updated, _removed): source_changed.append(true))
	source.operation_rejected.connect(func(operation, res):
		source_rejected.append({"operation": operation, "result": res})
	)
	target.items_added.connect(func(items): target_added.append(items))
	target.stacks_changed.connect(func(_updated, _removed): target_changed.append(true))

	var result := ItemContainer.move(source, target, [herb])

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_REJECTED)
	assert_eq(source.get_quantity(&"herb"), 1)
	assert_eq(target.get_quantity(&"herb"), 0)

	assert_eq(source_removed.size(), 0)
	assert_eq(source_changed.size(), 0)
	assert_eq(target_added.size(), 0)
	assert_eq(target_changed.size(), 0)
	assert_eq(source_rejected.size(), 1)
	assert_eq(source_rejected[0]["operation"], &"move")


func test_rejected_swap_by_tags_emits_only_operation_rejected() -> void:
	var herb := MockTestUtils.create_loot(&"herb")
	herb.add_tag(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")
	potion.add_tag(&"potion")

	var herbs := ItemContainer.new(TagQuery.create([&"herb"]))
	var potions := ItemContainer.new(TagQuery.create([&"potion"]))

	assert_true(herbs.add(herb).ok)
	assert_true(potions.add(potion).ok)

	var herbs_added: Array = []
	var herbs_removed: Array = []
	var herbs_changed: Array = []
	var herbs_order: Array = []
	var herbs_rejected: Array = []
	var potions_added: Array = []
	var potions_removed: Array = []
	var potions_changed: Array = []
	var potions_order: Array = []

	herbs.items_added.connect(func(items): herbs_added.append(items))
	herbs.items_removed.connect(func(items): herbs_removed.append(items))
	herbs.stacks_changed.connect(func(_updated, _removed): herbs_changed.append(true))
	herbs.order_changed.connect(func(): herbs_order.append(true))
	herbs.operation_rejected.connect(func(operation, res):
		herbs_rejected.append({"operation": operation, "result": res})
	)
	potions.items_added.connect(func(items): potions_added.append(items))
	potions.items_removed.connect(func(items): potions_removed.append(items))
	potions.stacks_changed.connect(func(_updated, _removed): potions_changed.append(true))
	potions.order_changed.connect(func(): potions_order.append(true))

	var result := ItemContainer.swap_stacks(herbs, 0, potions, 0)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_REJECTED)
	assert_eq(herbs.get_quantity(&"herb"), 1)
	assert_eq(potions.get_quantity(&"potion"), 1)

	assert_eq(herbs_added.size(), 0)
	assert_eq(herbs_removed.size(), 0)
	assert_eq(herbs_changed.size(), 0)
	assert_eq(herbs_order.size(), 0)
	assert_eq(potions_added.size(), 0)
	assert_eq(potions_removed.size(), 0)
	assert_eq(potions_changed.size(), 0)
	assert_eq(potions_order.size(), 0)

	assert_eq(herbs_rejected.size(), 1)
	assert_eq(herbs_rejected[0]["operation"], &"swap")


func test_rejected_transfer_all_without_partial_emits_only_operation_rejected() -> void:
	var source := ItemContainer.new()
	var target := ItemContainer.new(null, 1)

	var herbs: Array[Loot] = []
	var potions: Array[Loot] = []

	for i in 3:
		herbs.append(MockTestUtils.create_loot(&"herb"))
	potions.append(MockTestUtils.create_loot(&"potion"))

	assert_true(source.add_all(herbs).ok)
	assert_true(target.add_all(potions).ok)

	var source_added: Array = []
	var source_removed: Array = []
	var source_changed: Array = []
	var source_rejected: Array = []
	var target_added: Array = []
	var target_removed: Array = []
	var target_changed: Array = []

	source.items_added.connect(func(items): source_added.append(items))
	source.items_removed.connect(func(items): source_removed.append(items))
	source.stacks_changed.connect(func(_updated, _removed): source_changed.append(true))
	source.operation_rejected.connect(func(operation, res):
		source_rejected.append({"operation": operation, "result": res})
	)
	target.items_added.connect(func(items): target_added.append(items))
	target.items_removed.connect(func(items): target_removed.append(items))
	target.stacks_changed.connect(func(_updated, _removed): target_changed.append(true))

	var result := ItemContainer.transfer_all(source, target, false)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.FULL)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(target.get_quantity(&"potion"), 1)
	assert_eq(target.get_quantity(&"herb"), 0)

	assert_eq(source_added.size(), 0)
	assert_eq(source_removed.size(), 0)
	assert_eq(source_changed.size(), 0)
	assert_eq(target_added.size(), 0)
	assert_eq(target_removed.size(), 0)
	assert_eq(target_changed.size(), 0)
	assert_eq(source_rejected.size(), 1)
	assert_eq(source_rejected[0]["operation"], &"move")


func test_rejected_remove_missing_instance_preserves_container() -> void:
	var container := ItemContainer.new()
	var herb := MockTestUtils.create_loot(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")
	assert_true(container.add(herb).ok)

	var removed_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []

	container.items_removed.connect(func(items): removed_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.order_changed.connect(func(): order_calls.append(true))

	var result := container.remove(potion)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_FOUND)
	assert_eq(container.get_quantity(&"herb"), 1)
	assert_eq(container.get_quantity(&"potion"), 0)
	assert_eq(removed_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(order_calls.size(), 0)


func test_rejected_remove_all_duplicate_reference_preserves_container() -> void:
	var container := ItemContainer.new()
	var herb := MockTestUtils.create_loot(&"herb")
	assert_true(container.add(herb).ok)

	var removed_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []
	var rejected_calls: Array = []

	container.items_removed.connect(func(items): removed_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.order_changed.connect(func(): order_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var loots: Array[Loot] = [herb, herb]
	var result := container.remove_all(loots)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.DUPLICATE)
	assert_eq(container.get_quantity(&"herb"), 1)
	assert_eq(removed_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(order_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"remove")


func test_rejected_remove_by_id_insufficient_quantity_preserves_container() -> void:
	var container := ItemContainer.new()
	var herbs: Array[Loot] = []

	for i in 2:
		herbs.append(MockTestUtils.create_loot(&"herb"))

	assert_true(container.add_all(herbs).ok)

	var removed_calls: Array = []
	var changed_calls: Array = []
	var order_calls: Array = []
	var rejected_calls: Array = []

	container.items_removed.connect(func(items): removed_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.order_changed.connect(func(): order_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var result := container.remove_by_id(&"herb", 3)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.NOT_ENOUGH)
	assert_eq(container.get_quantity(&"herb"), 2)
	assert_eq(removed_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(order_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"remove_by_id")


func test_rejected_add_by_tags_preserves_container() -> void:
	var container := ItemContainer.new(TagQuery.create([&"herb"]))
	var potion := MockTestUtils.create_loot(&"potion")
	potion.add_tag(&"potion")

	var added_calls: Array = []
	var changed_calls: Array = []
	var rejected_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var result := container.add(potion)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_REJECTED)
	assert_eq(container.get_quantity(&"potion"), 0)
	assert_eq(added_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"add")


func test_rejected_add_all_by_tags_preserves_container() -> void:
	var container := ItemContainer.new(TagQuery.create([&"potion"]))

	var herb := MockTestUtils.create_loot(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")
	potion.add_tag(&"potion")

	var added_calls: Array = []
	var changed_calls: Array = []
	var rejected_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var loots: Array[Loot] = [herb, potion]
	var result := container.add_all(loots)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.TAG_REJECTED)
	assert_eq(container.get_quantity(&"herb"), 0)
	assert_eq(container.get_quantity(&"potion"), 0)
	assert_eq(added_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"add")


func test_rejected_add_all_by_capacity_preserves_container() -> void:
	var container := ItemContainer.new(null, 1)

	var herb := MockTestUtils.create_loot(&"herb")
	var potion := MockTestUtils.create_loot(&"potion")

	assert_true(container.add(herb).ok)

	var added_calls: Array = []
	var changed_calls: Array = []
	var rejected_calls: Array = []

	container.items_added.connect(func(items): added_calls.append(items))
	container.stacks_changed.connect(func(_updated, _removed): changed_calls.append(true))
	container.operation_rejected.connect(func(operation, res):
		rejected_calls.append({"operation": operation, "result": res})
	)

	var loots: Array[Loot] = [potion]
	var result := container.add_all(loots)

	assert_false(result.ok)
	assert_eq(result.fail_reason, ItemContainerOpResult.FailReason.FULL)
	assert_eq(container.get_quantity(&"herb"), 1)
	assert_eq(container.get_quantity(&"potion"), 0)
	assert_eq(added_calls.size(), 0)
	assert_eq(changed_calls.size(), 0)
	assert_eq(rejected_calls.size(), 1)
	assert_eq(rejected_calls[0]["operation"], &"add")

#endregion


#region Split
func test_split_common_stack_in_same_container() -> void:
	var container := ItemContainer.new()
	var item := MockTestUtils.create_loot(&"herb")
	container.add_all([item, item, item, item, item, item, item, item, item, item])

	var stack: ItemStack = container._content[0]
	var result := container.split(stack, 4, container)

	assert_true(result.ok)
	assert_eq(container._content.size(), 2)
	assert_eq(container._content[0].quantity, 6)
	assert_eq(container._content[1].quantity, 4)
	assert_eq(container.get_quantity(&"herb"), 10)


func test_split_common_stack_into_existing_stack_merges() -> void:
	var source := ItemContainer.new()
	var destination := ItemContainer.new()
	var herb := MockTestUtils.create_loot(&"herb")

	source.add_all([herb, herb, herb, herb, herb])
	destination.add_all([herb, herb])

	var source_stack: ItemStack = source._content[0]
	var result := source.split(source_stack, 3, destination)

	assert_true(result.ok)
	assert_eq(source.get_quantity(&"herb"), 2)
	assert_eq(destination.get_quantity(&"herb"), 5)
	assert_eq(destination._content.size(), 1)


func test_split_unique_stack_preserves_instances() -> void:
	var source := ItemContainer.new()
	var destination := ItemContainer.new()
	var items: Array[Loot] = []

	for i in 3:
		items.append(MockTestUtils.create_unique_loot(&"sword", 3))

	source.add_all(items)

	var original_stack: ItemStack = source._content[0]
	var moved_item: Loot = items[2]

	var result := source.split(original_stack, 1, destination)

	assert_true(result.ok)
	assert_eq(source.get_quantity(&"sword"), 2)
	assert_eq(destination.get_quantity(&"sword"), 1)
	assert_same(destination._content[0].items[0], moved_item)
	assert_false(source.contains(moved_item))
	assert_true(destination.contains(moved_item))


func test_split_invalid_quantity_does_not_mutate() -> void:
	var container := ItemContainer.new()
	var item := MockTestUtils.create_loot(&"herb")
	container.add_all([item, item, item])

	var stack: ItemStack = container._content[0]

	for quantity in [0, -1, 3, 4]:
		var result := container.split(stack, quantity, container)
		assert_false(result.ok)
		assert_eq(container._content.size(), 1)
		assert_eq(container.get_quantity(&"herb"), 3)


func test_split_rejected_when_destination_is_full() -> void:
	var source := ItemContainer.new()
	var destination := ItemContainer.new(null, 1)
	var herb := MockTestUtils.create_loot(&"herb")
	var sword := MockTestUtils.create_loot(&"sword")

	source.add_all([herb, herb, herb])
	destination.add(sword)

	var stack: ItemStack = source._content[0]
	var result := source.split(stack, 1, destination)

	assert_false(result.ok)
	assert_eq(source.get_quantity(&"herb"), 3)
	assert_eq(destination.get_quantity(&"sword"), 1)
	assert_eq(destination.get_quantity(&"herb"), 0)

#endregion
