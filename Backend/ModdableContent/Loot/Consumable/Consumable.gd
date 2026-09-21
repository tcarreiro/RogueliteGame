class_name Consumable extends Loot

signal consumed(consumable: Consumable)

var persistent: bool = false

var on_consume: Callable

func consume():
	consumed.emit(self)
	if on_consume.is_valid():
		on_consume.call(self)
