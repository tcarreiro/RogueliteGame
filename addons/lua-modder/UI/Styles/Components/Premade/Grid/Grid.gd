extends LuaStyledBox

@onready var _items: LuaGridBox = %Items


func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.COLUMNS, PropertyDefinition.GAP, PropertyDefinition.COLUMN_GAP,
			PropertyDefinition.ROW_GAP, PropertyDefinition.FILL_CELLS]
	names.append_array(LuaStyledBox.box_names())
	return {
		"name": "Grid",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 4}),
		"slots": {"default": "%Items"},
	}


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.COLUMNS:
			_items.columns = maxi(int(value), 1)
		PropertyDefinition.GAP, PropertyDefinition.COLUMN_GAP, PropertyDefinition.ROW_GAP:
			_refresh_gaps()
		PropertyDefinition.FILL_CELLS:
			_items.fill = bool(value)
		_:
			super._apply_prop(key, value)


## column_gap e row_gap vencem o gap quando definidos. Lê de props: a ordem não importa.
func _refresh_gaps() -> void:
	var gap := maxi(int(props.get("gap", 0)), 0)
	var column: Variant = props.get("column_gap")
	var row: Variant = props.get("row_gap")
	_items.add_theme_constant_override("h_separation", maxi(int(column), 0) if column != null else gap)
	_items.add_theme_constant_override("v_separation", maxi(int(row), 0) if row != null else gap)
