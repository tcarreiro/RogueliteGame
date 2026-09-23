class_name Effect extends Resource

# Modificadores do sistema de Enchantables (Equipment, Datashard, Addon)
# todos eles possuem efeitos modificadores da run
# A ideia é justamente todos serem um "Effect", construído a partir do Lua
# mas, ao menos no "mod base", ser diligente em quais peças (Equipment, Addon ou Datashard)
# podem ter de efeito

#var on_equip: Callable
#var on_unequip: Callable

enum EffectCategory {
	BUFF,
	DEBUFF
}

enum RunEvent {
	START, 
	END, 
	EVENT_TRIGGERED,
	EVENT_RESOLVED,
	EVENT_BLOCKED
}

enum PlayerEvent {
	PLAYER_HIT,
	PLAYER_DEATH,
	PLAYER_SPOTTED
}

enum LootEvent {
	LOOT_COLLECTED
}

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var unique: bool = false
@export var category: EffectCategory
@export var duration: float = INF # INF means it doesn't have a timer
@export var stacks: int = -1 # negative means it doesn't consume stacks

var on_run_event: Callable
var on_player_event: Callable
var on_loot_event: Callable

func _init(definition: EffectDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	unique = definition.unique
	category = definition.category
	duration = definition.duration
	stacks = definition.stacks
	
	on_run_event = definition.on_run_event
	on_player_event = definition.on_player_event
	on_loot_event = definition.on_loot_event


func connect_run_start() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_started, trigger_run_event.bind(RunEvent.START), ConnectFlags.CONNECT_ONE_SHOT)


func connect_run_end() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_ended, trigger_run_event.bind(RunEvent.END), ConnectFlags.CONNECT_ONE_SHOT)


func trigger_run_event(run_event: RunEvent) -> void:
	if not on_run_event.is_valid() or stacks == 0:
		return
	on_run_event.call(RunEvent.keys()[run_event])
	stacks -= 1


func trigger_player_event(player_event: PlayerEvent) -> void:
	if not on_player_event.is_valid() or stacks == 0:
		return
	on_player_event.call(PlayerEvent.keys()[player_event])
	stacks -= 1


func trigger_loot_event(loot_event: LootEvent) -> void:
	if not on_loot_event.is_valid() or stacks == 0:
		return
	on_loot_event.call(LootEvent.keys()[loot_event])
	stacks -= 1
