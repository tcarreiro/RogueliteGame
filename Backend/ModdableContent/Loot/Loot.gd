class_name Loot extends Resource

signal collected(loot: Loot)
signal spawned(loot: Loot)

const KIND_PREFIX := &"kind."
const KIND_LOOT := StringName(KIND_PREFIX+"loot")

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var max_stack: int:
	set(v):
		max_stack = maxi(v, 0)
## Content tags that come from the mod's JSON ("herb", "potion"...).
@export var extra_tags: Array[StringName] = []

var on_run_start: Callable
var on_collect: Callable
var on_spawn: Callable
var on_run_end: Callable

## Class tags per script, computed once: { Script: Array[StringName] }
static var _kind_tags_by_script: Dictionary = {}

var _tag_cache: Array[StringName] = []
var _tag_cache_valid: bool = false

func connect_run_start() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_started, _on_run_started, ConnectFlags.CONNECT_ONE_SHOT)


func connect_run_end() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_ended, _on_run_ended, ConnectFlags.CONNECT_ONE_SHOT)


func _on_run_started() -> void:
	if on_run_start.is_valid():
		on_run_start.call(self)


func _on_run_ended(success: bool) -> void:
	if on_run_end.is_valid():
		on_run_end.call(success)


func spawn() -> void:
	spawned.emit(self)
	if on_spawn.is_valid():
		on_spawn.call(self)


func collect() -> void:
	collected.emit(self)
	if on_collect.is_valid():
		on_collect.call(self)


## Can this item merge with another equal one into a stack? Subclasses with
## per-instance state (e.g. Enchantable with effects) must narrow this.
func can_stack() -> bool:
	return max_stack != 1


func get_max_stack() -> int:
	return max_stack


#region Tags
func has_tag(p_tag: StringName) -> bool:
	return get_tag_set().has(p_tag)


## Every tag of this item: class tags + content tags, no duplicates.
## Read-only by convention: use add_tag() to change it.
func get_tag_set() -> Array[StringName]:
	if not _tag_cache_valid:
		_tag_cache = get_kind_tags().duplicate()
		for tag in extra_tags:
			if not _tag_cache.has(tag):
				_tag_cache.append(tag)
		_tag_cache_valid = true
	return _tag_cache


func add_tag(tag: StringName) -> void:
	if extra_tags.has(tag):
		return
	extra_tags.append(tag)
	_tag_cache_valid = false


## Gauntlet -> [kind.gauntlet, kind.equipment, kind.enchantable, kind.loot]
func get_kind_tags() -> Array[StringName]:
	var script: Script = get_script()
	if _kind_tags_by_script.has(script):
		return _kind_tags_by_script[script]
	var kind_tags: Array[StringName] = []
	var current: Script = script  # starts at the item's own script, not its parent
	while current != null:
		var global_name := current.get_global_name()
		if not global_name.is_empty():
			#kind_tags.append(StringName("kind." + String(global_name).to_snake_case()))
			kind_tags.append(StringName(get("KIND_"+String(global_name).to_snake_case().to_upper())))
		current = current.get_base_script()
	_kind_tags_by_script[script] = kind_tags
	return kind_tags
#endregion
