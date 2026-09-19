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

signal log_changed

var _entries: Array[LogEntry] = []
var _colors: Dictionary = {
	Level.DEBUG: Color.GREEN,
	Level.INFO: Color.MEDIUM_BLUE,
	Level.WARN: Color.GOLDENROD,
	Level.ERROR: Color.RED,
	Level.COMMAND: Color.CORAL,
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
	_entries.append(LogEntry.new(level, message))
	print("[%s] --- %s"%[Level.keys()[level], message])
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
