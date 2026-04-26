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

class_name Ability_Run
extends CharacterAbility

## Target movement speed while running.
@export var run_speed: float = 380.0
## If true, run requires dedicated run input hold.
@export var run_input_required: bool = true
## Auto-run speed threshold when run input is not required.
@export var run_threshold: float = 180.0

## Cached walk speed restored when run stops.
var _original_speed: float = 0.0
## Reference to horizontal movement ability.
var _h_move: Ability_HorizontalMovement


# _ability_initialize(): Caches movement ability and baseline speed.
# return: No return value.
#
# Finds horizontal movement ability on character and stores its original walk
# speed for later restoration.
func _ability_initialize() -> void:
	_h_move = character.get_node_or_null("Ability_HorizontalMovement") as Ability_HorizontalMovement
	if _h_move:
		_original_speed = _h_move.walk_speed


# _ability_update(): Evaluates run state and updates animation flag.
# _delta: Physics step time in seconds.
# return: No return value.
#
# Starts/stops this ability based on configured run conditions and sets running
# animation parameter to match active state.
func _ability_update(_delta: float) -> void:
	if not _h_move:
		return

	var should_run: bool
	if run_input_required:
		should_run = InputManager.run_held and absf(InputManager.horizontal) > 0.01
	else:
		should_run = absf(controller.state.current_speed) > run_threshold

	if should_run and not is_active:
		start()
	elif not should_run and is_active:
		stop()

	character.set_anim_param(AnimParams.IS_RUNNING, is_active)


# _ability_start(): Applies run speed to horizontal movement.
# return: No return value.
#
# Overrides walk speed with run speed while running is active.
func _ability_start() -> void:
	if _h_move:
		_h_move.walk_speed = run_speed


# _ability_stop(): Restores original walk speed.
# return: No return value.
#
# Restores baseline movement speed when running ends.
func _ability_stop() -> void:
	if _h_move:
		_h_move.walk_speed = _original_speed
