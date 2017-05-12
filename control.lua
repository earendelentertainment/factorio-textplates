--[[
CUSTOM EVENTS USED

on_entity_revived
raise_event implementation: raise_event('on_entity_revived', {entity=LuaEntity, player_index=player.player_index})
on_event implementation: remote.add_interface("mymod", { on_entity_revived = function(data) return myfunction(data.entity, data.player_index) end})

]]--
local function raise_event(event_name, event_data)
	local responses = {}
	for interface_name, interface_functions in pairs(remote.interfaces) do
		if interface_functions[event_name] then
			responses[interface_name] = remote.call(interface_name, event_name, event_data)
		end
	end
	return responses
end

local modname = "textplates"
local textplates = require("plate-types")

local default_symbol = "square" -- constant

local function item_suffix_from_char(character)
	return textplates.symbol_by_char[string.lower( character )] or default_symbol
end

local function prep_player_plate_options(player_index)
	if not global.plates_players then
		global.plates_players = {}
	end
	if not global.plates_players[player_index] then
		global.plates_players[player_index] = {}
	end
end

local function show_gui(player, item_name)
	local item_prefix = string.gsub(item_name, "-blank", "")

	-- remove any UIs of the other plate types
	for _, material in ipairs(textplates.materials) do
		for _, size in ipairs(textplates.sizes) do
			if(size.."-"..material ~= item_prefix) and player.gui.left[size.."-"..material] ~= nil then
				player.gui.left[size.."-"..material].destroy()
			end
		end
	end

	-- add the desired plate type UI
	if player.gui.left[item_prefix] == nil then
		local plate_frame = player.gui.left.add{type = "frame", name = item_prefix, caption = {"textplates.text-plate-ui-title"}, direction = "vertical"}
		local plates_table = plate_frame.add{type ="table", name = "plates_table", colspan = 6, style = "plates-table"}

		for _, symbol in ipairs(textplates.symbols) do
			if not(symbol == "blank") then
				local plate_option = item_prefix.."-"..symbol
				if(symbol == default_symbol) then
					plates_table.add{type = "sprite-button", name = plate_option, sprite="item/"..plate_option, style="plates-button-active"}
				else
					plates_table.add{type = "sprite-button", name = plate_option, sprite="item/"..plate_option, style="plates-button"}
				end
			end
		end

		local plates_input_label = plate_frame.add{type ="label", name = "plates_input_label", caption={"textplates.text-plate-input-label"}}
		local plates_input = plate_frame.add{type ="textfield", name = "plates_input"}

		prep_player_plate_options(player.index)
		global.plates_players[player.index][item_prefix] = item_prefix.."-"..default_symbol

	end
end

local function hide_gui(player)
	for _, material in ipairs(textplates.materials) do
		for _, size in ipairs(textplates.sizes) do
			if player.gui.left[size.."-"..material] ~= nil then
				player.gui.left[size.."-"..material].destroy()
			end
		end
	end
end

local function is_blank_plate(item_name)
	for _, material in ipairs(textplates.materials) do
		for _, size in ipairs(textplates.sizes) do
			if item_name == size .. "-" .. material .. "-blank" then
				return true
			end
		end
	end
	return false
end

local function on_player_cursor_stack_changed(event)
	local player = game.players[event.player_index]
	if player.cursor_stack and player.cursor_stack.valid and player.cursor_stack.valid_for_read and is_blank_plate(player.cursor_stack.name)then
		show_gui(player, player.cursor_stack.name)
	else
		hide_gui(player)
	end
end


local function on_gui_click(event)
	local player_index = event.player_index
	local player = game.players[player_index]
	if event.element.parent and event.element.parent.name == "plates_table" then
		for _, material in ipairs(textplates.materials) do
			for _, size in ipairs(textplates.sizes) do
				for _, symbol in ipairs(textplates.symbols) do
					if event.element.name == size.."-"..material.."-"..symbol then
						-- uncheck others
						for _, buttonname in ipairs(event.element.parent.children_names) do
							event.element.parent[buttonname].style = "plates-button"
						end
						-- check self
						event.element.style = "plates-button-active"
						prep_player_plate_options(player_index)
						global.plates_players[player_index][size.."-"..material] = event.element.name
						if(player.gui.left[size.."-"..material].plates_input) then
							player.gui.left[size.."-"..material].plates_input.text = ""
						end
					end
				end
			end
		end
	end
end

local function prep_next_symbol(player_index)
	local player = game.players[player_index]
	for _, material in ipairs(textplates.materials) do
		for _, size in ipairs(textplates.sizes) do
			if player.gui.left[size.."-"..material] and player.gui.left[size.."-"..material].plates_input and player.gui.left[size.."-"..material].plates_table then
				prep_player_plate_options(player_index)
				local text = player.gui.left[size.."-"..material].plates_input.text
				if string.len(text) > 0 then
					local first_char = string.sub(text, 1, 1)
					local next_name = size.."-"..material.."-"..item_suffix_from_char(first_char)
					for _,buttonname in ipairs(player.gui.left[size.."-"..material].plates_table.children_names) do
						player.gui.left[size.."-"..material].plates_table[buttonname].style = "plates-button"
					end
					player.gui.left[size.."-"..material].plates_table[next_name].style = "plates-button-active"
					global.plates_players[player_index][size.."-"..material] = next_name
				else
					for _,buttonname in ipairs(player.gui.left[size.."-"..material].plates_table.children_names) do
						player.gui.left[size.."-"..material].plates_table[buttonname].style = "plates-button"
					end
					player.gui.left[size.."-"..material].plates_table[size.."-"..material.."-"..default_symbol].style = "plates-button-active"
					global.plates_players[player_index][size.."-"..material] = size.."-"..material.."-"..default_symbol
				end
			end
		end
	end
end

local function on_gui_text_changed(event)
	if(event.element.name == "plates_input") then
		prep_next_symbol(event.player_index)
	end
end


local function on_built_entity (event)
	local player_index = event.player_index
	if player_index then -- can be nil
		local player = game.players[player_index]
		local entity = event.created_entity
		if entity.valid then -- in case of other scripts
			if entity.name == "entity-ghost" then
				if player.cursor_stack and player.cursor_stack.valid and player.cursor_stack.valid_for_read and is_blank_plate(player.cursor_stack.name) then
					for _, material in ipairs(textplates.materials) do
						for _, size in ipairs(textplates.sizes) do
							if entity.ghost_name == size.."-"..material.."-blank" then
								entity.operable = false
								prep_player_plate_options(player_index)
								local replace_name = size.."-"..material.."-"..default_symbol -- default
								-- loaded value
								if global.plates_players[player_index][size.."-"..material] then
									replace_name = global.plates_players[player_index][size.."-"..material]
								end
								-- sequence
								if player.gui.left[size.."-"..material] and player.gui.left[size.."-"..material].plates_input then
									local text = player.gui.left[size.."-"..material].plates_input.text
									if string.len(text) > 0 then
										local first_char = string.sub(text, 1, 1)
										local remainder = string.sub(text, 2, -1)
										player.gui.left[size.."-"..material].plates_input.text = remainder
										replace_name = size.."-"..material.."-"..item_suffix_from_char(first_char)
										prep_next_symbol(player_index)
									end
								end

								if replace_name ~= entity.name then
									-- replace
									entity.get_control_behavior().parameters={parameters={{signal={type="item",name=replace_name},count=0,index=1}}}
									return
								end
							end
						end
					end
				else
					for _, material in ipairs(textplates.materials) do
						for _, size in ipairs(textplates.sizes) do
							for _, symbol in ipairs(textplates.symbols) do
								if symbol ~= "blank" and entity.ghost_name == size.."-"..material.."-"..symbol then
									local replacement = entity.surface.create_entity{
                    name = "entity-ghost",
                    inner_name = size.."-"..material.."-blank",
                    position = entity.position,
                    force = entity.force,
                    expires = false
                  }
									replacement.get_control_behavior().parameters={parameters={{signal={type="item",name=entity.ghost_name},count=0,index=1}}}
									replacement.operable = false
									script.raise_event(defines.events.on_built_entity,
									{
									   tick = event.tick,
									   name = defines.events.on_built_entity,
									   created_entity = replacement,
									   player_index = player_index,
									   mod = modname,
									   is_replacement = true,
									   replaced_unit_number = entity.unit_number
									})
									if entity.valid then entity.destroy() end
									return
								end
							end
						end
					end
				end
			else
				for _, material in ipairs(textplates.materials) do
					for _, size in ipairs(textplates.sizes) do
						if entity.name == size.."-"..material.."-blank" then
							entity.operable = false
							-- check to see if this is a revived or script-spawned enetity (from a blueprint)
							-- if it is configured to become a letter let it do it
							local replace_name = nil
							if entity.get_control_behavior().parameters.parameters[1]
								and entity.get_control_behavior().parameters.parameters[1].signal
								and entity.get_control_behavior().parameters.parameters[1].signal.name then
								local test_name = entity.get_control_behavior().parameters.parameters[1].signal.name
								for _, symbol in ipairs(textplates.symbols) do
									if test_name == size.."-"..material.."-"..symbol then
										replace_name = test_name
										local replacement = entity.surface.create_entity{ name=replace_name, position=entity.position, force=entity.force}
										replacement.operable = false
										script.raise_event(defines.events.on_built_entity,
										{
										   tick = event.tick,
										   name = defines.events.on_built_entity,
										   created_entity = replacement,
										   player_index = player_index,
										   mod = modname,
										   is_replacement = true,
										   replaced_unit_number = entity.unit_number
										})
										if entity.valid then entity.destroy() end
										return
									end
								end
							end
							if replace_name then
								local replacement = entity.surface.create_entity{ name=replace_name, position=entity.position, force=entity.force}
								replacement.operable = false
								script.raise_event(defines.events.on_built_entity,
								{
								   tick = event.tick,
								   name = defines.events.on_built_entity,
								   created_entity = replacement,
								   player_index = player_index,
								   mod = modname,
								   is_replacement = true,
								   replaced_unit_number = entity.unit_number
								})
								if entity.valid then entity.destroy() end
							else
								prep_player_plate_options(player_index)
								local replace_name = size.."-"..material.."-"..default_symbol -- default
								-- loaded value
								if global.plates_players[player_index][size.."-"..material] then
									replace_name = global.plates_players[player_index][size.."-"..material]
								end
								-- sequence
								if player.gui.left[size.."-"..material] and player.gui.left[size.."-"..material].plates_input then
									local text = player.gui.left[size.."-"..material].plates_input.text
									if string.len(text) > 0 then
										local first_char = string.sub(text, 1, 1)
										local remainder = string.sub(text, 2, -1)
										player.gui.left[size.."-"..material].plates_input.text = remainder
										replace_name = size.."-"..material.."-"..item_suffix_from_char(first_char)
										prep_next_symbol(player_index)
									end
								end

								if replace_name ~= entity.name then
									-- replace
									local replacement = entity.surface.create_entity{ name=replace_name,  position=entity.position, force=entity.force}
									replacement.operable = false
									script.raise_event(defines.events.on_built_entity,
									{
									   tick = event.tick,
									   name = defines.events.on_built_entity,
									   created_entity = replacement,
									   player_index = player_index,
									   mod = modname,
									   is_replacement = true,
									   replaced_unit_number = entity.unit_number
									})
									if entity.valid then entity.destroy() end
									return
								end
							end
						end
					end
				end
			end
		end
	end
end

local function on_robot_built_entity (event)
	local entity = event.created_entity
	if entity.valid then -- in case of other scripts
		for _, material in ipairs(textplates.materials) do
			for _, size in ipairs(textplates.sizes) do
				if entity.name == size.."-"..material.."-blank" then
					entity.operable = false
					local replace_name = entity.get_control_behavior().parameters.parameters[1].signal.name
					for _, symbol in ipairs(textplates.symbols) do
						if replace_name == size.."-"..material.."-"..symbol then
							local replacement = entity.surface.create_entity{ name=replace_name, position=entity.position, force=entity.force}
							replacement.operable = false
							script.raise_event(defines.events.on_robot_built_entity,
							{
							   tick = event.tick,
							   name = defines.events.on_robot_built_entity,
							   created_entity = replacement,
							   robot = event.robot,
							   mod = modname,
							   is_replacement = true,
							   replaced_unit_number = entity.unit_number
							})
							if entity.valid then entity.destroy() end
							return
						end
					end
				end
			end
		end
	end
end

local function on_entity_died (event)
    local entity = event.entity
    if entity.valid then -- in case of other scripts
        for _, material in ipairs(textplates.materials) do
            for _, size in ipairs(textplates.sizes) do
                for _, symbol in ipairs(textplates.symbols) do
                    if entity.name == size.."-"..material.."-"..symbol then
                        local replacement = entity.surface.create_entity{
                          name = "entity-ghost",
                          inner_name = size.."-"..material.."-blank",
                          position = entity.position,
                          force = entity.force,
                          expires = false
                        }
                        replacement.get_control_behavior().parameters={parameters={{signal={type="item",name=entity.name},count=0,index=1}}}
                        replacement.operable = false
                        script.raise_event(defines.events.on_robot_built_entity,
                            {
                                robot = {},
                                tick = event.tick,
                                name = defines.events.on_robot_built_entity,
                                created_entity = replacement,
                                player_index = event.player_index,
                                mod = modname,
                                is_replacement = true,
                                replaced_unit_number = entity.unit_number
                            })
                        if entity.valid then entity.destroy() end
                        return
                    end
                end
            end
        end
    end
end

local function on_entity_revived(event)
    local entity = event.entity
    if not entity.valid then return end -- in case of other scripts

    for _, material in ipairs(textplates.materials) do
        for _, size in ipairs(textplates.sizes) do
            if entity.name == size.."-"..material.."-blank" then
                entity.operable = false
                local replace_name = entity.get_control_behavior().parameters.parameters[1].signal.name
                for _, symbol in ipairs(textplates.symbols) do
                    if replace_name == size.."-"..material.."-"..symbol then
                        local replacement = entity.surface.create_entity{ name=replace_name, position=entity.position, force=entity.force}
                        replacement.operable = false
                        script.raise_event(defines.events.on_robot_built_entity,
                            {
                                robot = {},
                                tick = event.tick,
                                name = defines.events.on_robot_built_entity,
                                created_entity = replacement,
                                player_index = event.player_index,
                                mod = modname,
                                is_replacement = true,
                                replaced_unit_number = entity.unit_number
                            })
                        return replacement -- return replacement
                    end
                end
            end
        end
    end
end

script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity)
script.on_event(defines.events.on_entity_died, on_entity_died)

remote.add_interface("textplates", {
	on_entity_revived = function(data) return on_entity_revived(data) end,
})
