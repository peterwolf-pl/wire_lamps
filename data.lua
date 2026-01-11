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
local function scale_sprite(sprite, scale)
  if not sprite then
    return
  end
  if sprite.layers then
    for _, layer in pairs(sprite.layers) do
      layer.scale = scale
    end
    return
  end
  sprite.scale = scale
end

scale_sprite(lamp.picture_on, 0.5)
scale_sprite(lamp.picture_off, 0.5)

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
