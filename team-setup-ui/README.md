# Team Setup UI Mod

A Factorio 2.0+ mod that provides admins with an intuitive UI to manage teams, assign players, and configure team relationships.

## Features

- **Team Management**: Create, delete, and manage teams/forces
- **Player Assignment**: Move players between teams
- **Spawn Point Configuration**: Set custom spawn locations for each team on any surface
- **Team Relations**:
  - Cease Fire: Prevent turret targeting between teams
  - Allied Access: Allow access to buildings and vehicles
  - Map Vision Sharing: Share map discoveries

## Installation

1. Copy the `team-setup-ui` folder to your Factorio mods directory
2. Enable the mod in game settings
3. Restart the game

## Usage

Open the UI with the admin command:
```
/team-ui
```

### UI Tabs

**Teams Tab**
- Create new teams by entering a name and clicking "Create Team"
- View all existing teams with player counts
- Delete teams (players reassigned to player force)

**Assign Players Tab**
- Select player and choose a team from dropdown
- Click "Assign" to move player to team

**Relations Tab**
- **Cease Fire**: Prevents turrets from targeting other team (set for both teams simultaneously)
- **Allied Access**: Allows building and vehicle access between teams
- **Map Vision Sharing**: Teams share map discovery

**Settings Tab**
- Set X, Y coordinates and surface for each team's spawn point
- Supports all surfaces (Nauvis, Vulcanus, Aquilo, etc.)

#### Tab 2: Assign Players
- Select a player from the list
- Choose a team from the dropdown


## Console Commands (Alternative)

For scripting or direct control:

```lua
-- Create team
/c game.create_force('team_name')

-- Assign player
/c game.get_player('PlayerName').force = game.forces['team_name']

-- Set spawn point
/c game.forces['team_name'].set_spawn_position({x = -100, y = -100}, game.surfaces['nauvis'])

-- Cease fire between teams
/c game.forces['team1'].set_cease_fire(game.forces['team2'], true)

-- Allow allied access
/c game.forces['team1'].set_friend(game.forces['team2'], true)

-- Share map discovery
/c game.forces['team_name'].share_chart = true
```

## Permissions

Only **admin players** can use the Team Setup UI. Non-admins receive an error message.

## Module Architecture

- **control.lua**: Event handling and command registration
- **modules/team-manager.lua**: Core team operations (create, delete, assign, configure)
- **modules/gui-manager.lua**: UI rendering and event handling
- **modules/config.lua**: Data persistence and storage

## Requirements

- Factorio 2.0+
- base >= 2.0

## Examples

### Create a PvP Map
```
1. Create teams: "Red" and "Blue"
2. Assign players to teams
3. Set different spawn points
4. Disable cease fire for combat
```

### Create a Co-op Map
```
1. Create one team
2. Assign all players to same team
3. Enable allied access and map sharing
```

### Competitive Co-op
```
1. Create teams: "Team A" and "Team B"
2. Assign players to each team
3. Enable cease fire (prevent accidents)
4. Disable allied access (teams compete)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "You must be an admin" | Only admins can use the mod - contact server admin |
| UI won't open | Ensure mod is enabled, try `/team-ui` |
| Can't delete team | Default teams (player, enemy, neutral) can't be deleted |
| Players not assigned | Verify team exists and player name spelling |
| Spawn not working | Check coordinates are numbers and surface exists |

## Global Data Storage

The mod stores data in `global`:

```lua
global.teams = {
  [team_name] = {
    name = string,
    created_at = tick,
    spawn_position = {x, y},
    spawn_surface = string,
    description = string
  }
}
```

## Performance

The mod is lightweight:
- UI renders only when opened
- Minimal overhead on team operations
- No continuous background processes
- Efficient data storage

## License

This mod is provided as-is for use in Factorio.

## Changelog

**1.0.0** - Initial release for Factorio 2.0+
