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

class_name Ability_Pause
extends CharacterAbility

## Optional pause menu scene instantiated while paused.
# Optional — leave unassigned until PauseMenu scene exists (Tier 9).
@export var pause_menu_scene: PackedScene

## Runtime instance of the active pause menu.
var _pause_menu_instance: Node = null
## Whether game is currently paused by this ability.
var _is_paused: bool = false


# _ability_initialize(): Configures processing while paused.
# return: No return value.
#
# Forces always-processing so pause input can be detected even when the scene
# tree is paused.
func _ability_initialize() -> void:
	# Must always process so ESC works while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


# _process(): Listens for pause toggle input.
# _delta: Frame step time in seconds.
# return: No return value.
#
# Reads input directly and toggles between pause and unpause states.
func _process(_delta: float) -> void:
	if not is_enabled:
		return
	# Read directly from Input — InputManager stops updating when tree is paused.
	if Input.is_action_just_pressed("Player1_Pause"):
		if _is_paused:
			_unpause()
		else:
			_pause()


# Disable the base class physics update — this ability uses _process instead.
# _physics_process(): Disables inherited physics update handling.
# _delta: Physics step time in seconds.
# return: No return value.
#
# Pause ability intentionally runs in _process to work during paused tree state.
func _physics_process(_delta: float) -> void:
	pass


# _pause(): Pauses tree and optionally shows pause menu.
# return: No return value.
#
# Pauses the scene tree and instantiates configured pause menu UI.
func _pause() -> void:
	get_tree().paused = true
	_is_paused = true
	if pause_menu_scene:
		_pause_menu_instance = pause_menu_scene.instantiate()
		get_tree().root.add_child(_pause_menu_instance)


# _unpause(): Resumes tree and removes pause menu instance.
# return: No return value.
#
# Unpauses gameplay and frees any instantiated pause menu.
func _unpause() -> void:
	get_tree().paused = false
	_is_paused = false
	if _pause_menu_instance:
		_pause_menu_instance.queue_free()
		_pause_menu_instance = null
