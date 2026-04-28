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

class_name Ability_LevelBounds
extends CharacterAbility

## Behavior options when touching each level bound edge.
enum BoundsBehavior { NOTHING, CONSTRAIN, KILL }

## Action when crossing the left bound.
@export var behavior_left:   BoundsBehavior = BoundsBehavior.CONSTRAIN
## Action when crossing the right bound.
@export var behavior_right:  BoundsBehavior = BoundsBehavior.CONSTRAIN
## Action when crossing the top bound.
@export var behavior_top:    BoundsBehavior = BoundsBehavior.NOTHING
## Action when crossing the bottom bound.
@export var behavior_bottom: BoundsBehavior = BoundsBehavior.KILL


# _ability_update(): Enforces configured level-bound behavior.
# _delta: Physics step time in seconds.
# return: No return value.
#
# Reads active level bounds, compares controller position to each edge, and
# applies configured response per side.
func _ability_update(_delta: float) -> void:
	var lb := get_tree().get_first_node_in_group("level_bounds") as LevelBounds
	if not lb:
		return

	var rect := lb.get_bounds_rect()
	var pos := controller.global_position

	# Left edge
	if pos.x < rect.position.x:
		_apply(behavior_left, rect.position.x, true)

	# Right edge
	if pos.x > rect.end.x:
		_apply(behavior_right, rect.end.x, true)

	# Top edge
	if pos.y < rect.position.y:
		_apply(behavior_top, rect.position.y, false)

	# Bottom edge
	if pos.y > rect.end.y:
		_apply(behavior_bottom, rect.end.y, false)


# _apply(): Applies response for a single bound edge violation.
# behavior: Response type to apply.
# clamp_value: Edge coordinate used for constrain behavior.
# is_horizontal: True for x-axis bounds, false for y-axis bounds.
# return: No return value.
#
# Constrain snaps position and clears matching velocity axis, while kill triggers
# character death flow.
func _apply(behavior: BoundsBehavior, clamp_value: float, is_horizontal: bool) -> void:
	match behavior:
		BoundsBehavior.CONSTRAIN:
			if is_horizontal:
				controller.global_position.x = clamp_value
				controller.velocity.x = 0.0
			else:
				controller.global_position.y = clamp_value
				controller.velocity.y = 0.0
		BoundsBehavior.KILL:
			character.kill()
