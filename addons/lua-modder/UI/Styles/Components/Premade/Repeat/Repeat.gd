extends "res://addons/lua-modder/UI/Styles/Components/Premade/Div/Div.gd"
## Repeat: um Div cujos filhos vêm de uma lista reativa.
##
##   Repeat{
##     gap = 6,
##     items = UI.bind(store, "gauntlets"),          -- lista (Array) vinda de uma store
##     render_item = function(item, index)           -- index começa em 0 (como os Array do Godot)
##       return Button{ label = item.name }
##     end,
##   }
##
## Quando `items` muda, TODOS os filhos são destruídos e `render_item` roda de novo para cada item.
## Se a lista chegar igual à anterior (comparação por valor), nada é refeito.
## O Repeat é dono dos próprios filhos: `children` estáticos são descartados na primeira montagem.

var _built := false
var _last_items: Array = []


func get_schema() -> Dictionary:
	var schema := super.get_schema()
	schema["name"] = "Repeat"
	schema["props"]["items"] = {"type": "array", "default": []}
	schema["hooks"] = ["render_item"]
	return schema


func _apply_prop(key: String, value: Variant) -> void:
	if key == "items":
		_rebuild(value if value is Array else [])
		return
	super._apply_prop(key, value)


func _rebuild(items: Array) -> void:
	if _built and items == _last_items:
		return
	_built = true
	_last_items = items.duplicate(true)

	for child in _items.get_children():
		_items.remove_child(child)
		if child is LuaComponent:
			(child as LuaComponent).dispose()
		else:
			child.queue_free()

	var render_item: Callable = handlers.get("render_item", Callable())
	if not render_item.is_valid():
		push_warning("[Repeat] render_item hook missing")
		return

	for i in items.size():
		var el: Variant = render_item.call(items[i], i)
		if not el is UIElement:
			push_warning("[Repeat] render_item must return a LuaComponent (item %d)" % i)
			continue
		var node := ComponentRegistry.instantiate(el as UIElement)
		if node != null:
			_items.add_child(node)
