class_name UUID extends Resource

@export var value := ""

func _init(_value := ""):
	value = _value if !_value.is_empty() else _generate()

static func new_uuid() -> UUID:
	return UUID.new()

static func from_string(text: String) -> UUID:
	return UUID.new(text)

static func _generate() -> String:
	return "%08X-%08X%08X-%08X" % [
		randi(),
		randi(),
		randi(),
		randi()
	]

func regenerate() -> void:
	value = _generate()

func _to_string() -> String:
	return value

func equals(other: UUID) -> bool:
	return value == other.value

func is_empty() -> bool:
	return value.is_empty()
