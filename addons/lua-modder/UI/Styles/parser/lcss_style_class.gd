class_name LCSSStyleClass extends RefCounted
## Uma regra do .lcss: seletor + propriedades.
##
## `selectors` é a cadeia de trechos separados por espaço (descendente):
##   .a.b:hover .c  ->  [ { classes: [a, b], states: [hover] }, { classes: [c], states: [] } ]
## Dentro de um trecho, tudo que está colado exige o MESMO componente.
## Entre trechos, cada um precisa ser achado em um ancestral, nessa ordem.

var style_sheet: LCSSStyleSheet
var token: LCSSToken
# A StyleClass can have multiple selectors, like .main-menu.primary-button:hover {}
var selectors: Array[LCSSStyleSelector] = []
var properties: Dictionary[StringName, LCSSProperty] = {}

class LCSSStyleSelector:
	extends RefCounted
	var classes: Array[StringName] = []
	var states: Array[StringName] = []
	
	func matches(component: LuaComponent, match_states: bool) -> bool:
		for style_class in classes:
			if not component.has_class(style_class):
				return false
		if match_states:
			for state in states:
				if not component.is_style_state_active(state):
					return false
		return true

	func get_specificity() -> int:
		return classes.size() + states.size()

	func _to_string() -> String:
		return "LCSSStyleSelector(classes=%s, states=%s)" % [classes, states]


func _init(_style_sheet: LCSSStyleSheet, _token: LCSSToken) -> void:
	style_sheet = _style_sheet
	token = _token
	parse()


func parse() -> void:
	LCSSParser.parse_style_class(self)


func add_style_selector(_style_selector: LCSSStyleSelector) -> void:
	selectors.append(_style_selector)


func add_property(_property: LCSSProperty) -> void:
	properties[_property.name] = _property


## O último trecho é o componente alvo. Os anteriores são procurados nos ancestrais, do mais
## próximo para cima (com só o combinador de descendente, o ancestral mais próximo basta).
func matches(component: LuaComponent, match_states: bool = true) -> bool:
	if component == null or selectors.is_empty():
		return false

	var index := selectors.size() - 1
	if not selectors[index].matches(component, match_states):
		return false

	var current: LuaComponent = component
	index -= 1
	while index >= 0:
		current = _find_matching_ancestor(selectors[index], current, match_states)
		if current == null:
			return false
		index -= 1
	return true


func _find_matching_ancestor(selector: LCSSStyleSelector, from_component: LuaComponent, match_states: bool) -> LuaComponent:
	var node := from_component.get_parent()
	while node != null:
		var component := node as LuaComponent
		if component != null and selector.matches(component, match_states):
			return component
		node = node.get_parent()
	return null


func get_specificity() -> int:
	var total := 0
	for selector in selectors:
		total += selector.get_specificity()
	return total


## Estado da regra = o do último trecho. Só o primeiro estado é usado.
func get_own_state() -> StringName:
	if selectors.is_empty():
		return &""
	var last := selectors[selectors.size() - 1]
	return last.states[0] if not last.states.is_empty() else &""


func _to_string() -> String:
	return "LCSSStyleClass(selectors=%s, properties=%s)" % [selectors, properties.values()]
