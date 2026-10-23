class_name UIElement extends RefCounted
## Descrição declarativa de "um componente a ser instanciado".
## É o que `Button{...}`, `ProfileCard{...}` e `UI.getComponent(...)` devolvem no Lua.
## Quem instancia é o ComponentRegistry.instantiate().

var component_name: String = ""
## Props ainda "cruas" (sem defaults/coerção). O registry resolve na instanciação.
var props: Dictionary = {}
## prop -> LuaBinding (props ligadas a Reactive via UI.bind)
var bindings: Dictionary = {}
## "on_<evento>" e hooks -> Callable
var handlers: Dictionary = {}
## slot_name -> Array[UIElement]. Filhos sem slot vão para "default".
var slots: Dictionary = {}
## Nome opcional para o Lua chamar métodos expostos depois (UI.callMethod).
var ref: String = ""


func _init(p_component_name: String = "") -> void:
	component_name = p_component_name
