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

class_name Sanity
extends Node

## Tracks the player's sanity as a bounded integer (0–max_sanity).
## External systems call restore_sanity / reduce_sanity; this component
## clamps the value and broadcasts change signals.

## Emitted when sanity changes for any reason.
signal sanity_changed(old_val: int, new_val: int, max_val: int)
## Emitted when sanity reaches zero.
signal sanity_depleted()

## Maximum (and starting) sanity value.
@export var max_sanity: int = 200

## Current sanity value.
var current_sanity: int


# _ready(): Initialises sanity to the configured maximum.
func _ready() -> void:
	current_sanity = max_sanity


# restore_sanity(): Increases sanity by amount, clamped to max_sanity.
# amount: Positive number of sanity points to restore.
#
# No-ops silently when amount is zero or would produce no net change.
func restore_sanity(amount: int) -> void:
	var old := current_sanity
	current_sanity = min(max_sanity, current_sanity + amount)
	var actual := current_sanity - old
	if actual > 0:
		sanity_changed.emit(old, current_sanity, max_sanity)
		SignalBus.sanity_changed.emit(get_parent(), old, current_sanity, max_sanity)


# reduce_sanity(): Decreases sanity by amount, clamped to zero.
# amount: Positive number of sanity points to remove.
#
# Emits sanity_depleted (local and via SignalBus) when the result is zero.
func reduce_sanity(amount: int) -> void:
	var old := current_sanity
	current_sanity = max(0, current_sanity - amount)
	if current_sanity == old:
		return
	sanity_changed.emit(old, current_sanity, max_sanity)
	SignalBus.sanity_changed.emit(get_parent(), old, current_sanity, max_sanity)
	if current_sanity == 0:
		sanity_depleted.emit()
		SignalBus.sanity_depleted.emit(get_parent())


# reset(): Restores sanity to max_sanity.
#
# Used by respawn and restart flows to return sanity to a clean state.
func reset() -> void:
	var old := current_sanity
	current_sanity = max_sanity
	sanity_changed.emit(old, current_sanity, max_sanity)
	SignalBus.sanity_changed.emit(get_parent(), old, current_sanity, max_sanity)
