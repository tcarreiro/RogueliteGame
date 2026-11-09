class_name LCSSResolver extends RefCounted

static var _index: Dictionary = {}                 # StringName -> Array (regras)
static var _universal: Array = []                  # regras cujo último trecho não tem classe
static var _built := false

## Chame depois de carregar/registrar qualquer stylesheet (ou recarregar).
static func invalidate() -> void:
	_built = false


static func _build_index(registry: LCSSRegistry) -> void:
	_index.clear()
	_universal.clear()
	var order := 0
	for sheet in registry.get_stylesheets():
		for style_class: LCSSStyleClass in sheet.get_style_classes():
			style_class.sort_key = (style_class.get_specificity() << 20) | order
			order += 1   # mesma contagem do código antigo (conta toda regra)
			if style_class.selectors.is_empty():
				continue
			var last := style_class.selectors[style_class.selectors.size() - 1]
			if last.classes.is_empty():
				_universal.append(style_class)
			else:
				var key: StringName = last.classes[0]
				if not _index.has(key):
					_index[key] = []
				_index[key].append(style_class)
	_built = true


static func resolve(component: LuaComponent, registry: LCSSRegistry) -> LCSSStyle:
	if not _built:
		_build_index(registry)
	
	var matched: Array[LCSSStyleClass] = []
	for style_class: LCSSStyleClass in _universal:
		if style_class.matches(component, false):
			matched.append(style_class)
	for cls in component.style_classes:
		for style_class: LCSSStyleClass in _index.get(cls, []):
			if style_class.matches(component, false):
				matched.append(style_class)
	
	matched.sort_custom(func(a: LCSSStyleClass, b: LCSSStyleClass) -> bool: return a.sort_key < b.sort_key)

	var style := LCSSStyle.new()
	for style_class in matched:
		var state := style_class.get_own_state()
		var target: LCSSStyle = style if state == &"" else style.ensure_state(state)
		for property: StringName in style_class.properties:
			target.set_property(property, (style_class.properties[property] as LCSSProperty).value)
	return style
	#var matched: Array[Dictionary] = []  
	#var order := 0
	#for sheet in registry.get_stylesheets():
		#for style_class: LCSSStyleClass in sheet.get_style_classes():
			#if style_class.matches(component, false):
				#matched.append({LCSS.STYLE_CLASS: style_class, "order": order})
			#order += 1

	#matched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		#var sa: int = (a[LCSS.STYLE_CLASS] as LCSSStyleClass).get_specificity()
		#var sb: int = (b[LCSS.STYLE_CLASS] as LCSSStyleClass).get_specificity()
		#if sa != sb:
			#return sa < sb
		#return int(a["order"]) < int(b["order"]))

	#var style := LCSSStyle.new()
	#for entry in matched:
		#var style_class: LCSSStyleClass = entry[LCSS.STYLE_CLASS]
		#var state := style_class.get_own_state()
		#var target: LCSSStyle = style if state == &"" else style.ensure_state(state)
		#for property: StringName in style_class.properties:
			#target.set_property(property, (style_class.properties[property] as LCSSProperty).value)
	#return style


## Estado declarado na ÚLTIMA parte do selector (":hover" em ".foo:hover").
static func _own_state(style_class: LCSSStyleClass) -> StringName:
	if style_class.selectors.is_empty():
		return &""
	var last = style_class.selectors[style_class.selectors.size() - 1]
	return last.state
