-- Pause menu em Lua + LCSS.
UI.defineComponent("PauseMenu", {
	props = { ref = "string", title = "string" },
	events = { "closed" },
	render = function(p)
		if not Game.isPaused() then
			Game.pause()
		end
		
		local state = UI.store("local_store")
		state.set_at("description", "")
		
		local screen = UI.store("run_screen")
		local in_hub = screen.get_at("phase") == "hub"
		local in_run = screen.get_at("phase") == "run"
		
		local function close()
			UI.callMethod(p.ref, "close")
			if Game.isPaused() then
				Game.resume()
			end
		end 
		
		local function set_option_description(desc)
			state.set_at("description", desc)
		end
		
		local function confirm(title, message, action)
		  UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = action })
		end
		
		local function on_save_game()
			close()
			print("TODO: Save Game")
		end
		
		local function on_fail_run()
			close()
			Game.failRun()
		end
		
		local function on_quit_to_main_menu()
			print("TODO: Save Game")
			close()
			UI.goToScene("main_menu")
		end
		
		local function on_quit_to_desktop()
			print("TODO: Save Game")
			UI.quit()
		end
		
		local function button(btn_id, label, description, pressed, class_on_hover, visible)
			if class_on_hover == nil then
				class_on_hover = ""
			end
			return Button{ 
				id = btn_id,
				ref = btn_id,
				label = label,
				visible = visible,
				class = "btn pause-menu " .. class_on_hover,
				on_pressed = function()
					--UI.playSoundEffect("click")
					pressed()
				end,
				on_mouse_entered = function()
					--UI.playSoundEffect("hover")
					set_option_description(description)
				end,
				on_mouse_exited = function()
					set_option_description(" ")
				end
			}
		end
	
		return Modal{
			ref = p.ref,
			backdrop_color = "#000000AA",
			slots = { content = Div{ class = "pause-menu-panel", gap = 12, children = {
				Hotkey{ action = "close_modal", on_press = close },
				Div{ class = "panel", alignment = "center", align_items = "center", gap = 12,
					width = 700, height = 900, children = {
					Label{ text = p.title, class = "inv-title" },
					Div{ flex_grow = .2 },
					Div{ flex_grow = 1, width = 400, gap = 20, alignment = 'center', children = {
						button("resume_btn", "RESUME", "PM_RESUME_DESC", close, "", true),
						button("settings_btn", "SETTINGS", "PM_SETTINGS_DESC", function() UI.mount(Settings{}) end, "", true),
						button("save_game", "SAVE", "PM_SAVE_DESC", function() confirm("SAVE", "CONFIRM_SAVE_GAME_MSG", on_save_game) end, "", in_hub),
					} },
					Div{ flex_grow = .2 },
					Div{ flex_grow = 1, width = 400, gap = 20, alignment = 'center', children = {
						button("end_run", "LABEL_END_RUN", "PM_END_RUN_DESC", function() confirm("END_RUN", "CONFIRM_MSG_END_RUN", on_fail_run) end, "" ,in_run),
						button("main_menu_btn", "MAIN_MENU", "PM_MAIN_MENU_DESC", function() confirm("MAIN_MENU", "SAVE_GAME_MAIN_MENU_MSG", on_quit_to_main_menu) end, "", true),
						button("quit_btn", "LABEL_QUIT_TO_DESKTOP", "PM_QUIT_DESC", function() confirm("DESKTOP", "SAVE_GAME_QUIT_MSG", on_quit_to_desktop) end, "text-color-red", true),
					} },
					Div{ flex_grow = .2 },
					Div{ class = "pause-menu-description-panel p-1", flex_grow = 1, width = 400, alignment = 'start', children = {
						Label{class = "m-0", autowrap = "word", text=UI.bind(state, "description")}
					} },
				} },
			} } },
		}
	end,
})
