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

@tool
class_name LevelBounds
extends Node2D

@export var font: Font
@export var font_size: int = 16

@export var extents: Vector2 = Vector2(960.0, 540.0):
	set(value):
		extents = value
		queue_redraw()


func _ready() -> void:
	add_to_group("level_bounds")


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var rect := Rect2(-extents, extents * 2.0)

	# Draw rectangle
	draw_rect(rect, Color.YELLOW, false, 5.0)

	# Draw label
	if font:
		var text := "Level Bounds"

		# Measure text size
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

		# Top-left, above the rectangle
		var padding := Vector2(8, 8)
		var pos := rect.position + Vector2(padding.x, -padding.y)

		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)


func get_bounds_rect() -> Rect2:
	return Rect2(global_position - extents, extents * 2.0)
