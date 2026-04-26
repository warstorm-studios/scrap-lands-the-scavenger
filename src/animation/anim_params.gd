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

class_name AnimParams

## Centralized AnimationTree parameter paths used across abilities/animator.
# All standard AnimationTree parameter paths.
# Abilities call: _anim_tree.set(AnimParams.IS_MOVING, true)
# Sorted alphabetically.

## AnimationTree path for activation blend/flag.
const IS_ACTIVATING := "parameters/IsActivating"
## AnimationTree path for falling state.
const IS_FALLING    := "parameters/IsFalling"
## AnimationTree path for idle state.
const IS_IDLE       := "parameters/IsIdle"
## AnimationTree path for jumping state.
const IS_JUMPING    := "parameters/IsJumping"
## AnimationTree path for moving state.
const IS_MOVING     := "parameters/IsMoving"
## AnimationTree path for running state.
const IS_RUNNING    := "parameters/IsRunning"
## AnimationTree path for jump count parameter.
const JUMP_COUNT    := "parameters/JumpCount"
## AnimationTree path for speed parameter.
const SPEED         := "parameters/Speed"
