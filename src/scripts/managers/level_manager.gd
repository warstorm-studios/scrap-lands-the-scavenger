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

## Autoloaded singleton that handles scene loading, screen fade transitions,
## checkpoint tracking, and player spawning.
extends Node

## Emitted after a new scene finishes loading and the player is spawned.
signal level_loaded(scene_path: String)
## Emitted when the current level's win condition triggers a scene change.
signal level_complete()
## Emitted just before placing the player, with the resolved spawn position.
signal player_spawn_requested(position: Vector2)

## Default player scene to instantiate when no [LevelConfig] override exists.
## Assign once at boot from a boot scene or game-specific autoload.
var default_player_scene: PackedScene

var _active_spawn_position: Vector2 = Vector2.ZERO
var _active_spawn_set: bool = false
var _active_checkpoint_id: String = ""
var _registered_checkpoints: Array = []
var _spawn_points: Array = []
var _current_scene_path: String = ""

var _canvas_layer: CanvasLayer
var _transition_overlay: ColorRect
var _is_loading: bool = false


# _ready(): Builds the fade overlay, connects signals, and spawns the player.
#
# Waits one frame before spawning so all scene _ready() calls finish first.
func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_transition_overlay)

	SignalBus.character_died.connect(_on_character_died)

	# Capture path of whatever scene Godot loaded directly (F6 / main scene),
	# then spawn the player. One frame wait ensures all scene _ready() have run
	# (checkpoints registered, LevelConfig in group) before we try to use them.
	await get_tree().process_frame
	if get_tree().current_scene and _current_scene_path.is_empty():
		_current_scene_path = get_tree().current_scene.scene_file_path
		_spawn_player()


# load_scene(): Transitions to a new scene and spawns the player.
# path: Filesystem path of the scene to load.
# transition: Visual transition style; defaults to FADE.
#
# No-ops when a load is already in progress. Resets active spawn data
# before loading so the new scene's checkpoints take effect.
func load_scene(
	path: String,
	transition: Enums.TransitionType = Enums.TransitionType.FADE
) -> void:
	if _is_loading:
		return
	_is_loading = true
	_active_spawn_set = false
	_active_checkpoint_id = ""
	_active_spawn_position = Vector2.ZERO

	var config := _get_level_config()
	var out_transition: Enums.TransitionType = config.transition_out if config else transition
	await _do_load(path, out_transition)
	_is_loading = false


# reload_current_scene(): Reloads the current scene in-place.
# transition: Visual transition style; defaults to FADE.
#
# No-ops when a load is in progress or no scene path is recorded.
# Used internally by _on_character_died to respawn after player death.
func reload_current_scene(
	transition: Enums.TransitionType = Enums.TransitionType.FADE
) -> void:
	if _is_loading or _current_scene_path.is_empty():
		return
	_is_loading = true

	var config := _get_level_config()
	var out_transition: Enums.TransitionType = config.transition_out if config else transition
	await _do_load(_current_scene_path, out_transition)
	_is_loading = false


# register_checkpoint(): Registers a checkpoint node with LevelManager.
# checkpoint: The Checkpoint node to register.
#
# Must be called by Checkpoint nodes in their _ready. Avoids duplicates.
# Required for activate_checkpoint and get_spawn_position to work.
func register_checkpoint(checkpoint: Node) -> void:
	if not _registered_checkpoints.has(checkpoint):
		_registered_checkpoints.append(checkpoint)


# register_spawn_point(): Registers a spawn point node as a fallback.
# spawn_point: The spawn point node to register.
#
# Used by get_spawn_position when no checkpoint has been activated.
# Must be called by spawn point nodes in their _ready.
func register_spawn_point(spawn_point: Node) -> void:
	if not _spawn_points.has(spawn_point):
		_spawn_points.append(spawn_point)


# activate_checkpoint(): Sets a checkpoint as the active spawn point.
# checkpoint: The Checkpoint node to activate.
#
# Records its position plus spawn_offset as the active spawn location.
# Marks all other registered checkpoints as used.
func activate_checkpoint(checkpoint: Node) -> void:
	_active_spawn_position = checkpoint.global_position + checkpoint.get("spawn_offset")
	_active_spawn_set = true
	_active_checkpoint_id = checkpoint.get("checkpoint_id")

	for cp in _registered_checkpoints:
		if cp != checkpoint and cp.has_method("set_used"):
			cp.set_used()
	if checkpoint.has_method("set_active"):
		checkpoint.set_active()


# get_spawn_position(): Returns the resolved spawn position for the player.
# return: The active spawn position, or Vector2.ZERO as a last resort.
#
# Falls back in order: active checkpoint → first registered checkpoint
# → first registered spawn point → Vector2.ZERO.
func get_spawn_position() -> Vector2:
	if _active_spawn_set:
		return _active_spawn_position
	# Entry-point override: find the checkpoint whose ID matches.
	if not GameManager.pending_entry_id.is_empty():
		for cp: Node in _registered_checkpoints:
			if cp and is_instance_valid(cp):
				if cp.get("checkpoint_id") == GameManager.pending_entry_id:
					return cp.global_position + cp.get("spawn_offset")
	# Default: first checkpoint in the scene acts as the level start.
	if not _registered_checkpoints.is_empty():
		var cp: Node = _registered_checkpoints[0]
		if cp and is_instance_valid(cp):
			return cp.global_position + cp.get("spawn_offset")
	if not _spawn_points.is_empty():
		var sp: Node = _spawn_points[0]
		if sp and is_instance_valid(sp):
			return sp.global_position
	return Vector2.ZERO


# _do_load(): Fades out, changes scene, fades in, then spawns the player.
# path: Filesystem path of the scene to load.
# transition: Visual transition style to apply.
#
# Disables gameplay input for the duration. Spawns the player after the
# fade-in so all scene nodes are ready and CameraRig is connected before
# player_spawn_requested fires.
func _do_load(path: String, transition: Enums.TransitionType) -> void:
	InputManager.disable_gameplay_input()
	SignalBus.scene_transition_started.emit(_current_scene_path, path)

	await _transition_out(transition)

	get_tree().change_scene_to_file(path)
	_current_scene_path = path
	_registered_checkpoints.clear()
	_spawn_points.clear()

	await get_tree().process_frame

	await _transition_in(transition)

	InputManager.enable_gameplay_input()
	level_loaded.emit(path)
	SignalBus.scene_transition_finished.emit(path)
	_spawn_player()


# _transition_out(): Animates the overlay to opaque; no-op for NONE.
# transition: Transition style that determines the animation used.
#
# Only FADE is currently implemented; WIPE variants are reserved for
# future work and behave as NONE until added.
func _transition_out(transition: Enums.TransitionType) -> void:
	if transition == Enums.TransitionType.NONE:
		return
	if transition == Enums.TransitionType.FADE:
		var tween := create_tween()
		tween.tween_property(_transition_overlay, "color:a", 1.0, 0.3)
		await tween.finished


# _transition_in(): Animates the overlay back to clear; no-op for NONE.
# transition: Transition style that determines the animation used.
#
# Only FADE is currently implemented; WIPE variants are reserved for
# future work and behave as NONE until added.
func _transition_in(transition: Enums.TransitionType) -> void:
	if transition == Enums.TransitionType.NONE:
		return
	if transition == Enums.TransitionType.FADE:
		var tween := create_tween()
		tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)
		await tween.finished


# _get_level_config(): Returns the first LevelConfig node in group, or null.
# return: LevelConfig from the current scene, or null if absent.
#
# Callers must handle the null return when no LevelConfig is present,
# using a fallback transition or spawn behaviour instead.
func _get_level_config() -> LevelConfig:
	return get_tree().get_first_node_in_group("level_config") as LevelConfig


# _spawn_player(): Repositions a persistent player or instantiates a new one.
#
# Emits player_spawn_requested with the resolved spawn position in both cases.
func _spawn_player() -> void:
	var spawn_pos := get_spawn_position()
	GameManager.pending_entry_id = ""

	# 1. Persistent player already in the tree — just reposition.
	var persistent := get_tree().get_first_node_in_group("persistent_player")
	if persistent:
		player_spawn_requested.emit(spawn_pos)
		return

	# 2. Determine which scene to instantiate:
	# LevelConfig override → global default.
	var config := _get_level_config()
	var scene_to_use: PackedScene = null
	if config and config.player_scene:
		scene_to_use = config.player_scene
	elif default_player_scene:
		scene_to_use = default_player_scene

	if scene_to_use:
		var player := scene_to_use.instantiate()
		get_tree().current_scene.add_child(player)

	# Always emit — Character nodes connect to this in _ready() for repositioning.
	player_spawn_requested.emit(spawn_pos)


# _on_character_died(): Reloads the current scene when the player dies.
# character: The node that died; checked for CharacterType.PLAYER.
#
# Reads character_type directly to avoid a class dependency; assumes
# 0 == CharacterType.PLAYER.
func _on_character_died(character: Node) -> void:
	if character.get("character_type") == 0:  # CharacterType.PLAYER = 0
		reload_current_scene()
