local function lamp_key(a, b)
  if a < b then
    return a .. "-" .. b
  end
  return b .. "-" .. a
end

local function destroy_all_lamps()
  if not global.lamps then
    return
  end
  for _, entry in pairs(global.lamps) do
    if entry.entity and entry.entity.valid then
      entry.entity.destroy()
    end
  end
  global.lamps = {}
end

local function ensure_tables()
  global.lamps = global.lamps or {}
  global.enabled = global.enabled or false
end

local function create_lamp_for_connection(pole, neighbor)
  if not (pole and pole.valid and neighbor and neighbor.valid) then
    return
  end
  if pole.surface.index ~= neighbor.surface.index then
    return
  end
  if pole.unit_number == nil or neighbor.unit_number == nil then
    return
  end

  local key = lamp_key(pole.unit_number, neighbor.unit_number)
  if global.lamps[key] and global.lamps[key].entity and global.lamps[key].entity.valid then
    return
  end

  local midpoint = {
    (pole.position.x + neighbor.position.x) / 2,
    (pole.position.y + neighbor.position.y) / 2,
  }

  local lamp = pole.surface.create_entity({
    name = "wire-lamp",
    position = midpoint,
    force = pole.force,
  })

  if lamp then
    global.lamps[key] = {entity = lamp, surface_index = pole.surface.index}
  end
end

local function rebuild_lamps()
  destroy_all_lamps()
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered({type = "electric-pole"})) do
      if pole.neighbours and pole.neighbours.copper then
        for _, neighbor in pairs(pole.neighbours.copper) do
          create_lamp_for_connection(pole, neighbor)
        end
      end
    end
  end
end

local function set_enabled(player, enabled)
  global.enabled = enabled
  player.set_shortcut_toggled("wire-lamps-toggle", enabled)
  if enabled then
    rebuild_lamps()
  else
    destroy_all_lamps()
  end
end

script.on_init(function()
  ensure_tables()
end)

script.on_configuration_changed(function()
  ensure_tables()
  if global.enabled then
    rebuild_lamps()
  else
    destroy_all_lamps()
  end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= "wire-lamps-toggle" then
    return
  end
  ensure_tables()
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  set_enabled(player, not global.enabled)
end)

local function handle_pole_change()
  if not global.enabled then
    return
  end
  rebuild_lamps()
end

local wire_connection_event = defines.events.on_wire_connection_changed
if wire_connection_event then
  script.on_event(wire_connection_event, handle_pole_change)
end

script.on_event(
  {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.on_entity_cloned,
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
  },
  function(event)
    local entity = event.created_entity or event.entity
    if not (entity and entity.valid) then
      return
    end
    if entity.type ~= "electric-pole" then
      return
    end
    handle_pole_change()
  end
)
