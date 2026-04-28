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

class_name PlayerController extends CharacterBody2D

## Frame snapshot consumed by character abilities.
# ControllerState is read each frame by all abilities.
class ControllerState:
	## True when standing on floor this frame.
	var is_grounded: bool = false
	## True when grounded in previous frame.
	var was_grounded: bool = false
	## True when touching a ceiling.
	var is_on_ceiling: bool = false
	## True when touching a wall on the left.
	var is_on_wall_left: bool = false
	## True when touching a wall on the right.
	var is_on_wall_right: bool = false
	## True when overhead raycasts detect a blocker.
	var is_ceiling_blocked: bool = false
	## True when standing on one-way platform geometry.
	var is_on_one_way_platform: bool = false
	## True when floor normal indicates an incline.
	var is_on_slope: bool = false
	## Current slope angle in degrees.
	var slope_angle: float = 0.0
	## Current floor normal or Vector2.UP while airborne.
	var ground_normal: Vector2 = Vector2.UP
	## Current body velocity.
	var current_velocity: Vector2 = Vector2.ZERO
	## Absolute horizontal speed.
	var current_speed: float = 0.0
	## Facing direction hint for movement systems.
	var facing_right: bool = true
	## Continuous airborne time in seconds.
	var time_in_air: float = 0.0
	## Continuous grounded time in seconds.
	var time_grounded: float = 0.0

## Gravity scale multiplier applied to project gravity.
@export var gravity_scale: float = 1.0
## Maximum downward velocity.
@export var max_fall_speed: float = 900.0
## If true, this controller ignores Engine.time_scale slowdown.
@export var time_scale_immune: bool = false

@export_group("Raycasts")
## Horizontal offset for ground-check ray origins.
@export var ground_ray_offset_x: float = 8.0
## Length of downward ground-check rays.
@export var ground_ray_length: float = 4.0
## Length of horizontal wall-check rays.
@export var wall_ray_length: float = 12.0
## Horizontal offset for ceiling-check ray origins.
@export var ceiling_ray_offset_x: float = 8.0
## Length of upward ceiling-check rays.
@export var ceiling_ray_length: float = 4.0

## Emitted once when transitioning from air to ground.
signal landed()
## Emitted once when transitioning from ground to air.
signal left_ground()
## Emitted once when first touching ceiling.
signal hit_ceiling()
## Emitted when first touching wall; -1 left, +1 right.
signal hit_wall(direction: int)  # -1 = left, +1 = right

## Public frame state snapshot.
var state := ControllerState.new()

## Cached project gravity value.
var _gravity: float
## Optional per-frame gravity override.
var _gravity_override: float = -1.0
## Countdown timer for one-way platform passthrough.
var _passthrough_timer: float = 0.0

## Left ground check ray.
var _ray_ground_left: RayCast2D
## Right ground check ray.
var _ray_ground_right: RayCast2D
## Left wall check ray.
var _ray_wall_left: RayCast2D
## Right wall check ray.
var _ray_wall_right: RayCast2D
## Left ceiling check ray.
var _ray_ceiling_left: RayCast2D
## Right ceiling check ray.
var _ray_ceiling_right: RayCast2D

## Previous frame ceiling state for transition events.
var _prev_on_ceiling: bool = false
## Previous frame left wall state for transition events.
var _prev_on_wall_left: bool = false
## Previous frame right wall state for transition events.
var _prev_on_wall_right: bool = false

# _ready(): Initializes gravity cache and helper raycasts.
# return: No return value.
#
# Reads project gravity once and builds all runtime raycasts used for state
# detection.
func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	_build_raycasts()

# _physics_process(): Applies gravity, movement, and controller updates.
# delta: Physics step delta in seconds.
# return: No return value.
#
# Handles one-way passthrough timing, applies gravity with optional override,
# performs move_and_slide, and refreshes frame state.
func _physics_process(delta: float) -> void:
	var dt := _get_delta(delta)

	# One-way platform passthrough countdown
	if _passthrough_timer > 0.0:
		_passthrough_timer -= dt
		if _passthrough_timer <= 0.0:
			set_collision_mask_value(6, true)

	# Gravity — abilities override per-frame via set_gravity_override()
	var g := _gravity_override if _gravity_override >= 0.0 else _gravity * gravity_scale
	velocity.y = min(velocity.y + g * dt, max_fall_speed)
	_gravity_override = -1.0

	move_and_slide()
	_update_state(dt)

# _update_state(): Refreshes frame state and transition signals.
# dt: Effective frame delta in seconds.
# return: No return value.
#
# Reads collision data and raycasts to update grounded/wall/ceiling/slope state,
# updates movement timers, and emits one-shot transition signals.
func _update_state(dt: float) -> void:
	state.was_grounded = state.is_grounded
	state.is_grounded = is_on_floor()
	state.is_on_ceiling = is_on_ceiling()
	state.is_on_wall_left = is_on_wall() and get_wall_normal().x > 0.0
	state.is_on_wall_right = is_on_wall() and get_wall_normal().x < 0.0
	state.is_ceiling_blocked = _ray_ceiling_left.is_colliding() or _ray_ceiling_right.is_colliding()

	state.is_on_one_way_platform = false
	if state.is_grounded:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if col.get_normal().y < -0.7:
				var collider := col.get_collider()
				if collider is CollisionObject2D and (collider.collision_layer & Layers.PLATFORM_ONE_WAY):
					state.is_on_one_way_platform = true
					break

	var floor_normal := get_floor_normal() if state.is_grounded else Vector2.UP
	state.is_on_slope = state.is_grounded and floor_normal != Vector2.UP
	state.slope_angle = rad_to_deg(floor_normal.angle_to(Vector2.UP))
	state.ground_normal = floor_normal
	state.current_velocity = velocity
	state.current_speed = absf(velocity.x)

	if state.is_grounded:
		state.time_in_air = 0.0
		state.time_grounded += dt
	else:
		state.time_in_air += dt
		state.time_grounded = 0.0

	# Transition signals — emit once per state change, not every frame
	if not state.was_grounded and state.is_grounded:
		landed.emit()
	elif state.was_grounded and not state.is_grounded:
		left_ground.emit()

	if state.is_on_ceiling and not _prev_on_ceiling:
		hit_ceiling.emit()
	if state.is_on_wall_left and not _prev_on_wall_left:
		hit_wall.emit(-1)
	if state.is_on_wall_right and not _prev_on_wall_right:
		hit_wall.emit(1)

	_prev_on_ceiling = state.is_on_ceiling
	_prev_on_wall_left = state.is_on_wall_left
	_prev_on_wall_right = state.is_on_wall_right

# --- Public API ---

# set_horizontal_velocity(): Sets horizontal velocity component.
# vx: New x-axis velocity.
# return: No return value.
#
# Convenience API used by abilities to drive lateral movement.
func set_horizontal_velocity(vx: float) -> void:
	velocity.x = vx

# set_vertical_velocity(): Sets vertical velocity component.
# vy: New y-axis velocity.
# return: No return value.
#
# Convenience API used by abilities to drive jumps and drops.
func set_vertical_velocity(vy: float) -> void:
	velocity.y = vy

# add_external_impulse(): Adds a velocity impulse.
# impulse: Velocity delta to add on both axes.
# return: No return value.
#
# Allows gameplay systems to apply knockback or burst motion without replacing
# current velocity.
func add_external_impulse(impulse: Vector2) -> void:
	velocity += impulse

# set_gravity_override(): Sets one-frame gravity override.
# g: Gravity value to use this frame.
# return: No return value.
#
# Lets abilities replace default gravity behavior for the current physics step.
func set_gravity_override(g: float) -> void:
	_gravity_override = g

# start_one_way_passthrough(): Temporarily disables one-way collisions.
# return: No return value.
#
# Turns off one-way layer mask briefly and nudges position downward so the body
# can drop through one-way platforms.
func start_one_way_passthrough() -> void:
	if _passthrough_timer > 0.0:
		return
	set_collision_mask_value(6, false)
	position.y += 2.0
	_passthrough_timer = 0.3

# Disables all CollisionShape2D children then enables the named one.
# Game dev is responsible for adding CollisionShape2D nodes with matching names.
# set_collider(): Enables a specific collision shape by node name.
# collider_name: CollisionShape2D child name to keep enabled.
# return: No return value.
#
# Disables all sibling collision shapes and keeps only the named shape active;
# logs a warning if no matching shape exists.
func set_collider(collider_name: String) -> void:
	var found := false
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = child.name != collider_name
			if child.name == collider_name:
				found = true
	if not found:
		push_warning("PlayerController: no CollisionShape2D named '%s'" % collider_name)

# --- Private ---

# _get_delta(): Computes effective delta with optional time-scale immunity.
# delta: Physics step delta from engine.
# return: Delta adjusted for time-scale immunity rules.
#
# When immune, divides by Engine.time_scale to preserve real-time behavior.
func _get_delta(delta: float) -> float:
	if not time_scale_immune:
		return delta
	var ts := Engine.time_scale
	return delta / ts if ts > 0.0 else delta

# _build_raycasts(): Creates and configures helper raycasts.
# return: No return value.
#
# Builds six raycasts used for ground, wall, and ceiling checks.
func _build_raycasts() -> void:
	_ray_ground_left   = _make_ray("RayCast2D_GroundLeft",   Vector2(-ground_ray_offset_x,  ground_ray_length))
	_ray_ground_right  = _make_ray("RayCast2D_GroundRight",  Vector2( ground_ray_offset_x,  ground_ray_length))
	_ray_wall_left     = _make_ray("RayCast2D_WallLeft",     Vector2(-wall_ray_length,       0.0))
	_ray_wall_right    = _make_ray("RayCast2D_WallRight",    Vector2( wall_ray_length,       0.0))
	_ray_ceiling_left  = _make_ray("RayCast2D_CeilingLeft",  Vector2(-ceiling_ray_offset_x, -ceiling_ray_length))
	_ray_ceiling_right = _make_ray("RayCast2D_CeilingRight", Vector2( ceiling_ray_offset_x, -ceiling_ray_length))

# _make_ray(): Builds one RayCast2D child with a target vector.
# ray_name: Name assigned to the generated ray node.
# target: Local-space target position for the ray endpoint.
# return: Configured and attached RayCast2D instance.
#
# Uses player body mask and enables the ray immediately for state queries.
func _make_ray(ray_name: String, target: Vector2) -> RayCast2D:
	var ray := RayCast2D.new()
	ray.name = ray_name
	ray.target_position = target
	ray.collision_mask = Layers.MASK_PLAYER_BODY
	ray.enabled = true
	add_child(ray)
	return ray
