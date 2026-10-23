class_name LuaModel extends LuaBinding
## v-model: a leitura reativa do LuaBinding mais a escrita de volta na store.

var _setter: Callable


func _init(deps: Array, getter: Callable, setter: Callable) -> void:
	super._init(deps, getter)
	_setter = setter


func write(value: Variant) -> void:
	if _setter.is_valid():
		_setter.call(value)
