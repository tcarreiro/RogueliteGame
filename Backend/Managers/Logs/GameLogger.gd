@tool
extends Node

enum Level {
	DEBUG,
	INFO,
	WARN,
	ERROR,
	COMMAND
}

class LogEntry:
	var level: Level
	var message: String
	var timestamp: String
	var visible: bool = true
	
	func _init(lvl: Level, msg: String) -> void:
		level = lvl
		message = msg
		timestamp = Time.get_datetime_string_from_system()

class LevelColorMap:
	var color: Color
	var name: StringName
	
	func _init(_c: Color, _n: StringName) -> void:
		color = _c
		name = _n

signal log_changed

var _entries: Array[LogEntry] = []
var _colors: Dictionary[Level, LevelColorMap] = {
	Level.DEBUG: LevelColorMap.new(Color.GREEN, "green"),
	Level.INFO: LevelColorMap.new(Color.MEDIUM_BLUE, "blue"),
	Level.WARN: LevelColorMap.new(Color.GOLDENROD, "yellow"),
	Level.ERROR: LevelColorMap.new(Color.RED, "red"),
	Level.COMMAND: LevelColorMap.new(Color.CORAL, "orange"),
}


func debug(message: String) -> void:
	_add_entry(Level.DEBUG, message)

func info(message: String) -> void:
	_add_entry(Level.INFO, message)

func warn(message: String) -> void:
	_add_entry(Level.WARN, message)

func error(message: String) -> void:
	_add_entry(Level.ERROR, message)

func command(message: String) -> void:
	_add_entry(Level.COMMAND, message)


func _add_entry(level: Level, message: String) -> void:
	var log_entry := LogEntry.new(level, message)
	_entries.append(log_entry)
	print_rich("%s - [color=%s][%s][/color] --- %s"%[log_entry.timestamp, _colors.get(level).name, Level.keys()[level], message])
	log_changed.emit()


func get_visible_entries() -> Array[LogEntry]:
	var result: Array[LogEntry] = []
	for entry in _entries:
		if entry.visible:
			result.append(entry)
	return result


func get_all_entries() -> Array[LogEntry]:
	return _entries


func make_visible_by_level(level: Level) -> void:
	clear_visible()
	for entry in _entries:
		if entry.level == level:
			entry.visible = true
	log_changed.emit()

func make_all_visible() -> void:
	clear_visible()
	for entry in _entries:
		entry.visible = true
	log_changed.emit()


func clear_visible_by_level(level: Level) -> void:
	for entry in _entries:
		if entry.level == level:
			entry.visible = false
	log_changed.emit()


func clear_visible() -> void:
	for entry in _entries:
		entry.visible = false
	log_changed.emit()


func get_color(level: Level) -> Color:
	return _colors.get(level, Color.WHITE)


func get_level_name(level: Level) -> String:
	return Level.keys()[level]


func save_to_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		for entry in _entries:
			file.store_line("[%s] [%s] %s" % [entry.timestamp, Level.keys()[entry.level], entry.message])
		file.close()
