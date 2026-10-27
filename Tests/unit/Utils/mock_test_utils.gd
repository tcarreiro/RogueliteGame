class_name MockTestUtils extends RefCounted

class TestUniqueLoot extends Loot:
	var uuid: UUID = UUID.new_uuid()


static func create_loot(p_id: StringName = &"herb", p_max_stack: int = 20) -> Loot:
	var loot := Loot.new()
	loot.id = p_id
	loot.display_name = p_id
	loot.max_stack = p_max_stack
	return loot


static func create_unique_loot(p_id: StringName = &"sword", p_max_stack: int = 1) -> TestUniqueLoot:
	var loot := TestUniqueLoot.new()
	loot.id = p_id
	loot.display_name = p_id
	loot.max_stack = p_max_stack
	return loot
