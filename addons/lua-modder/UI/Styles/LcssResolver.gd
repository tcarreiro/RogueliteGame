class_name LCSSResolver extends RefCounted

static func resolve(component: LuaComponent, registry: LCSSRegistry) -> LCSSStyle:
	var matched: Array[Dictionary] = []  
	var order := 0
	for sheet in registry.get_stylesheets():
		for style_class: LCSSStyleClass in sheet.get_style_classes():
			if style_class.matches(component, false):
				matched.append({LCSS.STYLE_CLASS: style_class, "order": order})
			order += 1

	matched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = (a[LCSS.STYLE_CLASS] as LCSSStyleClass).get_specificity()
		var sb: int = (b[LCSS.STYLE_CLASS] as LCSSStyleClass).get_specificity()
		if sa != sb:
			return sa < sb
		return int(a["order"]) < int(b["order"]))

	var style := LCSSStyle.new()
	for entry in matched:
		var style_class: LCSSStyleClass = entry[LCSS.STYLE_CLASS]
		var state := style_class.get_own_state()
		var target: LCSSStyle = style if state == &"" else style.ensure_state(state)
		for property: StringName in style_class.properties:
			target.set_property(property, (style_class.properties[property] as LCSSProperty).value)
	return style


## Estado declarado na ÚLTIMA parte do selector (":hover" em ".foo:hover").
static func _own_state(style_class: LCSSStyleClass) -> StringName:
	if style_class.selectors.is_empty():
		return &""
	var last = style_class.selectors[style_class.selectors.size() - 1]
	return last.state
