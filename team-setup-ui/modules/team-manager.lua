-- Team Manager Module
-- Handles team creation, player assignment, spawn points, and team relationships

local team_manager = {}

-- Default teams that cannot be deleted
local DEFAULT_TEAMS = {player = true, enemy = true, neutral = true}

-- Helper: Validate team exists
local function get_force(team_name)
  return game.forces[team_name]
end

-- Helper: Initialize team data
local function init_team_data(team_name)
  storage.teams = storage.teams or {}
  storage.teams[team_name] = {
    name = team_name,
    created_at = game.tick,
    spawn_position = {x = 0, y = 0},
    spawn_surface = "nauvis",
    description = ""
  }
end

-- Create a new team
function team_manager.create_team(team_name)
  if not team_name or team_name == "" then
    return false, "Team name cannot be empty"
  end
  
  if get_force(team_name) then
    return false, "Team '" .. team_name .. "' already exists"
  end
  
  local force = game.create_force(team_name)
  force.reset()
  init_team_data(team_name)
  
  return true, "Team '" .. team_name .. "' created successfully"
end

-- Delete a team
function team_manager.delete_team(team_name)
  if DEFAULT_TEAMS[team_name] then
    return false, "Cannot delete default teams"
  end
  
  local force = get_force(team_name)
  if not force then
    return false, "Team '" .. team_name .. "' not found"
  end
  
  -- Reassign players to player force
  for _, player in ipairs(force.players) do
    player.force = game.forces["player"]
  end
  
  -- Merge force to remove all entities and the force itself
  game.merge_forces(team_name, "neutral")
  
  -- Remove from our tracking
  if storage.teams then
    storage.teams[team_name] = nil
  end
  
  return true, "Team '" .. team_name .. "' deleted"
end

-- Get all teams (excluding default ones)
function team_manager.get_all_teams()
  local teams = {}
  
  -- Only return teams that exist in both game.forces and storage.teams
  if storage.teams then
    for team_name, _ in pairs(storage.teams) do
      local force = get_force(team_name)
      if force then
        table.insert(teams, {
          name = team_name,
          player_count = #force.players,
          force = force
        })
      end
    end
  end
  
  return teams
end

-- Assign player to team
function team_manager.assign_player_to_team(player_name, team_name)
  local player = game.get_player(player_name)
  if not player then
    return false, "Player '" .. player_name .. "' not found"
  end
  
  local force = get_force(team_name)
  if not force then
    return false, "Team '" .. team_name .. "' not found"
  end
  
  player.force = force
  return true, "Player '" .. player_name .. "' assigned to team '" .. team_name .. "'"
end

-- Get players in a team
function team_manager.get_team_players(team_name)
  local force = get_force(team_name)
  if not force then return {} end
  
  local players = {}
  for _, player in ipairs(force.players) do
    table.insert(players, player.name)
  end
  return players
end

-- Set spawn point for team
function team_manager.set_spawn_position(team_name, position, surface_name)
  surface_name = surface_name or "nauvis"
  
  local force = get_force(team_name)
  if not force then
    return false, "Team '" .. team_name .. "' not found"
  end
  
  local surface = game.surfaces[surface_name]
  if not surface then
    return false, "Surface '" .. surface_name .. "' not found"
  end
  
  force.set_spawn_position(position, surface)
  
  -- Store spawn position in storage
  storage.teams = storage.teams or {}
  if storage.teams[team_name] then
    storage.teams[team_name].spawn_position = position
    storage.teams[team_name].spawn_surface = surface_name
  end
  
  return true, "Spawn position set for team '" .. team_name .. "' at (" .. position.x .. ", " .. position.y .. ")"
end

-- Helper: Set relationship between two teams
local function set_team_relationship(team1_name, team2_name, setter_func, enabled)
  local force1 = get_force(team1_name)
  local force2 = get_force(team2_name)
  
  if not force1 or not force2 then
    return false, "One or both teams not found"
  end
  
  setter_func(force1, force2, enabled)
  setter_func(force2, force1, enabled)
  return true
end

-- Set cease fire relationship
function team_manager.set_cease_fire(team1_name, team2_name, enabled)
  local success = set_team_relationship(team1_name, team2_name, 
    function(f1, f2, en) f1.set_cease_fire(f2, en) end, enabled)
  
  if not success then
    return false, "One or both teams not found"
  end
  
  local status = enabled and "enabled" or "disabled"
  return true, "Cease fire " .. status .. " between '" .. team1_name .. "' and '" .. team2_name .. "'"
end

-- Allow allied access to buildings and vehicles
function team_manager.set_friend(team1_name, team2_name, enabled)
  local success = set_team_relationship(team1_name, team2_name,
    function(f1, f2, en) f1.set_friend(f2, en) end, enabled)
  
  if not success then
    return false, "One or both teams not found"
  end
  
  local status = enabled and "enabled" or "disabled"
  return true, "Allied access " .. status .. " between '" .. team1_name .. "' and '" .. team2_name .. "'"
end

-- Share map vision for a team
function team_manager.set_share_chart(team_name, enabled)
  local force = get_force(team_name)
  if not force then
    return false, "Team '" .. team_name .. "' not found"
  end
  
  force.share_chart = enabled
  
  local status = enabled and "enabled" or "disabled"
  return true, "Map vision sharing " .. status .. " for team '" .. team_name .. "'"
end

-- Get team info
function team_manager.get_team_info(team_name)
  local force = get_force(team_name)
  if not force then return nil end
  
  local team_data = (storage.teams and storage.teams[team_name]) or {}
  
  return {
    name = team_name,
    player_count = #force.players,
    players = team_manager.get_team_players(team_name),
    spawn_position = team_data.spawn_position or {x = 0, y = 0},
    spawn_surface = team_data.spawn_surface or "nauvis",
    share_chart = force.share_chart,
    description = team_data.description or ""
  }
end

return team_manager
