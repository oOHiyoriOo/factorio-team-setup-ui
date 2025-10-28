-- GUI Manager Module
-- Handles the admin UI interface for team management

local gui_manager = {}
local team_manager = require("modules/team-manager")

-- Colors for UI
local COLOR = {
  BACKGROUND = {r = 0.15, g = 0.15, b = 0.15},
  TITLE = {r = 1, g = 0.84, b = 0},
  SUCCESS = {r = 0, g = 1, b = 0},
  ERROR = {r = 1, g = 0, b = 0},
  BUTTON = {r = 0.2, g = 0.55, b = 0.9}
}

-- Helper: Print colored message to player
local function print_message(player, message, color)
  player.print("[Team Setup UI] " .. message, color or COLOR.SUCCESS)
end

-- Helper: Print error message to player
local function print_error(player, message)
  print_message(player, "Error: " .. message, COLOR.ERROR)
end

-- Helper: Get GUI frame
local function get_main_frame(player)
  return player.gui.center["team_setup_main_frame"]
end

-- Helper: Get tab content by tab name
local function get_tab_content(player, tab_name)
  local frame = get_main_frame(player)
  if not frame or not frame.valid then return nil end
  
  local tabs = frame["team_setup_tabs"]
  if not tabs then return nil end
  
  -- Find the content flow by name
  for _, child in pairs(tabs.children) do
    if child.name == tab_name .. "_tab_content" then
      return child
    end
  end
  
  return nil
end

-- Helper: Create dropdown with items
local function create_dropdown(parent, name, items, selected_index)
  local dropdown = parent.add{
    type = "drop-down",
    name = name,
    items = items
  }
  dropdown.selected_index = selected_index or 1
  return dropdown
end

-- Helper: Create button with color
local function create_button(parent, name, caption, color)
  local button = parent.add{
    type = "button",
    name = name,
    caption = caption
  }
  button.style.font_color = color or COLOR.BUTTON
  return button
end

-- Helper: Get team names as list
local function get_team_names()
  local teams = team_manager.get_all_teams()
  local names = {}
  for _, team in ipairs(teams) do
    table.insert(names, team.name)
  end
  return names
end

-- Helper: Get surface names as list
local function get_surface_names()
  local names = {}
  for _, surface in pairs(game.surfaces) do
    table.insert(names, surface.name)
  end
  return names
end

-- Helper: Build two-team relation section
local function build_relation_section(content, title, dropdown1_name, dropdown2_name, enable_btn_name, disable_btn_name)
  local section = content.add{
    type = "frame",
    direction = "vertical",
    caption = title
  }
  section.style.margin = 5
  
  local flow = section.add{
    type = "flow",
    direction = "horizontal"
  }
  flow.style.margin = 5
  
  local team_names = get_team_names()
  flow.add{ type = "label", caption = "Team 1:" }
  create_dropdown(flow, dropdown1_name, team_names, 1)
  
  flow.add{ type = "label", caption = "Team 2:" }
  create_dropdown(flow, dropdown2_name, team_names, math.min(2, #team_names))
  
  create_button(flow, enable_btn_name, "Enable", COLOR.SUCCESS)
  create_button(flow, disable_btn_name, "Disable", COLOR.ERROR)
end

-- Initialize GUI storage
function gui_manager.init_storage()
  storage.gui = storage.gui or {}
end

-- Import existing custom forces into storage
local function import_existing_forces()
  storage.teams = storage.teams or {}
  
  -- Import existing custom forces that aren't tracked yet
  local default_forces = {player = true, enemy = true, neutral = true}
  for force_name, force in pairs(game.forces) do
    if not default_forces[force_name] and not storage.teams[force_name] then
      log("Importing existing force: " .. force_name)
      storage.teams[force_name] = {
        name = force_name,
        created_at = game.tick,
        spawn_position = {x = 0, y = 0},
        spawn_surface = "nauvis",
        description = "Imported from existing game"
      }
    end
  end
end

-- Close UI for a player
function gui_manager.close_ui(player)
  local player_index = player.index
  if storage.gui[player_index] and storage.gui[player_index].main_frame and storage.gui[player_index].main_frame.valid then
    storage.gui[player_index].main_frame.destroy()
    storage.gui[player_index] = nil
  end
end

-- Create or toggle main UI
function gui_manager.toggle_main_ui(player)
  gui_manager.init_storage()
  
  -- Ensure all existing custom forces are tracked
  import_existing_forces()
  
  local player_index = player.index
  
  -- Close if already open
  if storage.gui[player_index] and storage.gui[player_index].main_frame and storage.gui[player_index].main_frame.valid then
    gui_manager.close_ui(player)
    return
  end
  
  -- Create main frame
  local main_frame = player.gui.center.add{
    type = "frame",
    name = "team_setup_main_frame",
    direction = "vertical"
  }
  main_frame.style.maximal_width = 800
  
  -- Add title bar with close button
  local title_bar = main_frame.add{
    type = "flow",
    direction = "horizontal"
  }
  title_bar.style.horizontal_spacing = 8
  title_bar.style.vertically_stretchable = false
  
  local title_label = title_bar.add{
    type = "label",
    caption = "Team Setup UI"
  }
  title_label.style.font = "heading-2"
  title_label.style.font_color = COLOR.TITLE
  
  -- Spacer to push close button to the right
  local spacer = title_bar.add{
    type = "empty-widget"
  }
  spacer.style.horizontally_stretchable = true
  spacer.style.height = 28
  
  -- Close button
  local close_button = title_bar.add{
    type = "sprite-button",
    name = "team_ui_close_button",
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = "Close"
  }
  
  -- Create tabbed pane
  local tabs = main_frame.add{
    type = "tabbed-pane",
    name = "team_setup_tabs"
  }
  
  -- Helper to add tab
  local function add_tab(caption, content_name, build_func)
    local tab = tabs.add{ type = "tab", caption = caption }
    local content = tabs.add{ type = "flow", name = content_name, direction = "vertical" }
    tabs.add_tab(tab, content)
    build_func(content, player_index)
  end
  
  add_tab("Teams", "teams_tab_content", gui_manager.build_teams_tab)
  add_tab("Assign Players", "players_tab_content", gui_manager.build_players_tab)
  add_tab("Relations", "relations_tab_content", gui_manager.build_relations_tab)
  
  -- Store reference
  storage.gui[player_index] = storage.gui[player_index] or {}
  storage.gui[player_index].main_frame = main_frame
end

-- Build teams tab
function gui_manager.build_teams_tab(content, player_index)
  content.clear()
  
  -- Create new team section
  local create_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Create New Team"
  }
  create_section.style.margin = 5
  
  local input_flow = create_section.add{ type = "flow", direction = "horizontal" }
  input_flow.style.margin = 5
  
  input_flow.add{ type = "label", caption = "Team Name:" }
  local team_name_input = input_flow.add{
    type = "textfield",
    name = "team_name_input",
    text = ""
  }
  team_name_input.style.width = 150
  create_button(input_flow, "create_team_button", "Create Team", COLOR.BUTTON)
  
  -- List existing teams
  local teams_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Existing Teams"
  }
  teams_section.style.margin = 5
  
  local teams = team_manager.get_all_teams()
  
  if #teams == 0 then
    teams_section.add{ type = "label", caption = "No teams created yet" }
  else
    for _, team in ipairs(teams) do
      local team_flow = teams_section.add{ type = "flow", direction = "horizontal" }
      team_flow.style.margin = 5
      team_flow.add{ type = "label", caption = team.name .. " (" .. team.player_count .. " players)" }
      create_button(team_flow, "delete_team_button_" .. team.name, "Delete", COLOR.ERROR)
    end
  end
end

-- Build players tab
function gui_manager.build_players_tab(content, player_index)
  content.clear()
  
  local info_label = content.add{ type = "label", caption = "Assign players to teams" }
  info_label.style.margin = 5
  
  local teams = team_manager.get_all_teams()
  
  if #teams == 0 then
    content.add{ type = "label", caption = "No teams available. Create a team first.", style = "bold_label" }
    return
  end
  
  -- Build dropdown items
  local dropdown_items = {"-- Select Team --"}
  for _, team in ipairs(teams) do
    table.insert(dropdown_items, team.name)
  end
  
  -- List all players
  for _, player in ipairs(game.connected_players) do
    local player_flow = content.add{ type = "flow", direction = "horizontal" }
    player_flow.style.margin = 5
    
    player_flow.add{
      type = "label",
      caption = player.name .. " (currently in: " .. player.force.name .. ")"
    }
    
    -- Find current team index
    local selected_index = 1
    for idx, team in ipairs(teams) do
      if player.force.name == team.name then
        selected_index = idx + 1  -- +1 because of "-- Select Team --"
        break
      end
    end
    
    create_dropdown(player_flow, "player_team_dropdown_" .. player.name, dropdown_items, selected_index)
    create_button(player_flow, "assign_player_button_" .. player.name, "Assign", COLOR.BUTTON)
  end
end

-- Build relations tab
function gui_manager.build_relations_tab(content, player_index)
  content.clear()
  
  local teams = team_manager.get_all_teams()
  
  if #teams < 2 then
    content.add{ type = "label", caption = "Need at least 2 teams to set relations", style = "bold_label" }
    return
  end
  
  local team_names = get_team_names()
  
  -- Cease fire section
  local ceasefire_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Cease Fire (Prevent Turret Targeting)"
  }
  ceasefire_section.style.margin = 5
  
  local ceasefire_flow = ceasefire_section.add{ type = "flow", direction = "horizontal" }
  ceasefire_flow.style.margin = 5
  
  ceasefire_flow.add{ type = "label", caption = "Team 1:" }
  create_dropdown(ceasefire_flow, "ceasefire_team1_dropdown", team_names, 1)
  ceasefire_flow.add{ type = "label", caption = "Team 2:" }
  create_dropdown(ceasefire_flow, "ceasefire_team2_dropdown", team_names, math.min(2, #team_names))
  
  -- Button container for cease fire
  local ceasefire_button_flow = ceasefire_flow.add{
    type = "flow",
    name = "ceasefire_button_container",
    direction = "horizontal"
  }
  
  -- Allied access section
  local allied_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Allied Access (Buildings & Vehicles)"
  }
  allied_section.style.margin = 5
  
  local allied_flow = allied_section.add{ type = "flow", direction = "horizontal" }
  allied_flow.style.margin = 5
  
  allied_flow.add{ type = "label", caption = "Team 1:" }
  create_dropdown(allied_flow, "allied_team1_dropdown", team_names, 1)
  allied_flow.add{ type = "label", caption = "Team 2:" }
  create_dropdown(allied_flow, "allied_team2_dropdown", team_names, math.min(2, #team_names))
  
  -- Button container for allied
  local allied_button_flow = allied_flow.add{
    type = "flow",
    name = "allied_button_container",
    direction = "horizontal"
  }
  
  -- Map vision section (single team)
  local vision_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Map Vision Sharing"
  }
  vision_section.style.margin = 5
  
  local vision_flow = vision_section.add{ type = "flow", direction = "horizontal" }
  vision_flow.style.margin = 5
  
  vision_flow.add{ type = "label", caption = "Team:" }
  create_dropdown(vision_flow, "vision_team_dropdown", team_names, 1)
  
  -- Button container for vision
  local vision_button_flow = vision_flow.add{
    type = "flow",
    name = "vision_button_container",
    direction = "horizontal"
  }
  
  -- Update buttons based on initial selection
  gui_manager.update_relation_buttons(content, player_index)
end

-- Update relation buttons based on current team selections
function gui_manager.update_relation_buttons(content, player_index)
  if not content or not content.valid then return end
  
  -- Helper to update button container
  local function update_buttons(container, is_enabled, enable_name, disable_name)
    if not container or not container.valid then return end
    container.clear()
    
    if is_enabled then
      create_button(container, disable_name, "Disable", COLOR.ERROR)
    else
      create_button(container, enable_name, "Enable", COLOR.SUCCESS)
    end
  end
  
  -- Update cease fire buttons
  local ceasefire_container = nil
  local allied_container = nil
  local vision_container = nil
  
  for _, child in pairs(content.children) do
    if child.type == "frame" then
      for _, flow_child in pairs(child.children) do
        if flow_child.type == "flow" then
          if flow_child["ceasefire_button_container"] then
            ceasefire_container = flow_child["ceasefire_button_container"]
            local team1_dropdown = flow_child["ceasefire_team1_dropdown"]
            local team2_dropdown = flow_child["ceasefire_team2_dropdown"]
            
            if team1_dropdown and team2_dropdown and team1_dropdown.valid and team2_dropdown.valid then
              local team1 = team1_dropdown.items[team1_dropdown.selected_index]
              local team2 = team2_dropdown.items[team2_dropdown.selected_index]
              
              if team1 and team2 and team1 ~= team2 then
                local force1 = game.forces[team1]
                local force2 = game.forces[team2]
                local is_ceasefire = force1 and force2 and force1.get_cease_fire(force2)
                update_buttons(ceasefire_container, is_ceasefire, "ceasefire_enable_button", "ceasefire_disable_button")
              end
            end
          end
          
          if flow_child["allied_button_container"] then
            allied_container = flow_child["allied_button_container"]
            local team1_dropdown = flow_child["allied_team1_dropdown"]
            local team2_dropdown = flow_child["allied_team2_dropdown"]
            
            if team1_dropdown and team2_dropdown and team1_dropdown.valid and team2_dropdown.valid then
              local team1 = team1_dropdown.items[team1_dropdown.selected_index]
              local team2 = team2_dropdown.items[team2_dropdown.selected_index]
              
              if team1 and team2 and team1 ~= team2 then
                local force1 = game.forces[team1]
                local force2 = game.forces[team2]
                local is_friend = force1 and force2 and force1.get_friend(force2)
                update_buttons(allied_container, is_friend, "allied_enable_button", "allied_disable_button")
              end
            end
          end
          
          if flow_child["vision_button_container"] then
            vision_container = flow_child["vision_button_container"]
            local team_dropdown = flow_child["vision_team_dropdown"]
            
            if team_dropdown and team_dropdown.valid then
              local team_name = team_dropdown.items[team_dropdown.selected_index]
              if team_name then
                local force = game.forces[team_name]
                local is_shared = force and force.share_chart
                update_buttons(vision_container, is_shared, "vision_enable_button", "vision_disable_button")
              end
            end
          end
        end
      end
    end
  end
end

-- Build settings tab
function gui_manager.build_settings_tab(content, player_index)
  content.clear()
  
  local spawn_section = content.add{
    type = "frame",
    direction = "vertical",
    caption = "Spawn Point Configuration"
  }
  spawn_section.style.margin = 5
  
  local teams = team_manager.get_all_teams()
  
  if #teams == 0 then
    spawn_section.add{ type = "label", caption = "No teams available" }
    return
  end
  
  -- Team selection dropdown
  local selection_flow = spawn_section.add{ type = "flow", direction = "horizontal" }
  selection_flow.style.margin = 5
  selection_flow.add{ type = "label", caption = "Select Team:" }
  
  local team_names = get_team_names()
  create_dropdown(selection_flow, "settings_team_dropdown", team_names, 1)
  
  -- Get initial team info
  local initial_team = teams[1]
  local team_info = team_manager.get_team_info(initial_team.name)
  
  -- Position configuration container
  local config_container = spawn_section.add{
    type = "flow",
    name = "spawn_config_container",
    direction = "vertical"
  }
  config_container.style.margin = 5
  
  -- Build spawn configuration for the selected team
  gui_manager.build_spawn_config(config_container, team_info, player_index)
end

-- Build spawn configuration for a specific team
function gui_manager.build_spawn_config(container, team_info, player_index)
  container.clear()
  
  local coords_flow = container.add{ type = "flow", direction = "horizontal" }
  coords_flow.style.margin = 5
  
  coords_flow.add{ type = "label", caption = "X:" }
  local spawn_x = coords_flow.add{
    type = "textfield",
    name = "spawn_x",
    text = tostring(math.floor(team_info.spawn_position.x)),
    numeric = true
  }
  spawn_x.style.width = 80
  
  coords_flow.add{ type = "label", caption = "Y:" }
  local spawn_y = coords_flow.add{
    type = "textfield",
    name = "spawn_y",
    text = tostring(math.floor(team_info.spawn_position.y)),
    numeric = true
  }
  spawn_y.style.width = 80
  
  coords_flow.add{ type = "label", caption = "Surface:" }
  
  -- Find surface index
  local surface_names = get_surface_names()
  local surface_index = 1
  for idx, surface_name in ipairs(surface_names) do
    if surface_name == team_info.spawn_surface then
      surface_index = idx
      break
    end
  end
  
  create_dropdown(coords_flow, "spawn_surface", surface_names, surface_index)
  
  -- Buttons flow
  local buttons_flow = container.add{ type = "flow", direction = "horizontal" }
  buttons_flow.style.margin = 5
  buttons_flow.style.horizontal_spacing = 8
  
  create_button(buttons_flow, "get_position_button", "Get Current Position", COLOR.SUCCESS)
  create_button(buttons_flow, "set_spawn_button", "Set Spawn", COLOR.BUTTON)
end

-- Helper: Get two team names from dropdowns by searching the hierarchy
local function get_two_teams(tab_content, dropdown1_name, dropdown2_name)
  local dropdown1, dropdown2 = nil, nil
  
  -- Search through tab content hierarchy to find the dropdowns
  for _, child in pairs(tab_content.children) do
    if child.type == "frame" then
      for _, flow in pairs(child.children) do
        if flow.type == "flow" then
          if flow[dropdown1_name] then
            dropdown1 = flow[dropdown1_name]
          end
          if flow[dropdown2_name] then
            dropdown2 = flow[dropdown2_name]
          end
        end
      end
    end
  end
  
  if not dropdown1 or not dropdown1.valid or not dropdown2 or not dropdown2.valid then
    return nil, nil
  end
  
  local team1 = dropdown1.items[dropdown1.selected_index]
  local team2 = dropdown2.items[dropdown2.selected_index]
  
  return team1, team2
end

-- Helper: Execute team action and print result
local function execute_team_action(player, action_func, ...)
  local success, msg = action_func(...)
  if success then
    print_message(player, msg)
  else
    print_error(player, msg)
  end
  return success
end

-- Handle GUI click events
function gui_manager.handle_gui_click(event, player)
  local element = event.element
  local name = element.name
  
  -- Close button
  if name == "team_ui_close_button" then
    gui_manager.close_ui(player)
    return
  end
  
  -- Create team button
  if name == "create_team_button" then
    -- Get the input from the same parent flow as the button
    local input_flow = element.parent
    
    if input_flow and input_flow.valid then
      local input = input_flow["team_name_input"]
      
      if input and input.valid and input.text ~= "" then
        if execute_team_action(player, team_manager.create_team, input.text) then
          -- Update Teams tab
          local teams_content = get_tab_content(player, "teams")
          if teams_content then
            gui_manager.build_teams_tab(teams_content, event.player_index)
          end
          
          -- Update Assign Players tab
          local players_content = get_tab_content(player, "players")
          if players_content then
            gui_manager.build_players_tab(players_content, event.player_index)
          end
          
          -- Update Relations tab
          local relations_content = get_tab_content(player, "relations")
          if relations_content then
            gui_manager.build_relations_tab(relations_content, event.player_index)
          end
        end
      else
        print_error(player, "Team name cannot be empty")
      end
    end
    
  -- Delete team button
  elseif name:find("^delete_team_button_") then
    local team_name = name:sub(20)
    if execute_team_action(player, team_manager.delete_team, team_name) then
      -- Update Teams tab
      local teams_content = get_tab_content(player, "teams")
      if teams_content then
        gui_manager.build_teams_tab(teams_content, event.player_index)
      end
      
      -- Update Assign Players tab
      local players_content = get_tab_content(player, "players")
      if players_content then
        gui_manager.build_players_tab(players_content, event.player_index)
      end
      
      -- Update Relations tab
      local relations_content = get_tab_content(player, "relations")
      if relations_content then
        gui_manager.build_relations_tab(relations_content, event.player_index)
      end
    end
    
  -- Assign player button
  elseif name:find("^assign_player_button_") then
    local player_name = name:match("^assign_player_button_(.+)$")
    
    -- Get the dropdown from the same parent flow as the button
    local player_flow = element.parent
    
    if player_flow and player_flow.valid then
      local dropdown = player_flow["player_team_dropdown_" .. player_name]
      
      if dropdown and dropdown.valid and dropdown.selected_index > 1 then
        local team_name = dropdown.items[dropdown.selected_index]
        if execute_team_action(player, team_manager.assign_player_to_team, player_name, team_name) then
          local tab_content = get_tab_content(player, "players")
          if tab_content then
            gui_manager.build_players_tab(tab_content, event.player_index)
          end
        end
      else
        print_error(player, "Please select a team")
      end
    end
    
  -- Set spawn button
  elseif name:find("^set_spawn_button_") then
    local team_name = name:sub(18)
    local tab_content = get_tab_content(player, "settings")
    local x_field = tab_content and tab_content["spawn_x_" .. team_name]
    local y_field = tab_content and tab_content["spawn_y_" .. team_name]
    local surface_dropdown = tab_content and tab_content["spawn_surface_" .. team_name]
    
    if x_field and y_field and surface_dropdown then
      local x = tonumber(x_field.text) or 0
      local y = tonumber(y_field.text) or 0
      local surface_name = surface_dropdown.items[surface_dropdown.selected_index]
      execute_team_action(player, team_manager.set_spawn_position, team_name, x, y, surface_name)
    end
    
  -- Get Position button
  elseif name == "get_position_button" then
    game.print("Get Position button clicked")
    local tab_content = get_tab_content(player, "settings")
    game.print("Tab content: " .. tostring(tab_content and tab_content.valid))
    if tab_content then
      local spawn_config = tab_content["spawn_config_container"]
      game.print("Spawn config: " .. tostring(spawn_config and spawn_config.valid))
      if spawn_config and spawn_config.valid then
        -- Find elements in the nested flows
        local spawn_x, spawn_y, spawn_surface = nil, nil, nil
        for _, child in pairs(spawn_config.children) do
          game.print("Child type: " .. child.type)
          if child.type == "flow" then
            for _, element in pairs(child.children) do
              game.print("Element name: " .. tostring(element.name))
              if element.name == "spawn_x" then spawn_x = element end
              if element.name == "spawn_y" then spawn_y = element end
              if element.name == "spawn_surface" then spawn_surface = element end
            end
          end
        end
        
        game.print("Found elements - X: " .. tostring(spawn_x and spawn_x.valid) .. ", Y: " .. tostring(spawn_y and spawn_y.valid) .. ", Surface: " .. tostring(spawn_surface and spawn_surface.valid))
        
        if spawn_x and spawn_x.valid and spawn_y and spawn_y.valid and spawn_surface and spawn_surface.valid then
          local pos = player.position
          spawn_x.text = tostring(math.floor(pos.x))
          spawn_y.text = tostring(math.floor(pos.y))
          
          -- Set surface dropdown to current surface
          local surface_names = get_surface_names()
          for idx, surface_name in ipairs(surface_names) do
            if surface_name == player.surface.name then
              spawn_surface.selected_index = idx
              break
            end
          end
          
          print_message(player, "Position captured: [" .. spawn_x.text .. ", " .. spawn_y.text .. "] on " .. player.surface.name)
        end
      end
    end
    
  -- Set Spawn button
  elseif name == "set_spawn_button" then
    local tab_content = get_tab_content(player, "settings")
    if tab_content then
      local team_dropdown = tab_content["settings_team_dropdown"]
      local spawn_config = tab_content["spawn_config_container"]
      
      if team_dropdown and team_dropdown.valid and team_dropdown.selected_index > 0 then
        local team_name = team_dropdown.items[team_dropdown.selected_index]
        
        -- Find elements in the nested flows
        local spawn_x, spawn_y, spawn_surface = nil, nil, nil
        if spawn_config and spawn_config.valid then
          for _, child in pairs(spawn_config.children) do
            if child.type == "flow" then
              for _, element in pairs(child.children) do
                if element.name == "spawn_x" then spawn_x = element end
                if element.name == "spawn_y" then spawn_y = element end
                if element.name == "spawn_surface" then spawn_surface = element end
              end
            end
          end
        end
        
        if spawn_x and spawn_x.valid and spawn_y and spawn_y.valid and spawn_surface and spawn_surface.valid then
          local x = tonumber(spawn_x.text)
          local y = tonumber(spawn_y.text)
          local surface_name = spawn_surface.items[spawn_surface.selected_index]
          
          if x and y and surface_name ~= "" then
            if execute_team_action(player, team_manager.set_spawn_position, team_name, {x = x, y = y}, surface_name) then
              print_message(player, "Spawn position set for team " .. team_name)
            end
          else
            print_error(player, "Invalid spawn coordinates or surface")
          end
        end
      else
        print_error(player, "Select a team first")
      end
    end
    
  else
    -- Handle relation buttons using a dispatch table
    local relation_handlers = {
      ceasefire_enable_button = {func = team_manager.set_cease_fire, enabled = true, tab = "relations", prefix = "ceasefire"},
      ceasefire_disable_button = {func = team_manager.set_cease_fire, enabled = false, tab = "relations", prefix = "ceasefire"},
      allied_enable_button = {func = team_manager.set_friend, enabled = true, tab = "relations", prefix = "allied"},
      allied_disable_button = {func = team_manager.set_friend, enabled = false, tab = "relations", prefix = "allied"},
    }
    
    local handler = relation_handlers[name]
    if handler then
      local tab_content = get_tab_content(player, handler.tab)
      local team1, team2 = get_two_teams(tab_content, handler.prefix .. "_team1_dropdown", handler.prefix .. "_team2_dropdown")
      
      if team1 == team2 then
        print_error(player, "Select different teams")
      elseif team1 and team2 then
        if execute_team_action(player, handler.func, team1, team2, handler.enabled) then
          -- Update buttons after changing relationship
          gui_manager.update_relation_buttons(tab_content, event.player_index)
        end
      end
      
    -- Vision buttons
    elseif name == "vision_enable_button" or name == "vision_disable_button" then
      local tab_content = get_tab_content(player, "relations")
      
      -- Find the vision dropdown in the tab content
      local vision_dropdown = nil
      for _, child in pairs(tab_content.children) do
        if child.type == "frame" then
          for _, flow_child in pairs(child.children) do
            if flow_child.type == "flow" and flow_child["vision_team_dropdown"] then
              vision_dropdown = flow_child["vision_team_dropdown"]
              break
            end
          end
        end
      end
      
      if vision_dropdown and vision_dropdown.valid then
        local team_name = vision_dropdown.items[vision_dropdown.selected_index]
        local enabled = name == "vision_enable_button"
        if execute_team_action(player, team_manager.set_share_chart, team_name, enabled) then
          -- Update buttons after changing vision sharing
          gui_manager.update_relation_buttons(tab_content, event.player_index)
        end
      end
    end
  end
end

-- Handle text changed events
function gui_manager.handle_gui_text_changed(event, player)
  -- Can be extended for real-time validation
end

-- Handle selection changed events
function gui_manager.handle_gui_selection_changed(event, player)
  local element = event.element
  if not element or not element.valid then return end
  
  local name = element.name
  
  -- Update relation buttons when team selections change
  if name == "ceasefire_team1_dropdown" or name == "ceasefire_team2_dropdown" or
     name == "allied_team1_dropdown" or name == "allied_team2_dropdown" or
     name == "vision_team_dropdown" then
    local tab_content = get_tab_content(player, "relations")
    if tab_content then
      gui_manager.update_relation_buttons(tab_content, event.player_index)
    end
  
  -- Update spawn configuration when team selection changes
  elseif name == "settings_team_dropdown" then
    local tab_content = get_tab_content(player, "settings")
    if tab_content and element.selected_index > 0 then
      local team_name = element.items[element.selected_index]
      local spawn_config_container = tab_content["spawn_config_container"]
      if spawn_config_container and spawn_config_container.valid then
        gui_manager.build_spawn_config(spawn_config_container, team_name)
      end
    end
  end
end

return gui_manager
