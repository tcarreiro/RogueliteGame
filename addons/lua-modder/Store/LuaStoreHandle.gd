class_name LuaStoreHandle extends RefCounted
## Visão de um ReactiveDictionary para o Lua: só funções com valores simples.
## origin != null: significa que o handle é um rascunho (draft) de `origin`.

var id: int
var store: ReactiveDictionary
var origin: ReactiveDictionary


func _init(p_id: int, p_store: ReactiveDictionary, p_origin: ReactiveDictionary = null) -> void:
	id = p_id
	store = p_store
	origin = p_origin


func is_draft() -> bool:
	return origin != null


## O que um bind() deve observar: a store e, quando for rascunho, o original.
func dependencies() -> Array[Reactive]:
	var out: Array[Reactive] = [store]
	if origin != null:
		out.append(origin)
	return out


func to_lua() -> Dictionary:
	return {
		"_id": id,
		"get_at": Callable(self, "lua_get"),
		"set_at": Callable(self, "lua_set"),
		"draft": Callable(self, "lua_draft"),
		"dirty": Callable(self, "lua_dirty"),
		"commit": Callable(self, "lua_commit"),
		"discard": Callable(self, "lua_discard"),
		"model": Callable(self, "lua_model"),
	}


func lua_get(key: Variant) -> Variant:
	return store.get_at(str(key))


## Converte para o tipo do valor atual.
## Ex.: o Input number manda 55.0, a store guarda 55.
func lua_set(key: Variant, new_value: Variant) -> void:
	var k := str(key)
	var old: Variant = store.get_at(k)
	if old != null and typeof(new_value) != typeof(old):
		new_value = type_convert(new_value, typeof(old))
	store.set_at(k, new_value)


func lua_draft() -> Dictionary:
	return LuaUi.make_draft(self)


func lua_dirty() -> bool:
	return origin != null and store.value != origin.value


func lua_commit() -> void:
	if origin != null:
		origin.assign(store.value)


func lua_discard() -> void:
	if origin != null:
		store.assign(origin.value)


func lua_model(key: Variant) -> LuaModel:
	var k := str(key)
	return LuaModel.new(dependencies(), func() -> Variant: return store.get_at(k), func(v: Variant) -> void: lua_set(k, v))
