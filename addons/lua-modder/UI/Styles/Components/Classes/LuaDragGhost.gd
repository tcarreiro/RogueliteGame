class_name LuaDragGhost extends Control

var _offset := Vector2.ZERO

static func spawn(content: Control) -> LuaDragGhost:
	var ghost := LuaDragGhost.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	LuaUi.get_drag_layer().add_child(ghost)   # entra na árvore agora: o conteúdo roda o _ready
	# O holder ganha o tamanho do conteúdo: componentes têm âncoras de tela cheia e, num pai de tamanho 0, se
	# expandiriam em volta da origem (conteúdo deslocado). Com o holder do tamanho certo, o conteúdo o preenche
	# e centralizar o holder no cursor centraliza o conteúdo, não importa como ele se ancora.
	var size := content.get_combined_minimum_size()
	ghost.custom_minimum_size = size
	ghost.size = size
	ghost._offset = -size * 0.5
	ghost._follow()
	return ghost
	#node.position = -node.get_combined_minimum_size() * 0.5   # centrado no cursor



func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	position = get_viewport().get_mouse_position() + _offset

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		queue_free()
	
