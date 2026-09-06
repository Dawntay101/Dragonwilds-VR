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
    the script entirely fixed it. Prime suspect: that version called
    `uevr.params.functions:log_info(...)` directly from inside
    on_xinput_get_state, which fires on whatever thread calls the real
    XInputGetState - likely not the thread UEVR's logger expects to be
    called from. The next version removed all logging and only called
    vr:set_aim_allowed on an actual toggle edge - no crash this time,
    confirming set_aim_allowed itself is safe to call from that
    callback. But the toggle didn't visibly do anything either, and
    with no logging there was no way to tell why.

    This version adds logging back, but *not* from inside
    on_xinput_get_state: it only writes to a plain Lua local
    (`pending_log`) there (cheap, no uevr API calls beyond the
    already-proven-safe set_aim_allowed), and defers the actual
    log_info call to on_early_calculate_stereo_view_offset - a render-
    thread callback that mesh_Weapon.lua already calls into (including
    its own error-logging path) continuously, every frame, across every
    test session so far without ever causing a native crash. This
    should tell us, from the next profile/log.txt, whether the chord is
    being detected at all (grip really mapping to LB, both buttons
    registering as held in the same poll) and whether set_aim_allowed
    is being called with the value we expect - without touching the
    thread that's suspected of causing the earlier crash.
]]

local vr = uevr.params.vr

local frozen = false
local chord_was_held = false

-- Written from on_xinput_get_state (the xinput-hook thread - no uevr API
-- calls here except the already-proven-safe set_aim_allowed). Read and
-- logged from on_early_calculate_stereo_view_offset (render thread) instead.
local last_l3_held = false
local last_lb_held = false
local pending_log = nil

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    if l3_held ~= last_l3_held or lb_held ~= last_lb_held then
        pending_log = "L3=" .. tostring(l3_held) .. " LB/grip=" .. tostring(lb_held)
        last_l3_held = l3_held
        last_lb_held = lb_held
    end

    if chord_held and not chord_was_held then
        frozen = not frozen
        vr:set_aim_allowed(not frozen)
        pending_log = (pending_log and (pending_log .. " | ") or "") ..
            "chord toggled, frozen=" .. tostring(frozen)
    end
    chord_was_held = chord_held
end)

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    if pending_log ~= nil then
        uevr.params.functions:log_info("[menu_aim_freeze] " .. pending_log)
        pending_log = nil
    end
end)
