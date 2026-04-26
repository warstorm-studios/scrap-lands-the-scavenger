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

class_name Checkpoint
extends Area2D

## Trigger area that tracks progress and marks the active respawn point.

## Emitted when the player first enters this checkpoint's trigger area.
signal checkpoint_activated(checkpoint: Checkpoint)

## Lifecycle states for the visual and spawn-point logic.
enum State { INACTIVE, ACTIVE, USED }

## Unique identifier for this checkpoint within the level.
@export var checkpoint_id: String = ""
## World-space offset added to global_position to compute the spawn location.
@export var spawn_offset: Vector2 = Vector2(0.0, 0.0)

## Current lifecycle state; updated by LevelManager and the entry signal.
var state: State = State.INACTIVE


# _ready(): Registers with LevelManager and connects the body-entered signal.
#
# Sets the collision layer to Trigger and the mask to Player so the area
# fires only when the player character enters.
func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.PLAYER
	LevelManager.register_checkpoint(self)
	body_entered.connect(_on_body_entered)


# set_active(): Marks this checkpoint as the currently active spawn point.
#
# Called by LevelManager.activate_checkpoint when the player enters.
func set_active() -> void:
	state = State.ACTIVE


# set_used(): Marks this checkpoint as used and no longer the active spawn.
#
# Called by LevelManager.activate_checkpoint on all checkpoints that are
# not the newly activated one.
func set_used() -> void:
	state = State.USED


# _on_body_entered(): Activates the checkpoint when the player enters.
# body: The node that entered the trigger area.
#
# No-ops when the checkpoint is already ACTIVE or USED. Emits both the
# local checkpoint_activated signal and SignalBus.checkpoint_reached, then
# delegates spawn tracking to LevelManager.
func _on_body_entered(body: Node) -> void:
	if state != State.INACTIVE:
		return
	if body is PlayerController:
		checkpoint_activated.emit(self)
		SignalBus.checkpoint_reached.emit(self)
		LevelManager.activate_checkpoint(self)
