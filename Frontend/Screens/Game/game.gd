## Run test screen
extends Control

var _bridge: RunBridge
var _inventory_bridge: ItemContainerBridge
var _hotbar_inventory_bridge: ItemContainerBridge
var _screen: LuaComponent

func _ready() -> void:
	LuaUi.set_root(self)
	_bridge = RunBridge.new()
	_bridge.attach()
	_inventory_bridge = ItemContainerBridge.new(GameManager.game_state.persistent_inventory, "inventory", 28)
	_inventory_bridge.attach()
	_hotbar_inventory_bridge = ItemContainerBridge.new(ItemContainer.new(), "inventory_hotbar", 28)
	_hotbar_inventory_bridge.attach()
	_screen = ComponentRegistry.instantiate(ComponentRegistry.make_element("GameScreen", {})) as LuaComponent
	add_child(_screen)


func _exit_tree() -> void:
	_bridge.detach()
	_inventory_bridge.detach()
	_hotbar_inventory_bridge.detach()
