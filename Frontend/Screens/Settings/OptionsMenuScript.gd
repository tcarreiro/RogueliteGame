extends Control

func _ready():
	#EventBus.language_changed.connect(_load_labels)
	_load_labels()


func _on_back_pressed():
	get_tree().change_scene_to_file(SceneMap.MAIN_MENU_SCENE)

func _on_lang_selection(lang: String):
	if TranslationServer.get_locale() == lang:
		return
	TranslationServer.set_locale(lang)
	#EventBus.language_changed.emit()

func _load_labels():
	$NavTab/GeneralTabBtn.text = tr("GENERAL")
	$NavTab/GraphicsTabBtn.text = tr("GRAPHICS")
	$NavTab/ControlsTabBtn.text = tr("CONTROLS")
	$ConfirmContainer/RestoreBtn.text = tr("RESTORE")
	$ConfirmContainer/ConfirmBtn.text = tr("CONFIRM")
	$ConfirmContainer/CancelBtn.text = tr("CANCEL")
	$ConfirmContainer/ApplyBtn.text = tr("APPLY")
