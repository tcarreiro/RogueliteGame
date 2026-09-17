extends Node

signal save_started()
signal save_ended()

const SAVE_DIR_PATH := "user://data/saves"
const SAVE_FILE := "save_%d.tres"

var current_save: Save
var current_slot: int


func create_new_save(slot: int) -> void:
	var save := Save.new()
	save.save_id = slot
	save.created_at = Time.get_datetime_string_from_system(false, true)
	save.last_played = save.created_at

	current_save = save
	current_save.set_meta("new_game", true)
	current_slot = slot


func _save_to_disk() -> void:
	if current_slot == -1: return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR_PATH)
	var path = SAVE_DIR_PATH + SAVE_FILE % current_slot
	save_started.emit()
	current_save.save_data()
	#var t0 = Time.get_ticks_msec()
	var err = ResourceSaver.save(current_save, path)
	#GameLogger.info("Save levou %d ms" % (Time.get_ticks_msec() - t0))
	save_ended.emit()
	if err != OK:
		# TODO: handle failure
		push_error("Erro ao salvar: %s" % err)


func load_data(slot:int) -> Save:
	var path = SAVE_DIR_PATH + SAVE_FILE % slot
	if not FileAccess.file_exists(path):
		return null
	return (load(path) as Save)


func load_save(slot: int) -> void:
	var path = SAVE_DIR_PATH + SAVE_FILE % slot
	if not FileAccess.file_exists(path):
		create_new_save(slot)
		return

	current_save = load(path)
	current_save.set_meta("new_game", false)
	current_slot = slot
	current_save.last_played = Time.get_datetime_string_from_system(false, true)


func delete_save(slot: int) -> void:
	var path = SAVE_DIR_PATH + SAVE_FILE % slot
	if not FileAccess.file_exists(path):
		return

	DirAccess.remove_absolute(path)

	if current_slot == slot:
		reset_state()


func reset_state() -> void:
	current_save = null
	current_slot = -1
