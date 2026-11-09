extends LuaComponent
## Hotkey: ouve uma tecla (fixa ou configurável) e dispara on_press / on_release. Não desenha nada.
##
##   Hotkey{ key = "R", on_press = function() print("R!") end }                    -- tecla fixa
##   Hotkey{ action = "toggle_inventory", on_press = function() ... end }          -- tecla vinda da store "controls"
##   Hotkey{ action = "close", bindings = "controls", on_press = function() ... end }
##
## Props:
##   key       "R", "Escape", "Ctrl+R", "Shift+Tab", "F5", "Space"...   (qualquer texto que OS.find_keycode_from_string entende)
##   action    nome de uma ação. A tecla vem de UI.store(bindings)[action]: um texto ("R") ou uma lista ({"R", "Enter"}).
##             É lida a CADA tecla apertada, então regravar a store (tela de controles) vale na hora.
##   bindings  nome da store com as teclas. Padrão "controls".
##   repeating true = dispara também no auto-repeat de segurar a tecla. Padrão false. (Não se chama `repeat`: é palavra reservada do Lua.)
##   consume   true = o evento não chega a mais ninguém (outro Hotkey, o jogo). Padrão true.
##   visible   false = desligado.
## Eventos: on_press(), on_release()  (o release só vem se o press anterior foi seu)
##
## Regras:
##  - Os modificadores têm de bater exatamente: "R" não dispara com Ctrl+R; "Ctrl+R" não dispara só com R.
##  - Só dispara se o Hotkey está visível na árvore (o pai e os ancestrais): um Hotkey dentro de um modal fechado
##    ou de um painel com visible = false não responde, como um botão não responderia.
##  - Digitar num campo de texto (LineEdit...) consome a tecla antes: o Hotkey nunca a vê.
##  - Vários Hotkey para a mesma tecla: o último da árvore recebe primeiro e, com consume, para ali (pilha natural:
##    um Hotkey de um modal aberto ganha do da tela de baixo).

var _enabled := true
var _pressed := false          # recebemos o press e ainda não o release
var _keycodes: Dictionary = {} # texto -> código, para não reparsear a cada tecla
var _action_bindings: Array = []
var _warned: Dictionary = {}   # textos inválidos já avisados


func get_schema() -> Dictionary:
	return {
		"name": "Hotkey",
		"props": {
			"key": {"type": "string", "default": ""},
			"action": {"type": "string", "default": ""},
			"bindings": {"type": "string", "default": "controls"},
			"repeating": {"type": "bool", "default": false},
			"consume": {"type": "bool", "default": true},
		},
		"events": ["press", "release"],
		"slots": {},
	}


func _ready() -> void:
	# não ocupa espaço em containers (um Control escondido é ignorado por eles) e nunca pega o mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_bound_actions()
	super._ready()


## `visible` aqui significa "ligado/desligado", não "desenhado": o nó fica sempre escondido.
func _apply_prop_internal(key: String, value: Variant) -> void:
	if StringName(key) == PropertyDefinition.VISIBLE:
		_enabled = bool(value)
		return
	super._apply_prop_internal(key, value)


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not _is_active():
		return
	if key_event.echo and not bool(props.get("repeating", false)):
		return

	if key_event.pressed:
		if not _matches_press(key_event):
			return
		_pressed = true
		emit_event("press")
	else:
		if not _pressed or not _matches_release(key_event):
			return
		_pressed = false
		emit_event("release")

	if bool(props.get("consume", true)):
		get_viewport().set_input_as_handled()


func _is_active() -> bool:
	if not _enabled or not is_inside_tree():
		return false
	var parent := get_parent() as CanvasItem
	return parent == null or parent.is_visible_in_tree()


func _matches_press(event: InputEventKey) -> bool:
	for action in _action_bindings:
		if InputMap.event_is_action(event, action):
			return true
	return false


func _matches_release(event: InputEventKey) -> bool:
	for action in _action_bindings:
		if InputMap.event_is_action(event, action):
			return true
	return false


func _add_action_bindings(text: String) -> void:
	if text.is_empty():
		return
	if not InputMap.get_actions().has(text):
		if not _warned.has(text):
			_warned[text] = true
			push_warning("[Hotkey] action '%s' not mapped."%[text])
		return
	_action_bindings.append(text)


func _bound_actions() -> void:
	var keys: Array[int] = []
	_add_action_bindings(str(props.get("key", "")))
	
	var action := str(props.get("action", ""))
	if action.is_empty():
		return
	
	var store_name := str(props.get("bindings", "controls"))
	var store := LuaUi.get_store(store_name)
	
	var bound := store.get_at(action)
	if bound is Array:
		for text in bound:
			_add_action_bindings(str(text))
	elif bound != null:
		_add_action_bindings(str(bound))
