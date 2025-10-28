Commands Bearbeiten
Create a Team:
/c game.create_force('team1')

Assign a Team:
/c game.get_player('Player1').force = game.forces['team1']

Assign a new Spawn based on current position:
/c local player = game.get_player('PlayerName'); player.force.set_spawn_position(player.position, player.surface)

Assign Coord based:
/c game.forces['team1'].set_spawn_position({x = -100, y = -100}, game.surfaces['nauvis'])


Prevent Turrets targeting another team:
/c game.forces['team1'].set_cease_fire('team2', true)

Allow Access to buildings and Vehicles:
/c game.forces['team1'].set_friend('team2', true)

Share Map Vision:
/c game.forces['team1'].share_chart = true