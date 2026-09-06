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

    CONFIRMED (2026-09-05) twice now that building a log message
    (`..` string concatenation, `tostring()`) inside
    on_xinput_get_state reliably crashes the game
    (UEVRBackend.dll, STATUS_STACK_BUFFER_OVERRUN) the instant L3 is
    pressed. A version with no logging at all, and one that deferred
    only the `log_info` *call* itself to a safer callback while still
    building the log string in on_xinput_get_state, both crashed the
    same way; a version with zero string work of any kind in
    on_xinput_get_state (only boolean reads/compares and the
    already-proven-safe vr:set_aim_allowed call) did not crash. That
    points specifically at Lua memory allocation (string concatenation
    allocates and touches Lua's GC/string-interning state) being unsafe
    from whatever thread on_xinput_get_state runs on - probably a
    separate thread from the one running the game's other Lua
    callbacks (on_early_calculate_stereo_view_offset etc.), racing on
    the shared Lua state's allocator when both fire close together.

    So the rule for this callback now: ONLY booleans, numbers, and the
    already-proven-safe vr:set_aim_allowed call - never build a string,
    touch a table, or call anything else here. All string-building
    (including the log_info calls) happens in
    on_early_calculate_stereo_view_offset instead, a render-thread
    callback mesh_Weapon.lua already does plenty of string work in
    (get_full_name, string.find, its own error tracebacks) every frame
    without incident - it just reads the plain booleans/numbers set
    below and turns them into log lines there, safely off-thread from
    whatever on_xinput_get_state runs on.
]]

local vr = uevr.params.vr

local frozen = false
local chord_was_held = false

-- Only booleans/numbers, written from on_xinput_get_state - see comment
-- above for why. All string-building happens where these are read, in
-- on_early_calculate_stereo_view_offset below.
local last_l3_held = false
local last_lb_held = false
local edge_pending = false
local toggle_pending = false
local last_toggled_frozen = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    if l3_held ~= last_l3_held or lb_held ~= last_lb_held then
        last_l3_held = l3_held
        last_lb_held = lb_held
        edge_pending = true
    end

    if chord_held and not chord_was_held then
        frozen = not frozen
        vr:set_aim_allowed(not frozen)
        last_toggled_frozen = frozen
        toggle_pending = true
    end
    chord_was_held = chord_held
end)

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    if edge_pending then
        edge_pending = false
        uevr.params.functions:log_info("[menu_aim_freeze] L3=" .. tostring(last_l3_held) .. " LB/grip=" .. tostring(last_lb_held))
    end

    if toggle_pending then
        toggle_pending = false
        uevr.params.functions:log_info("[menu_aim_freeze] chord toggled, frozen=" .. tostring(last_toggled_frozen))
    end
end)
