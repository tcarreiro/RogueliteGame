class_name LuaUiComponent extends RefCounted


func get_type_name() -> String:
	push_error("[LuaUiComponent] get_type_name() não foi implementado.")
	return ""


func build(_definition: Dictionary, _context: LuaUiBuildContext) -> Control:
	push_error("[LuaUiComponent] build() não foi implementado.")
	return null

## Nó que efetivamente deve receber classes/vars GDSS via "style"/"style_vars".
## Por padrão é o próprio node retornado por build(). Componentes que separam
## "casca estrutural" de "camada visual" (como Section) sobrescrevem isso.
func get_style_target(built_node: Control) -> Control:
	return built_node
