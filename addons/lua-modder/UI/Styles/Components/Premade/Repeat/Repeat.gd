extends Div
## Repeat: um Div cujos filhos vêm de uma lista reativa.
##
##   Repeat{
##     gap = 6,
##     items = UI.bind(store, "gauntlets"),          -- lista (Array) vinda de uma store
##     render_item =F function(item, index)           -- index começa em 0 (como os Array do Godot)
##       return Button{ label = item.name }
##     end,
##   }
##
## Quando `items` muda, TODOS os filhos são destruídos e `render_item` roda de novo para cada item.
## Se a lista chegar igual à anterior (comparação por valor), nada é refeito.
## O Repeat é dono dos próprios filhos: `children` estáticos são descartados na primeira montagem.

var _builder := LuaRepeatBuilder.new()

func get_schema() -> Dictionary:
	return LuaRepeatBuilder.extend_schema(super.get_schema(), "Repeat")   # "RepeatGrid" no outro

func _apply_prop(key: String, value: Variant) -> void:
	if key == "items":
		_builder.sync_for(self, _items, value)
		return
	super._apply_prop(key, value)
