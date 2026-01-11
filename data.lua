local lamp = table.deepcopy(data.raw["lamp"]["small-lamp"])

lamp.name = "wire-lamp"
lamp.icon = "__base__/graphics/icons/small-lamp.png"
lamp.icon_size = 64
lamp.minable = nil
lamp.placeable_by = nil
lamp.flags = {"placeable-off-grid", "not-on-map", "hidden"}
lamp.selection_box = {{0, 0}, {0, 0}}
lamp.collision_box = {{0, 0}, {0, 0}}
lamp.collision_mask = {}
lamp.selectable_in_game = false
lamp.energy_usage_per_tick = "1KW"
lamp.light = {intensity = 0.6, size = 12, color = {r = 1, g = 0.95, b = 0.85}}
lamp.picture_on.layers[1].scale = 0.5
lamp.picture_off.layers[1].scale = 0.5

if lamp.picture_on.layers[2] then
  lamp.picture_on.layers[2].scale = 0.5
end

if lamp.picture_off.layers[2] then
  lamp.picture_off.layers[2].scale = 0.5
end

local shortcut = {
  type = "shortcut",
  name = "wire-lamps-toggle",
  action = "lua",
  toggleable = true,
  icon = "__base__/graphics/icons/small-lamp.png",
  icon_size = 64,
  order = "w[wire-lamps]",
}

data:extend({lamp, shortcut})
