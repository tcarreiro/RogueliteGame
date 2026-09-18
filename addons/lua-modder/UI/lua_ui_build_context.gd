class_name LuaUiBuildContext extends RefCounted

var factory: LuaUiFactory
var manager: LuaUiManager
var component_index: Dictionary
var translation_resolver: Callable


func _init(factory_ref: LuaUiFactory, index: Dictionary, resolver: Callable, manager_ref: LuaUiManager) -> void:
	factory = factory_ref
	component_index = index
	translation_resolver = resolver
	manager = manager_ref


func build_node(definition: Dictionary) -> Control:
	return factory.build_node(definition, self)


func resolve_text(key) -> String:
	return translation_resolver.call(str(key))


func get_theme(name: String) -> Theme:
	return manager.get_theme(name)


func get_animation(name: String) -> LuaUiAnimationPreset:
	return manager.get_animation_preset(name)


func get_sound(name: String) -> AudioStream:
	return manager.get_sound(name)
