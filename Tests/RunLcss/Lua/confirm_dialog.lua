UI.defineComponent("ConfirmDialog", {
  props = { title = "string", message = "string" },
  events = { "confirm", "cancel" },
  render = function(p)

	local function finish(handler)
		return function()
			Game.resume()
			UI.callMethod("confirm_dialog", "close")
			if handler then handler() end
		end
	end
	
	return Modal{
	  ref = "confirm_dialog",
	  blocking = true,
	  backdrop_color = "#000000AA",
	  slots = { content = Div{ class = "panel", gap = 0, children = {
		
		-- Header
		Div{ id = "dialog-header", padding_top = 0, display = "flex", flex_grow = 1, gap = 32, children = {
			Label{ text = p.title, class = "section-title" },
		} },
		
		-- Mid
		Div{ flex_grow = 1, padding_top = 40, gap = 16, children = {
			Scroll{ width = 700, height = 100, children = {
				Label{ text = p.message, class = "section-title" },
			} },
		} },
		
		-- Footer
		Div{ display = "flex", gap = 24, children = {
			Div { flex_grow = 1 },
			Button{ label = "OK", class = "btn modal confirm", on_pressed = finish(p.on_confirm) },
			Button{ label = "CANCEL", class = "btn modal cancel", on_pressed = finish(p.on_cancel) },
		} },
	  } } },
	}
  end,
})
