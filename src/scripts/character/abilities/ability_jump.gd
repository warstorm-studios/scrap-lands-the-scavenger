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

class_name Ability_Jump
extends CharacterAbility

## Emitted when a jump is performed.
signal jumped()
## Emitted when landing is detected.
signal landed()

## Desired jump apex height in pixels.
@export var jump_height: float = 300.0
## Maximum jumps allowed before touching ground.
@export var max_jump_count: int = 1
## Grace window allowing jump shortly after leaving ground.
@export var coyote_time: float = 0.12
## Input buffering window for early jump press.
@export var jump_buffer_time: float = 0.1
## Upward velocity multiplier applied on early jump release.
@export var variable_jump_multiplier: float = 0.5
## Additional gravity multiplier while falling.
@export var fall_gravity_multiplier: float = 2.0

## Calculated jump launch velocity.
var _jump_velocity: float = 0.0
## Number of jumps used since last landing.
var _jump_count: int = 0
## Remaining coyote-time window.
var _coyote_timer: float = 0.0
## Remaining jump-buffer window.
var _buffer_timer: float = 0.0
## Cached project gravity.
var _gravity: float = 0.0


# _ability_initialize(): Initializes jump physics constants and signals.
# return: No return value.
#
# Caches project gravity, computes launch velocity for target height, and hooks
# the controller landed signal.
func _ability_initialize() -> void:
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	_jump_velocity = -sqrt(2.0 * _gravity * jump_height)
	controller.landed.connect(_on_landed)


# _ability_update(): Handles jump input, timers, and gravity shaping.
# delta: Physics step time in seconds.
# return: No return value.
#
# Implements coyote time, jump buffering, multi-jump checks, variable jump
# height on release, and fall gravity tuning.
func _ability_update(delta: float) -> void:
	# Reset on landing — must run BEFORE jump attempt so it doesn't clobber _jump_count
	# from a jump taken this same frame
	if controller.state.is_grounded:
		_jump_count = 0
		if is_active:
			stop()

	# Start coyote window the moment we leave the ground
	if controller.state.was_grounded and not controller.state.is_grounded:
		_coyote_timer = coyote_time

	# Buffer a jump press so it works slightly before landing
	if InputManager.jump_pressed:
		_buffer_timer = jump_buffer_time

	# First jump requires ground or coyote window; air jumps (double jump etc.) do not
	var first_jump := _jump_count == 0 and (controller.state.is_grounded or _coyote_timer > 0.0)
	var air_jump := _jump_count > 0 and _jump_count < max_jump_count and not controller.state.is_grounded
	if _buffer_timer > 0.0 and (first_jump or air_jump):
		_do_jump()

	# Variable height: cut upward velocity on early button release
	if InputManager.jump_released and controller.velocity.y < 0.0:
		controller.set_vertical_velocity(controller.velocity.y * variable_jump_multiplier)

	# Enhanced fall gravity so descents feel snappy
	if controller.velocity.y > 0.0:
		controller.set_vertical_velocity(
			controller.velocity.y + _gravity * (fall_gravity_multiplier - 1.0) * delta
		)

	# Tick timers
	_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_buffer_timer = maxf(0.0, _buffer_timer - delta)

	character.set_anim_param(AnimParams.IS_JUMPING, is_active and controller.velocity.y < 0.0)
	character.set_anim_param(AnimParams.IS_FALLING, controller.velocity.y > 50.0)
	character.set_anim_param(AnimParams.JUMP_COUNT, _jump_count)


# _do_jump(): Performs one jump and emits jump events.
# return: No return value.
#
# Applies launch velocity, increments jump usage, clears input timers, and
# triggers both local and global jump feedback.
func _do_jump() -> void:
	controller.set_vertical_velocity(_jump_velocity)
	_jump_count += 1
	_coyote_timer = 0.0
	_buffer_timer = 0.0
	start()
	jumped.emit()
	SignalBus.play_sfx_requested.emit("sfx_jump")


# _on_landed(): Handles landed callback from controller.
# return: No return value.
#
# Emits local landed signal and stops active jump state when needed.
func _on_landed() -> void:
	landed.emit()
	if is_active:
		stop()
