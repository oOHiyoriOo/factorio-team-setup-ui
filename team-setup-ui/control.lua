-- Team Setup UI Main Control Module
-- Handles event registration and dispatching
-- Requires Factorio 2.0+

local team_manager = require("modules/team-manager")
local gui_manager = require("modules/gui-manager")
local config = require("modules/config")

-- Initialize mod on first load
script.on_init(function()
  config.init_storage()
  log("Team Setup UI initialized")
end)

-- Handle configuration changes
script.on_configuration_changed(function(data)
  config.migrate()
end)

-- Player commands and UI interactions
script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player and player.admin then
    player.print("Team Setup UI loaded. Use /team-ui to open the team management interface.")
  end
end)

-- Validate admin player for GUI events
local function validate_admin_event(event)
  if not event.element or not event.element.valid then return nil end
  local player = game.get_player(event.player_index)
  return (player and player.admin) and player or nil
end

-- Handle player left the game
script.on_event(defines.events.on_player_left_game, function(event)
  if storage.gui then
    storage.gui[event.player_index] = nil
  end
end)

-- Register command
commands.add_command("team-ui", "Opens the Team Setup UI (admin only)", function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  
  if not player.admin then
    player.print("[Team Setup UI] Error: You must be an admin to use this command", {r=1, g=0, b=0})
    return
  end
  
  gui_manager.toggle_main_ui(player)
end)

-- Register events for GUI interactions
script.on_event(defines.events.on_gui_click, function(event)
  local player = validate_admin_event(event)
  if player then gui_manager.handle_gui_click(event, player) end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = validate_admin_event(event)
  if player then gui_manager.handle_gui_text_changed(event, player) end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
  local player = validate_admin_event(event)
  if player then gui_manager.handle_gui_selection_changed(event, player) end
end)

-- Handle GUI close button
script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "team_setup_main_frame" then
    local player = game.get_player(event.player_index)
    if player then
      gui_manager.close_ui(player)
    end
  end
end)

-- Compatibility: Factorio 2.0+ uses different event names where applicable
-- This mod maintains compatibility with both 1.1 and 2.0+ event names

log("Team Setup UI Control Module loaded successfully")
