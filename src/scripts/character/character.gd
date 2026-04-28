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

class_name Character
extends Node2D

## Emitted when this character is killed.
signal died()
## Emitted when this character has respawned.
signal respawned()
## Emitted when an ability is enabled.
signal ability_enabled(ability: CharacterAbility)
## Emitted when an ability is disabled.
signal ability_disabled(ability: CharacterAbility)

enum CharacterType { PLAYER, AI }

## Whether this character is player-controlled or AI-controlled.
@export var character_type: CharacterType = CharacterType.PLAYER
## Optional identifier for this character instance.
@export var character_id: String = ""
## Visual node flipped based on facing direction.
@export var visual: Node2D  # assign to the visual container node in the editor

## Movement and collision controller.
var controller: PlayerController
## Health component for damage, healing, and death state.
var health: Health
## Horizontal facing direction.
var facing_right: bool = true

## Shared animation parameter map used by animator/abilities.
var anim_params: Dictionary = {}

## Cached list of child ability nodes.
var _abilities: Array[CharacterAbility] = []
## Internal guard that prevents duplicate kill flow.
var _killed: bool = false


# _ready(): Initializes component references and ability lifecycle.
# return: No return value.
#
# Collects child abilities, configures player/enemy collision setup, and wires
# death and spawn related signals.
func _ready() -> void:
	controller = get_node("PlayerController") as PlayerController
	health = get_node("Health") as Health

	if health:
		health.died.connect(_on_health_died)

	if controller:
		if character_type == CharacterType.PLAYER:
			controller.collision_layer = Layers.PLAYER
			controller.collision_mask = Layers.MASK_PLAYER_BODY
			controller.add_to_group("player_controller")
		else:
			controller.collision_layer = Layers.ENEMY
			controller.collision_mask = Layers.MASK_ENEMY_BODY

	for child in get_children():
		if child is CharacterAbility:
			_abilities.append(child)
			child.initialize(self)

	if character_type == CharacterType.PLAYER:
		add_to_group("player")

	LevelManager.player_spawn_requested.connect(_on_spawn_requested)


# _exit_tree(): Disconnects the spawn signal on scene unload.
#
# Prevents a stale connection from firing respawn on a freed controller
# during the next scene transition.
func _exit_tree() -> void:
	if LevelManager.player_spawn_requested.is_connected(_on_spawn_requested):
		LevelManager.player_spawn_requested.disconnect(_on_spawn_requested)


# set_anim_param(): Sets an animation parameter on this character.
# key: Animation parameter key.
# value: New value to store for that key.
# return: No return value.
#
# Stores ability/controller state in a shared dictionary consumed by animation
# systems.
func set_anim_param(key: String, value: Variant) -> void:
	anim_params[key] = value


## True when this character has a valid health component and is not dead.
var is_alive: bool:
	get:
		return not health.is_dead if health else false


# get_ability(): Finds an ability by class type.
# ability_class: Class object to search for among cached abilities.
# return: Matching ability instance, or null when not present.
#
# Uses instance checks to retrieve a concrete ability node by script class.
func get_ability(ability_class) -> CharacterAbility:
	for ability in _abilities:
		if is_instance_of(ability, ability_class):
			return ability
	return null


# has_ability(): Checks whether this character has an ability class.
# ability_class: Class object to search for among cached abilities.
# return: True if an ability instance of that class exists.
#
# Convenience wrapper used by gameplay code before requesting ability actions.
func has_ability(ability_class) -> bool:
	return get_ability(ability_class) != null


# enable_ability(): Enables a specific ability class if found.
# ability_class: Class object for the ability to enable.
# return: No return value.
#
# Enables the matching ability node and emits a notification signal.
func enable_ability(ability_class) -> void:
	var ability := get_ability(ability_class)
	if ability:
		ability.enable()
		ability_enabled.emit(ability)


# disable_ability(): Disables a specific ability class if found.
# ability_class: Class object for the ability to disable.
# return: No return value.
#
# Disables the matching ability node and emits a notification signal.
func disable_ability(ability_class) -> void:
	var ability := get_ability(ability_class)
	if ability:
		ability.disable()
		ability_disabled.emit(ability)


# flip(): Updates facing direction and visual horizontal scale.
# face_right: True to face right, false to face left.
# return: No return value.
#
# Stores facing state and mirrors the assigned visual node when available.
func flip(face_right: bool) -> void:
	facing_right = face_right
	if visual:
		visual.scale.x = 1.0 if face_right else -1.0


# kill(): Runs character death flow once.
# return: No return value.
#
# Kills health, disables abilities, emits global death events, and handles
# player-specific life loss signaling.
func kill() -> void:
	if _killed:
		return
	_killed = true
	if health and not health.is_dead:
		health.kill()
	_disable_all_abilities()
	died.emit()
	SignalBus.character_died.emit(self)
	if character_type == CharacterType.PLAYER:
		GameManager.lose_life()
		SignalBus.player_died.emit()


# respawn(): Revives this character at a target position.
# position: World-space spawn position for the controller body.
# return: No return value.
#
# Resets movement/health state, re-enables abilities, and emits revive events.
func respawn(position: Vector2) -> void:
	_killed = false
	controller.global_position = position
	controller.velocity = Vector2.ZERO
	health.reset()
	_enable_all_abilities()
	respawned.emit()
	SignalBus.character_revived.emit(self)


# _on_spawn_requested(): Handles player spawn requests from LevelManager.
# position: Spawn position to use for the player character.
# return: No return value.
#
# Only player-type characters respond to this event and run respawn.
func _on_spawn_requested(position: Vector2) -> void:
	if character_type == CharacterType.PLAYER:
		respawn(position)


# _on_health_died(): Handles health death callback.
# return: No return value.
#
# Bridges component-level death to full character death handling.
func _on_health_died() -> void:
	kill()


# _disable_all_abilities(): Disables every registered ability.
# return: No return value.
#
# Used during death flow to freeze gameplay controls and behavior.
func _disable_all_abilities() -> void:
	for ability in _abilities:
		ability.disable()


# _enable_all_abilities(): Enables every registered ability.
# return: No return value.
#
# Used after respawn to restore normal gameplay controls and behavior.
func _enable_all_abilities() -> void:
	for ability in _abilities:
		ability.enable()
