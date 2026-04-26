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

## Autoloaded singleton for JSON save/load to [code]user://saves/[/code].
## Slots are indexed 0 to [constant MAX_SAVE_SLOTS] minus 1.
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1
## Maximum number of save slots available to the player.
const MAX_SAVE_SLOTS := 3

## Emitted after a successful save.
signal save_completed(slot: int)
## Emitted after a successful load with the deserialized [RunData].
signal load_completed(slot: int, run: RunData)
## Emitted when a save fails; [param error] describes the cause.
signal save_failed(slot: int, error: String)


# _ready(): Ensures the saves directory exists before any file I/O.
#
# Creates user://saves/ if it does not exist; no-op when already present.
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# has_save(): Returns true if a save file exists for the given slot.
# slot: Zero-based save slot index to check.
# return: True when the slot's JSON file is present on disk.
#
# Does not validate the file contents; use load_slot for full validation.
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


# save(): Serializes the active RunData to the given slot.
# slot: Zero-based save slot index to write.
#
# Emits save_failed when current_run is null or the file cannot be opened.
# Emits save_completed on success.
func save(slot: int) -> void:
	var run := GameManager.current_run
	if run == null:
		save_failed.emit(slot, "No active run")
		return
	var data := {
		"saved_at": Time.get_datetime_string_from_system(),
		"version": SAVE_VERSION,
		"run": _serialize_run(run)
	}
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot, "Cannot write to " + _slot_path(slot))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(slot)


# load_slot(): Loads and returns RunData from the given slot.
# slot: Zero-based save slot index to read.
# return: Populated RunData on success, or null when missing or invalid.
#
# Emits load_completed on success. Returns null without emitting on any
# failure (missing file, unreadable, or invalid JSON structure).
func load_slot(slot: int) -> RunData:
	if not FileAccess.file_exists(_slot_path(slot)):
		return null
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return null
	var json: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (json is Dictionary) or not _is_valid(json):
		return null
	var run := _deserialize_run(json["run"])
	load_completed.emit(slot, run)
	return run


# delete_save(): Deletes the save file for the given slot.
# slot: Zero-based save slot index to delete.
#
# No-ops silently when no save file exists for the slot.
func delete_save(slot: int) -> void:
	if FileAccess.file_exists(_slot_path(slot)):
		DirAccess.remove_absolute(_slot_path(slot))


# get_save_index(): Returns one SaveSlotMeta per slot.
# return: Array of SaveSlotMeta with length MAX_SAVE_SLOTS.
#
# Reads each slot file directly; slots with no file have is_empty true.
# No separate index file is used.
func get_save_index() -> Array:
	var result: Array = []
	for i in MAX_SAVE_SLOTS:
		var meta := SaveSlotMeta.new()
		meta.slot = i
		if FileAccess.file_exists(_slot_path(i)):
			var file := FileAccess.open(_slot_path(i), FileAccess.READ)
			if file:
				var json: Variant = JSON.parse_string(file.get_as_text())
				file.close()
				if json is Dictionary and _is_valid(json):
					meta.timestamp = json.get("saved_at", "")
					var run_data: Dictionary = json.get("run", {})
					meta.difficulty = run_data.get("difficulty", "")
					meta.is_empty = false
		result.append(meta)
	return result


# auto_save(): Queues a deferred save to avoid writing mid-physics.
# slot: Zero-based save slot index to save to.
#
# Defers via call_deferred; use this from physics callbacks instead of
# calling save() directly.
func auto_save(slot: int) -> void:
	call_deferred("save", slot)


# _slot_path(): Returns the file path for a given slot index.
# slot: Zero-based save slot index.
# return: Absolute path string under user://saves/.
#
# Returns a path in the form user://saves/slot_N.json for slot index N.
func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot


# _is_valid(): Returns true when data contains the required save keys.
# data: Parsed JSON dictionary to validate.
# return: True if version and run keys are present.
#
# Does not validate field types or version numbers; only checks for the
# presence of the required top-level keys.
func _is_valid(data: Dictionary) -> bool:
	return data.has("version") and data.has("run")


# _serialize_run(): Converts a RunData resource into a plain Dictionary.
# run: The RunData instance to serialize.
# return: Dictionary safe for JSON serialization.
#
# Converts enum values to their string keys for human-readable JSON output.
func _serialize_run(run: RunData) -> Dictionary:
	return {
		"difficulty": Enums.DifficultyLevel.find_key(run.difficulty),
	}


# _deserialize_run(): Reconstructs a RunData resource from a saved Dictionary.
# data: The run sub-dictionary from a parsed save file.
# return: A populated RunData instance.
#
# Falls back to NORMAL difficulty when the saved difficulty string is not a
# valid DifficultyLevel key.
func _deserialize_run(data: Dictionary) -> RunData:
	var run := RunData.new()
	var diff_str: String = data.get("difficulty", "NORMAL")
	run.difficulty = Enums.DifficultyLevel.get(diff_str, Enums.DifficultyLevel.NORMAL)
	return run
