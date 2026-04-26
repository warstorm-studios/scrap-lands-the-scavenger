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

class_name Hurtbox
extends Area2D

## Optional explicit health node path override.
# Optional explicit override; falls back to first Health found in parent chain.
@export var health_node: NodePath

## Cached health component target.
var _health: Health


# _ready(): Connects hurtbox overlap signal.
# return: No return value.
#
# Registers the area overlap callback used for incoming hit detection.
func _ready() -> void:
	area_entered.connect(_on_area_entered)


# get_parent_health(): Resolves health for this hurtbox.
# return: Health component to apply damage to, or null if none found.
#
# Uses explicit override first, then walks parent chain to locate a Health node.
func get_parent_health() -> Health:
	if _health:
		return _health
	if health_node and not health_node.is_empty():
		_health = get_node(health_node) as Health
	if not _health:
		_health = _find_health_in_parents()
	return _health


# _find_health_in_parents(): Searches parents for a Health node.
# return: First Health component found in parent hierarchy, or null.
#
# Looks for a child node named "Health" on each ancestor to support flexible
# scene compositions.
func _find_health_in_parents() -> Health:
	var node := get_parent()
	while node:
		var h := node.get_node_or_null("Health") as Health
		if h:
			return h
		node = node.get_parent()
	return null


# _on_area_entered(): Handles overlap with potential attacking hitboxes.
# area: Entering area that may represent an attack.
# return: No return value.
#
# Applies damage when the entering area is a Hitbox and reports a successful hit
# back to that hitbox.
func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		var health := get_parent_health()
		if health:
			health.take_damage(area.damage)
			area.on_hit(self)
