# src/

All game source assets: scenes, scripts, prefabs, fonts, and native modules.

---

## Folder Structure

```
src/
├── animation/      Animation parameter constants
├── ffi/            Native FFI library definition
├── fonts/          Font assets
├── perf/           C performance module
├── prefabs/        Reusable blueprints, organised by category
├── scenes/         Top-level game scenes
└── scripts/        GDScript source, organised by category
```

---

## animation/

Holds `anim_params.gd` — a constants file that defines the string keys used in
`Character.anim_params` dictionary. `CharacterAnimator` reads these keys to
resolve animation states. Always reference keys through this file rather than
inline strings.

---

## ffi/

> **Placeholder** — purpose not yet documented. Contains `perf.ffilibrary`,
> which appears to define a native library binding. Details TBD.

---

## fonts/

`ARIAL.TTF` — the only font asset currently in use, referenced by `LevelBounds`
for debug extents display and by UI labels.

---

## perf/

> **Placeholder** — purpose not yet documented. Contains a C module
> (`src/main.c`, `include/common.h`) and a `Makefile`. Likely a native
> performance extension intended to be built and loaded via the FFI definition
> above. Details TBD.

---

## prefabs/

Reusable packed scenes (`.tscn`) that are instanced into levels rather than
opened directly.

| Subfolder | Contents |
|---|---|
| `characters/` | `DemoPlayer.tscn` — the player character blueprint |
| `enemies/` | Empty — enemy prefabs will live here |

---

## scenes/

Top-level scenes that are loaded directly by `LevelManager` or the editor.

| File | Purpose |
|---|---|
| `Template.tscn` | Base scene; all level scenes inherit from this |
| `Bar.tscn` | Bar area level |
| `Hub.tscn` | Hub/overworld area |
| `Levels/` | Empty — level scenes will live here |

### Creating a new scene from Template

`Template.tscn` pre-wires the camera rig, level bounds, managers, and the
`Canvases` / `Environment` node hierarchy that all levels need. Instead of
building that structure from scratch, **inherit** from it:

1. In the top menu **Scene**, select **New Inherited Scene**.
2. Select `src/scenes/Template.tscn`.
3. Save the new `.tscn` file wherever appropriate (e.g. `src/scenes/Levels/`).
4. The inherited scene shows the full Template tree in the editor; nodes marked
   with a chain icon are locked to the parent scene and can only be modified
   there. Add level-specific nodes freely on top.
5. Add at least one `Checkpoint` node under `Environment/Checkpoints` and set
   its `checkpoint_id` export to a unique string (e.g. `"level_start"`).
   `LevelManager` uses this ID to track the active respawn point — leaving it
   blank will cause spawn logic to malfunction.

---

## scripts/

All GDScript source. Each subfolder is a self-contained category — scripts
should only reach across categories via `SignalBus` or the autoloaded managers.

| Subfolder | Contents |
|---|---|
| `character/` | `Character`, `PlayerController`, `Health`, `Hitbox`, `Hurtbox`, `CharacterAbility` base, `CharacterAnimator` |
| `character/abilities/` | One file per ability: `HorizontalMovement`, `Jump`, `Dash`, `Crouch`, `Run`, `WallJump`, `WallClinging`, `Ladder`, `LookUp`, `LevelBounds`, `Pause`, `ButtonActivation` |
| `combat/` | Shared combat data types (e.g. `TypedDamage`) |
| `enemies/` | `AIBrain`, `AIAction` base, `AIDecision` base, `EnemyBase`; plus concrete `action_*` and `decision_*` implementations |
| `environment/` | Passive level objects: `KillZone`, `LadderArea`, `LevelBounds`, `MovingPlatform`, `OneWayPlatform`, `ConveyorBelt`, `Spring` |
| `managers/` | Autoloaded singletons: `SignalBus`, `GameManager`, `LevelManager`, `SaveManager`, `InputManager`, `AudioManager`, `TimeManager`, plus shared resources and enums |
| `spawn/` | Spawn-related logic: `Checkpoint`, `Teleport`, `GoToLevelEntryPoint`, `InteractableBase` |
| `ui/` | UI and HUD scripts (e.g. `DebugFpsLabel`) |
| `world/` | Scene-level helpers: `CameraRig`, `LevelConfig` |
