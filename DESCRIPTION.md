# Team Setup UI - Detailed Description

## Overview
Team Setup UI is a powerful administration mod for Factorio 2.0+ that provides server administrators with a comprehensive graphical interface to manage teams, players, and inter-team relationships. This mod streamlines team management and eliminates the need for complex console commands.

## Core Features

### Team Management
Create and delete custom teams (forces) through an intuitive interface. Each team functions as an independent force with its own technology tree, production statistics, and player roster. Default teams (player, enemy, neutral) are protected from deletion.

### Player Assignment
Move players between teams using a simple dropdown selection interface. The Assign Players tab displays all connected players and available teams, making server organization effortless.

### Spawn Point Configuration
Set custom spawn locations for each team on any surface (Nauvis, Vulcanus, Aquilo, etc.). The Settings tab provides precise coordinate input (X, Y) and surface selection - essential for balanced PvP scenarios or thematic challenges.

### Team Relationships
Configure how teams interact through three relationship types:

**Cease Fire**: Control whether teams' turrets target each other. Perfect for preventing accidental conflicts.

**Allied Access**: Determine whether teams can access each other's buildings and vehicles.

**Map Vision Sharing**: Control whether teams share their map discoveries.

## Use Cases

**PvP Battles**: Create competing teams, set different spawn points, disable cease fire for true competition.

**Cooperative Teams**: Organize players into specialized teams with shared vision and allied access for efficient collaboration.

**Competitive Co-op**: Teams race to achieve goals while maintaining cease fire but keeping separate access.

## Technical Details
Modular architecture with separate managers for teams, GUI, and configuration. Uses Factorio's native force system with minimal performance overhead.

**Requirements**: Factorio 2.0+, base mod >= 2.0
**Command**: `/team-ui` (admin only)
**Permissions**: Admin-only access
