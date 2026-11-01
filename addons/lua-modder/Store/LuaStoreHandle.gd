class_name LuaStoreHandle extends RefCounted
## Visão de um ReactiveDictionary para o Lua: só funções com valores simples.
## origin != null: significa que o handle é um rascunho (draft) de `origin`.

var id: int
var store: ReactiveDictionary
var origin: ReactiveDictionary
var readonly := false
var origin_readonly := false

func _init(p_id: int, p_store: ReactiveDictionary, p_origin: ReactiveDictionary = null, p_readonly := false, p_origin_readonly := false) -> void:
	id = p_id
	store = p_store
	origin = p_origin
	readonly = p_readonly
	origin_readonly = p_origin_readonly


func is_draft() -> bool:
	return origin != null


## O que um bind() deve observar: a store e, quando for rascunho, o original.
func dependencies() -> Array[Reactive]:
	var out: Array[Reactive] = [store]
	if origin != null:
		out.append(origin)
	return out


func to_lua() -> Dictionary:
	var out := {
		"_id": id,
		"get_at": Callable(self, "lua_get"),
		"draft": Callable(self, "lua_draft"),
		"dirty": Callable(self, "lua_dirty"),
		"discard": Callable(self, "lua_discard"),
	}
	if not readonly:
		out["set_at"] = Callable(self, "lua_set")
		out["model"] = Callable(self, "lua_model")
	if not readonly and not origin_readonly:
		out["commit"] = Callable(self, "lua_commit")
	return out


func lua_get(key: Variant) -> Variant:
	return store.get_at(str(key))


## Converte para o tipo do valor atual.
## Ex.: o Input number manda 55.0, a store guarda 55.
func lua_set(key: Variant, new_value: Variant) -> void:
	if readonly:
		return
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
	if origin != null and not origin_readonly:
		origin.assign(store.value)


func lua_discard() -> void:
	if origin != null:
		store.assign(origin.value)


func lua_model(key: Variant) -> LuaModel:
	var k := str(key)
	return LuaModel.new(dependencies(), func() -> Variant: return store.get_at(k), func(v: Variant) -> void: lua_set(k, v))
