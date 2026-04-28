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

class_name Ability_ButtonActivation
extends CharacterAbility

## Radius used to detect nearby interactables.
@export var detect_radius: float = 40.0

## Area sensor used to collect nearby interactables.
var _interact_sensor: Area2D
## Current nearby interactable areas.
var _nearby: Array[Area2D] = []
## True while activation animation flag is set.
var _activating: bool = false


# _ability_initialize(): Builds and wires the interaction sensor.
# return: No return value.
#
# Creates an Area2D circle sensor on the controller to track nearby
# interactables on the interactable collision layer.
func _ability_initialize() -> void:
	var circle := CircleShape2D.new()
	circle.radius = detect_radius

	var collision := CollisionShape2D.new()
	collision.shape = circle

	_interact_sensor = Area2D.new()
	_interact_sensor.name = "InteractSensor"
	_interact_sensor.collision_layer = 0
	_interact_sensor.collision_mask = Layers.INTERACTABLE
	_interact_sensor.add_child(collision)
	controller.add_child(_interact_sensor)

	_interact_sensor.area_entered.connect(_on_area_entered)
	_interact_sensor.area_exited.connect(_on_area_exited)


# _ability_update(): Handles interact input and activation flow.
# _delta: Physics step time in seconds.
# return: No return value.
#
# Resets one-frame activation state, finds the nearest interactable when input
# is pressed, and calls its activate method when available.
func _ability_update(_delta: float) -> void:
	if _activating:
		if _anim_tree:
			_anim_tree.set(AnimParams.IS_ACTIVATING, false)
		_activating = false

	if not InputManager.interact_pressed:
		return

	var nearest := _get_nearest()
	if nearest == null:
		return

	if nearest.has_method("activate"):
		nearest.activate(character)

	_activating = true
	if _anim_tree:
		_anim_tree.set(AnimParams.IS_ACTIVATING, true)
	start()
	stop()


# _get_nearest(): Returns nearest currently tracked interactable.
# return: Closest valid Area2D from nearby list, or null.
#
# Ignores invalid freed instances and chooses by squared distance to controller
# position.
func _get_nearest() -> Area2D:
	if _nearby.is_empty():
		return null
	var origin: Vector2 = controller.global_position
	var best: Area2D = null
	var best_dist := INF
	for area in _nearby:
		if not is_instance_valid(area):
			continue
		if area is InteractableBase and area.activation_mode == InteractableBase.ActivationMode.TOUCH:
			continue
		var d := area.global_position.distance_squared_to(origin)
		if d < best_dist:
			best_dist = d
			best = area
	return best


# _on_area_entered(): Tracks newly entered interactable areas.
# area: Area that entered the interaction sensor.
# return: No return value.
#
# Adds unique areas to the nearby tracking list.
func _on_area_entered(area: Area2D) -> void:
	if not _nearby.has(area):
		_nearby.append(area)


# _on_area_exited(): Untracks exited interactable areas.
# area: Area that left the interaction sensor.
# return: No return value.
#
# Removes areas from the nearby tracking list when they leave range.
func _on_area_exited(area: Area2D) -> void:
	_nearby.erase(area)
