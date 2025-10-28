-- Configuration Module
-- Handles persistent mod settings and data storage

local config = {}

-- Initialize storage
function config.init_storage()
  storage.teams = storage.teams or {}
  storage.gui = storage.gui or {}
  storage.config = storage.config or {
    version = "1.0.0",
    mod_enabled = true,
    log_events = true
  }
  
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

-- Handle configuration migration for mod updates
function config.migrate()
  config.init_storage()
  -- Add future migration logic here as needed
  storage.config.version = storage.config.version or "1.0.0"
end

-- Get a config value
function config.get(key, default)
  if storage.config and storage.config[key] ~= nil then
    return storage.config[key]
  end
  return default
end

-- Set a config value
function config.set(key, value)
  if not storage.config then
    config.init_storage()
  end
  storage.config[key] = value
end

-- Clear all data (used when mod is reset)
function config.clear_all()
  storage.teams = {}
  storage.gui = {}
  storage.config = {
    version = "1.0.0",
    mod_enabled = true,
    log_events = true
  }
end

-- Log helper function
function config.log(message, level)
  if config.get("log_events", true) then
    log("[Team Setup UI] [" .. (level or "info") .. "] " .. message)
  end
end

return config
