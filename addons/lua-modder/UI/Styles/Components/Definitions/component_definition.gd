class_name ComponentDefinition extends RefCounted

var name: StringName
var kind: ComponentRegistry.Kind
var schema: Dictionary
var render: Callable #Used by LUA components
var scene: PackedScene #Used by SCENE components
var source: String

func _init(p_name: StringName, p_kind: ComponentRegistry.Kind, p_schema: Dictionary,
		p_source: String, p_scene: PackedScene = null, p_render: Callable = Callable()
	) -> void:
	name = p_name
	kind = p_kind
	schema = p_schema
	source = p_source
	scene = p_scene
	render = p_render
