class_name Consumable extends Loot

signal consumed(consumable: Consumable)

const KIND_CONSUMABLE := StringName(KIND_PREFIX+"consumable")

var persistent: bool = false

var on_consume: Callable

func consume():
	consumed.emit(self)
	if on_consume.is_valid():
		on_consume.call(self)
