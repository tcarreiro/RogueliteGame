extends VBoxContainer
class_name SaveSlot

signal request_save_delete(slot: int)

#@export var data: SaveData
@export var slot_id: int

@onready var slot_btn: Button = %SlotBtn
@onready var background: TextureRect = %Background
@onready var save_data_container: VBoxContainer = %SaveData

@onready var runs_label: Label = %RunsLabel
@onready var deck_label: Label = %DeckLabel
@onready var gauntlet_label: Label = %GauntletLabel
@onready var last_play_label: Label = %LastPlayLabel

@onready var new_save_msg: Label = %NewSaveMsg

@onready var runs: Label = %Runs
@onready var deck: Label = %Deck
@onready var gauntlet: Label = %Gauntlet
@onready var last_play: Label = %LastPlay

@onready var new_save_container: VBoxContainer = %NewSave

@onready var delete_btn: TextureButton = %DeleteBtn

func _ready():
	slot_btn.mouse_entered.connect(_play_background_animation.bind(true))
	slot_btn.mouse_exited.connect(_play_background_animation.bind(false))
	slot_btn.pressed.connect(_on_select_save)
	delete_btn.pressed.connect(_on_delete_save)
	_load_labels()


func _play_background_animation(play:bool) -> void:
	(background.material as ShaderMaterial).set_shader_parameter("play", play)


func _load_labels():
	runs_label.text = ("SAVE_SLOT.RUNS_LABEL")
	deck_label.text = ("SAVE_SLOT.DECK_LABEL")
	gauntlet_label.text = ("SAVE_SLOT.GAUNTLET_LABEL")
	last_play_label.text = ("SAVE_SLOT.LAST_PLAY_LABEL")
	new_save_msg.text = ("SAVE_SLOT.NEW_SAVE_MSG")


func _on_select_save() -> void:
	SaveManager.current_slot = slot_id
	SaveManager.load_save(SaveManager.current_slot)
	get_tree().change_scene_to_file(SceneMap.GAME_SCENE)


func _on_delete_save() -> void:
	request_save_delete.emit(slot_id)


func setup_save_data(save_data: Save, slot:int)->void:
	slot_id = slot
	if not save_data:
		save_data_container.hide()
		new_save_container.show()
		delete_btn.hide()
	else:
		save_data_container.show()
		new_save_container.hide()
		delete_btn.show()
		
		runs.text = str(save_data.total_runs)
		#deck.text = str(save_data.deck_collection_ids.size())
		#gauntlet.text = save_data.gauntlet_data.name
		last_play.text = save_data.last_played
	
