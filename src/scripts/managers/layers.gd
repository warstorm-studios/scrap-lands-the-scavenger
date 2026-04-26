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

## Collision layer and mask constants for all physics objects in the game.
## Always use these constants — never raw integers. Layer N maps to bit
## [code](N-1)[/code], e.g. layer 1 = [code]1 << 0[/code].
class_name Layers

# Layer bit masks — match project.godot [layer_names] 2d_physics entries.
# Usage: node.collision_layer = Layers.PLAYER
# Layer N = bit (N-1), so layer 1 = 1 << 0, layer 5 = 1 << 4, etc.

const PLAYER            := 1 << 0
const ENEMY             := 1 << 1
const PROJECTILE_PLAYER := 1 << 2
const PROJECTILE_ENEMY  := 1 << 3
const PLATFORM          := 1 << 4
const PLATFORM_ONE_WAY  := 1 << 5
const KILL_ZONE         := 1 << 6
const PICKUP            := 1 << 7
const TRIGGER           := 1 << 8
const HURTBOX_PLAYER    := 1 << 9
const HURTBOX_ENEMY     := 1 << 10
const HITBOX_PLAYER     := 1 << 11
const HITBOX_ENEMY      := 1 << 12
const INTERACTABLE      := 1 << 13
const WATER             := 1 << 14
const LADDER            := 1 << 15
const CAMERA_BOUNDS     := 1 << 16

# Collision masks — what each node type scans for (see 10-collision-layers.md).
const MASK_PLAYER_BODY       := PLATFORM | PLATFORM_ONE_WAY
const MASK_ENEMY_BODY        := PLATFORM | PLATFORM_ONE_WAY
const MASK_HURTBOX_PLAYER    := HITBOX_ENEMY | KILL_ZONE
const MASK_HURTBOX_ENEMY     := HITBOX_PLAYER
const MASK_HITBOX_PLAYER     := HURTBOX_ENEMY
const MASK_HITBOX_ENEMY      := HURTBOX_PLAYER
const MASK_PROJECTILE_PLAYER := HURTBOX_ENEMY | PLATFORM
const MASK_PROJECTILE_ENEMY  := HURTBOX_PLAYER | PLATFORM
const MASK_PICKUP            := PLAYER
const MASK_KILL_ZONE         := HURTBOX_PLAYER | HURTBOX_ENEMY
const MASK_INTERACTABLE      := PLAYER
const MASK_WATER             := PLAYER | ENEMY
const MASK_LADDER            := PLAYER
