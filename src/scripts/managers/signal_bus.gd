# Copyright (C) 2026  WarStorm Studios - Lior Gonda
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program.  If not, see
# <https://www.gnu.org/licenses/>.

## Global event bus for decoupling systems. Emit signals here instead of
## holding direct node references across system boundaries.
extends Node

# Health & Damage
## Emitted by [Health] whenever HP changes on any character.
signal health_changed(character: Node, old_val: int, new_val: int, max_val: int)
## Emitted by [Health] when a character's HP reaches zero.
signal character_died(character: Node)
## Emitted by [Health] when a character is revived after death.
signal character_revived(character: Node)

# Game State
## Emitted when the player can no longer continue the current run.
signal game_over()
## Emitted when the player character dies.
signal player_died()
## Emitted when the player character respawns.
signal player_respawned()
## Emitted when a level's win condition is satisfied.
signal level_complete(scene_id: String)
## Emitted when any non-player enemy is defeated.
signal enemy_defeated(enemy: Node)

# Level & Scene
## Emitted by [Checkpoint] when the player activates it.
signal checkpoint_reached(checkpoint: Node)
## Emitted when the player enters a [LadderArea] volume.
signal ladder_area_entered(area: Node)
## Emitted when the player exits a [LadderArea] volume.
signal ladder_area_exited(area: Node)
## Emitted when a [Teleport] node is activated.
signal teleport_used(activator: Node)
## Emitted by [LevelManager] just before a scene change begins.
signal scene_transition_started(from_scene: String, to_scene: String)
## Emitted by [LevelManager] after a scene change completes.
signal scene_transition_finished(scene_name: String)

# Time
## Emitted by [TimeManager] when [code]Engine.time_scale[/code] changes.
signal time_scale_changed(new_scale: float)

# Audio
## Requests [AudioManager] to play a registered SFX by ID.
signal play_sfx_requested(sfx_id: String)
## Requests [AudioManager] to play a registered music track by ID.
signal play_music_requested(music_id: String)
