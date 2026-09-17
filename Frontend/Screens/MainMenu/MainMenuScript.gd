extends Control

@onready var main_menu_container: VBoxContainer = %MainMenuContainer
@onready var play_btn: AnimatedButton = %PlayBtn
@onready var options_btn: AnimatedButton = %OptionsBtn
@onready var exit_btn: AnimatedButton = %ExitBtn

@onready var save_slots_container: VBoxContainer = %SaveSlotsContainer
@onready var slots: HBoxContainer = %Slots
@onready var save_slots: Array[SaveSlot] = [%Slot0, %Slot1, %Slot2, %Slot3]
@onready var back_btn: Button = %BackBtn

@onready var confirmation_pop_up: ConfirmationPopUp = %ConfirmationPopUp

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	exit_btn.pressed.connect(_on_quit_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	#EventBus.language_changed.connect(_load_labels)
	_load_labels()

func _on_play_pressed():
	main_menu_container.hide()
	save_slots_container.show()
	for i in range(slots.get_child_count()):
		save_slots[i].setup_save_data(SaveManager.load_data(i), i)
		#Utils.ensure_connected(save_slots[i].request_save_delete, _on_save_delete_request)

func _on_save_delete_request(slot: int)-> void:
	confirmation_pop_up.confirm_action.connect(_on_save_delete.bind(slot))
	confirmation_pop_up._show(tr("SAVE_SLOT.CONFIRM_DELETE_MSG"))

func _on_save_delete(slot: int)-> void:
	SaveManager.delete_save(slot)
	confirmation_pop_up.confirm_action.disconnect(_on_save_delete.bind(slot))
	main_menu_container.show()
	save_slots_container.hide()

func _on_back_pressed():
	main_menu_container.show()
	save_slots_container.hide()

func _on_options_pressed():
	get_tree().change_scene_to_file(SceneMap.OPTIONS_SCENE)

func _on_quit_pressed():
	get_tree().quit()

func _load_labels():
	play_btn._set_text(tr("PLAY"))
	options_btn._set_text(tr("OPTIONS"))
	exit_btn._set_text(tr("EXIT"))
	back_btn.text = tr("BACK")
