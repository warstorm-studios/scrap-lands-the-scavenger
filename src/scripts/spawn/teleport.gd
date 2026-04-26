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

class_name Teleport
extends InteractableBase

## Interactable that teleports the activator to a paired destination Teleport.

## NodePath to the destination Teleport node.
@export var destination: NodePath
## World-space offset applied to the destination position to place the body.
@export var exit_offset: Vector2 = Vector2(0.0, -16.0)
## When true, only nodes in the "player" group can use this teleport.
@export var only_affects_player: bool = true

const _REENTRY_COOLDOWN := 0.5

var _destination: Teleport
var _on_cooldown: bool = false


# _ready(): Resolves the destination NodePath to a Teleport node reference.
#
# Calls super._ready() to set the collision layer, then caches the
# destination node. Leaves _destination null if the path is empty or the
# node is not found.
func _ready() -> void:
	super._ready()
	if not destination.is_empty():
		_destination = get_node_or_null(destination) as Teleport


# activate(): Teleports the activator to the destination Teleport node.
# activator: The node that triggered the teleport interaction.
#
# No-ops when on cooldown, destination is invalid, or only_affects_player
# is true and the activator is not in the "player" group. Resolves the
# physics body via activator.controller before repositioning. Starts
# cooldown on both endpoints after a successful teleport.
func activate(activator: Node2D) -> void:
	if _on_cooldown:
		return
	if _destination == null or not is_instance_valid(_destination):
		return
	if only_affects_player and not activator.is_in_group("player"):
		return

	var body = activator.get("controller")
	if not body:
		body = activator
	body.global_position = _destination.global_position + exit_offset

	SignalBus.teleport_used.emit(activator)
	_start_cooldown()
	_destination._start_cooldown()


# _start_cooldown(): Sets the cooldown flag and clears it after the delay.
#
# Prevents immediate re-entry. Uses a one-shot SceneTree timer so the
# delay runs in real time regardless of Engine.time_scale.
func _start_cooldown() -> void:
	_on_cooldown = true
	await get_tree().create_timer(_REENTRY_COOLDOWN).timeout
	_on_cooldown = false
