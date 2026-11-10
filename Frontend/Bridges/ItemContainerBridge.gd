class_name ItemContainerBridge extends UiBridge
## Projeta um ItemContainer na store `store_name` (inventário, baú, corpo de inimigo, sockets, loja...).
## O ItemContainer não muda em nada: a ponte escuta os sinais dele e traduz as soltura da UI nas
## operações que ele já tem (drop_stack = merge/swap, move_stack, move, split).
##
##   var bridge := ItemContainerBridge.new(GameManager.game_state.persistent_inventory, "inventory")
##   bridge.attach()    # ...e bridge.detach() ao sair da tela
##
## Store (UI.store("inventory")):
##   slots: [{ index, uid, empty, id, name, description, quantity, icon, kind, tier, selected }]  <- sempre com TODAS as chaves
##   used, capacity (texto: "7" ou "∞"), selected_name, selected_description
##
## Lua -> jogo  (todas por NOME de store; só containers com ponte anexada, ou seja, abertos, são alcançáveis):
##   Inventory.select(store, index)                                clicar no slot selecionado desmarca
##   Inventory.canDrop(src_store, src_uid, dst_store, dst_index, mode) -> { ok, op, reason }   não muda nada
##   Inventory.drop   (src_store, src_uid, dst_store, dst_index, mode) -> { ok, op, reason }
##
## O stack de origem é identificado por `uid` (não por índice): se o inventário mudar durante o arraste,
## o uid antigo simplesmente não é mais achado (NOT_FOUND) em vez de mexer no stack errado.
##
## Soltura (mode "all", o padrão):
##   slot vazio, mesmo container   -> "move"  (o stack vai para o fim)
##   slot vazio, outro container   -> "move"  (o stack inteiro, sem parcial)
##   slot ocupado, mesma espécie com espaço -> "merge"  (o que couber; o resto fica na origem)
##   slot ocupado, qualquer outro caso      -> "swap"   (funciona até com os dois containers cheios)
## mode "half" / "one": só em slot vazio, divide metade / uma unidade -> "split".
## `reason` é o nome do ItemContainerOpResult.FailReason ("FULL", "TAG_REJECTED"...) quando ok = false.

const NAMESPACE := &"Inventory"
const Fail := ItemContainerOpResult.FailReason

const MODE_ALL := "all"
const MODE_HALF := "half"
const MODE_ONE := "one"
const MODE_CUSTOM := "custom"

const OP_MOVE := "move"
const OP_SWAP := "swap"
const OP_MERGE := "merge"
const OP_SPLIT := "split"
# TODO: drop

## store_name bridge. Inventory.* is registered only once and Bridge is queried by store_name
static var _bridges: Dictionary = {}

## Minimun number os slots for unlimited container (capacity_slots = 0). It's filled with empty slots if necessary
var min_slots: int

var _container: ItemContainer
var _selected: ItemStack   # por identidade: acompanha o stack mesmo se a ordem mudar

class DropPlan extends RefCounted:
	var ok := false
	var op := ""
	var reason := ""
	var run: Callable

	func fail(fail_reason: ItemContainerOpResult.FailReason) -> DropPlan:
		ok = false
		reason = _reason_name(fail_reason)
		return self

	func from_check(check: ItemContainerOpResult, p_op: String, p_run: Callable) -> DropPlan:
		ok = check.ok
		op = p_op
		reason = "" if check.ok else _reason_name(check.fail_reason)
		run = p_run
		return self

	func to_dictionary() -> Dictionary:
		return {"ok": ok, "op": op, "reason": reason}

	static func _reason_name(fail_reason: ItemContainerOpResult.FailReason) -> String:
		return str(ItemContainerOpResult.FailReason.find_key(fail_reason))


func _init(container: ItemContainer, p_store_name: String, p_min_slots := 20) -> void:
	super(p_store_name)
	_container = container
	min_slots = p_min_slots


#region Ciclo de vida
func _on_attach() -> void:
	_bridges[store_name] = self
	_register_shared(NAMESPACE, "select", ItemContainerBridge._act_select)
	_register_shared(NAMESPACE, "canDrop", ItemContainerBridge._act_can_drop)
	_register_shared(NAMESPACE, "drop", ItemContainerBridge._act_drop)
	_link(_container.stacks_changed, _on_stacks_changed)
	_link(_container.order_changed, refresh)


func _on_detach() -> void:
	if _bridges.get(store_name) == self:
		_bridges.erase(store_name)
#endregion


#region Lua -> jogo
static func _act_select(bridge_name: Variant, index: Variant) -> bool:
	var bridge: ItemContainerBridge = _bridges.get(str(bridge_name))
	if bridge == null or not (index is int or index is float):
		return false
	bridge._select(int(index))
	return true


static func _act_can_drop(src_name: Variant, src_uid: Variant, dst_name: Variant, dst_index: Variant, mode: Variant) -> Dictionary:
	return _plan_drop(src_name, src_uid, dst_name, dst_index, mode).to_dictionary()


static func _act_drop(src_name: Variant, src_uid: Variant, dst_name: Variant, dst_index: Variant, mode: Variant) -> Dictionary:
	var plan := _plan_drop(src_name, src_uid, dst_name, dst_index, mode)
	if not plan.ok:
		return plan.to_dictionary()
	var result: ItemContainerOpResult = plan.run.call()
	if not result.ok:   # shouldn't happen, because _plan_drop already checks it. But should be safer this way
		plan.ok = false
		plan.reason = DropPlan._reason_name(result.fail_reason)
	return plan.to_dictionary()


func _select(index: int) -> void:
	var stacks := _container.get_all()
	if index < 0 or index >= stacks.size() or stacks[index] == _selected:
		_selected = null
	else:
		_selected = stacks[index]
	refresh()


## Decide o que a soltura faria, sem fazer. É a ÚNICA fonte da regra: canDrop (feedback do hover)
static func _plan_drop(src_name: Variant, src_uid: Variant, dst_name: Variant, dst_index: Variant, mode: Variant) -> DropPlan:
	var plan := DropPlan.new()
	var src: ItemContainerBridge = _bridges.get(str(src_name))
	var dst: ItemContainerBridge = _bridges.get(str(dst_name))
	if src == null or dst == null or not (dst_index is int or dst_index is float):
		return plan.fail(Fail.NOT_FOUND)

	var from := src._container
	var to := dst._container
	var from_index := src._index_of_uid(str(src_uid))
	if from_index < 0:
		return plan.fail(Fail.NOT_FOUND)   # lost origin reference
	var to_index := int(dst_index)
	if to_index < 0:
		return plan.fail(Fail.SLOT_INVALID)

	var stack: ItemStack = from.get_all()[from_index]
	var target_is_empty := to_index >= to.get_all().size()

	# Checks whether is a split action. Drop is never a "custom" mode
	var split_quantity := _split_quantity(stack.quantity, str(mode))
	if split_quantity > 0:
		if not target_is_empty:
			# checks whether 'to' has free slots
			if to.get_free_slots() == 0: # negative means 'to' has unlimited capacity
				return plan.fail(Fail.SLOT_INVALID)   # can only split if there's available slots
			# to_index changes to first available slot's index
			to_index = maxi(to.get_all().size(), to.get_capacity())
		return plan.from_check(from.can_split(stack, split_quantity, to), OP_SPLIT,
				func(): return from.split(stack, split_quantity, to))

	# TBD: should check whether drop is in exact same slot It spares unecessary component remount, but if 'failed' plan has 
	# its own style class, it shows. Maybe this is not desirable
	# ItemContainer.can_drop_stack() also checks that, so it needs to be consistent. Keeping in both places makes it respond faster, withou can_drop_stack check
	#if from == to and from_index == to_index:
		#return plan.fail(Fail.SLOT_INVALID)

	if target_is_empty:
		if from == to:
			var last := to.get_all().size() - 1
			# TBD: should check whether last? It spares unecessary component remount, but if 'failed' plan has 
			# its own style class, it shows. Maybe this is not desirable
			#if from_index == last:
				#return plan.fail(Fail.SLOT_INVALID)
			return plan.from_check(ItemContainerOpResult.complete(stack.quantity), OP_MOVE,
					func(): return from.move_stack(from_index, last))
		var loots: Array[Loot] = stack.get_all_units()
		return plan.from_check(ItemContainer.can_move(from, to, loots, false), OP_MOVE,
				func(): return ItemContainer.move(from, to, loots, false))

	var op := OP_MERGE if ItemContainer.would_merge(from, from_index, to, to_index) else OP_SWAP
	return plan.from_check(ItemContainer.can_drop_stack(from, from_index, to, to_index), op,
			func(): return ItemContainer.drop_stack(from, from_index, to, to_index))


## "half" = ceil halved stack (min = 1), "one" = one unity, "custom" uses 'split_quantity'. response 0 = means full stack
## 'quantity' = 1 turns into move operation
static func _split_quantity(quantity: int, mode: String, split_quantity:int = 0) -> int:
	if quantity < 2:
		return 0
	match mode:
		MODE_HALF:
			@warning_ignore("integer_division")
			return maxi(quantity / 2, 1)
		MODE_ONE:
			return 1
		MODE_CUSTOM:
			return mini(split_quantity, quantity)
	return 0
#endregion


#region jogo -> Lua
func _on_stacks_changed(_updated: Array, _removed: Array) -> void:
	refresh()


func _build_snapshot() -> Dictionary:
	var stacks := _container.get_all()
	var selected_index := stacks.find(_selected) if _selected != null else -1
	if selected_index < 0:
		_selected = null   # o stack saiu do container
	var capacity := _container.get_capacity()
	var total := maxi(capacity if capacity > 0 else min_slots, stacks.size())

	var slots: Array = []
	for i in total:
		slots.append(_slot_of(i, stacks[i], i == selected_index) if i < stacks.size() else _empty_slot(i))

	var sample: Loot = _selected.get_sample() if _selected != null else null
	return {
		"slots": slots,
		"used": stacks.size(),
		"capacity": str(capacity) if capacity > 0 else "INF",
		"selected_name": str(sample.display_name) if sample else "",
		"selected_description": sample.description if sample else "",
	}


func _index_of_uid(uid: String) -> int:
	var stacks := _container.get_all()
	for i in stacks.size():
		if _uid_of(stacks[i]) == uid:
			return i
	return -1


## Identidade estável do stack enquanto ele existir (texto: ids de objeto de 64 bits perdem precisão como número do Lua).
func _uid_of(stack: ItemStack) -> String:
	return str(stack.get_instance_id())


func _empty_slot(index: int) -> Dictionary:
	return {"index": index, "uid": "", "empty": true, "id": "", "name": "", "description": "",
			"quantity": 0, "icon": "", "kind": "", "tier": 0, "selected": false}


func _slot_of(index: int, stack: ItemStack, selected: bool) -> Dictionary:
	var loot: Loot = stack.get_sample()
	var icon: Variant = loot.get("icon")   # null enquanto o Loot não tiver a prop `icon`
	return {
		"index": index,
		"uid": _uid_of(stack),
		"empty": false,
		"id": str(loot.id),
		"name": str(loot.display_name),
		"description": loot.description,
		"quantity": stack.quantity,
		"icon": icon.resource_path if icon is Texture2D else "",
		"kind": _kind_of(loot),
		"tier": int(loot.get("tier")) if "tier" in loot else 0,
		"selected": selected,
	}


## "kind.gauntlet" -> "gauntlet": o primeiro kind tag é o mais específico da classe do item.
func _kind_of(loot: Loot) -> String:
	var kinds := loot.get_kind_tags()
	return String(kinds[0]).trim_prefix(String(Loot.KIND_PREFIX)) if not kinds.is_empty() else ""
#endregion
