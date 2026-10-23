class_name LuaBinding extends RefCounted
## Liga props de componentes a um ou mais Reactive. `getter` calcula o valor da prop;
## `changed` dispara quando qualquer dependência muda.

signal changed

var _deps: Array[Reactive] = []
var _getter: Callable


func _init(deps: Array, getter: Callable) -> void:
	_getter = getter
	for dep in deps:
		if dep is Reactive and not _deps.has(dep):
			_deps.append(dep)
			dep.reactive_changed.connect(_on_dep_changed)


func evaluate() -> Variant:
	return _getter.call() if _getter.is_valid() else null


func _on_dep_changed(_reactive: Reactive) -> void:
	changed.emit()
