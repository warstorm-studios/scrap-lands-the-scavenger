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

class_name Hitbox
extends Area2D

signal hit_landed(target_hurtbox: Area2D)

@export var damage: TypedDamage
@export var active: bool = true
@export var one_hit_per_activation: bool = true

var _hit_targets: Array = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = active


func activate(duration: float = 0.0) -> void:
	active = true
	monitoring = true
	_hit_targets.clear()
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		deactivate()


func deactivate() -> void:
	active = false
	monitoring = false
	_hit_targets.clear()


func on_hit(_hurtbox: Area2D) -> void:
	SignalBus.play_sfx_requested.emit("sfx_hit")


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	if not area is Hurtbox:
		return
	if one_hit_per_activation and area in _hit_targets:
		return
	_hit_targets.append(area)
	hit_landed.emit(area)
