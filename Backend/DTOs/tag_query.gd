class_name TagQuery extends Resource

enum TagResult {
	OK, MISSING, FORBIDDEN,
}

@export var require_all: Array[StringName] = []
@export var require_any: Array[StringName] = []
@export var forbid: Array[StringName] = []

static func create(all: Array = [], any: Array = [], none: Array = []) -> TagQuery:
	var tag_query := TagQuery.new()
	for tag in all:
		_add_tag_to_list(tag_query.require_all, StringName(tag))
	for tag in any:
		_add_tag_to_list(tag_query.require_any, StringName(tag))
	for tag in none:
		_add_tag_to_list(tag_query.forbid, StringName(tag))
	return tag_query
 
 
static func _add_tag_to_list(list: Array[StringName], tag: StringName) -> void:
	if not list.has(tag):
		list.append(tag)


## `tags` is the item's tag set (Loot.get_tag_set()). The loops walk the QUERY's lists
## and ask the item "do you have this?", not the other way around.
func query_tags(tags: Array[StringName]) -> TagResult:
	for tag in forbid:
		if tags.has(tag):
			return TagResult.FORBIDDEN
	for tag in require_all:
		if not tags.has(tag):
			return TagResult.MISSING
	if not require_any.is_empty():
		var any_match := false
		for tag in require_any:
			if tags.has(tag):
				any_match = true
				break
		if not any_match:
			return TagResult.MISSING
	return TagResult.OK


static func get_tag_query_name(tag_result: TagResult) -> String:
	return TagResult.keys()[tag_result]
