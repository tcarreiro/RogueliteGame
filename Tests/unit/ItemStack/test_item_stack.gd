extends GutTest

# -------------------------------------------------------------------
# Initialization
# -------------------------------------------------------------------

func test_empty_stack() -> void:
	var stack := ItemStack.new()

	assert_true(stack.is_empty())
	assert_eq(stack.quantity, 0)
	assert_eq(stack.get_loot_id(), &"")
	assert_null(stack.get_sample())
	assert_eq(stack.get_max_stack(), 1)
	assert_eq(stack.get_free_space(), 0)
	assert_true(stack.is_full())


func test_initialize_common_stack() -> void:
	var first := MockTestUtils.create_loot()
	var second := MockTestUtils.create_loot()
	var third := MockTestUtils.create_loot()

	var stack := ItemStack.new([first, second, third])

	assert_false(stack._unique)
	assert_eq(stack.items.size(), 1)
	assert_eq(stack.common_quantity, 3)
	assert_eq(stack.quantity, 3)
	assert_ne(stack.items[0], first)
	assert_eq(stack.items[0].id, first.id)


func test_initialize_unique_stack() -> void:
	var first := MockTestUtils.create_unique_loot()
	var second := MockTestUtils.create_unique_loot()

	var stack := ItemStack.new([first, second])

	assert_true(stack._unique)
	assert_eq(stack.items.size(), 2)
	assert_eq(stack.quantity, 2)
	assert_same(stack.items[0], first)
	assert_same(stack.items[1], second)


func test_initialize_with_empty_array() -> void:
	var stack := ItemStack.new([])

	assert_true(stack.is_empty())
	assert_eq(stack.quantity, 0)


# -------------------------------------------------------------------
# Quantity and capacity
# -------------------------------------------------------------------

func test_common_stack_free_space() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot()
	])

	assert_eq(stack.get_max_stack(), 20)
	assert_eq(stack.get_free_space(), 17)
	assert_false(stack.is_full())


func test_stack_at_max_capacity() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot()
	])

	stack.items[0].max_stack = 2

	assert_eq(stack.get_free_space(), 0)
	assert_true(stack.is_full())


func test_stack_over_capacity_has_no_free_space() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot()
	])

	stack.items[0].max_stack = 2

	assert_eq(stack.get_free_space(), 0)
	assert_true(stack.is_full())


func test_unlimited_stack() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"water", 0)])

	assert_eq(stack.get_free_space(), ItemStack.UNLIMITED)
	assert_false(stack.is_full())


func test_unique_stack_quantity_matches_instance_count() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_unique_loot(),
		MockTestUtils.create_unique_loot()
	])

	assert_eq(stack.quantity, stack.items.size())


# -------------------------------------------------------------------
# Stack compatibility
# -------------------------------------------------------------------

func test_accepts_same_id_stackable_loot() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb", 20)])
	var other := MockTestUtils.create_loot(&"herb", 20)

	assert_true(stack.accepts(other))


func test_rejects_different_id() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb", 20)])
	var other := MockTestUtils.create_loot(&"potion", 20)

	assert_false(stack.accepts(other))


func test_rejects_non_stackable_loot() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb", 20)])
	var other := MockTestUtils.create_loot(&"herb", 1)

	assert_false(stack.accepts(other))


func test_rejects_when_existing_loot_is_not_stackable() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"sword", 1)])
	var other := MockTestUtils.create_loot(&"sword", 20)

	assert_false(stack.accepts(other))


func test_rejects_null_loot() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot()])

	assert_false(stack.accepts(null))


func test_empty_stack_rejects_loot() -> void:
	var stack := ItemStack.new()

	assert_false(stack.accepts(MockTestUtils.create_loot()))


# -------------------------------------------------------------------
# Lookup
# -------------------------------------------------------------------

func test_find_common_loot_by_id() -> void:
	var first := MockTestUtils.create_loot()
	var stack := ItemStack.new([first, MockTestUtils.create_loot()])

	assert_eq(stack.find_index_of(first), 0)
	assert_true(stack.contains(first))


func test_find_common_loot_by_another_instance_with_same_id() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb")])
	var equivalent := MockTestUtils.create_loot(&"herb")

	assert_eq(stack.find_index_of(equivalent), 0)
	assert_true(stack.contains(equivalent))


func test_common_stack_does_not_contain_different_id() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb")])

	assert_eq(stack.find_index_of(MockTestUtils.create_loot(&"potion")), -1)
	assert_false(stack.contains(MockTestUtils.create_loot(&"potion")))


func test_find_unique_loot_by_instance() -> void:
	var first := MockTestUtils.create_unique_loot()
	var second := MockTestUtils.create_unique_loot()
	var stack := ItemStack.new([first, second])

	assert_eq(stack.find_index_of(first), 0)
	assert_eq(stack.find_index_of(second), 1)


func test_unique_stack_does_not_match_different_instance() -> void:
	var stack := ItemStack.new([MockTestUtils.create_unique_loot()])
	var equivalent := MockTestUtils.create_unique_loot()

	assert_eq(stack.find_index_of(equivalent), -1)
	assert_false(stack.contains(equivalent))


# -------------------------------------------------------------------
# Adding and removing
# -------------------------------------------------------------------

func test_add_common_loot_increments_quantity() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot()])

	stack.add_item(MockTestUtils.create_loot())

	assert_eq(stack.quantity, 2)
	assert_eq(stack.items.size(), 1)


func test_add_common_loot_to_empty_stack() -> void:
	var stack := ItemStack.new()

	stack.add_item(MockTestUtils.create_loot())

	assert_eq(stack.quantity, 1)
	assert_eq(stack.items.size(), 1)
	assert_false(stack.is_empty())


func test_add_unique_loot_preserves_instance() -> void:
	var first := MockTestUtils.create_unique_loot(&"sword", 2)
	var second := MockTestUtils.create_unique_loot(&"sword", 2)

	var stack := ItemStack.new([first])
	stack.add_item(second)

	assert_true(stack._unique)
	assert_eq(stack.items.size(), 2)
	assert_same(stack.items[1], second)


func test_remove_common_loot_decrements_quantity() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot(),
		MockTestUtils.create_loot()
	])

	assert_true(stack.remove_item(MockTestUtils.create_loot()))
	assert_eq(stack.quantity, 2)
	assert_eq(stack.items.size(), 1)


func test_remove_last_common_loot_empties_stack() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot()])

	assert_true(stack.remove_item(MockTestUtils.create_loot()))
	assert_true(stack.is_empty())
	assert_eq(stack.quantity, 0)


func test_remove_missing_common_loot_returns_false() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb")])

	assert_false(stack.remove_item(MockTestUtils.create_loot(&"potion")))
	assert_eq(stack.quantity, 1)


func test_remove_unique_loot_removes_exact_instance() -> void:
	var first := MockTestUtils.create_unique_loot()
	var second := MockTestUtils.create_unique_loot()
	var stack := ItemStack.new([first, second])

	assert_true(stack.remove_item(first))
	assert_eq(stack.quantity, 1)
	assert_same(stack.items[0], second)


func test_remove_missing_unique_loot_returns_false() -> void:
	var first := MockTestUtils.create_unique_loot()
	var other := MockTestUtils.create_unique_loot()
	var stack := ItemStack.new([first])

	assert_false(stack.remove_item(other))
	assert_eq(stack.quantity, 1)
	assert_same(stack.items[0], first)


func test_add_item_to_empty_stack() -> void:
	var loot := MockTestUtils.create_loot()
	var stack := ItemStack.new()

	stack.add_item(loot)

	assert_false(stack.is_empty())
	assert_eq(stack.quantity, 1)
	assert_eq(stack.get_loot_id(), loot.id)


func test_add_item_rejects_incompatible_loot() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(&"herb")])

	stack.add_item(MockTestUtils.create_loot(&"potion"))

	assert_eq(stack.quantity, 1)
	assert_eq(stack.get_loot_id(), &"herb")


func test_add_item_rejects_when_stack_is_full() -> void:
	var stack := ItemStack.new([
		MockTestUtils.create_loot(&"herb", 2),
		MockTestUtils.create_loot(&"herb", 2)
	])

	stack.add_item(MockTestUtils.create_loot(&"herb", 2))

	assert_eq(stack.quantity, 2)
	assert_true(stack.is_full())


func test_remove_null_loot_returns_false() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(), MockTestUtils.create_loot()])

	assert_false(stack.remove_item(null))
	assert_eq(stack.quantity, 2)
	assert_false(stack.is_empty())


# -------------------------------------------------------------------
# pop_item
# -------------------------------------------------------------------

func test_pop_common_loot_returns_copy() -> void:
	var original := MockTestUtils.create_loot()
	var stack := ItemStack.new([original, MockTestUtils.create_loot()])

	var popped := stack.pop_item()

	assert_not_null(popped)
	assert_eq(popped.id, original.id)
	assert_ne(popped, stack.items[0])
	assert_eq(stack.quantity, 1)


func test_pop_last_common_loot_empties_stack() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot()])

	var popped := stack.pop_item()

	assert_not_null(popped)
	assert_true(stack.is_empty())
	assert_eq(stack.quantity, 0)


func test_pop_unique_loot_returns_original_instance() -> void:
	var first := MockTestUtils.create_unique_loot()
	var second := MockTestUtils.create_unique_loot()
	var stack := ItemStack.new([first, second])

	var popped := stack.pop_item()

	assert_same(popped, second)
	assert_eq(stack.quantity, 1)
	assert_same(stack.items[0], first)


func test_pop_empty_stack_returns_null() -> void:
	var stack := ItemStack.new()

	assert_null(stack.pop_item())
	assert_true(stack.is_empty())


func test_pop_common_loot_returns_independent_copy() -> void:
	var stack := ItemStack.new([MockTestUtils.create_loot(), MockTestUtils.create_loot()])
	var original_sample := stack.items[0]

	var popped := stack.pop_item()

	assert_not_null(popped)
	assert_ne(popped, original_sample)
	assert_eq(popped.id, original_sample.id)
	assert_eq(stack.quantity, 1)
