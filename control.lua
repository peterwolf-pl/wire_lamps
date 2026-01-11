local function lamp_key(a, b)
  if a < b then
    return a .. "-" .. b
  end
  return b .. "-" .. a
end

local function destroy_all_lamps()
  if not global or not global.lamps then
    return
  end
  for _, entry in pairs(global.lamps) do
    local entities = entry.entities or {}
    if entry.entity then
      table.insert(entities, entry.entity)
    end
    for _, entity in pairs(entities) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
  end
  global.lamps = {}
end

local function ensure_tables()
  if not global then
    global = {}
  end
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
  local existing = global.lamps[key]
  if existing and existing.entities then
    local all_valid = true
    for _, entity in pairs(existing.entities) do
      if not (entity and entity.valid) then
        all_valid = false
        break
      end
    end
    if all_valid then
      return
    end
    for _, entity in pairs(existing.entities) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
  end

  local positions = {}
  if pole.name == "small-electric-pole" and neighbor.name == "small-electric-pole" then
    table.insert(positions, {
      pole.position.x + (neighbor.position.x - pole.position.x) / 3,
      pole.position.y + (neighbor.position.y - pole.position.y) / 3,
    })
    table.insert(positions, {
      pole.position.x + (neighbor.position.x - pole.position.x) * 2 / 3,
      pole.position.y + (neighbor.position.y - pole.position.y) * 2 / 3,
    })
  else
    table.insert(positions, {
      (pole.position.x + neighbor.position.x) / 2,
      (pole.position.y + neighbor.position.y) / 2,
    })
  end

  local entities = {}
  for _, position in pairs(positions) do
    local lamp = pole.surface.create_entity({
      name = "wire-lamp",
      position = position,
      force = pole.force,
    })
    if lamp then
      table.insert(entities, lamp)
    end
  end

  if #entities > 0 then
    global.lamps[key] = {entities = entities, surface_index = pole.surface.index}
  end
end

local function rebuild_lamps()
  destroy_all_lamps()
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered({type = "electric-pole"})) do
      local ok, neighbours = pcall(function()
        return pole.neighbours
      end)
      if ok and neighbours and neighbours.copper then
        for _, neighbor in pairs(neighbours.copper) do
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
