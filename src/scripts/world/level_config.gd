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

class_name LevelConfig
extends Node

## Per-scene configuration read by LevelManager after each scene load.
## Place one LevelConfig node under Managers in every scene.

## Leave empty to use LevelManager.default_player_scene (the common case).
@export var player_scene: PackedScene

## Transition used when the camera fades in after the scene loads.
@export var transition_in: Enums.TransitionType = Enums.TransitionType.FADE
## Transition used when the camera fades out before the scene unloads.
@export var transition_out: Enums.TransitionType = Enums.TransitionType.FADE


# _ready(): Adds this node to the level_config group for LevelManager.
#
# LevelManager calls get_first_node_in_group("level_config") after each
# scene load to read the transition and player-scene overrides.
func _ready() -> void:
	add_to_group("level_config")
