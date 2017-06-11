local function text_blank_sprite()
  return {
      filename = "__textplates__/graphics/blank.png",
      width = 1,
      height = 1,
      frame_count = 1,
      shift = {0, 0},
  }
end
local function text_sprite(size, material, symbol)
  local object =  {
      filename = "__textplates__/graphics/entity/large/"..material.."_"..symbol..".png",
      priority = "extra-high",
      width = 64,
      height = 64,
      frame_count = 1,
      scale = 0.5,
      shift = {0, 0},
  }
  if(size == "large") then
    object.scale = 1
  end
  return object
end
local function text_connections()
  return { shadow = { red = {0, 0}, green = {0, 0}, }, wire = { red = {0, 0}, green = {0, 0}, } }
end
for _, material in ipairs(textplates.materials) do
  for _, size in ipairs(textplates.sizes) do
    for _, symbol in ipairs(textplates.symbols) do
      local entity = {
        name = size.."-"..material.."-"..symbol,
        icon = "__textplates__/graphics/icon/"..size.."/"..material.."_"..symbol..".png",
        flags = {"placeable-neutral", "player-creation"},
        minable = {count=1, hardness = 0.2, mining_time = 0.25, result=size.."-"..material.."-blank"}, -- default
        render_layer = "floor",
        max_health = 25,
        collision_box = {{-0.45, -0.45}, {0.45, 0.45}},
        collision_mask = { "floor-layer", "water-tile" }, -- this does not work ... yet
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        corpse = "small-remnants",
        item_slot_count = 0,
        resistances =
        {
         {
           type = "fire",
           percent = 80
         }
        },
        localised_name = { "entity-name.text-plate", { "textplates."..size }, {"textplates.".. material }, { "textplates."..symbol } }
      }

      if(symbol == "blank") then -- add constant slot
         entity.type = "constant-combinator"
         entity.sprites =
          {
            north = text_sprite(size, material, symbol),
            east = text_sprite(size, material, symbol),
            south = text_sprite(size, material, symbol),
            west = text_sprite(size, material, symbol)
          }
          entity.activity_led_sprites =
          {
            north = text_blank_sprite(),
            east = text_blank_sprite(),
            south = text_blank_sprite(),
            west = text_blank_sprite()
          }
          entity.activity_led_light = { intensity = 0.8, size = 1, }
          entity.activity_led_light_offsets = {  {0, 0}, {0, 0}, {0, 0}, {0, 0} }
          entity.circuit_wire_connection_points = {
            text_connections(),
            text_connections(),
            text_connections(),
            text_connections()
          }
          entity.circuit_wire_max_distance = 0
          entity.item_slot_count = 1
      else
       entity.type = "simple-entity-with-force"
       entity.picture = text_sprite(size, material, symbol)
      end

      if(size == "large") then
        entity.corpse = "medium-remnants"
        entity.max_health = 100
        entity.collision_box = {{-0.9, -0.9}, {0.9, 0.9}}
        entity.selection_box = {{-1, -1}, {1, 1}}
        entity.minable.mining_time = 0.5
      end
      data:extend({entity})
    end
  end
end
