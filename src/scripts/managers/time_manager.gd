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

## Autoloaded singleton that manages [code]Engine.time_scale[/code] via
## named requests. Multiple systems can slow time independently; the lowest
## requested scale wins. Timed requests expire automatically.
extends Node

## The current engine time scale (read-only; use [method request_time_scale]).
var current_scale: float:
	get: return Engine.time_scale

## Emitted whenever the applied time scale changes.
signal scale_changed(new_scale: float)

var _requests: Dictionary = {}  # id -> {scale, duration, elapsed}


# request_time_scale(): Registers a named time-scale request.
# id: Unique key for this request; overwrites any existing entry.
# scale: Desired time scale (1.0 = normal, < 1.0 = slow motion).
# duration: Auto-release after this many unscaled seconds; 0 = persistent.
#
# The lowest scale among all active requests wins. Calls _apply immediately.
func request_time_scale(id: String, scale: float, duration: float = 0.0) -> void:
	_requests[id] = {"scale": scale, "duration": duration, "elapsed": 0.0}
	_apply()


# release_time_scale(): Removes the named request and recalculates the scale.
# id: Key of the request to remove.
#
# If no requests remain after removal, Engine.time_scale is restored to 1.0.
func release_time_scale(id: String) -> void:
	_requests.erase(id)
	_apply()


# reset(): Cancels all active requests and restores Engine.time_scale to 1.0.
#
# Equivalent to calling release_time_scale for every active request at once.
func reset() -> void:
	_requests.clear()
	_apply()


# has_request(): Returns true if a request with the given id is active.
# id: Key of the request to check.
# return: True when the id exists in the active request map.
#
# Does not distinguish between timed and persistent requests.
func has_request(id: String) -> bool:
	return _requests.has(id)


# _process(): Advances elapsed time on timed requests; expires finished ones.
# delta: Scaled engine delta time used for elapsed tracking.
#
# Uses unscaled time (delta / time_scale) so request durations are measured
# in real-world seconds regardless of the active time scale.
func _process(delta: float) -> void:
	if _requests.is_empty():
		return
	# delta is scaled; divide to get real elapsed time for duration tracking
	var ts := Engine.time_scale
	var udt := delta / ts if ts > 0.0 else delta
	var expired: Array[String] = []
	for id: String in _requests:
		var req: Dictionary = _requests[id]
		if req["duration"] > 0.0:
			req["elapsed"] += udt
			if req["elapsed"] >= req["duration"]:
				expired.append(id)
	for id: String in expired:
		release_time_scale(id)


# _apply(): Picks the lowest active scale and writes it to Engine.time_scale.
#
# Restores 1.0 when no requests remain. Emits scale_changed and
# SignalBus.time_scale_changed after every update.
func _apply() -> void:
	if _requests.is_empty():
		Engine.time_scale = 1.0
	else:
		var min_scale := 1.0
		for req: Dictionary in _requests.values():
			if req["scale"] < min_scale:
				min_scale = req["scale"]
		Engine.time_scale = min_scale
	scale_changed.emit(Engine.time_scale)
	SignalBus.time_scale_changed.emit(Engine.time_scale)
