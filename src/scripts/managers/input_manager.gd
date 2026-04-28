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

## Autoloaded singleton that samples raw input each physics frame and exposes
## named axes and booleans. Suppression stacking lets multiple systems disable
## gameplay input independently without stomping each other.
extends Node

## Horizontal axis: negative = left, positive = right.
var horizontal: float = 0.0
## Vertical axis: negative = up, positive = down.
var vertical: float = 0.0

## [code]true[/code] for one frame when jump is first pressed.
var jump_pressed: bool = false
## [code]true[/code] while jump is held.
var jump_held: bool = false
## [code]true[/code] for one frame when jump is released.
var jump_released: bool = false

## [code]true[/code] for one frame when dash is first pressed.
var dash_pressed: bool = false
## [code]true[/code] while the run modifier is held.
var run_held: bool = false
## [code]true[/code] for one frame when attack is first pressed.
var attack_pressed: bool = false
## [code]true[/code] while attack is held.
var attack_held: bool = false

## [code]true[/code] for one frame when interact is first pressed.
var interact_pressed: bool = false
## [code]true[/code] for one frame when pause is first pressed.
var pause_pressed: bool = false

var _suppression_count: int = 0


# _ready(): Registers default input actions on enter-tree.
#
# Calls _register_default_actions once; all subsequent input sampling
# happens each physics frame in _physics_process.
func _ready() -> void:
	_register_default_actions()


# _physics_process(): Samples raw input each physics frame into typed fields.
# _delta: Unused; required by the engine callback signature.
#
# Zeros all fields when gameplay input is suppressed.
func _physics_process(_delta: float) -> void:
	if not is_gameplay_input_enabled():
		horizontal = 0.0
		vertical = 0.0
		jump_pressed = false
		jump_held = false
		jump_released = false
		dash_pressed = false
		run_held = false
		attack_pressed = false
		attack_held = false
		interact_pressed = false
		pause_pressed = false
		return

	horizontal = Input.get_axis("Player1_Left", "Player1_Right")
	vertical = Input.get_axis("Player1_Up", "Player1_Down")

	jump_pressed = Input.is_action_just_pressed("Player1_Jump")
	jump_held = Input.is_action_pressed("Player1_Jump")
	jump_released = Input.is_action_just_released("Player1_Jump")

	dash_pressed = Input.is_action_just_pressed("Player1_Dash")
	run_held = Input.is_action_pressed("Player1_Run")
	attack_pressed = Input.is_action_just_pressed("Player1_Attack")
	attack_held = Input.is_action_pressed("Player1_Attack")

	interact_pressed = Input.is_action_just_pressed("Player1_Interact")
	pause_pressed = Input.is_action_just_pressed("Player1_Pause")


# disable_gameplay_input(): Increments the suppression counter.
#
# All gameplay axes and button fields zero out while the counter is above
# zero. Multiple callers can suppress input independently.
func disable_gameplay_input() -> void:
	_suppression_count += 1


# enable_gameplay_input(): Decrements the suppression counter.
#
# Input resumes when the counter reaches zero. The counter is clamped to
# a minimum of 0, so extra enable calls are safe.
func enable_gameplay_input() -> void:
	_suppression_count = max(0, _suppression_count - 1)


# is_gameplay_input_enabled(): Returns true when no suppression is active.
# return: True when the suppression counter is zero.
#
# A false return means at least one system has called disable_gameplay_input
# without a matching enable_gameplay_input.
func is_gameplay_input_enabled() -> bool:
	return _suppression_count == 0


# remap_action(): Replaces all bindings for an action with a new event.
# action_name: InputMap action name whose events will be replaced.
# new_event: The single InputEvent to bind to the action.
#
# No-ops silently when action_name is not registered in InputMap.
func remap_action(action_name: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		return
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)


# _register_default_actions(): Adds default keyboard bindings if absent.
#
# Each action is added only when missing from InputMap, so project-level
# bindings and prior remaps are preserved.
func _register_default_actions() -> void:
	_add_if_missing("Player1_Left",     [_key(KEY_A), _key(KEY_LEFT)])
	_add_if_missing("Player1_Right",    [_key(KEY_D), _key(KEY_RIGHT)])
	_add_if_missing("Player1_Down",     [_key(KEY_S), _key(KEY_DOWN)])
	_add_if_missing("Player1_Up",       [_key(KEY_W), _key(KEY_UP)])
	_add_if_missing("Player1_Jump",     [_key(KEY_SPACE)])
	_add_if_missing("Player1_Dash",     [_key(KEY_F)])
	_add_if_missing("Player1_Run",      [_key(KEY_SHIFT)])
	_add_if_missing("Player1_Attack",   [_key(KEY_C)])
	_add_if_missing("Player1_Interact", [_key(KEY_E)])
	_add_if_missing("Player1_Pause",    [_key(KEY_ESCAPE)])
	_add_if_missing("UI_Up",            [_key(KEY_UP)])
	_add_if_missing("UI_Down",          [_key(KEY_DOWN)])
	_add_if_missing("UI_Left",          [_key(KEY_LEFT)])
	_add_if_missing("UI_Right",         [_key(KEY_RIGHT)])
	_add_if_missing("UI_Accept",        [_key(KEY_ENTER), _key(KEY_SPACE)])
	_add_if_missing("UI_Cancel",        [_key(KEY_ESCAPE)])


# _add_if_missing(): Registers action with events only when not in InputMap.
# action: InputMap action name to register.
# events: Array of InputEvent instances to bind to the action.
#
# Preserves existing InputMap entries, so project-level bindings and
# runtime remaps made via remap_action are never overwritten.
func _add_if_missing(action: String, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for event in events:
		InputMap.action_add_event(action, event)


# _key(): Creates a bare InputEventKey for the given keycode.
# keycode: Key constant from the Key enum.
# return: A new InputEventKey with only keycode set.
#
# Modifier fields (shift, ctrl, alt) are left at their default false values.
func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event
