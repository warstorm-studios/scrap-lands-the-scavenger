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

class_name CharacterAbility
extends Node

## Emitted when this ability is started.
signal ability_started(ability: CharacterAbility)
## Emitted when this ability is stopped.
signal ability_stopped(ability: CharacterAbility)

## Whether this ability is currently allowed to run.
@export var ability_permitted: bool = true

## Character that owns this ability.
var character: Node2D   # typed as Node2D to avoid circular dep with character.gd
## Character controller used by this ability.
var controller: PlayerController
## Whether this ability may execute updates and start.
var is_enabled: bool = true
## Whether this ability is currently active.
var is_active: bool = false
## Optional animation tree, if one exists in the character hierarchy.
var _anim_tree: AnimationTree  # null until Tier 5 animation is wired up


# initialize(): Wires this ability to its owning character.
# owning_character: Character node that owns and drives this ability.
# return: No return value.
#
# Caches commonly used references and calls the subclass hook so each ability
# can perform its own startup logic.
func initialize(owning_character: Node2D) -> void:
	character = owning_character
	controller = character.controller
	_anim_tree = _find_anim_tree(owning_character)
	_ability_initialize()


# _find_anim_tree(): Recursively searches for an AnimationTree.
# root: Node to begin scanning for an AnimationTree child.
# return: The first AnimationTree found, or null if none exists.
#
# Traverses the full child hierarchy depth-first so abilities can still get an
# animation tree reference even when it is nested.
func _find_anim_tree(root: Node) -> AnimationTree:
	for child in root.get_children():
		if child is AnimationTree:
			return child
		var found := _find_anim_tree(child)
		if found:
			return found
	return null


# _physics_process(): Runs per-physics-frame ability updates.
# delta: Physics step time in seconds.
# return: No return value.
#
# Delegates update work to subclass code while this ability is enabled.
func _physics_process(delta: float) -> void:
	if not is_enabled:
		return
	_ability_update(delta)


# start(): Activates this ability when it is allowed to run.
# return: No return value.
#
# Guards against duplicate starts, checks permission gates, then runs subclass
# activation logic and emits an activation signal.
func start() -> void:
	if not is_enabled or is_active:
		return
	if not _ability_permitted():
		return
	is_active = true
	_ability_start()
	ability_started.emit(self)


# stop(): Deactivates this ability if it is active.
# return: No return value.
#
# Runs subclass stop logic and emits a stop signal so listeners can respond.
func stop() -> void:
	if not is_active:
		return
	is_active = false
	_ability_stop()
	ability_stopped.emit(self)


# enable(): Enables this ability.
# return: No return value.
#
# Enables updates and future starts for this ability.
func enable() -> void:
	is_enabled = true


# disable(): Disables this ability.
# return: No return value.
#
# Stops the ability first when active, then prevents further updates and starts
# until re-enabled.
func disable() -> void:
	if is_active:
		stop()
	is_enabled = false


# --- Override in subclasses ---

# _ability_initialize(): Subclass initialization hook.
# return: No return value.
#
# Override in ability scripts to initialize node-specific state.
func _ability_initialize() -> void:
	pass


# _ability_update(): Subclass per-frame hook.
# _delta: Physics step time in seconds.
# return: No return value.
#
# Override in ability scripts to implement ongoing behavior.
func _ability_update(_delta: float) -> void:
	pass


# _ability_start(): Subclass activation hook.
# return: No return value.
#
# Override in ability scripts to execute logic when the ability starts.
func _ability_start() -> void:
	pass


# _ability_stop(): Subclass deactivation hook.
# return: No return value.
#
# Override in ability scripts to clean up when the ability stops.
func _ability_stop() -> void:
	pass


# _ability_permitted(): Subclass permission check hook.
# return: True when this ability is currently allowed to start.
#
# Override in ability scripts to add contextual permission checks before start.
func _ability_permitted() -> bool:
	return ability_permitted
