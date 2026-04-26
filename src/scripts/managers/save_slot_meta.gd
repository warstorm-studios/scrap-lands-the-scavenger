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

## Lightweight descriptor for a single save slot, used by the save-select UI.
## Populated by [method SaveManager.get_save_index].
class_name SaveSlotMeta

## Zero-based slot index.
var slot: int = 0
## ISO 8601 timestamp of the last save; empty when [member is_empty].
var timestamp: String = ""
## Human-readable difficulty label; empty when [member is_empty].
var difficulty: String = ""
## [code]true[/code] when this slot contains no save data.
var is_empty: bool = true
