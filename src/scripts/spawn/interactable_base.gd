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

class_name InteractableBase
extends Area2D

## Base class for world interactables used by character interaction abilities.

## How this interactable is triggered by the player.
enum ActivationMode { INTERACT, TOUCH }

## Trigger mode for this interactable.
## INTERACT requires explicit input; TOUCH triggers on body enter.
@export var activation_mode: ActivationMode = ActivationMode.INTERACT


# _ready(): Sets the collision layer to INTERACTABLE with no collision mask.
#
# Mask is 0 because interactables are detected from the player side,
# not by scanning for bodies themselves. In TOUCH mode, the mask is set
# to PLAYER and body_entered is connected for automatic activation.
func _ready() -> void:
	collision_layer = Layers.INTERACTABLE
	collision_mask = 0
	if activation_mode == ActivationMode.TOUCH:
		collision_mask = Layers.PLAYER
		body_entered.connect(_on_body_entered)


# activate(): Override in subclasses; no-op in the base class.
# _activator: The node that triggered the interaction.
#
# Called by ButtonActivation when the player presses interact while inside
# this area. Subclasses override this to implement specific behaviour.
func activate(_activator: Node2D) -> void:
	pass


# _on_body_entered(): Resolves the interacting character and activates it.
# body: The physics body that entered this area in TOUCH mode.
#
# If the entered body is a PlayerController, uses its Character parent as
# the activator so subclass logic receives the character node consistently.
func _on_body_entered(body: Node2D) -> void:
	var parent := body.get_parent()
	var activator: Node2D = parent if parent is Character else body
	activate(activator)
