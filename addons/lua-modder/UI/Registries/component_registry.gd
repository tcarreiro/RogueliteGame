extends Node
## Autoload: ComponentRegistry (registrar ANTES de LuaUi).
##
## Catálogo único de componentes. Uma cena (.tscn) e um componente definido em Lua
## (UI.defineComponent) viram a mesma coisa aqui: uma definição
##   { name, kind, schema, scene | render, source }
## Quem consome só conhece o nome, não importa de onde o componente veio.
##
## Fluxo: Tag{...} no Lua -> make_element() -> UIElement -> instantiate() -> nós

signal component_registered(component_name: String)

enum Kind { SCENE, LUA }

## Pastas escaneadas no boot (recursivo). Cenas do jogo ou de mods entram depois,
## com scan_directory() ou register_scene_path().
const SCAN_PATHS: Array[String] = ["res://addons/lua-modder/UI/Styles/Components/Premade/"]

## Limite de profundidade do instantiate(). Protege contra um render() Lua que se chama sem fim.
const MAX_DEPTH := 64

## Tipos que um componente Lua pode escrever como string no schema (props = { label = "string" }).
const _TYPE_NAMES := {
	"any": TYPE_NIL, "string": TYPE_STRING, "int": TYPE_INT, "float": TYPE_FLOAT,
	"number": TYPE_FLOAT, "bool": TYPE_BOOL, "color": TYPE_COLOR, "vector2": TYPE_VECTOR2,
	"array": TYPE_ARRAY, "dict": TYPE_DICTIONARY, "object": TYPE_OBJECT,
}

## Cache das props base, montado na primeira consulta (ver base_props()).
static var _base_props: Dictionary = {}

var _defs: Dictionary[StringName, ComponentDefinition] = {}   # component_name -> definição
var _refs: Dictionary = {}   # ref -> WeakRef(LuaComponent)


func _init() -> void:
	for path in SCAN_PATHS:
		scan_directory(path)


#region Registration
## Escaneia `path` e registra toda cena cuja raiz herde LuaComponent.
## Retorna quantas cenas foram registradas.
func scan_directory(path: String, recursive := true) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[ComponentRegistry] pasta inexistente: %s" % path)
		return 0
	var count := 0
	if recursive:
		for sub in dir.get_directories():
			count += scan_directory(path.path_join(sub), true)
	for file in dir.get_files():
		# no export os arquivos aparecem como "x.tscn.remap"
		var real := file.trim_suffix(".remap")
		if real.get_extension() in ["tscn", "scn"]:
			if register_scene_path(path.path_join(real)):
				count += 1
	return count


## Registra uma cena a partir do caminho. API para quem quer cadastrar uma cena à mão.
func register_scene_path(path: String, name_override := "") -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("[ComponentRegistry] não foi possível carregar %s" % path)
		return false
	return register_scene(scene, name_override, path)


## Registra uma cena cuja raiz herda LuaComponent. O nome vem, nesta ordem, de
## `name_override`, do `name` do schema ou do nome do arquivo.
func register_scene(scene: PackedScene, name_override := "", source := "") -> bool:
	var schema := _extract_schema_from_scene(scene)
	if schema.is_empty():
		push_error("[ComponentRegistry] raiz de '%s' precisa herdar LuaComponent" % source)
		return false

	var component_name := name_override
	if component_name == "":
		component_name = schema.get("name", "")
	if component_name == "" and source != "":
		component_name = source.get_file().get_basename()
	if component_name == "":
		push_error("[ComponentRegistry] Please, supply a component name on: (%s)" % source)
		return false
	return _register(ComponentDefinition.new(component_name, Kind.SCENE,
			schema, source, scene))


## Registra um componente definido em Lua. `definition` é a tabela já normalizada:
## { props, events, hooks, methods, slots, render }. O `render` é obrigatório.
func register_lua(component_name: String, definition: Dictionary) -> bool:
	var render := LuaHelper.make_callable(definition.get("render"))
	if not render.is_valid():
		push_error("[ComponentRegistry] '%s': definição Lua sem função `render`" % component_name)
		return false
	return _register(ComponentDefinition.new(component_name, Kind.LUA,
			normalize_schema(definition), "lua", null, render))


## Nome duplicado é ignorado com aviso: vale o primeiro que foi registrado.
func _register(def: ComponentDefinition) -> bool:
	var component_name: String = def.name
	if _defs.has(component_name):
		push_warning("[ComponentRegistry] '%s' já registrado (%s), ignorando." % [component_name, _defs[component_name].source])
		return false
	_defs[component_name] = def
	component_registered.emit(component_name)
	return true


func _extract_schema_from_scene(scene: PackedScene) -> Dictionary:
	# a instância "sonda" só serve para ler o schema; nunca entra na árvore
	var probe := scene.instantiate()
	if not probe is LuaComponent:
		probe.free()
		return {}
	var schema := normalize_schema(probe.get_schema())
	probe.free()
	return schema
#endregion


#region Queries
func get_names() -> Array:
	return _defs.keys()


## Definição de uma prop: primeiro nas props base, depois no schema do componente.
## Vazio se a prop não existe.
static func get_prop_def(schema: Dictionary, key: String) -> Dictionary:
	var base := base_props()
	if base.has(key):
		return base[key]
	return schema.get("props", {}).get(key, {})
#endregion


#region Base props
## Props que TODO componente aceita, sem precisar declarar no schema. Quem as aplica
## é o LuaComponent. A lista fica em PropertyDefinition.BASE e as definições (tipo, default,
## doc) vêm do catálogo, para existir uma fonte de verdade só.
static func base_props() -> Dictionary:
	if _base_props.is_empty():
		_base_props = PropertyDefinition.pick(PropertyDefinition.BASE)
	return _base_props
#endregion


#region Element building (Lua -> UIElement)
## Separa a tabela crua do Lua em props, handlers e slots, segundo o schema do componente.
##   children        -> slot "default"
##   slots = {...}   -> slots nomeados
##   ref             -> nome usado em UI.callMethod
##   on_<evento>     -> handler (evento declarado em schema.events)
##   <hook>          -> handler (declarado em schema.hooks)
## Chave que o schema não declara gera aviso, mas segue adiante para não perder o valor.
func make_element(component_name: String, raw: Dictionary) -> UIElement:
	# Raw represents overriden props as dictionary
	var def: ComponentDefinition = _defs.get(component_name, null)
	if def == null:
		push_error("[ComponentRegistry] componente desconhecido: '%s'" % component_name)
		return null
	var schema: Dictionary = def.schema
	var base := base_props()
	var el := UIElement.new(component_name)

	for key: String in raw:
		var value: Variant = raw[key]
		if value is LuaBinding:
			el.bindings[key] = value
			value = (value as LuaBinding).evaluate()   # valor inicial
		match key:
			"children":
				el.slots["default"] = _to_elements(value)
			"slots":
				if value is Dictionary:
					for slot_name in value:
						el.slots[str(slot_name)] = _to_elements(value[slot_name])
			"ref":
				el.ref = str(value)
			_:
				if (key.begins_with("on_") and key.substr(3) in schema.events) or key in schema.hooks:
					el.handlers[key] = LuaHelper.make_callable(value)
				elif base.has(key) or schema.props.has(key):
					el.props[key] = value
				else:
					push_warning("[ComponentRegistry] '%s' não declara '%s'" % [component_name, key])
					if key.begins_with("on_"):
						el.handlers[key] = LuaHelper.make_callable(value)
					else:
						el.props[key] = value
	return el


## Aceita um UIElement ou uma lista deles; descarta o que não for UIElement.
func _to_elements(value: Variant) -> Array:
	var out: Array = []
	if value is UIElement:
		out.append(value)
	elif value is Array:
		for item in value:
			if item is UIElement:
				out.append(item)
	return out
#endregion


#region Instantiation (UIElement -> Control)
## Cria os nós de um UIElement e dos seus filhos (recursivo).
func instantiate(el: UIElement, depth := 0) -> Control:
	if el == null:
		return null
	if depth > MAX_DEPTH:
		push_error("[ComponentRegistry] profundidade máxima excedida (render recursivo?) em '%s'" % el.component_name)
		return null
	var def: ComponentDefinition = _defs.get(el.component_name, null)
	if def == null:
		push_error("[ComponentRegistry] componente desconhecido: '%s'" % el.component_name)
		return null
	match def.kind:
		Kind.SCENE:
			return _instantiate_scene(def, el, depth)
		Kind.LUA:
			return _instantiate_lua(def, el, depth)
	return null


## Cena: instancia o PackedScene, entrega props já resolvidas e handlers pelo setup()
## (antes de entrar na árvore) e pendura os filhos nos slots declarados no schema.
func _instantiate_scene(def: ComponentDefinition, el: UIElement, depth: int) -> Control:
	var node := (def.scene as PackedScene).instantiate() as LuaComponent
	node.setup(el.component_name, resolve_props(def.schema, el.props), el.handlers, def.schema, el.bindings)
	for slot_name: String in el.slots:
		var host := node.get_slot(slot_name)
		if host == null:
			push_error("[ComponentRegistry] '%s' não tem o slot '%s'" % [el.component_name, slot_name])
			continue
		for child_el: UIElement in el.slots[slot_name]:
			var child := instantiate(child_el, depth + 1)
			if child:
				host.add_child(child)
	_track_ref(node, el.ref)
	return node


## Lua: chama o render() com props, handlers, children e slots, e instancia o
## UIElement que ele devolve. Não cria nó nenhum: o resultado é sempre uma cena
## (ou mais um componente Lua, que repete o processo).
func _instantiate_lua(def: ComponentDefinition, el: UIElement, depth: int) -> Control:
	var args := resolve_props(def.schema, el.props)
	args.merge(el.handlers)
	args["children"] = el.slots.get("default", [])
	var named := {}
	for slot_name: String in el.slots:
		if slot_name != "default":
			named[slot_name] = el.slots[slot_name]
	args["slots"] = named

	var result: Variant = (def.render as Callable).call(args)
	if not result is UIElement:
		push_error("[ComponentRegistry] render de '%s' deve retornar um componente (retornou %s)" % [el.component_name, result])
		return null
	# o ref passa para o elemento renderizado, então aponta sempre para um nó real
	if el.ref != "" and result.ref == "":
		result.ref = el.ref
	return instantiate(result, depth + 1)
#endregion


#region Refs (Lua -> métodos expostos)
## Guarda o nó por nome
func _track_ref(node: LuaComponent, ref: String) -> void:
	if ref == "":
		return
	_refs[ref] = weakref(node)
	node.tree_exited.connect(func():
		if _refs.get(ref) and _refs[ref].get_ref() == node:
			_refs.erase(ref))


func get_ref(ref: String) -> LuaComponent:
	var w: WeakRef = _refs.get(ref)
	return w.get_ref() if w else null


## Chama um método de um componente pelo ref. O LuaComponent confere a whitelist.
func call_method(ref: String, method: String, args: Array = []) -> Variant:
	var node := get_ref(ref)
	if node == null:
		push_error("[ComponentRegistry] ref '%s' não encontrada" % ref)
		return null
	return node.call_exposed(method, args)
#endregion


#region Schema and props
## Normaliza um schema (de cena ou de Lua) para:
##   { name, props, events, hooks, methods, slots }
## - props: cada uma vira { type, default, ... }. Atalho no Lua: props = { label = "string" }.
##   Chaves extras, como `options` e `required`, passam intactas.
## - slots: na cena é { nome: "%NodePath" }. No Lua são só os nomes (caminho vazio).
static func normalize_schema(raw: Dictionary) -> Dictionary:
	var schema := {"name": str(raw.get("name", "")), "props": {}, "events": [], "hooks": [], "methods": [], "slots": {}}

	var raw_props: Variant = raw.get("props", {})
	if raw_props is Dictionary:
		for key in raw_props:
			var p: Variant = raw_props[key]
			var def := {}
			if p is Dictionary:
				def = p.duplicate()
			else:
				def = {"type": p}
			var t: Variant = def.get("type", TYPE_NIL)
			def["type"] = _TYPE_NAMES.get(t, TYPE_NIL) if t is String else int(t)
			if not def.has("default"):
				def["default"] = type_convert(null, def.type) if def.type != TYPE_NIL and def.type != TYPE_OBJECT else null
			schema.props[str(key)] = def

	for list_key in ["events", "hooks", "methods"]:
		var raw_list: Variant = raw.get(list_key, [])
		if raw_list is Array:
			for item in raw_list:
				schema[list_key].append(str(item))

	var raw_slots: Variant = raw.get("slots", {})
	if raw_slots is Dictionary:
		for key in raw_slots:
			schema.slots[str(key)] = str(raw_slots[key])
	elif raw_slots is Array:
		for item in raw_slots:
			schema.slots[str(item)] = ""
	return schema


## Props finais = base + schema, cada uma com default e coerção de tipo.
## Props que ninguém declarou passam adiante como vieram (o make_element já avisou).
## Um schema de Lua pode marcar uma prop com `required = true` para gerar aviso quando faltar.
static func resolve_props(schema: Dictionary, given: Dictionary) -> Dictionary:
	var out := {}
	var all_defs: Dictionary = base_props().duplicate()
	all_defs.merge(schema.get("props", {}), true)
	for key: String in all_defs:
		var def: Dictionary = all_defs[key]
		if given.has(key):
			out[key] = coerce(given[key], def)
		else:
			if def.get("required", false):
				push_warning("[ComponentRegistry] prop obrigatória ausente: '%s'" % key)
			var d: Variant = def.get("default")
			out[key] = d.duplicate(true) if (d is Array or d is Dictionary) else d
	for key: String in given:
		if not out.has(key):
			out[key] = given[key]
	return out


## Valida e converte um valor para a definição da prop.
##   nulo            -> default
##   fora de options -> aviso e default
##   cor             -> parse_color (aceita "#hex", nome ou lista {r, g, b, a})
##   Vector2         -> aceita lista de 2 números
##   tipo ANY/OBJECT -> sem conversão
static func coerce(value: Variant, def: Dictionary) -> Variant:
	if value == null:
		return def.get("default")
	var options: Array = def.get("options", [])
	if not options.is_empty() and not options.any(func(o): return str(o) == str(value)):
		push_warning("[ComponentRegistry] valor '%s' inválido, opções: %s" % [value, options])
		return def.get("default")
	var t: int = def.get("type", TYPE_NIL)
	if t == TYPE_NIL or t == TYPE_OBJECT or typeof(value) == t:
		return value
	if t == TYPE_VECTOR2 and value is Array and value.size() == 2:
		return Vector2(value[0], value[1])
	if t == TYPE_COLOR:
		return LuaHelper.parse_color(value)
	return type_convert(value, t)
#endregion
