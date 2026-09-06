--[[
    RSDWVR - menu_aim_freeze.lua

    Head-aim (VR_AimMethod=1 + VR_AimModifyPlayerControlRotation=true,
    see README "First-person mode") writes the HMD's rotation into the
    PlayerController's ControlRotation every frame with no smoothing.
    That's also the same value UEVR's automatic 3D-projected UI uses to
    orient menus/HUD, so menus re-center on your gaze instantly and
    become unreadable. Fix: press Left Stick Click (L3) + Left Grip
    together as a toggle (not a hold) to suspend head-aim
    (vr:set_aim_allowed(false)); press the chord again to resume.

    CONFIRMED (2026-09-05) that an earlier version of this script
    caused a native crash (UEVRBackend.dll, STATUS_STACK_BUFFER_OVERRUN)
    as soon as L3 was pressed, even with no chord engaged - disabling
    the script entirely fixed it, ruling out the "pre-existing UEVR
    bug" theory this project's memory previously leaned on. The prime
    suspect: that version called `uevr.params.functions:log_info(...)`
    on every L3/grip press-release edge for debugging, and
    on_xinput_get_state fires on whatever thread calls the real
    XInputGetState - likely not the thread UEVR's logger expects to be
    called from elsewhere. A stack-buffer-overrun is a plausible
    signature for a non-thread-safe logging call. This version removes
    all logging, and only calls vr:set_aim_allowed on an actual chord
    toggle edge (not unconditionally every frame like the crashing
    version did), to minimize how much runs inside this callback at
    all. This is a hypothesis, not a confirmed root cause - if L3
    (or the chord) crashes again with this version, the remaining
    suspects are the bitwise button reads themselves or calling any
    uevr API function (including set_aim_allowed) from this callback,
    which would mean this whole approach needs a different mechanism
    (e.g. polling from a callback known to run on the render thread,
    like on_pre_calculate_stereo_view_offset, and reading button state
    some other way) rather than on_xinput_get_state.
]]

local vr = uevr.params.vr

local frozen = false
local chord_was_held = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    if chord_held and not chord_was_held then
        frozen = not frozen
        vr:set_aim_allowed(not frozen)
    end
    chord_was_held = chord_held
end)
