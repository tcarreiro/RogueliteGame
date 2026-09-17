extends Control
class_name ConfirmationPopUp

signal confirm_action()
signal cancel_action()

@onready var msg: RichTextLabel = %Msg
@onready var ok_btn: Button = %OkBtn
@onready var cance_btn: Button = %CancelBtn

func _ready() -> void:
	ok_btn.pressed.connect(_on_confirm)
	cance_btn.pressed.connect(_on_cancel)

func _show(text: String)->void:
	show()
	ok_btn._set_text(tr("OK"))
	cance_btn._set_text(tr("CANCEL"))
	msg.text = text

func _on_confirm() -> void:
	hide()
	confirm_action.emit()

func _on_cancel() -> void:
	hide()
	cancel_action.emit()
