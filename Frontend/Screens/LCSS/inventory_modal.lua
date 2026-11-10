-- Inventário em Lua + LCSS.
-- Dados:  UI.store(<nome>)  (readonly, montada por um ItemContainerBridge)
-- Ações:  Inventory.select(store, index)
--         Inventory.canDrop(src_store, src_uid, dst_store, dst_index, mode) -> { ok, op, reason }
--         Inventory.drop   (src_store, src_uid, dst_store, dst_index, mode) -> { ok, op, reason }
--
-- Drag & drop: cada slot ocupado é arrastável (o slot de origem fica onde está; um fantasma segue o mouse).
-- Todo slot, ocupado ou vazio, é alvo. O arraste carrega só { store, uid } do slot de origem, por isso
-- funciona entre QUALQUER par de inventários abertos (cada um é uma store com nome próprio).

-- shift = metade do stack, ctrl = uma unidade. (Divisão só vale em slot vazio: o bridge decide.)
local function drop_mode(mode)
	if mode.shift then return "half" end
	if mode.ctrl then return "one" end
	return "all"
end

-- Slot base. Sem `item` (ou com item vazio) é um slot vazio: só a moldura.
-- Camadas num Stack: ícone embaixo; por cima um Button transparente que desenha a borda e recebe o mouse.
-- A cor da borda diferencia: vazio < ocupado < tipo do item (kind-*) < selecionado < alvo do arraste.
UI.defineComponent("ItemSlot", {
	-- Cuidado: p é um Dictionary do Godot; nomes como size/keys/values/get/has/erase viram MÉTODOS (p.size ~= p["size"]).
	props = { item = "dict", selected = "bool", slot_size = "int", store = "string", ghost = "bool" },
	events = { "pick" },
	render = function(p)
		local item = p.item
		local size = p.slot_size > 0 and p.slot_size or 64
		local filled = item.id ~= nil and item.id ~= ""

		local slot_class = "slot"
		if filled then slot_class = slot_class .. " filled kind-" .. item.kind end
		if p.selected then slot_class = slot_class .. " selected" end
		if p.ghost then slot_class = slot_class .. " ghost" end

		local label = ""
		if filled and item.quantity > 1 then label = "x" .. item.quantity end

		local frame = { class = slot_class, width = size, height = size }

		if not p.ghost then
			-- click (ao SOLTAR sem arrastar), não pressed: mudar a store no mouse-down recria os slots e mata o drag
			frame.on_click = function()
				if p.on_pick then p.on_pick(item.index) end
			end

			-- alvo: qualquer slot aceita
			frame.drop_accept = "item_slot"
			frame.on_can_drop = function(payload, mode)
				return Inventory.canDrop(payload.store, payload.uid, p.store, item.index, drop_mode(mode)).ok
			end
			frame.on_drop = function(payload, mode)
				Inventory.drop(payload.store, payload.uid, p.store, item.index, drop_mode(mode))
			end

			-- origem: só slot ocupado. O fantasma é um ItemSlot "dummy" com os mesmos dados.
			if filled then
				frame.drag_type = "item_slot"
				frame.drag_payload = { store = p.store, uid = item.uid }
				frame.on_drag_preview = function()
					return ItemSlot{ item = item, store = p.store, slot_size = size, ghost = true }
				end
			end
		end

		local layers = {}
		layers[#layers + 1] = Button(frame) -- button is responsible for pointer_events
				
		if filled and item.icon ~= "" then
			layers[#layers + 1] = Sprite{ texture = item.icon, width = size, height = size, class = "slot-icon", pointer_events = "none" }
		end

		layers[#layers + 1] = Div{ width = size, height = size, padding = 5, pointer_events = "none", children = {
			Div{ flex_grow = 1 },
			Label{ text = label, class = slot_class }
		} }

		local cell = { width = size, height = size, class = p.ghost and "slot-cell ghost" or "slot-cell", children = layers }
		if p.ghost then cell.pointer_events = "none" end   -- o fantasma nunca intercepta o mouse
		return Stack(cell)
	end,
})

-- Dois modos: modal (bloqueia o resto, um só inventário) ou janela (windowed: não bloqueia e dá para arrastar
-- a janela; é o que permite ter inventário + baú abertos e arrastar itens entre eles).
UI.defineComponent("InventoryModal", {
	props = { store = "string", title = "string", columns = "int", windowed = "bool", margin = "any" },
	events = { "closed" },
	render = function(p)
		local inv = UI.store(p.store)
		local columns = p.columns > 0 and p.columns or 5
		local ref = "inventory_modal:" .. p.store   -- uma ref por inventário: dois abertos não se confundem

		return Modal{
			ref = ref,
			blocking = not p.windowed,
			draggable = true,
			draggable = p.windowed,
			margin = p.margin,
			backdrop_color = p.windowed and "#00000000" or "#000000AA",
			slots = { content = Div{ class = "inv-panel", gap = 12, children = {
				Div{ display = "flex", drag_handle = true, gap = 12, children = {
					Label{ text = p.title, class = "inv-title" },
					Div{ flex_grow = 1 },
					Label{
						class = "inv-count",
						text = UI.bind(inv, function() return inv.get_at("used") .. " / " .. inv.get_at("capacity") end),
					},
					Button{ label = "X", width = 40, height = 40, class = "btn close", padding = 0, on_pressed = function() UI.callMethod(ref, "close") end },
					Hotkey{ key = "ui_cancel", on_press = function() UI.callMethod(ref, "close") end },
				} },

				Scroll{ height = 380, children = {
					RepeatGrid{
						columns = columns,
						gap = 6,
						items = UI.bind(inv, "slots"),
						render_item = function(item)
							return ItemSlot{
								item = item,
								store = p.store,
								selected = item.selected,
								on_pick = function(index) Inventory.select(p.store, index) end,
							}
						end,
					},
				} },

				Div{ class = "inv-details", gap = 4, children = {
					Label{ text = UI.bind(inv, "selected_name"), class = "inv-detail-name" },
					Label{ text = UI.bind(inv, "selected_description"), class = "inv-detail-text" },
				} },
			} } },
		}
	end,
})
