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

## Autoloaded singleton for music crossfading and pooled SFX playback.
## Register streams via [method register_music] and [method register_sfx]
## before playing, or emit via [signal SignalBus.play_sfx_requested].
extends Node

## Maximum simultaneous SFX voices; the oldest is stolen when all are busy.
const SFX_POOL_SIZE := 16

## ID of the currently playing music track; empty string when silent.
var current_music_id: String = ""

## Emitted when a new music track begins playing.
signal music_started(music_id: String)
## Emitted when music is explicitly stopped via [method stop_music].
signal music_stopped()

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _inactive_music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_registry: Dictionary = {}
var _sfx_registry: Dictionary = {}
var _crossfade_tween: Tween


# _ready(): Initialises audio buses, node structure, and signal connections.
#
# Ensures buses exist, builds the crossfade players and SFX pool, then
# wires all three SignalBus listeners needed for audio playback.
func _ready() -> void:
	_ensure_audio_buses()
	_build_node_structure()
	SignalBus.play_sfx_requested.connect(_on_play_sfx_requested)
	SignalBus.play_music_requested.connect(_on_play_music_requested)
	SignalBus.time_scale_changed.connect(_on_time_scale_changed)


# --- Registry ---

# register_music(): Associates an audio stream with a music id.
# id: Unique string key used to play the track via play_music.
# stream: The AudioStream asset to register.
#
# Overwrites any previously registered stream for the same id.
func register_music(id: String, stream: AudioStream) -> void:
	_music_registry[id] = stream


# register_sfx(): Associates an audio stream with an SFX id.
# id: Unique string key used to play the sound via play_sfx.
# stream: The AudioStream asset to register.
#
# Overwrites any previously registered stream for the same id.
func register_sfx(id: String, stream: AudioStream) -> void:
	_sfx_registry[id] = stream


# --- Music ---

# play_music(): Crossfades to the music registered as music_id.
# music_id: ID of the track to play; must be registered via register_music.
# crossfade_duration: Duration of the fade in seconds; defaults to 1.0.
#
# No-ops when music_id is already playing. Kills any in-progress crossfade
# before starting a new one. Emits music_started on success.
func play_music(music_id: String, crossfade_duration: float = 1.0) -> void:
	if music_id == current_music_id:
		return
	if not _music_registry.has(music_id):
		push_warning("AudioManager: music_id not registered: " + music_id)
		return
	if _crossfade_tween:
		_crossfade_tween.kill()

	_inactive_music.stream = _music_registry[music_id]
	_inactive_music.volume_db = -80.0
	_inactive_music.play()

	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(_active_music, "volume_db", -80.0, crossfade_duration)
	_crossfade_tween.tween_property(_inactive_music, "volume_db", 0.0, crossfade_duration)
	_crossfade_tween.chain().tween_callback(_active_music.stop)

	var prev := _active_music
	_active_music = _inactive_music
	_inactive_music = prev

	current_music_id = music_id
	music_started.emit(music_id)


# stop_music(): Fades out the active music track.
# fade_duration: Duration of the fade-out in seconds; defaults to 1.0.
#
# Clears current_music_id and emits music_stopped after the fade finishes.
func stop_music(fade_duration: float = 1.0) -> void:
	if _crossfade_tween:
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_active_music, "volume_db", -80.0, fade_duration)
	_crossfade_tween.chain().tween_callback(_active_music.stop)
	current_music_id = ""
	music_stopped.emit()


# pause_music(): Pauses the active music stream without losing position.
#
# Sets stream_paused on the active player. Resume with resume_music.
func pause_music() -> void:
	_active_music.stream_paused = true


# resume_music(): Resumes the active music stream from where it was paused.
#
# Clears stream_paused on the active player. No-op if not already paused.
func resume_music() -> void:
	_active_music.stream_paused = false


# --- SFX ---

# play_sfx(): Plays the registered SFX on the next free pool voice.
# sfx_id: ID of the sound to play; must be registered via register_sfx.
#
# Steals the oldest pool voice when all voices are busy. Emits a warning
# and returns without playing when sfx_id is not registered.
func play_sfx(sfx_id: String) -> void:
	if not _sfx_registry.has(sfx_id):
		push_warning("AudioManager: sfx_id not registered: " + sfx_id)
		return
	var player := _get_free_sfx_player()
	player.stream = _sfx_registry[sfx_id]
	player.play()


# play_sfx_at(): Positional SFX stub; delegates to play_sfx.
# sfx_id: ID of the sound to play.
# _position: World position of the emitter; unused until 2D pooling lands.
#
# Positional audio is not yet implemented; all SFX play on the same
# global player regardless of position.
func play_sfx_at(sfx_id: String, _position: Vector2) -> void:
	play_sfx(sfx_id)


# --- Volume (linear 0.0–1.0) ---

# set_music_volume(): Sets the Music bus volume from a linear value.
# linear: Volume as a linear value (0.0–1.0).
#
# Converts linear to dB and applies to the Music bus via _set_bus_volume.
func set_music_volume(linear: float) -> void:
	_set_bus_volume("Music", linear)


# set_sfx_volume(): Sets the SFX bus volume from a linear value.
# linear: Volume as a linear value (0.0–1.0).
#
# Converts linear to dB and applies to the SFX bus via _set_bus_volume.
func set_sfx_volume(linear: float) -> void:
	_set_bus_volume("SFX", linear)


# set_master_volume(): Sets the Master bus volume from a linear value.
# linear: Volume as a linear value (0.0–1.0).
#
# Writes directly to AudioServer bus 0 (Master) as dB.
func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(linear))


# --- Internal ---

# _build_node_structure(): Creates MusicPlayer_A/B nodes and fills _sfx_pool.
#
# MusicPlayer_B starts at -80 dB so MusicPlayer_A is the default active
# player. SFX players are added as children of a dedicated SfxPool node.
func _build_node_structure() -> void:
	_music_a = _make_music_player("MusicPlayer_A")
	_music_b = _make_music_player("MusicPlayer_B")
	_music_b.volume_db = -80.0
	_active_music = _music_a
	_inactive_music = _music_b

	var pool_node := Node.new()
	pool_node.name = "SfxPool"
	add_child(pool_node)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		player.bus = &"SFX"
		pool_node.add_child(player)
		_sfx_pool.append(player)


# _make_music_player(): Creates and adds a Music-bus AudioStreamPlayer.
# player_name: Node name assigned to the new player.
# return: The newly created AudioStreamPlayer.
#
# The player is assigned to the Music bus and added as a direct child of
# this AudioManager node before being returned.
func _make_music_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Music"
	add_child(player)
	return player


# _ensure_audio_buses(): Creates Music, SFX, and UI buses if absent at runtime.
#
# For production, configure buses in Project Settings → Audio → Buses.
func _ensure_audio_buses() -> void:
	for bus_name: String in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.get_bus_count()
			AudioServer.add_bus()
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


# _get_free_sfx_player(): Returns the next idle SFX pool player.
# return: An AudioStreamPlayer that is not currently playing.
#
# If all voices are busy, steals and returns the oldest pool player.
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	# All voices busy — steal the oldest player and rotate the pool.
	var stolen := _sfx_pool[0]
	stolen.stop()
	_sfx_pool.append(_sfx_pool.pop_front())
	return stolen


# _set_bus_volume(): Sets a named audio bus to the given linear volume.
# bus_name: Name of the AudioServer bus to adjust.
# linear: Volume as a linear value (0.0–1.0), converted to dB internally.
#
# Silently no-ops when bus_name is not found in AudioServer.
func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


# _on_play_sfx_requested(): Signal relay from SignalBus to play_sfx.
# sfx_id: ID of the SFX to play.
#
# Connected to SignalBus.play_sfx_requested in _ready.
func _on_play_sfx_requested(sfx_id: String) -> void:
	play_sfx(sfx_id)


# _on_play_music_requested(): Signal relay from SignalBus to play_music.
# music_id: ID of the music track to play.
#
# Connected to SignalBus.play_music_requested in _ready.
func _on_play_music_requested(music_id: String) -> void:
	play_music(music_id)


# _on_time_scale_changed(): Syncs pitch_scale on both music players.
# new_scale: New Engine.time_scale value, clamped to 0.1–4.0 for pitch.
#
# Connected to SignalBus.time_scale_changed in _ready.
func _on_time_scale_changed(new_scale: float) -> void:
	var pitch := clampf(new_scale, 0.1, 4.0)
	_music_a.pitch_scale = pitch
	_music_b.pitch_scale = pitch
