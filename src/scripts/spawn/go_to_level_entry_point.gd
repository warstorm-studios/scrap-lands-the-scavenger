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

class_name GoToLevelEntryPoint
extends InteractableBase

## Interactable that loads a scene and sets the player's entry point and facing.

## Direction the player will face after arriving at the destination scene.
enum FacingDirection { RIGHT, LEFT }

## Scene file to load when the player interacts with this entry point.
@export_file("*.tscn") var target_scene: String = ""
## [code]checkpoint_id[/code] of the checkpoint in the destination scene to
## spawn the player at. Leave empty to use the scene's first checkpoint.
@export var target_checkpoint_id: String = ""
## Direction the player will face after the scene transition completes.
@export var facing_direction: FacingDirection = FacingDirection.RIGHT


# activate(): Records target checkpoint and facing direction, then loads scene.
# _activator: The node that triggered the interaction; unused directly.
#
# No-ops when target_scene is empty. Sets pending_entry_id and
# pending_facing_direction on GameManager so the destination scene can
# position and orient the player on arrival.
func activate(_activator: Node2D) -> void:
	if target_scene.is_empty():
		return

	GameManager.pending_entry_id = target_checkpoint_id
	GameManager.pending_facing_direction = int(facing_direction)

	LevelManager.load_scene(target_scene)
