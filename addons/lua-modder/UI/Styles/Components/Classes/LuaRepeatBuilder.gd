class_name LuaRepeatBuilder extends RefCounted
## Mantém os filhos de um Repeat/RepeatGrid em sincronia com a lista `items`, refazendo SÓ o que mudou.
##
## Compara por ÍNDICE e por VALOR: se items[i] é igual ao que foi renderizado ali da última vez, o nó fica como
## está (preserva hover, foco, animação, um arraste em curso); só os índices cujo item mudou são recriados, e a
## lista cresce ou encolhe no fim. Isso presume que render_item é função de (item, índice), que é o contrato do
## Repeat: se o que ele desenha depende de OUTRO estado, use UI.bind dentro do que ele devolve.
##
## Inserir/remover no MEIO desloca os itens seguintes, então refaz dali em diante (comparação é por índice).
##
## ASYNC (props `async`, `loading_until` e o hook `render_loading` do Repeat):
##  - async = false: tudo no próprio sync(), como sempre.
##  - async = true: o 1º lote roda dentro do sync() (mesmo frame); se sobrar trabalho, ele continua em lotes,
##    um por frame, dentro de um orçamento de tempo.
##  - Os itens aparecem em GRUPOS de `loading_until` (os construídos entre um grupo e outro ficam invisíveis,
##    já prontos, até o grupo completar; o que sobra no fim aparece quando tudo termina).
##    -1 = um grupo só (tudo de uma vez, no fim)    0 = sem grupos nem loading (um a um)
##  - loading: o render_loading fica visível até o PRIMEIRO grupo aparecer (-1: até tudo terminar).
##    Sem o hook, não há loading: os itens aparecem aos poucos (de 1 em 1 se loading_until <= 0).
##  - itens já exibidos que mudam são trocados NO LUGAR, aos poucos: o nó antigo fica até o novo estar pronto.

signal finished   # todo o trabalho pendente terminou

const HELD := &"_repeat_held_visible"

## Orçamento por lote, em µs. O lote termina depois do primeiro item que estourar o orçamento,
## então o pior lote é o orçamento mais um item.
var first_budget_usec := 8000
var budget_usec := 6000

var _started := false
var _seen: Array = []           # cópia de cada item como foi renderizado
var _nodes: Array[Node] = []    # nó de cada índice (null = render_item não devolveu um componente)
var _revealed := 0              # os índices < _revealed estão visíveis; os demais, já prontos, esperam o grupo
var _staging := false           # este lote segura os nós novos invisíveis até o grupo completar

var _container: Control
var _render_item: Callable
var _render_loading: Callable
var _loading_until := -1
var _async := false

var _target: Array = []         # a lista pedida mais recentemente (cópia)
var _dirty: Array[int] = []     # índices já renderizados cujo item mudou, ainda não trocados
var _dirty_head := 0

var _loading: Node
var _loading_failed := false
var _scheduled := false


## Props e hooks que o Repeat/RepeatGrid acrescentam ao schema.
static func extend_schema(schema: Dictionary, component_name: String) -> Dictionary:
	schema["name"] = component_name
	schema["props"]["items"] = {"type": "array", "default": []}
	schema["props"]["async"] = {"type": "bool", "default": false}
	schema["props"]["loading_until"] = {"type": "int", "default": -1}
	schema["hooks"] = ["render_item", "render_loading"]
	return schema


## Atalho para o _apply_prop("items") do Repeat/RepeatGrid: lê hooks e props do dono.
func sync_for(owner: LuaComponent, container: Control, value: Variant) -> void:
	sync(container, value if value is Array else [],
			owner.handlers.get("render_item", Callable()),
			bool(owner.props.get("async", false)),
			owner.handlers.get("render_loading", Callable()),
			int(owner.props.get("loading_until", -1)))


func sync(container: Control, items: Array, render_item: Callable, async := false,
		render_loading := Callable(), loading_until := -1) -> void:
	if not render_item.is_valid():
		push_warning("[Repeat] falta o hook render_item")
		return
	_container = container
	_render_item = render_item
	_render_loading = render_loading
	_loading_until = loading_until
	_async = async
	_loading_failed = false
	if not _started:
		_started = true
		for child in container.get_children():   # `children` estáticos: o Repeat é dono dos filhos
			_discard(container, child)

	_target = items.duplicate(true)

	while _nodes.size() > _target.size():   # a lista encolheu
		var removed: Node = _nodes.pop_back()
		_seen.pop_back()
		if removed != null:
			_discard(container, removed)
	_revealed = mini(_revealed, _nodes.size())

	_dirty.clear()   # recalculado do zero: o estado atual é a única fonte de verdade
	_dirty_head = 0
	for i in _nodes.size():
		if _target[i] != _seen[i]:
			_dirty.append(i)

	_pump(true)


func _has_work() -> bool:
	return _dirty_head < _dirty.size() or _nodes.size() < _target.size()


## Faz trabalho até acabar (sync) ou até estourar o orçamento (async).
func _pump(first: bool) -> void:
	var budget := -1
	if _async and _container.is_inside_tree():
		budget = first_budget_usec if first else budget_usec
	_staging = budget >= 0
	var start := Time.get_ticks_usec()
	while _has_work():
		_do_one()
		if budget >= 0 and Time.get_ticks_usec() - start >= budget:
			break
	var remaining := _has_work()
	_reveal(remaining)
	_update_loading(remaining)
	if remaining:
		_schedule()
	else:
		finished.emit()


func _do_one() -> void:
	if _dirty_head < _dirty.size():   # primeiro o que já está na tela
		var i := _dirty[_dirty_head]
		_dirty_head += 1
		_replace(_container, i, _target[i], _render_item)
		return
	var index := _nodes.size()
	var node := _render(_target[index], index, _render_item)
	_nodes.append(node)
	_seen.append(_copy(_target[index]))
	if node != null:
		_container.add_child(node)   # o _ready (o trabalho pesado) roda aqui
		if _staging and index >= _revealed:
			_hold(node)


func _schedule() -> void:
	if _scheduled:
		return
	_scheduled = true
	_container.get_tree().process_frame.connect(_tick, CONNECT_ONE_SHOT)


func _tick() -> void:
	_scheduled = false
	if not is_instance_valid(_container) or not _container.is_inside_tree():
		# o dono saiu da árvore (fechou): o que faltava não será construído; nada fica invisível para sempre
		_loading = null
		if is_instance_valid(_container):
			for node in _nodes:
				_release(node)
			_revealed = _nodes.size()
		return
	_pump(false)


#region Grupos
## Quantos itens aparecem de cada vez.
func _batch_size() -> int:
	if _loading_until > 0:
		return _loading_until
	if _loading_until < 0 and _render_loading.is_valid():
		return maxi(_target.size(), 1)   # um grupo só: tudo no fim, atrás do loading
	return 1


## Mostra os itens prontos em múltiplos do grupo; ao terminar, mostra o resto.
@warning_ignore("integer_division")
func _reveal(remaining: bool) -> void:
	var built := _nodes.size()
	var count := built
	if remaining:
		var batch := _batch_size()
		count = (built / batch) * batch
	for i in range(_revealed, count):
		_release(_nodes[i])
	_revealed = maxi(_revealed, count)


## Guarda a visibilidade pretendida (a prop `visible` do componente) e esconde até o grupo completar.
func _hold(node: Node) -> void:
	var item := node as CanvasItem
	if item == null:
		return
	node.set_meta(HELD, item.visible)
	item.visible = false


func _release(node: Node) -> void:
	if node == null or not is_instance_valid(node) or not node.has_meta(HELD):
		return
	(node as CanvasItem).visible = bool(node.get_meta(HELD))
	node.remove_meta(HELD)
#endregion


#region Loading
func _update_loading(remaining: bool) -> void:
	var until := _loading_until if _loading_until >= 0 else _target.size()
	var want := remaining and _render_loading.is_valid() and _revealed < until
	if want and _loading == null and not _loading_failed:
		_show_loading()
	elif not want and _loading != null:
		_hide_loading()


func _show_loading() -> void:
	var element: Variant = _render_loading.call()
	var node: Node = null
	if element is UIElement:
		node = ComponentRegistry.instantiate(element as UIElement)
	if node == null:
		_loading_failed = true   # não tenta de novo a cada lote; a lista segue aparecendo aos poucos
		push_warning("[Repeat] render_loading deve retornar um componente")
		return
	var holder := _container.get_parent()
	holder.add_child(node)
	holder.move_child(node, _container.get_index())
	_loading = node


func _hide_loading() -> void:
	var node := _loading
	_loading = null
	if is_instance_valid(node) and node.get_parent() != null:
		_discard(node.get_parent(), node)
#endregion


func _replace(container: Node, index: int, item: Variant, render_item: Callable) -> void:
	var old := _nodes[index]
	var node := _render(item, index, render_item)
	if node != null:
		container.add_child(node)
		container.move_child(node, old.get_index() if old != null else _position_of(index))
		if _staging and index >= _revealed:
			_hold(node)   # o antigo também ainda não estava visível
	if old != null:
		_discard(container, old)
	_nodes[index] = node
	_seen[index] = _copy(item)


## Posição de um item entre os filhos reais (os que falharam ao renderizar não ocupam lugar).
func _position_of(index: int) -> int:
	var position := 0
	for i in index:
		if _nodes[i] != null:
			position += 1
	return position


func _render(item: Variant, index: int, render_item: Callable) -> Node:
	var element: Variant = render_item.call(item, index)
	if not element is UIElement:
		push_warning("[Repeat] render_item deve retornar um componente (item %d)" % index)
		return null
	return ComponentRegistry.instantiate(element as UIElement)


func _discard(container: Node, node: Node) -> void:
	container.remove_child(node)
	if node is LuaComponent:
		(node as LuaComponent).dispose()
	else:
		node.queue_free()


func _copy(item: Variant) -> Variant:
	return item.duplicate(true) if (item is Dictionary or item is Array) else item
