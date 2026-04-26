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

## Autoloaded singleton that owns the active run and emits run lifecycle events.
extends Node

## Shared configuration: difficulty options.
@export var settings: GameSettingsResource

## Active run data; [code]null[/code] when no run is in progress.
var current_run: RunData = null
## Save slot index associated with the current run.
var current_slot: int = 0

## [code]true[/code] when a run is in progress.
var has_active_run: bool:
	get: return current_run != null

## Scene path queued for the next stage transition; empty when none is pending.
var pending_stage_scene: String = ""
## [code]checkpoint_id[/code] of the checkpoint to spawn the player at in the
## destination scene. Empty string means use the scene default.
var pending_entry_id: String = ""
## Facing direction the player should have after a scene transition completes.
## [code]0[/code] = right, [code]1[/code] = left.
var pending_facing_direction: int = 0

## Emitted when a new run begins or a saved run is resumed.
signal run_started(run: RunData)
## Emitted when the current run is cleared.
signal run_ended()


# _ready(): Initialises settings to defaults when unassigned in the Inspector.
#
# Falls back to a default GameSettingsResource so GameManager is safe to use
# without an Inspector-level configuration assignment.
func _ready() -> void:
	if settings == null:
		settings = GameSettingsResource.new()


# start_new_run(): Creates a blank RunData for slot and emits run_started.
# slot: Save slot index to associate with the new run.
# difficulty: Difficulty level to assign to the new run.
#
# Replaces any existing current_run with a fresh RunData instance and
# records the slot for later use by SaveManager.
func start_new_run(
	slot: int = 0,
	difficulty: Enums.DifficultyLevel = Enums.DifficultyLevel.NORMAL
) -> void:
	current_slot = slot
	current_run = RunData.new()
	current_run.difficulty = difficulty
	run_started.emit(current_run)


# resume_run(): Restores a saved run into the active slot and emits run_started.
# slot: Save slot index the run was loaded from.
# saved_run: The RunData instance to restore as the active run.
#
# Sets current_run and current_slot, then emits run_started so systems
# dependent on the active run can reinitialise.
func resume_run(slot: int, saved_run: RunData) -> void:
	current_slot = slot
	current_run = saved_run
	run_started.emit(current_run)


# end_run(): Clears the active run and emits run_ended.
#
# Sets current_run to null; has_active_run returns false after this call.
func end_run() -> void:
	current_run = null
	run_ended.emit()
