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

class_name Ability_HorizontalMovement
extends CharacterAbility

## Maximum walking speed while this ability controls movement.
@export var walk_speed: float = 200.0
## Ground acceleration toward target speed.
@export var acceleration: float = 1200.0
## Deceleration when no movement input is held.
@export var deceleration: float = 1600.0
## Acceleration multiplier used while airborne.
@export var air_control_multiplier: float = 0.6
## If true, velocity snaps directly to target speed.
@export var instant_acceleration: bool = false


# _ability_update(): Applies horizontal movement from input.
# delta: Physics step time in seconds.
# return: No return value.
#
# Computes target horizontal velocity, applies acceleration/deceleration rules,
# updates facing, and writes movement animation parameters.
func _ability_update(delta: float) -> void:
	var input_x: float = InputManager.horizontal
	var actual_vx: float = controller.velocity.x
	var current_vx: float = actual_vx
	var target_vx: float = input_x * walk_speed
	var accel_mod: float = 1.0 if controller.state.is_grounded else air_control_multiplier

	if instant_acceleration:
		current_vx = target_vx
	elif absf(input_x) > 0.01:
		current_vx = move_toward(current_vx, target_vx, acceleration * accel_mod * delta)
	else:
		current_vx = move_toward(current_vx, 0.0, deceleration * delta)

	controller.set_horizontal_velocity(current_vx)

	if input_x > 0.01:
		character.flip(true)
	elif input_x < -0.01:
		character.flip(false)

	var moving := absf(actual_vx) > 10.0
	character.set_anim_param(AnimParams.IS_MOVING, moving)
	character.set_anim_param(AnimParams.IS_IDLE, not moving)
	character.set_anim_param(AnimParams.SPEED, absf(actual_vx))
