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

class_name Health
extends Node

## Emitted when HP changes.
signal health_changed(old_val: int, new_val: int, max_val: int)
## Emitted when this node takes non-zero damage.
signal damaged(amount: int, damage_type: int)
## Emitted when this node receives healing.
signal healed(amount: int)
## Emitted when HP reaches zero.
signal died()
## Emitted when this node is revived.
signal revived()
## Emitted when invincibility starts.
signal invincibility_started()
## Emitted when invincibility ends.
signal invincibility_ended()

## Maximum HP value.
@export var max_hp: int = 10
## Invincibility window duration after taking non-void damage.
@export var invincibility_duration: float = 1.2
## Flat damage reduction applied to non-void damage.
@export var damage_reduction: int = 0

## Current HP value.
var current_hp: int
## Whether damage is currently ignored.
var is_invincible: bool = false
## Whether this health component is dead.
var is_dead: bool = false

## Damage-type to resistance amount map.
var resistances: Dictionary = {}
## Damage types that are fully ignored.
var immunities: Array = []

## Persistent invincibility override flag.
var _forced_invincible: bool = false


# _ready(): Initializes runtime health state.
# return: No return value.
#
# Sets current HP to max HP on scene startup.
func _ready() -> void:
	current_hp = max_hp


# take_damage(): Applies incoming damage to health.
# damage: Typed damage payload containing amount and damage type.
# return: No return value.
#
# Applies immunity/reduction/resistance checks, emits change signals, handles
# post-hit invincibility, and triggers death when HP reaches zero.
func take_damage(damage: TypedDamage) -> void:
	if is_dead:
		return
	var is_void := damage.type == Enums.DamageType.VOID
	if is_invincible and not is_void:
		return
	if damage.type in immunities:
		return

	var resistance: int = resistances.get(damage.type, 0)
	var reduction: int = 0 if is_void else damage_reduction
	var final_amount: int = max(0, damage.amount - reduction - resistance)
	if final_amount <= 0:
		return

	var old := current_hp
	current_hp = max(0, current_hp - final_amount)
	health_changed.emit(old, current_hp, max_hp)
	damaged.emit(final_amount, damage.type)
	SignalBus.health_changed.emit(get_parent(), old, current_hp, max_hp)

	if not is_void:
		_start_invincibility()

	if current_hp == 0:
		is_dead = true
		died.emit()


# heal(): Restores HP up to max HP.
# amount: Requested healing amount.
# return: No return value.
#
# Clamps heal amount so HP never exceeds max HP and emits change/heal signals
# only when healing actually occurred.
func heal(amount: int) -> void:
	if is_dead:
		return
	var old := current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual := current_hp - old
	if actual > 0:
		health_changed.emit(old, current_hp, max_hp)
		healed.emit(actual)


# kill(): Forces HP to zero and enters dead state.
# return: No return value.
#
# Immediately marks the component dead, clears invincibility, and emits death
# related signals.
func kill() -> void:
	if is_dead:
		return
	var old := current_hp
	current_hp = 0
	is_dead = true
	is_invincible = false
	_forced_invincible = false
	health_changed.emit(old, current_hp, max_hp)
	died.emit()


# revive(): Revives with explicit HP or max HP.
# hp: Optional HP value; use max HP when set to -1.
# return: No return value.
#
# Clears dead/invincibility state, restores HP within valid range, and emits a
# revive signal.
func revive(hp: int = -1) -> void:
	is_dead = false
	is_invincible = false
	_forced_invincible = false
	current_hp = hp if hp > 0 else max_hp
	current_hp = clamp(current_hp, 1, max_hp)
	health_changed.emit(0, current_hp, max_hp)
	revived.emit()


# reset(): Resets to default alive full-health state.
# return: No return value.
#
# Used on respawn/restart flows to restore base health configuration.
func reset() -> void:
	is_dead = false
	is_invincible = false
	_forced_invincible = false
	var old := current_hp
	current_hp = max_hp
	health_changed.emit(old, current_hp, max_hp)


# set_invincible(): Toggles forced invincibility state.
# enabled: True to force invincibility, false to release forced state.
# return: No return value.
#
# This override is independent from temporary hit invincibility and controls
# whether invincibility state should be maintained persistently.
func set_invincible(enabled: bool) -> void:
	_forced_invincible = enabled
	if enabled and not is_invincible:
		is_invincible = true
		invincibility_started.emit()
	elif not enabled and not _forced_invincible:
		is_invincible = false
		invincibility_ended.emit()


# _start_invincibility(): Starts temporary invincibility timer.
# return: No return value.
#
# Grants invincibility for the configured duration unless forced invincibility
# keeps it active afterward.
func _start_invincibility() -> void:
	is_invincible = true
	invincibility_started.emit()
	await get_tree().create_timer(invincibility_duration).timeout
	if not _forced_invincible:
		is_invincible = false
		invincibility_ended.emit()
