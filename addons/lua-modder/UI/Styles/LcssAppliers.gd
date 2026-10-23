class_name LCSSAppliers extends RefCounted
## Handler único usado por TODO componente que registra propriedades em um
## LCSSStyleTarget. Sabe COMO cada propriedade vira Godot de verdade; o componente
## só declara ONDE. Recebe sempre nomes CANÔNICOS (PropertyDefinition.*), nunca o contexto
## escrito no .lua/.lcss (quem traduz contexto -> canônico é o LCSSStyleTarget).

#region Meta names
const LCSS_APPLIED_PREFIX := &"_lcss_applied_"
const LCSS_BOX := &"_lcss_box"
const LCSS_SCROLLBAR := &"_lcss_scrollbar"
const LCSS_TEX_BOX := &"_lcss_tex_box"
const LCSS_IMAGE := &"_lcss_image"
#endregion

# mesma ordem de PropertyDefinition.FAMILIES
const _SIDES := [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]
const _CORNERS := [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]
# padding também usa margin_*: o alvo é um MarginContainer
const _MARGIN_CONSTANTS := ["margin_left", "margin_top", "margin_right", "margin_bottom"]
const _RICH_FONT_SIZES := ["normal_font_size", "bold_font_size", "italics_font_size",
		"bold_italics_font_size", "mono_font_size"]

static func apply(property: StringName, value: Variant, target: Node) -> void:
	match property:
		PropertyDefinition.BACKGROUND_COLOR, PropertyDefinition.BORDER_COLOR, \
		PropertyDefinition.DROP_SHADOW_COLOR, PropertyDefinition.DROP_SHADOW_SIZE, \
		PropertyDefinition.DROP_SHADOW_OFFSET:
			_apply_stylebox_field(target as Control, property, value)
		PropertyDefinition.BACKGROUND_IMAGE, PropertyDefinition.BACKGROUND_IMAGE_TINT, \
		PropertyDefinition.BACKGROUND_IMAGE_STRETCH:
			_apply_image_field(target as Control, property, value)
		PropertyDefinition.FONT_COLOR, PropertyDefinition.FONT_SIZE, \
		PropertyDefinition.OUTLINE_COLOR, PropertyDefinition.OUTLINE_THICKNESS:
			_apply_text_style(target as Control, property, value)
		PropertyDefinition.SCROLLBAR_WIDTH, PropertyDefinition.SCROLLBAR_TRACK_COLOR, \
		PropertyDefinition.SCROLLBAR_GRABBER_COLOR, PropertyDefinition.SCROLLBAR_GRABBER_HOVER_COLOR, \
		PropertyDefinition.SCROLLBAR_GRABBER_PRESSED_COLOR, PropertyDefinition.SCROLL_HINT_COLOR:
			_apply_scrollbar(target as ScrollContainer, property, value)
		PropertyDefinition.SCROLLBAR_GAP:
			_apply_scrollbar_gap(target as ScrollContainer, value)
		PropertyDefinition.TEXT_SHADOW_COLOR, PropertyDefinition.TEXT_SHADOW_OFFSET, PropertyDefinition.TEXT_SHADOW_OUTLINE, \
		PropertyDefinition.LINE_SPACING, PropertyDefinition.PARAGRAPH_SPACING, \
		PropertyDefinition.SELECTION_COLOR, PropertyDefinition.SELECTED_FONT_COLOR:
			_apply_text_extras(target as Control, property, value)
		PropertyDefinition.SCALE, PropertyDefinition.ROTATE, PropertyDefinition.TRANSLATE, PropertyDefinition.TRANSFORM_ORIGIN:
			_apply_transform(target as Control, property, value)
		# TODO: SCROLL_HINT e SCROLL_HINT_TILE entram aqui quando existir o handler de textura
		_:
			push_warning("[LCSSAppliers] propriedade sem applier: '%s'" % property)


#region Famílias
## Recebe UM valor por parte (ordem de PropertyDefinition.FAMILIES); null = indefinido.
static func apply_family(family: StringName, values: Array, target: Node) -> void:
	match family:
		PropertyDefinition.MARGIN, PropertyDefinition.PADDING:
			_apply_box_family(target as MarginContainer, family, values)
		PropertyDefinition.BORDER_WIDTH, PropertyDefinition.BORDER_RADIUS:
			_apply_border_family(target as Control, family, values)
		PropertyDefinition.SCROLLBAR_BORDER_RADIUS:
			_apply_scrollbar_radius(target as ScrollContainer, values)
		PropertyDefinition.BACKGROUND_IMAGE_SLICE:
			_apply_slice_family(target as Control, values)
		_:
			push_warning("[LCSSAppliers] família sem applier: '%s'" % family)


static func _apply_box_family(node: MarginContainer, family: StringName, values: Array) -> void:
	if node == null:
		return
	node.begin_bulk_theme_override()
	_apply_parts(node, family, values,
		func(i, v): node.add_theme_constant_override(_MARGIN_CONSTANTS[i], int(v)),
		func(i): node.remove_theme_constant_override(_MARGIN_CONSTANTS[i]))
	node.end_bulk_theme_override()


static func _apply_border_family(target: Control, family: StringName, values: Array) -> void:
	if target == null:
		return
	# não cria StyleBoxFlat à toa: só com valor, ou se já existe (para poder desfazer)
	if not _has_any(values) and not target.has_meta(LCSS_BOX):
		return
	var box := _get_box(target)
	if family == PropertyDefinition.BORDER_WIDTH:
		_apply_parts(target, family, values,
			func(i, v): box.set_border_width(_SIDES[i], int(v)),
			func(i): box.set_border_width(_SIDES[i], 0))
	else:
		_apply_parts(target, family, values,
			func(i, v): box.set_corner_radius(_CORNERS[i], int(v)),
			func(i): box.set_corner_radius(_CORNERS[i], 0))


## Aplica as partes não nulas e desfaz as que ESTE applier aplicou antes e que agora
## estão indefinidas (ex.: um padding_left que existia só no :hover).
## O que o .tscn definiu à mão nunca é tocado. Os callables recebem o ÍNDICE da parte.
static func _apply_parts(target: Object, family: StringName, values: Array,
		set_fn: Callable, reset_fn: Callable) -> void:
	var meta_key := StringName("%s%s" % [LCSS_APPLIED_PREFIX, family])
	var applied: Dictionary = target.get_meta(meta_key, {})
	for i in values.size():
		if values[i] != null:
			set_fn.call(i, values[i])
			applied[i] = true
		elif applied.has(i):
			reset_fn.call(i)
			applied.erase(i)
	target.set_meta(meta_key, applied)


static func _has_any(values: Array) -> bool:
	for v in values:
		if v != null:
			return true
	return false
#endregion


#region StyleBoxFlat
static func _apply_stylebox_field(target: Control, property: StringName, value: Variant) -> void:
	if target == null or value == null:
		return
	var box := _get_box(target)
	match property:
		PropertyDefinition.BACKGROUND_COLOR: box.bg_color = LuaHelper.parse_color(value)
		PropertyDefinition.BORDER_COLOR: box.border_color = LuaHelper.parse_color(value)
		PropertyDefinition.DROP_SHADOW_COLOR: box.shadow_color = LuaHelper.parse_color(value)
		PropertyDefinition.DROP_SHADOW_SIZE: box.shadow_size = int(value)
		PropertyDefinition.DROP_SHADOW_OFFSET:
			var v := LuaHelper.parse_distributable(value)
			box.shadow_offset = Vector2(v[0], v[1])


## Quem decide QUAL alvo recebe é o contexto no LCSSStyleTarget; aqui o nome é canônico.
static func _apply_text_style(target: Control, property: StringName, value: Variant) -> void:
	if target == null or value == null:
		return
	if target is RichTextLabel:
		_apply_rich_text_style(target, property, value)
		return
	match property:
		PropertyDefinition.FONT_COLOR:
			var color := LuaHelper.parse_color(value)
			target.add_theme_color_override("font_color", color)
			if target is LineEdit:
				target.add_theme_color_override("font_uneditable_color", color)
		PropertyDefinition.FONT_SIZE:
			target.add_theme_font_size_override("font_size", int(value))
		PropertyDefinition.OUTLINE_COLOR:
			target.add_theme_color_override("font_outline_color", LuaHelper.parse_color(value))
		PropertyDefinition.OUTLINE_THICKNESS:
			target.add_theme_constant_override("outline_size", int(value))


static func _apply_rich_text_style(target: Control, property: StringName, value: Variant) -> void:
	match property:
		PropertyDefinition.FONT_COLOR:
			target.add_theme_color_override("default_color", LuaHelper.parse_color(value))
		PropertyDefinition.FONT_SIZE:
			for n in _RICH_FONT_SIZES:
				target.add_theme_font_size_override(n, int(value))
		PropertyDefinition.OUTLINE_COLOR:
			target.add_theme_color_override("font_outline_color", LuaHelper.parse_color(value))
		PropertyDefinition.OUTLINE_THICKNESS:
			target.add_theme_constant_override("outline_size", int(value))   # verificar

#endregion


#region Scrollbar
static func _apply_scrollbar(scroll: ScrollContainer, property: StringName, value: Variant) -> void:
	if scroll == null or value == null:
		return
	var cfg: Dictionary = scroll.get_meta(LCSS_SCROLLBAR, {})
	cfg[property] = value
	scroll.set_meta(LCSS_SCROLLBAR, cfg)
	_rebuild_scrollbar(scroll)


## Os 4 cantos vêm da família (um valor por canto, null = 0).
static func _apply_scrollbar_radius(scroll: ScrollContainer, values: Array) -> void:
	if scroll == null:
		return
	var cfg: Dictionary = scroll.get_meta(LCSS_SCROLLBAR, {})
	if not _has_any(values) and not cfg.has(PropertyDefinition.SCROLLBAR_BORDER_RADIUS):
		return
	cfg[PropertyDefinition.SCROLLBAR_BORDER_RADIUS] = values
	scroll.set_meta(LCSS_SCROLLBAR, cfg)
	_rebuild_scrollbar(scroll)


static func _rebuild_scrollbar(scroll: ScrollContainer) -> void:
	var cfg: Dictionary = scroll.get_meta(LCSS_SCROLLBAR, {})
	var thickness := maxi(int(cfg.get(PropertyDefinition.SCROLLBAR_WIDTH, 12)), 1)
	var track_color := LuaHelper.parse_color(cfg.get(PropertyDefinition.SCROLLBAR_TRACK_COLOR, Color(0, 0, 0, 0.1)))
	var grabber_color := LuaHelper.parse_color(cfg.get(PropertyDefinition.SCROLLBAR_GRABBER_COLOR, Color(1, 1, 1, 0.3)))
	var hover_color := LuaHelper.parse_color(cfg.get(PropertyDefinition.SCROLLBAR_GRABBER_HOVER_COLOR, grabber_color))
	var pressed_color := LuaHelper.parse_color(cfg.get(PropertyDefinition.SCROLLBAR_GRABBER_PRESSED_COLOR, grabber_color))
	var radius: Array = cfg.get(PropertyDefinition.SCROLLBAR_BORDER_RADIUS, [])

	if cfg.has(PropertyDefinition.SCROLL_HINT_COLOR):
		var hint := LuaHelper.parse_color(cfg[PropertyDefinition.SCROLL_HINT_COLOR])
		scroll.add_theme_color_override("scroll_hint_vertical_color", hint)
		scroll.add_theme_color_override("scroll_hint_horizontal_color", hint)

	_style_bar(scroll.get_v_scroll_bar(), true, thickness, track_color, grabber_color, hover_color, pressed_color, radius)
	_style_bar(scroll.get_h_scroll_bar(), false, thickness, track_color, grabber_color, hover_color, pressed_color, radius)


static func _style_bar(bar: ScrollBar, vertical: bool, thickness: int, track_color: Color,
		grabber_color: Color, hover_color: Color, pressed_color: Color, radius: Array) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = track_color
	_set_corners(track, radius)

	# Espessura no eixo CRUZADO. Segundo as docs de H/VScrollBar, as content margins de
	# `scroll` NO EIXO da barra viram padding do grabber, então ficam em 0.
	var half := thickness / 2.0
	if vertical:
		track.content_margin_left = half
		track.content_margin_right = half
		track.content_margin_top = 0
		track.content_margin_bottom = 0
	else:
		track.content_margin_top = half
		track.content_margin_bottom = half
		track.content_margin_left = 0
		track.content_margin_right = 0

	bar.begin_bulk_theme_override()
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", _grabber_box(grabber_color, radius))
	bar.add_theme_stylebox_override("grabber_highlight", _grabber_box(hover_color, radius))
	bar.add_theme_stylebox_override("grabber_pressed", _grabber_box(pressed_color, radius))
	bar.end_bulk_theme_override()


static func _grabber_box(color: Color, radius: Array) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	_set_corners(box, radius)
	return box


static func _set_corners(box: StyleBoxFlat, r: Array) -> void:
	for i in 4:
		box.set_corner_radius(_CORNERS[i], _corner(r, i))


static func _corner(r: Array, i: int) -> int:
	return maxi(int(r[i]), 0) if r.size() > i and r[i] != null else 0


## Doc: scrollbar_h_separation = espaço entre a barra VERTICAL e o conteúdo;
## scrollbar_v_separation = espaço entre a barra HORIZONTAL e o conteúdo.
static func _apply_scrollbar_gap(scroll: ScrollContainer, value: Variant) -> void:
	if scroll == null or value == null:
		return
	var g := LuaHelper.parse_distributable(value)
	scroll.add_theme_constant_override("scrollbar_h_separation", int(g[0]))
	scroll.add_theme_constant_override("scrollbar_v_separation", int(g[1]))


static func _apply_text_extras(target: Control, property: StringName, value: Variant) -> void:
	if target == null or value == null:
		return
	var rich := target is RichTextLabel
	match property:
		PropertyDefinition.TEXT_SHADOW_COLOR:
			target.add_theme_color_override("font_shadow_color", LuaHelper.parse_color(value))
		PropertyDefinition.TEXT_SHADOW_OFFSET:
			var v := LuaHelper.parse_distributable(value)
			target.add_theme_constant_override("shadow_offset_x", int(v[0]))
			target.add_theme_constant_override("shadow_offset_y", int(v[1]))
		PropertyDefinition.TEXT_SHADOW_OUTLINE:
			target.add_theme_constant_override("shadow_outline_size", int(value))
		PropertyDefinition.LINE_SPACING:
			target.add_theme_constant_override("line_separation" if rich else "line_spacing", int(value))
		PropertyDefinition.PARAGRAPH_SPACING:
			target.add_theme_constant_override("paragraph_separation" if rich else "paragraph_spacing", int(value))
		PropertyDefinition.SELECTION_COLOR:
			target.add_theme_color_override("selection_color", LuaHelper.parse_color(value))
		PropertyDefinition.SELECTED_FONT_COLOR:
			target.add_theme_color_override("font_selected_color", LuaHelper.parse_color(value))


static func _apply_transform(target: Control, property: StringName, value: Variant) -> void:
	if target == null or value == null:
		return
	target.offset_transform_enabled = true
	target.offset_transform_visual_only = true
	match property:
		PropertyDefinition.SCALE:
			var s := LuaHelper.parse_distributable(value)
			target.offset_transform_scale = Vector2(s[0], s[1])
		PropertyDefinition.ROTATE:
			target.offset_transform_rotation = deg_to_rad(float(value))
		PropertyDefinition.TRANSLATE:
			var t := LuaHelper.parse_distributable(value)
			target.offset_transform_position = Vector2(t[0], t[1])
		PropertyDefinition.TRANSFORM_ORIGIN:
			var o := LuaHelper.parse_distributable(value)
			target.offset_transform_pivot_ratio = Vector2(o[0], o[1])
#endregion


#region StyleBoxTexture
static func _get_box(target: Control) -> StyleBoxFlat:
	if target.has_meta(LCSS_BOX):
		return target.get_meta(LCSS_BOX)
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT   # o default do engine é cinza opaco
	target.set_meta(LCSS_BOX, box)
	if not _image_active(target):
		target.add_theme_stylebox_override("panel", box)
	return box


static func _tex_box(target: Control) -> StyleBoxTexture:
	if target.has_meta(LCSS_TEX_BOX):
		return target.get_meta(LCSS_TEX_BOX)
	var box := StyleBoxTexture.new()
	box.set_content_margin_all(0)   # sem isto, texture_margin vira content margin (doc)
	target.set_meta(LCSS_TEX_BOX, box)
	return box


static func _image_active(target: Control) -> bool:
	return str(target.get_meta(LCSS_IMAGE, "")) != ""


static func _apply_image_field(target: Control, property: StringName, value: Variant) -> void:
	if target == null or value == null:
		return
	var box := _tex_box(target)
	match property:
		PropertyDefinition.BACKGROUND_IMAGE:
			var path := str(value)
			if path == "":
				_remove_image(target)
				return
			if not path.begins_with("res://") and not path.begins_with("user://"):
				path = "res://" + path
			var texture := load(path) as Texture2D
			if texture == null:
				push_warning("[LCSSAppliers] background_image não encontrada: '%s'" % path)
				return
			box.texture = texture
			target.set_meta(LCSS_IMAGE, path)
			target.add_theme_stylebox_override("panel", box)
		PropertyDefinition.BACKGROUND_IMAGE_TINT:
			box.modulate_color = LuaHelper.parse_color(value)
		PropertyDefinition.BACKGROUND_IMAGE_STRETCH:
			var mode: int = PropertyDefinition.STRETCH_MODES.get(StringName(str(value)), StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH)
			box.axis_stretch_horizontal = mode
			box.axis_stretch_vertical = mode


static func _remove_image(target: Control) -> void:
	if not _image_active(target):
		return
	target.set_meta(LCSS_IMAGE, "")
	if target.has_meta(LCSS_BOX):
		target.add_theme_stylebox_override("panel", target.get_meta(LCSS_BOX))
	else:
		target.remove_theme_stylebox_override("panel")


static func _apply_slice_family(target: Control, values: Array) -> void:
	if target == null:
		return
	if not _has_any(values) and not target.has_meta(LCSS_TEX_BOX):
		return
	var box := _tex_box(target)
	_apply_parts(target, PropertyDefinition.BACKGROUND_IMAGE_SLICE, values,
		func(i, v): box.set_texture_margin(_SIDES[i], float(v)),
		func(i): box.set_texture_margin(_SIDES[i], 0.0))
#endregion


#region Reset
## Famílias já se desfazem sozinhas via _apply_parts. Aqui ficam as simples. Não cobre scrollbar_*.
static func reset(property: StringName, target: Node) -> void:
	var control := target as Control
	if control == null:
		return
	
	if control is RichTextLabel and PropertyDefinition.FONT.has(property):
		match property:
			PropertyDefinition.FONT_COLOR: control.remove_theme_color_override("default_color")
			PropertyDefinition.FONT_SIZE:
				for n in _RICH_FONT_SIZES:
					control.remove_theme_font_size_override(n)
			PropertyDefinition.OUTLINE_COLOR: control.remove_theme_color_override("font_outline_color")
			PropertyDefinition.OUTLINE_THICKNESS: control.remove_theme_constant_override("outline_size")
		return
	var flat: StyleBoxFlat = control.get_meta(LCSS_BOX) if control.has_meta(LCSS_BOX) else null
	var tex: StyleBoxTexture = control.get_meta(LCSS_TEX_BOX) if control.has_meta(LCSS_TEX_BOX) else null
	match property:
		PropertyDefinition.BACKGROUND_COLOR:
			if flat: flat.bg_color = Color.TRANSPARENT
		PropertyDefinition.BORDER_COLOR:
			if flat: flat.border_color = Color.TRANSPARENT
		PropertyDefinition.DROP_SHADOW_COLOR:
			if flat: flat.shadow_color = Color(0, 0, 0, 0.6)
		PropertyDefinition.DROP_SHADOW_SIZE:
			if flat: flat.shadow_size = 0
		PropertyDefinition.DROP_SHADOW_OFFSET:
			if flat: flat.shadow_offset = Vector2.ZERO
		PropertyDefinition.BACKGROUND_IMAGE:
			_remove_image(control)
		PropertyDefinition.BACKGROUND_IMAGE_TINT:
			if tex: tex.modulate_color = Color.WHITE
		PropertyDefinition.BACKGROUND_IMAGE_STRETCH:
			if tex:
				tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
				tex.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		PropertyDefinition.SCALE:
			control.offset_transform_scale = Vector2.ONE
		PropertyDefinition.ROTATE:
			control.offset_transform_rotation = 0.0
		PropertyDefinition.TRANSLATE:
			control.offset_transform_position = Vector2.ZERO
		PropertyDefinition.TRANSFORM_ORIGIN:
			control.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		PropertyDefinition.FONT_COLOR:
			control.remove_theme_color_override("font_color")
		PropertyDefinition.FONT_SIZE:
			control.remove_theme_font_size_override("font_size")
		PropertyDefinition.OUTLINE_COLOR:
			control.remove_theme_color_override("font_outline_color")
		PropertyDefinition.OUTLINE_THICKNESS:
			control.remove_theme_constant_override("outline_size")
#endregion
