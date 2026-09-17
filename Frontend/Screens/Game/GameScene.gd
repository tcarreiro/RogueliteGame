class_name GameScene extends Node3D
#TODO: COMPLETE

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var sun: DirectionalLight3D = %Sun
@onready var top_light_shadow: DirectionalLight3D = %TopLightShadow

#@onready var scene_transition: SceneTransition = $SceneTransition
@onready var level_container: Node3D = %LevelContainer

func _ready() -> void:
	#EventBus.request_scene_change.connect(_load_level)
	#RunManager.run_ended.connect(_on_run_ended)
	
	if not _get_hub_scene():
		push_error("GameScene: Hub scene not defined.")
	
	if SaveManager.current_save:
		if  SaveManager.current_save.get_meta("new_game"):
			GameManager.new_game()
		else:
			GameManager.load_game()
	
	# Inicia no hub principal
	_load_level(_get_hub_scene())


func _load_level(map_scene: PackedScene, spawn_name: String = "default_spawn") -> void:
	if not map_scene:
		return
	
	var scene_id := map_scene.resource_path
	
	# Pausa todos os mapas ativos
	for child in level_container.get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.visible = false
	
	# Instancia se ainda não existe
	#if not _get_loaded_maps().has(scene_id):
		#var map_node = map_scene.instantiate() as RoomManager
		#if not map_node:
			#push_error("GameScene: Invalid map level.")
			#return
		#level_container.add_child(map_node)
		#_get_loaded_maps()[scene_id] = map_node
	#else:
		#(_get_loaded_maps()[scene_id] as RoomManager).activate()
	#
	#var map := _get_loaded_maps()[scene_id] as RoomManager
	#
	## Posiciona o jogador no spawn point
	#var markers := map.find_children(spawn_name, "Marker3D", true, false)
	#if not markers.is_empty():
		#GameManager.player.global_position = markers[0].global_position


func _on_run_ended(success: bool) -> void:
	#GameLogger.info("Run ended. Success: %s" % success)
	SaveManager._save_to_disk() 
	
	#TODO Futuro: mostrar resultados antes de limpar
	clear_run_maps()
	#EventBus.request_scene_transition.emit(_get_hub_scene(), "default_spawn")


func clear_run_maps() -> void:
	#for scene_id in _get_loaded_maps().keys():
		#var map := _get_loaded_maps()[scene_id] as RoomManager
		#if map and map.is_run_level:
			#_get_loaded_maps().erase(scene_id)
			#map.queue_free()
	pass


func _get_loaded_maps() -> Dictionary:
	return GameManager.game_state.loaded_maps


func _get_hub_scene() -> PackedScene:
	return null#RoomDatabase.lighthouse_island_scene
