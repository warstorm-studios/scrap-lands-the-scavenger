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

class_name CameraRig
extends Camera2D

## Camera2D with deadzone follow, level-bounds clamping, room transitions,
## and a trauma-based screen shake system.

## Target node the camera lerps toward each frame.
@export var follow_target: Node2D
## Lerp speed used when the target is outside the deadzone.
@export var follow_lerp_speed: float = 8.0
## Half-width of the deadzone; camera starts moving once offset exceeds this.
@export var deadzone_x: float = 32.0
## Half-height of the deadzone; camera starts moving once offset exceeds this.
@export var deadzone_y: float = 48.0
## When true, the camera position is clamped inside the active level bounds.
@export var clamp_to_bounds: bool = true

@export_group("Shake")
## Maximum pixel radius of the shake displacement at full trauma.
@export var max_shake_offset: float = 16.0

## Emitted when a room-lock transition begins; carries the from and to rects.
signal room_transition_started(from_rect: Rect2, to_rect: Rect2)
## Emitted when the room-lock pan animation completes and follow resumes.
signal room_transition_finished()

var _bounds_rect: Rect2 = Rect2()
var _half_size: Vector2 = Vector2.ZERO
var _is_locked: bool = false
var _trauma: float = 0.0
var _shake_duration: float = 0.1
var _lock_tween: Tween
var _shift_offset: Vector2 = Vector2.ZERO
var _shift_tween: Tween


# _ready(): Enables the camera, reads level bounds, and connects spawn signal.
#
# Connects to LevelManager.player_spawn_requested so the camera re-acquires
# its target whenever the player is repositioned.
func _ready() -> void:
	enabled = true
	_read_bounds()
	LevelManager.player_spawn_requested.connect(_on_player_spawned)


# _exit_tree(): Disconnects the spawn signal on scene unload.
#
# Prevents a stale connection from firing after this node has left the tree
# during a scene transition where queue_free defers the actual memory release.
func _exit_tree() -> void:
	if LevelManager.player_spawn_requested.is_connected(_on_player_spawned):
		LevelManager.player_spawn_requested.disconnect(_on_player_spawned)


# _process(): Follows the target each frame and applies the shake offset.
# delta: Time elapsed since the last frame.
#
# Skips the follow step while the camera is locked during a room transition.
func _process(delta: float) -> void:
	if not _is_locked and follow_target:
		_follow(delta)
	_apply_shake(delta)


# --- Public API ---

# shake(): Adds trauma to the shake system for the given duration.
# trauma: Amount to add to current trauma (0.0–1.0); clamped at 1.0 total.
# duration: How long (in seconds) the trauma takes to decay to zero.
#
# Trauma values stack additively up to 1.0. Screen displacement scales as
# trauma squared so small values produce subtle effects.
func shake(trauma: float, duration: float) -> void:
	_trauma = clampf(_trauma + trauma, 0.0, 1.0)
	_shake_duration = maxf(duration, 0.01)


# shift_camera(): Smoothly translates the camera by a world-space offset.
# target_offset: The offset to tween the camera to, in world space.
# duration: Duration of the eased transition in seconds.
#
# Kills any in-progress shift before starting a new one. Used to pan the
# camera during cutscenes or ability previews.
func shift_camera(target_offset: Vector2, duration: float) -> void:
	if _shift_tween:
		_shift_tween.kill()
	_shift_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shift_tween.tween_property(self, "_shift_offset", target_offset, duration)


# lock_to_room(): Pans the camera to a room centre and locks it there.
# room_rect: The bounding rectangle of the target room in world space.
# transition_duration: Duration of the pan animation; defaults to 0.4 s.
#
# Disables gameplay input for the transition duration. Emits
# room_transition_started and SignalBus.scene_transition_started on entry.
# Unlocks and re-enables input via _on_room_transition_done on completion.
func lock_to_room(room_rect: Rect2, transition_duration: float = 0.4) -> void:
	var from_rect := _bounds_rect
	_is_locked = true
	_bounds_rect = room_rect
	InputManager.disable_gameplay_input()
	room_transition_started.emit(from_rect, room_rect)
	SignalBus.scene_transition_started.emit("", "")

	var target_pos := room_rect.get_center()
	if _lock_tween:
		_lock_tween.kill()
	_lock_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_lock_tween.tween_property(self, "global_position", target_pos, transition_duration)
	_lock_tween.tween_callback(_on_room_transition_done)


# unlock(): Restores free-follow mode after a room lock.
#
# Sets _is_locked to false so _process resumes calling _follow each frame.
func unlock() -> void:
	_is_locked = false


# snap_to_target(): Instantly moves the camera to the follow target.
#
# Used after spawn to avoid a visible lag frame before the lerp catches up.
func snap_to_target() -> void:
	if follow_target:
		global_position = follow_target.global_position


# --- Internal ---

# _on_player_spawned(): Re-acquires the player controller and snaps to spawn pos.
# pos: The resolved spawn position emitted by LevelManager.
#
# Finds the node in the player_controller group, assigns it as follow_target,
# refreshes level bounds, and positions the camera at the spawn location.
# Uses pos directly rather than follow_target.global_position because this
# signal fires before Character._on_spawn_requested moves the player body.
func _on_player_spawned(pos: Vector2) -> void:
	var pc := get_tree().get_first_node_in_group("player_controller") as PlayerController
	if pc:
		follow_target = pc
	_read_bounds()
	global_position = pos


# _follow(): Lerps the camera toward the follow target within a deadzone.
# delta: Time elapsed since the last frame.
#
# Movement only starts once the target exits the deadzone rectangle.
# Clamps the result inside _bounds_rect when clamp_to_bounds is true and
# the level is larger than the viewport half-size.
func _follow(delta: float) -> void:
	if not is_instance_valid(follow_target):
		follow_target = null
		return
	var target_pos := follow_target.global_position
	var cam_pos := global_position

	var offset := target_pos - cam_pos
	if absf(offset.x) > deadzone_x:
		cam_pos.x = lerpf(cam_pos.x, target_pos.x, follow_lerp_speed * delta)
	if absf(offset.y) > deadzone_y:
		cam_pos.y = lerpf(cam_pos.y, target_pos.y, follow_lerp_speed * delta)

	if clamp_to_bounds and _bounds_rect != Rect2():
		if _bounds_rect.size.x > _half_size.x * 2.0:
			cam_pos.x = clampf(cam_pos.x, _bounds_rect.position.x + _half_size.x, _bounds_rect.end.x - _half_size.x)
		if _bounds_rect.size.y > _half_size.y * 2.0:
			cam_pos.y = clampf(cam_pos.y, _bounds_rect.position.y + _half_size.y, _bounds_rect.end.y - _half_size.y)

	global_position = cam_pos


# _apply_shake(): Applies the current trauma as a random position offset.
# delta: Time elapsed since the last frame; used to decay trauma.
#
# Offset is added on top of _shift_offset so both systems compose cleanly.
# Trauma decays proportionally to delta / _shake_duration each frame.
func _apply_shake(delta: float) -> void:
	var result := _shift_offset
	if _trauma > 0.0:
		var amount := _trauma * _trauma
		result += Vector2(
			randf_range(-max_shake_offset, max_shake_offset) * amount,
			randf_range(-max_shake_offset, max_shake_offset) * amount
		)
		_trauma = maxf(0.0, _trauma - delta / _shake_duration)
	offset = result


# _read_bounds(): Reads the LevelBounds node and caches rect and half-size.
#
# No-op when no node in the level_bounds group is found. Called in _ready
# and on each player spawn to pick up per-level bound changes.
func _read_bounds() -> void:
	var lb := get_tree().get_first_node_in_group("level_bounds") as LevelBounds
	if not lb:
		return
	_bounds_rect = lb.get_bounds_rect()
	var viewport_size := get_viewport_rect().size
	_half_size = viewport_size * 0.5


# _on_room_transition_done(): Finishes the room lock and re-enables input.
#
# Called by the lock_to_room tween on completion. Re-enables gameplay input,
# emits room_transition_finished and SignalBus signals, then clears the lock.
func _on_room_transition_done() -> void:
	InputManager.enable_gameplay_input()
	room_transition_finished.emit()
	SignalBus.scene_transition_finished.emit("")
	_is_locked = false
