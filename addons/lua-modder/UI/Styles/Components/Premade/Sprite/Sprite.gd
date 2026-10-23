extends LuaComponent

## A raiz é um TextureRect, mas o script herda de LuaComponent (Control): Variant resolve em runtime.
@onready var _tr: Variant = self

var _source: Texture2D
var _atlas := AtlasTexture.new()
var _hframes := 1
var _vframes := 1
var _frame_count := 1
var _frame := 0
var _elapsed := 0.0
var _playing := true
var _loop := true


func get_schema() -> Dictionary:
	return {
		"name": "Sprite",
		"props": PropertyDefinition.pick([
			PropertyDefinition.TEXTURE, PropertyDefinition.HFRAMES, PropertyDefinition.VFRAMES,
			PropertyDefinition.FRAME_COUNT, PropertyDefinition.FRAME, PropertyDefinition.FPS,
			PropertyDefinition.DURATION, PropertyDefinition.LOOP, PropertyDefinition.PLAYING,
			PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
		]),
		"events": ["finished", "frame_changed"],
		"methods": ["play", "pause", "stop", "set_frame"],
	}


func _ready() -> void:
	_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # o tamanho vem de width/height, não da sheet inteira
	_tr.stretch_mode = TextureRect.STRETCH_SCALE
	super._ready()


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.TEXTURE, PropertyDefinition.HFRAMES, PropertyDefinition.VFRAMES, PropertyDefinition.FRAME_COUNT:
			_rebuild()
		PropertyDefinition.FRAME:
			set_frame(int(value))
		PropertyDefinition.LOOP:
			_loop = bool(value)
		PropertyDefinition.PLAYING:
			_playing = bool(value)
			_refresh_processing()
		PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT:
			_update_size()
		_:
			super._apply_prop(key, value)


## Lê sempre de `props`, que já vem resolvido: a ordem em que as props chegam não importa.
func _rebuild() -> void:
	var path := str(props.get("texture", ""))
	_source = null
	if path != "":
		_source = load(path) as Texture2D
		if _source == null:
			push_warning("[Sprite] textura não encontrada: '%s'" % path)
	_hframes = maxi(int(props.get("hframes", 1)), 1)
	_vframes = maxi(int(props.get("vframes", 1)), 1)
	var total := _hframes * _vframes
	var declared := int(props.get("frame_count", 0))
	_frame_count = clampi(declared, 1, total) if declared > 0 else total

	_atlas.atlas = _source
	_tr.texture = _atlas if _source != null else null
	_update_size()
	_elapsed = 0.0
	_show_frame(clampi(int(props.get("frame", 0)), 0, _frame_count - 1))
	_refresh_processing()


func _update_size() -> void:
	var cell := Vector2.ZERO
	if _source != null:
		cell = _source.get_size() / Vector2(_hframes, _vframes)
	var w := int(props.get("width", -1))
	var h := int(props.get("height", -1))
	custom_minimum_size = Vector2(float(w) if w >= 0 else cell.x, float(h) if h >= 0 else cell.y)


func _show_frame(index: int) -> void:
	_frame = index
	if _source == null:
		return
	var cell := _source.get_size() / Vector2(_hframes, _vframes)
	var col := index % _hframes
	var row := floori(float(index) / float(_hframes))
	_atlas.region = Rect2(Vector2(col, row) * cell, cell)
	if _is_ready:
		emit_event("frame_changed", [index])


func _seconds_per_frame() -> float:
	var duration := float(props.get("duration", 0.0))
	if duration > 0.0:
		return duration / float(_frame_count)
	return 1.0 / maxf(float(props.get("fps", 12.0)), 0.001)


func _refresh_processing() -> void:
	set_process(_playing and _source != null and _frame_count > 1)


func _process(delta: float) -> void:
	_elapsed += delta
	var raw := int(_elapsed / _seconds_per_frame())
	if not _loop and raw >= _frame_count:
		_show_frame(_frame_count - 1)
		_playing = false
		_refresh_processing()
		emit_event("finished")
		return
	var index := raw % _frame_count if _loop else raw
	if index != _frame:
		_show_frame(index)
		if index == _frame_count - 1:
			emit_event("finished")


#region Métodos expostos ao Lua
func play() -> void:
	if not _loop and _frame >= _frame_count - 1:
		_elapsed = 0.0   # já terminou: recomeça
	_playing = true
	_refresh_processing()


func pause() -> void:
	_playing = false
	_refresh_processing()


func stop() -> void:
	_playing = false
	_elapsed = 0.0
	_show_frame(0)
	_refresh_processing()


func set_frame(index: int) -> void:
	_show_frame(clampi(index, 0, maxi(_frame_count - 1, 0)))
	_elapsed = float(_frame) * _seconds_per_frame()
#endregion
