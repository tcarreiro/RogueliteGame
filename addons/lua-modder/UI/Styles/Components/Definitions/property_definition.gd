class_name PropertyDefinition extends RefCounted
## Catálogo de props de componente. Os componentes escolhem o que aceitam
## via pick() e só podem sobrescrever o default.

## Props que todo componente aceita sem declarar no schema (ver ComponentRegistry.base_props).
const BASE: Array[StringName] = [
	ID, CLASS, VISIBLE, TOOLTIP, DISABLED,
	FLEX_GROW, ALIGN_SELF, JUSTIFY_SELF, POINTER_EVENTS,
	EFFECTS,
]

const ANY := TYPE_NIL 
const TYPE := &"type"
const DOC := &"doc"
const DEFAULT := &"default"
const OPTIONS := &"options"

#region Functions
const TEXTURE_FN = &"texture"
const URL_FN = &"url"
#endregion

#region Names
const ID := &"id"
const CLASS := &"class"
const VISIBLE := &"visible"
const TOOLTIP := &"tooltip"
const EFFECTS := &"effects"

const MIN := &"min"
const MAX := &"max"
const STEP := &"step"
const SHOW_VALUE := &"show_value"
const TRACK_HEIGHT := &"track_height"
const THUMB_SIZE := &"thumb_size"

const DRAGGABLE := &"draggable"
const DRAG_MODE := &"drag_mode"
const DRAG_HANDLE := &"drag_handle"
const DRAG_BOUNDS := &"drag_bounds"
const DRAG_CURSOR := &"drag_cursor"

const MODEL := &"model"
const CHECKED := &"checked"
const RADIO := &"radio"
const INDICATOR_SIZE := &"indicator_size"
const MARK_INSET := &"mark_inset"
const OPTION_LIST := &"options"   # OPTIONS já é a chave de definição do catálogo
const OPTION_CLASS := &"option_class"
const LIST_CLASS := &"list_class"
const LIST_MAX_HEIGHT := &"list_max_height"
const PLACEHOLDER := &"placeholder"
const CARET := &"caret"
const JUSTIFY_SELF := &"justify_self"
const POINTER_EVENTS := &"pointer_events"

const MARGIN := &"margin"
const MARGIN_LEFT := &"margin_left"
const MARGIN_TOP := &"margin_top"
const MARGIN_RIGHT := &"margin_right"
const MARGIN_BOTTOM := &"margin_bottom"
const PADDING := &"padding"
const PADDING_LEFT := &"padding_left"
const PADDING_TOP := &"padding_top"
const PADDING_RIGHT := &"padding_right"
const PADDING_BOTTOM := &"padding_bottom"

const COLUMNS := &"columns"
const COLUMN_GAP := &"column_gap"
const ROW_GAP := &"row_gap"
const FILL_CELLS := &"fill_cells"

const DISPLAY := &"display"
const ALIGN_ITEMS := &"align_items"
const ALIGN_SELF := &"align_self"

const BACKGROUND_COLOR := &"background_color"
const BORDER_COLOR := &"border_color"
const BORDER_WIDTH := &"border_width"
const BORDER_WIDTH_LEFT := &"border_width_left"
const BORDER_WIDTH_TOP := &"border_width_top"
const BORDER_WIDTH_RIGHT := &"border_width_right"
const BORDER_WIDTH_BOTTOM := &"border_width_bottom"
const BORDER_RADIUS := &"border_radius"
const BORDER_RADIUS_TOP_LEFT := &"border_radius_top_left"
const BORDER_RADIUS_TOP_RIGHT := &"border_radius_top_right"
const BORDER_RADIUS_BOTTOM_RIGHT := &"border_radius_bottom_right"
const BORDER_RADIUS_BOTTOM_LEFT := &"border_radius_bottom_left"

const DROP_SHADOW_COLOR := &"drop_shadow_color"
const DROP_SHADOW_SIZE := &"drop_shadow_size"
const DROP_SHADOW_OFFSET := &"drop_shadow_offset"

const GAP := &"gap"
const WIDTH := &"width"
const HEIGHT := &"height"
const MAX_WIDTH := &"max_width"
const MAX_HEIGHT := &"max_height"

const DIRECTION := &"direction"
const ALIGNMENT := &"alignment"

const FOLLOW_FOCUS := &"follow_focus"
const EDGE_THRESHOLD := &"edge_threshold"
const SCROLLBAR_MODE := &"scrollbar_mode"
const SCROLLBAR_GAP := &"scrollbar_gap"
const SCROLLBAR_WIDTH := &"scrollbar_width"
const SCROLLBAR_BORDER_RADIUS := &"scrollbar_border_radius"
const SCROLLBAR_BORDER_RADIUS_TOP_LEFT := &"scrollbar_border_radius_top_left"
const SCROLLBAR_BORDER_RADIUS_TOP_RIGHT := &"scrollbar_border_radius_top_right"
const SCROLLBAR_BORDER_RADIUS_BOTTOM_RIGHT := &"scrollbar_border_radius_bottom_right"
const SCROLLBAR_BORDER_RADIUS_BOTTOM_LEFT := &"scrollbar_border_radius_bottom_left"
const SCROLLBAR_TRACK_COLOR := &"scrollbar_track_color"
const SCROLLBAR_GRABBER_COLOR := &"scrollbar_grabber_color"
const SCROLLBAR_GRABBER_HOVER_COLOR := &"scrollbar_grabber_hover_color"
const SCROLLBAR_GRABBER_PRESSED_COLOR := &"scrollbar_grabber_pressed_color"
const SCROLL_HINT := &"scroll_hint"
const SCROLL_HINT_TILE := &"scroll_hint_tile"
const SCROLL_HINT_COLOR := &"scroll_hint_color"

const BBCODE_ENABLED := &"bbcode_enabled"
const AUTOWRAP := &"autowrap"
const FIT_CONTENT := &"fit_content"
const SCROLL_ACTIVE := &"scroll_active"
const SCROLL_FOLLOWING := &"scroll_following"
const SELECTION_ENABLED := &"selection_enabled"
const FONT_SHADOW_COLOR := &"font_shadow_color"
const TEXT_ALIGN := &"text_align"
const TEXT_VALIGN := &"text_valign"
const UPPERCASE := &"uppercase"
const TEXT_OVERFLOW := &"text_overflow"
const CLIP_TEXT := &"clip_text"
const MAX_LINES := &"max_lines"
const LINES_SKIPPED := &"lines_skipped"
const VISIBLE_CHARACTERS := &"visible_characters"
const VISIBLE_RATIO := &"visible_ratio"
const AUTO_FONT_SIZE := &"auto_font_size"
const MIN_FONT_SIZE := &"min_font_size"
const MAX_FONT_SIZE := &"max_font_size"
const LINE_SPACING := &"line_spacing"
const PARAGRAPH_SPACING := &"paragraph_spacing"
const TEXT_SHADOW_COLOR := &"text_shadow_color"
const TEXT_SHADOW_OFFSET := &"text_shadow_offset"
const TEXT_SHADOW_OUTLINE := &"text_shadow_outline"
const META_UNDERLINED := &"meta_underlined"
const HINT_UNDERLINED := &"hint_underlined"
const SELECTION_COLOR := &"selection_color"
const SELECTED_FONT_COLOR := &"selected_font_color"
const TAB_SIZE := &"tab_size"
const SCROLL_FOLLOWING_VISIBLE := &"scroll_following_visible_characters"

const FONT_COLOR := &"font_color"
const FONT_SIZE := &"font_size"
const OUTLINE_COLOR := &"outline_color"
const OUTLINE_THICKNESS := &"outline_thickness"

const DISABLED := &"disabled"
const BLOCKING := &"blocking"
const BACKDROP_COLOR := &"backdrop_color"
const TEXT := &"text"
const LABEL := &"label"
const VALUE := &"value"
const INPUT_TYPE := &"type"   # não usar TYPE: já é a chave "type" dos dicts de definição
const DECIMALS := &"decimals"
const THOUSAND_SEPARATOR := &"thousand_separator"
const DECIMAL_SEPARATOR := &"decimal_separator"
const ICON := &"icon"
const ICON_SIDE := &"icon_side"
const CURSOR := &"cursor"

const BACKGROUND_IMAGE := &"background_image"
const BACKGROUND_IMAGE_TINT := &"background_image_tint"
const BACKGROUND_IMAGE_STRETCH := &"background_image_stretch"
const BACKGROUND_IMAGE_SLICE := &"background_image_slice"
const BACKGROUND_IMAGE_SLICE_LEFT := &"background_image_slice_left"
const BACKGROUND_IMAGE_SLICE_TOP := &"background_image_slice_top"
const BACKGROUND_IMAGE_SLICE_RIGHT := &"background_image_slice_right"
const BACKGROUND_IMAGE_SLICE_BOTTOM := &"background_image_slice_bottom"

const ANIMATION_NAME := &"animation_name"
const ANIMATION_DURATION := &"animation_duration"
const ANIMATION_EASING := &"animation_easing"
const ANIMATION_ITERATIONS := &"animation_iterations"
const ANIMATION_DIRECTION := &"animation_direction"
const ANIMATION_DELAY := &"animation_delay"
const ANIMATION_FILL := &"animation_fill"

const TRANSITION_DURATION := &"transition_duration"
const TRANSITION_EASING := &"transition_easing"
const TRANSITION_LOOP := &"transition_loop"
const TRANSITION_REPETITIONS := &"transition_repetitions"
const TRANSITION_PROPERTIES := &"transition_properties"

const SCALE := &"scale"
const ROTATE := &"rotate"
const TRANSLATE := &"translate"
const TRANSFORM_ORIGIN := &"transform_origin"

const TEXTURE := &"texture"
const HFRAMES := &"hframes"
const VFRAMES := &"vframes"
const FRAME_COUNT := &"frame_count"
const FRAME := &"frame"
const FPS := &"fps"
const DURATION := &"duration"
const LOOP := &"loop"
const PLAYING := &"playing"

const EFFECT := &"effect"
const PARAMS := &"params"
const ACTIVE := &"active"
const EMITTING := &"emitting"
const AMOUNT := &"amount"
const LIFETIME := &"lifetime"
const EXPLOSIVENESS := &"explosiveness"
const RANDOMNESS := &"randomness"
const PREWARM := &"prewarm"
const SHAPE := &"shape"
const EMIT_ANGLE := &"emit_angle"
const SPREAD := &"spread"
const SPEED := &"speed"
const GRAVITY := &"gravity"
const PARTICLE_SCALE := &"particle_scale"
const COLOR := &"color"
const COLOR_END := &"color_end"
const BLEND := &"blend"
#endregion

#region Values
const HOLD := &"hold"
const TOGGLE := &"toggle"
const VIEWPORT := &"viewport"

const VERTICAL := &"vertical"
const HORIZONTAL := &"horizontal"
const BOTH := &"both"
const AUTO := &"auto"
const ALWAYS := &"always"
const NEVER := &"never"
const RESERVE := &"reserve"
const GROW := &"grow"
const NONE := &"none"
const ALL := &"all"
const START := &"start"
const END := &"end"
const BLOCK := &"block"
const FLEX := &"flex"
const FLEX_GROW := &"flex_grow"
const NUMBER := &"number"
const SECRET := &"secret"
const LEFT := &"left"
const RIGHT := &"right"
const CENTER := &"center"
const FILL := &"fill"
const TOP := &"top"
const MIDDLE := &"middle"
const BOTTOM := &"bottom"
const CLIP := &"clip"
const ELLIPSIS := &"ellipsis"
const WORD_ELLIPSIS := &"word_ellipsis"
const TRIM := &"trim"

const POINTER := &"pointer"
const CROSSHAIR := &"crosshair"
const WAIT := &"wait"
const BUSY := &"busy"
const MOVE := &"move"
const NOT_ALLOWED := &"not_allowed"
const HELP := &"help"
const DRAG := &"drag"
const CAN_DROP := &"can_drop"

const NORMAL := &"normal"
const ALTERNATE := &"alternate"
const FORWARDS := &"forwards"
const INFINITE := &"infinite"

const STRETCH := &"stretch"
const TILE := &"tile"
const TILE_FIT := &"tile_fit"
const LINEAR := &"linear"
const EASE_IN := &"ease_in"
const EASE_OUT := &"ease_out"
const EASE_IN_OUT := &"ease_in_out"
const BACK := &"back"
const ELASTIC := &"elastic"
const BOUNCE := &"bounce"

const ONE_SHOT := &"one_shot"
const PING_PONG := &"ping_pong"
const POINT := &"point"
const BOX := &"box"
const SPHERE := &"sphere"
const MIX := &"mix"
const ADD := &"add"
const SUBTRACT := &"subtract"
const MULTIPLY := &"multiply"
const PREMULTIPLIED_ALPHA := &"premultiplied_alpha"

const OFF := &"off"
const WORD := &"word"
const WORD_SMART := &"word_smart"
const CHAR := &"char"
#endregion

#region Groups
const BOX_SPACING: Array[StringName] = [
	MARGIN, PADDING
]

const DRAG_GRP: Array[StringName] = [DRAGGABLE, DRAG_MODE, DRAG_HANDLE, DRAG_BOUNDS, DRAG_CURSOR]

const PANEL: Array[StringName] = [
	BACKGROUND_COLOR, BORDER_COLOR, BORDER_WIDTH, BORDER_RADIUS,
	DROP_SHADOW_COLOR, DROP_SHADOW_SIZE, DROP_SHADOW_OFFSET,
	BACKGROUND_IMAGE, BACKGROUND_IMAGE_TINT, BACKGROUND_IMAGE_STRETCH,
	BACKGROUND_IMAGE_SLICE,
]

const ANIMATION: Array[StringName] = [
	ANIMATION_NAME, ANIMATION_DURATION, ANIMATION_EASING, ANIMATION_ITERATIONS,
	ANIMATION_DIRECTION, ANIMATION_DELAY, ANIMATION_FILL,
]

const ANIMATION_DIRECTIONS := [NORMAL, ALTERNATE]

const ANIMATION_FILLS := [NONE, FORWARDS]

const TRANSITION: Array[StringName] = [
	TRANSITION_DURATION, TRANSITION_EASING, TRANSITION_PROPERTIES,
	TRANSITION_LOOP, TRANSITION_REPETITIONS,
]

const TRANSFORM: Array[StringName] = [SCALE, ROTATE, TRANSLATE, TRANSFORM_ORIGIN]

const SCROLLBAR: Array[StringName] = [
	SCROLLBAR_WIDTH, SCROLLBAR_GAP, SCROLLBAR_BORDER_RADIUS, SCROLLBAR_TRACK_COLOR,
	SCROLLBAR_GRABBER_COLOR, SCROLLBAR_GRABBER_HOVER_COLOR,
	SCROLLBAR_GRABBER_PRESSED_COLOR, SCROLL_HINT_COLOR,
]

const FONT: Array[StringName] = [
	FONT_COLOR, FONT_SIZE, OUTLINE_COLOR, OUTLINE_THICKNESS,
]

const TEXT_SHADOW: Array[StringName] = [TEXT_SHADOW_COLOR, TEXT_SHADOW_OFFSET, TEXT_SHADOW_OUTLINE]
const TEXT_LAYOUT: Array[StringName] = [
	TEXT_ALIGN, TEXT_VALIGN, AUTOWRAP, LINE_SPACING, PARAGRAPH_SPACING,
	AUTO_FONT_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, VISIBLE_CHARACTERS, VISIBLE_RATIO,
]
const LABEL_ONLY: Array[StringName] = [UPPERCASE, TEXT_OVERFLOW, CLIP_TEXT, MAX_LINES, LINES_SKIPPED]
const RICH_ONLY: Array[StringName] = [
	BBCODE_ENABLED, FIT_CONTENT, SCROLL_ACTIVE, SCROLL_FOLLOWING, SCROLL_FOLLOWING_VISIBLE,
	SELECTION_ENABLED, META_UNDERLINED, HINT_UNDERLINED, SELECTION_COLOR, SELECTED_FONT_COLOR, TAB_SIZE,
]

#endregion

#region Families
const FAMILIES := {
	MARGIN: [
		MARGIN_LEFT, MARGIN_TOP, MARGIN_RIGHT, MARGIN_BOTTOM
	],
	PADDING: [
		PADDING_LEFT, PADDING_TOP, PADDING_RIGHT, PADDING_BOTTOM
	],
	BORDER_WIDTH: [
		BORDER_WIDTH_LEFT, BORDER_WIDTH_TOP, BORDER_WIDTH_RIGHT, BORDER_WIDTH_BOTTOM
	],
	BORDER_RADIUS: [
		BORDER_RADIUS_TOP_LEFT, BORDER_RADIUS_TOP_RIGHT,
		BORDER_RADIUS_BOTTOM_RIGHT, BORDER_RADIUS_BOTTOM_LEFT
	],
	SCROLLBAR_BORDER_RADIUS: [
		SCROLLBAR_BORDER_RADIUS_TOP_LEFT, SCROLLBAR_BORDER_RADIUS_TOP_RIGHT,
		SCROLLBAR_BORDER_RADIUS_BOTTOM_RIGHT, SCROLLBAR_BORDER_RADIUS_BOTTOM_LEFT
	],
	BACKGROUND_IMAGE_SLICE: [
		BACKGROUND_IMAGE_SLICE_LEFT, BACKGROUND_IMAGE_SLICE_TOP,
		BACKGROUND_IMAGE_SLICE_RIGHT, BACKGROUND_IMAGE_SLICE_BOTTOM
	],
}


static var _family_index: Dictionary = {}

static func members_of(family: StringName) -> Array:
	return FAMILIES.get(family, [])


static func family_of(name: StringName) -> StringName:
	if _family_index.is_empty():
		for family: StringName in FAMILIES:
			_family_index[family] = family
			for member: StringName in FAMILIES[family]:
				_family_index[member] = family
	return _family_index.get(name, &"")


static func expand(names: Array) -> Array:
	var out: Array = []
	for n in names:
		var sn := StringName(n)
		out.append(sn)
		if FAMILIES.has(sn):
			out.append_array(FAMILIES[sn])
	return out


static func _defined(v: Variant) -> bool:
	if v == null:
		return false
	if (v is Array or v is Dictionary) and v.is_empty():
		return false
	return true


## Um valor por parte (null = ninguém definiu).
## `layers`: lookups da MAIOR para a MENOR prioridade; cada um recebe o nome da prop
## e devolve o valor ou null. Dentro de cada camada, a parte vence o atalho.
static func resolve_family(family: StringName, layers: Array[Callable]) -> Array:
	var members: Array = members_of(family)
	var out: Array = []
	out.resize(members.size())
	for layer: Callable in layers:
		var shorthand: Variant = layer.call(family)
		var distributed: Array = LuaHelper.parse_distributable(shorthand) if _defined(shorthand) else []
		for i in members.size():
			if out[i] != null:
				continue
			var specific: Variant = layer.call(members[i])
			if _defined(specific):
				out[i] = LuaHelper.parse_distributable(specific)[0]
			elif not distributed.is_empty():
				out[i] = distributed[i]
	return out
#endregion

#region Options
const DIRECTIONS := [
	VERTICAL, HORIZONTAL, BOTH
]

const ALIGNMENTS := {
	CENTER: BoxContainer.AlignmentMode.ALIGNMENT_CENTER,
	START: BoxContainer.AlignmentMode.ALIGNMENT_BEGIN, 
	END: BoxContainer.AlignmentMode.ALIGNMENT_END,
}

const CROSS_ALIGNS := {
	STRETCH: Control.SIZE_FILL,
	START: Control.SIZE_SHRINK_BEGIN,
	CENTER: Control.SIZE_SHRINK_CENTER,
	END: Control.SIZE_SHRINK_END,
}

const DRAG_MODES := [HOLD, TOGGLE]

const DRAG_BOUNDS_OPTIONS := [VIEWPORT, NONE]

const DISPLAYS := [
	BLOCK, FLEX,
]

const SCROLL_MODES := {
	AUTO: ScrollContainer.SCROLL_MODE_AUTO,
	ALWAYS: ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,
	NEVER: ScrollContainer.SCROLL_MODE_SHOW_NEVER,
	RESERVE: ScrollContainer.SCROLL_MODE_RESERVE,
	GROW: ScrollContainer.SCROLL_MODE_MAXIMIZE_FIRST,
}

const HINT_MODES := {
	NONE: ScrollContainer.SCROLL_HINT_MODE_DISABLED,
	ALL: ScrollContainer.SCROLL_HINT_MODE_ALL,
	START: ScrollContainer.SCROLL_HINT_MODE_TOP_AND_LEFT,
	END: ScrollContainer.SCROLL_HINT_MODE_BOTTOM_AND_RIGHT,
}

const INPUT_TYPES := [TEXT, NUMBER, SECRET]
const ICON_SIDES := [LEFT, RIGHT]

const CURSORS := {
	DEFAULT: Control.CURSOR_ARROW,
	TEXT: Control.CURSOR_IBEAM,
	POINTER: Control.CURSOR_POINTING_HAND,
	CROSSHAIR: Control.CURSOR_CROSS,
	WAIT: Control.CURSOR_WAIT,
	BUSY: Control.CURSOR_BUSY,
	MOVE: Control.CURSOR_MOVE,
	NOT_ALLOWED: Control.CURSOR_FORBIDDEN,
	HELP: Control.CURSOR_HELP,
	DRAG: Control.CURSOR_DRAG,
	CAN_DROP: Control.CURSOR_CAN_DROP,
}

const STRETCH_MODES := {
	STRETCH: StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH,
	TILE: StyleBoxTexture.AXIS_STRETCH_MODE_TILE,
	TILE_FIT: StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT,
}

const EASINGS := {
	LINEAR: [Tween.TRANS_LINEAR, Tween.EASE_IN_OUT],
	EASE_IN: [Tween.TRANS_QUAD, Tween.EASE_IN],
	EASE_OUT: [Tween.TRANS_QUAD, Tween.EASE_OUT],
	EASE_IN_OUT: [Tween.TRANS_QUAD, Tween.EASE_IN_OUT],
	BACK: [Tween.TRANS_BACK, Tween.EASE_OUT],
	ELASTIC: [Tween.TRANS_ELASTIC, Tween.EASE_OUT],
	BOUNCE: [Tween.TRANS_BOUNCE, Tween.EASE_OUT],
}

const LOOP_OPTIONS := [
	LOOP, PING_PONG, ONE_SHOT,
]

const AUTOWRAP_MODES := {
	OFF: TextServer.AUTOWRAP_OFF,
	WORD: TextServer.AUTOWRAP_WORD,
	WORD_SMART: TextServer.AUTOWRAP_WORD_SMART,
	CHAR: TextServer.AUTOWRAP_ARBITRARY,
}


const H_ALIGNS := {
	LEFT: HORIZONTAL_ALIGNMENT_LEFT, CENTER: HORIZONTAL_ALIGNMENT_CENTER,
	RIGHT: HORIZONTAL_ALIGNMENT_RIGHT, FILL: HORIZONTAL_ALIGNMENT_FILL,
}


const V_ALIGNS := {
	TOP: VERTICAL_ALIGNMENT_TOP, MIDDLE: VERTICAL_ALIGNMENT_CENTER,
	BOTTOM: VERTICAL_ALIGNMENT_BOTTOM, FILL: VERTICAL_ALIGNMENT_FILL,
}


const TEXT_OVERFLOWS := {
	NONE: TextServer.OVERRUN_NO_TRIMMING, CLIP: TextServer.OVERRUN_TRIM_CHAR,
	WORD: TextServer.OVERRUN_TRIM_WORD, ELLIPSIS: TextServer.OVERRUN_TRIM_ELLIPSIS,
	WORD_ELLIPSIS: TextServer.OVERRUN_TRIM_WORD_ELLIPSIS,
}

const EMIT_SHAPES := {
	POINT: CPUParticles2D.EMISSION_SHAPE_POINT,
	BOX: CPUParticles2D.EMISSION_SHAPE_RECTANGLE,
	SPHERE: CPUParticles2D.EMISSION_SHAPE_SPHERE,
}
const BLENDS := [MIX, ADD, SUBTRACT, MULTIPLY, PREMULTIPLIED_ALPHA]
#endregion

static var _cache: Dictionary = {}


static func type_of(name: StringName) -> int:
	return _catalog().get(String(name), {}).get(TYPE, TYPE_NIL)


## Ex.: pick([GAP, DIRECTION], {GAP: 4})
static func pick(names: Array, defaults: Dictionary = {}, prefix: String = "") -> Dictionary:
	var all := _catalog()
	var overrides := {}
	for d in defaults:
		overrides[String(d)] = defaults[d]

	var out := {}
	for n in expand(names):
		var key := String(n)
		if not all.has(key):
			push_warning("[PropertyDefinition] prop desconhecida: '%s'" % key)
			continue
		var def: Dictionary = all[key].duplicate(true)
		if overrides.has(key):
			def[DEFAULT] = overrides[key]
		out[prefix + key] = def

	for key in overrides:
		if not out.has(prefix + key):
			push_warning("[PropertyDefinition] default para prop que não está no pick: '%s'" % key)
	return out


static func _add(c: Dictionary, name: StringName, type: int, default: Variant,
		doc: String = "", options: Array = []) -> void:
	var def := {TYPE: type, DEFAULT: default, DOC: doc}
	if not options.is_empty():
		def[OPTIONS] = options
	c[String(name)] = def


static func _catalog() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var c := _cache

	# 
	_add(c, ID, TYPE_STRING, "", "Identificador do componente")
	_add(c, CLASS, TYPE_STRING, "", "Lista de classes de estilo")
	_add(c, VISIBLE, TYPE_BOOL, true, "Visibilidade do componente")
	_add(c, TOOLTIP, TYPE_STRING, "", "Tooltip do componente") # To be implemented 
	_add(c, FLEX_GROW, TYPE_FLOAT, 0.0, "Parte do espaço livre do container que o componente ocupa. 0 = só o tamanho do conteúdo; valores diferentes dividem o espaço na proporção entre eles.")

	_add(c, EFFECTS, ANY, null, "Efeitos de cor sobre o componente e tudo dentro dele, em ordem: nomes ou { effect = 'nome', param = valor }.")

	_add(c, MIN, TYPE_FLOAT, 0.0, "Menor valor.")
	_add(c, MAX, TYPE_FLOAT, 100.0, "Maior valor.")
	_add(c, STEP, TYPE_FLOAT, 1.0, "Passo entre valores (0 = contínuo).")
	_add(c, SHOW_VALUE, TYPE_BOOL, false, "Mostra o valor atual ao lado da barra.")
	_add(c, TRACK_HEIGHT, TYPE_INT, 6, "Espessura da barra em px.")
	_add(c, THUMB_SIZE, ANY, 20, "Tamanho do marcador em px: número ou {largura, altura}.")
	
	_add(c, DRAGGABLE, TYPE_BOOL, false, "Permite arrastar o componente com o mouse.")
	_add(c, DRAG_MODE, TYPE_STRING, "hold", "hold: arrasta com o botão pressionado. toggle: clica para pegar e clica de novo para soltar.", DRAG_MODES)
	_add(c, DRAG_HANDLE, TYPE_BOOL, false, "Marca este componente como a região de arraste do ancestral com draggable. Sem nenhum handle, o ancestral inteiro é a região.")
	_add(c, DRAG_BOUNDS, TYPE_STRING, "viewport", "viewport mantém o cursor dentro da tela durante o arraste; none não limita.", DRAG_BOUNDS_OPTIONS)
	_add(c, DRAG_CURSOR, TYPE_STRING, "move", "Cursor sobre a região de arraste enquanto draggable estiver ligado.", CURSORS.keys())

	_add(c, MARGIN, ANY, null, "Margem externa: número, {h, v} ou {esq, topo, dir, base}.")
	_add(c, MARGIN_LEFT, ANY, null, "Margem esquerda.")
	_add(c, MARGIN_TOP, ANY, null, "Margem superior.")
	_add(c, MARGIN_RIGHT, ANY, null, "Margem direita.")
	_add(c, MARGIN_BOTTOM, ANY, null, "Margem inferior.")
	_add(c, PADDING, ANY, null, "Espaço interno: número, {h, v} ou {esq, topo, dir, base}.")
	_add(c, PADDING_LEFT, ANY, null, "Espaço interno esquerdo.")
	_add(c, PADDING_TOP, ANY, null, "Espaço interno superior.")
	_add(c, PADDING_RIGHT, ANY, null, "Espaço interno direito.")
	_add(c, PADDING_BOTTOM, ANY, null, "Espaço interno inferior.")

	_add(c, COLUMNS, TYPE_INT, 2, "Número de colunas.")
	_add(c, COLUMN_GAP, TYPE_INT, null, "Espaço entre colunas. Sem valor, usa gap.")
	_add(c, ROW_GAP, TYPE_INT, null, "Espaço entre linhas. Sem valor, usa gap.")
	_add(c, FILL_CELLS, TYPE_BOOL, true, "Os filhos preenchem a célula. false = só o tamanho do conteúdo.")

	_add(c, DISPLAY, TYPE_STRING, "block", "Layout do container. {block} stacka verticalmente, {flex} stacka horizontalmente.", DISPLAYS)
	_add(c, DISABLED, TYPE_BOOL, false, "Desabilita a interação e ativa o estado :disabled.")
	_add(c, BLOCKING, TYPE_BOOL, true, "Se true, o backdrop bloqueia cliques no que está atrás.")
	_add(c, BACKDROP_COLOR, TYPE_COLOR, null, "Cor do fundo atrás do modal.")
	_add(c, TEXT, TYPE_STRING, "", "Texto exibido.")
	_add(c, LABEL, TYPE_STRING, "", "Texto do botão ou rótulo do campo.")
	_add(c, VALUE, TYPE_STRING, "", "Valor atual do campo.")
	_add(c, INPUT_TYPE, TYPE_STRING, "text", "Tipo de entrada.", INPUT_TYPES)
	_add(c, DECIMALS, TYPE_INT, 0, "Casas decimais (só type number).")
	_add(c, THOUSAND_SEPARATOR, TYPE_STRING, ".", "Separador de milhar (só type number).")
	_add(c, DECIMAL_SEPARATOR, TYPE_STRING, ",", "Separador decimal (só type number).")
	_add(c, ICON, TYPE_STRING, "", "Caminho da textura do ícone.")
	_add(c, ICON_SIDE, TYPE_STRING, "left", "Lado do ícone.", ICON_SIDES)
	_add(c, CURSOR, TYPE_STRING, "default", "Cursor do mouse sobre o componente.", CURSORS.keys())

	_add(c, BACKGROUND_COLOR, TYPE_COLOR, null, "Cor de fundo.")
	_add(c, BORDER_COLOR, TYPE_COLOR, null, "Cor da borda.")
	_add(c, BORDER_WIDTH, ANY, null, "Espessura da borda em px.")
	_add(c, BORDER_WIDTH_LEFT, ANY, null, "Espessura da borda esquerda.")
	_add(c, BORDER_WIDTH_TOP, ANY, null, "Espessura da borda superior.")
	_add(c, BORDER_WIDTH_RIGHT, ANY, null, "Espessura da borda direita.")
	_add(c, BORDER_WIDTH_BOTTOM, ANY, null, "Espessura da borda inferior.")
	_add(c, BORDER_RADIUS, ANY, null, "Raio dos cantos em px.")
	_add(c, BORDER_RADIUS_TOP_LEFT, ANY, null, "Raio do canto superior esquerdo.")
	_add(c, BORDER_RADIUS_TOP_RIGHT, ANY, null, "Raio do canto superior direito.")
	_add(c, BORDER_RADIUS_BOTTOM_RIGHT, ANY, null, "Raio do canto inferior direito.")
	_add(c, BORDER_RADIUS_BOTTOM_LEFT, ANY, null, "Raio do canto inferior esquerdo.")
	_add(c, DROP_SHADOW_COLOR, TYPE_COLOR, null, "Cor da sombra.")
	_add(c, DROP_SHADOW_SIZE, TYPE_INT, null, "Tamanho (blur) da sombra em px.")
	_add(c, DROP_SHADOW_OFFSET, ANY, null, "Deslocamento da sombra: número ou {x, y}.")

	_add(c, GAP, TYPE_INT, 0, "Espaço entre os filhos em px.")
	_add(c, WIDTH, TYPE_INT, -1, "Largura mínima em px (-1 = não definida).")
	_add(c, HEIGHT, TYPE_INT, -1, "Altura mínima em px (-1 = não definida).")
	_add(c, MAX_WIDTH, TYPE_INT, -1, "Largura máxima em px (-1 = sem limite).")
	_add(c, MAX_HEIGHT, TYPE_INT, -1, "Altura máxima em px (-1 = sem limite).")

	_add(c, DIRECTION, TYPE_STRING, "vertical", "Eixos de rolagem.", DIRECTIONS)
	_add(c, ALIGNMENT, TYPE_STRING, null, "Alinhamento dos filhos no eixo principal (vertical em block, horizontal em flex).", ALIGNMENTS.keys())
	_add(c, ALIGN_ITEMS, TYPE_STRING, "stretch", "Alinhamento dos filhos no eixo cruzado (horizontal em block, vertical em flex). stretch estica.", CROSS_ALIGNS.keys())
	_add(c, ALIGN_SELF, TYPE_STRING, "auto", "Em block/flex: alinhamento no eixo cruzado. Em um Stack: alinhamento vertical. Sobrescreve o align_items do container.", [AUTO, STRETCH, START, CENTER, END])
	_add(c, JUSTIFY_SELF, TYPE_STRING, "auto", "Alinhamento horizontal em um Stack.", [AUTO, STRETCH, START, CENTER, END])
	_add(c, POINTER_EVENTS, TYPE_STRING, "auto", "none: o componente e tudo dentro dele ignoram o mouse, e os cliques passam para o que está atrás.", [AUTO, NONE])
	
	_add(c, MODEL, ANY, null, "Liga o valor a uma entrada de store: model = handle.model('chave'). Lê, atualiza sozinho e grava o que o usuário muda.")
	_add(c, CHECKED, TYPE_BOOL, false, "Marcado.")
	_add(c, RADIO, TYPE_BOOL, false, "Age como opção de rádio: o usuário só marca, nunca desmarca.")
	_add(c, INDICATOR_SIZE, TYPE_INT, 20, "Lado do quadrado do indicador, em px.")
	_add(c, MARK_INSET, TYPE_INT, 4, "Distância entre a borda do indicador e a marca, em px.")
	_add(c, OPTION_LIST, ANY, null, "Opções: lista de textos ou de { value, label, disabled }.")
	_add(c, OPTION_CLASS, TYPE_STRING, "", "Classe de estilo de cada opção.")
	_add(c, LIST_CLASS, TYPE_STRING, "", "Classe da lista aberta do dropdown.")
	_add(c, LIST_MAX_HEIGHT, TYPE_INT, 240, "Altura máxima da lista aberta, em px.")
	_add(c, PLACEHOLDER, TYPE_STRING, "", "Texto mostrado quando nenhuma opção está selecionada.")
	_add(c, CARET, TYPE_STRING, "▾", "Texto do indicador de abertura.")
	
	_add(c, FOLLOW_FOCUS, TYPE_BOOL, true, "Rola até o filho focado.")
	_add(c, EDGE_THRESHOLD, TYPE_INT, 0, "Folga em px para os eventos de início/fim.")
	_add(c, SCROLLBAR_MODE, TYPE_STRING, "auto", "Visibilidade da barra e crescimento.", SCROLL_MODES.keys())
	_add(c, SCROLLBAR_GAP, ANY, null, "Espaço entre conteúdo e barras: {barra vertical, barra horizontal}.")
	_add(c, SCROLLBAR_WIDTH, ANY, null, "Espessura da barra em px.")
	_add(c, SCROLLBAR_BORDER_RADIUS, ANY, null, "Raio dos cantos da barra e do grabber.")
	_add(c, SCROLLBAR_BORDER_RADIUS_TOP_LEFT, ANY, null, "Raio do canto superior esquerdo da barra e do grabber.")
	_add(c, SCROLLBAR_BORDER_RADIUS_TOP_RIGHT, ANY, null, "Raio dos canto superior direito da barra e do grabber.")
	_add(c, SCROLLBAR_BORDER_RADIUS_BOTTOM_LEFT, ANY, null, "Raio dos canto inferior esquerdo da barra e do grabber.")
	_add(c, SCROLLBAR_BORDER_RADIUS_BOTTOM_RIGHT, ANY, null, "Raio dos canto inferior direito da barra e do grabber.")
	
	_add(c, SCROLLBAR_TRACK_COLOR, TYPE_COLOR, null, "Cor do trilho.")
	_add(c, SCROLLBAR_GRABBER_COLOR, TYPE_COLOR, null, "Cor do grabber em repouso.")
	_add(c, SCROLLBAR_GRABBER_HOVER_COLOR, TYPE_COLOR, null, "Cor do grabber sob o mouse.")
	_add(c, SCROLLBAR_GRABBER_PRESSED_COLOR, TYPE_COLOR, null, "Cor do grabber pressionado.")
	_add(c, SCROLL_HINT, TYPE_STRING, "none", "Onde mostrar os indicadores de rolagem.", HINT_MODES.keys())
	_add(c, SCROLL_HINT_TILE, TYPE_BOOL, false, "Repete a textura do indicador em vez de esticá-la.")
	_add(c, SCROLL_HINT_COLOR, TYPE_COLOR, null, "Cor dos indicadores de rolagem.")
	
	_add(c, BBCODE_ENABLED, TYPE_BOOL, true, "Interpreta BBCode no texto.")
	_add(c, AUTOWRAP, TYPE_STRING, WORD_SMART, "Quebra de linha.", AUTOWRAP_MODES.keys())
	_add(c, FIT_CONTENT, TYPE_BOOL, true, "O tamanho mínimo acompanha o conteúdo.")
	_add(c, SCROLL_ACTIVE, TYPE_BOOL, true, "Mostra barra de rolagem quando o texto excede a altura.")
	_add(c, SCROLL_FOLLOWING, TYPE_BOOL, false, "Rola sozinho para o fim ao acrescentar texto (log, chat).")
	_add(c, SELECTION_ENABLED, TYPE_BOOL, false, "Permite selecionar o texto com o mouse.")
	
	_add(c, TEXT_ALIGN, TYPE_STRING, "left", "Alinhamento horizontal do texto.", H_ALIGNS.keys())
	_add(c, TEXT_VALIGN, TYPE_STRING, "top", "Alinhamento vertical do texto.", V_ALIGNS.keys())
	_add(c, UPPERCASE, TYPE_BOOL, false, "Mostra todo o texto em maiúsculas.")
	_add(c, TEXT_OVERFLOW, TYPE_STRING, "none", "O que fazer com texto que não cabe.", TEXT_OVERFLOWS.keys())
	_add(c, CLIP_TEXT, TYPE_BOOL, false, "Corta o texto horizontalmente ao limite do componente.")
	_add(c, MAX_LINES, TYPE_INT, -1, "Limita as linhas visíveis (-1 = sem limite).")
	_add(c, LINES_SKIPPED, TYPE_INT, 0, "Linhas ignoradas a partir do início.")
	_add(c, VISIBLE_CHARACTERS, TYPE_INT, -1, "Quantos caracteres mostrar (-1 = todos). Útil em máquina de escrever.")
	_add(c, VISIBLE_RATIO, TYPE_FLOAT, null, "Fração do texto mostrada, de 0 a 1.")
	_add(c, AUTO_FONT_SIZE, TYPE_BOOL, false, "Encolhe ou cresce a fonte para caber no espaço.")
	_add(c, MIN_FONT_SIZE, TYPE_INT, null, "Menor fonte usada com auto_font_size.")
	_add(c, MAX_FONT_SIZE, TYPE_INT, null, "Maior fonte usada com auto_font_size.")
	_add(c, LINE_SPACING, TYPE_INT, null, "Espaço extra entre linhas em px (pode ser negativo).")
	_add(c, PARAGRAPH_SPACING, TYPE_INT, null, "Espaço extra entre parágrafos em px.")
	_add(c, TEXT_SHADOW_COLOR, TYPE_COLOR, null, "Cor da sombra do texto.")
	_add(c, TEXT_SHADOW_OFFSET, ANY, null, "Deslocamento da sombra do texto: número ou {x, y}.")
	_add(c, TEXT_SHADOW_OUTLINE, TYPE_INT, null, "Espessura do contorno da sombra.")
	_add(c, META_UNDERLINED, TYPE_BOOL, true, "Sublinha links [url].")
	_add(c, HINT_UNDERLINED, TYPE_BOOL, true, "Sublinha dicas [hint].")
	_add(c, SELECTION_COLOR, TYPE_COLOR, null, "Cor da caixa de seleção do texto.")
	_add(c, SELECTED_FONT_COLOR, TYPE_COLOR, null, "Cor do texto selecionado.")
	_add(c, TAB_SIZE, TYPE_INT, 4, "Espaços por tabulação.")
	_add(c, SCROLL_FOLLOWING_VISIBLE, TYPE_BOOL, false, "Rola até a última linha visível ao mudar visible_characters.")

	_add(c, FONT_SIZE, TYPE_INT, null, "Tamanho da fonte.")
	_add(c, FONT_COLOR, TYPE_COLOR, null, "Cor da fonte.")
	_add(c, OUTLINE_THICKNESS, TYPE_INT, null, "Espessura do outline da fonte.")
	_add(c, OUTLINE_COLOR, TYPE_COLOR, null, "Cor do outline da fonte.")

	_add(c, BACKGROUND_IMAGE, TYPE_STRING, null, "Imagem de fundo (9-slice). No .lcss: texture(\"res://...\"). Com imagem ativa, background_color, border_* e drop_shadow_* são ignorados.")
	_add(c, BACKGROUND_IMAGE_TINT, TYPE_COLOR, null, "Cor que multiplica a imagem de fundo.")
	_add(c, BACKGROUND_IMAGE_STRETCH, TYPE_STRING, null, "Como a imagem preenche as áreas esticáveis.", STRETCH_MODES.keys())
	_add(c, BACKGROUND_IMAGE_SLICE, ANY, null, "Margens do 9-slice em px: número, {h, v} ou {esq, topo, dir, base}.")
	_add(c, BACKGROUND_IMAGE_SLICE_LEFT, ANY, null, "Margem esquerda do 9-slice.")
	_add(c, BACKGROUND_IMAGE_SLICE_TOP, ANY, null, "Margem superior do 9-slice.")
	_add(c, BACKGROUND_IMAGE_SLICE_RIGHT, ANY, null, "Margem direita do 9-slice.")
	_add(c, BACKGROUND_IMAGE_SLICE_BOTTOM, ANY, null, "Margem inferior do 9-slice.")

	_add(c, ANIMATION_NAME, TYPE_STRING, null, "Nome de um @keyframes do .lcss. Vazio = sem animação.")
	_add(c, ANIMATION_DURATION, TYPE_FLOAT, null, "Duração de um ciclo, em segundos.")
	_add(c, ANIMATION_EASING, TYPE_STRING, null, "Curva entre os quadros (padrão: ease_in_out).", EASINGS.keys())
	_add(c, ANIMATION_ITERATIONS, ANY, null, "Repetições: número ou infinite (padrão: 1).")
	_add(c, ANIMATION_DIRECTION, TYPE_STRING, null, "normal ou alternate (ida e volta).", ANIMATION_DIRECTIONS)
	_add(c, ANIMATION_DELAY, TYPE_FLOAT, null, "Espera antes de começar, em segundos.")
	_add(c, ANIMATION_FILL, TYPE_STRING, null, "forwards mantém o último quadro ao terminar.", ANIMATION_FILLS)

	_add(c, TRANSITION_DURATION, TYPE_FLOAT, null, "Segundos de animação quando uma propriedade de estilo muda. Ausente ou 0 = sem animação.")
	_add(c, TRANSITION_EASING, TYPE_STRING, null, "Curva da animação (padrão: ease_out).", EASINGS.keys())
	_add(c, TRANSITION_LOOP, TYPE_STRING, null, "Configuração de loop da animação (one_shot, ping_pong, loop)", LOOP_OPTIONS)
	_add(c, TRANSITION_REPETITIONS, TYPE_INT, null, "Número de repetições de loop da animação (padrão = -1, infinito)")
	_add(c, TRANSITION_PROPERTIES, ANY, null, "Quais propriedades animam: all (padrão) ou uma lista de nomes.")

	_add(c, SCALE, ANY, null, "Escala visual: número ou {x, y}. Não altera o layout.")
	_add(c, ROTATE, TYPE_FLOAT, null, "Rotação visual em graus. Não altera o layout.")
	_add(c, TRANSLATE, ANY, null, "Deslocamento visual em px: {x, y}. Não altera o layout.")
	_add(c, TRANSFORM_ORIGIN, ANY, null, "Ponto fixo da transformação, de 0 a 1: {x, y}. Padrão: {0.5, 0.5}.")

	_add(c, TEXTURE, TYPE_STRING, "", "Caminho da imagem (sprite sheet).")
	_add(c, HFRAMES, TYPE_INT, 1, "Colunas da sheet.")
	_add(c, VFRAMES, TYPE_INT, 1, "Linhas da sheet.")
	_add(c, FRAME_COUNT, TYPE_INT, 0, "Quadros usados (0 = todos). Útil quando a última linha está incompleta.")
	_add(c, FRAME, TYPE_INT, 0, "Quadro inicial.")
	_add(c, FPS, TYPE_FLOAT, 12.0, "Quadros por segundo.")
	_add(c, DURATION, TYPE_FLOAT, 0.0, "Duração do ciclo completo em segundos. Se maior que 0, vence o fps.")
	_add(c, LOOP, TYPE_BOOL, true, "Repete a animação.")
	_add(c, PLAYING, TYPE_BOOL, true, "Toca automaticamente.")
	
	_add(c, EFFECT, TYPE_STRING, "tint", "Efeito de tela pré-definido.", LuaShaderLibrary.names())
	_add(c, PARAMS, ANY, null, "Parâmetros do efeito: { nome = valor }.")
	_add(c, ACTIVE, TYPE_BOOL, true, "Liga ou desliga o efeito.")

	_add(c, EMITTING, TYPE_BOOL, true, "Emite partículas.")
	_add(c, AMOUNT, TYPE_INT, 32, "Partículas vivas ao mesmo tempo.")
	_add(c, LIFETIME, TYPE_FLOAT, 1.5, "Vida de cada partícula, em segundos.")
	_add(c, ONE_SHOT, TYPE_BOOL, false, "Emite uma vez só. Use restart() para repetir.")
	_add(c, EXPLOSIVENESS, TYPE_FLOAT, 0.0, "0 = emissão contínua; 1 = todas de uma vez.")
	_add(c, RANDOMNESS, TYPE_FLOAT, 0.0, "Aleatoriedade do início de cada partícula, de 0 a 1.")
	_add(c, PREWARM, TYPE_FLOAT, 0.0, "Segundos simulados antes de aparecer (efeitos de ambiente).")
	_add(c, SHAPE, TYPE_STRING, "box", "Onde nascem: point (centro), box (todo o retângulo) ou sphere.", EMIT_SHAPES.keys())
	_add(c, EMIT_ANGLE, TYPE_FLOAT, -90.0, "Direção da emissão em graus (0 = direita, -90 = cima).")
	_add(c, SPREAD, TYPE_FLOAT, 25.0, "Abertura do cone de emissão, em graus.")
	_add(c, SPEED, ANY, null, "Velocidade inicial em px/s: número ou {min, max}. Padrão: {20, 60}.")
	_add(c, GRAVITY, ANY, null, "Aceleração em px/s²: número (vertical) ou {x, y}.")
	_add(c, PARTICLE_SCALE, ANY, null, "Escala da partícula: número ou {min, max}.")
	_add(c, COLOR, TYPE_COLOR, null, "Cor inicial. Padrão: branco.")
	_add(c, COLOR_END, TYPE_COLOR, null, "Cor final. Padrão: a inicial, transparente.")
	_add(c, BLEND, TYPE_STRING, "mix", "mix, add (brilho aditivo), multiply, subtract ou premultiplied_alpha.", BLENDS)
	_add(c, CLIP, TYPE_BOOL, false, "Corta as partículas que saem do retângulo.")
	
	return c
