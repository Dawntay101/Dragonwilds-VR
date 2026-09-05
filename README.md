# RSDWVR - VR controller mod for RuneScape: Dragonwilds

Use VR controllers (Meta Quest via Link/Air Link) to drive the game's
*existing* actions - movement, attack, interact, block, menus - not
gesture-based swinging. Built on [UEVR](https://uevr.io/), the universal
Unreal Engine VR injector: it turns your VR controllers into a virtual
Xbox controller and feeds that to the game, and Dragonwilds already has
full native gamepad support, so **no custom scripting turned out to be
necessary** - just the right UEVR build and profile settings.

Status: **working**. Head tracking, stereo rendering, and every game
action (movement, camera, attack, block, dodge, interact, spellbook,
inventory, build mode, quick access, map/journal, ammo switching) are all
reachable from the VR controllers.

## Why this approach

- Dragonwilds is Unreal Engine 5 (confirmed from
  `RSDragonwilds\Binaries\Win64\RSDragonwilds-Win64-Shipping.exe` and its
  `.pak`/`.utoc`/`.ucas` files) - UEVR's target.
- Dragonwilds has native Xbox/DualShock gamepad support covering
  everything, including inventory and build mode via D-pad (see control
  scheme below) - once UEVR's virtual controller reaches the game
  correctly, everything just works.
- This game runs on a proprietary UE5 fork ("Dominion", per its
  crash-log paths), which the current UEVR **stable** release (1.05,
  Nov 2024) doesn't fully support - several of its engine-hook signature
  scans fail on this build. A **nightly** UEVR build has much better
  generic UE5.4/5.5 support and is what actually got this working - see
  Setup below.

There's also a community UEVR profile for this game
([vilmarpn/RuneScape-Dragonwilds-Profile-UEVR](https://github.com/vilmarpn/RuneScape-Dragonwilds-Profile-UEVR),
MIT) that attaches the weapon mesh to your hand visually and forces
first-person - worth a look if you want that polish. This profile doesn't
do that (game runs in its normal third-person-over-shoulder camera),
focused purely on getting controller input working correctly.

## Project layout

```
uevr/                          UEVR injector + DLLs (downloaded, gitignored - see tools/Install-UEVR.ps1)
profile/                       This game's UEVR profile - version-controlled source of truth
  config.txt                   Main UEVR settings (rendering method, compatibility toggles, etc.)
  user_script.txt              Console commands run automatically at injection (AA/motion blur/shadow cvars)
  scripts/
    controller_bindings.lua    Currently empty/disabled - see "Lua binding attempt" below
tools/
  Install-UEVR.ps1             Downloads + checksum-verifies + extracts UEVR into ./uevr (-Nightly for nightly builds)
  Link-Profile.ps1             (Re)creates the junction described below
```

**Important wiring:** UEVR stores per-game profiles at
`%APPDATA%\UnrealVRMod\RSDragonwilds-Win64-Shipping\`. `tools/Link-Profile.ps1`
has already been run once, so that folder is a directory **junction**
pointing at `./profile` in this repo - anything UEVR saves at runtime
lands directly in version control. If you ever clone this repo fresh on a
new machine, re-run that script before first injection.

## One-time setup

1. **.NET 6.0 Desktop Runtime** - required by UEVR's injector GUI.
   Already installed on this machine.
2. UEVR is downloaded into `./uevr` as a **nightly build**
   (`tools/Install-UEVR.ps1 -Nightly`, requires `gh` CLI authenticated) -
   the stable 1.05 release doesn't work well enough on this game's engine
   fork. Re-run that script (with `-Nightly`) any time to pick up a newer
   nightly if something regresses; drop `-Nightly` to fall back to 1.05.
3. Make sure the Meta/Oculus PC app is running and your headset is
   connected via Link/Air Link before injecting.

## Injecting into the game (each play session)

1. Launch RuneScape: Dragonwilds normally from Steam and get to the main
   menu (leave it running).
2. Run `uevr\UEVRInjector.exe`.
3. In the injector: select the running `RSDragonwilds-Win64-Shipping.exe`
   process, choose **OpenXR** as the runtime (matches Quest Link), and
   inject. The profile's saved settings (Native Stereo rendering, the
   compatibility toggles below, the cvars in `user_script.txt`) all apply
   automatically - nothing else to configure in the overlay.

### Profile settings that mattered (in `config.txt`)

- `VR_RenderingMethod=0` (**Native Stereo**) - works cleanly on the
  nightly build. Earlier attempts used Alternating/AFR + Extreme
  Compatibility Mode to work around engine-hook failures on stable 1.05;
  the nightly build's hooks work well enough that neither is needed, and
  AFR was actually causing visible ghosting ("2 of everything").
- `VR_Compatibility_SkipPostInitProperties=true` - UEVR's internal scan
  for the engine's `PostInitProperties` function fails on this game's
  engine fork and crashes shortly after the first stereo frame without
  this. Still needed even on the nightly build.
- `VR_ExtremeCompatibilityMode=false` - was needed as a workaround on
  1.05 (grabs the backbuffer directly from the swapchain instead of via
  UEVR's engine hook), but caused a frame-buffering desync with AFR
  (visible as overlapping/transparent doubled geometry). Not needed on
  the nightly build.

### Console commands that mattered (in `user_script.txt`, run automatically at injection)

- `r.MotionBlurQuality 0`, `r.MotionBlur.Amount 0`,
  `r.DefaultFeature.MotionBlur 0` - motion blur baked into a headset view
  is disorienting; off for comfort.
- `r.AntiAliasingMethod` - **not** overridden (left at the game's
  default). It was forced to `0` at one point to fix AFR-specific
  ghosting, but doing that under Native Stereo starves UE5's Lumen
  GI/reflections denoiser of the temporal accumulation it needs, which
  showed up as glowing pink/colorful static patches (raw undenoised Lumen
  noise, not a shadow-specific bug despite how it looked). Removed once
  we moved off AFR.
- `r.Shadow.Virtual.Enable 0` - turns off UE5's Virtual Shadow Maps.
  Didn't end up being the fix for the pink patches (AA was), but kept
  since it's a real cvar and harmless to leave off.

## Control scheme (all working via UEVR's default virtual-gamepad mapping)

No custom bindings needed - Dragonwilds' native Xbox-controller scheme
covers everything once UEVR's virtual controller reaches it correctly:

| Input | Action |
|---|---|
| A | Jump |
| B | Dodge |
| X | Interact |
| Y | Spellbook |
| RT | Attack |
| RB | Special attack |
| LT | Block / Aim |
| LB | Quick access |
| Select/Back | Map / Journal / Spells |
| D-Pad Up | Inventory |
| D-Pad Down | Build mode |
| D-Pad Left/Right | Change equipped arrows/bolts/runes |

D-Pad presses are synthesized by UEVR from a thumbrest+thumbstick gesture
(rest your thumb on the *other* controller's thumbrest while pushing a
thumbstick in a direction) since Quest Touch controllers have no physical
D-pad - this already worked out of the box on this profile
(`VR_DPadShifting=true`, the default).

## First-person mode (experimental, `firstPerson` branch)

Attempting to switch from the default third-person-over-shoulder camera
to first-person, following the approach used by the community profile
mentioned above
([vilmarpn/RuneScape-Dragonwilds-Profile-UEVR](https://github.com/vilmarpn/RuneScape-Dragonwilds-Profile-UEVR),
MIT-licensed - ported with attribution). Three pieces, all additive to
the working third-person profile:

- `profile/uobjecthook/camera_state.json` - a UEVR UObjectHook camera
  attachment that pins the VR camera to `Acknowledged Pawn > Properties >
  Mesh` with a `+186.2` Z offset (head height), replacing the default
  third-person boom camera. This is why `VR_CameraForwardOffset` /
  `VR_CameraRightOffset` / `VR_CameraUpOffset` in `config.txt` are zeroed
  on this branch - the old third-person-tuned offsets would otherwise
  compound with this attachment.
- `profile/uobjecthook/5048649411680316389_props.json` - a UObjectHook
  property override on `Acknowledged Pawn` setting
  `bUseControllerRotationYaw`/`Roll` to true, so the character's body
  turns with the camera/controller instead of staying independently
  oriented (needed in first-person; the opposite of what you want in
  third-person over-shoulder).
- `profile/scripts/mesh_Weapon.lua` - hides the player's own skeletal
  mesh components (so the head-height camera doesn't see inside the
  character model) and attaches equipped weapon meshes to the right-hand
  motion controller, with per-weapon-type rotation offsets (dagger vs.
  bow vs. everything else). Uses UEVR's pawn/motion-controller-state Lua
  API, not the action-handle API - see the note below on why that
  distinction matters.
- `VR_DecoupledPitch=true` (was `false`) in `config.txt` - lets you look
  up/down freely with the headset independent of the body's pitch, which
  first-person needs and third-person-over-shoulder didn't.

Deliberately **not** changed from the working third-person config:
`VR_Compatibility_SkipPostInitProperties=true` stays on (still needed to
avoid the crash described above - the reference profile has it off,
which may just mean it targets a different UEVR build), and
`VR_AimMethod`/`VR_DPadShiftingMethod` are untouched since they aren't
obviously first-person-specific and changing them risks regressing
input that already works.

**Status: untested** - this is a from-the-README port, not yet verified
in-headset (see "Iterating" below - I can't put the headset on myself).
Expect the `186.21337890625` head-height offset in particular to need
retuning for this game's actual player mesh scale/pivot once someone
tries it.

## Lua binding attempt (abandoned - not needed)

`profile/scripts/controller_bindings.lua` originally tried to directly
inject extra virtual-gamepad button presses from specific VR controller
actions (via `uevr.params.vr:get_action_handle()` /
`:is_action_active()`), to reach actions that seemed unreachable. Turned
out unnecessary - once the script's own bug was fixed, D-pad shifting
(inventory/build mode) worked fine via UEVR's existing default mapping.
Also, that action-handle API throws something even a Lua `pcall` around
the call site can't catch in this UEVR build (the exception surfaces from
UEVR's own outer handler instead), so it's not safe to use here even if a
real need for it comes up later - worth knowing before reaching for it
again.

## Iterating

I can't put a headset on, so testing is on you: put the headset on, try
an action, tell me what's wrong, and I'll adjust the profile from there.
