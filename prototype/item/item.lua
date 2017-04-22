local count = 0
for _, material in ipairs(textplates.materials) do
	for _, size in ipairs(textplates.sizes) do
		for _, symbol in ipairs(textplates.symbols) do
			count = count + 1
			item = { 
					type = "item",
					name = size.."-"..material.."-"..symbol,
					icon = "__textplates__/graphics/icon/"..size.."/"..material.."_"..symbol..".png",
					flags = {"goes-to-quickbar"},
					subgroup = "terrain",
					order = "e[tileplates]-"..string.format( "%03d", count ),
					stack_size = 50,
					place_result = size.."-"..material.."-"..symbol,
					localised_name = { "item-name.text-plate", { size }, { material }, { symbol } }
				}
			if(symbol ~= "blank") then
				item.flags = {"goes-to-quickbar","hidden"}
			end
			data:extend({ item })
		end
	end
end
