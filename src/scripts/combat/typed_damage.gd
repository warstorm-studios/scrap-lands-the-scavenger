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

class_name TypedDamage
extends Resource

@export var amount: int = 0
@export var type: Enums.DamageType = Enums.DamageType.DEFAULT
@export var knockback: Vector2 = Vector2.ZERO

# Not exported — set at runtime only (nodes can't be serialized as resource fields).
var source: Node


static func create(
	p_amount: int,
	p_type: Enums.DamageType = Enums.DamageType.DEFAULT,
	p_source: Node = null
) -> TypedDamage:
	var d := TypedDamage.new()
	d.amount = p_amount
	d.type = p_type
	d.source = p_source
	return d
