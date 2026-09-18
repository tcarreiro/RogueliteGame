class_name LuaUiSprite extends LuaUiComponent

func get_type_name() -> String:
	return "sprite"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var rect := TextureRect.new()
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var base_texture := load(definition.get("texture", "")) as Texture2D
	if base_texture == null:
		push_warning("[LuaUiSprite] Textura não encontrada: %s" % definition.get("texture"))
		return rect

	var hframes := int(definition.get("hframes", 1))
	var vframes := int(definition.get("vframes", 1))
	var fps := float(definition.get("fps", 8))
	var loop := bool(definition.get("loop", true))
	var total_frames := hframes * vframes
	var frame_w := base_texture.get_width() / float(hframes)
	var frame_h := base_texture.get_height() / float(vframes)
	var current_frame := int(definition.get("frame", 0))

	var atlas := AtlasTexture.new()
	atlas.atlas = base_texture
	rect.texture = atlas

	var update_frame := func(idx: int):
		var col := idx % hframes
		var row := idx / hframes
		atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)

	update_frame.call(current_frame)

	if total_frames > 1 and fps > 0:
		var frame_state := [current_frame]
		rect.ready.connect(func():
			var timer := Timer.new()
			timer.wait_time = 1.0 / fps
			rect.add_child(timer)
			timer.timeout.connect(func():
				frame_state[0] += 1
				if frame_state[0] >= total_frames:
					if loop:
						frame_state[0] = 0
					else:
						frame_state[0] = total_frames - 1
						timer.stop()
				update_frame.call(frame_state[0])
			)
			timer.start()
		, CONNECT_ONE_SHOT)

	return rect
