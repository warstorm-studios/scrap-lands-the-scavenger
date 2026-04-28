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

## Shared enumerations used across all game systems.
class_name Enums

## Game difficulty; stored in [RunData] and shown in the save-select UI.
enum DifficultyLevel {
	EASY,
	NORMAL,
	HARD,
}

## Scene transition style used by [method LevelManager.load_scene].
enum TransitionType { NONE, FADE, WIPE_LEFT, WIPE_RIGHT }

## Damage category applied to a [TypedDamage] payload.
## VOID bypasses resistances, damage reduction, and invincibility frames.
enum DamageType { DEFAULT, VOID }
